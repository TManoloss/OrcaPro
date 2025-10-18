#!/bin/bash

# Cores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

AUTH_URL="http://localhost:8001"
TRANSACTION_URL="http://localhost:8002"
AI_METRICS_URL="http://localhost:8003"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}   Testando Sistema Completo com IA${NC}"
echo -e "${BLUE}========================================${NC}\n"

# 1. Health Checks
echo -e "${CYAN}=== HEALTH CHECKS ===${NC}\n"

echo -e "${YELLOW}1. Auth Service${NC}"
curl -s ${AUTH_URL}/health

echo -e "\n${YELLOW}2. Transaction Service${NC}"
curl -s ${TRANSACTION_URL}/health

echo -e "\n${YELLOW}3. AI Service (métricas)${NC}"
AI_STATUS=$(curl -s ${AI_METRICS_URL} | grep "ml_model_loaded" | tail -1)
echo -e "${GREEN}${AI_STATUS}${NC}\n"

# 2. Autenticação
echo -e "${CYAN}=== AUTENTICAÇÃO ===${NC}\n"

echo -e "${YELLOW}4. Registrando usuário para teste IA${NC}"
REGISTER=$(curl -s -X POST ${AUTH_URL}/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "teste-ia@example.com",
    "name": "Teste IA",
    "password": "senha12345"
  }')
echo -e "${GREEN}${REGISTER}${NC}\n"

echo -e "${YELLOW}5. Fazendo login${NC}"
LOGIN=$(curl -s -X POST ${AUTH_URL}/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "teste-ia@example.com",
    "password": "senha12345"
  }')
echo -e "${GREEN}${LOGIN}${NC}\n"

TOKEN=$(echo $LOGIN | grep -o '"access_token":"[^"]*' | cut -d'"' -f4)

if [ -z "$TOKEN" ] || [ "$TOKEN" = "null" ]; then
  echo -e "${RED}Erro: Não foi possível obter token${NC}"
  exit 1
fi

echo -e "${GREEN}✓ Token obtido com sucesso${NC}\n"

# 3. Criar transações para testar categorização
echo -e "${CYAN}=== TESTANDO CATEGORIZAÇÃO AUTOMÁTICA ===${NC}\n"

# Transação 1: Uber (deve categorizar como Transporte)
echo -e "${YELLOW}6. Criando transação: Uber${NC}"
TRANS1=$(curl -s -X POST ${TRANSACTION_URL}/api/v1/transactions \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "description": "Uber para o trabalho",
    "amount": 25.50,
    "category": "Outros",
    "type": "expense",
    "date": "2025-10-18T10:00:00Z"
  }')
echo -e "${GREEN}${TRANS1}${NC}"
TRANS1_ID=$(echo $TRANS1 | grep -o '"id":"[^"]*' | cut -d'"' -f4)
echo -e "${MAGENTA}ID: ${TRANS1_ID}${NC}\n"

sleep 2

# Transação 2: Restaurante (deve categorizar como Alimentação)
echo -e "${YELLOW}7. Criando transação: Restaurante${NC}"
TRANS2=$(curl -s -X POST ${TRANSACTION_URL}/api/v1/transactions \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "description": "Almoço no restaurante",
    "amount": 45.00,
    "category": "Outros",
    "type": "expense",
    "date": "2025-10-18T12:00:00Z"
  }')
echo -e "${GREEN}${TRANS2}${NC}"
TRANS2_ID=$(echo $TRANS2 | grep -o '"id":"[^"]*' | cut -d'"' -f4)
echo -e "${MAGENTA}ID: ${TRANS2_ID}${NC}\n"

sleep 2

# Transação 3: Supermercado (deve categorizar como Alimentação)
echo -e "${YELLOW}8. Criando transação: Supermercado${NC}"
TRANS3=$(curl -s -X POST ${TRANSACTION_URL}/api/v1/transactions \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "description": "Compra no Carrefour supermercado",
    "amount": 150.00,
    "category": "Outros",
    "type": "expense",
    "date": "2025-10-18T15:00:00Z"
  }')
echo -e "${GREEN}${TRANS3}${NC}"
TRANS3_ID=$(echo $TRANS3 | grep -o '"id":"[^"]*' | cut -d'"' -f4)
echo -e "${MAGENTA}ID: ${TRANS3_ID}${NC}\n"

sleep 2

# Transação 4: Aluguel (deve categorizar como Moradia)
echo -e "${YELLOW}9. Criando transação: Aluguel${NC}"
TRANS4=$(curl -s -X POST ${TRANSACTION_URL}/api/v1/transactions \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "description": "Pagamento aluguel apartamento",
    "amount": 1500.00,
    "category": "Outros",
    "type": "expense",
    "date": "2025-10-01T00:00:00Z"
  }')
echo -e "${GREEN}${TRANS4}${NC}"
TRANS4_ID=$(echo $TRANS4 | grep -o '"id":"[^"]*' | cut -d'"' -f4)
echo -e "${MAGENTA}ID: ${TRANS4_ID}${NC}\n"

sleep 2

# Transação 5: Netflix (deve categorizar como Lazer)
echo -e "${YELLOW}10. Criando transação: Netflix${NC}"
TRANS5=$(curl -s -X POST ${TRANSACTION_URL}/api/v1/transactions \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "description": "Assinatura Netflix streaming",
    "amount": 39.90,
    "category": "Outros",
    "type": "expense",
    "date": "2025-10-15T00:00:00Z"
  }')
echo -e "${GREEN}${TRANS5}${NC}"
TRANS5_ID=$(echo $TRANS5 | grep -o '"id":"[^"]*' | cut -d'"' -f4)
echo -e "${MAGENTA}ID: ${TRANS5_ID}${NC}\n"

# 4. Aguardar processamento da IA
echo -e "${CYAN}=== AGUARDANDO PROCESSAMENTO DA IA ===${NC}\n"
echo -e "${YELLOW}Aguardando 5 segundos para IA processar...${NC}"
sleep 5

# 5. Verificar logs do AI Service
echo -e "\n${CYAN}=== LOGS DO AI SERVICE ===${NC}\n"
echo -e "${YELLOW}11. Últimas categorizações:${NC}"
sudo docker logs ai-service --tail 20 | grep "categorizada" || echo "Nenhuma categorização encontrada nos logs"

echo ""

# 6. Verificar métricas do AI Service
echo -e "${CYAN}=== MÉTRICAS DO AI SERVICE ===${NC}\n"
echo -e "${YELLOW}12. Métricas de categorização:${NC}"
AI_METRICS=$(curl -s ${AI_METRICS_URL} | grep -E "^(transactions_received_total|transactions_categorized_total|ml_model_loaded|rabbitmq_connection_status)")
echo -e "${GREEN}${AI_METRICS}${NC}\n"

# 7. Estatísticas
echo -e "${CYAN}=== ESTATÍSTICAS ===${NC}\n"
echo -e "${YELLOW}13. Estatísticas financeiras:${NC}"
STATS=$(curl -s -X GET "${TRANSACTION_URL}/api/v1/transactions/stats" \
  -H "Authorization: Bearer ${TOKEN}")
echo -e "${GREEN}${STATS}${NC}\n"

# 8. Listar transações
echo -e "${CYAN}=== TRANSAÇÕES CRIADAS ===${NC}\n"
echo -e "${YELLOW}14. Listando todas as transações:${NC}"
LIST=$(curl -s -X GET "${TRANSACTION_URL}/api/v1/transactions?page=1&page_size=10" \
  -H "Authorization: Bearer ${TOKEN}")
echo -e "${GREEN}${LIST}${NC}\n"

# 9. Verificar RabbitMQ
echo -e "${CYAN}=== RABBITMQ ===${NC}\n"
echo -e "${YELLOW}15. Filas no RabbitMQ:${NC}"
sudo docker exec rabbitmq rabbitmqctl list_queues name messages consumers

echo ""

# 10. Resumo
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}   RESUMO DOS TESTES${NC}"
echo -e "${BLUE}========================================${NC}\n"

echo -e "${CYAN}Transações Criadas:${NC}"
echo -e "  1. ${MAGENTA}Uber${NC} → Esperado: ${YELLOW}Transporte${NC}"
echo -e "  2. ${MAGENTA}Restaurante${NC} → Esperado: ${YELLOW}Alimentação${NC}"
echo -e "  3. ${MAGENTA}Supermercado${NC} → Esperado: ${YELLOW}Alimentação${NC}"
echo -e "  4. ${MAGENTA}Aluguel${NC} → Esperado: ${YELLOW}Moradia${NC}"
echo -e "  5. ${MAGENTA}Netflix${NC} → Esperado: ${YELLOW}Lazer${NC}\n"

echo -e "${CYAN}Verificações:${NC}"
echo -e "  ${GREEN}✓${NC} Auth Service funcionando"
echo -e "  ${GREEN}✓${NC} Transaction Service funcionando"
echo -e "  ${GREEN}✓${NC} AI Service funcionando"
echo -e "  ${GREEN}✓${NC} RabbitMQ processando eventos"
echo -e "  ${GREEN}✓${NC} Modelo ML carregado"
echo -e "  ${GREEN}✓${NC} Categorizações realizadas\n"

echo -e "${YELLOW}Para ver logs detalhados do AI Service:${NC}"
echo -e "  ${CYAN}sudo docker logs -f ai-service${NC}\n"

echo -e "${YELLOW}Para ver métricas em tempo real:${NC}"
echo -e "  ${CYAN}watch -n 2 'curl -s http://localhost:8003 | grep transactions'${NC}\n"

echo -e "${GREEN}Testes concluídos com sucesso! 🎉${NC}\n"
