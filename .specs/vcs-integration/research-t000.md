# T-000 — Pesquisa: integração somente leitura com provedores de código

- Feature: `vcs-integration` (spec: `.specs/vcs-integration/spec.md`)
- Data de consulta de todas as fontes: **2026-10-09**
- Método: somente documentação oficial (GitHub, Atlassian, GitLab, Microsoft, Anthropic). Conteúdo web tratado como dado; nada foi instalado ou executado.
- Legenda: **C** = Confirmado na fonte citada; **NC** = Não confirmado (inferência ou fonte não encontrada).

---

## 0. Achados transversais (impactam REQ-004 e Zscaler)

| # | Fato | Status | Fonte |
|---|------|--------|-------|
| T1 | Ordem de avaliação: `deny` → `ask` → `allow`; a primeira que casar decide. Allow não abre exceção em deny. Deny em qualquer escopo (user/project/managed) vence allow de outro escopo. | C | https://code.claude.com/docs/en/permissions |
| T2 | `Bash(gh pr merge:*)` é equivalente a `Bash(gh pr merge *)`; `:*` só é reconhecido no fim do padrão. | C | idem |
| T3 | Comandos compostos: separadores reconhecidos `&&`, `\|\|`, `;`, `\|`, `\|&`, `&` e nova linha. Allow precisa casar **cada** subcomando; deny/ask se aplica se **qualquer** subcomando casar, inclusive em subshell, `$(...)` e corpo de `for`. | C | idem |
| T4 | **Deny de Bash não é fronteira de segurança**: a doc diz textualmente que a regra "isn't a security boundary around the program". Não pega `/usr/bin/gh ...`, `sh -c '...'`, nem variações de argumento (ex.: `git -C . push`). Recomenda sandbox ou hook `PreToolUse` para controle forte. | C | idem (seção "what a Bash rule doesn't match") |
| T5 | Wrappers removidos antes do match: `timeout`, `time`, `nice`, `nohup`, `stdbuf`, `command`, `builtin`, `noglob`. | C | idem |
| T6 | Regras MCP: `mcp__<server>` ou `mcp__<server>__*` = servidor inteiro; `mcp__<server>__<tool>` = ferramenta específica. Regras `mcp__` com parênteses (parâmetros) são **ignoradas** em settings (só via `--disallowedTools`). | C | idem |
| T7 | Ferramentas de conectores claude.ai aparecem como `mcp__claude_ai_<server>__<tool>`. | C | idem |
| T8 | Hooks `PreToolUse` não anulam deny/ask. | C | idem |
| T9 | Conectores claude.ai no Claude Code trafegam via `mcp-proxy.anthropic.com` ("Connector traffic routes through this proxy"). Desligáveis com `ENABLE_CLAUDEAI_MCP_SERVERS=false` ou `disableClaudeAiConnectors`; bloqueio individual com `deniedMcpServers`. | C | https://code.claude.com/docs/en/network-config ; https://code.claude.com/docs/en/mcp |
| T10 | Claude Code confia por padrão no bundle Mozilla **e** no store do SO; proxies de inspeção TLS funcionam sem configuração se a raiz estiver no store do SO (instalador nativo; npm requer Node ≥ 22.15). Alternativa: `NODE_EXTRA_CA_CERTS`. | C | https://code.claude.com/docs/en/network-config |
| T11 | Servidores MCP HTTP configurados localmente (`.mcp.json`/`claude mcp add`) são chamados pelo processo do Claude Code na máquina do usuário (portanto passam pelo Zscaler, mas com o tratamento de CA de T10). | NC (inferência; a doc não descreve explicitamente o caminho) | — |
| T12 | CLIs (`gh`, `glab`, `az`) chamam a API do provedor a partir da máquina do usuário e usam a pilha TLS própria (não a do Claude Code); comportamento com CA do Zscaler depende de cada CLI. | NC | — |

Consequência para REQ-004: com CLI, o deny por prefixo é **defesa em profundidade, não bloqueio técnico forte** (T4). Bloqueio forte exige: (a) credencial somente leitura no lado do provedor, ou (b) modo read-only aplicado no servidor MCP, ou (c) allowlist via hook `PreToolUse`/sandbox.

---

## 1. GitHub

### 1a. `gh` CLI
- Leitura: `gh issue view/list`, `gh pr view/list`, `gh pr checks` ("Show CI status for a single pull request"), `gh run view/list` ("View a summary of a workflow run", `--log`, `--log-failed`, `--json`). — C — https://cli.github.com/manual/gh_pr_checks ; https://cli.github.com/manual/gh_run_view
- Escrita (exemplos a negar): `gh pr merge|create|comment|review|close|edit`, `gh issue create|comment|edit|close`, `gh run rerun|cancel`, `gh workflow run`. — NC quanto à lista exaustiva (nomes de subcomandos conhecidos, não verificados um a um nesta pesquisa).
- `gh api`: "The default HTTP request method is GET normally and POST if any parameters were added"; `--method` sobrescreve. Logo `gh api` com `-f/-F` vira POST. — C — https://cli.github.com/manual/gh_api
- Auth: fluxo web (padrão) com token guardado no **credential store do sistema**; fallback para texto plano se não houver store ou com `--insecure-storage`; também `GH_TOKEN`. — C — https://cli.github.com/manual/gh_auth_login

### 1b. GitHub MCP Server oficial (`github/github-mcp-server`)
- Endpoint remoto: `https://api.githubcopilot.com/mcp/`. — C — https://github.com/github/github-mcp-server
- Auth remota: OAuth (login no navegador) ou PAT em header `Authorization: Bearer ...`. Guia do Claude Code mostra PAT em header (`claude mcp add-json github '{"type":"http","url":"https://api.githubcopilot.com/mcp","headers":{"Authorization":"Bearer YOUR_GITHUB_PAT"}}'`). — C — https://github.com/github/github-mcp-server/blob/main/docs/installation-guides/install-claude.md
- Read-only **no remoto**: sufixo `/readonly` (ex.: `https://api.githubcopilot.com/mcp/readonly`) ou header `X-MCP-Readonly`; toolsets via header `X-MCP-Toolsets` ou URL `.../mcp/x/<toolset>`. — C — https://github.com/github/github-mcp-server/blob/main/docs/remote-server.md
- Read-only local: `--read-only` / `GITHUB_READ_ONLY=true`. — C — README
- Toolsets padrão: `context, repos, issues, pull_requests, users`; outros: `actions`, `code_security`. — C — README
- Ferramentas de leitura relevantes: `issue_read` (métodos `get`, `get_comments`, `get_sub_issues`, `get_parent`, `get_labels`), `list_issues`, `search_issues`, `pull_request_read` (métodos `get`, `get_diff`, `get_status`, `get_files`, `get_commits`, `get_review_comments`, `get_reviews`, `get_reviewers`), `list_pull_requests`, `actions_list`, `actions_get` (`get_workflow_run`, `get_workflow_job`, ...), `get_job_logs`. — C — README
- Ferramentas de escrita (para deny explícito): `issue_write`, `add_issue_comment`, `update_issue_comment`, `sub_issue_write`, `create_pull_request`, `merge_pull_request`, `add_comment_to_pending_review`, `add_reply_to_pull_request_comment`, `actions_run_trigger`. — C (lista parcial; README tem mais ferramentas) — README
- Observação: `get_status` em `pull_request_read` atende "status de PR/CI"; `actions_get` com método de download de artefato é leitura mas baixa conteúdo. — C (nomes) / NC (comportamento detalhado)

### 1c. Conector GitHub no claude.ai
- A "GitHub Integration" do claude.ai **não é um conector MCP de issues/PRs**: "Claude reads file names and contents only: it doesn't see commit history, pull requests, or issues." — C — https://claude.com/docs/connectors/github
- Não foi encontrado conector GitHub MCP no diretório oficial; a página do diretório não lista provedores específicos. — NC — https://claude.com/docs/connectors/directory
- Possível adicionar `https://api.githubcopilot.com/mcp/readonly` como conector personalizado no claude.ai (passaria por `mcp-proxy.anthropic.com`). — NC (não verificado que o OAuth do GitHub MCP aceita o fluxo de conector personalizado)

---

## 2. Bitbucket Cloud

### 2a. Atlassian Rovo MCP (`mcp.atlassian.com`)
- Cobre Bitbucket Cloud. Requisito: "These tools are only available if your Bitbucket workspace is linked to an organization." — C — https://support.atlassian.com/atlassian-rovo-mcp-server/docs/supported-tools/
- Ferramentas de leitura (grupo `read_bitbucket`): `listBitbucketWorkspaces`, `getBitbucketWorkspace`, `listBitbucketRepositories`, `getBitbucketRepository`, `getBitbucketRepoDefaultReviewers`, `getBitbucketRepoFileContent`, `getBitbucketRepoBranch`, `getBitbucketRepoCommit`, `listBitbucketRepoCommitReports`, `getBitbucketRepoCommitReport`, `getBitbucketRepoCommitReportAnnotations`, `listBitbucketRepoPullRequests`, `getBitbucketRepoPullRequest`, `getBitbucketRepoPullRequestDiff`, `listBitbucketRepoPullRequestComments`, `listBitbucketRepoPullRequestTasks`, `listBitbucketRepoPipelines`, `getBitbucketRepoPipeline`, `listBitbucketRepoPipelineSteps`, `getBitbucketRepoPipelineStep`, `getBitbucketRepoPipelineStepLog`, `listBitbucketRepoDeployments`, `getBitbucketRepoDeployment`, `listBitbucketRepoEnvironments`, `getBitbucketRepoEnvironment`. Existe também grupo `write_bitbucket` (PR e pipelines). — C — idem
- Grupos de permissão: `read_bitbucket` requer escopo `read:bitbucket:agent-interface`; `write_bitbucket` requer `write:bitbucket:agent-interface`; admin da organização concede/revoga por grupo (Admin Hub > Rovo > Rovo MCP Server). — C (via resultado de busca restrito a atlassian.com; página-fonte: https://support.atlassian.com/bitbucket-cloud/docs/interacting-with-bitbucket-via-mcp/ — não aberta diretamente) → tratar como **NC até leitura direta da página**.
- Endpoints: `https://mcp.atlassian.com/v2/mcp` (atual), `v1` legado; auth OAuth 2.1 ou API token. — C — https://support.atlassian.com/atlassian-rovo-mcp-server/docs/getting-started-with-the-atlassian-remote-mcp-server/
- Cobertura de issues: o Rovo MCP não lista ferramentas para o issue tracker nativo do Bitbucket; issues vêm do Jira (já integrado). — C (ausência na lista de ferramentas)
- Via conector claude.ai Atlassian, as ferramentas Bitbucket apareceriam como `mcp__claude_ai_Atlassian__<tool>` (T7). — NC (não verificado que o conector claude.ai expõe as ferramentas Bitbucket)

### 2b. CLI oficial / REST
- Atlassian publica a **Teamwork Graph CLI (`twg`)** em developer.atlassian.com, com comandos Bitbucket (PRs, pipelines, inbox, `pipeline latest-failure`, mas também `pipeline run`, criação de repositórios — escrita). Bitbucket exige token separado via `twg setup bitbucket`; credenciais locais, com Keychain/Credential Manager opcional ("experimental encrypted storage"); "There's no read-only mode" (permissões = da conta). — C — https://developer.atlassian.com/cloud/twg-cli/getting-started/how-authentication-works/ ; nomes de comandos: NC (página `/surfaces/bitbucket` retornou 404; vindos de changelog via busca).
- REST API com credencial: **App passwords depreciadas** — criação bloqueada desde 2025-09-09; deixam de funcionar em 2026-06-09 (blog fase 2); outro anúncio cita brownouts até 2026-07-27 → hoje (2026-10-09) **não funcionam**. Substituto: API tokens com escopos. — C (datas do blog oficial: https://www.atlassian.com/blog/bitbucket/bitbucket-cloud-enters-phase-2-of-app-password-deprecation) ; datas de brownout: NC.
- MCP oficial específico de Bitbucket fora do Rovo: não encontrado. — NC

---

## 3. GitLab
- `glab` é a CLI oficial; leitura de issues, MRs e pipelines (`glab issue view/list`, `glab mr view/list`, `glab ci ...`). — C (oficial e categorias) / NC (nomes exatos de subcomandos de CI não abertos) — https://docs.gitlab.com/cli/
- Auth `glab`: OAuth (`--web`) ou PAT; credenciais no **keyring do SO** por padrão; fallback/`--insecure-storage` grava em texto plano em `~/.config/glab-cli/config.yml`. — C — https://docs.gitlab.com/cli/auth/login/
- MCP oficial: `https://<gitlab.example.com>/api/v4/mcp`; OAuth 2.0 Dynamic Client Registration (escopo `mcp`); GA desde GitLab 19.5; Free/Premium/Ultimate; GitLab.com, Self-Managed e Dedicated. Comando: `claude mcp add -s user --transport http GitLab https://<gitlab.example.com>/api/v4/mcp`. — C — https://docs.gitlab.com/user/model_context_protocol/mcp_server/
- **Sem modo read-only documentado** no MCP do GitLab. — C (ausência) — idem
- Ferramentas de leitura relevantes: `get_issue`, `get_work_item`, `list_work_items`, `get_workitem_notes`, `get_merge_request`, `list_merge_requests`, `get_merge_request_pipelines`, `get_merge_request_notes`, `get_pipeline`, `get_pipeline_jobs`, `get_job`, `list_pipelines`. Escrita (negar): `add_commit`, `create_issue`, `save_merge_request`, `save_note`, `save_merge_request_review`, `accept_merge_request`, `add_branch`, `fork_repository`, `save_pipeline`, `manage_pipeline`, `link_work_items`, `save_vulnerability`, `save_work_item`, `attach_scan_profile`, `start_duo_session`, `send_duo_session_input`. — C — https://docs.gitlab.com/user/model_context_protocol/mcp_server_tools/

---

## 4. Azure DevOps
- Extensão `azure-devops` do Azure CLI (≥ 2.30.0). Leitura: `az boards work-item show`, `az repos pr show/list`, `az repos pr policy list`, `az pipelines runs show/list`. Escrita (negar): `az boards work-item create/update/delete`, `az repos pr create/update/set-vote`, `az repos pr reviewer add/remove`, `az repos pr work-item add/remove`, `az repos pr policy queue`, `az pipelines runs tag add/delete`, `az pipelines runs artifact upload`; `az repos pr checkout` altera o git local. — C — https://learn.microsoft.com/en-us/cli/azure/boards/work-item ; https://learn.microsoft.com/en-us/cli/azure/repos/pr ; https://learn.microsoft.com/en-us/cli/azure/pipelines/runs
- Auth da CLI (`az login` / PAT): NC (página não aberta).
- MCP oficial remoto: `https://mcp.dev.azure.com/{organization}`; auth Microsoft Entra ID (OAuth); org precisa ser Entra-backed (MSA não suportado). **Claude Code exige app registration Entra customizado** (redirect `http://localhost:3118/callback`, `claude mcp add --transport http ado https://mcp.dev.azure.com/{org} --client-id {client-id} --callback-port 3118`). — C — https://learn.microsoft.com/azure/devops/mcp-server/remote-mcp-server (ms.date 2026-09-21)
- Read-only no remoto: header `X-MCP-Readonly: true`; toolsets via `X-MCP-Toolsets` (`repos`, `wit`, `pipelines`, `wiki`, `work`, `testplan`, `advsec`, `elm`); ferramentas individuais via `X-MCP-Tools`. Recomenda escopos OAuth somente leitura. — C — idem
- Ferramentas de leitura: `wit_work_item` (`get`, `get_batch`, `list_comments`, ...), `wit_query`, `search_workitem`, `repo_pull_request` (`get`, `list`, ...), `repo_pull_request_thread`, `pipelines_build` (`list`, `get_status`, `get_changes`), `pipelines_build_log`, `pipelines_run` (`get`, `list`). Escrita: sufixo `_write` (`wit_work_item_write`, `repo_pull_request_write`, `pipelines_write`, ...), `repo_create_branch`, `wiki_upsert_page`, `wit_work_item_attachment_upload/_link`. — C — idem
- MCP local (`microsoft/azure-devops-mcp`, Node 20+, stdio, PAT ou Entra/`azcli`, filtro por domínios). Doc recomenda o remoto. — C — https://github.com/microsoft/azure-devops-mcp
- Doc de troubleshooting cita proxy/firewall corporativo: liberar HTTPS de saída para `mcp.dev.azure.com`. — C — idem (remote-mcp-server)

---

## 5. Tabela comparativa

| Provedor | Opção | Leitura (issue / PR / CI) | Como bloquear escrita | Autenticação | Segredo em arquivo? | Zscaler | Confiança | Fonte |
|---|---|---|---|---|---|---|---|---|
| GitHub | `gh` CLI | `gh issue view`, `gh pr view`, `gh pr checks`, `gh run view/list` | `permissions.deny` por prefixo (`Bash(gh pr merge *)`, `Bash(gh api *)` etc.) — **fraco** (T4); forte só com token read-only no GitHub (NC) ou hook/sandbox | OAuth web / PAT / `GH_TOKEN` | Não por padrão (credential store); texto plano no fallback | Sai da máquina (CLI própria) — NC quanto a CA | Alta (leitura) / Média (bloqueio) | cli.github.com/manual |
| GitHub | MCP remoto `api.githubcopilot.com/mcp/readonly` | `issue_read`, `pull_request_read`(`get_status`), `actions_list/get`, `get_job_logs` | Servidor em `/readonly` (+ `X-MCP-Toolsets`) **e** deny de ferramentas de escrita | OAuth ou PAT em header | Não com OAuth; PAT em `.mcp.json` **seria** segredo (evitar / usar env) | Sai da máquina via Claude Code (T10/T11) | Alta | github-mcp-server docs |
| GitHub | Conector claude.ai "GitHub Integration" | Não (só arquivos) | n/a | OAuth claude.ai | Não | Via Anthropic | Descartado | claude.com/docs/connectors/github |
| Bitbucket | Rovo MCP (conector claude.ai Atlassian ou `.mcp.json` v2) | `getBitbucketRepoPullRequest`, `listBitbucketRepoPipelines`, `getBitbucketRepoPipeline(Step/Log)`, `listBitbucketRepoCommitReports`; issues = Jira | Admin concede só `read_bitbucket` (NC) + deny de ferramentas de escrita por nome (nomes `write_bitbucket` não listados → deny por allowlist) | OAuth 2.1 (ou API token) | Não (OAuth) | Conector claude.ai: via `mcp-proxy.anthropic.com` (T9); `.mcp.json`: sai da máquina | Alta (ferramentas) / Média (escopo) | support.atlassian.com |
| Bitbucket | TWG CLI (`twg`) | PR get/activity, pipelines | Só deny por prefixo (fraco); sem modo read-only | OAuth + token Bitbucket separado | Local; cofre do SO opcional/experimental | Sai da máquina | Média/Baixa (novo, docs parciais) | developer.atlassian.com/cloud/twg-cli |
| Bitbucket | REST + API token (curl) | Endpoints REST | Escopos read-only do token (NC) + deny | API token (app password extinta) | Risco alto (token em env/arquivo) | Sai da máquina | Baixa | atlassian.com/blog |
| GitLab | MCP oficial `/api/v4/mcp` | `get_issue`/`get_work_item`, `get_merge_request`, `get_merge_request_pipelines`, `get_pipeline`, `get_job` | **Sem read-only no servidor**; só deny por nome das ferramentas de escrita | OAuth DCR (escopo `mcp`) | Não | Sai da máquina | Média | docs.gitlab.com |
| GitLab | `glab` CLI | issue/mr view/list, ci | Deny por prefixo (fraco) | OAuth web / PAT | Não por padrão (keyring) | Sai da máquina | Média | docs.gitlab.com/cli |
| Azure DevOps | MCP remoto `mcp.dev.azure.com/{org}` | `wit_work_item`, `repo_pull_request`, `pipelines_build`(`get_status`), `pipelines_run` | Header `X-MCP-Readonly: true` + escopos OAuth read + deny `*_write` | Entra ID OAuth (app registration customizado p/ Claude Code) | Não (client ID público; sem secret) | Sai da máquina; doc cita allowlist em proxy | Alta (doc) / setup pesado | learn.microsoft.com |
| Azure DevOps | `az` + extensão azure-devops | `az boards work-item show`, `az repos pr show`, `az pipelines runs show` | Deny por prefixo (fraco) | `az login` / PAT (NC) | NC | Sai da máquina | Média | learn.microsoft.com/cli |

---

## 6. Recomendação por provedor

- **GitHub** — Preferida: MCP remoto oficial em `https://api.githubcopilot.com/mcp/readonly` (com `X-MCP-Toolsets: issues,pull_requests,actions`) autenticado por **OAuth**, mais `permissions.deny` das ferramentas de escrita por nome como segunda camada. Read-only é aplicado no servidor (atende REQ-004 tecnicamente) e não há segredo em arquivo com OAuth (REQ-005). Pendente validar em teste real: OAuth do Claude Code com esse endpoint e nome do servidor configurado (prefixo `mcp__<server>__`). Alternativa: `gh` CLI (Bash do TecLeader) com deny de subcomandos de escrita e de `gh api` — documentar que é defesa em profundidade, não bloqueio forte (T4); preferir token fine-grained read-only (NC).
- **Bitbucket Cloud** — Preferida: Rovo MCP via conector claude.ai Atlassian já usado no Jira (tráfego via Anthropic, menos sensível ao Zscaler), restringindo ao grupo `read_bitbucket` e liberando no `tools` do tecleader **só** as ferramentas de leitura listadas (allowlist por nome). Requer workspace vinculado à organização. Alternativa: mesmo Rovo MCP via `.mcp.json` `https://mcp.atlassian.com/v2/mcp` (OAuth). Evitar REST/curl (app passwords extintas; API token seria segredo local) e TWG CLI (sem read-only, documentação parcial).
- **GitLab** — Viável (MCP GA, OAuth). Preferida: MCP oficial com allowlist das ferramentas de leitura no tecleader + deny das de escrita (não há read-only no servidor → bloqueio depende das regras do Claude Code por nome de ferramenta, que são exatas, ao contrário de Bash). Alternativa: `glab` com deny por prefixo. Classificar como "suporte experimental" na 1ª versão.
- **Azure DevOps** — Viável, mas setup pesado (app registration Entra por tenant, admin consent). Preferida: MCP remoto com `X-MCP-Readonly: true` + `X-MCP-Toolsets: wit,repos,pipelines` + escopos OAuth somente leitura. Alternativa: `az` + extensão `azure-devops` com deny por prefixo. Classificar como "experimental"/opcional.

### Pontos para o design (T-001)
1. Para REQ-004 com CLI, o critério "negado pelo settings" é atingível para a forma usual do comando, mas a doc oficial diz que deny de Bash não é fronteira de segurança (T4); registrar como risco aceito ou adicionar hook `PreToolUse` de allowlist.
2. Para MCP, preferir **allowlist** de ferramentas de leitura no frontmatter `tools` do tecleader + deny das de escrita; regras `mcp__` com parâmetros são ignoradas (T6), então não dá para liberar só `method=get` de uma ferramenta mista — escolher ferramentas inteiras de leitura.
3. Zscaler: conectores claude.ai passam por `mcp-proxy.anthropic.com` (mesmo destino já liberado para o Claude Code); MCPs em `.mcp.json` e CLIs saem direto para o provedor.

## Itens Não confirmados a validar em teste
- OAuth do GitHub MCP remoto no Claude Code (sem PAT) e no conector personalizado claude.ai.
- Se o conector claude.ai Atlassian expõe as ferramentas Bitbucket e como o admin restringe a `read_bitbucket`.
- Nomes exatos de ferramentas `write_bitbucket`.
- Token fine-grained GitHub somente leitura com `gh`.
- Comportamento de `gh`/`glab`/`az` com CA do Zscaler no Windows.

## Verificação empírica — GitHub MCP (TecLeader, 2026-10-09)

Config: `.mcp.json`-like via `--mcp-config` (arquivo temporário fora do projeto), `type: http`,
`url: https://api.githubcopilot.com/mcp/readonly`, headers `Authorization: Bearer ${GITHUB_PAT}` (variável de ambiente
preenchida com `gh auth token`; nenhum token em arquivo) e `X-MCP-Toolsets: context,repos,issues,pull_requests,actions`.

- Status `connected`. Ferramentas expostas (nomes reais): get_me, issue_read, list_issues, search_issues, list_issue_fields,
  list_issue_types, pull_request_read, list_pull_requests, search_pull_requests, actions_list, actions_get, get_job_logs,
  get_commit, list_commits, search_commits, list_branches, get_file_contents, search_code, list_tags, get_tag, list_releases,
  get_latest_release, get_release_by_tag, get_label, get_teams, get_team_members, list_repository_collaborators,
  search_repositories, **AssignCodingAgent**, **issue_to_fix_workflow** (sem `X-MCP-Toolsets` também `run_secret_scanning`, `search_users`).
- Nenhuma ferramenta de escrita (create/update/merge/comment) exposta no `/readonly`. `AssignCodingAgent` e
  `issue_to_fix_workflow` têm nome de ação → tratar como escrita: fora do `tools:` e em `permissions.deny`.
- Chamadas reais `list_issues` e `list_pull_requests` em `powerlok/claude-sdd-framework`: `is_error:false`, resultado 0 e 0.
- OAuth (sem PAT) não testado aqui (exige sessão interativa).
