# 🚀 Guia de Execução - OrcaPro

## 📋 Pré-requisitos

- Docker e Docker Compose instalados
- Go 1.21+ instalado
- Python 3.11+ instalado
- Portas disponíveis: 5432, 6379, 5672, 8001, 8002, 8003, 15672, 16686

---

## ⚡ Início Rápido (Recomendado)

### 1. Preparar Ambiente

```bash
cd /home/manoelfelip/Documentos/projetos/OrcaPro

# Executar script de preparação
./start-all.sh
```

Este script irá:
- ✅ Verificar Docker
- ✅ Iniciar infraestrutura (PostgreSQL, Redis, RabbitMQ, Jaeger)
- ✅ Inicializar banco de dados
- ✅ Compilar serviços Go
- ✅ Criar arquivos .env

### 2. Iniciar Serviços (3 Terminais)

**Terminal 1 - Auth Service:**
```bash
cd /home/manoelfelip/Documentos/projetos/OrcaPro
./start-auth-service.sh
```

**Terminal 2 - Transaction Service:**
```bash
cd /home/manoelfelip/Documentos/projetos/OrcaPro
./start-transaction-service.sh
```

**Terminal 3 - AI Service:**
```bash
cd /home/manoelfelip/Documentos/projetos/OrcaPro
./start-ai-service.sh
```

### 3. Testar Sistema

```bash
cd /home/manoelfelip/Documentos/projetos/OrcaPro
./test-with-ai.sh
```

---

## 📝 Passo a Passo Detalhado

### Passo 1: Iniciar Infraestrutura

```bash
cd /home/manoelfelip/Documentos/projetos/OrcaPro

# Iniciar containers Docker
sudo docker-compose up -d postgres redis rabbitmq jaeger

# Verificar status
sudo docker-compose ps
```

**Aguarde ~10 segundos** para os serviços ficarem prontos.

### Passo 2: Inicializar Banco de Dados (Primeira vez apenas)

```bash
# Executar script SQL
sudo docker exec -i postgres psql -U admin -d app_database < init-scripts/postgres/001_init.sql
```

### Passo 3: Compilar Serviços Go

```bash
# Auth Service
cd services/auth-service
go build -o auth-service .
cd ../..

# Transaction Service
cd services/trasaction-service
go build -o transaction-service .
cd ../..
```

### Passo 4: Configurar Variáveis de Ambiente

```bash
# Criar arquivos .env a partir dos exemplos
cp services/auth-service/.env.example services/auth-service/.env
cp services/trasaction-service/.env.example services/trasaction-service/.env
cp services/ai-service/.env.example services/ai-service/.env
```

**Opcional:** Edite os arquivos `.env` se precisar alterar configurações.

### Passo 5: Iniciar Auth Service

**Terminal 1:**
```bash
cd /home/manoelfelip/Documentos/projetos/OrcaPro
./start-auth-service.sh
```

Ou manualmente:
```bash
cd services/auth-service
export $(cat .env | grep -v '^#' | xargs)
./auth-service
```

**Aguarde ver:** `starting auth service port=:8001`

### Passo 6: Iniciar Transaction Service

**Terminal 2:**
```bash
cd /home/manoelfelip/Documentos/projetos/OrcaPro
./start-transaction-service.sh
```

Ou manualmente:
```bash
cd services/trasaction-service
export $(cat .env | grep -v '^#' | xargs)
./transaction-service
```

**Aguarde ver:** `starting transaction service port=:8002`

### Passo 7: Iniciar AI Service

**Terminal 3:**
```bash
cd /home/manoelfelip/Documentos/projetos/OrcaPro
./start-ai-service.sh
```

Ou manualmente:
```bash
cd services/ai-service
pip install -r requirements.txt  # Primeira vez apenas
export $(cat .env | grep -v '^#' | xargs)
python3 main.py
```

**Aguarde ver:** `Aguardando mensagens...`

---

## ✅ Verificar se Está Funcionando

### Health Checks

```bash
# Auth Service
curl http://localhost:8001/health

# Transaction Service
curl http://localhost:8002/health

# AI Service (métricas)
curl http://localhost:8003 | grep ml_model_loaded
```

### Verificar Containers

```bash
sudo docker-compose ps
```

Deve mostrar:
- ✅ postgres (healthy)
- ✅ redis (healthy)
- ✅ rabbitmq (healthy)
- ✅ jaeger (running)

---

## 🧪 Executar Testes

### Teste Completo com IA

```bash
cd /home/manoelfelip/Documentos/projetos/OrcaPro
./test-with-ai.sh
```

### Teste de Categorização

```bash
./test-ai-categorization.sh
```

### Teste Manual

```bash
# 1. Registrar usuário
curl -X POST http://localhost:8001/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"teste@example.com","name":"Teste","password":"senha12345"}'

# 2. Login
TOKEN=$(curl -s -X POST http://localhost:8001/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"teste@example.com","password":"senha12345"}' \
  | grep -o '"access_token":"[^"]*' | cut -d'"' -f4)

# 3. Criar transação
curl -X POST http://localhost:8002/api/v1/transactions \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "description": "Uber para casa",
    "amount": 35.00,
    "category": "Outros",
    "type": "expense",
    "date": "2025-10-18T18:00:00Z"
  }'

# 4. Ver logs do AI Service
sudo docker logs ai-service --tail 5
```

---

## 🛑 Parar Serviços

### Parar Aplicações

Pressione `Ctrl+C` em cada terminal.

### Parar Infraestrutura

```bash
cd /home/manoelfelip/Documentos/projetos/OrcaPro
sudo docker-compose down
```

### Parar e Limpar Tudo (CUIDADO: apaga dados)

```bash
sudo docker-compose down -v
```

---

## 🌐 URLs e Portas

| Serviço | URL | Credenciais |
|---------|-----|-------------|
| Auth Service | http://localhost:8001 | - |
| Transaction Service | http://localhost:8002 | - |
| AI Service (métricas) | http://localhost:8003 | - |
| PostgreSQL | localhost:5432 | admin/admin123 |
| Redis | localhost:6379 | senha: redis123 |
| RabbitMQ AMQP | localhost:5672 | admin/admin123 |
| RabbitMQ Management | http://localhost:15672 | admin/admin123 |
| Jaeger UI | http://localhost:16686 | - |

---

## 🔧 Troubleshooting

### Erro: "porta já em uso"

```bash
# Verificar o que está usando a porta
sudo lsof -i :8001
sudo lsof -i :8002
sudo lsof -i :8003

# Matar processo
kill -9 <PID>
```

### Erro: "connection refused" no PostgreSQL

```bash
# Verificar se container está rodando
sudo docker ps | grep postgres

# Ver logs
sudo docker logs postgres

# Reiniciar
sudo docker restart postgres
```

### Erro: AI Service não categoriza

```bash
# Verificar logs
sudo docker logs ai-service --tail 50

# Verificar se RabbitMQ está rodando
sudo docker exec rabbitmq rabbitmqctl list_queues

# Reiniciar AI Service
sudo docker restart ai-service
```

### Erro: "permission denied" no Docker

```bash
# Adicionar usuário ao grupo docker
sudo usermod -aG docker $USER
newgrp docker

# Ou usar sudo
sudo docker-compose up -d
```

---

## 📊 Monitoramento

### Ver Logs em Tempo Real

```bash
# Auth Service
tail -f services/auth-service/logs/*.log

# Transaction Service  
tail -f services/trasaction-service/logs/*.log

# AI Service
sudo docker logs -f ai-service

# Todos containers
sudo docker-compose logs -f
```

### Métricas Prometheus

```bash
# Auth Service
curl http://localhost:8001/metrics | grep auth_

# Transaction Service
curl http://localhost:8002/metrics | grep transactions_

# AI Service
curl http://localhost:8003 | grep transactions_
```

### RabbitMQ

Acesse: http://localhost:15672
- User: `admin`
- Password: `admin123`

Verifique:
- Exchanges → `transactions_exchange`
- Queues → `ai_categorization_queue`

---

## 🎯 Comandos Úteis

```bash
# Recompilar serviços
cd services/auth-service && go build -o auth-service . && cd ../..
cd services/trasaction-service && go build -o transaction-service . && cd ../..

# Reiniciar infraestrutura
sudo docker-compose restart postgres redis rabbitmq

# Ver status de tudo
sudo docker-compose ps
ps aux | grep -E "(auth-service|transaction-service)"
sudo docker logs ai-service --tail 10

# Limpar e recomeçar
sudo docker-compose down
sudo docker-compose up -d postgres redis rabbitmq jaeger
./start-all.sh
```

---

## 📚 Próximos Passos

1. **Desenvolvimento:**
   - Adicionar mais endpoints
   - Implementar testes unitários
   - Melhorar modelo de IA

2. **Produção:**
   - Configurar CI/CD
   - Deploy em Kubernetes
   - Configurar monitoramento com Grafana

3. **Features:**
   - Frontend React
   - Notificações
   - Relatórios em PDF

---

## 🆘 Suporte

- **Documentação:** Veja os arquivos `*.md` na raiz do projeto
- **Logs:** Sempre verifique os logs quando algo não funcionar
- **Health Checks:** Use os endpoints `/health` para diagnóstico

---

**Status:** ✅ Sistema 100% funcional  
**Última atualização:** 2025-10-18
