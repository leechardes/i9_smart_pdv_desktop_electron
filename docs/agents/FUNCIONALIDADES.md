# I9 Smart PDV Web - Levantamento de Funcionalidades

Documento de referência baseado na análise do sistema legado (Flutter).
Este documento serve como guia para o novo desenvolvimento - **não copiar padrões antigos**.

---

## 1. Funcionalidades Principais

### Autenticação e Acesso
- [ ] Login com código de vendedor + senha
- [ ] Login rápido com PIN (4-6 dígitos)
- [ ] Controle de sessão e timeout
- [ ] Níveis de acesso (Admin, Gerente, Operador, Frentista)
- [ ] Log de acessos e tentativas

### Gestão de Vendas
- [ ] Criar nova venda
- [ ] Adicionar itens (produtos e combustíveis)
- [ ] Aplicar descontos (% ou R$) com motivo
- [ ] Calcular totais automaticamente
- [ ] Cancelar venda
- [ ] Cancelar item individual
- [ ] Histórico de vendas
- [ ] Reimpressão de cupom
- [ ] Venda offline (sincroniza depois)

### Abastecimentos
- [ ] Seleção de bomba (1-10+)
- [ ] Leitura automática de abastecimento (integração bomba)
- [ ] Registro manual de abastecimento
- [ ] Controle de encerrantes
- [ ] Identificação do frentista
- [ ] Associar abastecimento à venda

### Clientes e Veículos
- [ ] Consulta de cliente por placa
- [ ] Validação de situação do cliente (liberado/bloqueado)
- [ ] Cadastro de clientes (PF/PJ)
- [ ] Cadastro de veículos
- [ ] Registro de hodômetro
- [ ] Clientes de frota
- [ ] Limite de crédito
- [ ] Controle de fiado

### Pagamentos
- [ ] Dinheiro (com cálculo de troco)
- [ ] Cartão de Débito
- [ ] Cartão de Crédito (à vista e parcelado)
- [ ] PIX (QR Code dinâmico)
- [ ] Cartão Frota / Voucher
- [ ] Pagamento misto (múltiplas formas)
- [ ] Fiado / Convênio
- [ ] Assinatura digital

### Produtos e Estoque
- [ ] Catálogo de produtos
- [ ] Categorias de produtos
- [ ] Combustíveis (tipo especial)
- [ ] Produtos de loja/conveniência
- [ ] Controle de estoque
- [ ] Consulta de preços
- [ ] Código de barras

### Caixa
- [ ] Abertura de caixa (valor inicial)
- [ ] Fechamento de caixa
- [ ] Sangria (retirada)
- [ ] Suprimento (entrada)
- [ ] Conferência de valores
- [ ] Diferença de caixa
- [ ] Relatório de movimento

### Relatórios
- [ ] Vendas por período
- [ ] Vendas por operador
- [ ] Vendas por forma de pagamento
- [ ] Abastecimentos por bomba
- [ ] Movimentação de caixa
- [ ] Exportação (PDF/Excel)

### Sincronização
- [ ] Trabalho offline
- [ ] Sincronização automática
- [ ] Sincronização manual
- [ ] Fila de pendências
- [ ] Indicador de status de conexão

### Impressão
- [ ] Cupom de venda
- [ ] Comprovante de pagamento
- [ ] Relatório de caixa
- [ ] Impressora térmica (USB/Bluetooth)

---

## 2. Fluxos de Negócio

### Fluxo Principal: Venda de Combustível

```
┌─────────────────────────────────────────────────────────────┐
│                    FLUXO DE VENDA PISTA                      │
└─────────────────────────────────────────────────────────────┘

1. INÍCIO
   └─> Operador pressiona [F2] Nova Venda

2. IDENTIFICAÇÃO (Opcional)
   ├─> Inserir placa do veículo
   ├─> Sistema consulta cliente
   └─> Verifica situação (liberado/bloqueado)

3. ABASTECIMENTO
   ├─> Selecionar bomba [1-9]
   ├─> Sistema busca abastecimento pendente
   ├─> Carrega: produto, litros, valor
   └─> Adiciona como item da venda

4. PRODUTOS ADICIONAIS (Opcional)
   ├─> [F3] Buscar produto
   ├─> Informar quantidade
   └─> Adicionar à venda

5. PAGAMENTO
   ├─> [F7] Selecionar forma
   │   ├─> [1] Dinheiro → Informar valor recebido
   │   ├─> [2] Débito → Processar TEF
   │   ├─> [3] Crédito → Processar TEF
   │   ├─> [4] PIX → Gerar QR Code
   │   └─> [5] Frota → Validar cartão
   └─> Confirmar pagamento

6. FINALIZAÇÃO
   ├─> [F8] Finalizar
   ├─> Emitir documento fiscal
   ├─> Imprimir cupom
   └─> Limpar tela para próxima venda
```

### Fluxo: Venda de Loja (Conveniência)

```
1. [F2] Nova Venda
2. [F3] Buscar Produto (código ou nome)
3. Informar quantidade
4. Repetir para mais produtos
5. [F7] Pagamento
6. [F8] Finalizar
```

### Fluxo: Abertura de Caixa

```
1. Login do operador
2. Sistema verifica se há caixa aberto
3. Se não houver:
   ├─> Solicita valor de abertura
   ├─> Operador conta dinheiro
   ├─> Informa valor
   └─> Sistema registra abertura
4. Libera PDV para vendas
```

### Fluxo: Fechamento de Caixa

```
1. [Ctrl+F] Fechamento
2. Sistema calcula valor esperado:
   ├─> Abertura
   ├─> + Vendas em dinheiro
   ├─> + Suprimentos
   ├─> - Sangrias
   └─> = Valor esperado
3. Operador conta dinheiro em caixa
4. Informa valor real
5. Sistema calcula diferença
6. Registra fechamento
7. Gera relatório
```

### Fluxo: Pagamento PIX

```
1. Valor da venda: R$ 150,00
2. Operador seleciona PIX
3. Sistema gera QR Code dinâmico
4. Exibe na tela (grande e visível)
5. Cliente escaneia com app do banco
6. Sistema aguarda confirmação (polling/webhook)
7. PIX confirmado → registra txId e e2eId
8. Finaliza venda
```

### Fluxo: Cliente Bloqueado

```
1. Operador insere placa
2. Sistema consulta API de situação
3. Status retorna "bloqueado"
4. Sistema exibe mensagem genérica:
   "Cliente não autorizado para compra"
5. Opções:
   ├─> Venda à vista (sem crédito)
   └─> Cancelar operação
```

---

## 3. Entidades do Sistema (Referência)

### Entidades Principais

| Entidade | Descrição | Campos Principais |
|----------|-----------|-------------------|
| **Venda** | Registro de venda | numero, data, cliente, total, status |
| **ItemVenda** | Itens da venda | produto, quantidade, preco, desconto |
| **Pagamento** | Formas de pagamento | tipo, valor, status, autorizacao |
| **Abastecimento** | Registro de abastecimento | bomba, litros, preco, encerrantes |
| **Produto** | Catálogo | codigo, nome, preco, tipo, categoria |
| **Cliente** | Clientes | nome, documento, tipo, limiteCredito |
| **Veiculo** | Veículos | placa, modelo, cliente, hodometro |
| **Usuario** | Operadores | nome, email, perfil, pin |
| **Caixa** | Controle de caixa | operador, abertura, fechamento, status |
| **Bomba** | Bombas de combustível | numero, status, bicos |
| **Tanque** | Tanques de combustível | numero, capacidade, nivel |

### Tipos de Pagamento

| Código | Tipo | Campos Específicos |
|--------|------|-------------------|
| DINHEIRO | Dinheiro | valorRecebido, troco |
| DEBITO | Cartão Débito | nsu, autorizacao, bandeira |
| CREDITO | Cartão Crédito | nsu, autorizacao, bandeira, parcelas |
| PIX | PIX | txid, e2eId, qrcode |
| FROTA | Cartão Frota | documento, autorizacao |
| FIADO | Fiado/Convênio | - |
| MISTO | Múltiplas formas | lista de pagamentos |

### Status de Venda

| Status | Descrição |
|--------|-----------|
| EM_ANDAMENTO | Venda em progresso |
| FINALIZADA | Venda concluída com sucesso |
| CANCELADA | Venda cancelada |
| PENDENTE_SYNC | Aguardando sincronização |

### Status de Bomba

| Status | Descrição |
|--------|-----------|
| LIVRE | Disponível para abastecimento |
| EM_ABASTECIMENTO | Abastecimento em andamento |
| PENDENTE | Abastecimento aguardando PDV |
| BLOQUEADA | Bomba bloqueada |
| OFFLINE | Sem comunicação |

---

## 4. Integrações Necessárias

### Obrigatórias (MVP)
- [ ] **Impressora Térmica** - Cupom de venda
- [ ] **PIX** - QR Code dinâmico (API banco)

### Fase 2
- [x] **Módulo Tributário** - Configurador fiscal completo (ver [TRIBUTOS.md](./TRIBUTOS.md))
- [ ] **TEF** - Pagamento cartão (Cielo, Stone, Rede)
- [ ] **SAT/NFC-e** - Emissão fiscal
- [ ] **Bombas** - Automação (Fusion Wayne, Gilbarco, SASC)

### Fase 3
- [ ] **Cartão Frota** - E-fleet, Ticket Log
- [ ] **ERP** - Integração contábil
- [ ] **BI** - Dashboards e analytics

---

## 5. Requisitos Não-Funcionais

### Performance
- Tempo de resposta do PDV: < 200ms
- Finalização de venda: < 2 segundos
- Sincronização em background (não bloquear UI)

### Disponibilidade
- Funcionar 100% offline
- Sincronizar quando conexão disponível
- Recuperar transações pendentes após crash

### Segurança
- Senhas com hash (bcrypt)
- JWT para autenticação API
- Logs de auditoria completos
- Dados sensíveis não expostos em logs

### Usabilidade
- 100% operável via teclado
- Feedback visual e sonoro
- Mensagens de erro claras
- Treinamento mínimo necessário

---

## 6. Melhorias para o Novo Sistema

### Problemas Identificados no Legado
1. Nomes de campos em inglês (dificulta manutenção)
2. Múltiplas tabelas para pagamento Cielo (complexidade)
3. Sincronização com MongoDB desabilitada (pendência)
4. Muitos serviços com responsabilidades sobrepostas

### Melhorias Propostas
1. **Nomenclatura em português** - Mais claro para equipe BR
2. **Schema unificado** - Prisma com relacionamentos claros
3. **Teclado-first** - Atalhos profissionais de PDV
4. **Offline-first** - IndexedDB + sync queue
5. **Arquitetura limpa** - Separação clara de responsabilidades
6. **TypeScript strict** - Menos bugs em produção
7. **Testes automatizados** - Cobertura mínima de 80%
8. **Documentação viva** - OpenAPI/Swagger

---

## 7. Priorização de Funcionalidades

### MVP (Fase 1)
1. Login e autenticação
2. Abertura/Fechamento de caixa
3. Venda simples (sem abastecimento)
4. Pagamento em dinheiro
5. Impressão de cupom (não fiscal)

### Fase 2
1. ~~Módulo Tributário~~ ✅
2. Cadastro de bombas/tanques
3. Abastecimentos (simulado)
4. Pagamento PIX
5. Pagamento cartão (TEF)
6. Clientes e veículos

### Fase 3
1. Integração com bombas reais
2. Emissão fiscal (SAT/NFC-e) - usar dados do módulo tributário
3. Relatórios avançados
4. App mobile (frentista)

### Fase 4
1. Dashboard gerencial
2. Cartão frota
3. Integração ERP
4. Multi-posto

---

*Documento gerado em: Dezembro/2024*
*Baseado em análise do sistema: i9_smart_pdv_mobile_flutter*
