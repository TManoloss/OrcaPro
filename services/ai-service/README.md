# AI Service - Categorização Inteligente de Transações

## 📋 Descrição

Serviço de IA que consome eventos do RabbitMQ e categoriza automaticamente transações financeiras usando Machine Learning.

## 🤖 Funcionalidades

- **Categorização Automática**: Usa TF-IDF + Naive Bayes para classificar transações
- **Aprendizado Contínuo**: Modelo pode ser retreinado com novos dados
- **Fallback Inteligente**: Sistema de regras baseado em keywords quando confiança é baixa
- **Observabilidade Completa**: Métricas Prometheus, tracing Jaeger, logs estruturados

## 🏗️ Arquitetura

```
RabbitMQ (transaction.created)
         ↓
    AI Service
         ↓
   Categorização ML
         ↓
  [Futuro: Atualizar Transaction]
```

## 📊 Categorias Suportadas

1. **Alimentação** - Restaurantes, supermercados, delivery
2. **Transporte** - Uber, combustível, estacionamento
3. **Moradia** - Aluguel, condomínio, contas
4. **Saúde** - Farmácia, médico, plano de saúde
5. **Educação** - Escola, cursos, livros
6. **Lazer** - Cinema, viagens, streaming
7. **Compras** - Roupas, eletrônicos, presentes
8. **Serviços** - Cabeleireiro, reparos
9. **Investimentos** - Aplicações, ações
10. **Salário** - Remuneração
11. **Outros** - Demais categorias

## 🔧 Tecnologias

- **Python 3.11**
- **scikit-learn** - Machine Learning
- **RabbitMQ (pika)** - Mensageria
- **Prometheus** - Métricas
- **OpenTelemetry/Jaeger** - Tracing distribuído

## 📈 Métricas Expostas

- `transactions_received_total` - Total de transações recebidas
- `transactions_categorized_total` - Total categorizadas por categoria
- `transactions_processing_errors_total` - Erros de processamento
- `categorization_duration_seconds` - Tempo de categorização
- `rabbitmq_connection_status` - Status da conexão RabbitMQ
- `ml_model_loaded` - Status do modelo ML

## 🚀 Como Executar

### Com Docker Compose

```bash
docker-compose up -d ai-service
```

### Localmente

```bash
cd services/ai-service

# Instalar dependências
pip install -r requirements.txt

# Configurar variáveis
export RABBITMQ_URL="amqp://admin:admin123@localhost:5672/"
export METRICS_PORT=8003

# Executar
python main.py
```

## 🧪 Testar

```bash
# Ver métricas
curl http://localhost:8003

# Ver logs
docker logs -f ai-service

# Publicar evento de teste no RabbitMQ
# (será consumido automaticamente)
```

## 🔄 Retreinar Modelo

O modelo pode ser retreinado com novos dados:

```python
from categorizer import TransactionCategorizer

categorizer = TransactionCategorizer()
categorizer.load_model()

# Novos dados de treinamento
new_data = [
    {'description': 'Compra no Carrefour', 'category': 'Alimentação'},
    {'description': 'Uber para o trabalho', 'category': 'Transporte'},
    # ... mais dados
]

categorizer.retrain(new_data)
```

## 📝 Variáveis de Ambiente

| Variável | Padrão | Descrição |
|----------|--------|-----------|
| `ENVIRONMENT` | `development` | Ambiente de execução |
| `RABBITMQ_URL` | `amqp://admin:admin123@rabbitmq:5672/` | URL do RabbitMQ |
| `JAEGER_ENDPOINT` | `http://jaeger:14268/api/traces` | Endpoint do Jaeger |
| `METRICS_PORT` | `8003` | Porta para métricas |
| `MODEL_PATH` | `/app/models/categorizer.pkl` | Caminho do modelo |
| `CONFIDENCE_THRESHOLD` | `0.5` | Threshold de confiança |
| `RETRAIN_INTERVAL` | `86400` | Intervalo de retreino (segundos) |

## 🎯 Próximos Passos

- [ ] Implementar callback para atualizar transaction-service
- [ ] API REST para categorização sob demanda
- [ ] Dashboard de acurácia do modelo
- [ ] Retreino automático periódico
- [ ] Suporte a múltiplos idiomas
- [ ] Deep Learning (BERT/Transformers)
- [ ] Detecção de anomalias
- [ ] Sugestões de economia

## 📊 Exemplo de Uso

```json
// Evento recebido do RabbitMQ
{
  "event_type": "transaction.created",
  "transaction_id": "123e4567-e89b-12d3-a456-426614174000",
  "user_id": "user-123",
  "description": "Pagamento Uber",
  "amount": 25.50,
  "category": "Outros",
  "type": "expense"
}

// Resultado da categorização
{
  "transaction_id": "123e4567-e89b-12d3-a456-426614174000",
  "predicted_category": "Transporte",
  "confidence": 0.92,
  "original_category": "Outros"
}
```

## 🐛 Troubleshooting

### Modelo não carrega
```bash
# Verificar se o diretório existe
docker exec ai-service ls -la /app/models/

# Recriar modelo
docker exec ai-service rm /app/models/categorizer.pkl
docker restart ai-service
```

### Não recebe mensagens
```bash
# Verificar conexão RabbitMQ
docker logs ai-service | grep "Conectado ao RabbitMQ"

# Verificar fila
docker exec rabbitmq rabbitmqctl list_queues
```

### Baixa acurácia
- Retreinar modelo com mais dados reais
- Ajustar threshold de confiança
- Adicionar mais keywords no fallback

---

**Status:** ✅ Implementado e funcional
