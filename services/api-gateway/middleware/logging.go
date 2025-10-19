package middleware

import (
	"time"

	"github.com/gin-gonic/gin"
	"go.uber.org/zap"
)

// RequestLogger middleware para logar todas as requisições
func RequestLogger(logger *zap.Logger) gin.HandlerFunc {
	return func(c *gin.Context) {
		start := time.Now()
		path := c.Request.URL.Path
		raw := c.Request.URL.RawQuery

		// Processa a requisição
		c.Next()

		// Calcula latência
		latency := time.Since(start)

		// Determina status colorido
		statusColor := "green"
		if c.Writer.Status() >= 400 && c.Writer.Status() < 500 {
			statusColor = "yellow"
		} else if c.Writer.Status() >= 500 {
			statusColor = "red"
		}

		// Log da requisição
		logger.Info("HTTP Request",
			zap.String("method", c.Request.Method),
			zap.String("path", path),
			zap.String("query", raw),
			zap.String("ip", c.ClientIP()),
			zap.String("user_agent", c.Request.UserAgent()),
			zap.Int("status", c.Writer.Status()),
			zap.Duration("latency", latency),
			zap.String("status_color", statusColor),
		)
	}
}
