# CLAUDE.md

## ⚠️ Importante: Comandos de Substituição

### Evitar Comandos que Pedem Autorização
- **NÃO USAR**: `$(date)`, `$(comando)` ou outras substituições
- **NÃO USAR**: redirecionamento (>, >>)
- **NÃO USAR**: pipe (|)
- **NÃO USAR**: variáveis com $VARIAVEL
- Esses comandos ativam pedido de permissão e interrompem o fluxo

### Como Obter Data/Hora Corretamente
```bash
# ❌ ERRADO (pede autorização):
echo "[$(date '+%H:%M:%S')] Log message"

# ✅ CORRETO (sem autorização):
date '+%H:%M:%S'
# Resultado: 19:01:12
echo "[19:01:12] Log message"  # Usar o valor manualmente
```

## 🛠️ Ferramentas com Permissão Total
Todas as ferramentas abaixo estão pré-autorizadas:
- Read(**), Write(**), Edit(**), MultiEdit(**)
- Glob(**), Grep(**), LS(**)
- NotebookEdit(**), TodoWrite(**), Task(**)
- WebFetch(**), WebSearch(**)
- BashOutput(**), KillBash(**), ExitPlanMode(**)
- Bash(echo*), Bash(*)
