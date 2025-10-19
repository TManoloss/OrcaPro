#!/bin/bash
# save as: test-notification-flow.sh

echo "🔍 TESTANDO FLUXO COMPLETO DE NOTIFICAÇÃO"

# Configurações
RABBITMQ_MGMT_URL="http://localhost:15672"
RABBITMQ_USER="admin"
RABBITMQ_PASS="admin123"
SERVICE_URL="http://localhost:8004"

# Função para enviar mensagem de transação
send_transaction_message() {
    local routing_key=$1
    local amount=$2
    local description=$3
    local category=$4

    local test_message=$(cat <<EOF
{
    "properties": {
        "headers": {
            "trace_id": "test-flow-$(date +%s)"
        }
    },
    "routing_key": "$routing_key",
    "payload": "{\"transaction_id\": \"test-$(date +%s)\", \"amount\": $amount, \"description\": \"$description\", \"category\": \"$category\", \"date\": \"$(date -Iseconds)\", \"user_email\": \"test@example.com\", \"user_id\": \"test-user-123\"}",
    "payload_encoding": "string"
}
EOF
)

    echo "Enviando mensagem para routing_key: $routing_key"
    curl -s -u "$RABBITMQ_USER:$RABBITMQ_PASS" \
        -H "Content-Type: application/json" \
        -d "$test_message" \
        "$RABBITMQ_MGMT_URL/api/exchanges/%2F/transactions_exchange/publish"
    echo ""
}

# Verificar saúde do serviço
echo "1. Verificando saúde do serviço de notificação..."
curl -s -f "$SERVICE_URL/health" && echo " ✅ Saúde OK" || echo " ❌ Saúde falhou"

# Enviar mensagens de teste
echo ""
echo "2. Enviando mensagens de teste para o RabbitMQ..."

# Transação normal (baixo valor)
send_transaction_message "transaction.created" 100.50 "Compra normal" "Alimentação"

# Transação de alto valor (deve triggerar notificação)
send_transaction_message "transaction.created" 1500.75 "Compra de alto valor" "Eletrônicos"

# Budget excedido
send_transaction_message "budget.exceeded" 850.00 "Orçamento excedido" "Alimentação"

# Meta atingida
send_transaction_message "goal.achieved" 5000.00 "Meta de economia" "Economias"

echo ""
echo "3. Verificando métricas do serviço de notificação..."
echo "Métricas disponíveis:"
curl -s "$SERVICE_URL/metrics" | grep -E "notifications_(received_total|sent_total|errors_total)"

echo ""
echo "4. Verificando logs do serviço de notificação..."
docker-compose logs --tail=10 notification-service

echo ""
echo "🎉 Teste de fluxo concluído!"