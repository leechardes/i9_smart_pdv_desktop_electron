#!/bin/bash

# Script de Limpeza
# Remove arquivos de build e temporários

set -e

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo -e "${BLUE}🗑️  Limpando arquivos temporários...${NC}"
echo ""

# Backend
echo -e "${BLUE}📦 Backend${NC}"
cd "$PROJECT_ROOT/backend"
if [ -d "dist" ]; then
    rm -rf dist
    echo -e "${YELLOW}  Removido: dist/${NC}"
fi
if [ -d "node_modules" ]; then
    rm -rf node_modules
    echo -e "${YELLOW}  Removido: node_modules/${NC}"
fi
echo -e "${GREEN}✅ Backend limpo${NC}"
echo ""

# Frontend
echo -e "${BLUE}📦 Frontend${NC}"
cd "$PROJECT_ROOT/frontend"
if [ -d ".next" ]; then
    rm -rf .next
    echo -e "${YELLOW}  Removido: .next/${NC}"
fi
if [ -d "node_modules" ]; then
    rm -rf node_modules
    echo -e "${YELLOW}  Removido: node_modules/${NC}"
fi
if [ -d "out" ]; then
    rm -rf out
    echo -e "${YELLOW}  Removido: out/${NC}"
fi
echo -e "${GREEN}✅ Frontend limpo${NC}"
echo ""

# PDV Desktop
echo -e "${BLUE}📦 PDV Desktop${NC}"
cd "$PROJECT_ROOT/pdv_desktop"
if [ -d "dist" ]; then
    rm -rf dist
    echo -e "${YELLOW}  Removido: dist/${NC}"
fi
if [ -d "node_modules" ]; then
    rm -rf node_modules
    echo -e "${YELLOW}  Removido: node_modules/${NC}"
fi
echo -e "${GREEN}✅ PDV Desktop limpo${NC}"
echo ""

# Raiz
echo -e "${BLUE}📦 Raiz do projeto${NC}"
cd "$PROJECT_ROOT"
if [ -d ".next" ]; then
    rm -rf .next
    echo -e "${YELLOW}  Removido: .next/${NC}"
fi
echo -e "${GREEN}✅ Raiz limpa${NC}"
echo ""

echo -e "${GREEN}✅ Limpeza completa!${NC}"
echo -e "${YELLOW}⚠️  Execute 'make install' para reinstalar as dependências${NC}"
