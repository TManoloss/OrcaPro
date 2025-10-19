#!/bin/bash

# Script para iniciar todos os serviços em modo produção
echo "🚀 Iniciando OrcaPro em modo produção..."

# Navegar para o diretório do projeto
cd "$(dirname "$0")"

# Parar containers existentes se houver
echo "📦 Parando containers existentes..."
sudo docker compose down 2>/dev/null || true

# Construir as imagens se necessário
echo "🔨 Construindo imagens Docker..."
sudo docker compose build --no-cache

# Iniciar todos os serviços em background
echo "🚀 Iniciando todos os serviços..."
sudo docker compose up -d

# Aguardar um pouco para os serviços inicializarem
echo "⏳ Aguardando serviços inicializarem..."
sleep 15

# Verificar status dos serviços
echo "📊 Status dos serviços:"
sudo docker compose ps

# Verificar health checks
echo "🏥 Verificando health checks..."
sudo docker compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"

echo ""
echo "✅ Serviços iniciados! Verifique os status acima."
echo ""
echo "📋 URLs disponíveis:"
echo "  - API Gateway: http://localhost:8000"
echo "  - Auth Service: http://localhost:8001"
echo "  - Transaction Service: http://localhost:8002"
echo "  - AI Service: http://localhost:8003"
echo "  - Notification Service: http://localhost:8004"
echo "  - Grafana: http://localhost:3000"
echo "  - Prometheus: http://localhost:9090"
echo "  - Jaeger: http://localhost:16686"
echo "  - RabbitMQ: http://localhost:15672"
echo ""

# Verificar logs de inicialização
echo "📝 Últimos logs de inicialização:"
sudo docker compose logs --tail=10
