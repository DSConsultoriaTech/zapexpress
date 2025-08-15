# Funcionalidade de Importação com Suporte a Grupos

## Alterações Implementadas

### 1. Novo Serviço: FindOrCreateGroupService
- **Arquivo:** `backend/src/services/GroupService/FindOrCreateGroupService.ts`
- **Função:** Buscar grupos existentes por nome ou criar novos automaticamente
- **Parâmetros:** `name` (string), `companyId` (number)
- **Retorna:** Objeto Group

### 2. Migração: Adição do campo groupId
- **Arquivo:** `backend/src/database/migrations/20250101000002-add-groupId-to-contact-list-items.ts`
- **Função:** Adiciona campo `groupId` à tabela `ContactListItems`
- **Tipo:** INTEGER, referência para tabela Groups
- **Comportamento:** CASCADE no update, SET NULL no delete

### 3. Atualização do Modelo ContactListItem
- **Arquivo:** `backend/src/models/ContactListItem.ts`
- **Alterações:**
  - Adicionado campo `groupId: number`
  - Adicionada relação `@BelongsTo(() => Group)`
  - Importação do modelo Group

### 4. Modificação na Importação de Contatos para Listas
- **Arquivo:** `backend/src/services/ContactListService/ImportContacts.ts`
- **Novas funcionalidades:**
  - Suporte às colunas: "grupo", "Grupo", "group", "Group"
  - Busca/criação automática de grupos
  - Associação de contatos aos grupos durante importação
  - Tratamento de erros para grupos inválidos
  - **Validação de limite:** Máximo 200 contatos por arquivo

### 5. Modificação na Importação Direta de Contatos
- **Arquivo:** `backend/src/services/ContactServices/ImportContacts.ts`
- **Novas funcionalidades:**
  - Suporte às colunas: "grupo", "Grupo", "group", "Group"
  - Busca/criação automática de grupos
  - Associação de contatos aos grupos durante importação
  - Tratamento de erros para grupos inválidos
  - **Validação de limite:** Máximo 200 contatos por arquivo

## Como Usar

### Formato da Planilha
A planilha deve conter as seguintes colunas:

| Nome | Número | Email | Grupo |
|------|--------|-------|-------|
| João Silva | 5511999999999 | joao@email.com | Clientes VIP |
| Maria Santos | 5511888888888 | maria@email.com | Leads |

### Colunas Suportadas
- **Nome:** "nome", "Nome"
- **Número:** "numero", "número", "Numero", "Número"
- **Email:** "email", "e-mail", "Email", "E-mail"
- **Grupo:** "grupo", "Grupo", "group", "Group"

### Limitações
- **Máximo de contatos:** 200 contatos por arquivo
- **Mensagem de erro:** "O tamanho total de contatos importados por arquivo deve ser menor ou igual a 200."

### Comportamento
1. **Validação de limite:** Sistema verifica se o arquivo tem mais de 200 linhas antes de processar
2. **Se a coluna de grupo estiver presente e preenchida:**
   - O sistema busca um grupo existente com esse nome
   - Se não encontrar, cria um novo grupo automaticamente
   - Associa o contato ao grupo encontrado/criado

3. **Se a coluna de grupo estiver vazia ou não existir:**
   - O contato é importado sem associação a grupo

4. **Tratamento de erros:**
   - Se houver erro ao processar o grupo, o contato é importado sem grupo
   - Se o arquivo exceder 200 contatos, a importação é bloqueada
   - Erros são logados para análise

## Execução da Migração

Para aplicar as alterações no banco de dados:

```bash
# Executar a migração
npm run migration:run

# Ou se estiver usando yarn
yarn migration:run
```

## Benefícios

1. **Organização Automática:** Contatos são automaticamente organizados em grupos
2. **Flexibilidade:** Suporte a nomes de colunas em português e inglês
3. **Robustez:** Tratamento de erros e logs para debugging
4. **Compatibilidade:** Mantém compatibilidade com importações existentes
5. **Escalabilidade:** Grupos são criados automaticamente conforme necessário
6. **Controle de Volume:** Limita importações a 200 contatos por arquivo para evitar sobrecarga 