package messaging

import (
	"context"
	"encoding/json"
	"fmt"
	"time"

	amqp "github.com/rabbitmq/amqp091-go"
	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/attribute"
	"go.opentelemetry.io/otel/trace"
	"go.uber.org/zap"

	"transaction-service/metrics"
)

const (
	ExchangeName       = "transactions_exchange"
	ExchangeType       = "topic"
	TransactionCreated = "transaction.created"
	TransactionUpdated = "transaction.updated"
	TransactionDeleted = "transaction.deleted"
)

type RabbitMQ struct {
	conn    *amqp.Connection
	channel *amqp.Channel
	logger  *zap.Logger
}

type EventPublisher struct {
	rabbitmq *RabbitMQ
	logger   *zap.Logger
	tracer   trace.Tracer
}

type TransactionCreatedEvent struct {
	TransactionID string    `json:"transaction_id"`
	UserID        string    `json:"user_id"`
	Description   string    `json:"description"`
	Amount        float64   `json:"amount"`
	Category      string    `json:"category"`
	Type          string    `json:"type"`
	Date          time.Time `json:"date"`
	TraceID       string    `json:"trace_id"`
	SpanID        string    `json:"span_id"`
	Timestamp     time.Time `json:"timestamp"`
}

type TransactionEvent struct {
	EventType     string    `json:"event_type"`
	TransactionID string    `json:"transaction_id"`
	UserID        string    `json:"user_id"`
	Description   string    `json:"description"`
	Amount        float64   `json:"amount"`
	Type          string    `json:"type"`
	Category      string    `json:"category"`
	Timestamp     time.Time `json:"timestamp"`
}

// NewRabbitMQ cria uma nova conexão com RabbitMQ
func NewRabbitMQ(url string, logger *zap.Logger) (*RabbitMQ, error) {
	// Conecta ao RabbitMQ
	conn, err := amqp.Dial(url)
	if err != nil {
		return nil, fmt.Errorf("failed to connect to rabbitmq: %w", err)
	}

	// Cria um canal
	channel, err := conn.Channel()
	if err != nil {
		conn.Close()
		return nil, fmt.Errorf("failed to open channel: %w", err)
	}

	// Declara o exchange
	err = channel.ExchangeDeclare(
		ExchangeName, // name
		ExchangeType, // type
		true,         // durable
		false,        // auto-deleted
		false,        // internal
		false,        // no-wait
		nil,          // arguments
	)
	if err != nil {
		channel.Close()
		conn.Close()
		return nil, fmt.Errorf("failed to declare exchange: %w", err)
	}

	logger.Info("connected to rabbitmq",
		zap.String("exchange", ExchangeName),
		zap.String("type", ExchangeType),
	)

	return &RabbitMQ{
		conn:    conn,
		channel: channel,
		logger:  logger,
	}, nil
}

// Close fecha a conexão com RabbitMQ
func (r *RabbitMQ) Close() error {
	if r.channel != nil {
		if err := r.channel.Close(); err != nil {
			r.logger.Error("error closing channel", zap.Error(err))
		}
	}
	if r.conn != nil {
		if err := r.conn.Close(); err != nil {
			r.logger.Error("error closing connection", zap.Error(err))
			return err
		}
	}
	return nil
}

// NewEventPublisher cria um novo publisher de eventos
func NewEventPublisher(rabbitmq *RabbitMQ, logger *zap.Logger) *EventPublisher {
	return &EventPublisher{
		rabbitmq: rabbitmq,
		logger:   logger,
		tracer:   otel.Tracer("transaction-service"),
	}
}

// PublishTransactionCreated publica um evento de transação criada
func (p *EventPublisher) PublishTransactionCreated(ctx context.Context, event TransactionCreatedEvent) error {
	ctx, span := p.tracer.Start(ctx, "PublishTransactionCreated")
	defer span.End()

	start := time.Now()

	// Adiciona timestamp ao evento
	event.Timestamp = time.Now()

	// Serializa o evento
	body, err := json.Marshal(event)
	if err != nil {
		span.RecordError(err)
		return fmt.Errorf("failed to marshal event: %w", err)
	}

	span.SetAttributes(
		attribute.String("transaction.id", event.TransactionID),
		attribute.String("user.id", event.UserID),
		attribute.String("routing_key", TransactionCreated),
		attribute.Int("message.size", len(body)),
	)

	// Publica a mensagem
	err = p.rabbitmq.channel.Publish(
		ExchangeName,       // exchange
		TransactionCreated, // routing key
		false,              // mandatory
		false,              // immediate
		amqp.Publishing{
			ContentType:  "application/json",
			Body:         body,
			DeliveryMode: amqp.Persistent, // Torna a mensagem persistente
			Timestamp:    time.Now(),
			Headers: amqp.Table{
				"trace_id": event.TraceID,
				"span_id":  event.SpanID,
			},
		},
	)

	if err != nil {
		span.RecordError(err)
		metrics.MessagesPublishedTotal.WithLabelValues(TransactionCreated, "error").Inc()
		p.logger.Error("failed to publish transaction created event",
			zap.Error(err),
			zap.String("transaction_id", event.TransactionID),
			zap.String("trace_id", event.TraceID),
		)
		return fmt.Errorf("failed to publish message: %w", err)
	}

	// Registra métricas
	duration := time.Since(start).Seconds()
	metrics.MessagesPublishedTotal.WithLabelValues(TransactionCreated, "success").Inc()
	metrics.MessagePublishDuration.WithLabelValues(TransactionCreated).Observe(duration)

	p.logger.Info("transaction created event published",
		zap.String("transaction_id", event.TransactionID),
		zap.String("user_id", event.UserID),
		zap.String("routing_key", TransactionCreated),
		zap.String("trace_id", event.TraceID),
		zap.Duration("duration", time.Since(start)),
	)

	return nil
}

// PublishTransactionUpdated publica um evento de transação atualizada
func (p *EventPublisher) PublishTransactionUpdated(ctx context.Context, transactionID, userID, traceID string) error {
	ctx, span := p.tracer.Start(ctx, "PublishTransactionUpdated")
	defer span.End()

	event := map[string]interface{}{
		"transaction_id": transactionID,
		"user_id":        userID,
		"trace_id":       traceID,
		"timestamp":      time.Now(),
	}

	body, err := json.Marshal(event)
	if err != nil {
		return fmt.Errorf("failed to marshal event: %w", err)
	}

	err = p.rabbitmq.channel.Publish(
		ExchangeName,
		TransactionUpdated,
		false,
		false,
		amqp.Publishing{
			ContentType:  "application/json",
			Body:         body,
			DeliveryMode: amqp.Persistent,
			Timestamp:    time.Now(),
			Headers: amqp.Table{
				"trace_id": traceID,
			},
		},
	)

	if err != nil {
		metrics.MessagesPublishedTotal.WithLabelValues(TransactionUpdated, "error").Inc()
		return fmt.Errorf("failed to publish message: %w", err)
	}

	metrics.MessagesPublishedTotal.WithLabelValues(TransactionUpdated, "success").Inc()
	return nil
}

// PublishTransactionDeleted publica um evento de transação deletada
func (p *EventPublisher) PublishTransactionDeleted(ctx context.Context, transactionID, userID, traceID string) error {
	ctx, span := p.tracer.Start(ctx, "PublishTransactionDeleted")
	defer span.End()

	event := map[string]interface{}{
		"transaction_id": transactionID,
		"user_id":        userID,
		"trace_id":       traceID,
		"timestamp":      time.Now(),
	}

	body, err := json.Marshal(event)
	if err != nil {
		return fmt.Errorf("failed to marshal event: %w", err)
	}

	err = p.rabbitmq.channel.Publish(
		ExchangeName,
		TransactionDeleted,
		false,
		false,
		amqp.Publishing{
			ContentType:  "application/json",
			Body:         body,
			DeliveryMode: amqp.Persistent,
			Timestamp:    time.Now(),
			Headers: amqp.Table{
				"trace_id": traceID,
			},
		},
	)

	if err != nil {
		metrics.MessagesPublishedTotal.WithLabelValues(TransactionDeleted, "error").Inc()
		return fmt.Errorf("failed to publish message: %w", err)
	}

	metrics.MessagesPublishedTotal.WithLabelValues(TransactionDeleted, "success").Inc()
	return nil
}

// PublishTransactionEvent publica um evento genérico de transação
func (p *EventPublisher) PublishTransactionEvent(event TransactionEvent) error {
	start := time.Now()

	// Determina a routing key baseada no tipo de evento
	routingKey := event.EventType

	// Serializa o evento
	body, err := json.Marshal(event)
	if err != nil {
		return fmt.Errorf("failed to marshal event: %w", err)
	}

	// Publica a mensagem
	err = p.rabbitmq.channel.Publish(
		ExchangeName, // exchange
		routingKey,   // routing key
		false,        // mandatory
		false,        // immediate
		amqp.Publishing{
			ContentType:  "application/json",
			Body:         body,
			DeliveryMode: amqp.Persistent,
			Timestamp:    time.Now(),
		},
	)

	if err != nil {
		metrics.MessagesPublishedTotal.WithLabelValues(routingKey, "error").Inc()
		metrics.MessagesPublishErrors.WithLabelValues(routingKey, "publish_failed").Inc()
		p.logger.Error("failed to publish transaction event",
			zap.Error(err),
			zap.String("event_type", event.EventType),
			zap.String("transaction_id", event.TransactionID),
		)
		return fmt.Errorf("failed to publish message: %w", err)
	}

	// Registra métricas
	duration := time.Since(start).Seconds()
	metrics.MessagesPublishedTotal.WithLabelValues(routingKey, "success").Inc()
	metrics.MessagePublishDuration.WithLabelValues(routingKey).Observe(duration)

	p.logger.Info("transaction event published",
		zap.String("event_type", event.EventType),
		zap.String("transaction_id", event.TransactionID),
		zap.String("user_id", event.UserID),
		zap.Duration("duration", time.Since(start)),
	)

	return nil
}
