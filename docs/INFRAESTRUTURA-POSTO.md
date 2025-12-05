# Infraestrutura do Posto de Combustível

Este documento descreve a estrutura de dados para gerenciamento da infraestrutura física de um posto de combustível.

## Hierarquia de Relacionamentos

```
Empresa
  └── Concentrador (1:N) ─── Equipamento que controla bombas
        └── Bomba (1:N) ───── Equipamento físico de abastecimento
              ├── Bico (1:N) ── Mangueira/pistola de abastecimento
              │     └── Tanque (N:1) ─ Reservatório de combustível
              └── Lacre (1:N) ─ Histórico de lacres fiscais
```

## Modelos

### 1. Concentrador

Equipamento eletrônico que gerencia a comunicação com as bombas. Cada posto pode ter múltiplos concentradores.

| Campo | Tipo | Obrigatório | Descrição |
|-------|------|-------------|-----------|
| id | UUID | Sim | Identificador único |
| empresaId | UUID | Sim | FK para Empresa |
| nome | String | Não | Nome descritivo (ex: "Concentrador Pista 1") |
| modelo | String | Sim | Modelo do equipamento (ex: "WAYNE HELIX 6000") |
| tipoConexao | Enum | Sim | TCP_IP, SERIAL, USB, BLUETOOTH |
| ip | String | Não | Endereço IP (quando TCP_IP) |
| porta | Int | Não | Porta de comunicação |
| ativo | Boolean | Sim | Se está ativo (default: true) |

**Tipos de Conexão:**
- `TCP_IP` - Conexão via rede (mais comum)
- `SERIAL` - Conexão serial RS-232/RS-485
- `USB` - Conexão USB direta
- `BLUETOOTH` - Conexão sem fio Bluetooth

**Relações:**
- Pertence a uma `Empresa` (N:1)
- Possui várias `Bombas` (1:N)

---

### 2. Bomba

Equipamento físico de abastecimento onde ficam instalados os bicos.

| Campo | Tipo | Obrigatório | Descrição |
|-------|------|-------------|-----------|
| id | UUID | Sim | Identificador único |
| empresaId | UUID | Sim | FK para Empresa |
| concentradorId | UUID | Não | FK para Concentrador |
| numero | Int | Sim | Número da bomba no posto (único por empresa) |
| modelo | String | Não | Modelo da bomba (ex: "WAYNE HELIX 4000") |
| fabricante | String | Não | Fabricante (ex: "Wayne", "Gilbarco") |
| numeroSerie | String | Não | Número de série do fabricante |
| identificador | String | Não | Código interno do posto |
| status | Enum | Sim | Status atual da bomba |

**Status da Bomba:**
- `LIVRE` - Disponível para abastecimento
- `EM_ABASTECIMENTO` - Abastecimento em andamento
- `BLOQUEADA` - Bloqueada pelo sistema/operador
- `MANUTENCAO` - Em manutenção
- `OFFLINE` - Sem comunicação

**Relações:**
- Pertence a uma `Empresa` (N:1)
- Pertence a um `Concentrador` (N:1) - opcional
- Possui vários `Bicos` (1:N)
- Possui vários `Lacres` (1:N)
- Possui vários `Abastecimentos` (1:N)

**Constraint:** Número único por empresa (`empresaId` + `numero`)

---

### 3. Bico

Mangueira/pistola de abastecimento conectada à bomba. Cada bico está vinculado a um tanque específico.

| Campo | Tipo | Obrigatório | Descrição |
|-------|------|-------------|-----------|
| id | UUID | Sim | Identificador único |
| bombaId | UUID | Sim | FK para Bomba |
| tanqueId | UUID | Sim | FK para Tanque |
| numero | Int | Sim | Número sequencial único no posto (1, 2, 3...) |
| numeroLogico | Int | Sim | Número do bico na bomba (pode repetir: 1, 2, 3...) |
| encerrante | Float | Sim | Valor do encerrante/totalizador (litros) |

**Diferença entre `numero` e `numeroLogico`:**
- `numero`: Identificação única do bico no posto inteiro (ex: bico 1, 2, 3, 4, 5...)
- `numeroLogico`: Posição do bico na bomba (ex: bomba 1 tem bicos lógicos 1 e 2)

**Relações:**
- Pertence a uma `Bomba` (N:1)
- Pertence a um `Tanque` (N:1)
- Possui vários `Abastecimentos` (1:N)

**Constraint:** NumeroLogico único por bomba (`bombaId` + `numeroLogico`)

---

### 4. Tanque

Reservatório subterrâneo que armazena o combustível.

| Campo | Tipo | Obrigatório | Descrição |
|-------|------|-------------|-----------|
| id | UUID | Sim | Identificador único |
| empresaId | UUID | Sim | FK para Empresa |
| numero | Int | Sim | Número do tanque (único por empresa) |
| capacidade | Float | Sim | Capacidade total em litros |
| combustivelId | UUID | Sim | FK para Produto (tipo de combustível) |
| nivelAtual | Float | Não | Nível atual em litros |

**Relações:**
- Pertence a uma `Empresa` (N:1)
- Armazena um tipo de `Produto/Combustível` (N:1)
- Alimenta vários `Bicos` (1:N)

**Constraint:** Número único por empresa (`empresaId` + `numero`)

---

### 5. Lacre

Registro histórico dos lacres fiscais instalados nas bombas. Obrigatório para fiscalização.

| Campo | Tipo | Obrigatório | Descrição |
|-------|------|-------------|-----------|
| id | UUID | Sim | Identificador único |
| bombaId | UUID | Sim | FK para Bomba |
| lacre | String | Sim | Código/número do lacre fiscal |
| data | DateTime | Sim | Data de instalação do lacre |
| ativo | Boolean | Sim | Se é o lacre atual (default: true) |

**Relações:**
- Pertence a uma `Bomba` (N:1)

**Observação:** Uma bomba pode ter múltiplos lacres ao longo do tempo, mas apenas um deve estar `ativo = true`.

---

## Diagrama de Entidades

```
┌─────────────────┐       ┌─────────────────┐
│    EMPRESA      │       │   PRODUTO       │
│                 │       │  (Combustível)  │
└────────┬────────┘       └────────┬────────┘
         │                         │
         │ 1:N                     │ 1:N
         ▼                         │
┌─────────────────┐                │
│  CONCENTRADOR   │                │
│                 │                │
│ - modelo        │                │
│ - tipoConexao   │                │
│ - ip/porta      │                │
└────────┬────────┘                │
         │                         │
         │ 1:N                     │
         ▼                         │
┌─────────────────┐       ┌────────┴────────┐
│     BOMBA       │       │     TANQUE      │
│                 │       │                 │
│ - numero        │       │ - numero        │
│ - modelo        │       │ - capacidade    │
│ - fabricante    │       │ - nivelAtual    │
│ - status        │       │                 │
└────────┬────────┘       └────────┬────────┘
         │                         │
         │ 1:N              N:1    │
         ▼                         │
┌─────────────────┐                │
│      BICO       │◄───────────────┘
│                 │
│ - numero        │
│ - numeroLogico  │
│ - encerrante    │
└─────────────────┘
         ▲
         │ N:1
┌────────┴────────┐
│     LACRE       │
│                 │
│ - lacre (código)│
│ - data          │
│ - ativo         │
└─────────────────┘
```

---

## Exemplo de Configuração

### Estrutura do posto (seed de desenvolvimento):

```
CONCENTRADOR (1):
└── Concentrador Principal (WAYNE HELIX 6000)
    IP: 192.168.1.50:5000
    └── Controla todas as 27 bombas

TANQUES (5):
├── Tanque 1 → Gasolina Comum (15.000L)
├── Tanque 2 → Gasolina Aditivada (15.000L)
├── Tanque 3 → Etanol (15.000L)
├── Tanque 4 → Diesel S-10 (20.000L)
└── Tanque 5 → Diesel S-500 (20.000L)

BOMBAS E BICOS (27 bombas, 54 bicos):

Bombas 1-8 (Wayne HELIX 4000) - 16 bicos:
├── Bico lógico 1 → Gasolina Comum (Tanque 1)
└── Bico lógico 2 → Gasolina Aditivada (Tanque 2)
    Bicos: 1-2, 3-4, 5-6, 7-8, 9-10, 11-12, 13-14, 15-16

Bombas 9-14 (Wayne HELIX 4000) - 12 bicos:
├── Bico lógico 1 → Etanol (Tanque 3)
└── Bico lógico 2 → Gasolina Comum (Tanque 1)
    Bicos: 17-18, 19-20, 21-22, 23-24, 25-26, 27-28

Bombas 15-20 (Wayne HELIX 4000) - 12 bicos:
├── Bico lógico 1 → Etanol (Tanque 3)
└── Bico lógico 2 → Gasolina Aditivada (Tanque 2)
    Bicos: 29-30, 31-32, 33-34, 35-36, 37-38, 39-40

Bombas 21-27 (Gilbarco ENCORE 700) - 14 bicos:
├── Bico lógico 1 → Diesel S-10 (Tanque 4)
└── Bico lógico 2 → Diesel S-500 (Tanque 5)
    Bicos: 41-42, 43-44, 45-46, 47-48, 49-50, 51-52, 53-54

LACRES (27 - um por bomba):
├── LAC-2024-001 → Bomba 1 (15/01/2024)
├── LAC-2024-002 → Bomba 2 (15/01/2024)
├── ...
└── LAC-2024-027 → Bomba 27 (15/01/2024)
```

---

## Fluxo de Abastecimento

1. **Seleção da Bomba**: Operador seleciona uma bomba livre no PDV
2. **Liberação**: Sistema envia comando ao concentrador para liberar a bomba
3. **Abastecimento**: Cliente escolhe o bico e abastece
4. **Captura**: Concentrador envia dados (litros, valor) em tempo real
5. **Finalização**: Abastecimento é registrado com:
   - Bico utilizado
   - Tanque (via relação com bico)
   - Litros abastecidos
   - Encerrante inicial/final
   - Valor total

---

## Fabricantes Suportados

| Fabricante | Modelos | Protocolo |
|------------|---------|-----------|
| Wayne | HELIX 4000, HELIX 6000, WAYNE 3G | TCP/IP, Serial |
| Gilbarco | ENCORE 300/500/700, VEEDER-ROOT | TCP/IP, Serial |
| Tokheim | QUANTIUM | TCP/IP |
| Dover | WAYNE | TCP/IP |

---

## Considerações de Implementação

### Encerrante
- Valor totalizador de litros do bico
- Nunca zera (apenas troca de equipamento)
- Usado para auditoria e detecção de fraudes
- Diferença entre encerrante final e inicial = litros abastecidos

### Lacres
- Obrigatórios por lei (INMETRO/ANP)
- Devem ser registrados com data de instalação
- Troca de lacre deve manter histórico

### Múltiplos Tanques por Combustível
- Um tanque armazena apenas um tipo de combustível
- Múltiplos bicos podem puxar do mesmo tanque
- Permite redundância e maior capacidade
