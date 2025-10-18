#!/bin/bash

cd services/ai-service

# Cria .env se não existir
if [ ! -f .env ]; then
    echo "Criando .env a partir do .env.example..."
    cp .env.example .env
fi

# Carrega variáveis do .env
export $(cat .env | grep -v '^#' | xargs)

echo "🤖 Iniciando AI Service na porta $METRICS_PORT..."
python3 main.py
