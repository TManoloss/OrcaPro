# ✅ Checklist de Validação - Fase 1

Use este checklist para validar que tudo está funcionando corretamente.

## 📦 Infraestrutura Base

- [ ] Docker e Docker Compose instalados
- [ ] Todos os containers iniciaram com sucesso (`make ps`)
- [ ] PostgreSQL está healthy
- [ ] Redis está healthy
- [ ] RabbitMQ está healthy
- [ ] Prometheus está coletando métricas
- [ ] Grafana está acessível
- [ ] Jaeger está acessível
- [ ] Loki está recebendo logs

## 🔐 Auth Service

- [ ] Serviço iniciou sem erros (`make logs-auth-service`)
- [ ] Health check responde: `curl http://localhost:8001/health`
- [ ] Endpoint /metrics expõe métricas: `curl http://localhost:8001/metrics`
- [ ] Registro de usuário funciona
- [ ] Login retorna access_token e refresh_token
- [ ] Endpoint /me retorna dados do usuário autenticado
- [ ] Refresh token funciona
- [ ] Logout adiciona token à blacklist
- [ ] Token inválido retorna 401

### Métricas Auth Service
- [ ] `user_registrations_total` incrementa ao registrar
- [ ] `user_logins_total` incrementa ao fazer login
- [ ] `jwt_tokens_generated_total` incrementa
- [ ] `http_requests_total` registra todas as requisições
- [ ] `http_request_duration_seconds` registra latências

## 💰 Transaction Service

- [ ] Serviço iniciou sem erros (`make logs-transaction-service`)
- [ ] Health check responde: `curl http://localhost:8002/health`
- [ ] Endpoint /metrics expõe métricas: `curl http://localhost:8002/metrics`
- [ ] Criar transação funciona (com JWT válido)
- [ ] Listar transações funciona
- [ ] Buscar transação por ID funciona
- [ ] Atualizar transação funciona
- [ ] Deletar transação funciona
- [ ] Endpoint de estatísticas funciona
- [ ] Filtros de listagem funcionam (type, category, date)
- [ ] Paginação funciona

### Métricas Transaction Service
- [ ] `transactions_created_total` incrementa ao criar
- [ ] `transactions_updated_total` incrementa ao atualizar
- [ ] `transactions_deleted_total` incrementa ao deletar
- [ ] `transaction_amount` registra valores
- [ ] `rabbitmq_messages_published_total` incrementa

## 📨 RabbitMQ - Mensageria

- [ ] Exchange `transactions_exchange` foi criado
- [ ] Tipo do exchange é `topic`
- [ ] Mensagens são publicadas ao criar transação
- [ ] Mensagens contêm trace_id
- [ ] Routing key `transaction.created` funciona
- [ ] Routing key `transaction.updated` funciona
- [ ] Routing key `transaction.deleted` funciona
- [ ] Management UI mostra mensagens: http://localhost:15672

## 📊 Prometheus - Métricas

- [ ] Prometheus está acessível: http://localhost:9090
- [ ] Target `auth-service` está UP
- [ ] Target `transaction-service` está UP
- [ ] Query `user_registrations_total` retorna dados
- [ ] Query `transactions_created_total` retorna dados
- [ ] Query `rate(http_requests_total[5m])` funciona
- [ ] Query de latência P95 funciona

## 📈 Grafana - Visualização

- [ ] Grafana está acessível: http://localhost:3000
- [ ] Login funciona (admin/admin123)
- [ ] Datasource Prometheus está configurado
- [ ] Datasource Loki está configurado
- [ ] Datasource Jaeger está configurado
- [ ] Datasource PostgreSQL está configurado
- [ ] Consegue criar um painel com métricas
- [ ] Explore funciona com Prometheus
- [ ] Explore funciona com Loki

## 🔍 Jaeger - Tracing

- [ ] Jaeger está acessível: http://localhost:16686
- [ ] Service `auth-service` aparece na lista
- [ ] Service `transaction-service` aparece na lista
- [ ] Consegue buscar traces
- [ ] Traces mostram spans completos
- [ ] trace_id é propagado entre operações
- [ ] Latências estão sendo medidas

## 📝 Loki - Logs

- [ ] Loki está recebendo logs
- [ ] Query `{service="auth-service"}` retorna logs
- [ ] Query `{service="transaction-service"}` retorna logs
- [ ] Logs estão em formato JSON
- [ ] Logs contêm trace_id
- [ ] Logs contêm level (info, error, etc)
- [ ] Filtro por level funciona
- [ ] Busca por trace_id funciona

## 🗄️ PostgreSQL

- [ ] Banco `app_database` existe
- [ ] Tabela `users` foi criada
- [ ] Tabela `transactions` foi criada
- [ ] Índices foram criados
- [ ] Triggers de updated_at funcionam
- [ ] Foreign keys funcionam
- [ ] Adminer está acessível: http://localhost:8080

## 🔴 Redis

- [ ] Redis está respondendo
- [ ] Blacklist de tokens funciona
- [ ] TTL dos tokens funciona
- [ ] Redis Commander está acessível: http://localhost:8081

## 🧪 Teste Automatizado

- [ ] Script `test-flow.sh` tem permissão de execução
- [ ] Script executa sem erros
- [ ] Todas as 8 etapas passam
- [ ] Usuário é registrado
- [ ] Login retorna tokens
- [ ] Transações são criadas
- [ ] Estatísticas são calculadas

## 🔗 Integração End-to-End

- [ ] Criar transação → Evento publicado no RabbitMQ
- [ ] trace_id é propagado em toda a requisição
- [ ] Logs de auth e transaction têm o mesmo trace_id
- [ ] Métricas refletem as operações realizadas
- [ ] Traces no Jaeger mostram fluxo completo

## 📚 Documentação

- [ ] README.md está completo
- [ ] FASE1_README.md está completo
- [ ] SETUP.md está completo
- [ ] Todos os endpoints estão documentados
- [ ] Queries de observabilidade estão documentadas
- [ ] Troubleshooting está documentado

## 🔒 Segurança (Dev)

- [ ] .env não está commitado no git
- [ ] .gitignore está configurado
- [ ] Senhas padrão são apenas para desenvolvimento
- [ ] JWT secret é configurável via env
- [ ] Passwords são hasheados com bcrypt

## ⚡ Performance

- [ ] Requisições respondem em < 100ms (sem carga)
- [ ] Publicação no RabbitMQ é assíncrona
- [ ] Índices do banco estão otimizados
- [ ] Conexões com banco são reutilizadas
- [ ] Não há memory leaks visíveis

## 🎯 Próximos Passos

- [ ] Implementar Fase 2 (Serviço de IA)
- [ ] Adicionar testes unitários
- [ ] Adicionar testes de integração
- [ ] Configurar CI/CD
- [ ] Adicionar rate limiting
- [ ] Implementar circuit breaker
- [ ] Adicionar dead letter queue
- [ ] Configurar alertas no Grafana

---

## 📊 Resultado

**Total de itens:** 100+  
**Completados:** ___  
**Pendentes:** ___  
**Bloqueados:** ___

**Status Geral:** 🟢 Pronto / 🟡 Quase / 🔴 Problemas

---

**Data da validação:** ___________  
**Validado por:** ___________
