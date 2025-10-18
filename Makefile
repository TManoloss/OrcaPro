.PHONY: help up down restart logs ps clean health check-deps init

# Cores para output
GREEN  := \033[0;32m
YELLOW := \033[0;33m
RED    := \033[0;31m
NC     := \033[0m # No Color

help: ## Mostra este menu de ajuda
	@echo "$(GREEN)Comandos disponíveis:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(YELLOW)%-15s$(NC) %s\n", $$1, $$2}'

check-deps: ## Verifica dependências necessárias
	@echo "$(YELLOW)Verificando dependências...$(NC)"
	@command -v docker >/dev/null 2>&1 || { echo "$(RED)Docker não está instalado!$(NC)"; exit 1; }
	@command -v docker-compose >/dev/null 2>&1 || command -v docker compose >/dev/null 2>&1 || { echo "$(RED)Docker Compose não está instalado!$(NC)"; exit 1; }
	@echo "$(GREEN)✓ Todas as dependências estão instaladas$(NC)"

init: check-deps ## Inicializa a estrutura do projeto
	@echo "$(YELLOW)Criando estrutura de diretórios...$(NC)"
	@mkdir -p config/prometheus
	@mkdir -p config/grafana/provisioning/datasources
	@mkdir -p config/grafana/provisioning/dashboards
	@mkdir -p config/grafana/dashboards
	@mkdir -p config/loki
	@mkdir -p config/promtail
	@mkdir -p init-scripts/postgres
	@echo "$(GREEN)✓ Estrutura criada com sucesso$(NC)"

up: ## Inicia todos os serviços
	@echo "$(YELLOW)Iniciando serviços...$(NC)"
	docker-compose up -d
	@echo "$(GREEN)✓ Serviços iniciados$(NC)"
	@echo ""
	@$(MAKE) health

down: ## Para todos os serviços
	@echo "$(YELLOW)Parando serviços...$(NC)"
	docker-compose down
	@echo "$(GREEN)✓ Serviços parados$(NC)"

restart: down up ## Reinicia todos os serviços

logs: ## Mostra logs de todos os serviços
	docker-compose logs -f

logs-%: ## Mostra logs de um serviço específico (ex: make logs-postgres)
	docker-compose logs -f $*

ps: ## Lista status dos containers
	docker-compose ps

health: ## Verifica saúde dos serviços
	@echo "$(YELLOW)Verificando saúde dos serviços...$(NC)"
	@echo ""
	@docker-compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}" | grep -v "NAME"
	@echo ""
	@echo "$(GREEN)URLs de Acesso:$(NC)"
	@echo "  • Grafana:        http://localhost:3000 (admin/admin123)"
	@echo "  • Prometheus:     http://localhost:9090"
	@echo "  • Jaeger UI:      http://localhost:16686"
	@echo "  • RabbitMQ UI:    http://localhost:15672 (admin/admin123)"
	@echo "  • Adminer (DB):   http://localhost:8080"
	@echo "  • Redis UI:       http://localhost:8081"

clean: ## Remove todos os containers e volumes (CUIDADO: apaga dados!)
	@echo "$(RED)ATENÇÃO: Isso irá remover todos os dados!$(NC)"
	@read -p "Tem certeza? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		echo "$(YELLOW)Removendo containers e volumes...$(NC)"; \
		docker-compose down -v; \
		echo "$(GREEN)✓ Limpeza completa$(NC)"; \
	else \
		echo "$(YELLOW)Operação cancelada$(NC)"; \
	fi

clean-soft: ## Para os containers mas mantém os volumes
	@echo "$(YELLOW)Parando containers (mantendo dados)...$(NC)"
	docker-compose down
	@echo "$(GREEN)✓ Containers parados, dados preservados$(NC)"

backup: ## Cria backup dos volumes
	@echo "$(YELLOW)Criando backup...$(NC)"
	@mkdir -p backups
	@docker run --rm -v $(shell pwd):/backup -v postgres-data:/data alpine tar czf /backup/backups/postgres-backup-$(shell date +%Y%m%d-%H%M%S).tar.gz /data
	@echo "$(GREEN)✓ Backup criado em ./backups/$(NC)"

rebuild: ## Reconstrói as imagens dos serviços
	@echo "$(YELLOW)Reconstruindo imagens...$(NC)"
	docker-compose build --no-cache
	@echo "$(GREEN)✓ Imagens reconstruídas$(NC)"

prune: ## Remove recursos Docker não utilizados
	@echo "$(YELLOW)Removendo recursos não utilizados...$(NC)"
	docker system prune -f
	@echo "$(GREEN)✓ Limpeza concluída$(NC)"

shell-%: ## Abre shell em um container específico (ex: make shell-postgres)
	docker-compose exec $* sh

db-migrate: ## Executa migrações do banco de dados (implementar quando necessário)
	@echo "$(YELLOW)Executando migrações...$(NC)"
	@echo "$(RED)TODO: Implementar sistema de migrações$(NC)"

test: ## Executa testes (implementar quando necessário)
	@echo "$(YELLOW)Executando testes...$(NC)"
	@echo "$(RED)TODO: Implementar testes$(NC)"

dev: up logs ## Modo desenvolvimento: inicia e mostra logs

prod-check: ## Verifica configurações antes de deploy em produção
	@echo "$(YELLOW)Verificando configurações para produção...$(NC)"
	@echo "$(RED)⚠ ATENÇÃO: Trocar todas as senhas padrão!$(NC)"
	@echo "$(RED)⚠ ATENÇÃO: Configurar SSL/TLS para serviços expostos!$(NC)"
	@echo "$(RED)⚠ ATENÇÃO: Revisar limites de recursos!$(NC)"
	@echo "$(RED)⚠ ATENÇÃO: Configurar backups automáticos!$(NC)"