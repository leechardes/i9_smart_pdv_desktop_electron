.PHONY: help install dev build clean backup backup-full backup-list backup-clean restore

SCRIPTS_DIR := scripts

help:
	@echo "📋 I9 Smart PDV - Comandos Disponíveis"
	@echo ""
	@echo "🔧 Desenvolvimento:"
	@echo "  make install          - Instala dependências de todos os subprojetos"
	@echo "  make dev              - Inicia servidores de desenvolvimento (backend + frontend)"
	@echo "  make build            - Compila todos os subprojetos"
	@echo "  make clean            - Remove arquivos de build e temp"
	@echo ""
	@echo "📦 Backup e Restauração:"
	@echo "  make backup           - Cria backup compactado (recomendado)"
	@echo "  make backup-full      - Cria backup completo (com node_modules)"
	@echo "  make backup-list      - Lista backups disponíveis"
	@echo "  make backup-clean     - Remove backups anteriores a 30 dias"
	@echo "  make restore FILE=... - Restaura backup (ex: make restore FILE=arquivo.tar.gz)"
	@echo ""

# Instalar dependências
install:
	@bash $(SCRIPTS_DIR)/install-deps.sh

# Desenvolvimento
dev:
	@bash $(SCRIPTS_DIR)/start-dev.sh

# Build
build:
	@echo "🔨 Compilando projeto..."
	@cd backend && npm run build && cd ..
	@cd frontend && npm run build && cd ..
	@echo "✅ Build concluído!"

# Limpeza
clean:
	@bash $(SCRIPTS_DIR)/clean.sh

# Backup padrão
backup:
	@bash $(SCRIPTS_DIR)/backup.sh

# Backup completo
backup-full:
	@bash $(SCRIPTS_DIR)/backup.sh --full

# Listar backups
backup-list:
	@bash $(SCRIPTS_DIR)/backup.sh --list

# Limpar backups antigos
backup-clean:
	@bash $(SCRIPTS_DIR)/backup.sh --clean

# Restaurar backup
restore:
	@bash $(SCRIPTS_DIR)/backup.sh --restore $(FILE)
