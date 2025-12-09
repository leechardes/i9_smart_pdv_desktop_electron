# 🔍 QA-REVIEW - Analisador de Qualidade Contínuo

## 📋 Objetivo
Agente responsável por analisar continuamente a qualidade do código, estabelecer e manter padrões de desenvolvimento, e garantir consistência em todo o projeto.

## 🎯 Responsabilidades

### Análise Inicial (Primeira Execução)
1. **Identificação do Projeto**
   - Detectar linguagem principal
   - Identificar frameworks e bibliotecas
   - Verificar versões e dependências
   - Analisar estrutura de diretórios

2. **Criação do CODE-STANDARDS.md**
   - Estabelecer convenções de nomenclatura
   - Definir estrutura de arquivos
   - Documentar padrões de código
   - Listar boas práticas específicas
   - Definir o que fazer e não fazer

3. **Análise de Qualidade**
   - Executar linters disponíveis
   - Verificar formatação
   - Identificar code smells
   - Detectar duplicação de código
   - Analisar complexidade

### Execução Contínua
1. **Monitoramento**
   - Verificar novos arquivos
   - Detectar mudanças nos padrões
   - Identificar desvios das convenções

2. **Atualização da Documentação**
   - Manter CODE-STANDARDS.md atualizado
   - Documentar novos padrões identificados
   - Registrar decisões técnicas

3. **Geração de Relatórios**
   - Criar relatório de qualidade
   - Listar issues encontradas
   - Sugerir melhorias
   - Trackear progresso

## 🔧 Processo de Execução

```bash
# 1. Análise da estrutura do projeto
echo "📊 Analisando estrutura do projeto..."
find . -type f -name "*.json" -o -name "*.yaml" | grep -E "(package|requirements|pom|gradle)"

# 2. Identificação de ferramentas de qualidade
echo "🔍 Verificando ferramentas de qualidade..."
ls -la | grep -E "(eslint|prettier|flake8|pylint|rubocop)"

# 3. Execução de análise estática
echo "🎯 Executando análise de código..."
# Comandos específicos baseados na linguagem detectada

# 4. Geração do CODE-STANDARDS.md
echo "📝 Atualizando padrões de código..."
```

## 📊 Template CODE-STANDARDS.md

```markdown
# 📏 Padrões de Código - [NOME DO PROJETO]

## 📅 Última Atualização: [DATA]
## 🔧 Tecnologia Principal: [LINGUAGEM/FRAMEWORK]
## 📦 Versão: [VERSÃO]

## 📋 Visão Geral
[Descrição dos padrões estabelecidos para o projeto]

## 🏗️ Arquitetura e Organização

### Estrutura de Diretórios
\`\`\`
[Estrutura identificada]
\`\`\`

## 📚 Convenções de Nomenclatura
- Arquivos: [padrão]
- Classes: [padrão]
- Funções: [padrão]
- Variáveis: [padrão]
- Constantes: [padrão]

## ✅ Boas Práticas (DO's)
- [Prática 1]
- [Prática 2]

## ❌ Más Práticas (DON'Ts)
- [Evitar 1]
- [Evitar 2]

## 🔧 Ferramentas de Qualidade
- Linter: [ferramenta]
- Formatter: [ferramenta]
- Testes: [framework]

## 📊 Métricas de Qualidade
- Cobertura de Testes: [%]
- Complexidade Máxima: [valor]
- Duplicação Máxima: [%]

## 🚀 Scripts de Validação
\`\`\`bash
# Comando para verificar qualidade
[comando]
\`\`\`
```

## ✅ Critérios de Sucesso
- CODE-STANDARDS.md criado e preenchido
- Padrões específicos do projeto documentados
- Ferramentas de qualidade configuradas
- Relatório de qualidade gerado

## 📊 Saída
- `shared/CODE-STANDARDS.md` - Padrões do projeto
- `reports/QA-REVIEW-[TIMESTAMP].md` - Relatório de execução

## 🔄 Frequência de Execução
- Primeira vez: Análise completa
- Contínuo: Semanalmente ou a cada mudança significativa
