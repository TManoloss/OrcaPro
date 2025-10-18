#!/bin/bash

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}   Iniciando OrcaPro com Docker${NC}"
echo -e "${BLUE}========================================${NC}\n"

echo -e "${YELLOW}Parando containers antigos...${NC}"
sudo docker-compose down

echo -e "\n${YELLOW}Construindo imagens...${NC}"
sudo docker-compose build

echo -e "\n${YELLOW}Iniciando todos os serviços...${NC}"
sudo docker-compose up -d

echo -e "\n${YELLOW}Aguardando serviços ficarem prontos...${NC}"
sleep 15

echo -e "\n${GREEN}✓ Serviços iniciados!${NC}\n"

echo -e "${CYAN}Status dos containers:${NC}"
sudo docker-compose ps

echo -e "\n${BLUE}========================================${NC}"
echo -e "${BLUE}   URLs dos Serviços${NC}"
echo -e "${BLUE}========================================${NC}\n"

echo -e "  ${GREEN}Auth Service:${NC}        http://localhost:8001"
echo -e "  ${GREEN}Transaction Service:${NC} http://localhost:8002"
echo -e "  ${GREEN}AI Service:${NC}          http://localhost:8003"
echo -e "  ${GREEN}PostgreSQL (Adminer):${NC} http://localhost:8080"
echo -e "  ${GREEN}Redis Commander:${NC}     http://localhost:8081"
echo -e "  ${GREEN}RabbitMQ Management:${NC} http://localhost:15672 (admin/admin123)"
echo -e "  ${GREEN}Prometheus:${NC}          http://localhost:9090"
echo -e "  ${GREEN}Grafana:${NC}             http://localhost:3000 (admin/admin123)"
echo -e "  ${GREEN}Jaeger UI:${NC}           http://localhost:16686\n"

echo -e "${YELLOW}Para ver logs em tempo real:${NC}"
echo -e "  ${CYAN}sudo docker-compose logs -f${NC}\n"
echo -e "${YELLOW}Para ver logs de um serviço específico:${NC}"
echo -e "  ${CYAN}sudo docker-compose logs -f auth-service${NC}"
echo -e "  ${CYAN}sudo docker-compose logs -f transaction-service${NC}"
echo -e "  ${CYAN}sudo docker-compose logs -f ai-service${NC}\n"

echo -e "${YELLOW}Para testar o sistema:${NC}"
echo -e "  ${CYAN}./scripts/test-with-ai.sh${NC}\n"

echo -e "${YELLOW}Para parar tudo:${NC}"
echo -e "  ${CYAN}sudo docker-compose down${NC}\n"

echo -e "${GREEN}Sistema pronto! 🚀${NC}\n"
