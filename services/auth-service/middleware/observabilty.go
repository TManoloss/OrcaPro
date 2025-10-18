package middleware

import (
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"go.opentelemetry.io/otel/attribute"
	"go.opentelemetry.io/otel/trace"
	"go.uber.org/zap"

	"auth-service/metrics"
)

// RequestLogger adiciona logging estruturado para cada requisição
func RequestLogger(logger *zap.Logger) gin.HandlerFunc {
	return func(c *gin.Context) {
		start := time.Now()
		path := c.Request.URL.Path
		query := c.Request.URL.RawQuery

		// Processa a requisição
		c.Next()

		// Calcula latência
		latency := time.Since(start)

		// Extrai trace_id se disponível
		traceID := ""
		if span := trace.SpanFromContext(c.Request.Context()); span.SpanContext().HasTraceID() {
			traceID = span.SpanContext().TraceID().String()
		}

		// Log estruturado
		fields := []zap.Field{
			zap.Int("status", c.Writer.Status()),
			zap.String("method", c.Request.Method),
			zap.String("path", path),
			zap.String("query", query),
			zap.String("ip", c.ClientIP()),
			zap.String("user_agent", c.Request.UserAgent()),
			zap.Duration("latency", latency),
			zap.String("trace_id", traceID),
		}

		// Adiciona user_id se autenticado
		if userID, exists := c.Get("user_id"); exists {
			fields = append(fields, zap.String("user_id", userID.(string)))
		}

		// Log com nível apropriado
		if len(c.Errors) > 0 {
			fields = append(fields, zap.String("error", c.Errors.String()))
			logger.Error("request completed with errors", fields...)
		} else if c.Writer.Status() >= 500 {
			logger.Error("request failed", fields...)
		} else if c.Writer.Status() >= 400 {
			logger.Warn("request rejected", fields...)
		} else {
			logger.Info("request completed", fields...)
		}
	}
}

// TracingMiddleware adiciona tracing OpenTelemetry
func TracingMiddleware(tracer trace.Tracer) gin.HandlerFunc {
	return func(c *gin.Context) {
		ctx, span := tracer.Start(c.Request.Context(), c.Request.Method+" "+c.FullPath())
		defer span.End()

		// Adiciona atributos ao span
		span.SetAttributes(
			attribute.String("http.method", c.Request.Method),
			attribute.String("http.url", c.Request.URL.String()),
			attribute.String("http.user_agent", c.Request.UserAgent()),
			attribute.String("http.client_ip", c.ClientIP()),
		)

		// Propaga o contexto
		c.Request = c.Request.WithContext(ctx)

		// Adiciona trace_id ao response header
		span.SpanContext().TraceID().String()
		c.Header("X-Trace-ID", span.SpanContext().TraceID().String())

		// Processa a requisição
		c.Next()

		// Adiciona status code ao span
		span.SetAttributes(attribute.Int("http.status_code", c.Writer.Status()))

		// Marca como erro se status >= 400
		if c.Writer.Status() >= 400 {
			span.SetAttributes(attribute.Bool("error", true))
			if len(c.Errors) > 0 {
				span.SetAttributes(attribute.String("error.message", c.Errors.String()))
			}
		}
	}
}

// MetricsMiddleware coleta métricas Prometheus
func MetricsMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		start := time.Now()
		path := c.FullPath()
		if path == "" {
			path = c.Request.URL.Path
		}

		// Processa a requisição
		c.Next()

		// Calcula duração
		duration := time.Since(start).Seconds()
		status := strconv.Itoa(c.Writer.Status())

		// Registra métricas
		metrics.HTTPRequestsTotal.WithLabelValues(
			c.Request.Method,
			path,
			status,
		).Inc()

		metrics.HTTPRequestDuration.WithLabelValues(
			c.Request.Method,
			path,
			status,
		).Observe(duration)
	}
}

func Recovery(logger *zap.Logger) gin.HandlerFunc {
	return func(c *gin.Context) {
		defer func() {
			if err := recover(); err != nil {
				// Extrai trace_id se disponível
				traceID := ""
				if span := trace.SpanFromContext(c.Request.Context()); span.SpanContext().HasTraceID() {
					traceID = span.SpanContext().TraceID().String()
				}

				logger.Error("panic recovered",
					zap.Any("error", err),
					zap.String("trace_id", traceID),
					zap.String("path", c.Request.URL.Path),
					zap.String("method", c.Request.Method),
				)

				c.AbortWithStatusJSON(http.StatusInternalServerError, gin.H{
					"error":    "Internal Server Error",
					"trace_id": traceID,
				})
			}
		}()

		c.Next()
	}
}