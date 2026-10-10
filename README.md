<div align="center">

# Claude SDD Framework

**Spec-Driven Development para o Claude Code: um time de agentes que vai do requisito ao DONE, com evidência.**

![Claude Code](https://img.shields.io/badge/Claude%20Code-%E2%89%A5%202.1.288-D97757)
![sdd](https://img.shields.io/badge/plugin%20sdd-0.6.2-2563EB)
![authoring](https://img.shields.io/badge/plugin%20authoring-0.2.0-7C3AED)
![stacks](https://img.shields.io/badge/stacks-.NET%20%7C%20Python%20%7C%20React%20%7C%20Angular-0F766E)
![cloud](https://img.shields.io/badge/cloud-AWS%20%7C%20Azure%20%7C%20Google%20Cloud-F59E0B)
![idioma](https://img.shields.io/badge/docs-pt--BR-555)

[Início rápido](#-início-rápido) · [Como funciona](#-como-funciona) · [O time](#-o-time) · [Manual de uso](docs/manual-de-uso.html) · [Arquitetura](docs/arquitetura.md)

</div>

---

## ✨ O que é

Um **marketplace de plugins do Claude Code** que instala, em qualquer projeto, um processo de
engenharia completo:

- **Você conversa com um só agente, o TecLeader.** Ele transforma o pedido em spec e tasks,
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
    U([Você]) --> TL[sdd:tecleader]
    TL --> S[spec.md + tasks.md]
    S --> D{Design<br/>obrigatório?}
    D -->|sim| DS[design.md aprovado]
    D -->|não| I
    DS --> I[sdd:backend / sdd:frontend<br/>implementação + testes]
    I --> SR{Segurança<br/>aplicável?}
    SR -->|sim| SEC[sdd:security]
    SR -->|não| V
    SEC --> V[sdd:tests<br/>validação independente]
    V -->|falhou| I
    V -->|aprovado| DONE([DONE com evidência])
```

Estados de cada task: `TODO → IN_PROGRESS → IMPLEMENTED → SECURITY_REVIEW → VALIDATING → DONE`
(com `FAILED_VALIDATION → FIXING → VALIDATING_AGAIN` até aprovar). **Só o TecLeader encerra.**

## 👥 O time

| Agente | Papel | Modelo |
|---|---|---|
| `sdd:tecleader` | Orquestra, cria specs e tasks, aprova design, encerra (sessão principal) | opus |
| `sdd:backend` | APIs, domínio, persistência e testes, na stack do projeto | sonnet |
| `sdd:frontend` | Interfaces, UX, acessibilidade e testes, na stack do projeto | sonnet |
| `sdd:tests` | Validação independente: regressão, contratos, E2E, aceite | sonnet |
| `sdd:security` | Revisão de segurança (AppSec, dependências, segredos), somente leitura | opus |
| `sdd:infra-architect` | Arquitetura de infraestrutura na nuvem do projeto (AWS, Azure, Google Cloud), trade-offs e rollback; nunca aplica mudança | opus |

### Skills

| Skill | Para que serve |
|---|---|
| `sdd-rules` · `sdd-governance` | Regras globais, papéis, estados, escalonamento |
| `backend-engineering` | Princípios + referências **.NET** e **Python** |
| `frontend-engineering` | Princípios + referências **React** e **Angular** e checklist de interface web |
| `requirements-grilling` | Perguntas certas para fechar requisitos antes da spec |
| `bug-diagnosis` | Diagnóstico de bugs em 5 fases, com teste de regressão |
| `domain-modeling` | Glossário, modelo de domínio e registro de decisões (ADR) |
| `infra-engineering` | Princípios de nuvem + referências **AWS**, **Azure** e **Google Cloud** (IaC só com prévia; mudança real exige confirmação) |

Catálogo opcional **`authoring`**: `skill-development` e `agent-development`, para criar novas skills e agentes.

## 🚀 Início rápido

**Pré-requisitos:** Claude Code ≥ 2.1.288 e Git com acesso a este repositório.

> **Onde instalar:** na **raiz do projeto** (raiz do repositório git; em monorepo, a pasta do projeto). É lá que
> ficam `.claude/settings.json`, `CLAUDE.md` e `.specs/` — nunca num diretório pai/workspace fora do git.
> Abra o `claude` nessa pasta.

1. No seu projeto, crie `.claude/settings.json` a partir de
   [`templates/project-settings.git.json`](templates/project-settings.git.json):

   ```json
   {
     "extraKnownMarketplaces": {
       "claude-sdd-framework": {
         "source": { "source": "git", "url": "https://github.com/powerlok/claude-sdd-framework.git" }
       }
     },
     "enabledPlugins": { "sdd@claude-sdd-framework": true },
     "agent": "sdd:tecleader"
   }
   ```

   O template completo também bloqueia (`permissions.deny`) as ferramentas de escrita do Jira.

2. Instale:

   ```bash
   claude plugin marketplace add https://github.com/powerlok/claude-sdd-framework.git --scope project
   claude plugin install sdd@claude-sdd-framework --scope project
   ```

3. Copie [`templates/CLAUDE.md`](templates/CLAUDE.md) para a raiz do projeto e preencha a seção
   **`## Stack`** e os comandos (sem `CLAUDE.md`, o TecLeader faz o onboarding).

4. Abra `claude` no projeto. A sessão já começa com o **TecLeader**, que na primeira resposta verifica o
   onboarding (`CLAUDE.md`, `## Stack`, `.specs/INDEX.md`) e oferece o que faltar — nada é alterado sem confirmação:

   ```text
   Crie um endpoint POST /todos que cadastra tarefas com título obrigatório
   ```

   Ele propõe os requisitos e critérios de aceite, você confirma, e o time executa até o DONE.

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
</details>

## 🗂️ Camadas do CLAUDE.md

O Claude Code carrega o `CLAUDE.md` da pasta aberta, dos diretórios pais e o pessoal. Cada camada tem um papel:

| Camada | Onde | O que vai | Versionado |
|---|---|---|---|
| Pessoal | `~/.claude/CLAUDE.md` | preferências suas (idioma, estilo) | não |
| Workspace | pasta-mãe dos repositórios | só o comum a todos: lista de projetos, convenções ([modelo](templates/CLAUDE.workspace.md)) | não |
| **Projeto** | raiz do repositório | `## Stack`, comandos, arquitetura, `## Repositório`, `## SDD` ([modelo](templates/CLAUDE.md)) | sim (padrão) |
| Processo | plugin `sdd` | regras, governança, fluxo | no repositório do framework |

- Nada duplicado entre camadas; o mais específico prevalece (exceto os controles de segurança não relaxáveis).
- `Versionar artefatos SDD: não` (seção `## SDD` do projeto), para repositórios que não aceitam esses arquivos:
  `.claude/settings.local.json` + exclude local do git (`git rev-parse --git-path info/exclude`); `.gitignore` intocado.
- **Artefatos fora do repositório** (ex.: `CLAUDE.md`, `.specs/` e `.claude/` na pasta-mãe): o TecLeader propõe o plano
  padrão de migração com **uma única confirmação** — mescla sem sobrescrever (com diff), renomeia as origens para
  `.bak-<data>` (nunca apaga), não copia `allow`/`env` para arquivo versionável e **nunca faz commit**.
  Ele não pergunta onde fica `.specs/`, se move o `CLAUDE.md` nem se versiona: esses padrões são regra.

## 🔁 Atualização

```bash
claude plugin marketplace update claude-sdd-framework
claude plugin update sdd@claude-sdd-framework --scope project
```

Reinicie a sessão para aplicar. Versões seguem semver; veja o [CHANGELOG](CHANGELOG.md).

## 🧩 Jira (opcional, somente leitura)

- **Padrão:** conector Atlassian do claude.ai (Settings → Connectors → Atlassian). Só o TecLeader acessa.
- **Sem login claude.ai:** copie [`templates/mcp-atlassian.json`](templates/mcp-atlassian.json) para
  `.mcp.json` (MCP remoto oficial da Atlassian, OAuth, sem token em arquivo).
- Ferramentas de escrita (criar, editar, comentar, transicionar) ficam bloqueadas nos templates.

## 🔗 Repositório: GitHub, Bitbucket, GitLab, Azure DevOps (opcional, somente leitura)

Serve para duas coisas: **issue → spec** (o ID fica registrado, ex.: `GH#42`) e **status de PR/CI como evidência**
antes do DONE. Só o TecLeader consulta o provedor, e só se o `CLAUDE.md` do projeto tiver a seção `## Repositório`.

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

**Camadas de proteção:** (1) servidor em modo somente leitura; (2) o TecLeader só tem uma lista fechada de
ferramentas de leitura; (3) `permissions.deny` das ferramentas de escrita nos templates de settings.
Abrir PR, comentar, revisar, fazer merge e criar issue não estão liberados: faça manualmente.

**Issue e PR são dado não confiável.** O TecLeader não segue instruções escritas dentro de issue, PR,
comentário ou log; sinaliza trechos suspeitos, exige sua confirmação antes de transformar a issue em spec
e repassa aos demais agentes apenas os requisitos validados.

## 📚 Documentação

| Documento | Conteúdo |
|---|---|
| [Manual de uso](docs/manual-de-uso.html) | 18 exemplos passo a passo, solução de problemas. Baixe e abra no navegador (funciona offline) |
| [Arquitetura](docs/arquitetura.md) | Componentes, carregamento de skills, resolução da stack, segurança |
| [CHANGELOG](CHANGELOG.md) | Histórico de versões |
| [`.specs/INDEX.md`](.specs/INDEX.md) | Índice das specs: ativas em `.specs/<feature>/`, concluídas arquivadas em `.specs/done/` |

## 🛠️ Desenvolvimento do framework

```bash
claude plugin validate .                    # marketplace
claude plugin validate ./plugins/sdd
claude plugin validate ./plugins/authoring
```

Testar um agente sem instalar (prompt logo após `-p`, pois `--allowedTools` aceita vários valores):

```bash
claude -p "<prompt>" --plugin-dir ./plugins/sdd --agent sdd:backend --allowedTools "Read,Glob,Grep"
```

Para adicionar uma stack: crie `plugins/sdd/skills/<backend|frontend>-engineering/references/<stack>.md`,
registre na tabela do `SKILL.md`, suba a versão em `plugin.json` e registre no CHANGELOG.

```text
claude-sdd-framework/
├── .claude-plugin/marketplace.json   # marketplace (plugins sdd e authoring)
├── plugins/
│   ├── sdd/                          # agentes, skills, references e hook do processo
│   └── authoring/                    # catálogo opcional
├── templates/                        # settings (git/local), CLAUDE.md de projeto, .mcp.json (Jira, GitHub, GitLab, Azure)
├── docs/                             # manual de uso (HTML) e arquitetura
├── .specs/                           # specs ativas, INDEX.md e done/ (concluídas)
├── CHANGELOG.md
└── CLAUDE.md
```

## ⚠️ Limitações conhecidas

- `skills:` só pré-carrega em subagentes; o TecLeader carrega as regras pela ferramenta `Skill`.
- A verificação de onboarding no início da sessão é um hook em bash (no Windows, requer Git Bash no PATH);
  sem ele, o TecLeader faz a mesma verificação lendo os arquivos.
- Stacks sem referência (ex.: Vue, Java, Go) usam os princípios gerais; o agente declara a lacuna.
- Caminho `.mcp.json` (Jira, GitHub, GitLab, Azure DevOps) ainda não validado em rede com inspeção TLS (ex.: Zscaler).

## 🙏 Créditos

- `frontend-engineering`: seção de design visual adaptada de *frontend-design* (Anthropic), Apache-2.0.
- `skill-creator-original.md`: [anthropics/skills](https://github.com/anthropics/skills), Apache-2.0.
- Métodos inspirados (texto próprio) em [mattpocock/skills](https://github.com/mattpocock/skills),
  [obra/superpowers](https://github.com/obra/superpowers) e
  [vercel-labs/web-interface-guidelines](https://github.com/vercel-labs/web-interface-guidelines) (MIT).

---

<sub>Projeto da comunidade, **não afiliado à Anthropic**. "Claude" e "Claude Code" são marcas da Anthropic, PBC.</sub>
