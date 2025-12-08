# I9 Smart PDV Web - Modulo Tributario

Documentacao do Configurador Tributario inspirado no TOTVS Protheus.
Sistema completo para gestao fiscal de postos de combustiveis.

**Versao:** 2.0
**Data:** 07/12/2025
**Status:** Implementacao Completa

---

## 1. Visao Geral

O modulo tributario foi projetado para:
- Automatizar calculos fiscais conforme legislacao brasileira
- Suportar tributacao monofasica de combustiveis (NT 2023.001)
- Atender a Lei da Transparencia Fiscal (Lei 12.741/2012)
- Simplificar configuracao tributaria por produto/NCM
- Permitir configuracao visual via interface admin

### Arquitetura

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         CONFIGURADOR TRIBUTARIO                          │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  FRONTEND (Next.js)           BACKEND (Express)        BANCO (PostgreSQL)│
│  ┌──────────────────┐        ┌──────────────────┐     ┌────────────────┐ │
│  │ /admin/fiscal/   │   →    │ /api/v1/tributos │  →  │ TribPerfil     │ │
│  │   tributos       │        │ TributacaoService│     │ TribRegra      │ │
│  │   (CRUD visual)  │        │ (Motor calculo)  │     │ TribCST/CSOSN  │ │
│  └──────────────────┘        └──────────────────┘     └────────────────┘ │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Como Funciona o Calculo de Tributos

### 2.1 Fluxo Principal

Quando uma NFCe ou NFe e emitida, o sistema executa o seguinte fluxo:

```
1. EMISSAO DOCUMENTO FISCAL
   │
   ▼
2. TributacaoService.calcularTributos({
     tipoDocumento: 'NFCE' | 'NFE',
     empresaId: uuid,
     itens: [{ produtoId, ncm, cfop, quantidade, valorUnitario, codigoAnp }]
   })
   │
   ▼
3. BUSCA CONTEXTO
   ├── empresa.crt (1=Simples, 2=Simples Exc, 3=Regime Normal)
   ├── empresa.uf (estado de origem)
   └── destinatario.uf (estado de destino)
   │
   ▼
4. PARA CADA ITEM:
   │
   ├── Busca produto.perfilTributarioId (ex: COMB_GASOLINA)
   │
   ├── CALCULA ICMS:
   │   └── buscarRegraTributaria(perfilId, 'ICMS', crt)
   │       ├── Tenta: perfil + tributo + CRT
   │       ├── Tenta: perfil + tributo (sem CRT)
   │       └── Fallback: MERC_GERAL + tributo
   │
   ├── CALCULA PIS:
   │   └── buscarRegraTributaria(perfilId, 'PIS', crt)
   │
   ├── CALCULA COFINS:
   │   └── buscarRegraTributaria(perfilId, 'COFINS', crt)
   │
   ├── VERIFICA MONOFASICO:
   │   └── Se codigoAnp → busca TribANP.aliquotaAdRem
   │       → CST ICMS = 61, CST PIS/COFINS = 04
   │
   └── CALCULA IBPT (Lei Transparencia):
       └── busca TribIBPT por NCM → aliquotas aproximadas
   │
   ▼
5. RETORNA ResultadoCalculo {
     itens: [{ icms, pis, cofins, ibpt }],
     totais: { totalIcms, totalPis, totalCofins, totalTributos }
   }
```

### 2.2 Hierarquia de Busca de Regras

O sistema busca regras tributarias na seguinte ordem:

1. **Especifica**: Perfil do produto + Tributo + CRT
2. **Generica**: Perfil do produto + Tributo (qualquer CRT)
3. **Fallback**: Perfil MERC_GERAL + Tributo

Exemplo para Gasolina no Simples Nacional:
```
1. Busca: perfilId=COMB_GASOLINA, tributo=ICMS, crt=1
   → Se encontrar, usa essa regra

2. Se nao encontrar, busca: perfilId=COMB_GASOLINA, tributo=ICMS, crt=null
   → Se encontrar, usa essa regra

3. Se nao encontrar, busca: perfilId=MERC_GERAL, tributo=ICMS
   → Usa como fallback padrao
```

### 2.3 Tipos de Regime Tributario (CRT)

| CRT | Descricao | CST/CSOSN |
|-----|-----------|-----------|
| 1 | Simples Nacional | Usa CSOSN (101, 102, 500, etc) |
| 2 | Simples Nacional - Excesso Sublimite | Usa CSOSN |
| 3 | Regime Normal | Usa CST (00, 10, 60, 61, etc) |

---

## 3. Perfis de Produto

### 3.1 Conceito

Perfil de produto agrupa produtos com a mesma tributacao. Exemplos:

| Codigo | Descricao | Tipo |
|--------|-----------|------|
| COMB_GASOLINA | Gasolina Comum e Aditivada | MONOFASICO |
| COMB_DIESEL | Diesel S10 e S500 | MONOFASICO |
| COMB_ETANOL | Etanol Hidratado | MONOFASICO |
| MERC_GERAL | Mercadorias em Geral | TRIBUTADO |
| MERC_ISENTO | Produtos Isentos | ISENTO |
| SERV_LAVAGEM | Servicos de Lavagem | TRIBUTADO |

### 3.2 Tipos de Perfil

| Tipo | Descricao |
|------|-----------|
| TRIBUTADO | Produto com tributacao normal |
| ISENTO | Isento de impostos |
| NAO_TRIBUTADO | Nao incide imposto |
| ST | Substituicao Tributaria |
| DIFERIDO | Imposto diferido |
| MONOFASICO | Tributacao monofasica (combustiveis) |
| IMUNE | Imunidade tributaria |

### 3.3 Vinculo com Produto

No cadastro de produto, o campo `perfilTributarioId` define qual perfil usar:

```prisma
model Produto {
  id                String  @id
  nome              String
  ncm               String?
  codigoAnp         String?
  perfilTributarioId String? // → TribPerfilProduto
}
```

---

## 4. Regras Tributarias

### 4.1 Conceito

Cada regra tributaria define como calcular um tributo especifico para um perfil:

```prisma
model TribRegraTributaria {
  id              String   @id
  descricao       String   // "ICMS Gasolina SP - Regime Normal"
  prioridade      Int      // Para ordenacao (maior = mais importante)

  // Criterios de aplicacao
  tributoId       String   // ICMS, PIS, COFINS
  perfilProdutoId String?  // Se null, aplica a todos
  crt             Int?     // 1, 2, 3 ou null (todos)
  ufOrigem        String?  // SP, RJ ou null (todos)

  // Resultado
  cstId           String?  // Para Regime Normal
  csosnId         String?  // Para Simples Nacional
  aliquota        Decimal? // 0.18 = 18%
  reducaoBase     Decimal? // 0.30 = 30% reducao

  // Flags
  isMonofasico    Boolean  // Usa aliquota Ad Rem
  isST            Boolean  // Substituicao Tributaria
  isIsento        Boolean  // Isento de tributo

  // Vigencia
  vigenciaInicio  DateTime
  vigenciaFim     DateTime?
  ativo           Boolean
}
```

### 4.2 Exemplos de Regras

**ICMS Gasolina - Regime Normal (CRT 3)**
```json
{
  "descricao": "ICMS Gasolina - Regime Normal",
  "tributoId": "uuid-icms",
  "perfilProdutoId": "uuid-comb-gasolina",
  "crt": 3,
  "cstId": "uuid-cst-61",
  "isMonofasico": true,
  "aliquota": null
}
```

**ICMS Gasolina - Simples Nacional (CRT 1)**
```json
{
  "descricao": "ICMS Gasolina - Simples Nacional",
  "tributoId": "uuid-icms",
  "perfilProdutoId": "uuid-comb-gasolina",
  "crt": 1,
  "csosnId": "uuid-csosn-500",
  "isMonofasico": true
}
```

**PIS Mercadorias Gerais**
```json
{
  "descricao": "PIS Mercadorias - Aliquota Basica",
  "tributoId": "uuid-pis",
  "perfilProdutoId": "uuid-merc-geral",
  "crt": null,
  "cstId": "uuid-cst-01",
  "aliquota": 0.0165
}
```

---

## 5. Tributacao Monofasica (Combustiveis)

### 5.1 Conceito

A NT 2023.001 implementou a tributacao monofasica (Ad Rem) para combustiveis, substituindo o ICMS por aliquota percentual por aliquota fixa por litro/kg.

### 5.2 Aliquotas Ad Rem (vigentes)

| Combustivel | Codigo ANP | Aliquota | Unidade |
|-------------|------------|----------|---------|
| Gasolina A/C | 210203001/003 | R$ 1,2571 | por litro |
| Diesel S10/S500 | 420101001/002 | R$ 0,9456 | por litro |
| GLP | 610101001 | R$ 1,2571 | por kg |
| Etanol Hidratado | 220102002 | R$ 0,1279 | por litro |
| Etanol Anidro | 220102003 | R$ 0,0000 | por litro |

### 5.3 CST para Monofasico

| Tributo | CST | Descricao |
|---------|-----|-----------|
| ICMS | 61 | Tributacao monofasica sobre combustiveis |
| PIS | 04 | Monofasica - Revenda tributada |
| COFINS | 04 | Monofasica - Revenda tributada |

### 5.4 Calculo

```typescript
// Para combustivel monofasico:
const valorICMS = quantidade * aliquotaAdRem;

// Exemplo: 50 litros de gasolina
const icms = 50 * 1.2571; // = R$ 62,86
```

---

## 6. Interface Admin

### 6.1 Acesso

Menu: **Fiscal → Configurador Tributario**

### 6.2 Funcionalidades

**Aba Perfis de Produto**
- Listar todos os perfis
- Criar novo perfil
- Editar perfil existente
- Visualizar produtos vinculados
- Ativar/Desativar perfil

**Aba Regras Tributarias**
- Listar todas as regras
- Filtrar por tributo, CRT, UF
- Criar nova regra
- Editar regra existente
- Duplicar regra (para criar variantes)
- Definir vigencia

### 6.3 Endpoints da API

| Metodo | Rota | Descricao |
|--------|------|-----------|
| GET | `/api/v1/tributos/perfis-produto` | Listar perfis |
| POST | `/api/v1/tributos/perfis-produto` | Criar perfil |
| GET | `/api/v1/tributos/perfis-produto/:id` | Buscar perfil |
| PUT | `/api/v1/tributos/perfis-produto/:id` | Atualizar perfil |
| DELETE | `/api/v1/tributos/perfis-produto/:id` | Remover perfil |
| GET | `/api/v1/tributos/regras` | Listar regras |
| POST | `/api/v1/tributos/regras` | Criar regra |
| GET | `/api/v1/tributos/regras/:id` | Buscar regra |
| PUT | `/api/v1/tributos/regras/:id` | Atualizar regra |
| DELETE | `/api/v1/tributos/regras/:id` | Remover regra |
| POST | `/api/v1/tributos/regras/:id/duplicar` | Duplicar regra |

---

## 7. Tabelas de Referencia

### 7.1 Resumo

| Tabela | Registros | Fonte |
|--------|-----------|-------|
| TribTributo | 6 | Estatico |
| TribCST | 92 | Estatico |
| TribCSOSN | 10 | Estatico |
| TribCFOP | 247 | Estatico |
| TribANP | 22 | Estatico |
| TribAliquotaUF | 27 | Estatico |
| TribNCM | 10.507 | Siscomex API |
| TribIBPT | 98+ | CDN nfe.io |

### 7.2 Tributos Base

| Codigo | Descricao | Esfera |
|--------|-----------|--------|
| ICMS | Imposto sobre Circulacao de Mercadorias | ESTADUAL |
| PIS | Programa de Integracao Social | FEDERAL |
| COFINS | Contribuicao para Financiamento da Seguridade | FEDERAL |
| IPI | Imposto sobre Produtos Industrializados | FEDERAL |
| ISS | Imposto sobre Servicos | MUNICIPAL |
| FCP | Fundo de Combate a Pobreza | ESTADUAL |

### 7.3 CST ICMS (principais)

| Codigo | Descricao |
|--------|-----------|
| 00 | Tributada integralmente |
| 10 | Tributada com ST |
| 20 | Com reducao de base |
| 40 | Isenta |
| 41 | Nao tributada |
| 60 | ICMS cobrado anteriormente por ST |
| 61 | Tributacao monofasica combustiveis |

### 7.4 CSOSN (Simples Nacional)

| Codigo | Descricao |
|--------|-----------|
| 101 | Tributada com permissao de credito |
| 102 | Tributada sem permissao de credito |
| 103 | Isencao do ICMS no Simples |
| 500 | ICMS cobrado anteriormente por ST |
| 900 | Outros |

---

## 8. Seeds e Atualizacao

### 8.1 Comandos

```bash
# Seed completo (todas as tabelas)
npx tsx src/prisma/seeds/tributos/seed-all.ts --full

# Forcar novo download (ignorar cache)
npx tsx src/prisma/seeds/tributos/seed-all.ts --full --force

# Apenas tabelas especificas
npx tsx src/prisma/seeds/tributos/seed-all.ts --ncm
npx tsx src/prisma/seeds/tributos/seed-all.ts --ibge
npx tsx src/prisma/seeds/tributos/seed-all.ts --ibpt

# Seed perfis e regras padrao
npx tsx src/prisma/seeds/tributos/seed-perfis-regras.ts
```

### 8.2 Cache

Downloads sao cacheados por 30 dias em `seeds/tributos/cache/`.
Use `--force` para ignorar cache e baixar novamente.

---

## 9. Contexto para Outros Chats

### Para Claude entender o sistema:

1. **Perfis agrupam produtos** com mesma tributacao
2. **Regras definem** como calcular cada tributo por perfil
3. **TributacaoService** busca regras no banco (sem hardcoded)
4. **Fallback** para perfil MERC_GERAL se produto sem perfil
5. **Combustiveis** usam tributacao monofasica (CST 61)
6. **CRT** define se usa CST (Regime Normal) ou CSOSN (Simples)

### Arquivos principais:

| Arquivo | Responsabilidade |
|---------|------------------|
| `backend/src/modules/fiscal/services/tributacao.service.ts` | Motor de calculo |
| `backend/src/services/tributo.service.ts` | CRUD de perfis e regras |
| `backend/src/controllers/tributo.controller.ts` | Endpoints REST |
| `frontend/src/app/admin/fiscal/tributos/page.tsx` | Interface admin |

---

## 10. Referencias

- [Portal Unico Siscomex](https://portalunico.siscomex.gov.br/)
- [IBGE Localidades](https://servicodados.ibge.gov.br/api/docs/localidades)
- [IBPT - De Olho no Imposto](https://deolhonoimposto.ibpt.org.br/)
- [NT 2023.001 - Tributacao Monofasica](https://www.nfe.fazenda.gov.br/)

---

*Documento atualizado em: 07/12/2025*
*Versao: 2.0 (Implementacao Completa)*
