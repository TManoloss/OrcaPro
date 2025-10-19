# 📁 Estrutura do Projeto OrcaPro

```
OrcaPro/
│
├── 📄 README.md                          # Documentação principal
├── 📄 STRUCTURE.md                       # Este arquivo - estrutura do projeto
├── 📄 docker-compose.yml                 # Orquestração de todos os serviços
├── 📄 Makefile                           # Comandos make para automação
├── 📄 .env.example                       # Exemplo de variáveis de ambiente
├── 📄 .gitignore                         # Arquivos ignorados pelo Git
│
├── 📂 scripts/                           # 🔧 Scripts de automação
│   ├── start-docker.sh                  # Iniciar tudo com Docker
│   ├── stop-docker.sh                   # Parar containers Docker
│   ├── logs-docker.sh                   # Ver logs dos containers
│   ├── start-all.sh                     # Preparar ambiente local
│   ├── start-auth-service.sh            # Iniciar Auth Service
│   ├── start-transaction-service.sh     # Iniciar Transaction Service
│   ├── start-ai-service.sh              # Iniciar AI Service
│   ├── test-with-ai.sh                  # Teste completo do sistema
│   ├── test-ai-categorization.sh        # Teste de categorização IA
│   ├── test-auth-service.sh             # Teste do Auth Service
│   ├── test-complete-flow.sh            # Teste de fluxo completo
│   └── test-flow.sh                     # Teste de fluxo básico
│
├── 📂 docs/                              # 📚 Documentação
│   ├── README.md                        # Índice da documentação
│   │
│   ├── 📂 guides/                       # Guias de uso
│   │   ├── DOCKER_GUIDE.md             # Guia completo Docker
│   │   ├── GUIA_EXECUCAO.md            # Guia execução local
│   │   ├── INICIO_RAPIDO.md            # Início rápido
│   │   └── COMANDOS.txt                # Comandos úteis
│   │
│   ├── 📂 tests/                        # Documentação de testes
│   │   └── TESTES_FINAIS.md            # Resultados dos testes
│   │
│   ├── PROJETO_COMPLETO.md             # Arquitetura completa
│   ├── AI_SERVICE_COMPLETO.md          # Documentação do AI Service
│   ├── EXECUTIVE_SUMARY.md             # Resumo executivo
│   ├── DOCUMENTATION_INDEX.md          # Índice de documentação
│   ├── CHECKLIST.md                    # Checklist de implementação
│   ├── FASE1_README.md                 # Documentação Fase 1
│   ├── FASE2_PLAN.md                   # Planejamento Fase 2
│   ├── FASE3_PLAN.md                   # Planejamento Fase 3
│   └── FASE4_PLAN.md                   # Planejamento Fase 4
│
├── 📂 services/                          # 🚀 Microsserviços
│   │
│   ├── 📂 auth-service/                 # Serviço de Autenticação (Go)
│   │   ├── Dockerfile                  # Build do container
│   │   ├── go.mod                      # Dependências Go
│   │   ├── go.sum                      # Checksums das dependências
│   │   ├── main.go                     # Ponto de entrada
│   │   ├── .env.example                # Exemplo de configuração
│   │   │
│   │   ├── 📂 config/                  # Configurações
│   │   │   └── config.go
│   │   ├── 📂 handlers/                # Handlers HTTP
│   │   │   └── auth_handler.go
│   │   ├── 📂 middleware/              # Middlewares
│   │   │   └── auth_middleware.go
│   │   ├── 📂 models/                  # Modelos de dados
│   │   │   └── user.go
│   │   ├── 📂 repository/              # Camada de dados
│   │   │   ├── user_repository.go
│   │   │   └── redis.go
│   │   └── 📂 metrics/                 # Métricas Prometheus
│   │       └── metrics.go
│   │
│   ├── 📂 trasaction-service/           # Serviço de Transações (Go)
│   │   ├── Dockerfile
│   │   ├── go.mod
│   │   ├── go.sum
│   │   ├── main.go
│   │   ├── .env.example
│   │   │
│   │   ├── 📂 handlers/
│   │   │   └── transaction_handler.go
│   │   ├── 📂 models/
│   │   │   └── transaction.go
│   │   ├── 📂 repository/
│   │   │   └── transaction_repository.go
│   │   ├── 📂 messaging/               # RabbitMQ
│   │   │   └── publisher.go
│   │   └── 📂 metrics/
│   │       └── metrics.go
│   │
│   └── 📂 ai-service/                   # Serviço de IA (Python)
│       ├── Dockerfile
│       ├── requirements.txt            # Dependências Python
│       ├── main.py                     # Ponto de entrada
│       ├── .env.example
│       │
│       ├── categorizer.py              # Modelo de categorização ML
│       ├── config.py                   # Configurações
│       ├── logger.py                   # Logging estruturado
│       └── 📂 menssaging/              # RabbitMQ consumer
│           └── consumer.py
│
├── 📂 config/                            # ⚙️ Configurações de Infraestrutura
│   │
│   ├── 📂 grafana/                      # Dashboards e datasources
│   │   ├── 📂 provisioning/
│   │   └── 📂 dashboards/
│   │
│   ├── 📂 prometheus/                   # Configuração de métricas
│   │   └── prometheus.yml
│   │
│   ├── 📂 loki/                         # Configuração de logs
│   │   └── loki-config.yml
│   │
│   └── 📂 promtail/                     # Coleta de logs
│       └── promtail-config.yml
│
├── 📂 init-scripts/                      # 🗄️ Scripts de Inicialização
│   └── 📂 postgres/
│       └── 001_init.sql                # Schema inicial do banco
│
└── 📂 .github/                           # 🔄 CI/CD
    └── 📂 workflows/
        └── ci.yml                       # GitHub Actions
```

---

## 📊 Volumes Docker

Criados automaticamente pelo docker-compose:

```
volumes/
├── postgres-data/          # Dados do PostgreSQL
├── redis-data/             # Dados do Redis
├── rabbitmq-data/          # Dados do RabbitMQ
├── prometheus-data/        # Métricas do Prometheus
├── grafana-data/           # Dashboards do Grafana
├── loki-data/              # Logs do Loki
└── ai-models/              # Modelos ML treinados
```

---

## 🌐 Portas Utilizadas

| Porta | Serviço | Descrição |
|-------|---------|-----------|
| 8001 | Auth Service | API de autenticação |
| 8002 | Transaction Service | API de transações |
| 8003 | AI Service | Métricas do ML |
| 5432 | PostgreSQL | Banco de dados |
| 6379 | Redis | Cache e sessões |
| 5672 | RabbitMQ AMQP | Mensageria |
| 15672 | RabbitMQ Management | Interface web |
| 9090 | Prometheus | Métricas |
| 3000 | Grafana | Dashboards |
| 16686 | Jaeger | Tracing distribuído |
| 3100 | Loki | Agregação de logs |
| 8080 | Adminer | Interface PostgreSQL |
| 8081 | Redis Commander | Interface Redis |

---

## 🔑 Arquivos Importantes

### Raiz do Projeto
- **README.md** - Documentação principal, comece aqui
- **STRUCTURE.md** - Este arquivo
- **docker-compose.yml** - Define toda a infraestrutura
- **Makefile** - Comandos úteis (make help)

### Scripts Essenciais
- **scripts/start-docker.sh** - Forma mais fácil de rodar tudo
- **scripts/test-with-ai.sh** - Testa todo o sistema

### Documentação Principal
- **docs/guides/DOCKER_GUIDE.md** - Guia completo Docker
- **docs/PROJETO_COMPLETO.md** - Arquitetura técnica
- **docs/AI_SERVICE_COMPLETO.md** - Como funciona a IA

---

## 🎯 Navegação Rápida

### Quero rodar o projeto
→ `./scripts/start-docker.sh`

### Quero entender a arquitetura
→ `docs/PROJETO_COMPLETO.md`

### Quero desenvolver
→ `services/<nome-do-servico>/`

### Quero ver os testes
→ `docs/tests/TESTES_FINAIS.md`

### Quero configurar algo
→ `config/` ou `.env.example` nos serviços

---

## 📝 Convenções

### Nomenclatura
- **Scripts:** `kebab-case.sh`
- **Documentos:** `UPPER_SNAKE_CASE.md`
- **Código Go:** `snake_case.go`
- **Código Python:** `snake_case.py`

### Estrutura de Pastas
- `📂 services/` - Código dos microsserviços
- `📂 scripts/` - Automação e testes
- `📂 docs/` - Toda documentação
- `📂 config/` - Configurações de infraestrutura
- `📂 init-scripts/` - Inicialização de bancos

---

**Última atualização:** 2025-10-18  
**Versão:** 1.0.0
