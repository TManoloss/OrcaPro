# 🚀 Guia de Deploy - OrcaPro

## ⚠️ Execução Manual Necessária

Devido às permissões do sistema, você precisa executar os comandos manualmente no terminal.

## 📋 Comandos para Executar

### 1. Navegar para o diretório do projeto
```bash
cd /home/manoelfelip/Documentos/projetos/OrcaPro
```

### 2. Parar containers existentes (se houver)
```bash
sudo docker compose down
```

### 3. Construir as imagens
```bash
sudo docker compose build --no-cache
```

### 4. Iniciar todos os serviços em produção
```bash
sudo docker compose up -d
```

### 5. Verificar status dos serviços
```bash
sudo docker compose ps
```

### 6. Verificar logs (opcional)
```bash
sudo docker compose logs -f
```

## 🔍 Verificação de Funcionamento

Após executar os comandos acima, você pode verificar se tudo está funcionando:

### Health Checks
```bash
curl http://localhost:8000/health  # API Gateway
curl http://localhost:8001/health  # Auth Service
curl http://localhost:8002/health  # Transaction Service
curl http://localhost:8003/health  # AI Service
curl http://localhost:8004/health  # Notification Service
```

### URLs de Monitoramento
- **API Gateway**: http://localhost:8000
- **Auth Service**: http://localhost:8001
- **Transaction Service**: http://localhost:8002
- **AI Service**: http://localhost:8003
- **Notification Service**: http://localhost:8004
- **Grafana**: http://localhost:3000 (admin/admin123)
- **Prometheus**: http://localhost:9090
- **Jaeger**: http://localhost:16686
- **RabbitMQ**: http://localhost:15672 (admin/admin123)

## 🧪 Teste Rápido da API

Após iniciar os serviços, você pode testar com:

```bash
# 1. Health check
curl http://localhost:8000/health

# 2. Registrar usuário
curl -X POST http://localhost:8000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "name": "Test User",
    "password": "senha123456"
  }'

# 3. Login
TOKEN=$(curl -s -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"senha123456"}' \
  | jq -r '.access_token')

# 4. Criar transação
curl -X POST http://localhost:8000/api/v1/transactions \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "description": "Teste de transação",
    "amount": 100.50,
    "category": "Alimentação",
    "type": "expense",
    "date": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"
  }'
```

## 🐛 Troubleshooting

### Se algum serviço não iniciar:
```bash
# Ver logs específicos
sudo docker compose logs auth-service
sudo docker compose logs transaction-service
sudo docker compose logs api-gateway

# Reiniciar serviço específico
sudo docker compose restart auth-service
```

### Se houver problemas de porta:
```bash
# Verificar o que está usando as portas
sudo lsof -i :8000
sudo lsof -i :8001
sudo lsof -i :8002
```

### Limpar tudo e recomeçar:
```bash
sudo docker compose down -v
sudo docker compose up -d --build
```

## 📊 Monitoramento

Após iniciar, você pode acessar:
- **Grafana** em http://localhost:3000 para dashboards
- **Prometheus** em http://localhost:9090 para métricas
- **Jaeger** em http://localhost:16686 para traces

**Credenciais do Grafana**: admin / admin123

---

**⚠️ Execute os comandos acima no seu terminal para iniciar todos os serviços!**
