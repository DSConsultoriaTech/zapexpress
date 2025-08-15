# Teste da Validação de Limite de Contatos

## Cenários de Teste

### ✅ **Cenário 1: Importação Válida (≤ 200 contatos)**
- **Arquivo:** planilha_com_150_contatos.xlsx
- **Resultado Esperado:** Importação realizada com sucesso
- **Mensagem:** Contatos importados normalmente

### ❌ **Cenário 2: Importação Inválida (> 200 contatos)**
- **Arquivo:** planilha_com_250_contatos.xlsx
- **Resultado Esperado:** Importação bloqueada
- **Mensagem de Erro:** "O tamanho total de contatos importados por arquivo deve ser menor ou igual a 200."

### ✅ **Cenário 3: Importação no Limite (200 contatos)**
- **Arquivo:** planilha_com_200_contatos.xlsx
- **Resultado Esperado:** Importação realizada com sucesso
- **Mensagem:** Contatos importados normalmente

## Como Testar

### 1. **Criar Planilha de Teste**
```excel
Nome        | Número         | Email           | Grupo
João Silva  | 5511999999999  | joao@email.com  | Clientes VIP
Maria Santos| 5511888888888  | maria@email.com | Leads
... (repetir até ter 201 linhas para teste de erro)
```

### 2. **Testar Importação**
1. Acesse a página de "Listas de Leads"
2. Crie uma nova lista ou selecione uma existente
3. Clique no ícone de pessoas para acessar os contatos
4. Clique em "Importar"
5. Selecione o arquivo de teste
6. Confirme a importação

### 3. **Verificar Resultado**
- **Se ≤ 200 contatos:** Importação realizada com sucesso
- **Se > 200 contatos:** Mensagem de erro exibida

## Código da Validação

```typescript
// Verificar se o número de contatos não excede 200
if (rows.length > 200) {
  throw new AppError("O tamanho total de contatos importados por arquivo deve ser menor ou igual a 200.");
}
```

## Localização da Validação

A validação foi implementada em dois arquivos:

1. **`backend/src/services/ContactListService/ImportContacts.ts`**
   - Para importação em listas de leads

2. **`backend/src/services/ContactServices/ImportContacts.ts`**
   - Para importação direta de contatos

## Benefícios da Validação

1. **Performance:** Evita sobrecarga do sistema com arquivos muito grandes
2. **Experiência do Usuário:** Feedback claro sobre limitações
3. **Estabilidade:** Previne timeouts e erros de memória
4. **Consistência:** Aplica a mesma regra em todas as importações
