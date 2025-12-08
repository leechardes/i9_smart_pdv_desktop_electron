# 📜 Scripts - I9 Smart PDV

Pasta contendo scripts de automação para o projeto I9 Smart PDV.

## 📋 Scripts Disponíveis

### 1. `backup.sh` - Backup e Restauração
Script completo para criar backups do projeto e restaurá-los quando necessário.

**Uso:**
```bash
# Backup padrão (sem node_modules)
./scripts/backup.sh

# Backup completo (com tudo)
./scripts/backup.sh --full

# Listar backups
./scripts/backup.sh --list

# Limpar backups antigos (30+ dias)
./scripts/backup.sh --clean

# Restaurar backup
./scripts/backup.sh --restore i9_smart_pdv_web_2025-12-08_10-30-45.tar.gz

# Ajuda
./scripts/backup.sh --help
```

**Via Makefile:**
```bash
make backup                # Backup padrão
make backup-full          # Backup completo
make backup-list          # Listar backups
make backup-clean         # Limpar antigos
make restore FILE=arquivo.tar.gz  # Restaurar
```

### 2. `install-deps.sh` - Instalação de Dependências
Instala automaticamente todas as dependências dos subprojetos.

**Uso:**
```bash
./scripts/install-deps.sh
```

**Via Makefile:**
```bash
make install
```

Instala:
- Backend (Express + Prisma)
- Frontend (Next.js)
- PDV Desktop (Tauri)

### 3. `start-dev.sh` - Servidor de Desenvolvimento
Inicia todos os servidores de desenvolvimento simultaneamente.

**Uso:**
```bash
./scripts/start-dev.sh
```

**Via Makefile:**
```bash
make dev
```

Inicia:
- Backend: `http://localhost:4001`
- Frontend: `http://localhost:4000`

### 4. `clean.sh` - Limpeza de Arquivos
Remove arquivos temporários, builds e dependências.

**Uso:**
```bash
./scripts/clean.sh
```

**Via Makefile:**
```bash
make clean
```

Remove:
- Diretórios `dist/`
- Diretórios `.next/`
- Diretórios `node_modules/`
- Arquivos temporários

## 📌 Usando via Makefile (Recomendado)

O Makefile fornece uma interface amigável para os scripts:

```bash
# Ajuda
make help

# Instalação de dependências
make install

# Desenvolvimento
make dev

# Build
make build

# Limpeza
make clean

# Backups
make backup                    # Padrão
make backup-full             # Completo
make backup-list             # Listar
make backup-clean            # Remover antigos
make restore FILE=nome.tar.gz # Restaurar
```

## 🔐 Permissões

Os scripts têm permissão de execução (`755`). Para resetar:

```bash
chmod +x scripts/*.sh
```

## 💾 Localização dos Backups

Todos os backups são salvos em:
```
~/Projetos/backup/
```

**Exemplo de arquivo:**
```
i9_smart_pdv_web_2025-12-08_10-30-45.tar.gz
i9_smart_pdv_web_full_2025-12-08_10-31-20.tar.gz
```

## 📊 Tamanho dos Backups

- **Backup padrão:** ~600-700 MB (sem `node_modules`)
- **Backup completo:** ~2-3 GB (com tudo)

## ⚠️ Notas Importantes

1. **PostgreSQL**: Certifique-se de que o PostgreSQL está rodando antes de iniciar desenvolvimento
2. **Node.js**: Requer Node.js 18+ e npm 9+
3. **Espaço em disco**: Verificar espaço disponível antes de backups completos
4. **Restauração**: A restauração sobrescreve arquivos, use com cuidado

## 🐛 Troubleshooting

### Script de backup falha
```bash
# Verificar espaço em disco
df -h ~/Projetos/backup/

# Criar diretório manualmente se necessário
mkdir -p ~/Projetos/backup/
```

### Permissões negadas ao executar scripts
```bash
# Dar permissão de execução
chmod +x scripts/*.sh
```

### Dependências não instalam
```bash
# Limpar cache do npm
npm cache clean --force

# Tentar novamente
make clean && make install
```

## 📝 Exemplos Práticos

### Workflow Típico de Desenvolvimento

```bash
# 1. Clonar e instalar
make install

# 2. Iniciar desenvolvimento
make dev

# 3. Fazer mudanças e commits...

# 4. Antes de começar algo novo, fazer backup
make backup

# 5. Se algo der errado, restaurar
make restore FILE=i9_smart_pdv_web_2025-12-08_10-30-45.tar.gz
```

### Limpeza Periódica

```bash
# Remover backups antigos de 30 dias
make backup-clean

# Limpar arquivos temporários e builds
make clean

# Reinstalar dependências
make install
```

## 🤝 Contribuindo

Se adicionar novos scripts:
1. Use `#!/bin/bash` como shebang
2. Adicione cores para melhor visualização (`GREEN`, `BLUE`, `RED`, `YELLOW`)
3. Inclua `set -e` para falhar no primeiro erro
4. Atualize este README
5. Dê permissão de execução: `chmod +x scripts/novo-script.sh`
6. Atualize o Makefile

## 📞 Suporte

Para problemas ou sugestões de novos scripts, abra uma issue no repositório.
