package main

import (
	"context"
	"net/http"
	"net/http/httputil"
	"net/url"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/prometheus/client_golang/prometheus/promhttp"
	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/exporters/jaeger"
	"go.opentelemetry.io/otel/sdk/resource"
	tracesdk "go.opentelemetry.io/otel/sdk/trace"
	semconv "go.opentelemetry.io/otel/semconv/v1.17.0"
	"go.uber.org/zap"

	"api-gateway/config"
	"api-gateway/middleware"
)

var (
	logger *zap.Logger
	tracer = otel.Tracer("api-gateway")
)

func main() {
	// Inicializa logger
	logger = initLogger()
	defer logger.Sync()

	// Inicializa tracing
	tp, err := initTracer()
	if err != nil {
		logger.Fatal("failed to initialize tracer", zap.Error(err))
	}
	defer func() {
		if err := tp.Shutdown(context.Background()); err != nil {
			logger.Error("error shutting down tracer provider", zap.Error(err))
		}
	}()

	// Carrega configurações
	cfg := config.Load()

	// Configura router
	router := setupRouter(cfg)

	// Configura servidor HTTP
	srv := &http.Server{
		Addr:         cfg.ServerPort,
		Handler:      router,
		ReadTimeout:  30 * time.Second,
		WriteTimeout: 30 * time.Second,
		IdleTimeout:  90 * time.Second,
	}

	// Inicia servidor
	go func() {
		logger.Info("starting api gateway",
			zap.String("port", cfg.ServerPort),
			zap.String("environment", cfg.Environment),
		)
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			logger.Fatal("failed to start server", zap.Error(err))
		}
	}()

	// Graceful shutdown
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	logger.Info("shutting down api gateway...")

	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	if err := srv.Shutdown(ctx); err != nil {
		logger.Fatal("server forced to shutdown", zap.Error(err))
	}

	logger.Info("api gateway exited successfully")
}

func setupRouter(cfg *config.Config) *gin.Engine {
	if cfg.Environment == "production" {
		gin.SetMode(gin.ReleaseMode)
	}

	router := gin.New()

	// Middlewares globais
	router.Use(middleware.RequestLogger(logger))
	router.Use(middleware.TracingMiddleware(tracer))
	router.Use(middleware.MetricsMiddleware())
	router.Use(middleware.Recovery(logger))
	router.Use(middleware.CORS())
	router.Use(middleware.RateLimiter())

	// Health check
	router.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"status":  "healthy",
			"service": "api-gateway",
			"time":    time.Now().Unix(),
		})
	})

	// Métricas
	router.GET("/metrics", gin.WrapH(promhttp.Handler()))

	// Proxy para Auth Service
	authURL, _ := url.Parse(cfg.AuthServiceURL)
	authProxy := httputil.NewSingleHostReverseProxy(authURL)

	router.Any("/api/v1/auth/*path", func(c *gin.Context) {
		c.Request.URL.Path = c.Param("path")
		authProxy.ServeHTTP(c.Writer, c.Request)
	})

	// Proxy para Transaction Service
	transactionURL, _ := url.Parse(cfg.TransactionServiceURL)
	transactionProxy := httputil.NewSingleHostReverseProxy(transactionURL)

	router.Any("/api/v1/transactions/*path", func(c *gin.Context) {
		c.Request.URL.Path = c.Param("path")
		transactionProxy.ServeHTTP(c.Writer, c.Request)
	})

	// Endpoint agregado para dashboard
	router.GET("/api/v1/dashboard", middleware.AuthMiddleware(logger), func(c *gin.Context) {
		userID, _ := c.Get("user_id")

		// Busca dados do usuário
		userResp, err := http.Get(cfg.AuthServiceURL + "/api/v1/me")
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to fetch user"})
			return
		}
		defer userResp.Body.Close()

		// Busca estatísticas de transações
		statsReq, _ := http.NewRequest("GET", cfg.TransactionServiceURL+"/api/v1/transactions/stats", nil)
		statsReq.Header.Set("Authorization", c.GetHeader("Authorization"))

		statsResp, err := http.DefaultClient.Do(statsReq)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to fetch stats"})
			return
		}
		defer statsResp.Body.Close()

		// Retorna dados agregados
		c.JSON(http.StatusOK, gin.H{
			"user_id": userID,
			"message": "Dashboard data aggregated successfully",
		})
	})

	return router
}

func initLogger() *zap.Logger {
	var logger *zap.Logger
	var err error

	if os.Getenv("ENVIRONMENT") == "production" {
		logger, err = zap.NewProduction()
	} else {
		logger, err = zap.NewDevelopment()
	}

	if err != nil {
		panic("failed to initialize logger: " + err.Error())
	}

	return logger
}

func initTracer() (*tracesdk.TracerProvider, error) {
	jaegerURL := os.Getenv("JAEGER_ENDPOINT")
	if jaegerURL == "" {
		jaegerURL = "http://jaeger:14268/api/traces"
	}

	exp, err := jaeger.New(jaeger.WithCollectorEndpoint(jaeger.WithEndpoint(jaegerURL)))
	if err != nil {
		return nil, err
	}

	tp := tracesdk.NewTracerProvider(
		tracesdk.WithBatcher(exp),
		tracesdk.WithResource(resource.NewWithAttributes(
			semconv.SchemaURL,
			semconv.ServiceName("api-gateway"),
			semconv.ServiceVersion("1.0.0"),
		)),
	)

	otel.SetTracerProvider(tp)
	return tp, nil
}
