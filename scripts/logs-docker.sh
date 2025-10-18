#!/bin/bash

CYAN='\033[0;36m'
NC='\033[0m'

if [ -z "$1" ]; then
    echo -e "${CYAN}Mostrando logs de todos os serviços...${NC}\n"
    sudo docker-compose logs -f
else
    echo -e "${CYAN}Mostrando logs de $1...${NC}\n"
    sudo docker-compose logs -f $1
fi
