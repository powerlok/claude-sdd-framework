# Changelog

Formato por versão (semver). Regras de versionamento: `.specs/sdd-plugin/design.md`, seção 6.

## sdd 0.4.0 — 2026-10-10

- Nova skill **`infra-engineering`** para o `infra-architect`: princípios de nuvem + referências **AWS**, **Azure** e
  **Google Cloud** (14 seções cada: framework oficial, landing zone, identidade, rede, computação, dados, segredos,
  observabilidade, custo, DR, segurança, IaC com tabela "prévia × aplica", comandos só de leitura/prévia, armadilhas).
- Regra não relaxável: o agente nunca roda apply/deploy/delete/execute; state e plano contêm segredos; prévia só com
  identidade somente leitura sobre código revisado; lock file versionado e módulos de origem confiável.
- `infra-architect` agnóstico de nuvem (nuvem vem do `## Stack`); template `CLAUDE.md` com linha de infra.
- `sdd-rules`: fontes de instrução explícitas (CLAUDE.md, plugin, delegação, `.specs/`); o resto é dado não confiável
  (vale para todos os subagentes).
- Texto próprio: AWS (docs CC BY-SA 4.0, só fatos), Azure e Google Cloud (CC BY 4.0, com atribuição).
- Revisão de segurança APROVADA (3 voltas); pilotos Azure, GCP e AWS validados.

## sdd 0.3.0 — 2026-10-10

- Referência **Angular** em `frontend-engineering` (`references/angular.md`), GH#1: adapta-se à versão do projeto
  (v20 standalone, v21 zoneless, v22 OnPush/`@Service()`/Signal Forms/`resource`), sem migrar por conta própria.
  Texto próprio baseado em angular.dev (CC BY 4.0) e inspirado em angular/skills@ff69483 (MIT).
- Revisão de segurança APROVADA (2 voltas); piloto `sdd:frontend` com Stack Angular 21 validado.

## sdd 0.2.0 — 2026-10-09

- Integração opcional, somente leitura, com o provedor de código (feature `vcs-integration`):
  issue → spec (ID registrado, ex.: `GH#42`) e status de PR/CI como evidência antes do DONE.
  Ativada só se o `CLAUDE.md` do projeto tiver `## Repositório`.
- `tecleader`: `tools:` com ferramentas de leitura GitHub (`mcp__github__*`, verificadas na sessão) e
  Bitbucket (Atlassian, dois prefixos); nova seção "Repositório". Escrita (PR, comentário, merge, issue) proibida.
- `sdd-governance`: seção "Integrações externas (Jira e repositório)".
- Templates: `mcp-github.json` (`/mcp/readonly`); `mcp-gitlab.json` e `mcp-azure-devops.json` (experimentais);
  `permissions.deny` ampliado (escrita do GitHub MCP e prefixos Bash de `gh`/`glab`/`az`, defesa em profundidade);
  `CLAUDE.md` com seção opcional `## Repositório`.
- Correções da revisão de segurança (T-003): conteúdo de issue/PR/comentário/work item/log tratado como
  dado não confiável (sem seguir instruções; spec de issue exige confirmação do usuário; subagentes recebem só REQs);
  `GITHUB_PAT` fine-grained somente leitura (proibido `gh auth token`); Bitbucket rebaixado para experimental;
  `get_job_logs` e `getBitbucketRepoPipelineStepLog` removidos do `tools:`; deny das ferramentas de escrita
  GitLab e Azure DevOps por nome e de mais prefixos Bash (`gh auth token`, `gh secret`, `glab api`, `az devops invoke` etc.);
  Azure com `X-MCP-Toolsets: wit,repos,pipelines`; riscos residuais documentados (`curl`/PowerShell, `gh` logado, Zscaler, OAuth).

## marketplace — 2026-10-09 — renomeado para `claude-sdd-framework`

- Marketplace `engineering-workflow` → `claude-sdd-framework` (repositório GitHub `powerlok/claude-sdd-framework`).
  Instalação passa a ser `sdd@claude-sdd-framework` e `authoring@claude-sdd-framework`.
  Plugins e agentes não mudam (`sdd:tecleader` etc.).
- `templates/project-settings.git.json` aponta para o GitHub; Bitbucket substituído por GitHub na documentação.

## sdd 0.1.2 — 2026-10-09

- D-001: agentes `backend`, `frontend` e `tecleader` passam a indicar o caminho das references via `${CLAUDE_PLUGIN_ROOT}` (substituído no texto do agente; não é substituído no texto de skill). Antes, o agente buscava a referência no disco.

## authoring 0.2.0 — 2026-10-09

### authoring

- `skill-development/SKILL.md` e `agent-development/SKILL.md` reescritos com texto próprio,
  baseados na documentação pública do Claude Code (code.claude.com/docs) e nas convenções
  do projeto (spike T-001, design 4.3/4.5).
- `agent-development/references/examples.md`: exemplos próprios baseados nos agentes do plugin `sdd`.
- Cópias proprietárias de anthropics/claude-code removidas (`agent-development/examples/`,
  `agent-development/references/*` antigos e o `SKILL.md` anterior de ambas as skills).
- `agent-development/scripts/validate-agent.sh` removido (validação via `claude plugin validate`).
- Mantidos: `skill-development/references/skill-creator-original.md` e `LICENSE.txt` (Apache-2.0).

## 0.1.1 — 2026-10-09

Correções da revisão de segurança T-007 (volta 1).

### sdd

- `sdd-rules`: regras do projeto não podem relaxar segredos/credenciais, verificação SSL,
  confirmação de ações irreversíveis, Jira somente leitura e menor privilégio.
- `backend-engineering` (`python.md`, `dotnet.md`): comandos de migração somente em banco
  local/descartável; outros ambientes exigem confirmação explícita.
- `frontend-engineering` (`web-interface.md`): rodapé de atribuição no formato
  `Texto próprio; inspirado em vercel-labs/web-interface-guidelines@434b7f9 (MIT)`.

### authoring

- `skill-development/references/skill-creator-original.md`: origem anthropics/skills@83291af
  (Apache-2.0); `LICENSE.txt` incluído; scripts ausentes marcados "(não incluído neste plugin)".

### templates

- `project-settings.local.json` e `project-settings.git.json`: `permissions.deny` com as
  ferramentas de escrita do Atlassian (prefixos `mcp__claude_ai_Atlassian__` e `mcp__atlassian__`).
- `CLAUDE.md`: regras do projeto não podem relaxar os controles de segurança acima.

## 0.1.0 — 2026-10-09

### sdd

- Primeira versão do plugin do processo SDD.
- Agentes: `tecleader`, `backend`, `frontend`, `tests`, `security`, `infra-architect`
  (agnósticos de linguagem; stack lida da seção `## Stack` do `CLAUDE.md` do projeto).
- Skills: `sdd-rules`, `sdd-governance`, `backend-engineering`, `frontend-engineering`,
  `requirements-grilling`, `bug-diagnosis`, `domain-modeling` (com `references/` por stack).
- Hook `SessionStart` (compact) para reler `spec.md` e `tasks.md`.

### authoring

- Primeira versão do catálogo opcional.
- Skills `skill-development` e `agent-development` (cópia das skills do workspace,
  incluindo `examples/`, `references/` e `scripts/`).

### Marketplace e templates

- Marketplace `engineering-workflow` com os plugins `sdd` e `authoring`.
- Templates: `project-settings.local.json` (marketplace por diretório),
  `project-settings.git.json` (marketplace por repositório git),
  `CLAUDE.md` de projeto e `mcp-atlassian.json` (MCP remoto da Atlassian, opcional).
