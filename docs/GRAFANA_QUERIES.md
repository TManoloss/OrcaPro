# 📊 Grafana - Queries e Dashboards

Guia completo de queries úteis para monitoramento dos microsserviços.

## 🎯 Prometheus Queries

### HTTP Metrics

#### Taxa de Requisições por Segundo
```promql
# Por serviço
rate(http_requests_total[5m])

# Por serviço e endpoint
sum by(service, path) (rate(http_requests_total[5m]))

# Total geral
sum(rate(http_requests_total[5m]))
```

#### Taxa de Erros
```promql
# Percentual de erros 5xx
sum(rate(http_requests_total{status=~"5.."}[5m])) / sum(rate(http_requests_total[5m])) * 100

# Erros por serviço
sum by(service) (rate(http_requests_total{status=~"5.."}[5m]))

# Erros 4xx vs 5xx
sum by(status) (rate(http_requests_total{status=~"[45].."}[5m]))
```

#### Latência (Percentis)
```promql
# P50 (mediana)
histogram_quantile(0.50, rate(http_request_duration_seconds_bucket[5m]))

# P95
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))

# P99
histogram_quantile(0.99, rate(http_request_duration_seconds_bucket[5m]))

# Por endpoint
histogram_quantile(0.95, sum by(path, le) (rate(http_request_duration_seconds_bucket[5m])))
```

#### Requisições mais lentas
```promql
# Top 5 endpoints mais lentos (P95)
topk(5, histogram_quantile(0.95, sum by(path, le) (rate(http_request_duration_seconds_bucket[5m]))))
```

### Business Metrics

#### Auth Service
```promql
# Total de usuários registrados
user_registrations_total

# Taxa de registros por hora
increase(user_registrations_total[1h])

# Taxa de logins bem-sucedidos
rate(user_logins_total[5m])

# Taxa de tentativas de login falhas
rate(failed_login_attempts_total[5m])

# Ratio de falhas de login
rate(failed_login_attempts_total[5m]) / rate(user_logins_total[5m])

# Sessões ativas
active_sessions

# Tokens gerados por minuto
rate(jwt_tokens_generated_total[1m]) * 60

# Taxa de sucesso de validação de tokens
rate(jwt_tokens_validated_total{result="success"}[5m]) / rate(jwt_tokens_validated_total[5m]) * 100
```

#### Transaction Service
```promql
# Total de transações criadas
transactions_created_total

# Transações criadas por tipo
sum by(type) (transactions_created_total)

# Transações criadas por categoria
sum by(category) (transactions_created_total)

# Taxa de criação de transações
rate(transactions_created_total[5m])

# Transações criadas na última hora
increase(transactions_created_total[1h])

# Transações atualizadas
transactions_updated_total

# Transações deletadas
transactions_deleted_total

# Distribuição de valores de transações
histogram_quantile(0.95, rate(transaction_amount_bucket[5m]))
```

### RabbitMQ Metrics
```promql
# Mensagens publicadas com sucesso
rate(rabbitmq_messages_published_total{status="success"}[5m])

# Taxa de erros de publicação
rate(rabbitmq_messages_published_total{status="error"}[5m])

# Percentual de sucesso
rate(rabbitmq_messages_published_total{status="success"}[5m]) / rate(rabbitmq_messages_published_total[5m]) * 100

# Latência de publicação (P95)
histogram_quantile(0.95, rate(rabbitmq_message_publish_duration_seconds_bucket[5m]))

# Status da conexão (1=conectado, 0=desconectado)
rabbitmq_connection_status

# Mensagens por routing key
sum by(routing_key) (rate(rabbitmq_messages_published_total[5m]))
```

### Database Metrics
```promql
# Conexões ativas
database_connections_active

# Latência de queries (P95)
histogram_quantile(0.95, rate(database_query_duration_seconds_bucket[5m]))

# Queries mais lentas por tipo
topk(5, histogram_quantile(0.95, sum by(query_type, le) (rate(database_query_duration_seconds_bucket[5m]))))
```

### Redis Metrics
```promql
# Latência de operações no Redis (P95)
histogram_quantile(0.95, rate(redis_operation_duration_seconds_bucket[5m]))

# Operações por segundo
rate(redis_operation_duration_seconds_count[5m])
```

## 📈 Dashboards Recomendados

### Dashboard 1: Overview Geral

**Linha 1: Golden Signals**
- Taxa de Requisições (gauge)
- Taxa de Erros (gauge)
- Latência P95 (gauge)
- Saturação - Conexões DB (gauge)

**Linha 2: Gráficos de Tempo**
- Requisições/s por serviço (graph)
- Taxa de erros ao longo do tempo (graph)
- Latência P50/P95/P99 (graph)

**Linha 3: Business Metrics**
- Usuários registrados (stat)
- Logins/hora (stat)
- Transações criadas/hora (stat)
- Sessões ativas (stat)

### Dashboard 2: Auth Service

```json
{
  "panels": [
    {
      "title": "Registros de Usuários",
      "targets": [{
        "expr": "user_registrations_total"
      }]
    },
    {
      "title": "Taxa de Logins (req/s)",
      "targets": [{
        "expr": "rate(user_logins_total[5m])"
      }]
    },
    {
      "title": "Tentativas de Login Falhas",
      "targets": [{
        "expr": "rate(failed_login_attempts_total[5m])"
      }]
    },
    {
      "title": "Sessões Ativas",
      "targets": [{
        "expr": "active_sessions"
      }]
    },
    {
      "title": "Latência de Requisições",
      "targets": [
        {
          "expr": "histogram_quantile(0.50, rate(http_request_duration_seconds_bucket{service=\"auth-service\"}[5m]))",
          "legendFormat": "P50"
        },
        {
          "expr": "histogram_quantile(0.95, rate(http_request_duration_seconds_bucket{service=\"auth-service\"}[5m]))",
          "legendFormat": "P95"
        },
        {
          "expr": "histogram_quantile(0.99, rate(http_request_duration_seconds_bucket{service=\"auth-service\"}[5m]))",
          "legendFormat": "P99"
        }
      ]
    }
  ]
}
```

### Dashboard 3: Transaction Service

```promql
# Panel 1: Transações Criadas por Tipo
sum by(type) (transactions_created_total)

# Panel 2: Transações por Categoria (Top 10)
topk(10, sum by(category) (transactions_created_total))

# Panel 3: Taxa de Criação de Transações
rate(transactions_created_total[5m])

# Panel 4: Distribuição de Valores
histogram_quantile(0.50, rate(transaction_amount_bucket[5m]))

# Panel 5: RabbitMQ - Mensagens Publicadas
rate(rabbitmq_messages_published_total{status="success"}[5m])

# Panel 6: Latência do RabbitMQ
histogram_quantile(0.95, rate(rabbitmq_message_publish_duration_seconds_bucket[5m]))
```

### Dashboard 4: RabbitMQ Deep Dive

```promql
# Panel 1: Taxa de Publicação por Routing Key
sum by(routing_key) (rate(rabbitmq_messages_published_total[5m]))

# Panel 2: Taxa de Erros
rate(rabbitmq_messages_publish_errors_total[5m])

# Panel 3: Status da Conexão
rabbitmq_connection_status

# Panel 4: Latência de Publicação (percentis)
histogram_quantile(0.50, rate(rabbitmq_message_publish_duration_seconds_bucket[5m]))
histogram_quantile(0.95, rate(rabbitmq_message_publish_duration_seconds_bucket[5m]))
histogram_quantile(0.99, rate(rabbitmq_message_publish_duration_seconds_bucket[5m]))
```

## 🔍 Loki Queries (LogQL)

### Queries Básicas

```logql
# Todos os logs de um serviço
{service="auth-service"}

# Logs de múltiplos serviços
{service=~"auth-service|transaction-service"}

# Logs de erro
{} |= "error"

# Logs com level específico (JSON)
{} | json | level="error"

# Logs de um usuário específico
{} | json | user_id="abc-123"
```

### Queries Avançadas

```logql
# Logs de um trace_id específico
{} | json | trace_id="4bf92f3577b34da6a3ce929d0e0e4736"

# Logs de criação de transações
{service="transaction-service"} |= "transaction created"

# Logs de autenticação
{service="auth-service"} |= "logged in" or "login failed"

# Rate de erros nos últimos 5 minutos
rate({} | json | level="error" [5m])

# Count de erros agrupados por serviço
sum by(service) (count_over_time({} | json | level="error" [5m]))

# Logs com latência alta
{} | json | duration > 1s

# Logs de um endpoint específico
{} | json | path="/api/v1/transactions"

# Pattern extraction
{service="auth-service"} | pattern "<_> user_id=<user_id> <_>"
```

### Queries para Debugging

```logql
# Erros de conexão com banco
{} |~ "(?i)database.*error|connection.*refused"

# Erros do RabbitMQ
{service="transaction-service"} |= "rabbitmq" |= "error"

# Requests lentas (> 1 segundo)
{} | json | latency > "1s"

# Failed login attempts
{service="auth-service"} |= "invalid password" or "user not found"

# Todos os eventos de uma requisição (usando trace_id)
{} | json | trace_id="abc123" | line_format "{{.timestamp}} [{{.level}}] {{.service}} - {{.message}}"
```

### Agregações e Estatísticas

```logql
# Contagem de logs por nível
sum by(level) (count_over_time({} | json [5m]))

# Top 10 endpoints com mais erros
topk(10, sum by(path) (count_over_time({} | json | level="error" [1h])))

# Latência média por endpoint
avg_over_time({} | json | unwrap latency [5m]) by (path)

# Rate de logs por serviço
sum by(service) (rate({} [5m]))
```

## 📊 Alertas Importantes

### Alertas de SLA

```yaml
# Alert 1: Alta taxa de erros (> 5%)
groups:
  - name: sla_alerts
    interval: 30s
    rules:
      - alert: HighErrorRate
        expr: |
          (
            sum(rate(http_requests_total{status=~"5.."}[5m]))
            /
            sum(rate(http_requests_total[5m]))
          ) * 100 > 5
        for: 2m
        labels:
          severity: critical
          team: backend
        annotations:
          summary: "Alta taxa de erros detectada"
          description: "{{ $value }}% das requisições estão falhando"

      - alert: HighLatency
        expr: |
          histogram_quantile(0.95,
            rate(http_request_duration_seconds_bucket[5m])
          ) > 1
        for: 5m
        labels:
          severity: warning
          team: backend
        annotations:
          summary: "Latência P95 acima de 1 segundo"
          description: "P95 está em {{ $value }}s"

      - alert: ServiceDown
        expr: up{job=~"auth-service|transaction-service"} == 0
        for: 1m
        labels:
          severity: critical
          team: sre
        annotations:
          summary: "Serviço {{ $labels.job }} está down"
          description: "O serviço não está respondendo"
```

### Alertas de Negócio

```yaml
      - alert: NoUserRegistrations
        expr: |
          increase(user_registrations_total[1h]) == 0
        for: 2h
        labels:
          severity: warning
          team: product
        annotations:
          summary: "Sem registros de usuários nas últimas 2 horas"
          description: "Possível problema no fluxo de cadastro"

      - alert: HighLoginFailureRate
        expr: |
          (
            rate(failed_login_attempts_total[5m])
            /
            rate(user_logins_total[5m])
          ) > 0.5
        for: 5m
        labels:
          severity: warning
          team: security
        annotations:
          summary: "Alta taxa de falhas de login"
          description: "{{ $value }}% dos logins estão falhando"

      - alert: RabbitMQPublishErrors
        expr: |
          rate(rabbitmq_messages_publish_errors_total[5m]) > 0
        for: 2m
        labels:
          severity: critical
          team: backend
        annotations:
          summary: "Erros ao publicar mensagens no RabbitMQ"
          description: "Taxa de erros: {{ $value }}/s"
```

### Alertas de Infraestrutura

```yaml
      - alert: DatabaseConnectionsHigh
        expr: database_connections_active > 80
        for: 5m
        labels:
          severity: warning
          team: dba
        annotations:
          summary: "Número alto de conexões no banco"
          description: "{{ $value }} conexões ativas"

      - alert: RedisDown
        expr: redis_operation_duration_seconds_count == 0
        for: 2m
        labels:
          severity: critical
          team: sre
        annotations:
          summary: "Redis não está respondendo"
          description: "Sem operações no Redis nos últimos 2 minutos"

      - alert: RabbitMQDisconnected
        expr: rabbitmq_connection_status == 0
        for: 1m
        labels:
          severity: critical
          team: sre
        annotations:
          summary: "Conexão com RabbitMQ perdida"
          description: "Serviço {{ $labels.service }} desconectado do RabbitMQ"
```

## 🎨 Templates de Painéis Grafana

### Painel: Taxa de Requisições com Threshold

```json
{
  "type": "graph",
  "title": "Request Rate",
  "targets": [
    {
      "expr": "sum(rate(http_requests_total[5m]))",
      "legendFormat": "Total Requests/s"
    }
  ],
  "thresholds": [
    {
      "value": 100,
      "colorMode": "custom",
      "fill": true,
      "line": true,
      "op": "gt",
      "fillColor": "rgba(255, 0, 0, 0.1)",
      "lineColor": "rgb(255, 0, 0)"
    }
  ]
}
```

### Painel: Heatmap de Latência

```json
{
  "type": "heatmap",
  "title": "Request Latency Distribution",
  "targets": [
    {
      "expr": "sum(rate(http_request_duration_seconds_bucket[5m])) by (le)",
      "format": "heatmap",
      "legendFormat": "{{le}}"
    }
  ]
}
```

### Painel: Status dos Serviços (Stat)

```json
{
  "type": "stat",
  "title": "Services Status",
  "targets": [
    {
      "expr": "up{job=~\"auth-service|transaction-service\"}",
      "legendFormat": "{{job}}"
    }
  ],
  "options": {
    "reduceOptions": {
      "values": false,
      "calcs": ["lastNotNull"]
    },
    "colorMode": "background",
    "graphMode": "none"
  },
  "fieldConfig": {
    "defaults": {
      "mappings": [
        {
          "type": "value",
          "options": {
            "0": { "text": "DOWN", "color": "red" },
            "1": { "text": "UP", "color": "green" }
          }
        }
      ]
    }
  }
}
```

## 🔗 Correlacionando Dados

### Logs → Traces → Metrics

**1. Começar com um erro nos logs:**
```logql
{service="transaction-service"} | json | level="error" | trace_id!=""
```

**2. Pegar o trace_id e buscar no Jaeger:**
```
http://localhost:16686/trace/{trace_id}
```

**3. Ver métricas do período:**
```promql
rate(http_requests_total{status="500"}[5m])
```

### Exemplo de Workflow de Investigação

**Cenário: API lenta**

1. **Verificar latência no Prometheus:**
```promql
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket{path="/api/v1/transactions"}[5m]))
```

2. **Ver logs do período no Loki:**
```logql
{service="transaction-service", path="/api/v1/transactions"} 
| json 
| duration > 1s
```

3. **Pegar trace_id de uma request lenta e investigar no Jaeger**

4. **Verificar se há problema no banco:**
```promql
histogram_quantile(0.95, rate(database_query_duration_seconds_bucket[5m]))
```

5. **Verificar RabbitMQ:**
```promql
rate(rabbitmq_messages_publish_errors_total[5m])
```

## 📱 Variáveis de Dashboard

### Variável: Service
```
Query: label_values(http_requests_total, service)
```

### Variável: Endpoint
```
Query: label_values(http_requests_total{service="$service"}, path)
```

### Variável: Time Range
```
Custom: 5m, 15m, 1h, 6h, 24h, 7d
```

### Uso em Queries
```promql
rate(http_requests_total{service="$service", path="$endpoint"}[$__rate_interval])
```

## 🎯 Cheat Sheet Rápido

### Top Queries mais Úteis

```promql
# 1. Taxa de requisições
sum(rate(http_requests_total[5m])) by (service)

# 2. Taxa de erros
sum(rate(http_requests_total{status=~"5.."}[5m])) by (service)

# 3. Latência P95
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))

# 4. Transações por tipo
sum by(type) (transactions_created_total)

# 5. Status do RabbitMQ
rabbitmq_connection_status
```

### Top Loki Queries

```logql
# 1. Erros recentes
{} | json | level="error" | line_format "{{.timestamp}} {{.service}} - {{.message}}"

# 2. Logs de um trace
{} | json | trace_id="abc123"

# 3. Rate de erros
rate({} | json | level="error" [5m])

# 4. Top serviços com erros
topk(5, sum by(service) (count_over_time({} | json | level="error" [1h])))

# 5. Requests lentas
{} | json | duration > 1s
```

---

**💡 Dica**: Salve seus dashboards favoritos como JSON para versionamento no Git!