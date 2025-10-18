package config

import (
	"os"
	"strconv"
)

type Config struct {
	Environment  string
	ServerPort   string
	DatabaseURL  string
	RabbitMQURL  string
	JWTSecret    string
	JaegerURL    string
}

func Load() *Config {
	return &Config{
		Environment:  getEnv("ENVIRONMENT", "development"),
		ServerPort:   getEnv("SERVER_PORT", ":8002"),
		DatabaseURL:  getEnv("DATABASE_URL", "postgresql://admin:admin123@localhost:5432/app_database"),
		RabbitMQURL:  getEnv("RABBITMQ_URL", "amqp://admin:admin123@localhost:5672/"),
		JWTSecret:    getEnv("JWT_SECRET", "your-super-secret-jwt-key-change-in-production"),
		JaegerURL:    getEnv("JAEGER_ENDPOINT", "http://jaeger:14268/api/traces"),
	}
}

func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

func getEnvAsInt(key string, defaultValue int64) int64 {
	if value := os.Getenv(key); value != "" {
		if intValue, err := strconv.ParseInt(value, 10, 64); err == nil {
			return intValue
		}
	}
	return defaultValue
}
