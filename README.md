# ConnectTask Lazarus

O **ConnectTask** é um projeto público e comunitário focado no desenvolvimento de um sistema completo de gerenciamento de tarefas no estilo **Trello**. Desenvolvido em **Lazarus (Free Pascal)**, o projeto utiliza a robustez do banco de dados **Firebird 5.0** e traz um conjunto exclusivo de componentes visuais personalizados de alto desempenho.

Qualquer pessoa da comunidade é bem-vinda para contribuir, testar e evoluir o ecossistema!

---

## 🚀 Funcionalidades do Projeto

- **Organização Kanban:** Gerenciamento visual e intuitivo de fluxos de trabalho e tarefas.
- **Banco de Dados Firebird 5.0:** Estrutura relacional robusta, moderna e de alto desempenho para persistência de dados.
- **Componentes Visuais Customizados:** Desenvolvidos nativamente para garantir leveza e design moderno.

---


## 🎨 Pacote de Componentes (`componentes/cards/cards.lpk`)

O projeto utiliza um pacote de componentes visuais registrados sob a aba **`ConnectTask`** na paleta do Lazarus:

### 1. `THeaderScrollBox` (`uheaderscrollbox.pas`)
- Um contêiner rolável (`TScrollBox`) personalizado com um cabeçalho integrado.
- Possui a propriedade `HeaderCaption` publicada para edição direta pelo *Object Inspector* no Lazarus.

### 2. `TTaskCard` (`utaskcard.pas`)
- Componente visual de alto desempenho que representa um cartão de tarefa com design moderno (estilo escuro).
- **Recursos Gráficos:**
  - Renderização customizada via `Paint` (bordas arredondadas e suavizadas).
  - Badge de usuário com cor de fundo dinâmica.
  - Exibição de Código da Tarefa, Data e Texto da Tarefa de forma organizada.
- **Ações Rápidas Interativas (Ícones Integrados):**
  - **Copiar (📋):** Copia automaticamente o código da tarefa (`TaskCode`) para a Área de Transferência.
  - **Editar (✏️):** Abre uma janela pop-up (`InputQuery`) para renomear e atualizar instantaneamente o texto da tarefa.
  - **Excluir (🗑️):** Pergunta antes de excluir e destrói o componente em tempo de execução de forma segura.
  - **Efeitos Visuais:** Mudança dinâmica do cursor do mouse ao passar sobre os ícones e realce (hover) ao passar o mouse.

---

## 💻 Pré-requisitos & Instalação

### Passo 1: Instalar o Pacote de Componentes
Antes de abrir o projeto principal, você precisa instalar o pacote `cards`:
1. Abra o **Lazarus IDE**.
2. Vá em **Pacote (Package)** -> **Abrir arquivo de pacote (.lpk)...**
3. Selecione o arquivo `C:\Fontes\connecttask lazarus\componentes\cards\cards.lpk`.
4. Clique em **Compilar**.
5. Clique em **Usar** -> **Instalar** e confirme a reconstrução do Lazarus.

### Passo 2: Executar o Projeto Principal
1. No Lazarus, vá em **Projeto** -> **Abrir Projeto...**
2. Selecione o arquivo `C:\Fontes\connecttask lazarus\connecttasktrello.lpi`.
3. Pressione **F9** (ou clique em Executar) para compilar e iniciar o ConnectTask.

---

## 📂 Estrutura de Pastas

```
C:\Fontes\connecttask lazarus\
├── componentes\cards\        # Código-fonte do pacote de componentes visuais
│   ├── cards.lpk             # Arquivo do pacote Lazarus
│   ├── utaskcard.pas         # Componente customizado TTaskCard
│   ├── uheaderscrollbox.pas  # Componente customizado THeaderScrollBox
│   └── ...
├── connecttasktrello.lpi     # Arquivo de projeto do Lazarus
├── connecttasktrello.lpr     # Ponto de entrada do programa
├── uprincipal.pas            # Form principal do painel Kanban
├── udm.pas                   # DataModule para conexões de dados
├── cria banco.sql            # Script SQL com esquema do banco de dados
└── README.md                 # Documentação do projeto
```

---

## 🛠️ Tecnologias Utilizadas

- **IDE:** [Lazarus 3.0+](https://www.lazarus-ide.org/)
- **Compilador:** Free Pascal Compiler (FPC)
- **Linguagem:** Object Pascal (Modo ObjFPC)
- **Banco de Dados:** [Firebird 5.0](https://firebirdsql.org/) (SGBD relacional de alta performance)

