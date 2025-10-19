package middleware

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"go.opentelemetry.io/otel/attribute"
	"go.opentelemetry.io/otel/codes"
	"go.opentelemetry.io/otel/trace"
)

// TracingMiddleware middleware para tracing distribuído
func TracingMiddleware(tracer trace.Tracer) gin.HandlerFunc {
	return func(c *gin.Context) {
		ctx := c.Request.Context()
		spanName := c.Request.Method + " " + c.Request.URL.Path

		ctx, span := tracer.Start(ctx, spanName)
		defer span.End()

		// Adiciona atributos ao span
		span.SetAttributes(
			attribute.String("http.method", c.Request.Method),
			attribute.String("http.url", c.Request.URL.String()),
			attribute.String("http.user_agent", c.Request.UserAgent()),
			attribute.String("http.remote_addr", c.RemoteIP()),
		)

		// Adiciona span ao contexto do Gin
		c.Request = c.Request.WithContext(ctx)

		// Processa a requisição
		c.Next()

		// Marca span como erro se status >= 500
		if c.Writer.Status() >= 500 {
			span.SetStatus(codes.Error, http.StatusText(c.Writer.Status()))
		}

		span.SetAttributes(
			attribute.Int("http.status_code", c.Writer.Status()),
			attribute.Int("http.response_size", c.Writer.Size()),
		)
	}
}
