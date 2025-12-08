#!/bin/bash

# Script de Desenvolvimento
# Inicia os servidores de desenvolvimento

set -e

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo -e "${BLUE}🚀 Iniciando ambiente de desenvolvimento...${NC}"
echo ""
echo -e "${YELLOW}ℹ️  Certifique-se de que o PostgreSQL está rodando!${NC}"
echo ""

# Função para iniciar servidor
start_server() {
    local name=$1
    local path=$2
    local command=$3

    echo -e "${BLUE}🔧 Iniciando $name...${NC}"
    cd "$path"
    eval "$command" &
    sleep 2
}

# Backend
start_server "Backend (Express + Prisma)" \
    "$PROJECT_ROOT/backend" \
    "npm run dev"

# Frontend
start_server "Frontend (Next.js)" \
    "$PROJECT_ROOT/frontend" \
    "npm run dev"

echo ""
echo -e "${GREEN}✅ Servidores iniciados!${NC}"
echo ""
echo -e "${BLUE}📌 URLs disponíveis:${NC}"
echo -e "  Backend:  ${GREEN}http://localhost:4001${NC}"
echo -e "  Frontend: ${GREEN}http://localhost:4000${NC}"
echo ""
echo -e "${YELLOW}⚠️  Pressione Ctrl+C para parar todos os servidores${NC}"

# Aguardar termino
wait
