# Arquitetura do plugin `sdd`

Este documento explica como o marketplace `claude-sdd-framework` e o plugin `sdd` funcionam por dentro:
componentes, fluxo SDD, agentes, skills, carregamento, hooks, segurança e limitações.
Público: devs do time que vão usar e manter o plugin.

- Manual de uso com exemplos passo a passo: [manual-de-uso.html](manual-de-uso.html)
- Instalação, atualização e comandos: [README](../README.md)
- Histórico de versões: [CHANGELOG](../CHANGELOG.md)
- Decisões de design: [.specs/done/sdd-plugin/design.md](../.specs/done/sdd-plugin/design.md)

Os diagramas usam [Mermaid](https://mermaid.js.org/), que renderiza no GitHub, no Bitbucket e no preview de Markdown do VS Code.

## 1. Visão geral

O plugin `sdd` distribui um time de engenharia com papéis fixos. Toda solicitação passa por um orquestrador
(`sdd:tecleader`), que organiza o trabalho e delega para agentes especializados. O desenvolvimento segue
**SDD** (Spec-Driven Development): nada é implementado sem requisito, critério de aceite e forma de validação.

Os agentes não dependem de linguagem: a stack de cada projeto vem da seção `## Stack` do `CLAUDE.md` do projeto,
e o conhecimento específico de cada stack fica em `references/` dentro das skills.

```mermaid
flowchart TD
    U([Usuário]) -->|solicitação| TL

    subgraph ORQ[Orquestração]
        TL[sdd:tecleader<br/>opus · agente da sessão principal]
    end

    subgraph IMP[Implementadores · sonnet]
        BE[sdd:backend]
        FE[sdd:frontend]
    end

    subgraph SEC[Revisão de segurança · opus]
        SC[sdd:security]
    end

    subgraph VAL[Validador · sonnet]
        TS[sdd:tests]
    end

    subgraph ARQ[Arquitetural · opus]
        IA[sdd:infra-architect]
    end

    TL -->|"delega task (com campo Stack:)"| BE
    TL -->|"delega task (com campo Stack:)"| FE
    TL -->|"revisão (quando aplicável)"| SC
    TL -->|solicita validação| TS
    TL -->|solicita decisão| IA

    BE -.->|resumo + evidências| TL
    FE -.->|resumo + evidências| TL
    SC -.->|APROVADO / RISCO IDENTIFICADO| TL
    TS -.->|VALIDADO / REPROVADO| TL
    IA -.->|decisão + critérios INF-xxx| TL

    TL -->|"DONE + evidências + demonstração"| U
```

Setas tracejadas são os retornos. Cada subagente roda numa janela de contexto isolada e só o resumo final volta ao TecLeader.

## 2. Marketplace e plugins

O repositório `claude-sdd-framework` é um **marketplace** do Claude Code (`.claude-plugin/marketplace.json`) com dois plugins:

| Plugin | Versão atual | Instalação | Conteúdo |
|---|---|---|---|
| `sdd` | 0.6.2 | padrão | 6 agentes, 8 skills, hook pós-compact |
| `authoring` | 0.2.0 | opcional | skills `skill-development` e `agent-development` (criar skills e agentes) |

```mermaid
flowchart LR
    subgraph MK[marketplace claude-sdd-framework]
        direction TB
        SDD[plugin sdd<br/>agents · skills · hooks]
        AUT[plugin authoring<br/>skills]
    end
    subgraph PRJ[projeto consumidor]
        ST[.claude/settings.json<br/>extraKnownMarketplaces · enabledPlugins<br/>agent: sdd:tecleader · permissions.deny]
        CM[CLAUDE.md<br/>## Stack · comandos · regras]
        SP[.specs/feature/<br/>spec.md · design.md · tasks.md]
    end
    ST -->|instala e habilita| SDD
    ST -.->|opcional| AUT
    SDD -->|lê| CM
    SDD -->|cria e atualiza| SP
```

O plugin **não** distribui `CLAUDE.md` nem regras de projeto: as regras chegam como skills. O `CLAUDE.md` de cada
projeto continua local (criado no onboarding pelo TecLeader, a partir de [templates/CLAUDE.md](../templates/CLAUDE.md))
e prevalece sobre as regras do plugin no que for mais específico.

O projeto consumidor declara o marketplace e o agente da sessão no `.claude/settings.json`
(modelos: [project-settings.local.json](../templates/project-settings.local.json) para pasta local e
[project-settings.git.json](../templates/project-settings.git.json) para repositório git):

```json
{
  "extraKnownMarketplaces": {
    "claude-sdd-framework": { "source": { "source": "directory", "path": "<caminho local>" } }
  },
  "enabledPlugins": { "sdd@claude-sdd-framework": true },
  "agent": "sdd:tecleader"
}
```

Os modelos também trazem `permissions.deny` (ver seção 9). Formato confirmado no spike
([spike-result.md](../.specs/done/sdd-plugin/spike-result.md), item #6).

### Estrutura

```text
claude-sdd-framework/
├── .claude-plugin/marketplace.json   # marketplace (plugins sdd e authoring)
├── plugins/
│   ├── sdd/
│   │   ├── .claude-plugin/plugin.json # name, version (semver), description
│   │   ├── agents/                   # tecleader, backend, frontend, tests, security, infra-architect
│   │   ├── hooks/hooks.json          # SessionStart (compact)
│   │   └── skills/                   # sdd-rules, sdd-governance, backend/frontend-engineering, ...
│   └── authoring/skills/             # skill-development, agent-development
├── templates/                        # settings (local/git), CLAUDE.md de projeto, .mcp.json (Jira, GitHub, GitLab, Azure)
├── docs/                             # este documento e o manual de uso
└── .specs/                           # specs, design, validação do próprio plugin
```

## 3. Ciclo de uma tarefa (SDD)

```mermaid
flowchart TD
    A([Solicitação]) --> B{Projeto tem<br/>CLAUDE.md e .specs?}
    B -- não --> C[Onboarding<br/>CLAUDE.md com ## Stack + .specs]
    B -- sim --> D
    C --> D[Requisito, spec e critério de aceite<br/>spec.md]
    D --> E{Requisito, critério e<br/>validação definidos?}
    E -- não --> F[Atualizar spec /<br/>pedir complemento ao usuário]
    F --> D
    E -- sim --> E2{Design técnico<br/>obrigatório?}
    E2 -- sim --> E3[design.md<br/>aprovado pelo TecLeader]
    E2 -- não --> G
    E3 --> G[Criar tasks<br/>tasks.md]
    G --> H[Definir cenários de teste]
    H --> I[Delegar ao implementador<br/>código + testes da feature]
    I --> J[IMPLEMENTED]
    J --> J2{Revisão de<br/>segurança aplicável?}
    J2 -- sim --> J3[SECURITY_REVIEW<br/>sdd:security]
    J3 -- RISCO IDENTIFICADO --> N
    J3 -- APROVADO --> K
    J2 -- não --> K[Delegar ao sdd:tests<br/>VALIDATING]
    K --> L{Resultado}
    L -- REPROVADO --> M[FAILED_VALIDATION]
    M --> N[FIXING no implementador]
    N --> O[VALIDATING_AGAIN]
    O --> L
    L -- VALIDADO --> P[Critérios de DONE]
    P --> Q[README atualizado<br/>sistema no ar demonstrado]
    Q --> R([DONE pelo TecLeader])
    M -. "3 ciclos sem progresso" .-> S([Escalar ao usuário])
```

Design técnico (`.specs/<feature>/design.md`) é obrigatório para mudança arquitetural, novo módulo, banco de dados,
contrato de API, integração externa, infraestrutura e mudança relevante de domínio. Revisão de segurança se aplica a
autenticação/autorização, dados sensíveis, entrada externa, novas dependências, segredos e infraestrutura.

### Estados de uma task

```mermaid
stateDiagram-v2
    [*] --> TODO
    TODO --> IN_PROGRESS
    IN_PROGRESS --> IMPLEMENTED
    IMPLEMENTED --> SECURITY_REVIEW: quando aplicável
    IMPLEMENTED --> VALIDATING: sem revisão de segurança
    SECURITY_REVIEW --> VALIDATING: APROVADO
    SECURITY_REVIEW --> FIXING: RISCO IDENTIFICADO
    VALIDATING --> DONE: VALIDADO e critérios de DONE atendidos
    VALIDATING --> FAILED_VALIDATION: REPROVADO
    FAILED_VALIDATION --> FIXING
    FIXING --> VALIDATING_AGAIN
    VALIDATING_AGAIN --> DONE: VALIDADO
    VALIDATING_AGAIN --> FAILED_VALIDATION: REPROVADO
    FAILED_VALIDATION --> [*]: 3 ciclos sem progresso, escala ao usuário
    DONE --> [*]
```

O estado é gravado em `tasks.md` a cada mudança, para sobreviver a compactações de contexto.
Só o `sdd:tecleader` move uma task para `DONE`.

## 4. Agentes

Valores de `model`, `tools` e `skills` tirados do frontmatter de `plugins/sdd/agents/*.md`.
Na delegação e no settings, os agentes são chamados com o prefixo do plugin (`sdd:<agente>`).

| Agente | Papel | Model | Tools | Skills pré-carregadas (`skills:`) |
|---|---|---|---|---|
| `sdd:tecleader` | Orquestrador: tech lead, scrum master, coordenador SDD; único que encerra tasks | opus | Read, Edit, Write, Grep, Glob, Bash, Agent, Skill + 4 ferramentas de leitura do Jira em dois prefixos + ferramentas de leitura do provedor de código (seção 9) | nenhuma (carrega via ferramenta `Skill`, seção 6) |
| `sdd:backend` | Implementador backend agnóstico de linguagem (DDD, SOLID, Clean/Hexagonal, TDD) | sonnet | Read, Edit, Write, Grep, Glob, Bash | sdd-rules, backend-engineering, bug-diagnosis, domain-modeling |
| `sdd:frontend` | Implementador frontend agnóstico de framework (UX/UI, acessibilidade, performance, E2E) | sonnet | Read, Edit, Write, Grep, Glob, Bash | sdd-rules, frontend-engineering, bug-diagnosis |
| `sdd:tests` | Validador (QA): requisitos, regressão, integração, API, performance, E2E | sonnet | Read, Edit, Write, Grep, Glob, Bash | sdd-rules, bug-diagnosis |
| `sdd:security` | Revisor de segurança (AppSec); somente revisa | opus | Read, Grep, Glob, Bash | sdd-rules |
| `sdd:infra-architect` | Decisões de infraestrutura local e em nuvem (AWS, Azure, Google Cloud) | opus | Read, Write, Grep, Glob | sdd-rules, domain-modeling, infra-engineering |

### Segregação de responsabilidades

```mermaid
flowchart LR
    subgraph Implementa
        BE[sdd:backend]
        FE[sdd:frontend]
    end
    subgraph Revisa
        SC[sdd:security]
    end
    subgraph Valida
        TS[sdd:tests]
    end
    subgraph Decide
        IA[sdd:infra-architect]
    end
    subgraph Governa
        TL[sdd:tecleader]
    end

    BE ---|"quem implementa"| X1[não valida a própria entrega]
    SC ---|"quem revisa"| X5[não corrige código]
    TS ---|"quem valida"| X2[não corrige produção]
    IA ---|"quem decide"| X3[não implementa]
    TL ---|"quem governa"| X4[único que encerra tasks]
```

O TecLeader roda como **agente da sessão principal** (`"agent": "sdd:tecleader"` no settings, ou
`claude --agent sdd:tecleader`) porque um subagente não consegue chamar outros subagentes.

### Contrato de delegação

O TecLeader envia: objetivo, requisitos, spec, tasks, contexto, arquivos permitidos e proibidos, critérios de aceite,
validação obrigatória, resultado esperado e o campo `Stack:` (seção 5). Implementadores respondem `IMPLEMENTADO`
com arquivos, testes, comandos, evidências, riscos e a stack/referência lida; `tests` responde por requisito com
`VALIDADO` ou `REPROVADO`; `security` com `APROVADO` ou `RISCO IDENTIFICADO` e severidade.

## 5. Skills e `references/` por stack

| Skill | Conteúdo | Quem usa |
|---|---|---|
| `sdd-rules` | regras globais (antes de alterar, SDD, escopo, qualidade, segurança, documentação, evidências, encerramento); `references/` com `readme.md`, `final-run.md`, `reproducibility.md` | todos |
| `sdd-governance` | papéis, estados, correção, escalonamento, evidências, contexto, Jira e repositório somente leitura | tecleader |
| `requirements-grilling` | protocolo de perguntas antes de escrever ou aprovar uma spec | tecleader |
| `backend-engineering` | princípios backend agnósticos + `references/dotnet.md`, `references/python.md` | backend |
| `frontend-engineering` | princípios frontend agnósticos + `references/react.md`, `references/web-interface.md` | frontend |
| `bug-diagnosis` | diagnóstico em 5 fases (o `tests` usa a fase de reprodução) | backend, frontend, tests |
| `domain-modeling` | glossário, modelo de domínio, critério e modelo de ADR | backend, infra-architect |
| `infra-engineering` | princípios de nuvem + `references/aws.md`, `azure.md`, `gcp.md`; regra não relaxável: nunca aplicar sem confirmação | infra-architect |

Referências de stack existentes:

| Área | Referência | Observação |
|---|---|---|
| Backend | `.NET` (`dotnet.md`), Python (`python.md`) | exercitadas nos pilotos (ASP.NET Core e FastAPI) |
| Frontend | React (`react.md`) | SPA em React (sem renderização no servidor) |
| Frontend | `web-interface.md` | checklist de revisão de interface, para qualquer stack |
| Frontend | Angular | `references/angular.md` (adapta-se à versão do projeto: v20, v21, v22) |

As `references/` **não** são pré-carregadas: o agente lê só a da stack informada.

### Como a stack é resolvida

```mermaid
sequenceDiagram
    participant CM as CLAUDE.md do projeto
    participant TL as sdd:tecleader
    participant BE as sdd:backend
    participant RF as plugin: references/

    TL->>CM: lê a seção ## Stack
    TL->>BE: delegação com<br/>Stack: <linguagem/framework/versão> — referência: backend-engineering/references/<stack>.md
    BE->>RF: Read ${CLAUDE_PLUGIN_ROOT}/skills/backend-engineering/references/<stack>.md
    BE-->>TL: IMPLEMENTADO + stack e referência lida
```

1. A fonte é a seção `## Stack` do `CLAUDE.md` do projeto (o onboarding a cria; o template já traz a seção).
2. O TecLeader repete a stack na delegação, no campo
   `Stack: <linguagem/framework/versão> — referência: <skill>/references/<arquivo>.md`
   (ou `referência: nenhuma`).
3. O agente lê a referência em `${CLAUDE_PLUGIN_ROOT}/skills/<skill>/references/<stack>.md`.
   O Claude Code substitui `${CLAUDE_PLUGIN_ROOT}` pelo caminho do plugin **no texto do agente** (não no texto da skill),
   por isso o caminho fica nos agentes (correção D-001, `sdd` 0.1.2).
4. Sem referência: princípios gerais da skill e lacuna declarada no relato; o TecLeader registra como observação.
5. Stack ausente no `CLAUDE.md` e na delegação: o agente não adivinha e pede a informação.

## 6. Carregamento das skills

```mermaid
flowchart LR
    subgraph Sessão principal
        TL[sdd:tecleader] -->|"ferramenta Skill<br/>início da sessão e após compact"| R1[sdd:sdd-rules<br/>sdd:sdd-governance<br/>sdd:requirements-grilling]
    end
    subgraph Subagentes
        SA[sdd:backend / frontend /<br/>tests / security / infra-architect] -->|"skills: no frontmatter<br/>pré-carregadas"| R2[sdd-rules + skills do papel]
        SA -->|Read sob demanda| R3[references/ da stack]
    end
```

- **Subagentes:** as skills listadas em `skills:` são injetadas no início da execução (nome sem prefixo no frontmatter).
- **TecLeader:** `skills:` não pré-carrega no agente da sessão principal (spike, item #3). Por isso ele tem `Skill`
  em `tools:` e carrega `sdd:sdd-rules`, `sdd:sdd-governance` e `sdd:requirements-grilling` no início da sessão e
  após cada compact. Se uma skill não carregar, segue com a governança do próprio arquivo do agente (autossuficiente)
  e informa o usuário.

## 7. Hook pós-compact

`plugins/sdd/hooks/hooks.json` registra um hook `SessionStart` com matcher `compact`. Ele só executa `echo`
(sem script, sem rede) e injeta o lembrete:

- reler `spec.md` e `tasks.md` do projeto ativo (estados, REQs em andamento, decisões);
- não confiar apenas no resumo;
- recarregar as skills `sdd:sdd-rules` e `sdd:sdd-governance`.

Agentes não conseguem executar `/compact` nem medir o próprio contexto; o TecLeader pede ao usuário `/context`
e, se o uso estiver alto, `/compact`.

## 8. Rastreabilidade

```text
REQ-001 → task → teste → validação
REQ-001 → test_req001.py (Python) | req001.spec.ts / req001.test.tsx (TypeScript) | convenção da stack
```

Requisito sem teste é reportado pelo `sdd:tests` como lacuna de cobertura e impede o `DONE`.

## 9. Segurança

| Controle | Onde | Como |
|---|---|---|
| Jira somente leitura (1ª camada) | `tools:` do `sdd:tecleader` | só `atlassianUserInfo`, `getAccessibleAtlassianResources`, `getJiraIssue`, `searchJiraIssuesUsingJql`, nos prefixos `mcp__claude_ai_Atlassian__` (conector claude.ai, padrão) e `mcp__atlassian__` (`.mcp.json` opcional) |
| Jira somente leitura (2ª camada) | `permissions.deny` nos templates de settings | 16 regras bloqueiam as ferramentas de escrita do Atlassian (comentar, criar, editar, transicionar issue; Confluence; `executeWrite`/`executeDestructive`) nos dois prefixos |
| Somente o TecLeader acessa o Jira | frontmatter dos agentes | os demais agentes não têm ferramentas Atlassian |
| Regras não relaxáveis | `sdd-rules` e `templates/CLAUDE.md` | regras do projeto não podem relaxar segredos/credenciais, verificação SSL, confirmação de ações irreversíveis, Jira somente leitura e menor privilégio |
| `security` não altera o projeto | `tools:` sem Edit/Write | tem Bash para verificações; a proibição de alterar vale pelo prompt |
| `infra-architect` não executa | `tools:` sem Bash | limitado de fato |
| Hook seguro | `hooks.json` | apenas `echo` |
| Credenciais do GitHub | README | nunca usuário/senha/token na URL; SSH ou gerenciador de credenciais do git |
| Conteúdo de terceiros | rodapés das skills | origem `repo@commit` e licença SPDX; `authoring` reescrito com texto próprio |

Revisão de segurança do plugin: [security-review.md](../.specs/done/sdd-plugin/security-review.md)
(volta 1 RISCO IDENTIFICADO, 1 MEDIUM e 4 LOW; volta 2 APROVADO).

### Integração com provedores de código

Opcional e somente leitura (feature `vcs-integration`, `sdd` 0.2.0). Só vale se o `CLAUDE.md` do projeto tiver
`## Repositório` (Provedor, Repositório, Acesso); sem a seção, o TecLeader não consulta nenhum provedor.
Uso: issue → spec (ID registrado, ex.: `GH#42`) e status de PR/CI como evidência antes do `DONE`.
Decisão e riscos: [design.md](../.specs/done/vcs-integration/design.md); pesquisa: [research-t000.md](../.specs/done/vcs-integration/research-t000.md).

**Camadas de proteção**

| Camada | Onde | Como |
|---|---|---|
| 1. Servidor somente leitura | `.mcp.json` | GitHub em `/mcp/readonly`; Azure DevOps com `X-MCP-Readonly: true` (GitLab e Bitbucket não oferecem modo read-only) |
| 2. Lista fechada de leitura | `tools:` do `sdd:tecleader` | GitHub: `get_me`, `issue_read`, `list_issues`, `search_issues`, `pull_request_read`, `list_pull_requests`, `search_pull_requests`, `actions_list`, `actions_get`; sem `get_job_logs`. Bitbucket (Atlassian) só ferramentas de leitura; GitLab e Azure: nenhuma no plugin (usuário adiciona por nome, nunca curinga) |
| 3. `permissions.deny` | templates de settings | ferramentas de escrita por nome (cobre sessões sem o agente) e prefixos Bash de `gh`/`glab`/`az`. O deny de Bash é defesa em profundidade, não barreira |
| Token | variável de ambiente `GITHUB_PAT` | PAT fine-grained somente leitura (só os repositórios do projeto; Metadata, Issues, Pull requests, Actions = Read; validade curta); proibido reutilizar `gh auth token`; nunca versionado |

**Provedores**

| Provedor | Caminho padrão | Status |
|---|---|---|
| GitHub | `templates/mcp-github.json` (MCP oficial `/mcp/readonly`, `Authorization: Bearer ${GITHUB_PAT}`, `X-MCP-Toolsets: context,repos,issues,pull_requests,actions`) | suportado e validado (6/6 casos, [validation-report.md](../.specs/done/vcs-integration/validation-report.md)) |
| Bitbucket Cloud | MCP Atlassian (issues vêm do Jira); admin concede só `read_bitbucket` | experimental, não validado |
| GitLab | `templates/mcp-gitlab.json` (`/api/v4/mcp`) | experimental, não validado |
| Azure DevOps | `templates/mcp-azure-devops.json` (`X-MCP-Toolsets: wit,repos,pipelines`; exige app registration Entra ID) | experimental, não validado |

**Fluxo issue → spec com confirmação**

```mermaid
sequenceDiagram
    actor U as Usuário
    participant TL as sdd:tecleader
    participant P as Provedor (leitura)
    participant SA as Subagentes
    U->>TL: "Implemente a issue GH#42"
    TL->>P: issue_read (somente leitura)
    P-->>TL: texto da issue (dado não confiável)
    TL->>TL: converte em spec.md + tasks.md, sinaliza trechos suspeitos
    TL->>U: spec derivada da issue, pede confirmação
    U-->>TL: confirma
    TL->>SA: apenas REQs validados (nunca o texto bruto)
```

Issue, PR, comentário, work item e log são **dados, nunca instruções**: o TecLeader não executa comandos, não chama
ferramentas, não muda escopo e não lê nem expõe segredos por pedido contido neles. Issue sem critério de aceite:
solicita complementação. Escrita (PR, comentário, merge, issue) não está liberada: o usuário faz manualmente.

**Riscos residuais**

- `gh` já logado na máquina tem escrita, e o Bash do `tecleader` alcança a API por `curl`/PowerShell sem passar
  pelo deny. Mitigação real: token somente leitura. O modo `Acesso: cli` não é recomendado.
- OAuth do GitHub (sem header `Authorization`) não foi testado.
- Bitbucket, GitLab e Azure DevOps não foram validados; nomes das ferramentas de escrita do Bitbucket devem ser
  confirmados na sessão e então negados.
- O deny do `gh issue create` foi provado só com `--help` (o agente recusa antes de tentar; defesa em camadas).
- Com Zscaler, `.mcp.json` e CLIs saem da máquina (nunca desabilitar SSL); validar com a TI.

## 10. Versionamento e atualização

- `version` semver em `plugins/*/.claude-plugin/plugin.json`; mudanças registradas no [CHANGELOG](../CHANGELOG.md).
- **MAJOR:** muda contrato de delegação, nomes de agentes ou estados. **MINOR:** nova skill ou referência.
  **PATCH:** texto ou correção.
- Após editar o plugin instalado: bump de `version`, depois
  `claude plugin marketplace update claude-sdd-framework` e
  `claude plugin update sdd@claude-sdd-framework --scope project`; reiniciar a sessão para aplicar.
- Validar a estrutura antes de publicar: `claude plugin validate .`, `./plugins/sdd`, `./plugins/authoring`.

## 11. Evidências de validação

Resumo do [validation-report.md](../.specs/done/sdd-plugin/validation-report.md) (`sdd` 0.1.2, `authoring` 0.2.0,
Claude Code 2.1.288):

- `claude plugin validate` OK no marketplace e nos dois plugins; instalação limpa em projeto de teste.
- Mesma delegação gerou backend FastAPI (piloto Python, `pytest` 13 passed) e ASP.NET Core (piloto .NET,
  `dotnet test` 9 passed + 3 extras do validador), com leitura da referência correta.
- Regressão do `app-workshop`: `npm test` 9/9, build OK, E2E 6/6.

## 12. Limitações conhecidas

- `skills:` só pré-carrega em subagentes; o carregamento das regras no TecLeader depende da instrução de usar a
  ferramenta `Skill` (observado funcionando na validação).
- `${CLAUDE_PLUGIN_ROOT}` só é substituído no texto de agentes, não no de skills.
- Stacks sem referência (ex.: Vue) usam os princípios gerais e o agente declara a lacuna.
- Caminho `.mcp.json` do Jira não testado com Zscaler ativo; nomes `mcp__atlassian__*` não verificados.
- Repositório: ver riscos residuais na seção 9 (OAuth GitHub não testado; Bitbucket, GitLab e Azure DevOps não validados).
- "Listar projetos do Jira" não tem ferramenta de leitura dedicada no conector.
- `/compact` não executa em modo `-p`: o hook do plugin foi confirmado com matcher `startup`, e o matcher `compact`
  foi confirmado no mecanismo do workspace; os relatórios não registram o hook do plugin disparando após um `/compact` real.
- Ferramentas MCP pedem permissão na primeira chamada em sessão interativa.
- `tests` tem Edit e Write (para testes e relatórios); "não alterar produção" vale pelo prompt.
- Comandos de exemplo das references (lint, auditoria de dependências) não foram executados nos pilotos.
