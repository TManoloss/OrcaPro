#!/bin/bash

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}   Testando Categorização com IA${NC}"
echo -e "${BLUE}========================================${NC}\n"

# Get token
TOKEN=$(curl -s -X POST http://localhost:8001/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"teste-ia@example.com","password":"senha12345"}' \
  | grep -o '"access_token":"[^"]*' | cut -d'"' -f4)

echo -e "${GREEN}✓ Token obtido${NC}\n"

# Teste 1: Uber (Transporte)
echo -e "${YELLOW}1. Testando: Uber${NC}"
curl -s -X POST http://localhost:8002/api/v1/transactions \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"description":"Corrida de Uber","amount":30.00,"category":"Outros","type":"expense","date":"2025-10-18T10:00:00Z"}' > /dev/null
sleep 2
sudo docker logs ai-service --tail 2 | grep "categorizada"
echo ""

# Teste 2: Restaurante (Alimentação)
echo -e "${YELLOW}2. Testando: Restaurante${NC}"
curl -s -X POST http://localhost:8002/api/v1/transactions \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"description":"Jantar no restaurante","amount":80.00,"category":"Outros","type":"expense","date":"2025-10-18T19:00:00Z"}' > /dev/null
sleep 2
sudo docker logs ai-service --tail 2 | grep "categorizada"
echo ""

# Teste 3: Supermercado (Alimentação)
echo -e "${YELLOW}3. Testando: Supermercado${NC}"
curl -s -X POST http://localhost:8002/api/v1/transactions \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"description":"Compras no supermercado Extra","amount":200.00,"category":"Outros","type":"expense","date":"2025-10-18T15:00:00Z"}' > /dev/null
sleep 2
sudo docker logs ai-service --tail 2 | grep "categorizada"
echo ""

# Teste 4: Gasolina (Transporte)
echo -e "${YELLOW}4. Testando: Gasolina${NC}"
curl -s -X POST http://localhost:8002/api/v1/transactions \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"description":"Gasolina posto Shell","amount":150.00,"category":"Outros","type":"expense","date":"2025-10-18T08:00:00Z"}' > /dev/null
sleep 2
sudo docker logs ai-service --tail 2 | grep "categorizada"
echo ""

# Teste 5: Netflix (Lazer)
echo -e "${YELLOW}5. Testando: Netflix${NC}"
curl -s -X POST http://localhost:8002/api/v1/transactions \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"description":"Assinatura Netflix","amount":39.90,"category":"Outros","type":"expense","date":"2025-10-15T00:00:00Z"}' > /dev/null
sleep 2
sudo docker logs ai-service --tail 2 | grep "categorizada"
echo ""

# Teste 6: Farmácia (Saúde)
echo -e "${YELLOW}6. Testando: Farmácia${NC}"
curl -s -X POST http://localhost:8002/api/v1/transactions \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"description":"Remédios na farmácia","amount":85.00,"category":"Outros","type":"expense","date":"2025-10-17:00:00Z"}' > /dev/null
sleep 2
sudo docker logs ai-service --tail 2 | grep "categorizada"
echo ""

# Métricas
echo -e "${CYAN}=== MÉTRICAS DO AI SERVICE ===${NC}\n"
curl -s http://localhost:8003 | grep "transactions_categorized_total"

echo -e "\n${GREEN}Testes concluídos! 🎉${NC}\n"
