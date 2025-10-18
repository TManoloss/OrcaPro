# ⚡ Quick Reference - Comandos Úteis

Guia rápido de comandos mais utilizados no dia a dia.

## 🚀 Setup Inicial (Primeira vez)

```bash
# Criar estrutura
make init

# Copiar variáveis de ambiente
cp .env.example .env

# Subir tudo
make up

# Verificar saúde
make health
```

## 📦 Comandos Docker Compose

```bash
# Subir todos os serviços
docker-compose up -d

# Parar todos os serviços
docker-compose down

# Ver logs em tempo real
docker-compose logs -f

# Ver logs de um serviço específico
docker-compose logs -f auth-service
docker-compose logs -f transaction-service

# Verificar status
docker-compose ps

# Reconstruir imagens
docker-compose build

# Reconstruir e subir
docker-compose up -d --build

# Remover tudo (incluindo volumes)
docker-compose down -v
```

## 🛠️ Comandos Make

```bash
make help          # Lista todos os comandos
make up            # Sobe tudo
make down          # Para tudo
make restart       # Reinicia tudo
make logs          # Logs de todos
make logs-SERVICE  # Logs de um serviço
make health        # Verifica saúde
make dev           # Modo dev (up + logs)
make clean         # Remove tudo
make rebuild       # Reconstrói imagens
make backup        # Backup do PostgreSQL
```

## 🔐 Auth Service

### Registro
```bash
curl -X POST http://localhost:8001/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "senha123456",
    "name": "Nome do Usuário"
  }'
```

### Login
```bash
curl -X POST http://localhost:8001/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "senha123456"
  }'

# Salvar token em variável
TOKEN=$(curl -s -X POST http://localhost:8001/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"user@example.com","password":"senha123456"}' \
  | jq -r '.access_token')
```

### Ver perfil
```bash
curl http://localhost:8001/api/v1/me \
  -H "Authorization: Bearer $TOKEN"
```

### Logout
```bash
curl -X POST http://localhost:8001/api/v1/logout \
  -H "Authorization: Bearer $TOKEN"
```

## 💰 Transaction Service

### Criar Transação
```bash
# Despesa
curl -X POST http://localhost:8002/api/v1/transactions \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "description": "Almoço no restaurante",
    "amount": 45.50,
    "category": "Alimentação",
    "type": "expense"
  }'

# Receita
curl -X POST http://localhost:8002/api/v1/transactions \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "description": "Salário",
    "amount": 5000.00,
    "category": "Salário",
    "type": "income"
  }'
```

### Listar Transações
```bash
# Todas
curl http://localhost:8002/api/v1/transactions \
  -H "Authorization: Bearer $TOKEN"

# Com paginação
curl "http://localhost:8002/api/v1/transactions?page=1&page_size=10" \
  -H "Authorization: Bearer $TOKEN"

# Filtrar por tipo
curl "http://localhost:8002/api/v1/transactions?type=expense" \
  -H "Authorization: Bearer $TOKEN"

# Filtrar por categoria
curl "http://localhost:8002/api/v1/transactions?category=Alimentação" \
  -H "Authorization: Bearer $TOKEN"
```

### Buscar por ID
```bash
curl http://localhost:8002/api/v1/transactions/TRANSACTION_ID \
  -H "Authorization: Bearer $TOKEN"
```

### Atualizar
```bash
curl -X PUT http://localhost:8002/api/v1/transactions/TRANSACTION_ID \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "description": "Nova descrição",
    "amount": 50.00
  }'
```

### Deletar
```bash
curl -X DELETE http://localhost:8002/api/v1/transactions/TRANSACTION_ID \
  -H "Authorization: Bearer $TOKEN"
```

### Estatísticas
```bash
curl http://localhost:8002/api/v1/transactions/stats \
  -H "Authorization: Bearer $TOKEN" | jq
```

## 📊 Observabilidade

### Métricas
```bash
# Auth Service
curl http://localhost:8001/metrics

# Transaction Service
curl http://localhost:8002/metrics

# Filtrar métricas específicas
curl http://localhost:8001/metrics | grep user_registrations
curl http://localhost:8002/metrics | grep transactions_created
```

### Health Checks
```bash
curl http://localhost:8001/health
curl http://localhost:8002/health
```

## 🗄️ Database

### PostgreSQL via Docker
```bash
# Entrar no container
docker-compose exec postgres psql -U admin -d app_database

# SQL direto
docker-compose exec postgres psql -U admin -d app_database -c "SELECT * FROM users;"

# Backup
docker-compose exec postgres pg_dump -U admin app_database > backup.sql

# Restore
docker-compose exec -T postgres psql -U admin app_database < backup.sql
```

### Queries Úteis
```sql
-- Ver usuários
SELECT id, email, name, created_at FROM users;

-- Ver transações
SELECT id, description, amount, type, category, date 
FROM transactions 
ORDER BY date DESC 
LIMIT 10;

-- Estatísticas
SELECT 
    type,
    COUNT(*) as count,
    SUM(amount) as total
FROM transactions
GROUP BY type;

-- Por categoria
SELECT 
    category,
    COUNT(*) as count,
    SUM(amount) as total
FROM transactions
WHERE type = 'expense'
GROUP BY category
ORDER BY total DESC;
```

## 🔴 Redis

### Via Docker
```bash
# Entrar no container
docker-compose exec redis redis-cli -a redis123

# Comandos úteis
KEYS *                    # Ver todas as chaves
GET key                   # Ver valor
TTL key                   # Ver tempo de expiração
FLUSHALL                  # Limpar tudo (CUIDADO!)

# Ver tokens revogados
KEYS revoked:*
```

## 🐰 RabbitMQ

### Management UI
- **URL**: http://localhost:15672
- **Login**: admin / admin123

### Via CLI
```bash
# Listar exchanges
docker-compose exec rabbitmq rabbitmqctl list_exchanges

# Listar queues
docker-compose exec rabbitmq rabbitmqctl list_queues

# Ver bindings
docker-compose exec rabbitmq rabbitmqctl list_bindings
```

## 📈 Prometheus Queries

```promql
# Taxa de requisições
rate(http_requests_total[5m])

# Por serviço
sum by(service) (rate(http_requests_total[5m]))

# Taxa de erros
rate(http_requests_total{status=~"5.."}[5m])

# Latência P95
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))

# Usuários registrados
user_registrations_total

# Transações criadas
sum by(type) (transactions_created_total)

# Status RabbitMQ
rabbitmq_connection_status
```

## 📝 Loki Queries (LogQL)

```logql
# Logs de um serviço
{service="auth-service"}
{service="transaction-service"}

# Logs de erro
{} | json | level="error"

# Por trace_id
{} | json | trace_id="abc123..."

# Rate de erros
rate({} | json | level="error" [5m])

# Requests lentas
{} | json | duration > 1s

# Pattern extraction
{service="auth-service"} | pattern "<_> user_id=<user_id> <_>"
```

## 🐛 Debugging

### Ver logs com contexto
```bash
# Últimas 100 linhas
docker-compose logs --tail=100 auth-service

# Seguir logs em tempo real
docker-compose logs -f auth-service

# Logs com timestamp
docker-compose logs -t auth-service

# Logs de múltiplos serviços
docker-compose logs auth-service transaction-service
```

### Verificar recursos
```bash
# CPU e memória
docker stats

# Detalhes de um container
docker inspect auth-service

# Processos rodando
docker-compose top
```

### Shell nos containers
```bash
# PostgreSQL
docker-compose exec postgres sh

# Redis
docker-compose exec redis sh

# Auth Service
docker-compose exec auth-service sh

# Transaction Service
docker-compose exec transaction-service sh
```

## 🧪 Testing

### Teste manual completo
```bash
./test-flow.sh
```

### Teste específico
```bash
# Criar usuário e testar fluxo
EMAIL="test_$(date +%s)@test.com"

# 1. Registrar
curl -X POST http://localhost:8001/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$EMAIL\",\"password\":\"senha123\",\"name\":\"Test\"}"

# 2. Login
TOKEN=$(curl -s -X POST http://localhost:8001/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$EMAIL\",\"password\":\"senha123\"}" \
  | jq -r '.access_token')

# 3. Criar transação e pegar trace_id
RESPONSE=$(curl -v -X POST http://localhost:8002/api/v1/transactions \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"description":"Test","amount":100,"category":"Test","type":"expense"}' \
  2>&1)

TRACE_ID=$(echo "$RESPONSE" | grep "X-Trace-ID" | awk '{print $3}')
echo "Trace ID: $TRACE_ID"
echo "Jaeger: http://localhost:16686/trace/$TRACE_ID"
```

## 🔧 Troubleshooting

### Serviço não inicia
```bash
# Ver erro específico
docker-compose logs service-name

# Verificar se porta está em uso
lsof -i :8001
lsof -i :8002

# Reiniciar serviço específico
docker-compose restart service-name
```

### Banco não conecta
```bash
# Verificar se está rodando
docker-compose ps postgres

# Ver logs
docker-compose logs postgres

# Testar conexão
docker-compose exec postgres pg_isready -U admin
```

### RabbitMQ com problema
```bash
# Status
docker-compose exec rabbitmq rabbitmqctl status

# Ver logs
docker-compose logs rabbitmq

# Restart
docker-compose restart rabbitmq
```

### Limpar tudo e recomeçar
```bash
# Parar tudo
docker-compose down

# Remover volumes
docker-compose down -v

# Remover imagens
docker-compose down --rmi all

# Subir de novo
make up
```

## 📦 Build e Deploy

### Build local
```bash
# Build das imagens
docker-compose build

# Build sem cache
docker-compose build --no-cache

# Build de um serviço específico
docker-compose build auth-service
```

### Go específico
```bash
# Entrar no diretório do serviço
cd services/auth-service

# Download dependencies
go mod download

# Tidy dependencies
go mod tidy

# Build local
go build -o auth-service

# Run local (precisa das envs)
./auth-service

# Tests
go test ./...

# Tests com coverage
go test -cover ./...

# Race detector
go test -race ./...
```

## 🔗 URLs Rápidas

| Serviço | URL |
|---------|-----|
| Auth Service | http://localhost:8001 |
| Transaction Service | http://localhost:8002 |
| Grafana | http://localhost:3000 |
| Prometheus | http://localhost:9090 |
| Jaeger | http://localhost:16686 |
| RabbitMQ | http://localhost:15672 |
| Adminer | http://localhost:8080 |
| Redis Commander | http://localhost:8081 |

## 💾 Backup e Restore

### PostgreSQL
```bash
# Backup
docker-compose exec postgres pg_dump -U admin app_database > backup_$(date +%Y%m%d).sql

# Restore
docker-compose exec -T postgres psql -U admin app_database < backup_20240101.sql

# Backup com make
make backup
```

### Exportar métricas (opcional)
```bash
# Snapshot do Prometheus
curl -X POST http://localhost:9090/api/v1/admin/tsdb/snapshot
```

---

**💡 Dica**: Adicione este arquivo aos favoritos do seu editor para acesso rápido!