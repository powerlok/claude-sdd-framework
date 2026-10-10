# Design técnico: Plugin SDD compartilhável (T-001)

Status: **APROVADO** pelo usuário em 2026-10-09 (após spike, ver spike-result.md).
Base: [spec.md](spec.md), [research-t000.md](research-t000.md).

## 1. Objetivo

Distribuir o processo SDD (agentes, regras, skills, hook) como um plugin do Claude Code
instalável por marketplace (local agora, Bitbucket depois), com agentes agnósticos de
linguagem e conhecimento de stack em skills com `references/`.

## 2. Impacto arquitetural

| Hoje (`workshop/.claude/`) | Depois (plugin `sdd`) |
|---|---|
| Regras em `CLAUDE.md` + `rules/global.md` (carregadas pelo Claude Code) | Skills do plugin pré-carregadas via `skills:` (plugin não distribui CLAUDE.md/rules — T-000 #1) |
| Agentes `*.agent.md`, nome `backend` | `agents/backend.md`, nome `sdd:backend` (T-000 #8) |
| Stack fixa no texto do agente (Python/FastAPI, React/Vite) | Stack declarada no `CLAUDE.md` do projeto; conhecimento em `references/` |
| Nenhum agente usa skills | Skills pré-carregadas por agente (tabela 4.3) |
| Hook pós-compact em `.claude/settings.json` | `hooks/hooks.json` do plugin |
| `"agent": "tecleader"` no settings do workspace | `"agent": "sdd:tecleader"` no settings do projeto (**revalidar no spike**) |

O `CLAUDE.md` de cada projeto continua local (criado pelo onboarding do `tecleader`) e
prevalece sobre as regras do plugin no que for mais específico.

## 3. Estrutura do repositório `engineering-workflow`

```text
engineering-workflow/
├── .claude-plugin/
│   └── marketplace.json          # marketplace "engineering-workflow": plugins sdd e authoring
├── plugins/
│   ├── sdd/                      # plugin do processo (instalação padrão)
│   │   ├── .claude-plugin/plugin.json      # name: sdd, version semver
│   │   ├── agents/               # tecleader, backend, frontend, tests, security, infra-architect
│   │   ├── skills/
│   │   │   ├── sdd-rules/        # regras globais (hoje rules/global.md) + references/
│   │   │   ├── sdd-governance/   # papéis, estados, delegação, Jira (hoje CLAUDE.md do workspace)
│   │   │   ├── backend-engineering/   # princípios + references/dotnet.md, python.md
│   │   │   ├── frontend-engineering/  # princípios + references/react.md, web-interface.md (angular.md depois)
│   │   │   ├── requirements-grilling/
│   │   │   ├── bug-diagnosis/
│   │   │   └── domain-modeling/
│   │   └── hooks/hooks.json      # SessionStart/compact: reler spec.md e tasks.md
│   └── authoring/                # catálogo (opcional): skill-development, agent-development
├── templates/
│   ├── project-settings.local.json  # settings modelo: marketplace em diretório local
│   ├── project-settings.git.json    # settings modelo: marketplace em repo git (Bitbucket)
│   ├── mcp-atlassian.json        # .mcp.json opcional (MCP remoto oficial Atlassian v2)
│   └── CLAUDE.md                 # modelo de CLAUDE.md de projeto (com seção Stack)
├── CHANGELOG.md
└── README.md
```

## 4. Componentes

### 4.1 Regras (REQ-002)

- `sdd-rules`: conteúdo de `rules/global.md`. Corpo principal enxuto (fluxo, escopo,
  qualidade, segurança, evidências, encerramento); detalhes em `references/`
  (`readme.md`, `final-run.md`, `reproducibility.md`). Pré-carregada em **todos** os agentes.
- `sdd-governance`: conteúdo do `CLAUDE.md` do workspace (papéis, estados, correção,
  escalonamento, Jira). Pré-carregada só no `tecleader`.
- Meta de tamanho: corpo de cada skill pré-carregada ≤ ~250 linhas
  (hoje: 403 + 415 linhas; janela dos agentes sonnet é 200k).

### 4.2 Agentes agnósticos (REQ-003, REQ-004)

- `backend`/`frontend`: sem nome de linguagem/framework. Mantêm princípios
  (DDD, SOLID, TDD, segurança, acessibilidade, performance) e o contrato de entrega.
- Fonte da stack: seção `## Stack` do `CLAUDE.md` do projeto (template em `templates/CLAUDE.md`).
- O `tecleader` inclui na delegação um campo novo:
  `Stack: <linguagem/framework/versão> — referência: <skill>/references/<stack>.md`.
- Sem referência para a stack: o agente aplica os princípios gerais,
  declara a lacuna no relato e o `tecleader` registra como observação.
- Delegação usa os nomes com prefixo (`sdd:backend` etc.).

### 4.3 Skills pré-carregadas por agente (REQ-005, REQ-007)

| Agente | `skills:` |
|---|---|
| tecleader | **não pré-carrega** (agente da sessão principal; ver nota) |
| backend | sdd-rules, backend-engineering, bug-diagnosis, domain-modeling |
| frontend | sdd-rules, frontend-engineering, bug-diagnosis |
| tests | sdd-rules, bug-diagnosis (fase de reprodução determinística) |
| security | sdd-rules |
| infra-architect | sdd-rules, domain-modeling (critério de ADR) |

`references/` não são pré-carregadas: o agente lê só a da stack informada.

Nota (spike, [spike-result.md](spike-result.md)): `skills:` só pré-carrega em subagentes.
No agente da sessão principal, o `tecleader`:
- mantém no próprio corpo a governança essencial (fluxo, estados, delegação, DONE);
- tem `Skill` em `tools:` e carrega `sdd:sdd-rules`, `sdd:sdd-governance` e
  `sdd:requirements-grilling` no início da sessão e após compact (o hook reforça).

### 4.4 Skills de frontend atuais (REQ-006)

| Skill atual | Destino |
|---|---|
| react-performance | `frontend-engineering/references/react.md` (sem links para `.agents/`, sem citar outro projeto) |
| web-design-guidelines | `frontend-engineering/references/web-interface.md`, regras vendorizadas com origem/licença; sem fetch em tempo de uso |
| frontend-design | princípios visuais no corpo de `frontend-engineering`, respeitando `LICENSE.txt` |
| skill-development, agent-development | plugin `authoring` (catálogo, REQ-008) |

Os arquivos em `workspace/.claude/skills/` **não são removidos** neste ciclo (fora de escopo).

### 4.5 Métodos de terceiros (REQ-007)

- Antes de copiar qualquer trecho: verificar licença do repositório de origem
  (mattpocock/skills, obra/superpowers). Licença ausente ou incompatível:
  reescrever o método com texto próprio e citar só a inspiração.
- Cada skill traz no rodapé: `Origem: <repo>@<commit> — Licença: <SPDX>`.

### 4.6 Hook

`hooks/hooks.json`: `SessionStart` com matcher `compact`, apenas `echo` (sem script,
sem rede). Mesmo comportamento do workspace. **Revalidar no spike.**

### 4.7 Jira

Continua opcional e somente leitura, apenas no `tecleader`. Dois caminhos:

| Caminho | Quando usar | Ferramentas |
|---|---|---|
| Conector claude.ai Atlassian (**padrão**) | dev com login claude.ai; conexão sai do lado da Anthropic (menos exposto ao Zscaler) | `mcp__claude_ai_Atlassian__*` |
| `.mcp.json` com o MCP remoto oficial da Atlassian (**opcional, desligado por padrão**) | dev sem login claude.ai (API key, Bedrock, Vertex); OAuth por usuário, sem token em arquivo | `mcp__atlassian__*` |

- O `tools:` do `tecleader` lista os dois conjuntos, só com ferramentas de leitura
  confirmadas no spike: `atlassianUserInfo`, `getAccessibleAtlassianResources`,
  `getJiraIssue`, `searchJiraIssuesUsingJql`.
- O `.mcp.json` fica como modelo em `templates/` (o dev copia para o projeto se precisar),
  não vai ativo no plugin. Endpoint `https://mcp.atlassian.com/v2/mcp` (OAuth 2.1), confirmado na doc oficial Atlassian na T-006.
- Pendente: teste do caminho `.mcp.json` numa máquina **com Zscaler ativo**
  (a do usuário está inativa e não representa os colegas). Falhou → documentar e manter só o conector.
- Nomes `mcp__claude_ai_Atlassian__*` em agente de plugin: confirmados no spike (busca JQL OK).

Decisão do usuário (2026-10-09): manter o conector claude.ai como padrão e oferecer `.mcp.json` como opção.

## 5. Contratos

- `marketplace.json`: `name: engineering-workflow`, `owner.name`, `plugins[]` com
  `{name: sdd, source: ./plugins/sdd}` e `{name: authoring, source: ./plugins/authoring}`.
- `plugin.json`: `name`, `version` (semver), `description`.
- Projeto consumidor (`templates/project-settings.local.json` / `.git.json`), formato confirmado no spike e na doc (marketplace-reference):

```json
{
  "extraKnownMarketplaces": {
    "engineering-workflow": { "source": { "source": "directory", "path": "<caminho local>" } }
  },
  "enabledPlugins": { "sdd@engineering-workflow": true },
  "agent": "sdd:tecleader"
}
```

Depois do Bitbucket: `source` passa a `{"source": "git", "url": "<url do repo>"}`.

## 6. Versionamento e atualização

- `version` semver no `plugin.json`; `CHANGELOG.md` por versão.
- MAJOR: muda contrato de delegação, nomes de agentes ou estados.
  MINOR: nova skill/referência. PATCH: texto/correção.
- Devs atualizam com `/plugin update` (auto-update desligado por padrão).

## 7. Migração do workspace

1. Construir e validar o plugin sem tocar em `workspace/.claude/`.
2. Pilotos em projetos de teste **fora** do workspace (o `CLAUDE.md` do workspace seria
   herdado por subpastas e contaminaria o teste).
3. Após T-008 aprovado, propor ao usuário trocar o workspace para o plugin e remover
   os duplicados — **somente com confirmação explícita**.

## 8. Riscos

| Risco | Mitigação |
|---|---|
| `"agent": "sdd:tecleader"` não funcionar no settings do projeto | Spike; alternativa `claude --agent sdd:tecleader`; plano B (kit + script) |
| Formato de `extraKnownMarketplaces` diferente | Spike; alternativa `/plugin marketplace add <caminho>` manual |
| Contexto alto com skills pré-carregadas | Corpo enxuto + `references/`; medir com `/context` no piloto |
| Delegação com nome errado (`backend` vs `sdd:backend`) | Teste no spike (lead → worker) |
| Conteúdo de terceiros sem licença compatível | Reescrita própria; revisão do `security` (T-007) |
| Hook executando comando em máquina de outros devs | Apenas `echo`; revisão do `security` |
| Agentes do workspace e do plugin ativos ao mesmo tempo | Nomes distintos; pilotos fora do workspace |

## 9. Estratégia de implementação

T-002 (agentes) → T-003/T-004/T-005 em paralelo (skills) → T-006 (marketplace, templates,
catálogo) → T-007 (security) → T-008 (tests) → T-009 (README).
Ordem condicionada ao resultado do spike (seção 11).

## 10. Estratégia de testes

- Estrutura: `claude plugin validate` no marketplace e em cada plugin.
- Instalação: projeto de teste limpo com `templates/project-settings.local.json`.
- Comportamento: tokens marcadores nas skills/referências para provar o carregamento.
- Piloto Python e .NET: mesma tarefa (CRUD com teste), evidência de leitura da referência.
- Regressão: `app-workshop` (`npm test`, `npm run build`, `npm run e2e`) com os agentes do plugin.
- Segurança: revisão de hooks, templates e conteúdo vendorizado.

## 11. Spike (parte da T-001)

Plugin mínimo em `spike/` (removido em 2026-10-09 com confirmação do usuário; resultados preservados em spike-result.md).
Responde aos itens "Revalidar" da T-000:

| Item T-000 | Verificação |
|---|---|
| #2 agente principal | sessão abre como `sdd-spike:lead` via settings do projeto |
| #3 `skills:` em agente | lead e worker citam o token da skill pré-carregada |
| #4 MCP | lead lista projetos do Jira (se o conector estiver autenticado) |
| #6 settings do projeto | marketplace/plugin sugeridos e habilitados pelo settings |
| #9 hook compact | mensagem do hook aparece após `/compact` |
| #10 references | worker lê `references/dotnet.md` e cita o token |
| delegação | lead chama `sdd-spike:worker` |

Resultado registrado em `spike-result.md`. Falha em #2 ou #6 sem alternativa aceitável → plano B.

## 12. Glossário

- **Plugin**: pacote de agentes/skills/hooks instalável.
- **Marketplace**: catálogo de plugins (diretório local ou repo git).
- **Pré-carregada**: skill listada em `skills:` do agente, injetada no início da execução.
- **Referência de stack**: arquivo em `references/` lido sob demanda conforme a stack do projeto.
