# 🤖 Fase 2: Reatividade, Inteligência e Notificações

## 🎯 O Que Foi Implementado

### AI Service (Python) - O Cérebro Analítico
✅ Consumer do RabbitMQ para eventos `transaction.created`  
✅ Categorização automática usando Machine Learning  
✅ Modelo TF-IDF + Naive Bayes  
✅ Fallback para categorização baseada em regras  
✅ Logging estruturado em JSON  
✅ Métricas Prometheus customizadas  
✅ Distributed tracing com OpenTelemetry  
✅ Persistência do modelo ML  

### Notification Service (Node.js) - A Voz do Sistema
✅ Consumer do RabbitMQ para múltiplos eventos  
✅ Alertas de transações de alto valor  
✅ Notificações por email (SMTP)  
✅ Extensível para push notifications e SMS  
✅ Logging estruturado com Winston  
✅ Métricas Prometheus  
✅ Distributed tracing  

---

## 🏗️ Arquitetura Event-Driven

```
┌──────────────────────────────────────────────────────┐
│                  OBSERVABILIDADE                     │
│      Grafana │ Prometheus │ Jaeger │ Loki          │
└──────────────────────────────────────────────────────┘
                         ▲
                         │ métricas/logs/traces
                         │
┌──────────────────────────────────────────────────────┐
│                   MICROSSERVIÇOS                     │
│                                                       │
│  Auth ──→ Transaction ──→ RabbitMQ ──→ AI Service   │
│  (8001)     (8002)          Exchange    (8003)       │
│                                │                      │
│                                └──→ Notification     │
│                                      Service (8004)   │
└──────────────────────────────────────────────────────┘
         │              │
         ▼              ▼
    PostgreSQL      Redis
```

### Fluxo de Eventos

```
1. Usuário cria transação
   POST /api/v1/transactions
          ↓
2. Transaction Service salva no DB
          ↓
3. Publica evento "transaction.created" no RabbitMQ
          ↓
4. AI Service consome evento
   - Categoriza transação com ML
   - Loga resultado
          ↓
5. Notification Service consome evento
   - Verifica se é alto valor
   - Envia email se necessário
```

---

## 🚀 Como Usar

### 1. Atualizar Infraestrutura

```bash
# Subir novos serviços
docker-compose up -d ai-service notification-service

# Verificar status
docker-compose ps

# Ver logs
docker-compose logs -f ai-service
docker-compose logs -f notification-service
```

### 2. Teste Completo do Fluxo

```bash
# 1. Fazer login
TOKEN=$(curl -s -X POST http://localhost:8001/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"user@test.com","password":"senha123"}' \
  | jq -r '.access_token')

# 2. Criar transação (será categorizada automaticamente)
curl -X POST http://localhost:8002/api/v1/transactions \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "description": "Uber para o aeroporto",
    "amount": 45.00,
    "category": "Outros",
    "type": "expense"
  }'

# 3. Verificar logs do AI Service
docker-compose logs ai-service | grep "categorizada"

# 4. Criar transação de alto valor (dispara notificação)
curl -X POST http://localhost:8002/api/v1/transactions \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "description": "Pagamento de aluguel",
    "amount": 1500.00,
    "category": "Moradia",
    "type": "expense"
  }'

#