#!/bin/bash

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}Parando todos os serviços...${NC}"
sudo docker-compose down

echo -e "${GREEN}✓ Todos os serviços foram parados${NC}\n"

echo -e "${YELLOW}Para remover volumes (CUIDADO: apaga dados):${NC}"
echo -e "  sudo docker-compose down -v\n"
