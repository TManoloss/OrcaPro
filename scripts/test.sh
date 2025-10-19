#!/bin/bash
# save as: check-structure.sh

echo "📁 ANALISANDO ESTRUTURA DO PROJETO"

echo ""
echo "1. ESTRUTURA ATUAL:"
find . -name "*notification*" -type f 2>/dev/null | head -20
echo ""

echo "2. DOCKER-COMPOSE DO NOTIFICATION-SERVICE:"
docker-compose config services notification-service

echo ""
echo "3. ARQUIVOS NO DIRETÓRIO ATUAL:"
ls -la

echo ""
echo "4. VERIFICANDO SE O CÓDIGO EXISTE:"
if [ -f "notification-service.js" ]; then
    echo "✅ notification-service.js encontrado na raiz"
    head -5 notification-service.js
else
    echo "❌ notification-service.js não encontrado na raiz"
fi

echo ""
echo "5. VERIFICANDO DOCKERFILE:"
if [ -f "Dockerfile" ]; then
    echo "📄 Dockerfile na raiz:"
    head -20 Dockerfile
fi