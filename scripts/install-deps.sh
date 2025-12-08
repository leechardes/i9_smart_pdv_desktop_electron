#!/bin/bash

# Script de Instalação de Dependências
# Instala dependências de todos os subprojetos

set -e

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo -e "${BLUE}📦 Instalando dependências de todos os subprojetos...${NC}"
echo ""

# Backend
echo -e "${BLUE}🔧 Backend${NC}"
cd "$PROJECT_ROOT/backend"
npm install
echo -e "${GREEN}✅ Backend instalado${NC}"
echo ""

# Frontend
echo -e "${BLUE}🔧 Frontend${NC}"
cd "$PROJECT_ROOT/frontend"
npm install
echo -e "${GREEN}✅ Frontend instalado${NC}"
echo ""

# PDV Desktop
echo -e "${BLUE}🔧 PDV Desktop${NC}"
cd "$PROJECT_ROOT/pdv_desktop"
npm install
echo -e "${GREEN}✅ PDV Desktop instalado${NC}"
echo ""

echo -e "${GREEN}✅ Todas as dependências foram instaladas!${NC}"
