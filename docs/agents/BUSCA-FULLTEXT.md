# Busca Full-Text - Implementação Futura

## Contexto

O sistema possui ~500.000 clientes em produção. A busca atual utiliza `LIKE '%termo%'` (via Prisma `contains`), que funciona bem para buscas simples mas não suporta:

- Busca por múltiplas palavras (ex: "João Silva")
- Busca fonética (ex: "Joao" encontrar "João")
- Ranking por relevância

## Problema

Implementar busca multi-termo com múltiplos `LIKE` em AND degrada severamente a performance:

```sql
-- Consulta problemática (NÃO USAR)
SELECT * FROM clientes
WHERE (nome LIKE '%João%' OR cpf_cnpj LIKE '%João%')
  AND (nome LIKE '%Silva%' OR cpf_cnpj LIKE '%Silva%');
```

Com 500k registros, cada `LIKE '%termo%'` força um **full table scan**.

## Solução: Full-Text Search

### PostgreSQL (Atual)

#### Opção 1: pg_trgm (Trigram)

Ideal para buscas parciais e fuzzy matching.

```sql
-- 1. Habilitar extensão
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- 2. Criar índice GIN
CREATE INDEX idx_clientes_nome_trgm ON clientes USING GIN (nome gin_trgm_ops);
CREATE INDEX idx_clientes_cpf_trgm ON clientes USING GIN (cpf_cnpj gin_trgm_ops);

-- 3. Consulta otimizada
SELECT * FROM clientes
WHERE nome % 'João Silva'  -- similaridade
   OR nome ILIKE '%João Silva%';
```

**Prós:**
- Suporta busca parcial (`%termo%`)
- Fuzzy matching (encontra palavras similares)
- Fácil de implementar

**Contras:**
- Índices maiores
- Menos eficiente que FTS para textos longos

#### Opção 2: Full-Text Search Nativo

Ideal para busca por palavras completas com ranking.

```sql
-- 1. Adicionar coluna tsvector
ALTER TABLE clientes ADD COLUMN search_vector tsvector;

-- 2. Popular coluna
UPDATE clientes SET search_vector =
  to_tsvector('portuguese', coalesce(nome, '') || ' ' || coalesce(cpf_cnpj, ''));

-- 3. Criar índice GIN
CREATE INDEX idx_clientes_search ON clientes USING GIN (search_vector);

-- 4. Trigger para manter atualizado
CREATE TRIGGER clientes_search_update
BEFORE INSERT OR UPDATE ON clientes
FOR EACH ROW EXECUTE FUNCTION
  tsvector_update_trigger(search_vector, 'pg_catalog.portuguese', nome, cpf_cnpj);

-- 5. Consulta otimizada
SELECT *, ts_rank(search_vector, query) as rank
FROM clientes, plainto_tsquery('portuguese', 'João Silva') query
WHERE search_vector @@ query
ORDER BY rank DESC;
```

**Prós:**
- Muito rápido para grandes volumes
- Ranking por relevância
- Suporte a stemming (português)

**Contras:**
- Não suporta busca parcial nativamente
- Requer manutenção da coluna tsvector

### SQL Server (Futuro)

```sql
-- 1. Criar catálogo Full-Text
CREATE FULLTEXT CATALOG ClientesCatalog;

-- 2. Criar índice Full-Text
CREATE FULLTEXT INDEX ON clientes(nome, cpf_cnpj)
KEY INDEX PK_clientes ON ClientesCatalog;

-- 3. Consulta otimizada
SELECT * FROM clientes
WHERE CONTAINS((nome, cpf_cnpj), '"João" AND "Silva"');

-- Ou busca mais flexível
SELECT * FROM clientes
WHERE FREETEXT((nome, cpf_cnpj), 'João Silva');
```

## Implementação Recomendada

### Fase 1: pg_trgm (Rápida)

1. Criar migration para extensão e índices
2. Ajustar service para usar operador `%` ou `ILIKE` otimizado
3. Testar performance com 500k registros

```typescript
// Exemplo com Prisma Raw Query
const results = await prisma.$queryRaw`
  SELECT * FROM clientes
  WHERE nome % ${searchTerm}
  ORDER BY similarity(nome, ${searchTerm}) DESC
  LIMIT 20
`;
```

### Fase 2: Full-Text Search (Completa)

1. Adicionar coluna `search_vector` nas tabelas
2. Criar triggers de atualização
3. Implementar endpoint de busca dedicado
4. Considerar Elasticsearch para casos mais complexos

## Tabelas Afetadas

| Tabela | Campos de Busca | Prioridade |
|--------|-----------------|------------|
| clientes | nome, cpfCnpj, email, telefone | Alta |
| produtos | nome, codigo, codigoBarras, descricao | Alta |
| veiculos | placa, modelo | Média |

## Métricas de Performance Esperadas

| Método | 500k registros | Tempo esperado |
|--------|----------------|----------------|
| LIKE simples | 1 termo | ~200ms |
| LIKE múltiplo | 2+ termos | ~2-5s (inaceitável) |
| pg_trgm | 2+ termos | ~50-100ms |
| Full-Text Search | 2+ termos | ~20-50ms |

## Referências

- [PostgreSQL pg_trgm](https://www.postgresql.org/docs/current/pgtrgm.html)
- [PostgreSQL Full Text Search](https://www.postgresql.org/docs/current/textsearch.html)
- [SQL Server Full-Text Search](https://docs.microsoft.com/en-us/sql/relational-databases/search/full-text-search)
- [Prisma Raw Queries](https://www.prisma.io/docs/concepts/components/prisma-client/raw-database-access)

## Status

- [ ] Decidir abordagem (pg_trgm vs FTS)
- [ ] Criar migration
- [ ] Implementar no backend
- [ ] Testar performance
- [ ] Deploy em produção

---

*Criado em: 2025-12-04*
*Última atualização: 2025-12-04*
