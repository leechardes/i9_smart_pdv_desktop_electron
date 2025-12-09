# 🤖 Sistema de Agentes de Documentação

## 📋 Visão Geral

Os agentes são scripts automatizados que mantêm a documentação e qualidade do código. Cada agente tem uma responsabilidade específica e pode ser executado independentemente.

## 📁 Estrutura

```
agents/
├── continuous/      # Agentes que rodam continuamente
├── executed/        # Agentes já executados (histórico)
├── pending/         # Agentes aguardando execução
├── reports/         # Relatórios gerados pelos agentes
└── shared/          # Recursos compartilhados entre agentes
    └── CODE-STANDARDS.md  # Padrões de código do projeto
```

## ⚠️ IMPORTANTE: Padrões de Código

### Referência Obrigatória
**TODOS os agentes devem usar como referência**: `docs/agents/shared/CODE-STANDARDS.md`
- Este arquivo contém os padrões específicos do projeto
- É atualizado automaticamente pelo agente QA-REVIEW
- Define convenções, boas práticas e estruturas

### Verificação de Permissões
Antes de criar ou executar agentes:
1. Verificar CLAUDE.md para regras de comandos
2. Confirmar .claude/settings.local.json tem permissões corretas
3. Evitar comandos que pedem autorização ($(), >, |, etc.)

## 🎯 Como Criar Novos Agentes

### Nomenclatura
- Formato: `AXX-NOME-DO-AGENTE.md`
- Sequência: A01, A02, A03... (ordem de prioridade)
- Nome: MAIÚSCULAS-SEPARADAS-POR-HÍFEN

### Estrutura Padrão (usar CODE-STANDARDS.md como base)
```markdown
# 🏷️ AXX - Nome do Agente

## 📋 Objetivo
[Descrição clara do que o agente faz]

## 🎯 Tarefas
- [ ] Tarefa 1
- [ ] Tarefa 2
- [ ] Tarefa 3

## 🔧 Comandos
\`\`\`bash
# Comandos a executar
\`\`\`

## ✅ Critérios de Sucesso
- Critério 1
- Critério 2

## 📊 Relatório
Gera: agents/reports/AXX-NOME-REPORT.md
```

## 🔄 Ciclo de Vida

1. **Criação**: Agente criado em `pending/`
2. **Execução**: Agente processado
3. **Relatório**: Resultado em `reports/`
4. **Arquivamento**: Movido para `executed/`

## 🚀 Agentes Contínuos

### QA-REVIEW
- Analisa qualidade do código
- Mantém CODE-STANDARDS.md atualizado
- Identifica melhorias

### TECHNICAL-WRITER
- Sincroniza código e documentação
- Identifica gaps
- Atualiza automaticamente
- Primeira execução: análise completa
- Execuções seguintes: apenas mudanças
- Respeita .gitignore

## 📝 Próximos Agentes Sugeridos

Após executar os agentes base, considere criar:
- A03-TEST-AUTOMATION - Automatização de testes
- A04-SECURITY-SCAN - Verificação de segurança
- A05-PERFORMANCE-MONITOR - Monitoramento de performance

## 🔧 Como Executar

1. Escolha o agente em `pending/`
2. Execute as tarefas descritas
3. Gere o relatório em `reports/`
4. Mova para `executed/` com timestamp

## 📊 Métricas

- Agentes pendentes: [X]
- Agentes executados: [Y]
- Última execução: [DATA]
