#!/bin/bash

cd services/trasaction-service

# Cria .env se não existir
if [ ! -f .env ]; then
    echo "Criando .env a partir do .env.example..."
    cp .env.example .env
fi

# Carrega variáveis do .env
export $(cat .env | grep -v '^#' | xargs)

echo "🚀 Iniciando Transaction Service na porta $SERVER_PORT..."
./transaction-service
