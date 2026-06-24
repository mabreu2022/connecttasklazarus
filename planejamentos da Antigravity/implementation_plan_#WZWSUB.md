# Tela de Detalhamento de Tarefa — Lazarus

## Objetivo

Criar uma tela modal (`TForm`) de detalhamento de tarefa no projeto Lazarus que reproduza fielmente o `CardModal.jsx` do projeto web Conect Trelo. Ao clicar em um `TTaskCard` no board, a tela abrirá mostrando os detalhes completos da tarefa.

---

## Análise do CardModal Web

A tela web é um modal com **duas colunas** dividido em:

### Header (topo fixo)
- Título editável + ícones (editar, copiar, ticket ID)
- Criado por / data de criação
- **Prioridade** (dropdown com cores: Alta/Média/Baixa/Urgente/Observação/Ideia/Recuperado)
- Tempo em cada etapa (Backlog: Xm | Em andamento: -Xm | Total: -Xm)

### Coluna Esquerda
- **Descrição** (editável via textarea com markdown)
- **Observações e Comentários** (lista com input + botão enviar)

### Coluna Direita
- **Responsáveis** (avatares com botão remover)
- **Anexos e Vídeos** (lista de arquivos)
- **Ações**: Anexar Arquivo (azul), Compartilhar no QAP (verde), Agendar Tarefa IA (azul)
- **Mover para outro Board** → botão "Escolher Board"
- **Copiar para outro Board** → botão "Copiar Card"
- **Tarefas Relacionadas** (input #TicketID + vincular)
- **Atividades** (histórico de movimentações)

---

## Proposta de Implementação em Lazarus

### Estrutura da nova unit: `utaskdetail.pas` + `utaskdetail.lfm`

Form modal (`bsDialog` ou `bsSizeable`) com tamanho ~1000×700px, tema escuro, com:

**Componentes Lazarus a usar:**
- `TPanel` para o header
- `TSplitter` + dois `TPanel` para as colunas
- `TEdit` / `TMemo` para campos editáveis
- `TComboBox` para prioridade
- `TScrollBox` para comentários e atividades
- `TListBox` ou painéis dinâmicos para listas (responsáveis, anexos, relacionados, atividades)
- `TBitBtn` / `TSpeedButton` estilizados para as ações

**Banco de dados (IBQuery):**
As queries extras necessárias que serão buscadas ao abrir o detalhe:
1. `SELECT * FROM "Card" WHERE ID = :ID` — dados base
2. `SELECT u.USERNAME FROM "User" u JOIN "CardAssignee" ca ON ca.USERID = u.ID WHERE ca.CARDID = :ID` — responsáveis
3. `SELECT * FROM "CardComment" WHERE CARDID = :ID ORDER BY CREATEDAT DESC` — comentários
4. `SELECT * FROM "CardAttachment" WHERE CARDID = :ID` — anexos
5. `SELECT * FROM "CardHistory" ch LEFT JOIN "List" l ON l.ID = ch.TOLISTID WHERE ch.CARDID = :ID ORDER BY ch.CREATEDAT DESC` — atividades

> [!IMPORTANT]
> Precisamos verificar os nomes exatos das tabelas no banco Firebird do projeto Lazarus (arquivo `cria banco.sql`). O projeto web usa Prisma/SQLite, enquanto o Lazarus usa Firebird.

---

## Open Questions

> [!IMPORTANT]
> **Q1 — Tabelas de suporte existem no banco Firebird?**
> O banco web tem tabelas como `CardAssignee`, `CardComment`, `CardAttachment`, `CardHistory`. O banco Firebird do Lazarus pode não ter todas elas. 
> - Quer que eu verifique o SQL do banco (`cria banco.sql`) para confirmar quais existem?
> - Caso não existam, devemos criar apenas com as tabelas disponíveis (Card + dados base)?

> [!IMPORTANT]
> **Q2 — Escopo mínimo ou completo?**
> O CardModal web tem dezenas de funcionalidades. Qual o escopo para esta primeira versão?
> - **Mínimo**: título, prioridade, descrição editável, responsáveis, comentários, atividades
> - **Completo**: todas as seções (anexos, mover/copiar board, tarefas relacionadas, agendamento IA)

> [!IMPORTANT]  
> **Q3 — Como abrir o modal?**
> O clique na área do `TTaskCard` (não nos botões de ação) deve abrir o detalhe. Atualmente `TTaskCard` usa `dmAutomatic` para drag. Devemos:
> - Adicionar um evento `OnCardDetail` ao `TTaskCard` disparado por clique simples (não nos botões)
> - Ou usar `OnDblClick` para abrir o detalhe e click simples para drag?

---

## Proposed Changes

### Fase 1 — Verificação do banco
#### [VERIFY] cria banco.sql
Verificar quais tabelas de suporte existem (`CardComment`, `CardAssignee`, `CardHistory`, etc.)

---

### Fase 2 — Novo form de detalhe
#### [NEW] utaskdetail.pas
- Form `TForm4` (ou `TFormTaskDetail`)
- Método público `LoadCard(ACardID: Integer)`
- Seções: Header, Coluna Esquerda (descrição + comentários), Coluna Direita (responsáveis, ações, atividades)
- Estilo visual: fundo escuro `#1a1a2e`, bordas arredondadas via `TPanel.BevelOuter = bvNone`

#### [NEW] utaskdetail.lfm
- Layout do form gerado via designer ou criado programaticamente

---

### Fase 3 — Integração com TTaskCard
#### [MODIFY] utaskcard.pas
- Adicionar propriedade `OnCardDetail: TNotifyEvent`
- No `MouseDown`, quando o click não for nos botões de ação e não iniciar drag, disparar `OnCardDetail`

#### [MODIFY] ulistas.pas  
- Conectar `OnCardDetail` → abrir `TFormTaskDetail.LoadCard(Card.CardID)`

#### [MODIFY] connecttasktrello.lpi
- Adicionar `utaskdetail.pas` ao projeto

---

## Verification Plan

### Após implementação:
1. Compilar o projeto sem erros
2. Abrir um board, clicar em um card → modal deve abrir com dados corretos
3. Testar edição de título e prioridade → confirmar salvamento no banco
4. Testar adição de comentário → confirmar persistência
5. Verificar visual: tema escuro, layout duas colunas, botões estilizados

