# 📚 Documentação OrcaPro

Índice completo da documentação do projeto.

---

## 🚀 Guias de Início Rápido

### Para Usuários
- **[INICIO_RAPIDO.md](guides/INICIO_RAPIDO.md)** - Comece aqui! Guia de 3 passos
- **[DOCKER_GUIDE.md](guides/DOCKER_GUIDE.md)** - Guia completo usando Docker
- **[GUIA_EXECUCAO.md](guides/GUIA_EXECUCAO.md)** - Guia para execução local
- **[COMANDOS.txt](guides/COMANDOS.txt)** - Lista de comandos úteis

---

## 🏗️ Documentação Técnica

### Arquitetura
- **[PROJETO_COMPLETO.md](PROJETO_COMPLETO.md)** - Arquitetura completa do sistema
- **[EXECUTIVE_SUMARY.md](EXECUTIVE_SUMARY.md)** - Resumo executivo
- **[CHECKLIST.md](CHECKLIST.md)** - Checklist de implementação

### Serviços
- **[AI_SERVICE_COMPLETO.md](AI_SERVICE_COMPLETO.md)** - Documentação completa do AI Service
- **[FASE1_README.md](FASE1_README.md)** - Documentação da Fase 1

### Fases do Projeto
- **[FASE2_PLAN.md](FASE2_PLAN.md)** - Planejamento Fase 2
- **[FASE3_PLAN.md](FASE3_PLAN.md)** - Planejamento Fase 3
- **[FASE4_PLAN.md](FASE4_PLAN.md)** - Planejamento Fase 4

---

## 🧪 Testes e Validação

- **[TESTES_FINAIS.md](tests/TESTES_FINAIS.md)** - Resultados dos testes completos
- **Scripts de teste:** Veja `/scripts/test-*.sh`

---

## 📊 Estrutura do Projeto

```
OrcaPro/
├── README.md                    # Documentação principal
├── docker-compose.yml           # Orquestração Docker
├── Makefile                     # Comandos make
│
├── scripts/                     # Scripts de automação
│   ├── start-docker.sh         # Iniciar com Docker
│   ├── start-all.sh            # Preparar ambiente local
│   ├── start-auth-service.sh   # Iniciar Auth Service
│   ├── start-transaction-service.sh
│   ├── start-ai-service.sh
│   ├── test-with-ai.sh         # Testes completos
│   └── ...
│
├── docs/                        # Documentação
│   ├── README.md               # Este arquivo
│   ├── guides/                 # Guias de uso
│   │   ├── DOCKER_GUIDE.md
│   │   ├── GUIA_EXECUCAO.md
│   │   └── COMANDOS.txt
│   ├── tests/                  # Documentação de testes
│   │   └── TESTES_FINAIS.md
│   └── *.md                    # Docs técnicos
│
├── services/                    # Microsserviços
│   ├── auth-service/           # Serviço de autenticação (Go)
│   ├── trasaction-service/     # Serviço de transações (Go)
│   └── ai-service/             # Serviço de IA (Python)
│
├── config/                      # Configurações
│   ├── grafana/
│   ├── prometheus/
│   ├── loki/
│   └── promtail/
│
└── init-scripts/                # Scripts de inicialização
    └── postgres/
```

---

## 🎯 Fluxo de Leitura Recomendado

### 1. Para Começar Rapidamente
1. [INICIO_RAPIDO.md](guides/INICIO_RAPIDO.md)
2. [DOCKER_GUIDE.md](guides/DOCKER_GUIDE.md) ou [GUIA_EXECUCAO.md](guides/GUIA_EXECUCAO.md)
3. [COMANDOS.txt](guides/COMANDOS.txt)

### 2. Para Entender o Sistema
1. [EXECUTIVE_SUMARY.md](EXECUTIVE_SUMARY.md)
2. [PROJETO_COMPLETO.md](PROJETO_COMPLETO.md)
3. [AI_SERVICE_COMPLETO.md](AI_SERVICE_COMPLETO.md)

### 3. Para Desenvolver
1. [CHECKLIST.md](CHECKLIST.md)
2. [FASE2_PLAN.md](FASE2_PLAN.md)
3. Código fonte em `/services/`

---

## 🔗 Links Úteis

### Interfaces Web (quando rodando)
- Auth Service: http://localhost:8001
- Transaction Service: http://localhost:8002
- AI Service: http://localhost:8003
- RabbitMQ: http://localhost:15672
- Grafana: http://localhost:3000
- Prometheus: http://localhost:9090
- Jaeger: http://localhost:16686

### Repositórios
- GitHub: [TManoloss/OrcaPro](https://github.com/TManoloss/OrcaPro)

---

## 📝 Convenções

### Nomenclatura de Arquivos
- `*_GUIDE.md` - Guias passo a passo
- `*_PLAN.md` - Planejamento de fases
- `*_README.md` - Documentação de componentes
- `*.txt` - Referências rápidas

### Estrutura de Documentos
- Todos os docs usam Markdown
- Emojis para melhor visualização
- Código com syntax highlighting
- Links relativos entre documentos

---

## 🆘 Precisa de Ajuda?

1. **Início Rápido:** [INICIO_RAPIDO.md](guides/INICIO_RAPIDO.md)
2. **Problemas Comuns:** Ver seção Troubleshooting nos guias
3. **Comandos:** [COMANDOS.txt](guides/COMANDOS.txt)
4. **Arquitetura:** [PROJETO_COMPLETO.md](PROJETO_COMPLETO.md)

---

**Última atualização:** 2025-10-18  
**Versão:** 1.0.0
