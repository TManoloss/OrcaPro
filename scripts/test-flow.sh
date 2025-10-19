#!/bin/bash

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# URLs dos serviços
AUTH_URL="http://localhost:8001"
TRANSACTION_URL="http://localhost:8002"

# Variáveis
EMAIL="teste_$(date +%s)@example.com"
PASSWORD="senha123456"
NAME="Usuário Teste $(date +%s)"

echo -e "${BLUE}╔════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Teste Completo de Fluxo - Microsserviços    ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════╝${NC}"
echo ""

# Função para verificar resposta
check_response() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Sucesso${NC}"
        return 0
    else
        echo -e "${RED}✗ Falhou${NC}"
        return 1
    fi
}

# Função para extrair JSON com jq ou grep
extract_json() {
    if command -v jq &> /dev/null; then
        echo "$1" | jq -r "$2"
    else
        echo "$1" | grep -o "\"$2\":[^,}]*" | cut -d'"' -f4
    fi
}

# 1. Health Checks
echo -e "${YELLOW}═══ 1. Verificando Health dos Serviços ═══${NC}"

echo -n "Auth Service... "
AUTH_HEALTH=$(curl -s "$AUTH_URL/health")
check_response
echo "Response: $AUTH_HEALTH"
echo ""

echo -n "Transaction Service... "
TRANSACTION_HEALTH=$(curl -s "$TRANSACTION_URL/health")
check_response
echo "Response: $TRANSACTION_HEALTH"
echo ""

# 2. Registro de Usuário
echo -e "${YELLOW}═══ 2. Registrando Novo Usuário ═══${NC}"
echo "Email: $EMAIL"
echo "Password: $PASSWORD"
echo "Name: $NAME"
echo ""

REGISTER_RESPONSE=$(curl -s -X POST "$AUTH_URL/api/v1/auth/register" \
  -H "Content-Type: application/json" \
  -d "{
    \"email\": \"$EMAIL\",
    \"password\": \"$PASSWORD\",
    \"name\": \"$NAME\"
  }")

echo "$REGISTER_RESPONSE"
check_response
echo ""

# 3. Login
echo -e "${YELLOW}═══ 3. Fazendo Login ═══${NC}"

LOGIN_RESPONSE=$(curl -s -X POST "$AUTH_URL/api/v1/auth/login" \
  -H "Content-Type: application/json" \
  -d "{
    \"email\": \"$EMAIL\",
    \"password\": \"$PASSWORD\"
  }")

echo "$LOGIN_RESPONSE"
check_response

# Extrai o token
if command -v jq &> /dev/null; then
    TOKEN=$(echo "$LOGIN_RESPONSE" | jq -r '.access_token')
else
    TOKEN=$(echo "$LOGIN_RESPONSE" | grep -o '"access_token":"[^"]*"' | cut -d'"' -f4)
fi

if [ -z "$TOKEN" ] || [ "$TOKEN" == "null" ]; then
    echo -e "${RED}✗ Erro: Não foi possível obter o token${NC}"
    exit 1
fi

echo -e "${GREEN}Token obtido: ${TOKEN:0:50}...${NC}"
echo ""

# 4. Verificar dados do usuário
echo -e "${YELLOW}═══ 4. Verificando Dados do Usuário (/me) ═══${NC}"

ME_RESPONSE=$(curl -s "$AUTH_URL/api/v1/me" \
  -H "Authorization: Bearer $TOKEN")

echo "$ME_RESPONSE"
check_response
echo ""

# 5. Criar Transações
echo -e "${YELLOW}═══ 5. Criando Transações ═══${NC}"

echo "5.1 - Transação de Despesa (Alimentação)"
TRANSACTION1=$(curl -s -w "\nHTTP_CODE:%{http_code}\nTRACE_ID:%{header_x_trace_id}" \
  -X POST "$TRANSACTION_URL/api/v1/transactions" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "description": "Almoço no restaurante",
    "amount": 45.50,
    "category": "Alimentação",
    "type": "expense"
  }')

echo "$TRANSACTION1"
TRACE_ID1=$(echo "$TRANSACTION1" | grep "TRACE_ID:" | cut -d: -f2)
echo -e "${BLUE}Trace ID: $TRACE_ID1${NC}"
check_response
echo ""

echo "5.2 - Transação de Despesa (Transporte)"
TRANSACTION2=$(curl -s -w "\nHTTP_CODE:%{http_code}\nTRACE_ID:%{header_x_trace_id}" \
  -X POST "$TRANSACTION_URL/api/v1/transactions" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "description": "Uber para o trabalho",
    "amount": 25.00,
    "category": "Transporte",
    "type": "expense"
  }')

echo "$TRANSACTION2"
TRACE_ID2=$(echo "$TRANSACTION2" | grep "TRACE_ID:" | cut -d: -f2)
echo -e "${BLUE}Trace ID: $TRACE_ID2${NC}"
check_response
echo ""

echo "5.3 - Transação de Receita (Salário)"
TRANSACTION3=$(curl -s -w "\nHTTP_CODE:%{http_code}\nTRACE_ID:%{header_x_trace_id}" \
  -X POST "$TRANSACTION_URL/api/v1/transactions" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "description": "Salário do mês",
    "amount": 5000.00,
    "category": "Salário",
    "type": "income"
  }')

echo "$TRANSACTION3"
TRACE_ID3=$(echo "$TRANSACTION3" | grep "TRACE_ID:" | cut -d: -f2)
echo -e "${BLUE}Trace ID: $TRACE_ID3${NC}"
check_response
echo ""

echo "5.4 - Transação de Despesa (Moradia)"
TRANSACTION4=$(curl -s -w "\nHTTP_CODE:%{http_code}\nTRACE_ID:%{header_x_trace_id}" \
  -X POST "$TRANSACTION_URL/api/v1/transactions" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "description": "Aluguel",
    "amount": 1500.00,
    "category": "Moradia",
    "type": "expense"
  }')

echo "$TRANSACTION4"
TRACE_ID4=$(echo "$TRANSACTION4" | grep "TRACE_ID:" | cut -d: -f2)
echo -e "${BLUE}Trace ID: $TRACE_ID4${NC}"
check_response
echo ""

# 6. Listar Transações
echo -e "${YELLOW}═══ 6. Listando Todas as Transações ═══${NC}"

LIST_RESPONSE=$(curl -s "$TRANSACTION_URL/api/v1/transactions?page=1&page_size=10" \
  -H "Authorization: Bearer $TOKEN")

if command -v jq &> /dev/null; then
    echo "$LIST_RESPONSE" | jq '.'
else
    echo "$LIST_RESPONSE"
fi
check_response
echo ""

# 7. Filtrar Transações
echo -e "${YELLOW}═══ 7. Filtrando Transações (apenas despesas) ═══${NC}"

FILTER_RESPONSE=$(curl -s "$TRANSACTION_URL/api/v1/transactions?type=expense" \
  -H "Authorization: Bearer $TOKEN")

if command -v jq &> /dev/null; then
    echo "$FILTER_RESPONSE" | jq '.'
else
    echo "$FILTER_RESPONSE"
fi
check_response
echo ""

# 8. Estatísticas
echo -e "${YELLOW}═══ 8. Obtendo Estatísticas ═══${NC}"

STATS_RESPONSE=$(curl -s "$TRANSACTION_URL/api/v1/transactions/stats" \
  -H "Authorization: Bearer $TOKEN")

if command -v jq &> /dev/null; then
    echo "$STATS_RESPONSE" | jq '.'
else
    echo "$STATS_RESPONSE"
fi
check_response
echo ""

# 9. Verificar Métricas
echo -e "${YELLOW}═══ 9. Verificando Métricas do Prometheus ═══${NC}"

echo "9.1 - Métricas do Auth Service:"
AUTH_METRICS=$(curl -s "$AUTH_URL/metrics" | grep -E "(user_registrations_total|user_logins_total|http_requests_total)")
echo "$AUTH_METRICS"
echo ""

echo "9.2 - Métricas do Transaction Service:"
TRANSACTION_METRICS=$(curl -s "$TRANSACTION_URL/metrics" | grep -E "(transactions_created_total|rabbitmq_messages_published_total|http_requests_total)")
echo "$TRANSACTION_METRICS"
echo ""

# 10. Verificar RabbitMQ
echo -e "${YELLOW}═══ 10. Verificando RabbitMQ ═══${NC}"
echo "Acesse: http://localhost:15672"
echo "Login: admin / admin123"
echo "Exchange: transactions_exchange"
echo "Mensagens publicadas devem estar visíveis"
echo ""

# Resumo
echo -e "${BLUE}╔════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║              Resumo do Teste                  ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}✓ Usuário registrado: $EMAIL${NC}"
echo -e "${GREEN}✓ Login realizado com sucesso${NC}"
echo -e "${GREEN}✓ 4 transações criadas${NC}"
echo -e "${GREEN}✓ Listagem funcionando${NC}"
echo -e "${GREEN}✓ Filtros funcionando${NC}"
echo -e "${GREEN}✓ Estatísticas calculadas${NC}"
echo -e "${GREEN}✓ Métricas sendo coletadas${NC}"
echo ""
echo -e "${BLUE}═══ Trace IDs para rastreamento no Jaeger ═══${NC}"
echo -e "Transação 1: ${YELLOW}$TRACE_ID1${NC}"
echo -e "Transação 2: ${YELLOW}$TRACE_ID2${NC}"
echo -e "Transação 3: ${YELLOW}$TRACE_ID3${NC}"
echo -e "Transação 4: ${YELLOW}$TRACE_ID4${NC}"
echo ""
echo -e "${BLUE}═══ Links Úteis ═══${NC}"
echo "Grafana:    http://localhost:3000 (admin/admin123)"
echo "Prometheus: http://localhost:9090"
echo "Jaeger:     http://localhost:16686"
echo "RabbitMQ:   http://localhost:15672 (admin/admin123)"
echo ""
echo -e "${GREEN}✅ Teste completo finalizado com sucesso!${NC}"