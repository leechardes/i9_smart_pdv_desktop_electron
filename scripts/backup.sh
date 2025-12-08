#!/bin/bash

# Script de Backup do Projeto I9 Smart PDV
# Cria backup compactado do projeto excluindo node_modules

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Data
DATA=$(date +%Y-%m-%d)
HORA=$(date +%H-%M-%S)

# Diretórios
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BACKUP_DIR="$HOME/Projetos/backup"
BACKUP_FILE="$BACKUP_DIR/i9_smart_pdv_web_${DATA}_${HORA}.tar.gz"

# Função de ajuda
show_help() {
    cat << EOF
📦 Script de Backup - I9 Smart PDV

Uso: $0 [opções]

Opções:
  --full         Backup completo (inclui node_modules e .git)
  --clean        Remove backups anteriores a 30 dias
  --list         Lista backups disponíveis
  --restore      Restaura backup (use: --restore arquivo.tar.gz)
  --help         Mostra esta mensagem

Exemplos:
  $0                              # Backup padrão
  $0 --full                       # Backup completo
  $0 --clean                      # Limpar backups antigos
  $0 --list                       # Listar backups
  $0 --restore i9_smart_pdv_web_2025-12-08_10-30-45.tar.gz

EOF
}

# Função de backup padrão (sem node_modules)
backup_default() {
    echo -e "${BLUE}📦 Iniciando backup padrão do projeto...${NC}"
    mkdir -p "$BACKUP_DIR"

    echo -e "${BLUE}📁 Destino: $BACKUP_FILE${NC}"
    echo ""

    cd "$(dirname "$PROJECT_ROOT")" && tar -czf "$BACKUP_FILE" \
        --exclude='i9_smart_pdv_web/node_modules' \
        --exclude='i9_smart_pdv_web/backend/node_modules' \
        --exclude='i9_smart_pdv_web/frontend/node_modules' \
        --exclude='i9_smart_pdv_web/pdv_desktop/node_modules' \
        --exclude='i9_smart_pdv_web/.next' \
        --exclude='i9_smart_pdv_web/backend/dist' \
        --exclude='i9_smart_pdv_web/pdv_desktop/dist' \
        --exclude='i9_smart_pdv_web/.git' \
        --exclude='i9_smart_pdv_web/backend/.git' \
        --exclude='i9_smart_pdv_web/frontend/.git' \
        --exclude='.DS_Store' \
        i9_smart_pdv_web

    SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
    echo -e "${GREEN}✅ Backup concluído!${NC}"
    echo -e "${GREEN}📦 Arquivo: $(basename $BACKUP_FILE)${NC}"
    echo -e "${GREEN}📊 Tamanho: $SIZE${NC}"
    echo -e "${GREEN}📅 Data: $DATA${NC}"
}

# Função de backup completo
backup_full() {
    echo -e "${BLUE}📦 Iniciando backup completo do projeto...${NC}"
    mkdir -p "$BACKUP_DIR"

    BACKUP_FILE="${BACKUP_DIR}/i9_smart_pdv_web_full_${DATA}_${HORA}.tar.gz"
    echo -e "${BLUE}📁 Destino: $BACKUP_FILE${NC}"
    echo ""

    cd "$(dirname "$PROJECT_ROOT")" && tar -czf "$BACKUP_FILE" \
        --exclude='.DS_Store' \
        i9_smart_pdv_web

    SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
    echo -e "${GREEN}✅ Backup completo concluído!${NC}"
    echo -e "${GREEN}📦 Arquivo: $(basename $BACKUP_FILE)${NC}"
    echo -e "${GREEN}📊 Tamanho: $SIZE${NC}"
    echo -e "${GREEN}📅 Data: $DATA${NC}"
}

# Função de limpeza de backups antigos
cleanup_old_backups() {
    echo -e "${BLUE}🗑️  Limpando backups anteriores a 30 dias...${NC}"

    if [ ! -d "$BACKUP_DIR" ]; then
        echo -e "${YELLOW}⚠️  Diretório de backup não existe${NC}"
        return
    fi

    REMOVED=0
    while IFS= read -r file; do
        rm -f "$file"
        REMOVED=$((REMOVED + 1))
        echo -e "${YELLOW}  Removido: $(basename $file)${NC}"
    done < <(find "$BACKUP_DIR" -name "i9_smart_pdv_web*.tar.gz" -mtime +30)

    if [ $REMOVED -eq 0 ]; then
        echo -e "${GREEN}✅ Nenhum backup antigo encontrado${NC}"
    else
        echo -e "${GREEN}✅ Removidos $REMOVED backups antigos${NC}"
    fi
}

# Função de listagem
list_backups() {
    echo -e "${BLUE}📋 Backups disponíveis:${NC}"
    echo ""

    if [ ! -d "$BACKUP_DIR" ]; then
        echo -e "${YELLOW}⚠️  Nenhum backup encontrado${NC}"
        return
    fi

    ls -lh "$BACKUP_DIR"/i9_smart_pdv_web*.tar.gz 2>/dev/null | awk '{print $9, "(" $5 ")"}'
}

# Função de restauração
restore_backup() {
    local RESTORE_FILE="$BACKUP_DIR/$1"

    if [ ! -f "$RESTORE_FILE" ]; then
        echo -e "${RED}❌ Arquivo não encontrado: $1${NC}"
        exit 1
    fi

    echo -e "${YELLOW}⚠️  Você está prestes a restaurar um backup!${NC}"
    echo -e "${YELLOW}Arquivo: $(basename $RESTORE_FILE)${NC}"
    read -p "Continuar? (s/n) " -n 1 -r
    echo

    if [[ ! $REPLY =~ ^[Ss]$ ]]; then
        echo -e "${RED}Operação cancelada${NC}"
        exit 1
    fi

    echo -e "${BLUE}🔄 Restaurando backup...${NC}"
    cd "$(dirname "$PROJECT_ROOT")" && tar -xzf "$RESTORE_FILE"

    echo -e "${GREEN}✅ Backup restaurado com sucesso!${NC}"
}

# Função principal
main() {
    case "${1:-}" in
        --full)
            backup_full
            ;;
        --clean)
            cleanup_old_backups
            ;;
        --list)
            list_backups
            ;;
        --restore)
            if [ -z "$2" ]; then
                echo -e "${RED}❌ Especifique o arquivo de backup${NC}"
                show_help
                exit 1
            fi
            restore_backup "$2"
            ;;
        --help|-h)
            show_help
            ;;
        *)
            backup_default
            ;;
    esac
}

main "$@"
