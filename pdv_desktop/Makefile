# PDV Desktop - Makefile
# ========================

.PHONY: help install dev build build-debug build-windows build-linux build-macos build-macos-arm icons clean setup check

# Cores para output
GREEN  := \033[0;32m
YELLOW := \033[0;33m
BLUE   := \033[0;34m
RED    := \033[0;31m
NC     := \033[0m # No Color

# Variáveis
TAURI_DIR := src-tauri
DIST_DIR := dist
CONFIG_FILE := config.json

help: ## Mostra esta ajuda
	@echo ""
	@echo "$(BLUE)╔══════════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(BLUE)║           PDV Desktop - Comandos Disponíveis                 ║$(NC)"
	@echo "$(BLUE)╚══════════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""

check: ## Verifica dependências do sistema
	@echo "$(BLUE)🔍 Verificando dependências...$(NC)"
	@echo ""
	@echo "Node.js:"
	@node --version 2>/dev/null || echo "  $(RED)❌ Node.js não encontrado$(NC)"
	@echo ""
	@echo "npm:"
	@npm --version 2>/dev/null || echo "  $(RED)❌ npm não encontrado$(NC)"
	@echo ""
	@echo "Rust:"
	@rustc --version 2>/dev/null || echo "  $(RED)❌ Rust não encontrado. Instale: https://rustup.rs$(NC)"
	@echo ""
	@echo "Cargo:"
	@cargo --version 2>/dev/null || echo "  $(RED)❌ Cargo não encontrado$(NC)"
	@echo ""
	@echo "Tauri CLI:"
	@npx tauri --version 2>/dev/null || echo "  $(YELLOW)⚠️  Tauri CLI será instalado com 'make install'$(NC)"
	@echo ""

install: ## Instala dependências do projeto
	@echo "$(BLUE)📦 Instalando dependências...$(NC)"
	npm install
	@echo ""
	@echo "$(GREEN)✅ Dependências instaladas!$(NC)"
	@echo ""
	@echo "$(YELLOW)📌 Próximos passos:$(NC)"
	@echo "   1. Edite $(CONFIG_FILE) com a URL do seu sistema"
	@echo "   2. Execute: make sync-config"
	@echo "   3. Execute: make dev"

setup: install sync-config ## Setup completo (install + sync-config)
	@echo "$(GREEN)✅ Setup completo!$(NC)"

sync-config: ## Sincroniza config.json para dist/ e src-tauri/
	@echo "$(BLUE)🔄 Sincronizando configuração...$(NC)"
	@cp $(CONFIG_FILE) $(DIST_DIR)/$(CONFIG_FILE)
	@cp $(CONFIG_FILE) $(TAURI_DIR)/$(CONFIG_FILE)
	@echo "$(GREEN)✅ config.json copiado para dist/ e src-tauri/$(NC)"
	@echo ""
	@echo "$(YELLOW)URL configurada:$(NC)"
	@cat $(CONFIG_FILE) | grep url

dev: sync-config ## Inicia em modo desenvolvimento
	@echo "$(BLUE)🚀 Iniciando PDV Desktop em modo desenvolvimento...$(NC)"
	npm run dev

build: sync-config ## Build para o sistema atual
	@echo "$(BLUE)🏗️  Gerando build de produção...$(NC)"
	npm run build
	@echo ""
	@echo "$(GREEN)✅ Build concluído!$(NC)"
	@echo "$(YELLOW)📁 Instaladores em: $(TAURI_DIR)/target/release/bundle/$(NC)"

build-debug: sync-config ## Build com debug symbols
	@echo "$(BLUE)🏗️  Gerando build de debug...$(NC)"
	npm run build:debug

build-windows: sync-config ## Build para Windows (.exe + .msi)
	@echo "$(BLUE)🏗️  Gerando build para Windows...$(NC)"
	npm run build:windows

build-linux: sync-config ## Build para Linux (.AppImage + .deb)
	@echo "$(BLUE)🏗️  Gerando build para Linux...$(NC)"
	npm run build:linux

build-macos: sync-config ## Build para macOS Intel (.dmg)
	@echo "$(BLUE)🏗️  Gerando build para macOS Intel...$(NC)"
	npm run build:macos

build-macos-arm: sync-config ## Build para macOS ARM M1/M2 (.dmg)
	@echo "$(BLUE)🏗️  Gerando build para macOS ARM...$(NC)"
	npm run build:macos-arm

build-all: sync-config ## Build para todas as plataformas
	@echo "$(BLUE)🏗️  Gerando builds para todas as plataformas...$(NC)"
	@echo "$(YELLOW)⚠️  Nota: Cross-compilation requer configuração adicional$(NC)"
	npm run build

icons: ## Gera ícones a partir de icons/app-icon.png
	@echo "$(BLUE)🎨 Gerando ícones...$(NC)"
	@if [ -f "icons/app-icon.png" ]; then \
		npm run icons; \
		echo "$(GREEN)✅ Ícones gerados em $(TAURI_DIR)/icons/$(NC)"; \
	else \
		echo "$(RED)❌ Arquivo icons/app-icon.png não encontrado$(NC)"; \
		echo "$(YELLOW)   Crie um PNG 1024x1024 em icons/app-icon.png$(NC)"; \
	fi

clean: ## Limpa builds e cache
	@echo "$(BLUE)🧹 Limpando builds e cache...$(NC)"
	rm -rf $(TAURI_DIR)/target
	rm -rf node_modules
	@echo "$(GREEN)✅ Limpeza concluída!$(NC)"

clean-build: ## Limpa apenas builds (mantém node_modules)
	@echo "$(BLUE)🧹 Limpando builds...$(NC)"
	rm -rf $(TAURI_DIR)/target
	@echo "$(GREEN)✅ Builds removidos!$(NC)"

info: ## Mostra informações do projeto
	@echo ""
	@echo "$(BLUE)╔══════════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(BLUE)║                  PDV Desktop - I9 Smart                      ║$(NC)"
	@echo "$(BLUE)╚══════════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(GREEN)Versão:$(NC) 1.0.0"
	@echo ""
	@echo "$(GREEN)Configuração atual:$(NC)"
	@cat $(CONFIG_FILE) 2>/dev/null || echo "  $(RED)Arquivo config.json não encontrado$(NC)"
	@echo ""
	@echo "$(GREEN)Estrutura:$(NC)"
	@echo "  📁 dist/          - Frontend (HTML/JS)"
	@echo "  📁 src-tauri/     - Código Rust/Tauri"
	@echo "  📁 icons/         - Ícone fonte"
	@echo "  📄 config.json    - URL do sistema"
	@echo ""

kiosk-on: ## Ativa modo kiosk (tela cheia + sem decorações)
	@echo "$(BLUE)🔒 Ativando modo kiosk...$(NC)"
	@sed -i.bak 's/"fullscreen": false/"fullscreen": true/g' $(TAURI_DIR)/tauri.conf.json
	@sed -i.bak 's/"resizable": true/"resizable": false/g' $(TAURI_DIR)/tauri.conf.json
	@rm -f $(TAURI_DIR)/tauri.conf.json.bak
	@echo "$(GREEN)✅ Modo kiosk ATIVADO (fullscreen + não redimensionável)$(NC)"
	@echo "$(YELLOW)   Rebuild necessário: make build$(NC)"

kiosk-off: ## Desativa modo kiosk
	@echo "$(BLUE)🔓 Desativando modo kiosk...$(NC)"
	@sed -i.bak 's/"fullscreen": true/"fullscreen": false/g' $(TAURI_DIR)/tauri.conf.json
	@sed -i.bak 's/"resizable": false/"resizable": true/g' $(TAURI_DIR)/tauri.conf.json
	@rm -f $(TAURI_DIR)/tauri.conf.json.bak
	@echo "$(GREEN)✅ Modo kiosk DESATIVADO$(NC)"
	@echo "$(YELLOW)   Rebuild necessário: make build$(NC)"

set-url: ## Define a URL do PDV (uso: make set-url URL=https://exemplo.com)
	@if [ -z "$(URL)" ]; then \
		echo "$(RED)❌ URL não especificada$(NC)"; \
		echo "$(YELLOW)   Uso: make set-url URL=https://seu-dominio.com$(NC)"; \
	else \
		echo '{"url": "$(URL)"}' > $(CONFIG_FILE); \
		cp $(CONFIG_FILE) $(DIST_DIR)/$(CONFIG_FILE); \
		cp $(CONFIG_FILE) $(TAURI_DIR)/$(CONFIG_FILE); \
		echo "$(GREEN)✅ URL definida: $(URL)$(NC)"; \
	fi

run: ## Executa o app compilado
	@echo "$(BLUE)🚀 Abrindo PDV Desktop...$(NC)"
	@open "$(TAURI_DIR)/target/release/bundle/macos/PDV Desktop.app"
