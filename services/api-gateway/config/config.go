package config

import (
	"os"
)

// Config representa as configurações da aplicação
type Config struct {
	Environment           string
	ServerPort            string
	AuthServiceURL        string
	TransactionServiceURL string
	JaegerEndpoint        string
}

// Load carrega as configurações das variáveis de ambiente
func Load() *Config {
	return &Config{
		Environment:           getEnv("ENVIRONMENT", "development"),
		ServerPort:            getEnv("SERVER_PORT", ":8000"),
		AuthServiceURL:        getEnv("AUTH_SERVICE_URL", "http://auth-service:8001"),
		TransactionServiceURL: getEnv("TRANSACTION_SERVICE_URL", "http://transaction-service:8002"),
		JaegerEndpoint:        getEnv("JAEGER_ENDPOINT", "http://jaeger:14268/api/traces"),
	}
}

// getEnv obtém uma variável de ambiente com valor padrão
func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}
