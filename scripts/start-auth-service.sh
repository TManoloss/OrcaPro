#!/bin/bash

cd services/auth-service

# Cria .env se não existir
if [ ! -f .env ]; then
    echo "Criando .env a partir do .env.example..."
    cp .env.example .env
fi

# Carrega variáveis do .env
export $(cat .env | grep -v '^#' | xargs)

echo "🚀 Iniciando Auth Service na porta $SERVER_PORT..."
./auth-service
