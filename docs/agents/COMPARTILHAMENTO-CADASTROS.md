# Compartilhamento de Cadastros

## Visão Geral

O sistema suporta três níveis de compartilhamento para cadastros:

| Escopo | empresaId | grupoEmpresaId | Comportamento |
|--------|-----------|----------------|---------------|
| **GLOBAL** | `null` | `null` | Mesmo registro para todo o sistema |
| **GRUPO** | `null` | `uuid` | Compartilhado entre empresas do grupo |
| **EMPRESA** | `uuid` | - | Exclusivo da empresa |

## Tabela de Configuração

A tabela `configuracao_compartilhamento` define o escopo de cada entidade:

```sql
SELECT * FROM configuracao_compartilhamento;

-- Resultado exemplo:
-- | entidade          | escopo  |
-- |-------------------|---------|
-- | CLIENTE           | GLOBAL  |
-- | PRODUTO           | GRUPO   |
-- | CATEGORIA_PRODUTO | GRUPO   |
-- | VEICULO           | GLOBAL  | (segue cliente)
```

## Entidades Afetadas

### Cliente
- **Escopo atual**: GLOBAL
- **Comportamento**: Mesmo cliente pode comprar em qualquer empresa
- **Limite de crédito**: No próprio cadastro (evolução futura: por empresa)

### Produto
- **Escopo configurável**: GLOBAL, GRUPO ou EMPRESA
- **Código único**: Dentro do escopo configurado
- **Preço**: Pode variar por empresa (tabela `ProdutoPreco` futura)

### Categoria de Produto
- **Escopo configurável**: GLOBAL, GRUPO ou EMPRESA
- **Segue**: Geralmente mesmo escopo do Produto

### Veículo
- **Escopo**: Segue o Cliente (GLOBAL)
- **Vinculado ao**: clienteId

## Fluxo de Criação

### Escopo GLOBAL
```
Criar Produto → empresaId = null, grupoEmpresaId = null
Visível para: Todas as empresas do sistema
```

### Escopo GRUPO
```
Criar Produto → empresaId = null, grupoEmpresaId = <grupo do usuário>
Visível para: Todas as empresas do grupo
```

### Escopo EMPRESA
```
Criar Produto → empresaId = <empresa do usuário>, grupoEmpresaId = null
Visível para: Apenas a empresa específica
```

## Fluxo de Consulta

```typescript
// Pseudocódigo do filtro
function buildWhereClause(entidade: string, user: UserContext) {
  const config = await getConfiguracaoCompartilhamento(entidade);

  switch (config.escopo) {
    case 'GLOBAL':
      // Sem filtro de empresa/grupo
      return { empresaId: null, grupoEmpresaId: null };

    case 'GRUPO':
      // Registros do grupo OU globais
      return {
        OR: [
          { grupoEmpresaId: user.grupoEmpresaId },
          { empresaId: null, grupoEmpresaId: null }
        ]
      };

    case 'EMPRESA':
      // Registros da empresa OU do grupo OU globais
      return {
        OR: [
          { empresaId: user.empresaId },
          { grupoEmpresaId: user.grupoEmpresaId, empresaId: null },
          { empresaId: null, grupoEmpresaId: null }
        ]
      };
  }
}
```

## Validação de Unicidade

### Código de Produto

| Escopo | Regra de Unicidade |
|--------|-------------------|
| GLOBAL | Código único no sistema |
| GRUPO | Código único no grupo |
| EMPRESA | Código único na empresa |

```sql
-- Constraint condicional (implementada via service)
-- GLOBAL: codigo único onde empresaId IS NULL AND grupoEmpresaId IS NULL
-- GRUPO: codigo único por grupoEmpresaId
-- EMPRESA: codigo único por empresaId
```

## Permissões

| Perfil | GLOBAL | GRUPO | EMPRESA |
|--------|--------|-------|---------|
| SUPER_ADMIN | CRUD | CRUD | CRUD |
| ADMIN_GRUPO | Leitura | CRUD | CRUD |
| GERENTE_GERAL | Leitura | CRUD | CRUD |
| GERENTE_UNIDADE | Leitura | Leitura | CRUD |
| OPERADOR | Leitura | Leitura | Leitura |

## Migração de Dados

### De EMPRESA para GRUPO
1. Identificar registros duplicados (mesmo código em empresas do grupo)
2. Mesclar ou renomear duplicados
3. Atualizar: `empresaId = null, grupoEmpresaId = <grupo>`

### De GRUPO para GLOBAL
1. Identificar registros duplicados entre grupos
2. Mesclar ou renomear duplicados
3. Atualizar: `empresaId = null, grupoEmpresaId = null`

## Diagrama

```
┌─────────────────────────────────────────────────────────────────┐
│                         SISTEMA                                  │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │              CADASTROS GLOBAIS                          │    │
│  │  • Clientes (compartilhados)                            │    │
│  │  • Veículos (seguem cliente)                            │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                  │
│  ┌─────────────────────┐    ┌─────────────────────┐             │
│  │   GRUPO "Rede A"    │    │   GRUPO "Rede B"    │             │
│  │  ┌───────────────┐  │    │  ┌───────────────┐  │             │
│  │  │ Produtos      │  │    │  │ Produtos      │  │             │
│  │  │ Categorias    │  │    │  │ Categorias    │  │             │
│  │  └───────────────┘  │    │  └───────────────┘  │             │
│  │                     │    │                     │             │
│  │  ┌─────┐ ┌─────┐   │    │  ┌─────┐ ┌─────┐   │             │
│  │  │Emp A│ │Emp B│   │    │  │Emp C│ │Emp D│   │             │
│  │  │Preço│ │Preço│   │    │  │Preço│ │Preço│   │             │
│  │  └─────┘ └─────┘   │    │  └─────┘ └─────┘   │             │
│  └─────────────────────┘    └─────────────────────┘             │
└─────────────────────────────────────────────────────────────────┘
```

## Configuração Padrão

| Entidade | Escopo Default | Justificativa |
|----------|----------------|---------------|
| Cliente | GLOBAL | Cliente pode comprar em qualquer posto |
| Veículo | GLOBAL | Segue o cliente |
| Produto | EMPRESA | Cada empresa pode ter produtos diferentes |
| CategoriaProduto | EMPRESA | Segue produto |

## API

### Consultar Configuração
```http
GET /api/v1/configuracao/compartilhamento
Authorization: Bearer <token>

Response:
{
  "data": [
    { "entidade": "CLIENTE", "escopo": "GLOBAL" },
    { "entidade": "PRODUTO", "escopo": "EMPRESA" },
    { "entidade": "CATEGORIA_PRODUTO", "escopo": "EMPRESA" }
  ]
}
```

### Alterar Configuração (SUPER_ADMIN)
```http
PUT /api/v1/configuracao/compartilhamento
Authorization: Bearer <token>
Content-Type: application/json

{
  "entidade": "PRODUTO",
  "escopo": "GRUPO"
}
```

---

*Criado em: 2025-12-04*
