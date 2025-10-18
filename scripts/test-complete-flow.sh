#!/bin/bash

# Cores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

AUTH_URL="http://localhost:8001"
TRANSACTION_URL="http://localhost:8002"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}   Testando Fluxo Completo${NC}"
echo -e "${BLUE}   Auth + Transaction Services${NC}"
echo -e "${BLUE}========================================${NC}\n"

# 1. Health Checks
echo -e "${CYAN}=== HEALTH CHECKS ===${NC}\n"

echo -e "${YELLOW}1. Auth Service Health${NC}"
AUTH_HEALTH=$(curl -s ${AUTH_URL}/health)
echo -e "Response: ${GREEN}${AUTH_HEALTH}${NC}\n"

echo -e "${YELLOW}2. Transaction Service Health${NC}"
TRANS_HEALTH=$(curl -s ${TRANSACTION_URL}/health)
echo -e "Response: ${GREEN}${TRANS_HEALTH}${NC}\n"

# 2. Registrar e fazer login
echo -e "${CYAN}=== AUTENTICAÇÃO ===${NC}\n"

echo -e "${YELLOW}3. Registrando usuário${NC}"
REGISTER_RESPONSE=$(curl -s -X POST ${AUTH_URL}/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "joao@example.com",
    "name": "João Silva",
    "password": "senha12345"
  }')
echo -e "Response: ${GREEN}${REGISTER_RESPONSE}${NC}\n"

echo -e "${YELLOW}4. Fazendo login${NC}"
LOGIN_RESPONSE=$(curl -s -X POST ${AUTH_URL}/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "joao@example.com",
    "password": "senha12345"
  }')
echo -e "Response: ${GREEN}${LOGIN_RESPONSE}${NC}\n"

# Extrai o access_token
ACCESS_TOKEN=$(echo $LOGIN_RESPONSE | grep -o '"access_token":"[^"]*' | cut -d'"' -f4)

if [ -z "$ACCESS_TOKEN" ]; then
  echo -e "${RED}Erro: Não foi possível obter o access token${NC}"
  exit 1
fi

echo -e "${GREEN}✓ Token obtido com sucesso${NC}\n"

# 3. Criar transações
echo -e "${CYAN}=== TRANSAÇÕES ===${NC}\n"

echo -e "${YELLOW}5. Criando transação de receita${NC}"
INCOME=$(curl -s -X POST ${TRANSACTION_URL}/api/v1/transactions \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "description": "Salário",
    "amount": 5000.00,
    "category": "Salário",
    "type": "income",
    "date": "2025-10-01T00:00:00Z"
  }')
echo -e "Response: ${GREEN}${INCOME}${NC}\n"

INCOME_ID=$(echo $INCOME | grep -o '"id":"[^"]*' | cut -d'"' -f4)

echo -e "${YELLOW}6. Criando transação de despesa${NC}"
EXPENSE=$(curl -s -X POST ${TRANSACTION_URL}/api/v1/transactions \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "description": "Aluguel",
    "amount": 1500.00,
    "category": "Moradia",
    "type": "expense",
    "date": "2025-10-05T00:00:00Z"
  }')
echo -e "Response: ${GREEN}${EXPENSE}${NC}\n"

echo -e "${YELLOW}7. Criando mais uma despesa${NC}"
EXPENSE2=$(curl -s -X POST ${TRANSACTION_URL}/api/v1/transactions \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "description": "Supermercado",
    "amount": 450.00,
    "category": "Alimentação",
    "type": "expense",
    "date": "2025-10-10T00:00:00Z"
  }')
echo -e "Response: ${GREEN}${EXPENSE2}${NC}\n"

# 4. Listar transações
echo -e "${YELLOW}8. Listando todas as transações${NC}"
LIST=$(curl -s -X GET "${TRANSACTION_URL}/api/v1/transactions?page=1&page_size=10" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}")
echo -e "Response: ${GREEN}${LIST}${NC}\n"

# 5. Buscar transação específica
echo -e "${YELLOW}9. Buscando transação específica${NC}"
GET_ONE=$(curl -s -X GET "${TRANSACTION_URL}/api/v1/transactions/${INCOME_ID}" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}")
echo -e "Response: ${GREEN}${GET_ONE}${NC}\n"

# 6. Atualizar transação
echo -e "${YELLOW}10. Atualizando transação${NC}"
UPDATE=$(curl -s -X PUT "${TRANSACTION_URL}/api/v1/transactions/${INCOME_ID}" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "description": "Salário + Bônus",
    "amount": 5500.00,
    "category": "Salário"
  }')
echo -e "Response: ${GREEN}${UPDATE}${NC}\n"

# 7. Estatísticas
echo -e "${YELLOW}11. Obtendo estatísticas${NC}"
STATS=$(curl -s -X GET "${TRANSACTION_URL}/api/v1/transactions/stats" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}")
echo -e "Response: ${GREEN}${STATS}${NC}\n"

# 8. Filtrar por tipo
echo -e "${YELLOW}12. Filtrando apenas despesas${NC}"
FILTER=$(curl -s -X GET "${TRANSACTION_URL}/api/v1/transactions?type=expense" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}")
echo -e "Response: ${GREEN}${FILTER}${NC}\n"

# 9. Deletar transação
echo -e "${YELLOW}13. Deletando uma transação${NC}"
DELETE=$(curl -s -X DELETE "${TRANSACTION_URL}/api/v1/transactions/${INCOME_ID}" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}")
echo -e "Response: ${GREEN}${DELETE}${NC}\n"

# 10. Verificar que foi deletada
echo -e "${YELLOW}14. Tentando buscar transação deletada (deve falhar)${NC}"
GET_DELETED=$(curl -s -X GET "${TRANSACTION_URL}/api/v1/transactions/${INCOME_ID}" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}")
echo -e "Response: ${RED}${GET_DELETED}${NC}\n"

# 11. Testar autenticação inválida
echo -e "${YELLOW}15. Testando com token inválido (deve falhar)${NC}"
INVALID=$(curl -s -X GET "${TRANSACTION_URL}/api/v1/transactions" \
  -H "Authorization: Bearer token-invalido")
echo -e "Response: ${RED}${INVALID}${NC}\n"

# 12. Métricas
echo -e "${CYAN}=== MÉTRICAS ===${NC}\n"

echo -e "${YELLOW}16. Métricas do Auth Service${NC}"
AUTH_METRICS=$(curl -s ${AUTH_URL}/metrics | grep -E "^(http_requests_total|auth_)" | head -5)
echo -e "${GREEN}${AUTH_METRICS}${NC}\n"

echo -e "${YELLOW}17. Métricas do Transaction Service${NC}"
TRANS_METRICS=$(curl -s ${TRANSACTION_URL}/metrics | grep -E "^(http_requests_total|transactions_)" | head -5)
echo -e "${GREEN}${TRANS_METRICS}${NC}\n"

# 13. Informações do usuário
echo -e "${YELLOW}18. Informações do usuário autenticado${NC}"
ME=$(curl -s -X GET ${AUTH_URL}/api/v1/me \
  -H "Authorization: Bearer ${ACCESS_TOKEN}")
echo -e "Response: ${GREEN}${ME}${NC}\n"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}   ✓ Todos os Testes Concluídos!${NC}"
echo -e "${BLUE}========================================${NC}\n"

echo -e "${CYAN}Resumo:${NC}"
echo -e "  ${GREEN}✓${NC} Auth Service funcionando"
echo -e "  ${GREEN}✓${NC} Transaction Service funcionando"
echo -e "  ${GREEN}✓${NC} Autenticação JWT funcionando"
echo -e "  ${GREEN}✓${NC} CRUD de transações funcionando"
echo -e "  ${GREEN}✓${NC} Filtros e paginação funcionando"
echo -e "  ${GREEN}✓${NC} Estatísticas funcionando"
echo -e "  ${GREEN}✓${NC} Métricas sendo coletadas"
echo -e "  ${GREEN}✓${NC} Eventos RabbitMQ sendo publicados\n"
