#!/bin/bash

# Cores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

BASE_URL="http://localhost:8001"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}   Testando Auth Service${NC}"
echo -e "${BLUE}========================================${NC}\n"

# 1. Health Check
echo -e "${YELLOW}1. Health Check${NC}"
HEALTH=$(curl -s ${BASE_URL}/health)
echo -e "Response: ${GREEN}${HEALTH}${NC}\n"

# 2. Registrar novo usuário
echo -e "${YELLOW}2. Registrando novo usuário${NC}"
REGISTER_RESPONSE=$(curl -s -X POST ${BASE_URL}/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "teste@example.com",
    "name": "Usuário Teste",
    "password": "senha12345"
  }')
echo -e "Response: ${GREEN}${REGISTER_RESPONSE}${NC}\n"

# 3. Login
echo -e "${YELLOW}3. Fazendo login${NC}"
LOGIN_RESPONSE=$(curl -s -X POST ${BASE_URL}/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "teste@example.com",
    "password": "senha12345"
  }')
echo -e "Response: ${GREEN}${LOGIN_RESPONSE}${NC}\n"

# Extrai o access_token
ACCESS_TOKEN=$(echo $LOGIN_RESPONSE | grep -o '"access_token":"[^"]*' | cut -d'"' -f4)
REFRESH_TOKEN=$(echo $LOGIN_RESPONSE | grep -o '"refresh_token":"[^"]*' | cut -d'"' -f4)

if [ -z "$ACCESS_TOKEN" ]; then
  echo -e "${RED}Erro: Não foi possível obter o access token${NC}"
  exit 1
fi

echo -e "${GREEN}Access Token obtido: ${ACCESS_TOKEN:0:50}...${NC}\n"

# 4. Acessar rota protegida /me
echo -e "${YELLOW}4. Acessando informações do usuário (rota protegida)${NC}"
ME_RESPONSE=$(curl -s -X GET ${BASE_URL}/api/v1/me \
  -H "Authorization: Bearer ${ACCESS_TOKEN}")
echo -e "Response: ${GREEN}${ME_RESPONSE}${NC}\n"

# 5. Refresh Token
echo -e "${YELLOW}5. Renovando access token${NC}"
REFRESH_RESPONSE=$(curl -s -X POST ${BASE_URL}/api/v1/auth/refresh \
  -H "Content-Type: application/json" \
  -d "{
    \"refresh_token\": \"${REFRESH_TOKEN}\"
  }")
echo -e "Response: ${GREEN}${REFRESH_RESPONSE}${NC}\n"

# 6. Logout
echo -e "${YELLOW}6. Fazendo logout${NC}"
LOGOUT_RESPONSE=$(curl -s -X POST ${BASE_URL}/api/v1/logout \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{
    \"refresh_token\": \"${REFRESH_TOKEN}\"
  }")
echo -e "Response: ${GREEN}${LOGOUT_RESPONSE}${NC}\n"

# 7. Tentar acessar com token após logout (deve falhar)
echo -e "${YELLOW}7. Tentando refresh após logout (deve falhar)${NC}"
AFTER_LOGOUT=$(curl -s -X POST ${BASE_URL}/api/v1/auth/refresh \
  -H "Content-Type: application/json" \
  -d "{
    \"refresh_token\": \"${REFRESH_TOKEN}\"
  }")
echo -e "Response: ${RED}${AFTER_LOGOUT}${NC}\n"

# 8. Métricas
echo -e "${YELLOW}8. Verificando métricas do Prometheus${NC}"
METRICS=$(curl -s ${BASE_URL}/metrics | grep -E "^(http_requests_total|auth_)" | head -10)
echo -e "${GREEN}${METRICS}${NC}\n"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}   Testes Concluídos!${NC}"
echo -e "${BLUE}========================================${NC}"
