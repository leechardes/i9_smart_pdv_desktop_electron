# I9 Smart PDV Web - Estrutura Multi-Empresa

Documentação da arquitetura de grupos, empresas, estações e permissões.

---

## 1. Hierarquia Organizacional

```
┌─────────────────────────────────────────────────────────────────┐
│                      GRUPO DE EMPRESAS                           │
│                   (Rede / Holding / Franquia)                    │
│                                                                  │
│   Exemplo: "Rede Combustíveis Nordeste"                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   ┌───────────────┐   ┌───────────────┐   ┌───────────────┐     │
│   │   EMPRESA     │   │   EMPRESA     │   │   EMPRESA     │     │
│   │   (MATRIZ)    │   │   (FILIAL)    │   │   (FILIAL)    │     │
│   │               │◄──│   vinculada   │   │   vinculada   │     │
│   │ CNPJ próprio  │   │ CNPJ próprio  │   │ CNPJ próprio  │     │
│   └───────────────┘   └───────────────┘   └───────────────┘     │
│          │                   │                   │               │
│          ▼                   ▼                   ▼               │
│   ┌───────────────┐   ┌───────────────┐   ┌───────────────┐     │
│   │  ESTAÇÕES     │   │  ESTAÇÕES     │   │  ESTAÇÕES     │     │
│   │  (Hardware)   │   │  (Hardware)   │   │  (Hardware)   │     │
│   │               │   │               │   │               │     │
│   │ - PDV-01      │   │ - PDV-01      │   │ - PDV-01      │     │
│   │ - PDV-02      │   │               │   │ - PDV-02      │     │
│   │ - Totem       │   │               │   │               │     │
│   └───────────────┘   └───────────────┘   └───────────────┘     │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘

                              │
                              ▼

┌─────────────────────────────────────────────────────────────────┐
│                         USUÁRIOS                                 │
│                                                                  │
│   Podem trabalhar em QUALQUER estação (conforme permissão)       │
│                                                                  │
│   ┌─────────────┐  ┌─────────────┐  ┌─────────────┐             │
│   │  GERENTE    │  │  OPERADOR   │  │  FRENTISTA  │             │
│   │  (Geral)    │  │  (Caixa)    │  │  (Pista)    │             │
│   └─────────────┘  └─────────────┘  └─────────────┘             │
│         │                │                │                      │
│         ▼                ▼                ▼                      │
│   ┌─────────────────────────────────────────────────────────┐   │
│   │                    CAIXA (Financeiro)                    │   │
│   │         Controle de movimentação por usuário             │   │
│   └─────────────────────────────────────────────────────────┘   │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 2. Entidades

### 2.1 Grupo de Empresas

Representa uma rede, holding ou franquia que agrupa várias empresas.

| Campo | Tipo | Descrição |
|-------|------|-----------|
| id | UUID | Identificador único |
| nome | String | Nome do grupo (ex: "Rede Combustíveis Nordeste") |
| slug | String | Identificador URL-friendly |
| logoUrl | String? | URL do logotipo |
| ativo | Boolean | Se o grupo está ativo |
| criadoEm | DateTime | Data de criação |
| atualizadoEm | DateTime | Última atualização |

---

### 2.2 Empresa

Representa um posto individual com CNPJ próprio.

| Campo | Tipo | Descrição |
|-------|------|-----------|
| id | UUID | Identificador único |
| grupoEmpresaId | FK | Grupo ao qual pertence |
| **tipoUnidade** | ENUM | `MATRIZ` ou `FILIAL` |
| **matrizId** | FK? | Se filial, aponta para a matriz |
| cnpj | String | CNPJ único |
| razaoSocial | String | Razão social |
| nomeFantasia | String | Nome fantasia |
| inscricaoEstadual | String? | IE |
| endereco | String | Endereço completo |
| numero | String | Número |
| complemento | String? | Complemento |
| bairro | String | Bairro |
| cidade | String | Cidade |
| estado | String(2) | UF |
| cep | String | CEP |
| telefone | String? | Telefone |
| email | String? | Email |
| regimeTributario | String? | Simples, Lucro Presumido, etc |
| configFiscal | JSON? | Configurações SAT/NFC-e |
| configPix | JSON? | Configurações PIX |
| ativo | Boolean | Se está ativo |
| criadoEm | DateTime | Data de criação |
| atualizadoEm | DateTime | Última atualização |

**Relacionamentos:**
- `grupoEmpresa` → GrupoEmpresa (N:1)
- `matriz` → Empresa (N:1, auto-relacionamento)
- `filiais` → Empresa[] (1:N, auto-relacionamento)
- `estacoes` → Estacao[] (1:N)
- `usuarios` → Usuario[] (1:N)

---

### 2.3 Estação

Representa um terminal físico (computador/hardware) com seus periféricos.

| Campo | Tipo | Descrição |
|-------|------|-----------|
| id | UUID | Identificador único |
| empresaId | FK | Empresa onde está instalada |
| nome | String | Nome da estação (ex: "PDV-01") |
| identificador | String | ID único do hardware/máquina |
| descricao | String? | Descrição adicional |
| **Impressora** | | |
| impressoraIp | String? | IP da impressora térmica |
| impressoraPorta | Int? | Porta (padrão: 9100) |
| impressoraModelo | String? | Modelo (Epson, Elgin, etc) |
| **Terminal TEF** | | |
| tefHabilitado | Boolean | Se tem TEF |
| tefOperadora | ENUM? | CIELO, STONE, REDE, GETNET |
| tefConfig | JSON? | Configurações específicas do TEF |
| **Leitor de Código** | | |
| leitorHabilitado | Boolean | Se tem leitor |
| leitorTipo | String? | USB, Serial, etc |
| **Display Cliente** | | |
| displayIp | String? | IP do display |
| displayPorta | Int? | Porta |
| **SAT/NFC-e** | | |
| satHabilitado | Boolean | Se tem SAT |
| satModelo | String? | Modelo do SAT |
| satCodigo | String? | Código de ativação |
| **Controle** | | |
| ativo | Boolean | Se está em uso |
| ultimoAcesso | DateTime? | Último acesso |
| criadoEm | DateTime | Data de criação |
| atualizadoEm | DateTime | Última atualização |

**Relacionamentos:**
- `empresa` → Empresa (N:1)
- `caixas` → Caixa[] (1:N)
- `vendas` → Venda[] (1:N)

---

### 2.4 Usuário

Representa uma pessoa física que opera o sistema.

| Campo | Tipo | Descrição |
|-------|------|-----------|
| id | UUID | Identificador único |
| **Vínculo Organizacional** | | |
| grupoEmpresaId | FK? | Grupo (para ADMIN_GRUPO, GERENTE_GERAL) |
| empresaId | FK? | Empresa (para GERENTE_UNIDADE, OPERADOR, FRENTISTA) |
| **Dados Pessoais** | | |
| nome | String | Nome completo |
| email | String | Email único |
| cpf | String | CPF único |
| telefone | String? | Telefone |
| **Autenticação** | | |
| senha | String | Hash bcrypt |
| pin | String? | PIN de acesso rápido (4-6 dígitos) |
| **Perfil e Permissões** | | |
| perfil | ENUM | Perfil único (ver tabela abaixo) |
| **Controle** | | |
| ativo | Boolean | Se está ativo |
| ultimoAcesso | DateTime? | Último login |
| criadoEm | DateTime | Data de criação |
| atualizadoEm | DateTime | Última atualização |

**Relacionamentos:**
- `grupoEmpresa` → GrupoEmpresa (N:1, opcional)
- `empresa` → Empresa (N:1, opcional)
- `caixas` → Caixa[] (1:N)
- `vendasOperador` → Venda[] (1:N)
- `vendasFrentista` → Venda[] (1:N)
- `abastecimentos` → Abastecimento[] (1:N)

---

### 2.5 Caixa (Controle Financeiro)

Representa o controle financeiro de um turno de trabalho do usuário.

| Campo | Tipo | Descrição |
|-------|------|-----------|
| id | UUID | Identificador único |
| **Vínculos** | | |
| usuarioId | FK | Usuário dono do caixa |
| empresaId | FK | Empresa do movimento |
| estacaoId | FK | Estação onde foi aberto |
| **Valores** | | |
| valorAbertura | Decimal | Valor inicial informado |
| valorFechamento | Decimal? | Valor final informado |
| valorEsperado | Decimal? | Calculado pelo sistema |
| diferenca | Decimal? | Diferença (sobra/falta) |
| **Status** | | |
| status | ENUM | ABERTO, FECHADO |
| abertoEm | DateTime | Data/hora abertura |
| fechadoEm | DateTime? | Data/hora fechamento |
| observacoes | String? | Observações do fechamento |
| criadoEm | DateTime | Data de criação |
| atualizadoEm | DateTime | Última atualização |

**Relacionamentos:**
- `usuario` → Usuario (N:1)
- `empresa` → Empresa (N:1)
- `estacao` → Estacao (N:1)
- `vendas` → Venda[] (1:N)
- `movimentos` → MovimentoCaixa[] (1:N)

---

## 3. Perfis e Permissões

### 3.1 Enum de Perfis

```typescript
enum Perfil {
  SUPER_ADMIN      // Acesso total ao sistema
  ADMIN_GRUPO      // Administrador do grupo de empresas
  GERENTE_GERAL    // Gerente de todas empresas do grupo
  GERENTE_UNIDADE  // Gerente de uma empresa específica
  OPERADOR         // Operador de caixa
  FRENTISTA        // Frentista (apenas pista)
}
```

### 3.2 Matriz de Permissões

| Perfil | Escopo | Vê | Pode Fazer |
|--------|--------|-----|------------|
| **SUPER_ADMIN** | Sistema | Todos os grupos e empresas | Tudo |
| **ADMIN_GRUPO** | Grupo | Todas empresas do grupo | Configurar grupo, empresas, usuários |
| **GERENTE_GERAL** | Grupo | Todas empresas do grupo | Relatórios, dashboard, supervisão |
| **GERENTE_UNIDADE** | Empresa | Tudo da sua empresa | Relatórios, estorno, supervisão |
| **OPERADOR** | Próprio | Apenas suas vendas/caixa | Vendas, abertura/fechamento caixa |
| **FRENTISTA** | Próprio | Apenas seus abastecimentos | Registrar abastecimentos |

### 3.3 Regras de Vínculo

| Perfil | grupoEmpresaId | empresaId |
|--------|----------------|-----------|
| SUPER_ADMIN | NULL | NULL |
| ADMIN_GRUPO | Obrigatório | NULL |
| GERENTE_GERAL | Obrigatório | NULL |
| GERENTE_UNIDADE | NULL | Obrigatório |
| OPERADOR | NULL | Obrigatório |
| FRENTISTA | NULL | Obrigatório |

---

## 4. Fluxos de Operação

### 4.1 Login e Seleção de Contexto

```
┌─────────────────────────────────────────────────────────────┐
│                         LOGIN                                │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
              ┌───────────────────────────────┐
              │      Identificar Perfil       │
              └───────────────────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
        ▼                     ▼                     ▼
┌───────────────┐   ┌───────────────┐   ┌───────────────┐
│ SUPER_ADMIN   │   │ ADMIN_GRUPO   │   │ OPERADOR      │
│ ADMIN_GRUPO   │   │ GERENTE_GERAL │   │ GERENTE_UNID  │
│ GERENTE_GERAL │   │               │   │ FRENTISTA     │
└───────────────┘   └───────────────┘   └───────────────┘
        │                     │                     │
        ▼                     ▼                     ▼
┌───────────────┐   ┌───────────────┐   ┌───────────────┐
│ Selecionar    │   │ Selecionar    │   │ Empresa já    │
│ Grupo         │   │ Empresa       │   │ definida      │
└───────────────┘   └───────────────┘   └───────────────┘
        │                     │                     │
        ▼                     │                     │
┌───────────────┐             │                     │
│ Selecionar    │◄────────────┘                     │
│ Empresa       │                                   │
└───────────────┘                                   │
        │                                           │
        └─────────────────────┬─────────────────────┘
                              │
                              ▼
              ┌───────────────────────────────┐
              │      Selecionar Estação       │
              │   (lista estações da empresa) │
              └───────────────────────────────┘
                              │
                              ▼
              ┌───────────────────────────────┐
              │    Verificar Caixa Aberto     │
              └───────────────────────────────┘
                              │
            ┌─────────────────┴─────────────────┐
            │                                   │
            ▼                                   ▼
    ┌───────────────┐                   ┌───────────────┐
    │ Caixa Aberto  │                   │ Sem Caixa     │
    │ → Continuar   │                   │ → Abrir Caixa │
    └───────────────┘                   └───────────────┘
            │                                   │
            └─────────────────┬─────────────────┘
                              │
                              ▼
              ┌───────────────────────────────┐
              │        PDV LIBERADO           │
              └───────────────────────────────┘
```

### 4.2 Troca de Estação

Um usuário pode trocar de estação durante o turno (ex: ir para outro PDV):

```
1. Usuário está em PDV-01
2. Precisa ir para PDV-02
3. [Menu] → Trocar Estação
4. Sistema verifica se há venda em andamento
   - Se sim: "Finalize a venda atual primeiro"
   - Se não: Exibe lista de estações
5. Seleciona PDV-02
6. Sistema atualiza contexto
7. Continua operando no PDV-02
   - Caixa permanece o mesmo (vinculado ao usuário)
```

### 4.3 Abertura de Caixa

```
1. Usuário faz login
2. Seleciona empresa (se necessário)
3. Seleciona estação
4. Sistema verifica: "Usuário tem caixa aberto hoje?"
   - Sim: Usa o caixa existente
   - Não: Solicita abertura
5. Usuário conta dinheiro em mãos
6. Informa valor de abertura
7. Sistema cria registro de caixa:
   - usuarioId: usuário logado
   - empresaId: empresa selecionada
   - estacaoId: estação selecionada
   - valorAbertura: valor informado
   - status: ABERTO
   - abertoEm: agora
8. Caixa aberto, PDV liberado
```

### 4.4 Fechamento de Caixa

```
1. Usuário solicita fechamento [Ctrl+F]
2. Sistema calcula valor esperado:
   valorEsperado = valorAbertura
                 + vendasDinheiro
                 + suprimentos
                 - sangrias
3. Exibe resumo de movimentações
4. Usuário conta dinheiro em mãos
5. Informa valor de fechamento
6. Sistema calcula diferença:
   diferenca = valorFechamento - valorEsperado
7. Se diferença != 0:
   - Solicita observação obrigatória
8. Registra fechamento:
   - valorFechamento: valor informado
   - valorEsperado: calculado
   - diferenca: calculada
   - status: FECHADO
   - fechadoEm: agora
9. Gera relatório de fechamento
10. Caixa fechado
```

---

## 5. Exemplos Práticos

### 5.1 Estrutura de uma Rede

```
Grupo: "Rede Combustíveis Nordeste" (id: grupo-001)
│
├── Empresa: "Posto Central" (MATRIZ, id: emp-001)
│   │   CNPJ: 12.345.678/0001-00
│   │   Cidade: Recife/PE
│   │
│   ├── Estação: "PDV-01" (id: est-001)
│   │   └── Impressora: 192.168.1.10:9100
│   │   └── TEF: Cielo
│   │   └── SAT: Ativo
│   │
│   ├── Estação: "PDV-02" (id: est-002)
│   │   └── Impressora: 192.168.1.11:9100
│   │   └── TEF: Stone
│   │   └── SAT: Ativo
│   │
│   └── Estação: "Totem" (id: est-003)
│       └── Impressora: 192.168.1.12:9100
│       └── TEF: Não
│       └── SAT: Não (pré-venda)
│
├── Empresa: "Posto Praia" (FILIAL → emp-001, id: emp-002)
│   │   CNPJ: 12.345.678/0002-00
│   │   Cidade: Olinda/PE
│   │
│   └── Estação: "PDV-01" (id: est-004)
│       └── Impressora: 192.168.2.10:9100
│       └── TEF: Cielo
│       └── SAT: Ativo
│
└── Empresa: "Posto Centro" (FILIAL → emp-001, id: emp-003)
    │   CNPJ: 12.345.678/0003-00
    │   Cidade: Recife/PE
    │
    ├── Estação: "PDV-01" (id: est-005)
    │   └── Impressora: 192.168.3.10:9100
    │   └── TEF: Rede
    │   └── SAT: Ativo
    │
    └── Estação: "PDV-02" (id: est-006)
        └── Impressora: 192.168.3.11:9100
        └── TEF: Rede
        └── SAT: Ativo
```

### 5.2 Usuários e Acessos

```
Usuários:
│
├── João Silva (SUPER_ADMIN)
│   └── Acesso: Todo o sistema
│
├── Maria Santos (ADMIN_GRUPO, grupo: grupo-001)
│   └── Acesso: Todas empresas do grupo "Rede Combustíveis Nordeste"
│
├── Carlos Souza (GERENTE_GERAL, grupo: grupo-001)
│   └── Acesso: Visualiza todas empresas do grupo
│   └── Pode: Relatórios consolidados, supervisão
│
├── Ana Lima (GERENTE_UNIDADE, empresa: emp-001)
│   └── Acesso: Apenas "Posto Central"
│   └── Pode: Tudo na sua unidade
│
├── Pedro Costa (OPERADOR, empresa: emp-001)
│   └── Acesso: Apenas "Posto Central"
│   └── Pode: Vendas, seu caixa
│   └── Vê: Apenas suas próprias vendas
│
└── José Pereira (FRENTISTA, empresa: emp-002)
    └── Acesso: Apenas "Posto Praia"
    └── Pode: Registrar abastecimentos
    └── Vê: Apenas seus abastecimentos
```

### 5.3 Cenário de Uso

```
Dia 03/12/2024 - Posto Central

08:00 - Pedro (OPERADOR) faz login
        → Empresa já definida: Posto Central
        → Seleciona estação: PDV-01
        → Abre caixa com R$ 200,00

09:30 - Precisa ir ao PDV-02 (outro operador precisa do PDV-01)
        → Menu → Trocar Estação
        → Seleciona PDV-02
        → Continua com mesmo caixa

12:00 - Ana (GERENTE) faz login
        → Empresa já definida: Posto Central
        → Não precisa de estação (não opera PDV)
        → Acessa relatórios, dashboard

14:00 - Carlos (GERENTE_GERAL) faz login
        → Seleciona empresa: Posto Central
        → Vê dashboard consolidado do grupo
        → Pode trocar para ver Posto Praia ou Posto Centro

18:00 - Pedro fecha o caixa
        → Valor esperado: R$ 1.850,00
        → Valor em mãos: R$ 1.845,00
        → Diferença: -R$ 5,00
        → Observação: "Diferença de troco"
        → Caixa fechado
```

---

## 6. Considerações Técnicas

### 6.1 Middleware de Contexto

```typescript
// Toda requisição autenticada terá:
interface RequestContext {
  usuario: Usuario;
  grupoEmpresa?: GrupoEmpresa;  // Se selecionado
  empresa?: Empresa;            // Se selecionada
  estacao?: Estacao;            // Se selecionada
  caixa?: Caixa;                // Se aberto
}
```

### 6.2 Filtros Automáticos

```typescript
// Queries são automaticamente filtradas pelo contexto
const vendas = await prisma.venda.findMany({
  where: {
    // Filtro automático baseado no perfil
    ...(ctx.perfil === 'OPERADOR' && { operadorId: ctx.usuario.id }),
    ...(ctx.perfil === 'GERENTE_UNIDADE' && { empresaId: ctx.empresa.id }),
    ...(ctx.perfil === 'GERENTE_GERAL' && { empresa: { grupoEmpresaId: ctx.grupoEmpresa.id } }),
  }
});
```

### 6.3 Validações

```typescript
// Antes de criar venda
if (!ctx.caixa || ctx.caixa.status !== 'ABERTO') {
  throw new Error('Caixa deve estar aberto para realizar vendas');
}

// Antes de fechar caixa
if (await temVendaEmAndamento(ctx.caixa.id)) {
  throw new Error('Finalize todas as vendas antes de fechar o caixa');
}
```

---

## 7. Migrations Necessárias

### Ordem de criação das tabelas:

1. `grupos_empresa`
2. `empresas` (com auto-relacionamento matriz/filial)
3. `estacoes`
4. `usuarios` (com vínculo a grupo ou empresa)
5. Atualizar `caixas` (adicionar estacaoId)
6. Atualizar `vendas` (adicionar estacaoId)

---

*Documento criado em: Dezembro/2024*
*Última atualização: Dezembro/2024*
