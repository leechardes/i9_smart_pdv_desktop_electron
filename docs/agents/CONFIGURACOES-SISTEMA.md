# Sistema de Configurações Dinâmicas

Este documento descreve o sistema de configurações dinâmicas do I9 Smart PDV, que permite gerenciar todas as configurações do sistema através do banco de dados, com renderização automática no frontend.

## Visão Geral

O sistema utiliza uma abordagem **metadata-driven**, onde cada configuração possui metadados que definem como ela deve ser renderizada no frontend. Isso elimina a necessidade de alterar código para adicionar novas configurações.

## Arquitetura

### Tabela `configuracoes_sistema`

```prisma
model ConfiguracaoSistema {
  id    String @id @default(uuid())
  chave String @unique                    // Identificador único (ex: pdv.desconto_maximo)
  valor String                            // Valor atual da configuração
  tipo  String @default("string")         // Tipo de dado: string, number, boolean, json

  // Metadados para renderização dinâmica
  titulo      String?                     // Label amigável exibido no frontend
  descricao   String?                     // Descrição curta da configuração
  help        String?                     // Tooltip/ajuda adicional
  placeholder String?                     // Placeholder do input
  ordem       Int     @default(0)         // Ordenação dentro do grupo

  // Tipo de input para renderização
  inputType String @default("text")       // text, number, checkbox, select, textarea

  // Para inputs do tipo select
  opcoes Json?                            // Array de {value, label}

  // Informações do grupo
  grupo       String?                     // Identificador do grupo (pdv, impressao, etc)
  grupoTitulo String?                     // Título do grupo para exibição
  grupoIcone  String?                     // Nome do ícone Lucide para o grupo
  grupoOrdem  Int     @default(0)         // Ordenação dos grupos

  criadoEm     DateTime @default(now())
  atualizadoEm DateTime @updatedAt
}
```

### Campos Importantes

| Campo | Descrição | Exemplo |
|-------|-----------|---------|
| `chave` | Identificador único, formato: `grupo.nome` | `pdv.desconto_maximo` |
| `valor` | Valor armazenado como string | `"10"`, `"true"`, `"homologacao"` |
| `tipo` | Tipo de dado para conversão | `string`, `number`, `boolean`, `json` |
| `titulo` | Label exibido no frontend | `"Desconto Máximo (%)"` |
| `inputType` | Tipo de input HTML | `text`, `number`, `checkbox`, `select`, `textarea` |
| `opcoes` | Opções para select | `[{value: "15", label: "15 minutos"}]` |
| `grupoIcone` | Nome do ícone Lucide | `Monitor`, `Printer`, `Bell`, `Shield` |

## Grupos de Configuração

Os grupos organizam as configurações em seções no frontend:

| Grupo | Título | Ícone | Descrição |
|-------|--------|-------|-----------|
| `pdv` | Configurações do PDV | Monitor | Vendas, descontos, timeout |
| `impressao` | Configurações de Impressão | Printer | Cupom, logo, rodapé |
| `notificacoes` | Notificações | Bell | Alertas do sistema |
| `seguranca` | Segurança | Shield | Senhas, sessão |
| `fiscal` | Configurações Fiscais | FileText | NFC-e, ambiente |
| `descontos` | Descontos Automáticos | Percent | Descontos por forma de pagamento |
| `sistema` | Sistema | Settings | Configurações gerais |
| `tef` | TEF (Transferência Eletrônica) | CreditCard | Integração TEF para pagamentos |

## API Endpoints

### Listar Configurações Agrupadas
```http
GET /api/v1/configuracao/sistema?agrupado=true
Authorization: Bearer {token}
```

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "grupo": "pdv",
      "grupoTitulo": "Configurações do PDV",
      "grupoIcone": "Monitor",
      "grupoOrdem": 1,
      "configs": [
        {
          "id": "...",
          "chave": "pdv.confirmar_cancelamento",
          "valor": "true",
          "tipo": "boolean",
          "titulo": "Confirmar Cancelamento",
          "descricao": "Exigir confirmação antes de cancelar uma venda",
          "inputType": "checkbox",
          "ordem": 1,
          ...
        }
      ]
    }
  ]
}
```

### Criar Nova Configuração
```http
POST /api/v1/configuracao/sistema
Authorization: Bearer {token}
Content-Type: application/json

{
  "chave": "pdv.nova_config",
  "valor": "true",
  "tipo": "boolean",
  "titulo": "Nova Configuração",
  "descricao": "Descrição da configuração",
  "help": "Texto de ajuda adicional",
  "inputType": "checkbox",
  "grupo": "pdv",
  "grupoTitulo": "Configurações do PDV",
  "grupoIcone": "Monitor"
}
```

### Atualizar Configuração
```http
PUT /api/v1/configuracao/sistema/{chave}
Authorization: Bearer {token}
Content-Type: application/json

{
  "valor": "false"
}
```

### Atualizar em Lote
```http
PUT /api/v1/configuracao/sistema/batch
Authorization: Bearer {token}
Content-Type: application/json

{
  "configs": [
    { "chave": "pdv.confirmar_cancelamento", "valor": "false" },
    { "chave": "pdv.desconto_maximo", "valor": "15" }
  ]
}
```

### Remover Configuração
```http
DELETE /api/v1/configuracao/sistema/{chave}
Authorization: Bearer {token}
```

## Como Adicionar Nova Configuração

### Via Seed (Recomendado para configurações padrão)

Adicione ao arquivo `backend/src/prisma/seed.ts`:

```typescript
{
  chave: 'pdv.nova_funcionalidade',
  valor: 'true',
  tipo: 'boolean',
  titulo: 'Habilitar Nova Funcionalidade',
  descricao: 'Ativa a nova funcionalidade no PDV',
  help: 'Esta funcionalidade permite...',
  ordem: 10,
  inputType: 'checkbox',
  grupo: 'pdv',
  grupoTitulo: 'Configurações do PDV',
  grupoIcone: 'Monitor',
  grupoOrdem: 1,
}
```

### Via Interface (Para configurações dinâmicas)

1. Acesse **Admin > Configurações**
2. Clique em **Nova Configuração** (apenas SUPER_ADMIN)
3. Preencha os campos:
   - **Chave**: Identificador único (ex: `pdv.nova_config`)
   - **Título**: Label exibido no frontend
   - **Tipo de Dado**: string, number, boolean ou json
   - **Tipo de Input**: text, number, checkbox, select ou textarea
   - **Grupo**: Identificador do grupo existente ou novo
   - **Título do Grupo**: Nome exibido no menu lateral
   - **Ícone do Grupo**: Ícone Lucide para o grupo

### Via API

```typescript
await configuracaoSistemaService.criar({
  chave: 'pdv.nova_config',
  valor: 'valor_padrao',
  tipo: 'string',
  titulo: 'Nova Configuração',
  descricao: 'Descrição da configuração',
  inputType: 'text',
  grupo: 'pdv',
  grupoTitulo: 'Configurações do PDV',
  grupoIcone: 'Monitor',
});
```

## Tipos de Input

### checkbox
Para valores booleanos (true/false).
```typescript
{
  inputType: 'checkbox',
  tipo: 'boolean',
  valor: 'true'
}
```

### number
Para valores numéricos.
```typescript
{
  inputType: 'number',
  tipo: 'number',
  valor: '10',
  placeholder: 'Ex: 10'
}
```

### text
Para strings simples.
```typescript
{
  inputType: 'text',
  tipo: 'string',
  valor: 'Valor padrão',
  placeholder: 'Digite aqui...'
}
```

### textarea
Para textos longos.
```typescript
{
  inputType: 'textarea',
  tipo: 'string',
  valor: 'Texto longo...'
}
```

### select
Para seleção de opções predefinidas.
```typescript
{
  inputType: 'select',
  tipo: 'string',
  valor: '30',
  opcoes: [
    { value: '15', label: '15 minutos' },
    { value: '30', label: '30 minutos' },
    { value: '60', label: '1 hora' },
    { value: '0', label: 'Nunca' }
  ]
}
```

## Ícones Disponíveis

Os ícones são do pacote Lucide React. Ícones pré-configurados no sistema:

- `Monitor` - PDV/Terminal
- `Printer` - Impressão
- `Bell` - Notificações
- `Shield` - Segurança
- `FileText` - Fiscal/Documentos
- `Percent` - Descontos
- `Settings` - Configurações gerais
- `CreditCard` - Pagamentos
- `Truck` - Entrega/Logística
- `Package` - Estoque/Produtos
- `Users` - Usuários
- `Building2` - Empresas
- `Zap` - Integrações
- `Database` - Banco de dados

## Leitura de Configurações no Código

### Backend (TypeScript/Node.js)

```typescript
import { configuracaoSistemaService } from './services/configuracao-sistema.service';

// Buscar valor com tipo convertido
const descontoMaximo = await configuracaoSistemaService.getValor<number>('pdv.desconto_maximo', 10);
const confirmarCancelamento = await configuracaoSistemaService.getValor<boolean>('pdv.confirmar_cancelamento', true);

// Buscar configuração completa
const config = await configuracaoSistemaService.buscarPorChave('pdv.desconto_maximo');
```

### Frontend (React/Next.js)

```typescript
import { configuracaoSistemaService } from '@/services/api';

// Buscar todas as configurações agrupadas
const { data } = await configuracaoSistemaService.listarAgrupadas();

// Buscar configuração específica
const { data: config } = await configuracaoSistemaService.buscar('pdv.desconto_maximo');

// Atualizar configuração
await configuracaoSistemaService.atualizar('pdv.desconto_maximo', { valor: '15' });
```

## Boas Práticas

1. **Nomenclatura de Chave**: Use o padrão `grupo.nome_descritivo` (ex: `pdv.desconto_maximo`)
2. **Valores Padrão**: Sempre defina um valor padrão sensato no seed
3. **Descrições Claras**: Escreva descrições que ajudem o usuário a entender a configuração
4. **Help para Campos Complexos**: Use o campo `help` para explicações detalhadas
5. **Ordenação**: Use o campo `ordem` para organizar logicamente as configurações
6. **Grupos Coerentes**: Agrupe configurações relacionadas no mesmo grupo

## Permissões

- **Visualização**: Todos os usuários autenticados podem visualizar configurações
- **Edição**: Apenas `SUPER_ADMIN` pode criar, editar ou remover configurações
- **API**: Todas as rotas de escrita (POST, PUT, DELETE) verificam o perfil `SUPER_ADMIN`

## Arquivos Relacionados

- **Schema**: [backend/src/prisma/schema.prisma](../backend/src/prisma/schema.prisma)
- **Seed**: [backend/src/prisma/seed.ts](../backend/src/prisma/seed.ts)
- **Service Backend**: [backend/src/services/configuracao-sistema.service.ts](../backend/src/services/configuracao-sistema.service.ts)
- **Controller**: [backend/src/controllers/configuracao-sistema.controller.ts](../backend/src/controllers/configuracao-sistema.controller.ts)
- **Rotas**: [backend/src/routes/v1/configuracao.routes.ts](../backend/src/routes/v1/configuracao.routes.ts)
- **API Frontend**: [frontend/src/services/api.ts](../frontend/src/services/api.ts)
- **Página**: [frontend/src/app/admin/configuracoes/page.tsx](../frontend/src/app/admin/configuracoes/page.tsx)
