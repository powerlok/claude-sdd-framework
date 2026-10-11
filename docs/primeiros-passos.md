# Primeiros passos

Guia para quem **nunca usou** o Claude SDD Framework nem plugins do Claude Code. Siga na ordem: cada passo diz o que
**fazer**, o que **você vai ver** e como **conferir** que deu certo antes de seguir.

Testado com o Claude Code 2.1.296 e a versão `v0.7.0` do framework (a salinha dos agentes, opcional, chega nessa versão).

## Índice

- [Antes de começar](#antes-de-começar)
- [1. Instalar na máquina (uma vez)](#1-instalar-na-máquina-uma-vez)
- [2. Preparar o projeto](#2-preparar-o-projeto) — [Caminho A: código existente](#caminho-a-projeto-com-código-existente) ·
  [Caminho B: projeto do zero](#caminho-b-projeto-do-zero)
- [3. Primeira conversa](#3-primeira-conversa)
- [4. Primeiro pedido](#4-primeiro-pedido)
- [O que versionar](#o-que-versionar)
- [Equipe: o que cada dev faz](#equipe-o-que-cada-dev-faz)
- [Workspace com vários repositórios](#workspace-com-vários-repositórios)
- [Salinha dos agentes (opcional)](#salinha-dos-agentes-opcional)
- [Atualizar a versão](#atualizar-a-versão)
- [Problemas comuns](#problemas-comuns)

## Como funciona, em uma frase

O framework é um **plugin** (`sdd`) distribuído por um **marketplace** (`claude-sdd-framework`, este repositório).
Você registra o marketplace **uma vez na máquina** e instala o plugin **em cada projeto**. Depois disso, ao abrir o
`claude` na pasta do projeto, quem responde é o **TecLeader**, o agente que conduz todo o trabalho.

## Antes de começar

| Pré-requisito | Como conferir |
|---|---|
| Claude Code **2.1.288 ou superior** (testado no 2.1.296) | `claude --version` |
| Git com acesso a este repositório (privado) | `git ls-remote https://github.com/powerlok/claude-sdd-framework.git` lista as referências, sem erro |
| **Windows:** Git for Windows (o hook do plugin usa `bash`) | `bash --version` no terminal |
| **Windows:** `claude` no PATH | `claude --version` funciona no terminal que você vai usar |

**Acesso ao repositório.** O Claude Code usa as credenciais do git da sua máquina, sem pedir senha:

- HTTPS: pelo gerenciador de credenciais do git (ex.: `gh auth setup-git`, se você usa o GitHub CLI);
- ou SSH, com a chave carregada no agente.

> **Nunca** coloque usuário, senha ou token na URL (`https://user:token@...`).

Se o `git ls-remote` acima falhar, resolva o acesso antes de seguir: os passos seguintes fazem o mesmo acesso.

**Windows: `claude` não encontrado.** O instalador nativo coloca o `claude.exe` em `%USERPROFILE%\.local\bin`.
Adicione ao PATH da sessão:

```powershell
# PowerShell
$env:Path += ";$HOME\.local\bin"
```

```bash
# Git Bash
export PATH="$PATH:$HOME/.local/bin"
```

## 1. Instalar na máquina (uma vez)

**Faça** (em qualquer pasta):

```bash
claude plugin marketplace add "https://github.com/powerlok/claude-sdd-framework.git#v0.7.0"
```

O `#v0.7.0` escolhe a versão (tag). O comando clona o repositório nessa tag e registra o marketplace no seu usuário.

**Você vai ver** algo como:

```text
Cloning ... (ref: v0.7.0)
Successfully added marketplace: claude-sdd-framework (declared in user settings)
```

**Confira:**

```bash
claude plugin marketplace list
```

`claude-sdd-framework` aparece na lista. Se o clone falhar, veja [Problemas comuns](#problemas-comuns).

> Só faça isso de novo em outra máquina. Para trocar de versão, veja [Atualizar a versão](#atualizar-a-versão).

## 2. Preparar o projeto

**Onde:** sempre na **raiz do repositório git** do projeto (em monorepo, a pasta do projeto). É lá que ficam
`.claude/settings.json`, `CLAUDE.md` e `.specs/`.

Escolha o seu caso:

| Caminho A: projeto com código existente | Caminho B: projeto do zero |
|---|---|
| Já existe um repositório com código (e talvez sem `CLAUDE.md`) | Pasta nova, ainda sem código |
| O TecLeader **lê o código** e propõe o `CLAUDE.md` | O TecLeader **pergunta a stack** e propõe o `CLAUDE.md` |

### Caminho A: projeto com código existente

**A1. Copie o settings do projeto**

**Faça:** copie o arquivo **inteiro** [`templates/project-settings.git.json`](../templates/project-settings.git.json)
para `<projeto>/.claude/settings.json` (crie a pasta `.claude` se não existir). Copie o arquivo todo, não só um
trecho: além de declarar o marketplace e o plugin, ele traz as [proteções do template](../README.md#-proteções-do-template)
(`permissions.deny`).

**Você vai ver:** nada ainda. Esse arquivo **sozinho não carrega o plugin**: ele declara o marketplace, habilita o
`sdd` e define o TecLeader como agente da sessão, mas a instalação é o próximo passo.

**Confira:** o arquivo existe em `<projeto>/.claude/settings.json` e contém `"ref": "v0.7.0"` e `"agent": "sdd:tecleader"`.

**A2. Instale o plugin no projeto**

**Faça** (na raiz do projeto):

```bash
claude plugin install sdd@claude-sdd-framework --scope project
```

**Você vai ver:** `Successfully installed` com `(scope: project)`. O comando pode reordenar as chaves do
`.claude/settings.json`: o `git diff` mostra o arquivo alterado, mas o conteúdo é o mesmo.

**Confira:**

```bash
claude plugin list
```

`sdd` aparece com versão `0.6.4`, escopo `project` e `enabled`.

Se aparecerem várias linhas `sdd` (uma por projeto em que você instalou), basta uma com `0.6.4`, `project`, `enabled`.
O `plugin list` não mostra o caminho do projeto; na dúvida, abra o `claude` e veja se a resposta começa com
"Sou o TecLeader".

Siga para [3. Primeira conversa](#3-primeira-conversa).

### Caminho B: projeto do zero

**B1. Crie a pasta e o repositório**

**Faça:**

```bash
mkdir meu-projeto
cd meu-projeto
git init
```

**Você vai ver:** a mensagem do git de repositório vazio inicializado.

**Confira:** existe a pasta `.git` dentro de `meu-projeto`.

**B2. Copie o settings e instale o plugin**

**Faça:** os mesmos passos [A1](#caminho-a-projeto-com-código-existente) e A2: copie o arquivo **inteiro**
[`templates/project-settings.git.json`](../templates/project-settings.git.json) para `meu-projeto/.claude/settings.json` e,
na raiz da pasta, rode:

```bash
claude plugin install sdd@claude-sdd-framework --scope project
```

**Você vai ver:** `Successfully installed` com `(scope: project)`.

**Confira:** `claude plugin list` mostra `sdd` `0.6.4`, escopo `project`, `enabled`.

## 3. Primeira conversa

**Faça:** na raiz do projeto, abra a sessão:

```bash
claude
```

**Você vai ver:**

1. Na primeira vez, o **diálogo de confiança da pasta**. Aceite: sem confiar na pasta, o plugin do projeto não carrega.
2. A primeira resposta vem do **TecLeader** ("Sou o TecLeader") com a situação do projeto (onboarding). Nada é
   alterado sem a sua confirmação.

Se você instalou o plugin com uma sessão já aberta, rode `/reload-plugins` ou abra uma nova sessão.

**No Caminho A (código existente, sem `CLAUDE.md`)**, o TecLeader:

- diz que a pasta é um repositório git com manifestos (ex.: `package.json`), sem `CLAUDE.md` e sem `.specs/`;
- explica o que vai ler e o que vai criar;
- pergunta: **"Faço o onboarding agora?"**

A resposta inicial pode citar mesclar o `.claude/settings.json` com o modelo; se ele já estiver igual ao modelo, nada
muda.

Responda `sim`. Ele lê o código e pode pedir aprovação para ler a pasta do plugin (`~/.claude/plugins`), para comparar
o seu `.claude/settings.json` com o modelo, e para rodar comandos de leitura (ex.: `git status`) e testes (ex.:
`npm test`): aprove (são leitura/testes). Se negar, ele avisa o que ficou sem conferir. No fim, cria:

- `CLAUDE.md` com `## Stack`, os comandos reais do projeto (os que não existem ficam "não configurado"),
  `## Arquitetura`, `## Convenções` e `## SDD`;
- `.specs/INDEX.md` (índice das specs).

Ele **não faz commit**. Revise o `CLAUDE.md` gerado e corrija o que estiver errado antes do primeiro pedido. Se o
`CLAUDE.md` sair com a nota "comandos ainda não executados", aprove a execução (ou peça para rodar depois) e confira
os comandos registrados.

**No Caminho B (projeto do zero)**, o TecLeader diz que a pasta não tem código e pergunta:

- a stack (linguagem, framework, versão);
- a nuvem/infra (ou "nenhuma");
- as convenções.

Ele assume que os artefatos do processo são versionados (`Versionar artefatos SDD: sim`); você pode pedir `não`
(veja [O que versionar](#o-que-versionar)).

Responda, por exemplo:

```text
API REST em Python com FastAPI
```

Ele pode fazer mais perguntas (versões, gerenciador de dependências, testes). Pode responder "recomendações". Ele
mostra o plano e **só cria** `CLAUDE.md` e `.specs/INDEX.md` depois do seu "ok".

**Confira:**

- a resposta começa com "Sou o TecLeader" (se vier uma resposta genérica, veja [Problemas comuns](#problemas-comuns));
- `/plugin`: aba **Installed** mostra o `sdd`; aba **Errors** vazia;
- fora da sessão, `claude doctor` não aponta erro de plugin;
- o `CLAUDE.md` e o `.specs/INDEX.md` existem na raiz do projeto.

> Opcional: em vez do onboarding, você pode partir do modelo [`templates/CLAUDE.md`](../templates/CLAUDE.md) e
> preenchê-lo; o TecLeader confere o que faltar.

## 4. Primeiro pedido

**Faça:** descreva o que você quer, em linguagem natural (adapte o exemplo ao seu projeto):

```text
Crie um endpoint POST /todos que cadastra tarefas com título obrigatório
```

**Você vai ver:** o TecLeader pode primeiro fazer perguntas (ex.: qual framework, onde guardar os dados),
principalmente se o pedido muda a stack do projeto. Pode responder "recomendações". Depois ele propõe requisitos e
critérios de aceite — e um design técnico quando necessário (novo módulo, contrato de API) — e pede sua confirmação
antes de implementar. Depois de confirmar, ele cria
`.specs/<feature>/spec.md` e `tasks.md`, delega aos especialistas (backend, frontend, testes, segurança) e só encerra a
task com evidência de que funciona.

**Confira:** a pasta `.specs/<feature>/` existe com `spec.md` e `tasks.md`, e o `.specs/INDEX.md` lista a feature.

Para entender o fluxo completo e ver outros exemplos, use o [manual de uso](manual-de-uso.html).

## O que versionar

O padrão é `Versionar artefatos SDD: sim` (seção `## SDD` do `CLAUDE.md`). Faça commit de:

- `.claude/settings.json`
- `CLAUDE.md`
- `.specs/`

O TecLeader **nunca faz commit**: você revisa e commita.

**Repositório de cliente que não aceita esses arquivos:** use `Versionar artefatos SDD: não`. O TecLeader passa a usar
`.claude/settings.local.json` e o exclude local do git, sem tocar no `.gitignore`. Detalhes em
"Camadas do CLAUDE.md" no [README](../README.md).

## Equipe: o que cada dev faz

O `.claude/settings.json` versionado **não instala nada sozinho**. Cada dev da equipe, depois de clonar o projeto:

1. Uma vez na máquina: `claude plugin marketplace add "https://github.com/powerlok/claude-sdd-framework.git#v0.7.0"`
   ([passo 1](#1-instalar-na-máquina-uma-vez)).
2. Uma vez por projeto, na raiz: `claude plugin install sdd@claude-sdd-framework --scope project`.
3. Abrir `claude` na raiz, confiar na pasta e conferir que responde o TecLeader.

Sem o passo 2, o `/plugin` mostra na aba **Errors**: "enabled in project settings but isn't installed here".

## Workspace com vários repositórios

Se a sua pasta de trabalho tem vários repositórios lado a lado, **abra o `claude` dentro do repositório** em que vai
trabalhar (é lá que ficam o settings, o `CLAUDE.md` e o `.specs/`), não na pasta-mãe.

Para trabalho que envolve mais de um projeto, veja [Trabalhar entre projetos](../README.md#-trabalhar-entre-projetos)
no README.

## Salinha dos agentes (opcional)

Uma página local, aberta no navegador, mostra uma sala em pixel art com uma mesa por agente e o que cada um está fazendo
(ex.: "backend: editando arquivos"). Vem **desligada**; sem dependências de terceiros, sem servidor, sem rede.

- **Aceitar na primeira conversa:** o TecLeader oferece uma vez, no fim da primeira resposta (e no fim do onboarding).
  Responda que quer; se recusar, ela fica desligada.
- **Ligar ou desligar depois:** `/sdd:office on`, `/sdd:office off` ou `/sdd:office status` (na primeira vez o Claude
  pede para você aprovar o comando), ou peça ao TecLeader. O `on` já abre a tela e, nas sessões seguintes, ela abre
  sozinha no navegador padrão.
- **Onde fica a preferência:** `~/.claude/sdd/office.conf`, por usuário, nunca no repositório. A página guarda só agente,
  tipo de ferramenta e horário (nunca conteúdo de arquivos, comandos ou prompts), na pasta temporária do sistema.
- **Requisitos:** bash (Git Bash no Windows) e navegador moderno. Validada no Windows (Chrome, Edge); não testada em macOS,
  Linux nem Firefox.

Detalhes e limites: [README](../README.md#-salinha-dos-agentes-opcional).

## Atualizar a versão

1. No `.claude/settings.json` do projeto, troque o `"ref"` pela nova tag (ex.: de `"v0.7.0"` para a tag nova).
2. Rode:

   ```bash
   claude plugin marketplace update claude-sdd-framework
   claude plugin update sdd@claude-sdd-framework --scope project
   ```

3. Abra uma nova sessão (ou `/reload-plugins`).

**Confira:** `claude plugin list` mostra a versão nova do `sdd`. As mudanças de cada versão estão no
[CHANGELOG](../CHANGELOG.md).

## Problemas comuns

| Sintoma | Causa provável | Solução |
|---|---|---|
| `claude` não encontrado (Windows) | `%USERPROFILE%\.local\bin` fora do PATH | PowerShell: `$env:Path += ";$HOME\.local\bin"`; Git Bash: `export PATH="$PATH:$HOME/.local/bin"` |
| `Plugin "sdd" not found in marketplace` ao instalar | Marketplace não registrado nesta máquina, ou desatualizado | Rode o [passo 1](#1-instalar-na-máquina-uma-vez) (`marketplace add`); se já registrado, `claude plugin marketplace update claude-sdd-framework` |
| Falha de clone ou de autenticação no `marketplace add` | Git sem acesso ao repositório privado | Teste `git ls-remote https://github.com/powerlok/claude-sdd-framework.git`; configure credenciais (gerenciador de credenciais/`gh auth setup-git` ou SSH); nunca token na URL |
| Resposta genérica, sem "Sou o TecLeader" | Plugin não instalado no projeto; pasta não confiada; ou sessão aberta antes do install | Rode o `plugin install` na raiz; aceite o diálogo de confiança; `/reload-plugins` ou nova sessão |
| `/plugin` › Errors: "enabled in project settings but isn't installed here" | O settings foi copiado (ou veio pelo git), mas o plugin não foi instalado nesta máquina | `claude plugin install sdd@claude-sdd-framework --scope project` na raiz do projeto |
| Verificação de onboarding (hook) sem efeito no Windows | Git for Windows ausente (o hook usa `bash`) | Instale o Git for Windows; sem ele, o TecLeader faz a mesma verificação lendo os arquivos |
| `git diff` mostra o `.claude/settings.json` alterado logo após o install | O `plugin install` reordena as chaves | Sem mudança de conteúdo; pode commitar ou descartar |
| A salinha dos agentes não abre | Preferência desligada, navegador padrão não definido ou Git Bash ausente | Rode `/sdd:office status` (se `off`, `/sdd:office on`); defina um navegador padrão; instale o Git for Windows (e confira que o `bash` do PATH não é o do WSL) |

Outros problemas: [Solução de problemas](manual-de-uso.html#problemas) no manual.
