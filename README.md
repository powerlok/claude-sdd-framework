<div align="center">

# Claude SDD Framework

**Spec-Driven Development para o Claude Code: um time de agentes que vai do requisito ao DONE, com evidência.**

![Claude Code](https://img.shields.io/badge/Claude%20Code-%E2%89%A5%202.1.288-D97757)
![sdd](https://img.shields.io/badge/plugin%20sdd-0.8.0-2563EB)
![authoring](https://img.shields.io/badge/plugin%20authoring-0.2.1-7C3AED)
![stacks](https://img.shields.io/badge/stacks-.NET%20%7C%20Python%20%7C%20React%20%7C%20Angular-0F766E)
![cloud](https://img.shields.io/badge/cloud-AWS%20%7C%20Azure%20%7C%20Google%20Cloud-F59E0B)
![idioma](https://img.shields.io/badge/docs-pt--BR-555)

[Início rápido](#-início-rápido) · [Primeiros passos](docs/primeiros-passos.md) · [Como funciona](#-como-funciona) · [O time](#-o-time) · [Manual de uso](docs/manual-de-uso.html) · [Arquitetura](docs/arquitetura.md) · [Salinha dos agentes](#-salinha-dos-agentes-opcional)

</div>

---

## ✨ O que é

Um **marketplace de plugins do Claude Code** que instala, em qualquer projeto, um processo de
engenharia completo:

- **Você conversa com um só agente, o TechLead.** Ele transforma o pedido em spec e tasks,
  delega aos especialistas e só encerra quando há evidência de que funciona.
- **Nada de implementação sem spec.** Requisito, critério de aceite e forma de validar vêm antes do código.
- **Agnóstico de linguagem.** Os agentes não têm stack fixa: a stack do projeto é declarada no
  `CLAUDE.md` e o conhecimento específico vem de referências (.NET, Python, React, Angular; infra: AWS, Azure, Google Cloud).
- **Segurança e qualidade embutidas.** Revisão de segurança quando aplicável, validação independente,
  regras que nenhum projeto pode relaxar (segredos, SSL, ações irreversíveis, menor privilégio).

> Testado com pilotos reais: a **mesma delegação** gerou uma API em ASP.NET Core (12/12 testes)
> e em FastAPI (13/13 testes), mudando apenas a stack declarada.

## 🔄 Como funciona

```mermaid
flowchart LR
    U([Você]) --> TL[sdd:techlead]
    TL --> S[spec.md + tasks.md]
    S --> D{Design<br/>obrigatório?}
    D -->|sim| DS[design.md aprovado]
    D -->|não| I
    DS --> I[sdd:backend / sdd:frontend / sdd:mobile<br/>implementação + testes]
    I --> SR{Segurança<br/>aplicável?}
    SR -->|sim| SEC[sdd:security]
    SR -->|não| V
    SEC --> V[sdd:tests<br/>validação independente]
    V -->|falhou| I
    V -->|aprovado| DONE([DONE com evidência])
```

Estados de cada task: `TODO → IN_PROGRESS → IMPLEMENTED → SECURITY_REVIEW → VALIDATING → DONE`
(com `FAILED_VALIDATION → FIXING → VALIDATING_AGAIN` até aprovar). **Só o TechLead encerra.**

## 👥 O time

| Agente | Papel | Modelo |
|---|---|---|
| `sdd:techlead` | Orquestra, cria specs e tasks, aprova design, encerra (sessão principal) | opus |
| `sdd:backend` | APIs, domínio, persistência e testes, na stack do projeto | sonnet |
| `sdd:frontend` | Interfaces, UX, acessibilidade e testes, na stack do projeto | sonnet |
| `sdd:mobile` | Apps mobile (React Native/Expo), acessibilidade, permissões e testes, na stack do projeto | sonnet |
| `sdd:tests` | Validação independente: regressão, contratos, E2E, aceite | sonnet |
| `sdd:security` | Revisão de segurança (AppSec, dependências, segredos), somente leitura | opus |
| `sdd:infra-architect` | Arquitetura de infraestrutura na nuvem do projeto (AWS, Azure, Google Cloud), trade-offs e rollback; nunca aplica mudança | opus |

### Skills

| Skill | Para que serve |
|---|---|
| `sdd-rules` · `sdd-governance` | Regras globais, papéis, estados, escalonamento |
| `backend-engineering` | Princípios + referências **.NET** e **Python** |
| `frontend-engineering` | Princípios + referências **React** e **Angular** e checklist de interface web |
| `mobile-engineering` | Princípios mobile + referência **React Native/Expo** (outras plataformas: sem referência, lacuna declarada) |
| `git-lang` | Comando `/sdd:git-lang pt\|en`: idioma de commits e PR (seção `## Git` do `CLAUDE.md`) |
| `requirements-grilling` | Perguntas certas para fechar requisitos antes da spec |
| `bug-diagnosis` | Diagnóstico de bugs em 5 fases, com teste de regressão |
| `domain-modeling` | Glossário, modelo de domínio e registro de decisões (ADR) |
| `infra-engineering` | Princípios de nuvem + referências **AWS**, **Azure** e **Google Cloud** (IaC só com prévia; mudança real exige confirmação) |

### Fluxo Git (opcional, por projeto)

Com a seção `## Git` no `CLAUDE.md` do projeto (modelo trunk-based, Conventional Commits, branch `<tipo>/<ISSUE>-<slug>`,
`Idioma: pt | en`, perguntado no onboarding), o `sdd:techlead` pode criar a **branch** e **commits locais**, sempre
**depois da sua confirmação** (mostra antes branch, mensagem e lista explícita de arquivos). Ele nunca faz `push`,
`merge`, `rebase`, `--force` nem `--no-verify`; o texto do PR é entregue a você para abrir manualmente. Sem a seção
`## Git`, nada é criado. Convenções: `skills/sdd-rules/references/git-workflow.md`. Troque o idioma com
`/sdd:git-lang pt` ou `/sdd:git-lang en`. O `templates/project-settings.git.json` nega por padrão operações destrutivas
(`git reset --hard`, `git clean -f*`, `git commit --no-verify`, `git branch -D`, `git config*` etc.).

Catálogo opcional **`authoring`**: `skill-development` e `agent-development`, para criar novas skills e agentes.

## 🚀 Início rápido

**Pré-requisitos:** Claude Code ≥ 2.1.288 e Git com acesso a este repositório (teste:
`git ls-remote https://github.com/powerlok/claude-sdd-framework.git`). No Windows, também Git for Windows.

1. **Uma vez por máquina**, registre o marketplace na versão desejada (tag):

   ```bash
   claude plugin marketplace add "https://github.com/powerlok/claude-sdd-framework.git#v0.7.0"
   ```

2. **Na raiz do projeto** (raiz do repositório git; em monorepo, a pasta do projeto; nunca uma pasta-mãe fora do git),
   copie o arquivo **inteiro**
   [`templates/project-settings.git.json`](templates/project-settings.git.json) para `.claude/settings.json`
   (veja as [proteções do template](#-proteções-do-template)).

3. Instale o plugin no projeto e confira com `claude plugin list` (`sdd` 0.7.0, `project`, `enabled`):

   ```bash
   claude plugin install sdd@claude-sdd-framework --scope project
   ```

4. Abra `claude` na raiz do projeto e aceite o diálogo de confiança da pasta. A primeira resposta é do **TechLead**,
   que verifica o onboarding e, se faltar `CLAUDE.md`, oferece criá-lo (lendo o código ou perguntando a stack) — nada é
   alterado sem confirmação. Depois, faça o primeiro pedido:

   ```text
   Crie um endpoint POST /todos que cadastra tarefas com título obrigatório
   ```

**Guia completo** (código existente × projeto do zero, o que você vai ver, o que versionar, equipe, problemas comuns):
[docs/primeiros-passos.md](docs/primeiros-passos.md).

> **Credenciais:** o Claude Code usa o git da sua máquina. Nunca coloque usuário, senha ou token na URL
> (`https://user:token@...`); use SSH ou o gerenciador de credenciais do git.

<details>
<summary><b>Instalar a partir de um clone local</b></summary>

Use [`templates/project-settings.local.json`](templates/project-settings.local.json), troque o placeholder
pelo caminho do clone (com `/`) e rode:

```bash
claude plugin marketplace add "<caminho>/claude-sdd-framework" --scope project
claude plugin install sdd@claude-sdd-framework --scope project
```
</details>

<details>
<summary><b>Instalar o catálogo opcional <code>authoring</code></b></summary>

```bash
claude plugin install authoring@claude-sdd-framework --scope project
```
</details>

<details>
<summary><b>Windows: <code>claude</code> não encontrado</b></summary>

O instalador nativo coloca o `claude.exe` em `%USERPROFILE%\.local\bin`. No PowerShell:

```powershell
$env:Path += ";$HOME\.local\bin"
```

No Git Bash:

```bash
export PATH="$PATH:$HOME/.local/bin"
```
</details>

<details>
<summary><b>Preencher o <code>CLAUDE.md</code> à mão (opcional)</b></summary>

Em vez do onboarding pelo TechLead, copie [`templates/CLAUDE.md`](templates/CLAUDE.md) para a raiz do projeto e
preencha a seção **`## Stack`** e os comandos. O TechLead confere o que faltar.
</details>

## 🔒 Proteções do template

[`templates/project-settings.git.json`](templates/project-settings.git.json) declara o marketplace
(`extraKnownMarketplaces`), habilita o plugin (`enabledPlugins`) e define `"agent": "sdd:techlead"`. Por isso copie o
arquivo inteiro: o template também bloqueia (`permissions.deny`) as ferramentas de escrita do Jira e dos provedores de
repositório; a leitura de segredos (`.env`/`.env.*`, também na edição, exceto `.env.example`/`.sample`/`.template`;
chaves e certificados; credenciais de npm, PyPI, git e `netrc`; estado e variáveis do Terraform; e, na home,
`~/.ssh`, `~/.aws`, `~/.azure`, `~/.config/gh`, `~/.kube`, `~/.docker/config.json`); e as formas usuais de push
forçado/destrutivo (`--force*`, `-f`, `+refspec`, `--mirror`, `--delete`/`-d`). Push comum pede confirmação
(`permissions.ask`).

**Versão fixada:** o template fixa a versão com `"ref"` (tag, ex.: `"ref": "v0.7.0"`). Para subir de versão: troque o
`ref` pela nova tag e rode `claude plugin marketplace update claude-sdd-framework` e
`claude plugin update sdd@claude-sdd-framework --scope project`. Sem `ref`, vale a branch padrão do repositório
(sempre a última versão).

> **Limites:** o deny é defesa em profundidade, não barreira. O deny de `Read` cobre as ferramentas de arquivo e os
> comandos de arquivo que o Claude Code reconhece no Bash (`cat`, `head`, `tail`, `sed`, `tee`, redirecionamentos),
> mas não um `grep -r` sem citar o arquivo nem um script (Python, Node) que abre o arquivo por conta própria. Padrões
> `**/` valem a partir da pasta onde a sessão começou; arquivos da home usam `~/`. O deny de `Bash` não pega o mesmo
> comando escrito de outro jeito (`sh -c '...'`, caminho absoluto do programa, `git -C . push`); flags combinadas
> (`-uf`) e `:refspec` caem só na confirmação (`ask`). No Windows sem Git Bash (ferramenta PowerShell), as regras
> `Bash(...)` não se aplicam ao PowerShell. Para bloqueio no
> sistema operacional, use o [sandbox](https://code.claude.com/docs/en/sandboxing) do Claude Code
> ([permissões](https://code.claude.com/docs/en/permissions)).

## 🗂️ Camadas do CLAUDE.md

O Claude Code carrega o `CLAUDE.md` da pasta aberta, dos diretórios pais e o pessoal. Cada camada tem um papel:

| Camada | Onde | O que vai | Versionado |
|---|---|---|---|
| Pessoal | `~/.claude/CLAUDE.md` | preferências suas (idioma, estilo) | não |
| Workspace | pasta-mãe dos repositórios | só o comum a todos: lista de projetos, convenções ([modelo](templates/CLAUDE.workspace.md)) | não |
| **Projeto** | raiz do repositório | `## Stack`, comandos, arquitetura, `## Repositório`, `## SDD` ([modelo](templates/CLAUDE.md)) | sim (padrão) |
| Processo | plugin `sdd` | regras, governança, fluxo | no repositório do framework |

- Nada duplicado entre camadas. Os `CLAUDE.md` são **concatenados** (sem sobreposição automática); em conflito, o agente
  aplica o mais específico e sinaliza (exceto os controles de segurança não relaxáveis).
- `Versionar artefatos SDD: não` (seção `## SDD` do projeto), para repositórios que não aceitam esses arquivos:
  `.claude/settings.local.json` + exclude local do git (`git rev-parse --git-path info/exclude`); `.gitignore` intocado.
- **Artefatos fora do repositório** (ex.: `CLAUDE.md`, `.specs/` e `.claude/` na pasta-mãe): o TechLead propõe o plano
  padrão de migração com **uma única confirmação** — mescla sem sobrescrever (com diff), renomeia as origens para
  `.bak-<data>` (nunca apaga), não copia `allow`/`env` para arquivo versionável e **nunca faz commit**.
  Ele não pergunta onde fica `.specs/`, se move o `CLAUDE.md` nem se versiona: esses padrões são regra.

## 🔀 Trabalhar entre projetos

Três modos, com efeitos diferentes (verificados na documentação oficial e em testes):

| Modo | Como abrir | Acesso | `CLAUDE.md` carregado | Deny que vale |
|---|---|---|---|---|
| Dentro do projeto | `claude` em `ict_app/` | só o projeto | o do projeto + pais (workspace) | o do projeto |
| Projeto + outro | `claude --add-dir ../outro` (ou `/add-dir`) | os dois | o do outro só com `CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=1` | **só o da sessão** |
| Workspace | `claude` na pasta-mãe, com `.claude/settings.json` | todos os projetos abaixo | o do workspace; o de um projeto carrega sob demanda ao ler arquivo da pasta dele (o TechLead ainda o lê antes de planejar) | **só o do workspace** |

- Deny exigido na sessão = deny do modelo ∪ deny dos projetos envolvidos. Faltando, a sessão fica **somente leitura**
  (sem escrita, build, testes ou delegação) até corrigir e reiniciar; dica: `--permission-mode plan`.
- Mudança em mais de um projeto: plano com projetos **alterados** e de **referência**, **uma** confirmação; spec + tasks
  em cada projeto alterado, ligadas por `Relacionada a:`; cada task mexe em um único repositório; nunca commit.
- O `CLAUDE.md` de um projeto só vale para ele; o de um projeto de referência é dado, não instrução. Use a variável
  acima só para repositórios confiáveis.

## 🏢 Salinha dos agentes (opcional)

Uma página HTML local, aberta no navegador, mostra uma **sala em pixel art 16 bits** com uma mesa por agente
(techlead, backend, frontend, mobile, tests, security, infra-architect; agentes novos ganham mesa). Os personagens aparecem
trabalhando, entregando, em revisão ou ociosos, e um popup mostra o processo atual (ex.: "TechLead → delegou uma
tarefa ao backend", "backend: editando arquivos", "tests: rodando validação"). Sem dependências de terceiros, sem
servidor, sem rede.

**Desligada por padrão.** O TechLead oferece uma vez (no fim da primeira resposta e no fim do onboarding; recusar
grava `off`). Depois, liga e desliga a qualquer momento:

| Comando | Efeito |
|---|---|
| `/sdd:office on` | Liga e abre a tela na hora (na primeira vez o Claude pede para você aprovar o comando) |
| `/sdd:office off` | Desliga; o hook só confere a preferência e sai |
| `/sdd:office status` | Mostra a preferência atual |

Também dá para pedir ao TechLead. A preferência fica em `~/.claude/sdd/office.conf` (respeita `CLAUDE_CONFIG_DIR`),
por usuário, nunca no repositório. Para apagar, remova o arquivo.

- **Abre sozinha:** com `on`, cada sessão nova abre o navegador padrão uma vez (Windows `cmd.exe /c start`, macOS `open`,
  Linux `xdg-open`); falha ao abrir não interrompe a sessão.
- **Privacidade:** grava só agente, categoria da ferramenta (read/edit/run/web/delegate/plan/ask/mcp/other), agente de
  destino da delegação, tipo do evento, horário e a descrição curta da delegação (caminhos, termos de segredo e senhas
  viram `[omitido]`). Nunca grava conteúdo de arquivos, comandos, prompts, saídas ou caminhos. Os arquivos ficam na
  pasta temporária do sistema (`sdd-office-<uid>/<sala>/`), nunca no repositório; a sala é por projeto (hash do caminho).
- **Custo:** os hooks usam `"async": true`; no Windows cada hook abre um bash (~165 ms) fora do caminho crítico. Em
  versão do CLI sem suporte a `async`, cada hook bloquearia ~165 ms por evento.
- **Limites:** exige bash (Git Bash no Windows; atenção ao bash do WSL no PATH) e navegador moderno. Validada em Chrome 155
  e Edge 154 no Windows, com Claude Code 2.1.296; **não testada** em macOS, Linux nem Firefox. A página usa `file://` com
  reinjeção de script a cada 1 s: política corporativa que bloqueie `file://` impede a atualização (a página avisa).
  Tem botão "Pausar animação" e respeita `prefers-reduced-motion`.
- **Segurança:** revisada em 3 voltas (aprovada); 363 testes (shell + página).

## 🔁 Atualização

```bash
claude plugin marketplace update claude-sdd-framework
claude plugin update sdd@claude-sdd-framework --scope project
```

Reinicie a sessão para aplicar. Versões seguem semver; veja o [CHANGELOG](CHANGELOG.md).

> **0.8.0 (mudança incompatível):** `sdd:tecleader` foi renomeado para `sdd:techlead`. Troque
> `"agent": "sdd:tecleader"` por `"agent": "sdd:techlead"` no `.claude/settings.json` (ou `settings.local.json`) e
> reinicie. Até lá, a sessão abre com um agente obsoleto que só mostra essa instrução (removido na versão seguinte).

## 🧩 Jira (opcional, somente leitura)

- **Padrão:** conector Atlassian do claude.ai (Settings → Connectors → Atlassian). Só o TechLead acessa.
- **Sem login claude.ai:** copie [`templates/mcp-atlassian.json`](templates/mcp-atlassian.json) para
  `.mcp.json` (MCP remoto oficial da Atlassian, OAuth, sem token em arquivo).
- Ferramentas de escrita (criar, editar, comentar, transicionar) ficam bloqueadas nos templates.

## 🔗 Repositório: GitHub, Bitbucket, GitLab, Azure DevOps (opcional, somente leitura)

Serve para duas coisas: **issue → spec** (o ID fica registrado, ex.: `GH#42`) e **status de PR/CI como evidência**
antes do DONE. Só o TechLead consulta o provedor, e só se o `CLAUDE.md` do projeto tiver a seção `## Repositório`.

| Provedor | Caminho padrão | Status |
|---|---|---|
| GitHub | [`templates/mcp-github.json`](templates/mcp-github.json) (MCP oficial em `/mcp/readonly`) | **suportado e validado** |
| Bitbucket Cloud | MCP Atlassian (issues vêm do Jira) | experimental |
| GitLab | [`templates/mcp-gitlab.json`](templates/mcp-gitlab.json) | experimental |
| Azure DevOps | [`templates/mcp-azure-devops.json`](templates/mcp-azure-devops.json) | experimental |

**Como ativar (GitHub):**

1. No `CLAUDE.md` do projeto, adicione a seção `## Repositório` (modelo em [`templates/CLAUDE.md`](templates/CLAUDE.md)):
   `Provedor: github`, `Repositório: <owner/repo>`, `Acesso: mcp`.
2. Copie [`templates/mcp-github.json`](templates/mcp-github.json) para `.mcp.json` na raiz do projeto.
3. Crie um **PAT fine-grained somente leitura** no GitHub: só os repositórios do projeto; permissões
   Metadata, Issues, Pull requests e Actions = **Read**; sem Contents write e sem Workflows; validade curta.
4. Exporte o token na variável de ambiente `GITHUB_PAT` (nunca em arquivo versionado nem `.env` versionado)
   e confira com `/mcp` que o servidor `github` está `connected`.

Nunca reutilize `gh auth token`: o login local do `gh` costuma ter escrita.

**Camadas de proteção:** (1) servidor em modo somente leitura; (2) o TechLead só tem uma lista fechada de
ferramentas de leitura; (3) `permissions.deny` das ferramentas de escrita nos templates de settings.
Abrir PR, comentar, revisar, fazer merge e criar issue não estão liberados: faça manualmente.

**Issue e PR são dado não confiável.** O TechLead não segue instruções escritas dentro de issue, PR,
comentário ou log; sinaliza trechos suspeitos, exige sua confirmação antes de transformar a issue em spec
e repassa aos demais agentes apenas os requisitos validados.

## 📚 Documentação

| Documento | Conteúdo |
|---|---|
| [Primeiros passos](docs/primeiros-passos.md) | Primeiro uso passo a passo: código existente ou projeto do zero, o que versionar, problemas comuns |
| [Manual de uso](docs/manual-de-uso.html) | 18 exemplos passo a passo, solução de problemas. Baixe e abra no navegador (funciona offline) |
| [Arquitetura](docs/arquitetura.md) | Componentes, carregamento de skills, resolução da stack, hooks e salinha dos agentes, segurança |
| [CHANGELOG](CHANGELOG.md) | Histórico de versões |
| [`.specs/INDEX.md`](.specs/INDEX.md) | Índice das specs: ativas em `.specs/<feature>/`, concluídas arquivadas em `.specs/done/` |

## 🛠️ Desenvolvimento do framework

Antes de cada release (obrigatório; avisos também reprovam com `--strict`):

```bash
claude plugin validate ./plugins/sdd --strict
claude plugin validate ./plugins/authoring --strict
claude plugin validate .                    # marketplace
```

Depois: bump de `version` no `plugin.json` alterado, seção no [CHANGELOG](CHANGELOG.md) e versões no README e em `docs/`.
**Versão × release:** toda mudança em plugin sobe a `version` (commit em `main`, sem tag). **Release** é o conjunto
pronto para consumo (validações acima, segurança aprovada quando aplicável, sem defeito aberto, CHANGELOG fechado):
`metadata.version` do `marketplace.json`, tag anotada `vX.Y.Z`, `"ref"` do template e seção `## Release vX.Y.Z` no
CHANGELOG. A tag versiona o marketplace inteiro; só é criada com confirmação. Detalhes em [CLAUDE.md](CLAUDE.md).

Testar um agente sem instalar (prompt logo após `-p`, pois `--allowedTools` aceita vários valores):

```bash
claude -p "<prompt>" --plugin-dir ./plugins/sdd --agent sdd:backend --allowedTools "Read,Glob,Grep"
```

Para adicionar uma stack: crie `plugins/sdd/skills/<backend|frontend|mobile>-engineering/references/<stack>.md`,
registre na tabela do `SKILL.md`, suba a versão em `plugin.json` e registre no CHANGELOG.

```text
claude-sdd-framework/
├── .claude-plugin/marketplace.json   # marketplace (plugins sdd e authoring)
├── plugins/
│   ├── sdd/                          # agentes, skills, references e hook do processo
│   └── authoring/                    # catálogo opcional
├── templates/                        # settings (git/local), CLAUDE.md de projeto, .mcp.json (Jira, GitHub, GitLab, Azure)
├── docs/                             # primeiros passos, manual de uso (HTML) e arquitetura
├── .specs/                           # specs ativas, INDEX.md e done/ (concluídas)
├── CHANGELOG.md
└── CLAUDE.md
```

## ⚠️ Limitações conhecidas

- `skills:` só pré-carrega em subagentes; o TechLead carrega as regras pela ferramenta `Skill`.
- A verificação de onboarding no início da sessão é um hook em bash (no Windows, requer Git Bash no PATH);
  sem ele, o TechLead faz a mesma verificação lendo os arquivos.
- Stacks sem referência (ex.: Vue, Java, Go) usam os princípios gerais; o agente declara a lacuna.
- A salinha dos agentes (opcional) só foi validada no Windows (Chrome e Edge); macOS, Linux e Firefox não foram testados.
- Caminho `.mcp.json` (Jira, GitHub, GitLab, Azure DevOps) ainda não validado em rede com inspeção TLS (ex.: Zscaler).

## 📄 Licença

[MIT](LICENSE). O material de terceiros em `plugins/authoring/skills/skill-development/references/`
(`skill-creator-original.md`) segue a Apache-2.0 ([LICENSE.txt](plugins/authoring/skills/skill-development/references/LICENSE.txt)).

## 🙏 Créditos

- `frontend-engineering`: seção de design visual adaptada de *frontend-design* (Anthropic), Apache-2.0.
- `skill-creator-original.md`: [anthropics/skills](https://github.com/anthropics/skills), Apache-2.0.
- Métodos inspirados (texto próprio) em [mattpocock/skills](https://github.com/mattpocock/skills),
  [obra/superpowers](https://github.com/obra/superpowers) e
  [vercel-labs/web-interface-guidelines](https://github.com/vercel-labs/web-interface-guidelines) (MIT).

---

<sub>Projeto da comunidade, **não afiliado à Anthropic**. "Claude" e "Claude Code" são marcas da Anthropic, PBC.</sub>
