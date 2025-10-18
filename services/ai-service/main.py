import os
import sys
import json
import signal
import logging
from typing import Dict, Any
from datetime import datetime

import pika
from prometheus_client import Counter, Histogram, Gauge, start_http_server
from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.exporter.jaeger.thrift import JaegerExporter
from opentelemetry.sdk.resources import Resource

from categorizer import TransactionCategorizer
from config import Config

# Configuração de logging estruturado
logging.basicConfig(
    level=logging.INFO,
    format='%(message)s',
    handlers=[logging.StreamHandler(sys.stdout)]
)

class StructuredLogger:
    """Logger estruturado em JSON"""
    
    def __init__(self, service_name: str):
        self.service_name = service_name
    
    def _log(self, level: str, message: str, **kwargs):
        log_entry = {
            "timestamp": datetime.utcnow().isoformat(),
            "level": level,
            "service": self.service_name,
            "message": message,
            **kwargs
        }
        print(json.dumps(log_entry))
    
    def info(self, message: str, **kwargs):
        self._log("info", message, **kwargs)
    
    def error(self, message: str, **kwargs):
        self._log("error", message, **kwargs)
    
    def warning(self, message: str, **kwargs):
        self._log("warning", message, **kwargs)
    
    def debug(self, message: str, **kwargs):
        self._log("debug", message, **kwargs)

logger = StructuredLogger("ai-service")

# Métricas Prometheus
transactions_received_total = Counter(
    'transactions_received_total',
    'Total de transações recebidas do RabbitMQ'
)

transactions_categorized_total = Counter(
    'transactions_categorized_total',
    'Total de transações categorizadas',
    ['category']
)

transactions_processing_errors = Counter(
    'transactions_processing_errors_total',
    'Total de erros ao processar transações',
    ['error_type']
)

categorization_duration = Histogram(
    'categorization_duration_seconds',
    'Tempo de categorização em segundos'
)

rabbitmq_connection_status = Gauge(
    'rabbitmq_connection_status',
    'Status da conexão com RabbitMQ (1=conectado, 0=desconectado)'
)

ml_model_loaded = Gauge(
    'ml_model_loaded',
    'Status do modelo ML (1=carregado, 0=não carregado)'
)

# Inicializa OpenTelemetry
def init_tracing():
    """Inicializa distributed tracing com Jaeger"""
    jaeger_endpoint = os.getenv("JAEGER_ENDPOINT", "http://jaeger:14268/api/traces")
    
    resource = Resource.create({
        "service.name": "ai-service",
        "service.version": "1.0.0"
    })
    
    tracer_provider = TracerProvider(resource=resource)
    
    jaeger_exporter = JaegerExporter(
        collector_endpoint=jaeger_endpoint.replace("/api/traces", ""),
        agent_host_name=None,
    )
    
    tracer_provider.add_span_processor(
        BatchSpanProcessor(jaeger_exporter)
    )
    
    trace.set_tracer_provider(tracer_provider)
    
    return trace.get_tracer(__name__)

tracer = init_tracing()

class AIServiceConsumer:
    """Consumer do RabbitMQ para processar eventos de transações"""
    
    def __init__(self):
        self.config = Config()
        self.categorizer = TransactionCategorizer()
        self.connection = None
        self.channel = None
        self.should_stop = False
        
        logger.info("AI Service iniciado", 
                   environment=self.config.environment,
                   rabbitmq_url=self.config.rabbitmq_url.split('@')[1] if '@' in self.config.rabbitmq_url else self.config.rabbitmq_url)
        
        # Carrega modelo ML
        try:
            self.categorizer.load_model()
            ml_model_loaded.set(1)
            logger.info("Modelo ML carregado com sucesso")
        except Exception as e:
            ml_model_loaded.set(0)
            logger.error("Erro ao carregar modelo ML", error=str(e))
            raise
    
    def connect_rabbitmq(self):
        """Estabelece conexão com RabbitMQ"""
        try:
            parameters = pika.URLParameters(self.config.rabbitmq_url)
            parameters.heartbeat = 600
            parameters.blocked_connection_timeout = 300
            
            self.connection = pika.BlockingConnection(parameters)
            self.channel = self.connection.channel()
            
            # Declara exchange
            self.channel.exchange_declare(
                exchange='transactions_exchange',
                exchange_type='topic',
                durable=True
            )
            
            # Declara fila
            queue_name = 'ai_categorization_queue'
            self.channel.queue_declare(
                queue=queue_name,
                durable=True,
                arguments={
                    'x-message-ttl': 86400000,  # 24 horas
                    'x-max-length': 10000
                }
            )
            
            # Bind fila ao exchange
            self.channel.queue_bind(
                exchange='transactions_exchange',
                queue=queue_name,
                routing_key='transaction.created'
            )
            
            # Configura QoS (prefetch)
            self.channel.basic_qos(prefetch_count=1)
            
            rabbitmq_connection_status.set(1)
            logger.info("Conectado ao RabbitMQ", 
                       queue=queue_name,
                       routing_key='transaction.created')
            
            return queue_name
            
        except Exception as e:
            rabbitmq_connection_status.set(0)
            logger.error("Erro ao conectar ao RabbitMQ", error=str(e))
            raise
    
    def process_message(self, ch, method, properties, body):
        """Processa mensagem recebida do RabbitMQ"""
        trace_id = None
        span_id = None
        
        try:
            # Deserializa mensagem
            message = json.loads(body.decode('utf-8'))
            
            # Extrai trace_id e span_id dos headers
            if properties.headers:
                trace_id = properties.headers.get('trace_id')
                span_id = properties.headers.get('span_id')
            
            # Fallback para trace_id no body
            if not trace_id and 'trace_id' in message:
                trace_id = message['trace_id']
            
            transactions_received_total.inc()
            
            logger.info("Mensagem recebida",
                       transaction_id=message.get('transaction_id'),
                       user_id=message.get('user_id'),
                       trace_id=trace_id)
            
            # Inicia span de tracing
            with tracer.start_as_current_span("process_transaction") as span:
                span.set_attribute("transaction.id", message.get('transaction_id', ''))
                span.set_attribute("user.id", message.get('user_id', ''))
                
                if trace_id:
                    span.set_attribute("parent.trace_id", trace_id)
                
                # Categoriza transação
                with categorization_duration.time():
                    category = self.categorizer.categorize(
                        description=message.get('description', ''),
                        amount=message.get('amount', 0.0),
                        current_category=message.get('category', '')
                    )
                
                span.set_attribute("category.predicted", category)
                
                transactions_categorized_total.labels(category=category).inc()
                
                logger.info("Transação categorizada",
                           transaction_id=message.get('transaction_id'),
                           original_category=message.get('category'),
                           predicted_category=category,
                           confidence=self.categorizer.last_confidence,
                           trace_id=trace_id)
                
                # TODO: Publicar evento de categorização concluída ou
                # chamar API do transaction-service para atualizar
                
                # Acknowledge da mensagem
                ch.basic_ack(delivery_tag=method.delivery_tag)
                
        except json.JSONDecodeError as e:
            transactions_processing_errors.labels(error_type='json_decode').inc()
            logger.error("Erro ao decodificar JSON",
                        error=str(e),
                        body=body.decode('utf-8')[:200],
                        trace_id=trace_id)
            # Reject e não requeue mensagens inválidas
            ch.basic_reject(delivery_tag=method.delivery_tag, requeue=False)
            
        except Exception as e:
            transactions_processing_errors.labels(error_type='processing').inc()
            logger.error("Erro ao processar mensagem",
                        error=str(e),
                        error_type=type(e).__name__,
                        trace_id=trace_id)
            # Reject e requeue para tentar novamente
            ch.basic_nack(delivery_tag=method.delivery_tag, requeue=True)
    
    def start_consuming(self):
        """Inicia consumo de mensagens"""
        try:
            queue_name = self.connect_rabbitmq()
            
            self.channel.basic_consume(
                queue=queue_name,
                on_message_callback=self.process_message,
                auto_ack=False
            )
            
            logger.info("Aguardando mensagens...", queue=queue_name)
            
            # Loop de consumo
            while not self.should_stop:
                self.connection.process_data_events(time_limit=1)
                
        except KeyboardInterrupt:
            logger.info("Interrompido pelo usuário")
        except Exception as e:
            logger.error("Erro no loop de consumo", error=str(e))
            raise
        finally:
            self.cleanup()
    
    def cleanup(self):
        """Limpa recursos"""
        logger.info("Encerrando AI Service...")
        
        if self.channel and self.channel.is_open:
            self.channel.close()
        
        if self.connection and self.connection.is_open:
            self.connection.close()
        
        rabbitmq_connection_status.set(0)
        logger.info("AI Service encerrado")
    
    def signal_handler(self, signum, frame):
        """Handler para sinais de sistema"""
        logger.info("Sinal recebido", signal=signum)
        self.should_stop = True

def main():
    """Função principal"""
    # Inicia servidor de métricas Prometheus
    metrics_port = int(os.getenv("METRICS_PORT", "8003"))
    start_http_server(metrics_port)
    logger.info("Servidor de métricas iniciado", port=metrics_port)
    
    # Cria consumer
    consumer = AIServiceConsumer()
    
    # Registra handlers de sinais
    signal.signal(signal.SIGINT, consumer.signal_handler)
    signal.signal(signal.SIGTERM, consumer.signal_handler)
    
    # Inicia consumo
    consumer.start_consuming()

if __name__ == "__main__":
    main()