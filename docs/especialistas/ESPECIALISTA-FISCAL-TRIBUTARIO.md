# Especialista Fiscal e Tributário - I9 Smart PDV

> **Prompt de Especialista** para assistência em questões relacionadas a tributos, notas fiscais, cadastros e configurador tributário.

---

## PROMPT DO ESPECIALISTA

```
Você é um especialista em configuração fiscal e tributária do sistema I9 Smart PDV Web.
Seu conhecimento abrange:

1. CONFIGURADOR TRIBUTÁRIO - Motor de regras fiscais centralizado
2. EMISSÃO DE NOTAS FISCAIS - NFC-e e NF-e via Focus NFe API
3. CADASTROS - Clientes, Produtos, Veículos
4. TABELAS FISCAIS - NCM, CFOP, CST, CSOSN, ANP, IBPT, CEST

Você deve:
- Ajudar a configurar regras tributárias corretamente
- Diagnosticar e resolver rejeições da SEFAZ
- Orientar cadastro correto de produtos com dados fiscais
- Explicar conceitos de tributação (monofásica, ST, diferido, etc.)
- Validar compatibilidade entre CST/CSOSN e CFOP

Ao responder:
1. Cite as tabelas e campos específicos do banco
2. Indique os arquivos-fonte relevantes
3. Forneça exemplos práticos quando possível
4. Sugira consultas SQL/Prisma quando apropriado
```

---

## 1. ARQUITETURA DO SISTEMA

### 1.1 Visão Geral

```
┌─────────────────────────────────────────────────────────────┐
│                    FRONTEND (Next.js 16)                    │
│  - Cadastro de Produtos/Clientes                            │
│  - PDV (Ponto de Venda)                                     │
│  - Gerenciador de Documentos Fiscais                        │
│  - Configurador Tributário (Admin)                          │
└─────────────────────────────────────────────────────────────┘
                              ↓ API REST
┌─────────────────────────────────────────────────────────────┐
│                    BACKEND (Express + Prisma)               │
│                                                              │
│  ┌─────────────────┐  ┌─────────────────┐                   │
│  │ TributacaoService│  │  NFCe/NFeService │                   │
│  │  (Motor Cálculo) │  │  (Emissão Docs)  │                   │
│  └────────┬────────┘  └────────┬────────┘                   │
│           │                    │                             │
│           ↓                    ↓                             │
│  ┌─────────────────────────────────────────┐                │
│  │            FocusMapper                   │                │
│  │   (Converte para formato Focus NFe)     │                │
│  └─────────────────────────────────────────┘                │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                  BANCO DE DADOS (PostgreSQL)                │
│  - 14 tabelas tributárias (trib_*)                          │
│  - Tabelas fiscais (fis_*)                                  │
│  - Cadastros (cad_*)                                        │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                    FOCUS NFe API                            │
│  - Emissão NFC-e/NF-e                                       │
│  - Cancelamento                                             │
│  - Carta de Correção                                        │
│  - Download DANFe/XML                                       │
└─────────────────────────────────────────────────────────────┘
```

### 1.2 Projetos

| Projeto | Tecnologia | Descrição |
|---------|------------|-----------|
| `backend/` | Express + Prisma + TypeScript | API REST, serviços fiscais |
| `frontend/` | Next.js 16 + React 19 | Interface web, PDV |
| `mobile/` | React Native + Expo | App mobile |
| `pdv_desktop/` | Tauri | Desktop app |

---

## 2. TABELAS DO BANCO DE DADOS

### 2.1 Tabelas Tributárias (trib_*)

| Tabela | Model Prisma | Descrição | Registros |
|--------|--------------|-----------|-----------|
| `trib_tributos` | TribTributo | Cadastro de tributos (ICMS, PIS, COFINS, IPI) | 6 |
| `trib_ncm` | TribNCM | Nomenclatura Comum Mercosul | 10.507 |
| `trib_cfop` | TribCFOP | Códigos Fiscais de Operação | 247 |
| `trib_cst` | TribCST | Códigos Situação Tributária | 92 |
| `trib_csosn` | TribCSOSN | Códigos Simples Nacional | 10 |
| `trib_cest` | TribCEST | Códigos CEST (ST) | - |
| `trib_anp` | TribANP | Códigos ANP (combustíveis) | 22 |
| `trib_ibpt` | TribIBPT | Lei da Transparência | 98+ |
| `trib_aliquotas_uf` | TribAliquotaUF | Alíquotas ICMS por UF | 27 |
| `trib_aliquotas_monofasicas` | TribAliquotaMonofasica | Alíquotas Ad Rem | - |
| `trib_perfis_produto` | TribPerfilProduto | Perfis tributários de produtos | 10+ |
| `trib_perfis_operacao` | TribPerfilOperacao | Perfis de operação | - |
| `trib_regras_tributarias` | TribRegraTributaria | Regras de tributação | 50+ |
| `trib_excecoes_fiscais` | TribExcecaoFiscal | Exceções fiscais | - |

### 2.2 Tabelas Fiscais (fis_*)

| Tabela | Model Prisma | Descrição |
|--------|--------------|-----------|
| `fis_documentos` | FisDocumento | Documentos fiscais (NFC-e, NF-e) |
| `fis_cartas_correcao` | FisCartaCorrecao | Cartas de correção |
| `fis_inutilizacao` | FisInutilizacao | Inutilização de numeração |
| `fis_webhook_logs` | FisWebhookLog | Logs de webhook Focus |
| `fis_configuracoes` | FisConfiguracao | Configurações fiscais por empresa |

### 2.3 Cadastros (cad_*)

| Tabela | Model Prisma | Campos Fiscais Importantes |
|--------|--------------|---------------------------|
| `cad_produtos` | CadProduto | `ncm`, `cest`, `cfop`, `cst`, `codigoAnp`, `descricaoAnp`, `perfilTributarioId` |
| `cad_clientes` | CadCliente | `cpfCnpj`, `inscricaoEstadual`, `tipo` (PF/PJ) |
| `cad_veiculos` | CadVeiculo | `placa`, `modelo` |
| `cad_categorias` | CadCategoria | - |

---

## 3. TABELA PRINCIPAL: TribRegraTributaria

```sql
-- Estrutura da regra tributária
CREATE TABLE trib_regras_tributarias (
  id                  UUID PRIMARY KEY,
  descricao           VARCHAR(200),
  prioridade          INTEGER DEFAULT 100,  -- Menor = mais específico

  -- Critérios de aplicação
  tributo_id          UUID,                 -- ICMS, PIS, COFINS
  perfil_produto_id   UUID,                 -- Perfil do produto
  perfil_operacao_id  UUID,                 -- Tipo de operação
  ncm_id              UUID,                 -- NCM específico
  cfop_id             UUID,                 -- CFOP específico
  cst_id              UUID,                 -- CST específico
  csosn_id            UUID,                 -- CSOSN específico
  cest_id             UUID,                 -- CEST específico
  codigo_anp_id       UUID,                 -- Código ANP
  uf_origem           VARCHAR(2),           -- UF origem
  uf_destino          VARCHAR(2),           -- UF destino
  crt                 INTEGER,              -- 1, 2 ou 3

  -- Resultado da regra
  aliquota            DECIMAL(10,4),        -- % alíquota
  base_calculo        DECIMAL(10,4),        -- % base
  reducao_base        DECIMAL(10,4),        -- % redução
  mva                 DECIMAL(10,4),        -- MVA para ST
  pauta               DECIMAL(10,4),        -- Valor pauta

  -- Flags
  is_monofasico       BOOLEAN DEFAULT false,
  is_st               BOOLEAN DEFAULT false,
  is_diferido         BOOLEAN DEFAULT false,
  is_isento           BOOLEAN DEFAULT false,

  -- Vigência
  vigencia_inicio     DATE,
  vigencia_fim        DATE,
  ativo               BOOLEAN DEFAULT true
);
```

### Hierarquia de Prioridade

```
Prioridade 10  → Mais específico (NCM + UF + CRT)
Prioridade 50  → Intermediário (Perfil + CRT)
Prioridade 100 → Geral (Fallback MERC_GERAL)
```

---

## 4. TABELA ANP (Combustíveis)

### 4.1 Estrutura

```sql
CREATE TABLE trib_anp (
  id              UUID PRIMARY KEY,
  codigo          VARCHAR(9) UNIQUE,      -- Ex: 320101001
  descricao       VARCHAR(200),           -- Ex: GASOLINA C COMUM
  unidade         VARCHAR(10),            -- Ex: L
  ncm_padrao      VARCHAR(10),            -- NCM correspondente
  is_monofasico   BOOLEAN DEFAULT false,  -- CRÍTICO: Define se usa CST 61
  aliquota_ad_rem DECIMAL(10,4)           -- R$/L (não percentual)
);
```

### 4.2 Códigos ANP Importantes

| Código | Descrição | Monofásico | Alíquota Ad Rem |
|--------|-----------|------------|-----------------|
| 320101001 | GASOLINA C COMUM | true | 1.22 |
| 320102001 | GASOLINA C ADITIVADA | true | 1.3721 |
| 320102002 | GASOLINA C PREMIUM | true | 1.3721 |
| 810101001 | ETANOL HIDRATADO COMUM | **false** | null |
| 820101033 | OLEO DIESEL B S500 | true | 0.9456 |
| 820101034 | OLEO DIESEL B S10 | true | 0.9456 |

### 4.3 Regra de Monofásico

```typescript
// Combustíveis derivados de petróleo = Monofásico
32xxxx = Gasolina → isMonofasico = true, CST 61
42xxxx = Diesel comum → isMonofasico = true, CST 61
82xxxx = Diesel S10/S500 → isMonofasico = true, CST 61

// Biocombustíveis = NÃO Monofásico
81xxxx = Etanol → isMonofasico = false, CST 00/20
22xxxx = GNV → isMonofasico = false
```

---

## 5. COMPATIBILIDADE CST x CFOP

### 5.1 Regras de Validação

| CST | CFOPs Válidos | CFOPs Inválidos |
|-----|---------------|-----------------|
| 00, 20, 102 | 5102, 6102, 7101 | 5405, 5656, 6404, 6656 |
| 60, 61 | 5405, 5656, 6404, 6656 | 5102, 6102 |
| 40, 41 | 5102, 5405 | - |

### 5.2 Função de Validação

```typescript
// backend/src/modules/fiscal/mappers/focus.mapper.ts

function validarCfopComCst(cfop: string, cst: string): boolean {
  const cfopNum = parseInt(cfop, 10);

  // CST de ST/Monofásica precisam de CFOP de ST
  if (cst === '60' || cst === '61' || cst === '500') {
    const cfopsStValidos = [5405, 5656, 5667, 6404, 6656, 6667];
    return cfopsStValidos.includes(cfopNum);
  }

  // CST normal não deve usar CFOP de ST/monofásico
  if (cst === '00' || cst === '20' || cst === '102') {
    const cfopsInvalidos = [5405, 5656, 5667, 6404, 6656, 6667];
    return !cfopsInvalidos.includes(cfopNum);
  }

  return true;
}
```

---

## 6. ENDPOINTS DA API

### 6.1 Documentos Fiscais

| Método | Endpoint | Descrição |
|--------|----------|-----------|
| POST | `/api/v1/fis/documentos/nfce/emitir` | Emitir NFC-e |
| GET | `/api/v1/fis/documentos/nfce/:referencia` | Consultar NFC-e |
| POST | `/api/v1/fis/documentos/nfce/:referencia/cancelar` | Cancelar NFC-e |
| GET | `/api/v1/fis/documentos/nfce/:referencia/danfe` | Download DANFCe |
| GET | `/api/v1/fis/documentos/nfce/:referencia/xml` | Download XML |
| POST | `/api/v1/fis/documentos/nfe/emitir` | Emitir NF-e |
| GET | `/api/v1/fis/documentos/nfe/:referencia` | Consultar NF-e |
| POST | `/api/v1/fis/documentos/nfe/:referencia/cancelar` | Cancelar NF-e |
| POST | `/api/v1/fis/documentos/nfe/:referencia/carta-correcao` | Carta de Correção |
| GET | `/api/v1/fis/documentos/nfe/:referencia/danfe` | Download DANFe |
| GET | `/api/v1/fis/documentos/nfe/:referencia/xml` | Download XML |

### 6.2 Configuração Tributária

| Método | Endpoint | Descrição |
|--------|----------|-----------|
| GET | `/api/v1/fis/tributos/perfis-produto` | Listar perfis |
| POST | `/api/v1/fis/tributos/perfis-produto` | Criar perfil |
| PUT | `/api/v1/fis/tributos/perfis-produto/:id` | Atualizar perfil |
| DELETE | `/api/v1/fis/tributos/perfis-produto/:id` | Remover perfil |
| GET | `/api/v1/fis/tributos/regras` | Listar regras |
| POST | `/api/v1/fis/tributos/regras` | Criar regra |
| PUT | `/api/v1/fis/tributos/regras/:id` | Atualizar regra |
| DELETE | `/api/v1/fis/tributos/regras/:id` | Remover regra |
| GET | `/api/v1/fis/tributos/tributos` | Listar tributos |
| GET | `/api/v1/fis/tributos/csts` | Listar CSTs |
| GET | `/api/v1/fis/tributos/csosns` | Listar CSOSNs |

### 6.3 PDV e Vendas

| Método | Endpoint | Descrição |
|--------|----------|-----------|
| GET | `/api/v1/pdv/vendas/:numero/completo` | **Venda completa com todos os dados** |
| GET | `/api/v1/pdv/vendas` | Listar vendas |
| GET | `/api/v1/pdv/vendas/:id` | Buscar venda por ID |
| POST | `/api/v1/pdv/vendas` | Criar venda |
| POST | `/api/v1/pdv/vendas/:id/finalizar` | Finalizar venda |

### 6.4 Cadastros

| Método | Endpoint | Descrição |
|--------|----------|-----------|
| GET | `/api/v1/clientes` | Listar clientes |
| POST | `/api/v1/clientes` | Criar cliente |
| PUT | `/api/v1/clientes/:id` | Atualizar cliente |
| GET | `/api/v1/clientes/:id/veiculos` | Listar veículos |
| GET | `/api/v1/produtos` | Listar produtos |
| POST | `/api/v1/produtos` | Criar produto |
| PUT | `/api/v1/produtos/:id` | Atualizar produto |

---

## 7. ARQUIVOS-FONTE PRINCIPAIS

### 7.1 Serviços Fiscais

| Arquivo | Descrição |
|---------|-----------|
| `backend/src/modules/fiscal/services/tributacao.service.ts` | Motor de cálculo de tributos |
| `backend/src/modules/fiscal/services/nfce.service.ts` | Emissão de NFC-e |
| `backend/src/modules/fiscal/services/nfe.service.ts` | Emissão de NF-e |
| `backend/src/modules/fiscal/mappers/focus.mapper.ts` | Conversão para formato Focus |
| `backend/src/modules/fiscal/clients/focus-nfe.client.ts` | Cliente HTTP Focus NFe |

### 7.2 Tipos e Interfaces

| Arquivo | Descrição |
|---------|-----------|
| `backend/src/modules/fiscal/types/tributacao.types.ts` | Tipos do motor de tributação |
| `backend/src/modules/fiscal/types/focus-nfe.types.ts` | Tipos da API Focus |

### 7.3 Controllers e Rotas

| Arquivo | Descrição |
|---------|-----------|
| `backend/src/modules/fiscal/controllers/nfce.controller.ts` | Controller NFC-e |
| `backend/src/modules/fiscal/controllers/nfe.controller.ts` | Controller NF-e |
| `backend/src/routes/v1/fis/documentos.routes.ts` | Rotas de documentos fiscais |
| `backend/src/routes/v1/fis/tributos.routes.ts` | Rotas de configuração tributária |

### 7.4 Schema do Banco

| Arquivo | Descrição |
|---------|-----------|
| `backend/src/prisma/schema.prisma` | Schema completo do banco |

---

## 8. FLUXO DE CÁLCULO TRIBUTÁRIO

```
1. NFCe/NFeService recebe vendaId
   ↓
2. Busca venda com itens e pagamentos
   ↓
3. TributacaoService.calcularTributos()
   │
   ├─► Busca empresa (CRT, UF)
   │
   ├─► Para cada item:
   │   ├─► Busca perfilTributarioId do produto
   │   ├─► Busca dados ANP (se combustível)
   │   ├─► Verifica se é monofásico (isMonofasico)
   │   ├─► Busca regra tributária por prioridade
   │   ├─► Calcula ICMS (normal ou Ad Rem)
   │   ├─► Calcula PIS
   │   ├─► Calcula COFINS
   │   └─► Calcula IBPT (Lei Transparência)
   │
   ├─► Totaliza valores
   │
   └─► Retorna ResultadoCalculo
   ↓
4. FocusMapper.mapToFocusItem()
   ├─► Determina CST correto
   ├─► Determina CFOP compatível
   ├─► Adiciona campos monofásicos (se CST 61)
   └─► Adiciona campos combustível (se ANP)
   ↓
5. Envia para Focus NFe API
   ↓
6. Atualiza FisDocumento com resultado
```

---

## 9. REJEIÇÕES SEFAZ COMUNS

### 9.1 Rejeição: CFOP não permitido para CST

**Causa:** CST 00 com CFOP 5656 (ou vice-versa)

**Solução:**
```sql
-- Verificar produto
SELECT p.nome, p.cfop, p.cst, a.is_monofasico
FROM cad_produtos p
LEFT JOIN trib_anp a ON a.codigo = p.codigo_anp
WHERE p.id = 'xxx';

-- Se etanol com CFOP 5656, corrigir:
UPDATE cad_produtos SET cfop = '5102' WHERE codigo_anp LIKE '81%';
```

### 9.2 Rejeição: Grupo Monofásica não permitido

**Causa:** Enviando campos monofásicos para produto não-monofásico

**Solução:**
```sql
-- Verificar se ANP está correto
SELECT * FROM trib_anp WHERE codigo = '810101001';

-- Corrigir etanol para não ser monofásico
UPDATE trib_anp
SET is_monofasico = false, aliquota_ad_rem = NULL
WHERE codigo LIKE '81%' AND descricao LIKE '%ETANOL%';
```

### 9.3 Rejeição: Obrigatório Grupo Monofásica

**Causa:** CST 61 sem campos monofásicos

**Solução:**
```sql
-- Verificar se alíquota Ad Rem está preenchida
SELECT codigo, descricao, is_monofasico, aliquota_ad_rem
FROM trib_anp
WHERE codigo LIKE '32%' OR codigo LIKE '82%';

-- Gasolina e Diesel devem ter aliquota_ad_rem
```

### 9.4 Rejeição: modBC obrigatório

**Causa:** Base de cálculo sem modalidade

**Solução:** O mapper deve incluir `icms_modalidade_base_calculo: 3` quando há base de cálculo.

---

## 10. CONSULTAS ÚTEIS

### 10.1 Verificar Configuração de Produto

```sql
SELECT
  p.codigo,
  p.nome,
  p.ncm,
  p.cfop,
  p.cst,
  p.codigo_anp,
  a.descricao as anp_descricao,
  a.is_monofasico,
  a.aliquota_ad_rem,
  pp.codigo as perfil_codigo,
  pp.tipo_perfil
FROM cad_produtos p
LEFT JOIN trib_anp a ON a.codigo = p.codigo_anp
LEFT JOIN trib_perfis_produto pp ON pp.id = p.perfil_tributario_id
WHERE p.tipo = 'COMBUSTIVEL';
```

### 10.2 Verificar Regras Ativas

```sql
SELECT
  r.descricao,
  r.prioridade,
  t.codigo as tributo,
  pp.codigo as perfil,
  r.aliquota,
  r.is_monofasico,
  r.uf_origem,
  r.uf_destino
FROM trib_regras_tributarias r
LEFT JOIN trib_tributos t ON t.id = r.tributo_id
LEFT JOIN trib_perfis_produto pp ON pp.id = r.perfil_produto_id
WHERE r.ativo = true
ORDER BY r.prioridade ASC;
```

### 10.3 Documentos Fiscais por Status

```sql
SELECT
  tipo,
  status,
  COUNT(*) as quantidade,
  SUM(valor_total) as total
FROM fis_documentos
WHERE criado_em >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY tipo, status
ORDER BY tipo, status;
```

---

## 11. DIAGNÓSTICO VIA API

### 11.1 Endpoint: Venda Completa

O endpoint `/api/v1/pdv/vendas/:numero/completo` retorna todos os dados necessários para diagnóstico fiscal.

**Uso via curl:**

```bash
# Autenticar e consultar venda pelo número
/bin/bash -c 'TOKEN=$(curl -s -X POST "http://localhost:4001/api/v1/auth/login" \
  -H "Content-Type: application/json" \
  -d "{\"login\":\"admin@i9smart.com.br\",\"senha\":\"123456\"}" | jq -r ".data.access_token") && \
  curl -s "http://localhost:4001/api/v1/pdv/vendas/40/completo" \
  -H "Authorization: Bearer $TOKEN" | jq "."'
```

**Estrutura do Retorno:**

```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "numero": 40,
    "status": "FINALIZADA",
    "total": "175.65",

    // Dados fiscais da empresa
    "empresa": {
      "cnpj": "02393780000102",
      "inscricaoEstadual": "00000000435961",
      "estado": "RO",
      "crt": 3  // Regime Normal
    },

    // Dados do cliente (para NF-e)
    "cliente": {
      "cpfCnpj": "98765432100",
      "tipo": "PF",
      "inscricaoEstadual": null,
      "endereco": "Rua das Palmeiras",
      "cidade": "São Paulo",
      "estado": "SP",
      "cep": "01234000"
    },

    // Veículo (para frota)
    "veiculo": {
      "placa": "ABC1234",
      "hodometroAtual": 302224
    },

    // Itens com dados fiscais
    "itens": [{
      "quantidade": "28.77",
      "precoUnitario": "6.109",
      "total": "175.65",
      "produto": {
        "codigo": "GAS001",
        "nome": "Gasolina Comum",
        "tipo": "COMBUSTIVEL",
        "ncm": "27101259",
        "cfop": "5656",
        "cst": "61",
        "codigoAnp": "320101001",
        "descricaoAnp": "GASOLINA C COMUM"
      }
    }],

    // Pagamentos
    "pagamentos": [{
      "tipo": "DINHEIRO",
      "valor": "175.65",
      "status": "APROVADO"
    }],

    // Documentos fiscais emitidos
    "documentosFiscais": [{
      "tipo": "NFCE",
      "status": "AUTORIZADO",
      "chaveAcesso": "11...",
      "numero": 123,
      "serie": 502
    }]
  }
}
```

### 11.2 Campos Importantes para Diagnóstico

| Campo | Localização | Uso |
|-------|-------------|-----|
| `empresa.crt` | data.empresa.crt | Determina CST vs CSOSN |
| `empresa.estado` | data.empresa.estado | UF origem |
| `cliente.estado` | data.cliente.estado | UF destino (NF-e) |
| `produto.codigoAnp` | data.itens[].produto.codigoAnp | Identifica combustível |
| `produto.ncm` | data.itens[].produto.ncm | Classificação fiscal |
| `produto.cfop` | data.itens[].produto.cfop | CFOP cadastrado |
| `produto.cst` | data.itens[].produto.cst | CST cadastrado |

### 11.3 Verificar Dados Específicos

```bash
# Ver apenas dados fiscais do produto
curl -s "http://localhost:4001/api/v1/pdv/vendas/40/completo" \
  -H "Authorization: Bearer $TOKEN" | \
  jq '.data.itens[].produto | {codigo, nome, ncm, cfop, cst, codigoAnp}'

# Ver dados da empresa
curl -s "http://localhost:4001/api/v1/pdv/vendas/40/completo" \
  -H "Authorization: Bearer $TOKEN" | \
  jq '.data.empresa | {cnpj, estado, crt}'

# Ver documentos fiscais
curl -s "http://localhost:4001/api/v1/pdv/vendas/40/completo" \
  -H "Authorization: Bearer $TOKEN" | \
  jq '.data.documentosFiscais'
```

### 11.4 Fluxo de Diagnóstico de Rejeição

```
1. Recebe rejeição SEFAZ (ex: "CFOP não permitido para CST")
   ↓
2. Consulta venda completa pelo número
   GET /api/v1/pdv/vendas/:numero/completo
   ↓
3. Identifica o item com problema
   - produto.cfop vs produto.cst
   - produto.codigoAnp → trib_anp.is_monofasico
   ↓
4. Verifica tabela ANP
   SELECT * FROM trib_anp WHERE codigo = 'xxx'
   ↓
5. Corrige no banco ou cadastro
   - trib_anp.is_monofasico
   - cad_produtos.cfop
   ↓
6. Reemite documento fiscal
```

### 11.5 Emissão via API (curl)

**Autenticação:**

```bash
# Obter token
TOKEN=$(curl -s -X POST "http://localhost:4001/api/v1/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"login":"admin@i9smart.com.br","senha":"123456"}' | jq -r ".data.access_token")
```

**Emitir NFC-e (síncrono):**

```bash
# Payload simples - apenas vendaId
curl -s -X POST "http://localhost:4001/api/v1/fis/documentos/nfce/emitir" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"vendaId":"uuid-da-venda"}' | jq "."
```

**Emitir NF-e (assíncrono - requer destinatário):**

```bash
# Payload completo com destinatário
curl -s -X POST "http://localhost:4001/api/v1/fis/documentos/nfe/emitir" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "vendaId": "uuid-da-venda",
    "destinatario": {
      "cpfCnpj": "12345678901",
      "nome": "Nome do Cliente",
      "endereco": "Rua Exemplo",
      "numero": "123",
      "bairro": "Centro",
      "cidade": "São Paulo",
      "estado": "SP",
      "cep": "01234567"
    }
  }' | jq "."
```

**Consultar status (polling para NF-e):**

```bash
# Usar a referência retornada na emissão
curl -s "http://localhost:4001/api/v1/fis/documentos/nfe/REF123" \
  -H "Authorization: Bearer $TOKEN" | jq "."
```

**Consultar documento por venda:**

```bash
# Busca documento mais recente da venda
curl -s "http://localhost:4001/api/v1/fis/documentos/venda/uuid-da-venda" \
  -H "Authorization: Bearer $TOKEN" | jq "."
```

**Cancelar documento:**

```bash
# Cancelar NFC-e (justificativa mínimo 15 caracteres)
curl -s -X POST "http://localhost:4001/api/v1/fis/documentos/nfce/REF123/cancelar" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"justificativa":"Venda cancelada a pedido do cliente"}' | jq "."
```

**Download DANFE/XML:**

```bash
# Download DANFCe (PDF)
curl -s "http://localhost:4001/api/v1/fis/documentos/nfce/REF123/danfe" \
  -H "Authorization: Bearer $TOKEN" -o danfce.pdf

# Download XML
curl -s "http://localhost:4001/api/v1/fis/documentos/nfce/REF123/xml" \
  -H "Authorization: Bearer $TOKEN" -o nfce.xml
```

### 11.6 Exemplo Completo: Testar Emissão de Etanol

```bash
#!/bin/bash
# Script de teste para emissão de NFC-e com etanol

# 1. Autenticar
TOKEN=$(curl -s -X POST "http://localhost:4001/api/v1/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"login":"admin@i9smart.com.br","senha":"123456"}' | jq -r ".data.access_token")

# 2. Buscar venda com etanol
VENDA=$(curl -s "http://localhost:4001/api/v1/pdv/vendas?perPage=100" \
  -H "Authorization: Bearer $TOKEN" | \
  jq -r '.data[] | select(.status == "FINALIZADA") | .id' | head -1)

echo "Venda ID: $VENDA"

# 3. Verificar dados da venda
curl -s "http://localhost:4001/api/v1/pdv/vendas/$VENDA/completo" \
  -H "Authorization: Bearer $TOKEN" | \
  jq '.data.itens[].produto | {codigo, nome, codigoAnp, cfop, cst}'

# 4. Emitir NFC-e
curl -s -X POST "http://localhost:4001/api/v1/fis/documentos/nfce/emitir" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"vendaId\":\"$VENDA\"}" | jq "."
```

---

## 12. DIFERENÇAS NFC-e vs NF-e

| Aspecto | NFC-e | NF-e |
|---------|-------|------|
| **Processamento** | Síncrono | Assíncrono (polling) |
| **Destinatário** | Opcional (CPF) | Obrigatório (endereço completo) |
| **CFOP** | Estadual (5xxx) | Est/Inter/Ext (5xxx/6xxx/7xxx) |
| **Série Homologação** | 502 | 501 |
| **Série Produção** | 2 | 1 |
| **Prazo Cancelamento** | 24h | 7 dias |
| **Carta Correção** | Não suportada | Suportada |
| **IPI** | Não aplicável | Aplicável |

---

## 12. CHECKLIST DE CADASTRO

### 12.1 Produto Combustível

- [ ] Código ANP preenchido corretamente
- [ ] NCM compatível com ANP
- [ ] CFOP adequado ao CST (5656 para monofásico, 5102 para normal)
- [ ] Perfil tributário vinculado
- [ ] Unidade = "L" (litro)
- [ ] Verificar `is_monofasico` na tabela `trib_anp`

### 12.2 Produto Normal

- [ ] NCM preenchido (8 dígitos)
- [ ] CFOP padrão (5102 para venda interna)
- [ ] CST/CSOSN conforme regime (CRT)
- [ ] Alíquotas de ICMS, PIS, COFINS
- [ ] Perfil tributário vinculado

### 12.3 Cliente para NF-e

- [ ] CPF ou CNPJ válido
- [ ] Nome completo
- [ ] Endereço completo (logradouro, número, bairro, cidade, UF, CEP)
- [ ] Inscrição Estadual (se contribuinte)
- [ ] Indicador IE (1=Contribuinte, 2=Isento, 9=Não contribuinte)

---

## 13. ENUMS IMPORTANTES

### 13.1 Tipo de Perfil Tributário

```typescript
enum TribTipoPerfil {
  TRIBUTADO       // Tributação normal
  ISENTO          // Isento de ICMS
  NAO_TRIBUTADO   // Não tributado
  ST              // Substituição Tributária
  DIFERIDO        // Diferimento
  MONOFASICO      // Tributação monofásica
  IMUNE           // Imunidade tributária
}
```

### 13.2 Status de Documento Fiscal

```typescript
enum StatusDocumentoFiscal {
  PENDENTE           // Aguardando processamento
  PROCESSANDO        // Em processamento na SEFAZ
  AUTORIZADO         // Autorizado com sucesso
  REJEITADO          // Rejeitado pela SEFAZ
  CANCELADO          // Cancelado
  DENEGADO           // Denegado (irregularidade)
  ERRO_AUTORIZACAO   // Erro durante autorização
}
```

### 13.3 CRT (Código Regime Tributário)

```typescript
1 = Simples Nacional
2 = Simples Nacional (Excesso de sublimite)
3 = Regime Normal (Lucro Presumido/Real)
```

---

## 14. DIFAL - Operações Interestaduais (EC 87/2015)

### 14.1 O que é DIFAL?

O **DIFAL** (Diferencial de Alíquota) é devido nas operações interestaduais destinadas a **consumidor final não contribuinte** do ICMS. A Emenda Constitucional 87/2015 estabeleceu a partilha do ICMS entre os estados de origem e destino.

### 14.2 Quando Informar o DIFAL

O grupo ICMSUFDest (DIFAL) é **obrigatório** quando:

| Condição | Valor |
|----------|-------|
| `local_destino` | 2 (Interestadual) |
| `consumidor_final` | 1 (Sim) |
| `indicador_ie_destinatario` | 9 (Não contribuinte) |
| CST ICMS | 00, 20 (tributado) |

### 14.3 Cálculo do DIFAL

```
Base de Cálculo = Valor do Produto
Alíquota Interestadual = 7% ou 12% (conforme tabela)
Alíquota Interna UF Destino = Alíquota do estado de destino
DIFAL = (Alíquota Interna - Alíquota Interestadual)
Valor DIFAL = Base × (DIFAL / 100)
```

**Desde 2019:** 100% do DIFAL vai para a UF de destino (`vICMSUFRemet = 0`).

### 14.4 Alíquotas Interestaduais

| Origem → Destino | Alíquota |
|------------------|----------|
| Sul/Sudeste → N/NE/CO/ES | **7%** |
| Demais combinações | **12%** |

**Estados Sul/Sudeste:** SP, RJ, MG, ES, PR, SC, RS

### 14.5 Alíquotas Internas por UF

| UF | Alíquota | FCP | UF | Alíquota | FCP |
|----|----------|-----|----|----------|-----|
| AC | 19% | 0% | PB | 20% | 2% |
| AL | 19% | 2% | PE | 20.5% | 2% |
| AM | 20% | 2% | PI | 21% | 2% |
| AP | 18% | 0% | PR | 19.5% | 0% |
| BA | 20.5% | 2% | RJ | 22% | 2% |
| CE | 20% | 2% | RN | 20% | 2% |
| DF | 20% | 2% | RO | 19.5% | 2% |
| ES | 17% | 2% | RR | 20% | 0% |
| GO | 19% | 2% | RS | 17% | 0% |
| MA | 22% | 2% | SC | 17% | 0% |
| MG | 18% | 2% | SE | 19% | 2% |
| MS | 17% | 2% | SP | 18% | 2% |
| MT | 17% | 2% | TO | 20% | 2% |
| PA | 19% | 0% | | | |

### 14.6 Campos Focus NFe API (DIFAL)

> **IMPORTANTE:** Os nomes dos campos devem ser exatamente como na documentação oficial da Focus NFe:
> https://campos.focusnfe.com.br/nfe/ItemNotaFiscalXML.html

| Campo | Descrição | Exemplo |
|-------|-----------|---------|
| `icms_base_calculo_uf_destino` | Base de cálculo ICMS UF destino | 180.85 |
| `fcp_base_calculo_uf_destino` | Base de cálculo FCP UF destino | 180.85 |
| `fcp_percentual_uf_destino` | % FCP UF destino | 2.0 |
| `icms_aliquota_interna_uf_destino` | Alíquota interna UF destino | 18.0 |
| `icms_aliquota_interestadual` | Alíquota interestadual | 12.0 |
| `icms_percentual_partilha` | % partilha (100 desde 2019) | 100 |
| `fcp_valor_uf_destino` | Valor FCP UF destino | 3.62 |
| `icms_valor_uf_destino` | Valor ICMS DIFAL UF destino | 10.85 |
| `icms_valor_uf_remetente` | Valor ICMS UF origem (0 desde 2019) | 0.00 |

> **ATENÇÃO - Nomes incorretos que causam rejeição:**
> - ❌ `fcp_aliquota_uf_destino` → ✅ `fcp_percentual_uf_destino`
> - ❌ `icms_aliquota_uf_destino` → ✅ `icms_aliquota_interna_uf_destino`
> - ❌ `icms_aliquota_interestadual_partilha` → ✅ `icms_percentual_partilha`

### 14.7 Exemplo de Cálculo

**Operação:** Venda de Etanol de RO para SP (Consumidor Final PF)

```
Base de Cálculo: R$ 180.85
Alíquota Interestadual (RO→SP): 12%
Alíquota Interna SP: 18%
FCP SP: 2%

ICMS Interestadual = 180.85 × 12% = R$ 21.70
DIFAL = 18% - 12% = 6%
Valor DIFAL = 180.85 × 6% = R$ 10.85
Valor FCP = 180.85 × 2% = R$ 3.62

Total ICMS recolhido:
- UF Origem (RO): R$ 21.70 (12%)
- UF Destino (SP): R$ 10.85 + R$ 3.62 = R$ 14.47 (DIFAL + FCP)
```

### 14.8 Implementação no Sistema

O cálculo do DIFAL é feito automaticamente no `nfe.service.ts`:

```typescript
// Detecta operação interestadual com consumidor final
const isInterestadual = localDestino === 2;
const isConsumidorFinal = !isCnpj; // PF = consumidor final

// Calcula DIFAL apenas quando necessário
if (isInterestadual && isConsumidorFinal && !isMonofasico && baseCalculo > 0) {
  const aliquotaInterestadual = itemTrib.icms.aliquota; // 7% ou 12%
  const aliquotaInterna = this.getAliquotaInternaUF(ufDestinatario);
  const fcpPercentual = this.getFcpUF(ufDestinatario);

  const difal = aliquotaInterna - aliquotaInterestadual;
  const valorDifal = baseCalculo * (difal / 100);
  const valorFcp = baseCalculo * (fcpPercentual / 100);
}
```

### 14.9 Rejeições SEFAZ - DIFAL

| Código | Mensagem SEFAZ | Causa | Solução |
|--------|----------------|-------|---------|
| **694** | "Não informado grupo ICMS UF destino" | DIFAL obrigatório não enviado | Verificar condições: `isInterestadual && isConsumidorFinal && !isMonofasico` |
| **815** | "Valor ICMS Interestadual UF Destino difere do calculado" | Nome de campo incorreto ou cálculo errado | Usar nomes corretos: `icms_aliquota_interna_uf_destino`, `icms_percentual_partilha` |
| **694** | "pICMSInter não é elemento válido" | Nome do campo incorreto | Usar `icms_aliquota_interestadual` (não `percentual`) |
| **815** | "Valor Informado: X - Valor Calculado: 0" | Campo com nome errado sendo ignorado | Verificar nomes na documentação Focus NFe |
| **693** | "Alíquota superior à interestadual" | Usando alíquota interna (18%) como interestadual | Usar tabela de alíquotas interestaduais (7% ou 12%) |

**Dica de Debug:** Se a SEFAZ calcular `0` para o DIFAL, significa que algum campo está com nome incorreto e sendo ignorado.

---

## 15. COMPATIBILIDADE CFOP vs CST

### 15.1 Regra Geral

O **CFOP** (Código Fiscal de Operações) deve ser compatível com o **CST** (Código de Situação Tributária) do ICMS:

| CST | CFOPs Válidos | Descrição |
|-----|---------------|-----------|
| 00, 20 | 5102, 6102, 7102 | Tributação normal |
| 60 | 5405, 6404, 5656, 6656 | Substituição tributária |
| 61 | 5656, 6656, 5667, 6667 | Tributação monofásica |
| 41, 50 | Qualquer | Não tributado/Suspensão |

### 15.2 CFOPs para Combustíveis

| Combustível | CST | CFOP Interno | CFOP Interestadual |
|-------------|-----|--------------|-------------------|
| Gasolina | 61 | 5656 | 6656 |
| Diesel | 61 | 5656 | 6656 |
| **Etanol** | **00** | **5102** | **6102** |
| GNV | 61 | 5656 | 6656 |

**Atenção:** Etanol é combustível mas **NÃO é monofásico** (CST 00, não 61).

### 15.3 Validação Automática

O sistema valida automaticamente a compatibilidade no `nfe.service.ts`:

```typescript
// CFOPs que só podem ser usados com CST de ST/Monofásico (60, 61, 500)
const cfopsStMonofasico = [405, 656, 667];

// Se CST é normal (00, 20, 102), não pode usar esses CFOPs
if (!isStMonofasico && cfopsStMonofasico.includes(cfopBase)) {
  // Corrige para CFOP de mercadoria normal
  return `${prefixo}102`; // 5102 ou 6102
}
```

### 15.4 Erros Comuns CFOP vs CST

| Erro SEFAZ | Causa | Solução |
|------------|-------|---------|
| "CFOP não permitido para CST" | CFOP 5656 com CST 00 | Usar CFOP 5102 para CST normal |
| "CST incompatível com operação" | CST 61 para etanol | Verificar `trib_anp.is_monofasico` |
| "CFOP inválido para operação" | CFOP interno em op. interestadual | Usar prefixo 6xxx |

---

## 16. CACHE DO SISTEMA

O `TributacaoService` implementa cache para performance:

```typescript
// Caches em memória
private cacheAnp: Map<string, DadosAnp | null>       // Dados ANP
private cacheIbpt: Map<string, DadosIbpt | null>     // Dados IBPT
private cacheRegras: Map<string, DadosRegraTributaria | null>  // Regras
private perfilGeralId: string | null                  // Perfil MERC_GERAL

// Chave do cache de regras: "perfilId_tributoCode_crt"
```

**Observação:** Cache não tem TTL automático. Reiniciar o servidor limpa o cache.

---

## 17. DOCUMENTAÇÃO RELACIONADA

| Documento | Localização |
|-----------|-------------|
| Conceito do Configurador | `backend/docs/configurador_tributario/CONCEITO-CONFIGURADOR-TRIBUTOS.md` |
| Plano de Implementação | `backend/docs/configurador_tributario/PLANO-IMPLEMENTACAO.md` |
| Análise do Schema | `backend/docs/configurador_tributario/reports/ANALISE-SCHEMA-FISCAL.md` |
| Análise NFC-e | `backend/docs/configurador_tributario/reports/ANALISE-SERVICOS-NFCE.md` |
| Análise NF-e | `backend/docs/configurador_tributario/reports/ANALISE-SERVICOS-NFE.md` |
| Funcionalidades | `docs/FUNCIONALIDADES.md` |
| Multi-empresa | `docs/MULTI-EMPRESA.md` |

---

**Última atualização:** 2025-02-07
