package main

import (
	"context"
	"net/http"
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

	"transaction-service/config"
	"transaction-service/handlers"
	"transaction-service/middleware"
	"transaction-service/messaging"
	"transaction-service/repository"
)

var (
	logger *zap.Logger
	tracer = otel.Tracer("transaction-service")
)

func main() {
	// Inicializa logger estruturado
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

	// Conecta ao banco de dados
	db, err := repository.NewPostgresConnection(cfg.DatabaseURL)
	if err != nil {
		logger.Fatal("failed to connect to database", zap.Error(err))
	}
	defer db.Close()

	// Inicializa RabbitMQ
	rabbitmq, err := messaging.NewRabbitMQ(cfg.RabbitMQURL, logger)
	if err != nil {
		logger.Fatal("failed to connect to rabbitmq", zap.Error(err))
	}
	defer rabbitmq.Close()

	// Inicializa publisher
	publisher := messaging.NewEventPublisher(rabbitmq, logger)

	// Inicializa repositórios
	transactionRepo := repository.NewTransactionRepository(db, logger)

	// Inicializa handlers
	transactionHandler := handlers.NewTransactionHandler(
		transactionRepo,
		publisher,
		cfg,
		logger,
	)

	// Configura o router
	router := setupRouter(transactionHandler)

	// Configura servidor HTTP
	srv := &http.Server{
		Addr:         cfg.ServerPort,
		Handler:      router,
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 15 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	// Inicia servidor em goroutine
	go func() {
		logger.Info("starting transaction service",
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

	logger.Info("shutting down server...")

	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	if err := srv.Shutdown(ctx); err != nil {
		logger.Fatal("server forced to shutdown", zap.Error(err))
	}

	logger.Info("server exited successfully")
}

func setupRouter(transactionHandler *handlers.TransactionHandler) *gin.Engine {
	// Modo release em produção
	if os.Getenv("ENVIRONMENT") == "production" {
		gin.SetMode(gin.ReleaseMode)
	}

	router := gin.New()

	// Middlewares globais
	router.Use(middleware.RequestLogger(logger))
	router.Use(middleware.TracingMiddleware(tracer))
	router.Use(middleware.MetricsMiddleware())
	router.Use(middleware.Recovery(logger))
	router.Use(middleware.CORS())

	// Health check
	router.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"status":  "healthy",
			"service": "transaction-service",
			"time":    time.Now().Unix(),
		})
	})

	// Métricas do Prometheus
	router.GET("/metrics", gin.WrapH(promhttp.Handler()))

	// API v1
	v1 := router.Group("/api/v1")
	v1.Use(middleware.AuthMiddleware(logger)) // Todas as rotas requerem autenticação
	{
		transactions := v1.Group("/transactions")
		{
			transactions.POST("", transactionHandler.Create)
			transactions.GET("", transactionHandler.List)
			transactions.GET("/:id", transactionHandler.GetByID)
			transactions.PUT("/:id", transactionHandler.Update)
			transactions.DELETE("/:id", transactionHandler.Delete)
			transactions.GET("/stats", transactionHandler.GetStats)
		}
	}

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
			semconv.ServiceName("transaction-service"),
			semconv.ServiceVersion("1.0.0"),
		)),
	)

	otel.SetTracerProvider(tp)
	return tp, nil
}