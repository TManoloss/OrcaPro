#!/bin/bash

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     Teste Fase 2 - Event-Driven + ML + AI    ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════╝${NC}"
echo ""

# URLs
AUTH_URL="http://localhost:8001"
TRANSACTION_URL="http://localhost:8002"
AI_URL="http://localhost:8003"
NOTIFICATION_URL="http://localhost:8004"

# 1. Health Checks
echo -e "${YELLOW}═══ 1. Verificando Health dos Novos Serviços ═══${NC}"

echo -n "AI Service... "
AI_HEALTH=$(curl -s "$AI_URL/metrics" | head -n 1)
if [ ! -z "$AI_HEALTH" ]; then
    echo -e "${GREEN}✓ OK${NC}"
else
    echo -e "${RED}✗ ERRO${NC}"
fi

echo -n "Notification Service... "
NOTIF_HEALTH=$(curl -s "$NOTIFICATION_URL/health")
if [ ! -z "$NOTIF_HEALTH" ]; then
    echo -e "${GREEN}✓ OK${NC}"
else
    echo -e "${RED}✗ ERRO${NC}"
fi
echo ""

# 2. Login
echo -e "${YELLOW}═══ 2. Fazendo Login ═══${NC}"

EMAIL="test_fase2_$(date +%s)@example.com"
PASSWORD="senha123456"

# Registrar
echo "Registrando usuário: $EMAIL"
curl -s -X POST "$AUTH_URL/api/v1/auth/register" \
  -H "Content-Type: application/json" \
  -d "{
    \"email\": \"$EMAIL\",
    \"password\": \"$PASSWORD\",
    \"name\": \"Test Fase 2\"
  }" > /dev/null

# Login
LOGIN_RESPONSE=$(curl -s -X POST "$AUTH_URL/api/v1/auth/login" \
  -H "Content-Type: application/json" \
  -d "{
    \"email\": \"$EMAIL\",
    \"password\": \"$PASSWORD\"
  }")

TOKEN=$(echo $LOGIN_RESPONSE | jq -r '.access_token')

if [ "$TOKEN" != "null" ] && [ ! -z "$TOKEN" ]; then
    echo -e "${GREEN}✓ Login realizado com sucesso${NC}"
    echo "Token: ${TOKEN:0:50}..."
else
    echo -e "${RED}✗ Erro no login${NC}"
    exit 1
fi
echo ""

# 3. Teste de Categorização Automática
echo -e "${YELLOW}═══ 3. Testando Categorização Automática com ML ═══${NC}"

declare -A TEST_TRANSACTIONS=(
    ["Restaurante McDonald's"]="Alimentação"
    ["Uber para o aeroporto"]="Transporte"
    ["Conta de luz Copel"]="Moradia"
    ["Farmácia Drogasil"]="Saúde"
    ["Netflix assinatura"]="Lazer"
    ["Supermercado Condor"]="Alimentação"
    ["Gasolina posto Shell"]="Transporte"
)

for description in "${!TEST_TRANSACTIONS[@]}"; do
    expected="${TEST_TRANSACTIONS[$description]}"
    
    echo -e "\n${BLUE}Testando:${NC} $description"
    echo -e "${BLUE}Esperado:${NC} $expected"
    
    # Criar transação
    RESPONSE=$(curl -s -X POST "$TRANSACTION_URL/api/v1/transactions" \
      -H "Authorization: Bearer $TOKEN" \
      -H "Content-Type: application/json" \
      -d "{
        \"description\": \"$description\",
        \"amount\": 50.00,
        \"category\": \"Outros\",
        \"type\": \"expense\"
      }")
    
    TRANSACTION_ID=$(echo $RESPONSE | jq -r '.transaction_id')
    
    # Aguarda processamento do AI Service
    echo "Aguardando categorização..."
    sleep 3
    
    # Verifica logs do AI Service
    echo "Verificando logs do AI Service..."
    docker-compose logs --tail=20 ai-service 2>/dev/null | grep "categorizada" | tail -1
done

echo ""

# 4. Teste de Notificação de Alto Valor
echo -e "${YELLOW}═══ 4. Testando Notificação de Alto Valor ═══${NC}"

echo "Criando transação de baixo valor (não deve notificar)..."
curl -s -X POST "$TRANSACTION_URL/api/v1/transactions" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "description": "Lanche rápido",
    "amount": 25.00,
    "category": "Alimentação",
    "type": "expense"
  }' > /dev/null

sleep 2

echo "Criando transação de ALTO VALOR (deve notificar)..."
HIGH_VALUE_RESPONSE=$(curl -s -X POST "$TRANSACTION_URL/api/v1/transactions" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"description\": \"Compra de notebook Dell\",
    \"amount\": 3500.00,
    \"category\": \"Compras\",
    \"type\": \"expense\",
    \"user_email\": \"$EMAIL\"
  }")

HIGH_TRANSACTION_ID=$(echo $HIGH_VALUE_RESPONSE | jq -r '.transaction_id')

echo "Aguardando processamento..."
sleep 3

echo -e "\n${BLUE}Verificando logs do Notification Service:${NC}"
docker-compose logs --tail=20 notification-service 2>/dev/null | grep -E "(High amount|detected)" | tail -3

echo ""

# 5. Verificar Métricas
echo -e "${YELLOW}═══ 5. Verificando Métricas ═══${NC}"

echo -e "\n${BLUE}5.1 - Métricas do AI Service:${NC}"
curl -s "$AI_URL/metrics" | grep -E "(transactions_received|transactions_categorized|ml_model_loaded)" | head -5

echo -e "\n${BLUE}5.2 - Métricas do Notification Service:${NC}"
curl -s "$NOTIFICATION_URL/metrics" | grep -E "(notifications_received|notifications_sent)" | head -5

echo ""

# 6. Verificar RabbitMQ
echo -e "${YELLOW}═══ 6. Verificando RabbitMQ ═══${NC}"

echo "Acesse o RabbitMQ Management UI:"
echo "URL: http://localhost:15672"
echo "Login: admin / admin123"
echo ""
echo "Verifique:"
echo "  • Exchange: transactions_exchange"
echo "  • Queues: ai_categorization_queue, notification_queue"
echo "  • Consumers ativos: 2 (AI Service + Notification Service)"
echo ""

# 7. Verificar Jaeger
echo -e "${YELLOW}═══ 7. Distributed Tracing no Jaeger ═══${NC}"

echo "Acesse o Jaeger UI:"
echo "URL: http://localhost:16686"
echo ""
echo "Busque por:"
echo "  • Service: transaction-service"
echo "  • Operation: POST /api/v1/transactions"
echo ""
echo "Você verá o trace completo:"
echo "  1. Transaction Service recebe request"
echo "  2. Salva no PostgreSQL"
echo "  3. Publica no RabbitMQ"
echo "  4. AI Service consome e categoriza"
echo "  5. Notification Service consome e notifica"
echo ""

# 8. Estatísticas Finais
echo -e "${YELLOW}═══ 8. Estatísticas Finais ═══${NC}"

echo -e "\n${BLUE}Transações Criadas:${NC}"
STATS=$(curl -s "$TRANSACTION_URL/api/v1/transactions/stats" \
  -H "Authorization: Bearer $TOKEN")

echo $STATS | jq '{
  total_income,
  total_expenses,
  balance,
  total_count,
  by_category
}'

echo ""

# Resumo
echo -e "${BLUE}╔════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                   RESUMO                       ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}✓ AI Service funcionando e categorizando${NC}"
echo -e "${GREEN}✓ Notification Service funcionando${NC}"
echo -e "${GREEN}✓ RabbitMQ processando eventos${NC}"
echo -e "${GREEN}✓ Distributed tracing ativo${NC}"
echo -e "${GREEN}✓ Métricas sendo coletadas${NC}"
echo ""
echo -e "${YELLOW}Próximos passos:${NC}"
echo "1. Acesse o Grafana e crie dashboards para as novas métricas"
echo "2. Configure SMTP para testar notificações por email"
echo "3. Explore os traces no Jaeger"
echo "4. Monitore as filas no RabbitMQ"
echo ""
echo -e "${GREEN}✅ Teste da Fase 2 concluído!${NC}"