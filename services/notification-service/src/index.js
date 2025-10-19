const amqp = require('amqplib');
const express = require('express');
const prometheus = require('prom-client');
const { trace, context } = require('@opentelemetry/api');
const { NodeTracerProvider } = require('@opentelemetry/sdk-trace-node');
const { JaegerExporter } = require('@opentelemetry/exporter-jaeger');
const { BatchSpanProcessor } = require('@opentelemetry/sdk-trace-base');
const { Resource } = require('@opentelemetry/resources');
const { SemanticResourceAttributes } = require('@opentelemetry/semantic-conventions');
const winston = require('winston');
const nodemailer = require('nodemailer');

// ============================================
// CONFIGURAÇÃO
// ============================================

const config = {
    environment: process.env.ENVIRONMENT || 'development',
    rabbitmqUrl: process.env.RABBITMQ_URL || 'amqp://admin:admin123@rabbitmq:5672/',
    jaegerEndpoint: process.env.JAEGER_ENDPOINT || 'http://jaeger:14268/api/traces',
    metricsPort: parseInt(process.env.METRICS_PORT || '8004'),
    highAmountThreshold: parseFloat(process.env.HIGH_AMOUNT_THRESHOLD || '1000'),
    smtpHost: process.env.SMTP_HOST || 'smtp.gmail.com',
    smtpPort: parseInt(process.env.SMTP_PORT || '587'),
    smtpUser: process.env.SMTP_USER || '',
    smtpPass: process.env.SMTP_PASS || '',
    emailFrom: process.env.EMAIL_FROM || 'noreply@financeapp.com'
};

// ============================================
// LOGGING ESTRUTURADO
// ============================================

const logger = winston.createLogger({
    format: winston.format.combine(
        winston.format.timestamp(),
        winston.format.json()
    ),
    defaultMeta: { service: 'notification-service' },
    transports: [
        new winston.transports.Console()
    ]
});

// ============================================
// TRACING
// ============================================

function initTracing() {
    const provider = new NodeTracerProvider({
        resource: new Resource({
            [SemanticResourceAttributes.SERVICE_NAME]: 'notification-service',
            [SemanticResourceAttributes.SERVICE_VERSION]: '1.0.0'
        })
    });

    const jaegerExporter = new JaegerExporter({
        endpoint: config.jaegerEndpoint
    });

    provider.addSpanProcessor(new BatchSpanProcessor(jaegerExporter));
    provider.register();

    return trace.getTracer('notification-service');
}

const tracer = initTracing();

// ============================================
// MÉTRICAS PROMETHEUS
// ============================================

const register = new prometheus.Registry();

prometheus.collectDefaultMetrics({ register });

const notificationsReceivedTotal = new prometheus.Counter({
    name: 'notifications_received_total',
    help: 'Total de eventos recebidos para notificação',
    registers: [register]
});

const notificationsSentTotal = new prometheus.Counter({
    name: 'notifications_sent_total',
    help: 'Total de notificações enviadas',
    labelNames: ['type', 'status'],
    registers: [register]
});

const notificationProcessingDuration = new prometheus.Histogram({
    name: 'notification_processing_duration_seconds',
    help: 'Tempo de processamento de notificações',
    registers: [register]
});

const notificationErrors = new prometheus.Counter({
    name: 'notification_errors_total',
    help: 'Total de erros ao processar notificações',
    labelNames: ['error_type'],
    registers: [register]
});

const rabbitmqConnectionStatus = new prometheus.Gauge({
    name: 'rabbitmq_connection_status',
    help: 'Status da conexão RabbitMQ (1=conectado, 0=desconectado)',
    registers: [register]
});

// ============================================
// EMAIL SERVICE
// ============================================

class EmailService {
    constructor() {
        this.transporter = null;
        this.initTransporter();
    }

    initTransporter() {
        if (!config.smtpUser || !config.smtpPass) {
            logger.warn('SMTP credentials not configured, email notifications disabled');
            return;
        }

        this.transporter = nodemailer.createTransporter({
            host: config.smtpHost,
            port: config.smtpPort,
            secure: false,
            auth: {
                user: config.smtpUser,
                pass: config.smtpPass
            }
        });

        logger.info('Email transporter initialized', { host: config.smtpHost });
    }

    async sendHighAmountAlert(userEmail, transaction) {
        if (!this.transporter) {
            logger.warn('Email transporter not configured, skipping email');
            return { success: false, reason: 'not_configured' };
        }

        try {
            const mailOptions = {
                from: config.emailFrom,
                to: userEmail,
                subject: '🚨 Alerta: Transação de Alto Valor',
                html: `
                    <h2>Alerta de Transação</h2>
                    <p>Uma transação de alto valor foi detectada em sua conta:</p>
                    <ul>
                        <li><strong>Descrição:</strong> ${transaction.description}</li>
                        <li><strong>Valor:</strong> R$ ${transaction.amount.toFixed(2)}</li>
                        <li><strong>Categoria:</strong> ${transaction.category}</li>
                        <li><strong>Data:</strong> ${new Date(transaction.date).toLocaleString('pt-BR')}</li>
                    </ul>
                    <p>Se você não reconhece esta transação, entre em contato conosco imediatamente.</p>
                `
            };

            const info = await this.transporter.sendMail(mailOptions);
            
            logger.info('High amount alert email sent', {
                user_email: userEmail,
                transaction_id: transaction.transaction_id,
                message_id: info.messageId
            });

            return { success: true, messageId: info.messageId };

        } catch (error) {
            logger.error('Error sending email', {
                error: error.message,
                user_email: userEmail,
                transaction_id: transaction.transaction_id
            });

            return { success: false, error: error.message };
        }
    }

    async sendBudgetAlert(userEmail, data) {
        if (!this.transporter) {
            return { success: false, reason: 'not_configured' };
        }

        try {
            const mailOptions = {
                from: config.emailFrom,
                to: userEmail,
                subject: '⚠️ Alerta de Orçamento',
                html: `
                    <h2>Alerta de Orçamento</h2>
                    <p>Você atingiu ${data.percentage}% do seu orçamento mensal:</p>
                    <ul>
                        <li><strong>Categoria:</strong> ${data.category}</li>
                        <li><strong>Gasto Atual:</strong> R$ ${data.current_amount.toFixed(2)}</li>
                        <li><strong>Orçamento:</strong> R$ ${data.budget_limit.toFixed(2)}</li>
                    </ul>
                `
            };

            const info = await this.transporter.sendMail(mailOptions);
            
            logger.info('Budget alert email sent', {
                user_email: userEmail,
                message_id: info.messageId
            });

            return { success: true, messageId: info.messageId };

        } catch (error) {
            logger.error('Error sending budget alert', {
                error: error.message,
                user_email: userEmail
            });

            return { success: false, error: error.message };
        }
    }
}

// ============================================
// NOTIFICATION SERVICE
// ============================================

class NotificationService {
    constructor() {
        this.connection = null;
        this.channel = null;
        this.emailService = new EmailService();
        this.shouldStop = false;
    }

    async connectRabbitMQ() {
        try {
            this.connection = await amqp.connect(config.rabbitmqUrl);
            this.channel = await this.connection.createChannel();

            // Declara exchange
            await this.channel.assertExchange('transactions_exchange', 'topic', {
                durable: true
            });

            // Declara fila para notificações
            const queueName = 'notification_queue';
            await this.channel.assertQueue(queueName, {
                durable: true,
                arguments: {
                    'x-message-ttl': 86400000, // 24 horas
                    'x-max-length': 10000
                }
            });

            // Bind para eventos de transações
            await this.channel.bindQueue(queueName, 'transactions_exchange', 'transaction.created');
            await this.channel.bindQueue(queueName, 'transactions_exchange', 'budget.exceeded');
            await this.channel.bindQueue(queueName, 'transactions_exchange', 'goal.achieved');

            // Configura prefetch
            await this.channel.prefetch(1);

            rabbitmqConnectionStatus.set(1);

            logger.info('Connected to RabbitMQ', {
                queue: queueName,
                exchange: 'transactions_exchange'
            });

            return queueName;

        } catch (error) {
            rabbitmqConnectionStatus.set(0);
            logger.error('Error connecting to RabbitMQ', { error: error.message });
            throw error;
        }
    }

    async processMessage(msg) {
        const startTime = Date.now();
        let traceId = null;

        try {
            const message = JSON.parse(msg.content.toString());
            
            // Extrai trace_id
            traceId = msg.properties.headers?.trace_id || message.trace_id;

            notificationsReceivedTotal.inc();

            logger.info('Message received', {
                routing_key: msg.fields.routingKey,
                transaction_id: message.transaction_id,
                trace_id: traceId
            });

            // Inicia span
            const span = tracer.startSpan('process_notification', {
                attributes: {
                    'notification.routing_key': msg.fields.routingKey,
                    'transaction.id': message.transaction_id || '',
                    'trace.parent_id': traceId || ''
                }
            });

            // Processa baseado no routing key
            let result;
            switch (msg.fields.routingKey) {
                case 'transaction.created':
                    result = await this.handleTransactionCreated(message);
                    break;
                case 'budget.exceeded':
                    result = await this.handleBudgetExceeded(message);
                    break;
                case 'goal.achieved':
                    result = await this.handleGoalAchieved(message);
                    break;
                default:
                    logger.warn('Unknown routing key', { routing_key: msg.fields.routingKey });
                    result = { success: false, reason: 'unknown_routing_key' };
            }

            span.end();

            // Registra métricas
            const duration = (Date.now() - startTime) / 1000;
            notificationProcessingDuration.observe(duration);

            if (result.success) {
                notificationsSentTotal.labels(
                    msg.fields.routingKey,
                    'success'
                ).inc();
                this.channel.ack(msg);
            } else {
                notificationsSentTotal.labels(
                    msg.fields.routingKey,
                    'failed'
                ).inc();
                // Requeue se falhar
                this.channel.nack(msg, false, true);
            }

        } catch (error) {
            notificationErrors.labels(error.name || 'unknown').inc();
            
            logger.error('Error processing message', {
                error: error.message,
                stack: error.stack,
                trace_id: traceId
            });

            // Reject sem requeue para mensagens inválidas
            this.channel.nack(msg, false, false);
        }
    }

    async handleTransactionCreated(message) {
        const { amount, description, user_email } = message;

        // Verifica se é transação de alto valor
        if (amount > config.highAmountThreshold) {
            logger.info('High amount transaction detected', {
                transaction_id: message.transaction_id,
                amount,
                threshold: config.highAmountThreshold
            });

            // Envia alerta por email (se configurado)
            if (user_email) {
                const result = await this.emailService.sendHighAmountAlert(user_email, message);
                return result;
            } else {
                logger.warn('User email not provided, skipping email notification');
            }

            // Aqui você pode adicionar outras formas de notificação:
            // - Push notification via Firebase
            // - SMS via Twilio
            // - Webhook para sistemas externos
        }

        return { success: true, notified: false };
    }

    async handleBudgetExceeded(message) {
        logger.info('Budget exceeded event received', {
            user_id: message.user_id,
            category: message.category
        });

        if (message.user_email) {
            return await this.emailService.sendBudgetAlert(message.user_email, message);
        }

        return { success: true, notified: false };
    }

    async handleGoalAchieved(message) {
        logger.info('Goal achieved event received', {
            user_id: message.user_id,
            goal: message.goal_name
        });

        // Implementar notificação de meta atingida
        return { success: true, notified: false };
    }

    async startConsuming() {
        try {
            const queueName = await this.connectRabbitMQ();

            await this.channel.consume(queueName, (msg) => {
                if (msg) {
                    this.processMessage(msg);
                }
            }, { noAck: false });

            logger.info('Waiting for messages...', { queue: queueName });

            // Keep alive
            while (!this.shouldStop) {
                await new Promise(resolve => setTimeout(resolve, 1000));
            }

        } catch (error) {
            logger.error('Error in consumer loop', { error: error.message });
            throw error;
        }
    }

    async cleanup() {
        logger.info('Shutting down notification service...');

        this.shouldStop = true;

        if (this.channel) {
            await this.channel.close();
        }

        if (this.connection) {
            await this.connection.close();
        }

        rabbitmqConnectionStatus.set(0);
        logger.info('Notification service shut down');
    }
}

// ============================================
// HTTP SERVER (METRICS)
// ============================================

const app = express();

app.get('/metrics', async (req, res) => {
    res.set('Content-Type', register.contentType);
    res.end(await register.metrics());
});

app.get('/health', (req, res) => {
    res.json({
        status: 'healthy',
        service: 'notification-service',
        timestamp: Date.now()
    });
});

app.listen(config.metricsPort, () => {
    logger.info('Metrics server started', { port: config.metricsPort });
});

// ============================================
// MAIN
// ============================================

const notificationService = new NotificationService();

// Graceful shutdown
process.on('SIGINT', async () => {
    logger.info('SIGINT received');
    await notificationService.cleanup();
    process.exit(0);
});

process.on('SIGTERM', async () => {
    logger.info('SIGTERM received');
    await notificationService.cleanup();
    process.exit(0);
});

// Start consuming
notificationService.startConsuming().catch((error) => {
    logger.error('Fatal error', { error: error.message });
    process.exit(1);
});