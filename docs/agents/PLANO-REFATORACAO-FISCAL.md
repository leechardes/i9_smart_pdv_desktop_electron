# Plano de Refatoracao do Fluxo Fiscal PDV

## Objetivo
Separar a persistencia da venda da transmissao fiscal, garantindo que os dados sejam sempre salvos antes de tentar transmitir o documento, e centralizando todas as operacoes fiscais no Gerenciador de Documento Fiscal.

---

## Fluxo Proposto

### Fase 1: Finalizacao da Venda (F12)
1. Validar pagamentos (total vs restante)
2. Enviar pagamentos para o backend (`vendaService.addPagamento`)
3. Finalizar venda no backend (`vendaService.finalizar`)
4. **Venda 100% persistida** com status FINALIZADA

### Fase 2: Selecao do Documento
5. Abrir modal de selecao: NFCe ou NFe
6. Se NFe: Coletar dados do destinatario

### Fase 3: Transmissao
7. Transmitir documento fiscal (`fiscalService.emitirNFCe/emitirNFe`)
8. **Se SUCESSO**: Exibir resultado -> Limpar estado -> Nova venda disponivel
9. **Se FALHA**: Abrir Gerenciador automaticamente com erro

---

## Mudancas no Backend

### 1. Separar `finalizar` da emissao fiscal
**Arquivo:** `backend/src/services/venda.service.ts`

**Atual (linhas 604-665):** O metodo `finalizar` emite NFCe automaticamente.

**Proposto:** Remover a emissao automatica do `finalizar`. O frontend controlara quando emitir.

```typescript
async finalizar(vendaId: string, _data: FinalizarVendaInput, user: UserContext) {
  // ... validacoes existentes ...

  // Finalizar venda (sem emitir NFCe)
  const vendaFinalizada = await prisma.venda.update({
    where: { id: vendaId },
    data: {
      status: 'FINALIZADA',
      finalizadaEm: new Date(),
    },
    select: vendaSelect,
  });

  return vendaFinalizada; // Sem campo nfce
}
```

### 2. Verificar duplicidade no nfce.service
**Arquivo:** `backend/src/modules/fiscal/services/nfce.service.ts`

**Atual (linhas 72-81):** Ja verifica se existe documento.

**OK** - Manter verificacao, permite retransmissao quando nao existe documento autorizado.

---

## Mudancas no Frontend

### 1. Refatorar `handleFinalizarComDocumento`
**Arquivo:** `frontend/src/app/pdv/atendimento/page.tsx`

**Separar em 3 etapas:**

```typescript
// Etapa 1: Persistir venda
const persistirVenda = async () => {
  // Adicionar pagamentos ao backend
  for (const pag of pagamentos) {
    await addPagamento(pag.tipo, Number(pag.valor));
  }

  // Finalizar venda (sem emitir documento)
  await finalizarVenda(); // Modificar store para nao emitir
};

// Etapa 2: Transmitir documento (separado)
const transmitirDocumento = async (tipo: 'NFCE' | 'NFE', destinatario?: DestinatarioNFe) => {
  const result = tipo === 'NFCE'
    ? await fiscalService.emitirNFCe(venda.id)
    : await fiscalService.emitirNFe(venda.id, destinatario);
  return result;
};
```

### 2. Modificar Store `finalizarVenda`
**Arquivo:** `frontend/src/stores/pdv.ts`

**Proposto:** Store nao emite documento, apenas finaliza.

```typescript
finalizarVenda: async (): Promise<boolean> => {
  const { venda } = get();
  if (!venda) return false;

  set({ isLoading: true });
  try {
    // Apenas finalizar (backend nao emitira documento)
    const response = await vendaService.finalizar(venda.id, false);
    if (!response.success) {
      set({ error: 'Erro ao finalizar venda', isLoading: false });
      return false;
    }
    // NAO limpar estado - sera limpo apos documento emitido
    set({ isLoading: false });
    return true;
  } catch (error) {
    set({ error: 'Erro ao finalizar venda', isLoading: false });
    return false;
  }
}
```

### 3. Novo handler `handleFinalizarComDocumento`

```typescript
const handleFinalizarComDocumento = useCallback(async (
  tipoDocumento: TipoDocumentoFiscal,
  destinatario?: DestinatarioNFe
) => {
  if (!venda) return;

  const valorTotalVenda = total;
  setDocumentoValorTotal(valorTotalVenda);

  try {
    // FASE 1: Persistir pagamentos
    for (const pag of pagamentos) {
      const ok = await addPagamento(pag.tipo, Number(pag.valor));
      if (!ok) throw new Error('Erro ao adicionar pagamento');
    }

    // FASE 2: Finalizar venda (sem documento)
    const finalizouOk = await finalizarVendaSemDocumento();
    if (!finalizouOk) throw new Error('Erro ao finalizar venda');

    // FASE 3: Transmitir documento
    setTipoDocumentoTransmitindo(tipoDocumento === 'NFCE' ? 'NFCe' : 'NFe');
    setTransmitindoDocumento(true);

    let result;
    if (tipoDocumento === 'NFCE') {
      result = await fiscalService.emitirNFCe(venda.id);
    } else {
      result = await fiscalService.emitirNFe(venda.id, destinatario);
    }

    setTransmitindoDocumento(false);

    if (result.success !== false) {
      // SUCESSO: Limpar e mostrar resultado
      limparEstadoVenda();
      setNfceResult(result);
      setNfceModalOpen(true);
    } else {
      // FALHA: Abrir gerenciador
      setErroEmissao(result.mensagem);
      setTipoDocumentoAtual(tipoDocumento);
      setDocumentoResultAtual(result);
      setGerenciadorFiscalModalOpen(true); // Abre automaticamente
    }
  } catch (error) {
    setTransmitindoDocumento(false);
    setErroEmissao(error.message);
    setGerenciadorFiscalModalOpen(true);
  }
}, [venda, pagamentos, total]);
```

---

## Gerenciador de Documento Fiscal - Melhorias

### 4. Buscar dados completos da venda
**Arquivo:** `frontend/src/components/pdv/modals/GerenciadorDocumentoFiscalModal.tsx`

Adicionar prop para receber dados da venda ou buscar via API:

```typescript
interface GerenciadorDocumentoFiscalModalProps {
  // ... props existentes ...

  // Nova: dados da venda para exibir
  vendaNumero?: number;
  vendaData?: Date;
  vendaStatus?: string;

  // Nova: permitir alterar tipo de documento
  onAlterarTipoDocumento?: (novoTipo: 'NFCE' | 'NFE') => void;
}
```

### 5. Nova Tab: Resumo da Venda
Adicionar tab mostrando:
- Numero da venda
- Data/hora
- Itens
- Pagamentos
- Status atual

### 6. Funcionalidade: Alterar Tipo de Documento
Se erro na NFCe, permitir trocar para NFe ou vice-versa.

### 7. Historico de Tentativas
Mostrar lista de tentativas de emissao para esta venda.

---

## Tarefas de Implementacao

### Backend
- [ ] 1. Modificar `vendaService.finalizar` para nao emitir documento automaticamente
- [ ] 2. Criar endpoint `GET /vendas/:id/fiscal` para retornar historico fiscal

### Frontend - Store
- [ ] 3. Modificar `finalizarVenda` na store para nao emitir documento
- [ ] 4. Adicionar funcao `limparVenda` na store

### Frontend - Page
- [ ] 5. Refatorar `handleFinalizarComDocumento` com as 3 fases
- [ ] 6. Remover banner de erro (usar apenas Gerenciador)
- [ ] 7. Abrir Gerenciador automaticamente em caso de falha

### Frontend - Gerenciador
- [ ] 8. Adicionar exibicao de dados da venda (numero, data, itens, pagamentos)
- [ ] 9. Adicionar opcao de alterar tipo de documento
- [ ] 10. Adicionar historico de tentativas
- [ ] 11. Melhorar UI da tab de erro com mais detalhes
- [ ] 12. Adicionar botao para tentar com outro tipo de documento

---

## Prioridade de Implementacao

### Fase A - Critico (Corrigir fluxo)
1. Backend: Separar finalizacao da emissao
2. Store: Modificar finalizarVenda
3. Page: Refatorar handleFinalizarComDocumento

### Fase B - Gerenciador Basico
4. Abrir Gerenciador automaticamente em falha
5. Exibir dados da venda no Gerenciador

### Fase C - Funcionalidades Extras
6. Alterar tipo de documento
7. Historico de tentativas
8. Melhorias de UI

---

## Testes a Realizar

1. **Fluxo normal**: F12 -> NFCe -> Sucesso -> Nova venda
2. **Falha transmissao**: F12 -> NFCe -> Erro -> Gerenciador abre -> Corrigir -> Retransmitir -> Sucesso
3. **Troca de tipo**: F12 -> NFCe -> Erro -> Trocar para NFe -> Sucesso
4. **Contingencia**: F12 -> NFCe -> SEFAZ offline -> Contingencia -> Sucesso
5. **Dados incorretos**: F12 -> NFe -> Erro IE -> Editar cliente -> Retransmitir -> Sucesso

---

## Riscos e Mitigacoes

| Risco | Mitigacao |
|-------|-----------|
| Venda finalizada sem documento | Gerenciador permite retransmitir a qualquer momento via Ctrl+F |
| Documento duplicado | Backend ja valida existencia de documento autorizado |
| Estado inconsistente frontend | Limpar estado apenas apos sucesso da transmissao |
