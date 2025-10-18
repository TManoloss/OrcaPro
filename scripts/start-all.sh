#!/bin/bash

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}   Iniciando OrcaPro - Todos Serviços${NC}"
echo -e "${BLUE}========================================${NC}\n"

# 1. Verificar se Docker está rodando
echo -e "${YELLOW}1. Verificando Docker...${NC}"
if ! sudo docker ps > /dev/null 2>&1; then
    echo -e "${RED}❌ Docker não está rodando!${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Docker OK${NC}\n"

# 2. Iniciar infraestrutura
echo -e "${YELLOW}2. Iniciando infraestrutura (PostgreSQL, Redis, RabbitMQ, Jaeger)...${NC}"
sudo docker-compose up -d postgres redis rabbitmq jaeger
echo -e "${GREEN}✓ Infraestrutura iniciada${NC}\n"

# 3. Aguardar serviços ficarem prontos
echo -e "${YELLOW}3. Aguardando serviços ficarem prontos...${NC}"
sleep 10
echo -e "${GREEN}✓ Serviços prontos${NC}\n"

# 4. Inicializar banco de dados (se necessário)
echo -e "${YELLOW}4. Verificando banco de dados...${NC}"
if sudo docker exec postgres psql -U admin -d app_database -c "SELECT 1 FROM users LIMIT 1" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Banco já inicializado${NC}\n"
else
    echo -e "${YELLOW}Inicializando banco de dados...${NC}"
    sudo docker exec -i postgres psql -U admin -d app_database < init-scripts/postgres/001_init.sql
    echo -e "${GREEN}✓ Banco inicializado${NC}\n"
fi

# 5. Compilar serviços Go
echo -e "${YELLOW}5. Compilando serviços...${NC}"
cd services/auth-service && go build -o auth-service . && cd ../..
echo -e "${GREEN}✓ Auth Service compilado${NC}"
cd services/trasaction-service && go build -o transaction-service . && cd ../..
echo -e "${GREEN}✓ Transaction Service compilado${NC}\n"

# 6. Criar arquivos .env
echo -e "${YELLOW}6. Configurando variáveis de ambiente...${NC}"
for service in auth-service trasaction-service ai-service; do
    if [ ! -f "services/$service/.env" ]; then
        cp "services/$service/.env.example" "services/$service/.env"
        echo -e "${GREEN}✓ .env criado para $service${NC}"
    fi
done
echo ""

# 7. Instruções para iniciar serviços
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}   Serviços Prontos para Iniciar${NC}"
echo -e "${BLUE}========================================${NC}\n"

echo -e "${YELLOW}Abra 3 terminais e execute:${NC}\n"

echo -e "${GREEN}Terminal 1 - Auth Service:${NC}"
echo -e "  cd $(dirname $(pwd))"
echo -e "  ./scripts/start-auth-service.sh\n"

echo -e "${GREEN}Terminal 2 - Transaction Service:${NC}"
echo -e "  cd $(dirname $(pwd))"
echo -e "  ./scripts/start-transaction-service.sh\n"

echo -e "${GREEN}Terminal 3 - AI Service:${NC}"
echo -e "  cd $(dirname $(pwd))"
echo -e "  ./scripts/start-ai-service.sh\n"

echo -e "${YELLOW}Ou use tmux/screen para rodar todos em background.${NC}\n"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}   URLs dos Serviços${NC}"
echo -e "${BLUE}========================================${NC}\n"

echo -e "  ${GREEN}Auth Service:${NC}        http://localhost:8001"
echo -e "  ${GREEN}Transaction Service:${NC} http://localhost:8002"
echo -e "  ${GREEN}AI Service:${NC}          http://localhost:8003"
echo -e "  ${GREEN}RabbitMQ Management:${NC} http://localhost:15672 (admin/admin123)"
echo -e "  ${GREEN}Jaeger UI:${NC}           http://localhost:16686\n"

echo -e "${YELLOW}Para testar o sistema:${NC}"
echo -e "  ./scripts/test-with-ai.sh\n"
