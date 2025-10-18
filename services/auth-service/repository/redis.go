package repository

import (
	"context"

	"github.com/go-redis/redis/v8"
)

// NewRedisClient cria uma nova conexão com o Redis
func NewRedisClient(redisURL string) *redis.Client {
	opt, err := redis.ParseURL(redisURL)
	if err != nil {
		panic("failed to parse redis URL: " + err.Error())
	}

	client := redis.NewClient(opt)

	// Testa a conexão
	if err := client.Ping(context.Background()).Err(); err != nil {
		panic("failed to connect to redis: " + err.Error())
	}

	return client
}
