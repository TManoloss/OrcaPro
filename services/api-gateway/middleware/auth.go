package middleware

import (
	"net/http"
	"strings"
	"sync"
	"time"

	"github.com/gin-gonic/gin"
	"go.uber.org/zap"
)

// AuthMiddleware middleware básico de autenticação
func AuthMiddleware(logger *zap.Logger) gin.HandlerFunc {
	return func(c *gin.Context) {
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Authorization header required"})
			c.Abort()
			return
		}

		// Extrai token Bearer
		tokenParts := strings.Split(authHeader, " ")
		if len(tokenParts) != 2 || tokenParts[0] != "Bearer" {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid authorization header format"})
			c.Abort()
			return
		}

		// token := tokenParts[1]
		// TODO: Validar token JWT aqui

		// Por enquanto, apenas adiciona user_id simulado
		c.Set("user_id", "user123")
		c.Next()
	}
}

// RateLimiter middleware simples de limitação de taxa
func RateLimiter() gin.HandlerFunc {
	var mu sync.Mutex
	var requests = make(map[string][]time.Time)

	return func(c *gin.Context) {
		mu.Lock()
		defer mu.Unlock()

		clientIP := c.ClientIP()
		now := time.Now()

		// Remove requests antigos (janela de 1 minuto)
		window := time.Minute
		var validRequests []time.Time
		for _, reqTime := range requests[clientIP] {
			if now.Sub(reqTime) < window {
				validRequests = append(validRequests, reqTime)
			}
		}
		requests[clientIP] = validRequests

		// Verifica limite (100 requests por minuto)
		limit := 100
		if len(requests[clientIP]) >= limit {
			c.JSON(http.StatusTooManyRequests, gin.H{
				"error":  "Rate limit exceeded",
				"limit":  limit,
				"window": "1 minute",
			})
			c.Abort()
			return
		}

		// Adiciona request atual
		requests[clientIP] = append(requests[clientIP], now)
		c.Next()
	}
}
