# Primeiros passos

Guia para quem **nunca usou** o Claude SDD Framework nem plugins do Claude Code. Siga na ordem: cada passo diz o que
**fazer**, o que **você vai ver** e como **conferir** que deu certo antes de seguir.

Passo a passo testado em máquina nova com o Claude Code 2.1.296 e o framework `v0.7.0`. A `v0.12.0` (atual) foi verificada com `validate --strict`, a suíte de testes (também em Linux) e sandboxes com o CLI (`claude -p`); este passo a passo não foi refeito em máquina nova com ela.

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
`claude` na pasta do projeto, quem responde é o **TechLead**, o agente que conduz todo o trabalho.

## Antes de começar

| Pré-requisito | Como conferir |
|---|---|
| Claude Code **2.1.288 ou superior** (testado no 2.1.296) | `claude --version` |
| Git com acesso de rede a este repositório (público, sem credencial) | `git ls-remote https://github.com/powerlok/claude-sdd-framework.git` lista as referências, sem erro |
| **Windows:** Git for Windows (o hook do plugin usa `bash`) | `bash --version` no terminal |
| **Windows:** `claude` no PATH | `claude --version` funciona no terminal que você vai usar |

**Acesso ao repositório.** O repositório é público: o Claude Code usa o git da sua máquina e não precisa de credencial.

> **Nunca** coloque usuário, senha ou token na URL (`https://user:token@...`).

Se o `git ls-remote` acima falhar, resolva a rede antes de seguir (proxy, firewall ou DNS bloqueando o github.com): os passos seguintes fazem o mesmo acesso.

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

O marketplace fica registrado no **seu usuário** (`~/.claude/settings.json`, em `extraKnownMarketplaces`). Se esse arquivo
não existir, o próprio comando abaixo o cria. Quem decide a versão do plugin nesta máquina é essa entrada (o `ref` do
`.claude/settings.json` de cada projeto só vale em máquina que ainda não tem o marketplace).

**Primeiro, veja em que situação você está** (só leitura):

```bash
claude plugin marketplace list
```

Procure `claude-sdd-framework` na lista e leia a linha `Source:`.

| O que a lista mostra | Situação | O que fazer |
|---|---|---|
| `claude-sdd-framework` não aparece | **A. Primeira vez nesta máquina** (ou o `~/.claude/settings.json` nem existe) | Faça o **passo A** |
| `Source: Git (https://github.com/powerlok/claude-sdd-framework.git@v0.12.0)` | **B. Já registrado na versão desejada** | Nada a fazer aqui; siga para o [passo 2](#2-preparar-o-projeto) |
| Aparece sem `@...` (sem versão fixada) ou com outra versão (ex.: `@v0.9.1`) | **C. Já registrado com outra fonte** | Faça o **passo C**. Se rodar o `add` com `#v0.12.0` sem fazer isso, dá o erro `its source doesn't match its extraKnownMarketplaces entry` |

### Passo A: primeira vez

```bash
claude plugin marketplace add "https://github.com/powerlok/claude-sdd-framework.git#v0.12.0"
```

O `#v0.12.0` escolhe a versão (tag). O comando clona o repositório nessa tag, registra o marketplace e grava a entrada no
`~/.claude/settings.json` (criando o arquivo se não existir).

**Você vai ver** algo como:

```text
Cloning ... (ref: v0.12.0)
Successfully added marketplace: claude-sdd-framework (declared in user settings)
```

**Confira:** `claude plugin marketplace list` mostra `Source: Git (https://github.com/powerlok/claude-sdd-framework.git@v0.12.0)`.
Rodar o mesmo `add` de novo é seguro (responde que já está no disco).

### Passo C: já registrado sem versão ou com outra versão

Escolha **uma** das duas saídas.

**C1. Seguir a entrada atual (sem fixar versão).** Use exatamente a fonte que está no seu settings, sem `#`:

```bash
claude plugin marketplace add "https://github.com/powerlok/claude-sdd-framework.git"
```

Você acompanha a branch principal (`main`). Serve para experimentar; para equipe, prefira fixar a versão (C2).

**C2. Fixar a versão (recomendado).**

1. Abra o `~/.claude/settings.json` (Windows: `%USERPROFILE%\.claude\settings.json`) e, na entrada
   `claude-sdd-framework`, acrescente (ou troque) o `ref` dentro de `source`:

   ```json
   "extraKnownMarketplaces": {
     "claude-sdd-framework": {
       "source": { "source": "git", "url": "https://github.com/powerlok/claude-sdd-framework.git", "ref": "v0.12.0" }
     }
   }
   ```

   Salve mantendo as outras chaves do arquivo como estão.
2. Registre de novo, com a **mesma** fonte da entrada:

   ```bash
   claude plugin marketplace add "https://github.com/powerlok/claude-sdd-framework.git#v0.12.0"
   ```

3. Se o plugin já estava instalado em algum projeto, atualize-o lá (na raiz do projeto):

   ```bash
   claude plugin update sdd@claude-sdd-framework --scope project
   ```

**Confira:** `claude plugin marketplace list` mostra `@v0.12.0`; num projeto já instalado, `claude plugin list` mostra a versão nova.

> **Evite** `claude plugin marketplace remove claude-sdd-framework` para resolver isso: ele **desinstala** o plugin de todos os
> projetos e apaga a declaração do marketplace do `.claude/settings.json` deles (depois você teria de reinstalar em cada
> projeto e recopiar o template). Evite também `marketplace update` logo depois de editar o `ref` à mão: o marketplace
> passa a aparecer como "not found" até você rodar o `add` do item 2.

Se o clone falhar, veja [Problemas comuns](#problemas-comuns).

> Só faça isso de novo em outra máquina. Para trocar de versão depois, veja [Atualizar a versão](#atualizar-a-versão).

## 2. Preparar o projeto

**Onde:** sempre na **raiz do repositório git** do projeto (em monorepo, a pasta do projeto). É lá que ficam
`.claude/settings.json`, `CLAUDE.md` e `.specs/`.

Escolha o seu caso:

| Caminho A: projeto com código existente | Caminho B: projeto do zero |
|---|---|
| Já existe um repositório com código (e talvez sem `CLAUDE.md`) | Pasta nova, ainda sem código |
| O TechLead **lê o código** e propõe o `CLAUDE.md` | O TechLead **pergunta a stack** e propõe o `CLAUDE.md` |

### Caminho A: projeto com código existente

**A1. Copie o settings do projeto**

**Faça:** copie o arquivo **inteiro** [`templates/project-settings.git.json`](../templates/project-settings.git.json)
para `<projeto>/.claude/settings.json` (crie a pasta `.claude` se não existir). Copie o arquivo todo, não só um
trecho: além de declarar o marketplace e o plugin, ele traz as [proteções do template](../README.md#-proteções-do-template)
(`permissions.deny`).

**O projeto já tem `.claude/settings.json`?** Não sobrescreva. Mescle (o TechLead faz essa mescla no onboarding, com a sua
confirmação; ou faça à mão): acrescente as chaves `extraKnownMarketplaces`, `enabledPlugins` e `agent` do template, e una as
listas `permissions.deny` e `permissions.ask` com as do template (união: nenhuma entrada sua é removida). As suas outras
chaves (ex.: `permissions.allow`, `env`) ficam como estão. O `plugin install` do passo A2 também preserva as chaves existentes
(só acrescenta `enabledPlugins`). Se você já tem `permissions.allow` com `Bash(gh *)` ou `Bash(*)`, remova: um `allow` amplo
anula as confirmações de publicação.

**Você vai ver:** nada ainda. Esse arquivo **sozinho não carrega o plugin**: ele declara o marketplace, habilita o
`sdd` e define o TechLead como agente da sessão, mas a instalação é o próximo passo.

**Confira:** o arquivo existe em `<projeto>/.claude/settings.json` e contém `"ref": "v0.12.0"` e `"agent": "sdd:techlead"`.

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

`sdd` aparece com versão `0.9.4`, escopo `project` e `enabled`.

Se aparecerem várias linhas `sdd` (uma por projeto em que você instalou), basta uma com `0.9.4`, `project`, `enabled`.
O `plugin list` não mostra o caminho do projeto; na dúvida, abra o `claude` e veja se a resposta começa com
"Sou o TechLead".

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

**Confira:** `claude plugin list` mostra `sdd` `0.9.4`, escopo `project`, `enabled`.

## 3. Primeira conversa

**Faça:** na raiz do projeto, abra a sessão:

```bash
claude
```

**Você vai ver:**

1. Na primeira vez, o **diálogo de confiança da pasta**. Aceite: sem confiar na pasta, o plugin do projeto não carrega.
2. O sdd mostra um **aviso de início** ("sdd: ... Digite /sdd:start"). O Claude Code **só responde depois da sua
   primeira mensagem**, então o terminal fica esperando você: **digite `/sdd:start`** (qualquer mensagem também funciona).
3. A resposta vem do **TechLead** ("Sou o TechLead") com a situação do projeto (onboarding) e conduz as perguntas iniciais, uma
   etapa de cada vez. Nada é alterado sem a sua confirmação.

Se você instalou o plugin com uma sessão já aberta, rode `/reload-plugins` ou abra uma nova sessão.

**No Caminho A (código existente, sem `CLAUDE.md`)**, o TechLead:

- diz que a pasta é um repositório git com manifestos (ex.: `package.json`), sem `CLAUDE.md` e sem `.specs/`;
- explica o que vai ler e o que vai criar;
- pergunta: **"Faço o onboarding agora?"**, e, para a seção `## Git`, o idioma das mensagens de commit e do PR (`pt` ou `en`) e se ele pode publicar (push da branch, PR, release; o merge é sempre seu) com confirmação a cada comando (padrão: não; fica só no seu `.claude/settings.local.json`).

A resposta inicial pode citar mesclar o `.claude/settings.json` com o modelo; se ele já estiver igual ao modelo, nada
muda.

Responda `sim`. Ele lê o código e pode pedir aprovação para ler a pasta do plugin (`~/.claude/plugins`), para comparar
o seu `.claude/settings.json` com o modelo, e para rodar comandos de leitura (ex.: `git status`) e testes (ex.:
`npm test`): aprove (são leitura/testes). Se negar, ele avisa o que ficou sem conferir. No fim, cria:

- `CLAUDE.md` com `## Stack`, os comandos reais do projeto (os que não existem ficam "não configurado"),
  `## Arquitetura`, `## Convenções`, `## Git` e `## SDD`;
- `.specs/INDEX.md` (índice das specs).

Ele **não faz commit** neste passo (com a seção `## Git`, ele só cria branch e commit locais depois da sua confirmação, e só faz `push`, PR ou release se você ligar o modo publicação, com confirmação a cada comando). Revise o `CLAUDE.md` gerado e corrija o que estiver errado antes do primeiro pedido. Se o
`CLAUDE.md` sair com a nota "comandos ainda não executados", aprove a execução (ou peça para rodar depois) e confira
os comandos registrados.

**No Caminho B (projeto do zero)**, o TechLead diz que a pasta não tem código e pergunta:

- a stack (linguagem, framework, versão);
- a nuvem/infra (ou "nenhuma");
- as convenções;
- o idioma das mensagens de commit e do PR (`pt` ou `en`), para a seção `## Git`.

Ele assume que os artefatos do processo são versionados (`Versionar artefatos SDD: sim`); você pode pedir `não`
(veja [O que versionar](#o-que-versionar)).

Responda, por exemplo:

```text
API REST em Python com FastAPI
```

Ele pode fazer mais perguntas (versões, gerenciador de dependências, testes). Pode responder "recomendações". Ele
mostra o plano e **só cria** `CLAUDE.md` e `.specs/INDEX.md` depois do seu "ok".

**Confira:**

- a resposta começa com "Sou o TechLead" (se vier uma resposta genérica, veja [Problemas comuns](#problemas-comuns));
- `/plugin`: aba **Installed** mostra o `sdd`; aba **Errors** vazia;
- fora da sessão, `claude doctor` não aponta erro de plugin;
- o `CLAUDE.md` e o `.specs/INDEX.md` existem na raiz do projeto.

> Opcional: em vez do onboarding, você pode partir do modelo [`templates/CLAUDE.md`](../templates/CLAUDE.md) e
> preenchê-lo; o TechLead confere o que faltar.

## 4. Primeiro pedido

**Faça:** descreva o que você quer, em linguagem natural (adapte o exemplo ao seu projeto):

```text
Crie um endpoint POST /todos que cadastra tarefas com título obrigatório
```

**Você vai ver:** o TechLead pode primeiro fazer perguntas (ex.: qual framework, onde guardar os dados),
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

O TechLead **nunca faz commit**: você revisa e commita.

**Repositório de cliente que não aceita esses arquivos:** use `Versionar artefatos SDD: não`. O TechLead passa a usar
`.claude/settings.local.json` e o exclude local do git, sem tocar no `.gitignore`. Detalhes em
"Camadas do CLAUDE.md" no [README](../README.md).

## Equipe: o que cada dev faz

O `.claude/settings.json` versionado **não instala nada sozinho**. Cada dev da equipe, depois de clonar o projeto:

1. Uma vez na máquina: `claude plugin marketplace add "https://github.com/powerlok/claude-sdd-framework.git#v0.12.0"`
   ([passo 1](#1-instalar-na-máquina-uma-vez)).
2. Uma vez por projeto, na raiz: `claude plugin install sdd@claude-sdd-framework --scope project`.
3. Abrir `claude` na raiz, confiar na pasta e conferir que responde o TechLead.

Sem o passo 2, o `/plugin` mostra na aba **Errors**: "enabled in project settings but isn't installed here".

## Workspace com vários repositórios

Se a sua pasta de trabalho tem vários repositórios lado a lado, **abra o `claude` dentro do repositório** em que vai
trabalhar (é lá que ficam o settings, o `CLAUDE.md` e o `.specs/`), não na pasta-mãe.

Para trabalho que envolve mais de um projeto, veja [Trabalhar entre projetos](../README.md#-trabalhar-entre-projetos)
no README.

## Salinha dos agentes (opcional)

Uma página local, aberta no navegador, mostra uma sala em pixel art com uma mesa por agente e o que cada um está fazendo
(ex.: "backend: editando arquivos"). O agente fica "trabalhando" do início até o fim da tarefa, mesmo em silêncio (ex.: "tests: trabalhando há 10 min"); sem nenhum evento por 30 min aparece "sem atividade". Vem **desligada**; sem dependências de terceiros, sem servidor, sem rede.

- **Aceitar na primeira conversa:** o TechLead oferece uma vez, no fim da primeira resposta (e no fim do onboarding).
  Responda que quer; se recusar, ela fica desligada.
- **Ligar ou desligar depois:** `/sdd:office on`, `/sdd:office off` ou `/sdd:office status` (na primeira vez o Claude
  pede para você aprovar o comando), ou peça ao TechLead. O `on` já abre a tela e, nas sessões seguintes, ela abre
  sozinha no navegador padrão, **a não ser que a salinha já esteja em uso** (atividade nos últimos 30 min: não abre outra aba;
  se você fechou a aba, reabra com `/sdd:office on`).
- **Onde fica a preferência:** `~/.claude/sdd/office.conf`, por usuário, nunca no repositório. A página guarda só agente,
  tipo de ferramenta e horário (nunca conteúdo de arquivos, comandos ou prompts), na pasta temporária do sistema.
- **Requisitos:** bash (Git Bash no Windows) e navegador moderno. Validada no Windows (Chrome, Edge); não testada em macOS,
  Linux nem Firefox.

Detalhes e limites: [README](../README.md#-salinha-dos-agentes-opcional).

## Navegador do frontend (opcional)

O plugin traz o MCP do Playwright para o `sdd:frontend` conferir a interface no navegador. Precisa de **Node.js/npm** e **Google Chrome**. Suba o app local e peça ao
TechLead para verificar a tela: o frontend abre `http://localhost:...` numa janela do Chrome (perfil isolado, sem logins) e pede a sua confirmação a cada
`browser_navigate`. Adicione `.playwright-mcp/` ao `.gitignore` do projeto. Riscos, limites e como desligar (`/mcp`):
[README](../README.md#-navegador-do-frontend-mcp-playwright-opcional).

## Diagramas do arquiteto (opcional)

O plugin traz o MCP oficial do draw.io para o `sdd:infra-architect`. Para usá-lo, é preciso **Node.js/npm** (`npx --version`). Peça ao
TechLead um diagrama de arquitetura: o arquiteto abre o editor do draw.io em uma aba do navegador e pede a sua confirmação a cada `open_*`.
Sem Node/npm ele descreve o diagrama em Mermaid. Privacidade, riscos e como desligar (`/mcp`): [README](../README.md#-diagramas-do-arquiteto-mcp-drawio-opcional).

## Atualizar a versão

A versão instalada nesta máquina vem da entrada `claude-sdd-framework` do `~/.claude/settings.json`. Para subir:

1. No `~/.claude/settings.json`, troque o `ref` da entrada `claude-sdd-framework` pela nova tag (ex.: de `"v0.9.1"` para
   `"v0.12.0"`). No `.claude/settings.json` do projeto, troque também o `"ref"`, para quem ainda não tem o marketplace.
2. Registre com a nova tag (mesma fonte da entrada):

   ```bash
   claude plugin marketplace add "https://github.com/powerlok/claude-sdd-framework.git#v0.12.0"
   ```

3. Em cada projeto onde o plugin está instalado (na raiz do projeto):

   ```bash
   claude plugin update sdd@claude-sdd-framework --scope project
   ```

4. Abra uma nova sessão (ou `/reload-plugins`).

**Confira:** `claude plugin list` mostra a versão nova do `sdd` (a saída do `update` diz "updated from X to Y"). As mudanças de cada versão
estão no [CHANGELOG](../CHANGELOG.md). Ao subir de versão, reaplique também o `deny`/`ask` do
[template](../templates/project-settings.git.json) no `.claude/settings.json` do projeto, se o CHANGELOG avisar que mudou.

> **Ao subir da 0.7.x ou anterior para a 0.11.0 ou mais:** o agente `sdd:tecleader` foi renomeado para `sdd:techlead` na 0.8.0 e **removido** na 0.11.0. Troque
> `"agent": "sdd:tecleader"` por `"agent": "sdd:techlead"` no `.claude/settings.json` (ou no
> `.claude/settings.local.json`) e reinicie o Claude Code. Passo a passo no [CHANGELOG](../CHANGELOG.md).

## Problemas comuns

| Sintoma | Causa provável | Solução |
|---|---|---|
| `claude` não encontrado (Windows) | `%USERPROFILE%\.local\bin` fora do PATH | PowerShell: `$env:Path += ";$HOME\.local\bin"`; Git Bash: `export PATH="$PATH:$HOME/.local/bin"` |
| `Plugin "sdd" not found in marketplace` ao instalar | Marketplace não registrado nesta máquina, ou desatualizado | Rode o [passo 1](#1-instalar-na-máquina-uma-vez) (`marketplace add`); se já registrado, `claude plugin marketplace update claude-sdd-framework` (sem `ref`) ou o [passo C](#passo-c-já-registrado-sem-versão-ou-com-outra-versão) (com tag) |
| `Failed to add marketplace ... its source doesn't match its extraKnownMarketplaces entry in user or managed settings` | O seu `~/.claude/settings.json` já declara `claude-sdd-framework` sem `ref` (ou com outra versão) e o `add` usa outra fonte | Faça o [passo C do passo 1](#passo-c-já-registrado-sem-versão-ou-com-outra-versão): `add` sem `#` (C1) ou edite o `ref` da entrada e rode o `add` com o mesmo `#vX.Y.Z` (C2). Não use `marketplace remove` |
| Falha de clone ou de autenticação no `marketplace add` | Rede bloqueando o github.com (proxy/firewall/DNS) | Teste `git ls-remote https://github.com/powerlok/claude-sdd-framework.git`; ajuste a rede; nunca token na URL |
| Abri o `claude` e nada acontece | O Claude Code só responde depois da primeira mensagem (não existe primeiro turno automático para agente de plugin) | Digite `/sdd:start` (ou qualquer mensagem); o TechLead responde com a situação do projeto e pergunta se pode fazer o onboarding. O aviso de início do sdd lembra disso ao abrir |
| Resposta genérica, sem "Sou o TechLead" | Plugin não instalado no projeto; pasta não confiada; ou sessão aberta antes do install | Rode o `plugin install` na raiz; aceite o diálogo de confiança; `/reload-plugins` ou nova sessão |
| `/plugin` › Errors: "enabled in project settings but isn't installed here" | O settings foi copiado (ou veio pelo git), mas o plugin não foi instalado nesta máquina | `claude plugin install sdd@claude-sdd-framework --scope project` na raiz do projeto |
| A sessão abre sem o TechLead (ou avisa que o agente `sdd:tecleader` não existe) | O `settings` ainda aponta para o nome antigo, renomeado na 0.8.0 e removido na 0.11.0 | Troque `"agent": "sdd:tecleader"` por `"agent": "sdd:techlead"` no `.claude/settings.json` (ou `settings.local.json`) e reinicie (ou `/reload-plugins`) |
| Verificação de onboarding (hook) sem efeito no Windows | Git for Windows ausente (o hook usa `bash`) | Instale o Git for Windows; sem ele, o TechLead faz a mesma verificação lendo os arquivos |
| `git diff` mostra o `.claude/settings.json` alterado logo após o install | O `plugin install` reordena as chaves | Sem mudança de conteúdo; pode commitar ou descartar |
| A salinha dos agentes não abre | Preferência desligada, navegador padrão não definido ou Git Bash ausente | Rode `/sdd:office status` (se `off`, `/sdd:office on`); defina um navegador padrão; instale o Git for Windows (e confira que o `bash` do PATH não é o do WSL) |

Outros problemas: [Solução de problemas](manual-de-uso.html#problemas) no manual.
