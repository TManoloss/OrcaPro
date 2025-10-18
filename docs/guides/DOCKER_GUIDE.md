# 🐳 Guia Docker - OrcaPro

## ⚡ Início Rápido com Docker

### 🚀 Rodar Tudo com 1 Comando

```bash
cd /home/manoelfelip/Documentos/projetos/OrcaPro
./start-docker.sh
```

**Pronto!** Todos os serviços estarão rodando em containers Docker.

---

## 📋 O Que Será Iniciado

### Serviços de Aplicação
- ✅ **Auth Service** (porta 8001)
- ✅ **Transaction Service** (porta 8002)
- ✅ **AI Service** (porta 8003)

### Infraestrutura
- ✅ **PostgreSQL** (porta 5432)
- ✅ **Redis** (porta 6379)
- ✅ **RabbitMQ** (portas 5672, 15672)

### Observabilidade
- ✅ **Prometheus** (porta 9090)
- ✅ **Grafana** (porta 3000)
- ✅ **Jaeger** (porta 16686)
- ✅ **Loki + Promtail** (porta 3100)

### Ferramentas
- ✅ **Adminer** - Interface PostgreSQL (porta 8080)
- ✅ **Redis Commander** - Interface Redis (porta 8081)

---

## 🎯 Comandos Principais

### Iniciar Tudo
```bash
./start-docker.sh
```

### Parar Tudo
```bash
./stop-docker.sh
```

Ou manualmente:
```bash
sudo docker-compose down
```

### Ver Logs

**Todos os serviços:**
```bash
./logs-docker.sh
```

**Serviço específico:**
```bash
./logs-docker.sh auth-service
./logs-docker.sh transaction-service
./logs-docker.sh ai-service
```

Ou manualmente:
```bash
sudo docker-compose logs -f
sudo docker-compose logs -f auth-service
```

### Ver Status
```bash
sudo docker-compose ps
```

### Reiniciar um Serviço
```bash
sudo docker-compose restart auth-service
sudo docker-compose restart transaction-service
sudo docker-compose restart ai-service
```

### Reconstruir Imagens
```bash
# Reconstruir tudo
sudo docker-compose build

# Reconstruir serviço específico
sudo docker-compose build auth-service
sudo docker-compose build transaction-service
sudo docker-compose build ai-service
```

### Reiniciar com Rebuild
```bash
sudo docker-compose down
sudo docker-compose up -d --build
```

---

## 🧪 Testar Sistema

Após iniciar com `./start-docker.sh`, aguarde ~15 segundos e execute:

```bash
./test-with-ai.sh
```

Ou teste manualmente:

```bash
# Health checks
curl http://localhost:8001/health
curl http://localhost:8002/health
curl http://localhost:8003 | grep ml_model_loaded

# Criar usuário e transação
TOKEN=$(curl -s -X POST http://localhost:8001/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"teste@example.com","password":"senha12345"}' \
  | grep -o '"access_token":"[^"]*' | cut -d'"' -f4)

curl -X POST http://localhost:8002/api/v1/transactions \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"description":"Uber","amount":35.00,"category":"Outros","type":"expense","date":"2025-10-18T18:00:00Z"}'

# Ver categorização
sudo docker logs ai-service --tail 5
```

---

## 🌐 URLs e Acessos

| Serviço | URL | Credenciais |
|---------|-----|-------------|
| **Auth Service** | http://localhost:8001 | - |
| **Transaction Service** | http://localhost:8002 | - |
| **AI Service (métricas)** | http://localhost:8003 | - |
| **Adminer (PostgreSQL)** | http://localhost:8080 | Server: postgres<br>User: admin<br>Pass: admin123<br>DB: app_database |
| **Redis Commander** | http://localhost:8081 | - |
| **RabbitMQ Management** | http://localhost:15672 | admin/admin123 |
| **Prometheus** | http://localhost:9090 | - |
| **Grafana** | http://localhost:3000 | admin/admin123 |
| **Jaeger UI** | http://localhost:16686 | - |

---

## 🔧 Troubleshooting

### Erro: "port is already allocated"

```bash
# Ver o que está usando a porta
sudo lsof -i :8001
sudo lsof -i :8002
sudo lsof -i :8003

# Parar containers
sudo docker-compose down

# Matar processo se necessário
kill -9 <PID>
```

### Erro: "build failed"

```bash
# Limpar cache do Docker
sudo docker system prune -a

# Reconstruir
sudo docker-compose build --no-cache
```

### Serviço não inicia

```bash
# Ver logs
sudo docker-compose logs auth-service
sudo docker-compose logs transaction-service
sudo docker-compose logs ai-service

# Verificar dependências
sudo docker-compose ps

# Reiniciar
sudo docker-compose restart <service-name>
```

### Banco de dados não inicializa

```bash
# Entrar no container
sudo docker exec -it postgres bash

# Conectar ao PostgreSQL
psql -U admin -d app_database

# Ver tabelas
\dt

# Sair
\q
exit
```

### Limpar Tudo e Recomeçar

```bash
# Parar e remover containers, networks, volumes
sudo docker-compose down -v

# Remover imagens
sudo docker rmi orcapro-auth-service orcapro-transaction-service orcapro-ai-service

# Iniciar novamente
./start-docker.sh
```

---

## 📊 Monitoramento

### Ver Logs em Tempo Real

```bash
# Todos
sudo docker-compose logs -f

# Apenas aplicação
sudo docker-compose logs -f auth-service transaction-service ai-service

# Com filtro
sudo docker-compose logs -f | grep ERROR
```

### Métricas

```bash
# Auth Service
curl http://localhost:8001/metrics | grep auth_

# Transaction Service
curl http://localhost:8002/metrics | grep transactions_

# AI Service
curl http://localhost:8003 | grep transactions_
```

### Prometheus Queries

Acesse http://localhost:9090 e execute:

```promql
# Taxa de requisições
rate(http_requests_total[5m])

# Transações criadas
transactions_created_total

# Categorizações da IA
transactions_categorized_total
```

### Grafana Dashboards

Acesse http://localhost:3000 (admin/admin123)

Dashboards disponíveis em `/config/grafana/dashboards/`

---

## 🎯 Comandos Úteis

```bash
# Ver uso de recursos
sudo docker stats

# Entrar em um container
sudo docker exec -it auth-service sh
sudo docker exec -it transaction-service sh
sudo docker exec -it ai-service sh

# Ver networks
sudo docker network ls

# Ver volumes
sudo docker volume ls

# Limpar recursos não usados
sudo docker system prune

# Backup do banco
sudo docker exec postgres pg_dump -U admin app_database > backup.sql

# Restaurar banco
sudo docker exec -i postgres psql -U admin app_database < backup.sql
```

---

## 🚀 Desenvolvimento

### Fazer Mudanças no Código

1. Edite o código
2. Reconstrua a imagem:
```bash
sudo docker-compose build <service-name>
```
3. Reinicie o serviço:
```bash
sudo docker-compose up -d <service-name>
```

### Hot Reload (Desenvolvimento)

Para desenvolvimento com hot reload, use volumes:

```yaml
# Adicionar em docker-compose.yml
volumes:
  - ./services/auth-service:/app
```

Ou rode localmente sem Docker (ver GUIA_EXECUCAO.md)

---

## 📦 Estrutura Docker

```
OrcaPro/
├── docker-compose.yml          # Orquestração de todos os serviços
├── services/
│   ├── auth-service/
│   │   └── Dockerfile         # Build do Auth Service
│   ├── trasaction-service/
│   │   └── Dockerfile         # Build do Transaction Service
│   └── ai-service/
│       └── Dockerfile         # Build do AI Service
├── start-docker.sh            # Script para iniciar tudo
├── stop-docker.sh             # Script para parar tudo
└── logs-docker.sh             # Script para ver logs
```

---

## ✅ Vantagens do Docker

- ✅ **Um comando** inicia tudo
- ✅ **Isolamento** completo entre serviços
- ✅ **Portabilidade** - roda em qualquer máquina
- ✅ **Fácil escalonamento**
- ✅ **Networking** automático entre containers
- ✅ **Health checks** integrados
- ✅ **Logs centralizados**
- ✅ **Restart automático** em caso de falha

---

## 🎉 Resumo

**Para rodar tudo:**
```bash
./start-docker.sh
```

**Para testar:**
```bash
./test-with-ai.sh
```

**Para ver logs:**
```bash
./logs-docker.sh
```

**Para parar:**
```bash
./stop-docker.sh
```

**Simples assim!** 🚀

---

**Status:** ✅ Sistema 100% containerizado  
**Última atualização:** 2025-10-18
