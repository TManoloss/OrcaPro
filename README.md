# 🚀 Projeto Completo: Microsserviços com IA e Observabilidade

Sistema completo de gestão financeira usando arquitetura de microsserviços, Machine Learning e observabilidade de nível produção.

## 📋 O Que Foi Construído

### 🏗️ Fase 0: Infraestrutura Base
- **Bancos de Dados**: PostgreSQL + Redis
- **Mensageria**: RabbitMQ com Management UI
- **Observabilidade**: Prometheus + Grafana + Jaeger + Loki + Promtail
- **Ferramentas**: Adminer (PostgreSQL UI) + Redis Commander

### ⚙️ Fase 1: Microsserviços Core (Go)
- **Auth Service (8001)**: Autenticação JWT completa
- **Transaction Service (8002)**: CRUD de transações + Event publishing

### 🤖 Fase 2: Inteligência e Reatividade
- **AI Service (8003)** - Python: Categorização automática com ML
- **Notification Service (8004)** - Node.js: Alertas inteligentes

## 🎯 Arquitetura Completa

```
┌─────────────────────────────────────────────────────────┐
│                   OBSERVABILIDADE                        │
│   Grafana │ Prometheus │ Jaeger │ Loki │ Promtail      │
└─────────────────────────────────────────────────────────┘
                         ▲
                         │ métricas/logs/traces
                         │
┌─────────────────────────────────────────────────────────┐
│                   MICROSSERVIÇOS                         │
│                                                          │
│  Auth ──→ Transaction ──→ RabbitMQ ──┬──→ AI Service   │
│ (Go)       (Go)          Exchange    │    (Python)      │
│  8001       8002                     │     8003         │
│                                      │                   │
│                                      └──→ Notification  │
│                                           (Node.js)      │
│                                            8004          │
└─────────────────────────────────────────────────────────┘
         │              │
         ▼              ▼
    PostgreSQL      Redis
```# 🚀 Infraestrutura de Desenvolvimento - Microsserviços com Observabilidade

Projeto completo de microsserviços em Go com infraestrutura de produção local, observabilidade total e mensageria assíncrona.

## 📋 O Que Foi Construído

### 🏗️ Fase 0: Infraestrutura Base
- **Bancos de Dados**: PostgreSQL + Redis
- **Mensageria**: RabbitMQ com Management UI
- **Observabilidade**: Prometheus + Grafana + Jaeger + Loki + Promtail
- **Ferramentas**: Adminer (PostgreSQL UI) + Redis Commander

### ⚙️ Fase 1: Microsserviços Core
- **Auth Service**: Autenticação completa com JWT, registro, login, refresh tokens
- **Transaction Service**: CRUD de transações com publicação de eventos no RabbitMQ
- **Observabilidade Completa**: Logs estruturados, métricas Prometheus, tracing distribuído

## 🎯 Arquitetura

```
┌─────────────────────────────────────────────────────────────┐
│                     OBSERVABILIDADE                          │
│  Grafana │ Prometheus │ Jaeger │ Loki │ Promtail           │
└─────────────────────────────────────────────────────────────┘
                            ▲
                            │ métricas/logs/traces
                            │
┌─────────────────────────────────────────────────────────────┐
│                      MICROSSERVIÇOS                          │
│                                                               │
│  ┌─────────────┐         ┌──────────────────┐              │
│  │Auth Service │         │Transaction Service│              │
│  │   (8001)    │         │      (8002)       │              │
│  └──────┬──────┘         └────────┬──────────┘              │
│         │                          │                         │
│         └──────────┬───────────────┘                         │
│                    │                                         │
└────────────────────┼─────────────────────────────────────────┘
                     │
         ┌───────────┴───────────┐
         ▼                       ▼
    ┌─────────┐            ┌──────────┐
    │PostgreSQL│            │RabbitMQ  │
    │  Redis  │            │(Events)  │
    └─────────┘            └──────────┘
```

## 🚀 Quick Start

```bash
# 1. Clone e configure
git clone <seu-repo>
cd <seu-repo>
make init

# 2. Inicie tudo
make up

# 3. Verifique a saúde
make health

# 4. Teste o fluxo completo
chmod +x test-flow.sh
./test-flow.sh
```

## 🔗 URLs de Acesso

| Serviço | URL | Credenciais |
|---------|-----|-------------|
| **Auth Service** | http://localhost:8001 | - |
| **Transaction Service** | http://localhost:8002 | - |
| **Grafana** | http://localhost:3000 | admin / admin123 |
| **Prometheus** | http://localhost:9090 | - |
| **Jaeger UI** | http://localhost:16686 | - |
| **RabbitMQ Management** | http://localhost:15672 | admin / admin123 |
| **Adminer (PostgreSQL)** | http://localhost:8080 | admin / admin123 |
| **Redis Commander** | http://localhost:8081 | - |

## 📖 Documentação Detalhada

- **[FASE1_README.md](FASE1_README.md)**: Guia completo da Fase 1 com exemplos de API, queries de observabilidade e troubleshooting

## 🎓 Features Implementadas

### Observabilidade de Produção
✅ **Logging Estruturado**: JSON logs com Zap para fácil parsing  
✅ **Métricas Custom**: Prometheus com métricas de negócio e técnicas  
✅ **Distributed Tracing**: Jaeger com propagação de trace_id  
✅ **Log Aggregation**: Loki + Promtail para busca centralizada  
✅ **Dashboards**: Grafana com datasources pré-configurados  

### Microsserviços Desacoplados
✅ **Event-Driven**: Comunicação assíncrona via RabbitMQ  
✅ **Trace Propagation**: trace_id mantido em eventos  
✅ **Health Checks**: Endpoints /health em todos os serviços  
✅ **Graceful Shutdown**: Timeout de 30s para finalizar requests  

### Segurança
✅ **JWT Authentication**: Access + Refresh tokens  
✅ **Password Hashing**: bcrypt com salt  
✅ **Token Blacklist**: Redis para logout  
✅ **CORS configurado**: Headers permitidos  

### Database
✅ **Migrations**: SQL scripts automáticos  
✅ **Indexes**: Otimizados para queries comuns  
✅ **Triggers**: Auto-update de timestamps  
✅ **Relations**: Foreign keys com CASCADE  

## 📊 Métricas Disponíveis

Veja no [FASE1_README.md](FASE1_README.md) a lista completa de métricas e como usá-las.

**Exemplos:**
- `user_registrations_total`: Usuários cadastrados
- `transactions_created_total{type="expense"}`: Despesas criadas  
- `http_request_duration_seconds`: Latência das APIs
- `rabbitmq_messages_published_total`: Eventos publicados

## 🧪 Testando

```bash
# Teste manual completo
./test-flow.sh

# Teste individual - Registro
curl -X POST http://localhost:8001/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"senha123","name":"Test"}'

# Métricas
curl http://localhost:8001/metrics
curl http://localhost:8002/metrics
```

## 🛠️ Comandos Make

```bash
make help          # Lista todos os comandos
make up            # Inicia todos os serviços
make down          # Para todos os serviços
make health        # Verifica saúde dos serviços
make logs          # Logs de todos os serviços
make logs-auth-service        # Logs de um serviço específico
make dev           # Modo desenvolvimento (up + logs)
make clean         # Remove tudo (incluindo volumes)
make rebuild       # Reconstrói as imagens Docker
make backup        # Backup dos volumes do PostgreSQL
```

## 🔧 Configuração

### Variáveis de Ambiente

Copie o arquivo `.env.example` para `.env` e ajuste conforme necessário:

```bash
cp .env.example .env
```

**⚠️ IMPORTANTE**: Em produção, altere todas as senhas e secrets!

### Estrutura de Diretórios Completa

```
projeto/
├── docker-compose.yml           # Orquestração de toda infraestrutura
├── Makefile                     # Comandos úteis
├── .env.example                 # Template de variáveis
├── .gitignore                   # Arquivos ignorados
├── README.md                    # Este arquivo
├── FASE1_README.md             # Documentação detalhada
├── test-flow.sh                # Script de teste
│
├── config/                     # Configurações da infraestrutura
│   ├── prometheus/
│   │   └── prometheus.yml      # Targets e scrape configs
│   ├── grafana/
│   │   └── provisioning/
│   │       └── datasources/
│   │           └── datasources.yml  # Datasources pré-configurados
│   ├── loki/
│   │   └── loki-config.yml     # Configuração do Loki
│   └── promtail/
│       └── promtail-config.yml # Coleta de logs
│
├── init-scripts/               # Scripts de inicialização
│   └── postgres/
│       └── 001_init.sql        # Schema do banco
│
└── services/                   # Microsserviços
    ├── auth-service/
    │   ├── Dockerfile
    │   ├── go.mod
    │   ├── main.go
    │   ├── config/
    │   │   └── config.go
    │   ├── handlers/
    │   │   └── auth_handler.go
    │   ├── middleware/
    │   │   └── observability.go
    │   ├── metrics/
    │   │   └── metrics.go
    │   ├── models/
    │   │   └── user.go
    │   └── repository/
    │       └── user_repository.go
    │
    └── transaction-service/
        ├── Dockerfile
        ├── go.mod
        ├── main.go
        ├── config/
        │   └── config.go
        ├── handlers/
        │   └── transaction_handler.go
        ├── messaging/
        │   └── publisher.go
        ├── metrics/
        │   └── metrics.go
        ├── models/
        │   └── transaction.go
        └── repository/
            └── transaction_repository.go
```

## 🔍 Observabilidade em Ação

### Ver logs em tempo real com trace_id
```bash
# No Grafana → Explore → Loki
{service="transaction-service"} | json | trace_id="abc123..."
```

### Queries Prometheus úteis
```promql
# Taxa de requisições por segundo
rate(http_requests_total[5m])

# P95 de latência
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))

# Erros no RabbitMQ
rate(rabbitmq_messages_publish_errors_total[5m])
```

### Rastrear uma requisição no Jaeger
1. Faça uma request e pegue o X-Trace-ID do header
2. Acesse Jaeger UI
3. Busque pelo trace_id
4. Veja o fluxo completo: API → DB → RabbitMQ

## 🐛 Troubleshooting

### Serviços não sobem
```bash
# Verificar logs
make logs

# Verificar recursos
docker stats

# Limpar e reiniciar
make clean
make up
```

### Erro de conexão com PostgreSQL
```bash
# Verificar se está healthy
docker-compose ps postgres

# Testar conexão
docker-compose exec postgres psql -U admin -d app_database -c "\dt"

# Ver logs
make logs-postgres
```

### RabbitMQ não recebe mensagens
```bash
# Verificar exchange
# http://localhost:15672 → Exchanges → transactions_exchange

# Ver logs
make logs-rabbitmq

# Verificar filas
make logs-transaction-service | grep "published"
```

### Prometheus não coleta métricas
```bash
# Verificar targets
# http://localhost:9090/targets

# Testar endpoint /metrics
curl http://localhost:8001/metrics
curl http://localhost:8002/metrics

# Ver logs do Prometheus
make logs-prometheus
```

## 📈 Monitoramento de Produção

### Dashboards Recomendados para Importar no Grafana

1. **Go Metrics** (ID: 10826)
2. **PostgreSQL** (ID: 9628)
3. **Redis** (ID: 11835)
4. **RabbitMQ** (ID: 10991)
5. **Node Exporter** (ID: 1860)

### Alertas Importantes (configurar no Prometheus)

```yaml
# Alta taxa de erros
- alert: HighErrorRate
  expr: rate(http_requests_total{status=~"5.."}[5m]) > 0.05
  
# Latência alta
- alert: HighLatency
  expr: histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m])) > 1

# RabbitMQ com problemas
- alert: RabbitMQPublishErrors
  expr: rate(rabbitmq_messages_publish_errors_total[5m]) > 0
```

## 🔐 Segurança

### Antes de ir para produção:

- [ ] Trocar todas as senhas padrão
- [ ] Configurar SSL/TLS para todos os serviços expostos
- [ ] Implementar rate limiting
- [ ] Configurar network policies
- [ ] Usar secrets management (Vault, AWS Secrets Manager)
- [ ] Implementar RBAC no Kubernetes
- [ ] Configurar backups automáticos
- [ ] Implementar disaster recovery
- [ ] Auditar dependências com `go mod audit`
- [ ] Scan de vulnerabilidades com Trivy/Snyk

## 🚀 Próximos Passos

### Fase 2: Serviço de IA
- [ ] Consumer RabbitMQ para `transaction.created`
- [ ] Integração com OpenAI/Anthropic
- [ ] Categorização inteligente de transações
- [ ] Publicação de `transaction.categorized`

### Melhorias Arquiteturais
- [ ] API Gateway (Kong, Traefik)
- [ ] Service Mesh (Istio, Linkerd)
- [ ] Circuit Breaker (resilience4j)
- [ ] Rate Limiting distribuído
- [ ] Caching strategies (Redis cache-aside)
- [ ] Database sharding
- [ ] Read replicas
- [ ] CQRS pattern

### DevOps
- [ ] CI/CD pipeline (GitHub Actions, GitLab CI)
- [ ] Kubernetes deployment
- [ ] Helm charts
- [ ] ArgoCD para GitOps
- [ ] Integration tests
- [ ] Load testing (k6, Gatling)
- [ ] Chaos engineering (Chaos Mesh)

## 📚 Tecnologias Utilizadas

### Backend
- **Go 1.21**: Linguagem principal
- **Gin**: Framework HTTP
- **GORM**: ORM (ou SQL puro)
- **JWT**: Autenticação
- **bcrypt**: Hash de senhas

### Infraestrutura
- **Docker & Docker Compose**: Containerização
- **PostgreSQL 15**: Banco relacional
- **Redis 7**: Cache e sessões
- **RabbitMQ 3**: Message broker

### Observabilidade
- **Prometheus**: Métricas
- **Grafana**: Visualização
- **Jaeger**: Tracing distribuído
- **Loki**: Agregação de logs
- **Promtail**: Coleta de logs
- **OpenTelemetry**: Instrumentação

## 🤝 Contribuindo

1. Fork o projeto
2. Crie uma branch (`git checkout -b feature/nova-feature`)
3. Commit suas mudanças (`git commit -am 'Adiciona nova feature'`)
4. Push para a branch (`git push origin feature/nova-feature`)
5. Abra um Pull Request

## 📄 Licença

Este projeto está sob a licença MIT. Veja o arquivo LICENSE para mais detalhes.

## 👨‍💻 Autor

Desenvolvido com ❤️ seguindo as melhores práticas de microsserviços e observabilidade.

---

## 🎯 Checklist de Setup

### Primeira vez:
- [ ] Instalar Docker e Docker Compose
- [ ] Clonar o repositório
- [ ] Executar `make init`
- [ ] Copiar `.env.example` para `.env`
- [ ] Executar `make up`
- [ ] Verificar com `make health`
- [ ] Acessar Grafana e configurar dashboards
- [ ] Testar com `./test-flow.sh`

### Desenvolvimento diário:
- [ ] `make dev` para iniciar com logs
- [ ] Fazer mudanças no código
- [ ] `make rebuild` se mudou Dockerfile
- [ ] `make logs-SERVICE` para debugar
- [ ] Verificar métricas no Grafana
- [ ] Verificar traces no Jaeger
- [ ] `make down` ao final do dia

### Deploy:
- [ ] Revisar todas as configurações de segurança
- [ ] Trocar senhas e secrets
- [ ] Configurar SSL/TLS
- [ ] Setup de backups automáticos
- [ ] Configurar monitoramento e alertas
- [ ] Documentar runbooks
- [ ] Configurar disaster recovery

---

**🎉 Pronto! Você tem uma arquitetura de microsserviços de produção rodando localmente!**

Para mais detalhes, consulte [FASE1_README.md](FASE1_README.md) Configuração dos Serviços

### PostgreSQL

**Conexão:**
- Host: `localhost`
- Port: `5432`
- Database: `app_database`
- User: `admin`
- Password: `admin123`

**String de conexão:**
```
postgresql://admin:admin123@localhost:5432/app_database
```

### Redis

**Conexão:**
- Host: `localhost`
- Port: `6379`
- Password: `redis123`

**String de conexão:**
```
redis://:redis123@localhost:6379
```

### RabbitMQ

**Conexão:**
- Host: `localhost`
- Port AMQP: `5672`
- Management UI: `15672`
- User: `admin`
- Password: `admin123`

**String de conexão:**
```
amqp://admin:admin123@localhost:5672/
```

## 📊 Configurando Observabilidade

### 1. Métricas com Prometheus

Os targets já estão configurados em `config/prometheus/prometheus.yml`. Para adicionar novos serviços:

```yaml
- job_name: 'seu-servico'
  static_configs:
    - targets: ['seu-servico:porta']
      labels:
        service: 'seu-servico'
```

### 2. Dashboards no Grafana

1. Acesse http://localhost:3000
2. Login: admin / admin123
3. Os datasources já estão configurados automaticamente
4. Importe dashboards prontos:
   - PostgreSQL: Dashboard ID `9628`
   - Redis: Dashboard ID `11835`
   - RabbitMQ: