import os

class Config:
    """Configuração do AI Service"""
    
    def __init__(self):
        self.environment = os.getenv('ENVIRONMENT', 'development')
        self.rabbitmq_url = os.getenv('RABBITMQ_URL', 'amqp://admin:admin123@rabbitmq:5672/')
        self.jaeger_endpoint = os.getenv('JAEGER_ENDPOINT', 'http://jaeger:14268/api/traces')
        self.metrics_port = int(os.getenv('METRICS_PORT', '8003'))
        self.model_path = os.getenv('MODEL_PATH', '/app/models/categorizer.pkl')
        self.transaction_service_url = os.getenv('TRANSACTION_SERVICE_URL', 'http://transaction-service:8002')
        
        # RabbitMQ
        self.queue_name = os.getenv('QUEUE_NAME', 'ai_categorization_queue')
        self.exchange_name = os.getenv('EXCHANGE_NAME', 'transactions_exchange')
        self.routing_key = os.getenv('ROUTING_KEY', 'transaction.created')
        
        # ML
        self.confidence_threshold = float(os.getenv('CONFIDENCE_THRESHOLD', '0.5'))
        self.retrain_interval = int(os.getenv('RETRAIN_INTERVAL', '86400'))  # 24h em segundos