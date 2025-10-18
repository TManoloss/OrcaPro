# ✅ Production Readiness Checklist

Checklist completo para garantir que sua aplicação está pronta para produção.

## 🔐 Segurança

### Secrets e Credenciais
- [ ] Todas as senhas padrão foram alteradas
- [ ] JWT_SECRET é forte e aleatório (mínimo 256 bits)
- [ ] Credenciais estão em secret manager (Vault, AWS Secrets, GCP Secret Manager)
- [ ] Secrets não estão commitados no Git
- [ ] `.env` está no `.gitignore`
- [ ] Rotação automática de secrets configurada
- [ ] Acesso aos secrets é auditado

### Autenticação e Autorização
- [ ] HTTPS/TLS configurado em todos os endpoints públicos
- [ ] JWT expiration configurado adequadamente (15-60 min)
- [ ] Refresh tokens implementados
- [ ] Token blacklist/revogação funciona
- [ ] Rate limiting implementado
- [ ] CORS configurado corretamente
- [ ] Validação de entrada em todos os endpoints
- [ ] Proteção contra SQL Injection
- [ ] Proteção contra XSS
- [ ] CSRF tokens onde necessário

### Network e Firewall
- [ ] Firewall rules configuradas
- [ ] Apenas portas necessárias expostas
- [ ] Network policies no Kubernetes
- [ ] Serviços internos não expostos publicamente
- [ ] VPN/Bastion para acesso interno
- [ ] DDoS protection configurado
- [ ] WAF (Web Application Firewall) em produção

## 🗄️ Database

### Performance e Escala
- [ ] Índices criados em colunas frequentemente consultadas
- [ ] Query performance analisada (EXPLAIN ANALYZE)
- [ ] Connection pooling configurado
- [ ] Timeout de queries configurado
- [ ] Prepared statements utilizados
- [ ] N+1 queries identificadas e otimizadas
- [ ] Database sharding planejado (se necessário)
- [ ] Read replicas configuradas (se necessário)

### Backup e Recovery
- [ ] Backups automáticos diários configurados
- [ ] Backups testados (restore funcionando)
- [ ] Retenção de backups definida (30-90 dias)
- [ ] Backups offsite/região diferente
- [ ] Point-in-time recovery possível
- [ ] Disaster recovery plan documentado
- [ ] RTO e RPO definidos
- [ ] Runbook de recovery criado

### Migrations
- [ ] Sistema de migrations implementado
- [ ] Migrations são reversíveis (down migrations)
- [ ] Migrations testadas em staging
- [ ] Zero-downtime migrations strategy
- [ ] Rollback plan para cada migration

## 🔍 Observabilidade

### Logging
- [ ] Logs estruturados (JSON)
- [ ] Log levels apropriados (DEBUG, INFO, WARN, ERROR)
- [ ] Sensitive data não logada (senhas, tokens, PII)
- [ ] Logs centralizados (Loki, ELK, Datadog)
- [ ] Log retention policy definida
- [ ] Logs incluem trace_id, request_id
- [ ] Correlation IDs para requisições distribuídas
- [ ] Log rotation configurado

### Metrics
- [ ] Métricas de negócio implementadas
- [ ] Métricas técnicas (RED/USE) implementadas
- [ ] Prometheus exporters configurados
- [ ] Métricas estão sendo coletadas
- [ ] Dashboards criados no Grafana
- [ ] SLIs (Service Level Indicators) definidos
- [ ] SLOs (Service Level Objectives) definidos
- [ ] Métricas de custo monitoradas

### Tracing
- [ ] Distributed tracing implementado
- [ ] Trace_id propagado entre serviços
- [ ] Sampling rate configurado (1-10% em prod)
- [ ] Jaeger/Tempo configurado
- [ ] Traces correlacionados com logs
- [ ] Spans incluem informações relevantes
- [ ] Performance overhead medido

### Alerting
- [ ] Alertas críticos configurados
- [ ] Alertas têm runbooks associados
- [ ] On-call rotation definida
- [ ] PagerDuty/Opsgenie configurado
- [ ] Alert fatigue evitado (alertas acionáveis)
- [ ] Escalation policy definida
- [ ] Alertas testados
- [ ] Silencing e maintenance windows configurados

## 🚀 Deploy e CI/CD

### Pipeline
- [ ] CI/CD pipeline automatizado
- [ ] Testes automatizados (unit, integration, e2e)
- [ ] Code coverage > 70%
- [ ] Linting e formatting automatizados
- [ ] Security scanning (Snyk, Trivy)
- [ ] Dependency scanning
- [ ] Container scanning
- [ ] Static code analysis (SonarQube)

### Deploy Strategy
- [ ] Blue-green ou canary deployment
- [ ] Health checks configurados
- [ ] Readiness probes configurados
- [ ] Liveness probes configurados
- [ ] Graceful shutdown implementado
- [ ] Zero-downtime deployment
- [ ] Rollback automatizado em caso de falha
- [ ] Feature flags para deploys graduais

### Environments
- [ ] Dev, Staging, Production separados
- [ ] Staging é cópia de produção
- [ ] Dados de teste não vazam para produção
- [ ] Configurações por ambiente (12-factor)
- [ ] Smoke tests em staging antes de prod

## 📊 Performance

### Application
- [ ] Response time < 200ms para 95% das requests
- [ ] Throughput adequado para carga esperada
- [ ] Memory leaks identificados e corrigidos
- [ ] Goroutine/thread leaks identificados
- [ ] Connection pooling otimizado
- [ ] Caching strategy implementada
- [ ] CDN para assets estáticos
- [ ] Compressão (gzip) habilitada

### Load Testing
- [ ] Load tests executados
- [ ] Stress tests executados
- [ ] Spike tests executados
- [ ] Soak tests executados (24h+)
- [ ] Bottlenecks identificados
- [ ] Capacity planning feito
- [ ] Auto-scaling configurado
- [ ] Circuit breakers implementados

## 🔄 Resiliência

### Error Handling
- [ ] Todos os erros são tratados
- [ ] Errors retornam status codes apropriados
- [ ] Error messages são user-friendly
- [ ] Stack traces não expostas
- [ ] Error budget definido
- [ ] Chaos engineering praticado

### Retry e Timeout
- [ ] Retry policy implementada (com backoff exponencial)
- [ ] Timeouts configurados em todas as chamadas externas
- [ ] Circuit breaker pattern implementado
- [ ] Bulkhead pattern onde aplicável
- [ ] Dead letter queue para mensagens falhadas
- [ ] Idempotency garantida

### High Availability
- [ ] Múltiplas réplicas rodando
- [ ] Load balancing configurado
- [ ] Health checks ativos
- [ ] Failover automático
- [ ] Multi-AZ deployment
- [ ] Disaster recovery testado
- [ ] SLA definido e monitorado

## 📋 Compliance e Governança

### Data Privacy
- [ ] LGPD/GDPR compliance verificado
- [ ] PII identificada e protegida
- [ ] Data retention policy implementada
- [ ] Right to be forgotten implementado
- [ ] Data encryption at rest
- [ ] Data encryption in transit
- [ ] Audit logs para acesso a dados sensíveis

### Documentation
- [ ] API documentation atualizada (Swagger/OpenAPI)
- [ ] Architecture diagrams atualizados
- [ ] Runbooks criados para operações comuns
- [ ] Postmortems de incidentes documentados
- [ ] README.md completo e atualizado
- [ ] Onboarding guide para novos devs
- [ ] Change log mantido (CHANGELOG.md)

## 🧪 Testing

### Automated Tests
- [ ] Unit tests (> 70% coverage)
- [ ] Integration tests
- [ ] End-to-end tests
- [ ] Contract tests (para APIs)
- [ ] Performance tests
- [ ] Security tests (OWASP Top 10)
- [ ] Chaos tests

### Manual Testing
- [ ] Smoke tests executados
- [ ] UAT (User Acceptance Testing) completo
- [ ] Penetration testing realizado
- [ ] Accessibility testing (WCAG)

## 💰 Cost Optimization

### Resources
- [ ] Resource requests/limits configurados
- [ ] Auto-scaling baseado em métricas
- [ ] Spot instances onde possível
- [ ] Reserved instances para cargas previsíveis
- [ ] Storage lifecycle policies
- [ ] Log retention otimizada
- [ ] Métricas de custo monitoradas
- [ ] FinOps practices implementadas

## 📞 Support e Operações

### Monitoring e On-call
- [ ] On-call rotation definida
- [ ] Escalation matrix criada
- [ ] SLA/SLO documentados
- [ ] Incident response plan
- [ ] Postmortem template
- [ ] Status page configurada
- [ ] Customer communication plan

### Maintenance
- [ ] Maintenance windows definidas
- [ ] Runbooks atualizados
- [ ] Emergency procedures documentadas
- [ ] Contact list atualizada
- [ ] Backup restore testado regularmente

## 🔧 Infrastructure as Code

### IaC
- [ ] Infraestrutura versionada (Terraform, CloudFormation)
- [ ] Environments replicáveis
- [ ] State management configurado
- [ ] Drift detection ativo
- [ ] Changes via PR/MR
- [ ] Infrastructure tests

## 📱 Kubernetes Specific (se aplicável)

### Configuration
- [ ] Resource requests/limits definidos
- [ ] HPA (Horizontal Pod Autoscaler) configurado
- [ ] PDB (Pod Disruption Budget) configurado
- [ ] Network policies configuradas
- [ ] RBAC configurado
- [ ] Service mesh considerado (Istio, Linkerd)
- [ ] Ingress/Gateway configurado
- [ ] TLS certificates gerenciados (cert-manager)

### Security
- [ ] Pod Security Policies aplicadas
- [ ] Secrets não em configmaps
- [ ] Image scanning habilitado
- [ ] Registry privado utilizado
- [ ] Non-root containers
- [ ] Read-only root filesystem
- [ ] Security context configurado

## 🎯 Go Specific Best Practices

### Code Quality
- [ ] `go vet` passa sem erros
- [ ] `golangci-lint` configurado e passa
- [ ] Error handling completo (não ignora erros)
- [ ] Context propagado corretamente
- [ ] Goroutines não vazam
- [ ] Defer usado apropriadamente
- [ ] Panic/recover usado apenas onde necessário
- [ ] Race detector executado (`go test -race`)

### Performance
- [ ] Profiling realizado (pprof)
- [ ] Memory allocations otimizadas
- [ ] String concatenation otimizada
- [ ] Sync.Pool usado onde apropriado
- [ ] Buffered channels dimensionados
- [ ] Worker pools implementados corretamente

## ✅ Final Checklist

Antes do go-live:

- [ ] Code review completo
- [ ] Security review completo
- [ ] Performance review completo
- [ ] Load testing passou
- [ ] Staging aprovado
- [ ] Documentação atualizada
- [ ] Runbooks prontos
- [ ] On-call definido
- [ ] Rollback plan pronto
- [ ] Stakeholders notificados
- [ ] Go/No-Go meeting realizado

---

**🎉 Pronto para Produção!**

Lembre-se: Este checklist deve ser adaptado às necessidades específicas do seu projeto. Nem todos os itens são aplicáveis a todos os projetos.