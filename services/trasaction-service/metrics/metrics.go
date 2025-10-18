package metrics

import (
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
)

var (
	// HTTP Request metrics
	HTTPRequestsTotal = promauto.NewCounterVec(
		prometheus.CounterOpts{
			Name: "http_requests_total",
			Help: "Total number of HTTP requests",
		},
		[]string{"method", "path", "status"},
	)

	HTTPRequestDuration = promauto.NewHistogramVec(
		prometheus.HistogramOpts{
			Name:    "http_request_duration_seconds",
			Help:    "HTTP request latencies in seconds",
			Buckets: prometheus.DefBuckets,
		},
		[]string{"method", "path", "status"},
	)

	// Transaction business metrics
	TransactionsCreatedTotal = promauto.NewCounterVec(
		prometheus.CounterOpts{
			Name: "transactions_created_total",
			Help: "Total number of transactions created",
		},
		[]string{"type", "category"},
	)

	TransactionsUpdatedTotal = promauto.NewCounter(
		prometheus.CounterOpts{
			Name: "transactions_updated_total",
			Help: "Total number of transactions updated",
		},
	)

	TransactionsDeletedTotal = promauto.NewCounter(
		prometheus.CounterOpts{
			Name: "transactions_deleted_total",
			Help: "Total number of transactions deleted",
		},
	)

	TransactionAmount = promauto.NewHistogramVec(
		prometheus.HistogramOpts{
			Name:    "transaction_amount",
			Help:    "Transaction amounts",
			Buckets: []float64{10, 50, 100, 500, 1000, 5000, 10000},
		},
		[]string{"type"},
	)

	// Database metrics
	DatabaseConnectionsActive = promauto.NewGauge(
		prometheus.GaugeOpts{
			Name: "database_connections_active",
			Help: "Number of active database connections",
		},
	)

	DatabaseQueryDuration = promauto.NewHistogramVec(
		prometheus.HistogramOpts{
			Name:    "database_query_duration_seconds",
			Help:    "Database query latencies in seconds",
			Buckets: prometheus.DefBuckets,
		},
		[]string{"query_type"},
	)

	// RabbitMQ metrics
	MessagesPublishedTotal = promauto.NewCounterVec(
		prometheus.CounterOpts{
			Name: "rabbitmq_messages_published_total",
			Help: "Total number of messages published to RabbitMQ",
		},
		[]string{"routing_key", "status"},
	)

	MessagePublishDuration = promauto.NewHistogramVec(
		prometheus.HistogramOpts{
			Name:    "rabbitmq_message_publish_duration_seconds",
			Help:    "Message publish latencies in seconds",
			Buckets: prometheus.DefBuckets,
		},
		[]string{"routing_key"},
	)

	MessagesPublishErrors = promauto.NewCounterVec(
		prometheus.CounterOpts{
			Name: "rabbitmq_messages_publish_errors_total",
			Help: "Total number of message publish errors",
		},
		[]string{"routing_key", "error_type"},
	)

	// Connection health
	RabbitMQConnectionStatus = promauto.NewGauge(
		prometheus.GaugeOpts{
			Name: "rabbitmq_connection_status",
			Help: "RabbitMQ connection status (1 = connected, 0 = disconnected)",
		},
	)
)