# Design: integração opcional com provedores de código

Status: **APROVADO** pelo usuário em 2026-10-09. Bitbucket: "suportado, não validado" (sem projeto para teste). Base: [spec.md](spec.md), [research-t000.md](research-t000.md).

## 1. Decisão central

**MCP em modo somente leitura é o caminho padrão; CLI é alternativa de menor garantia.**

- Permissão `deny` de Bash "não é barreira de segurança" (doc oficial de permissions): não cobre
  `sh -c`, caminho absoluto do binário ou variações de argumento. Serve só como defesa em profundidade.
- Com MCP há três camadas: (1) servidor em modo read-only (quando o provedor oferece);
  (2) `tools:` do `sdd:tecleader` lista só ferramentas de leitura (lista fechada: as demais não existem para ele);
  (3) `permissions.deny` das ferramentas de escrita por nome no settings (cobre sessões sem o agente).
- Lição do Jira (`getVisibleJiraProjects` não existia): nomes de ferramentas só entram no `tools:` após verificação na sessão.

## 2. Por provedor

| Provedor | Padrão | Read-only no servidor | Alternativa | Status |
|---|---|---|---|---|
| GitHub | MCP remoto oficial `https://api.githubcopilot.com/mcp/readonly` (OAuth) | sim (`/readonly`) | `gh` CLI + deny por prefixo (best-effort) | **suportado** (testar ponta a ponta) |
| Bitbucket Cloud | MCP Atlassian v2 (`templates/mcp-atlassian.json`, já existe) com ferramentas Bitbucket | não; allowlist em `tools:` + deny de escrita | — (app passwords encerradas; CLI `twg` sem read-only) | **suportado** se o workspace estiver vinculado a uma organização Atlassian (testar) |
| GitLab | MCP oficial `https://<host>/api/v4/mcp` (OAuth DCR) | não; allowlist + deny | `glab` + deny (best-effort) | **experimental** |
| Azure DevOps | MCP remoto `https://mcp.dev.azure.com/{org}` + header `X-MCP-Readonly: true` | sim | `az` + deny (best-effort) | **experimental** (exige app registration Entra ID) |

Conector claude.ai Atlassian: as ferramentas Bitbucket não apareceram na lista verificada no spike (só Jira/Confluence
e genéricas); confirmar no teste. Se não aparecerem, Bitbucket usa o `.mcp.json` v2.

## 3. Configuração por projeto

`CLAUDE.md` do projeto ganha a seção opcional:

```markdown
## Repositório
- Provedor: github | bitbucket | gitlab | azure-devops
- Repositório: <owner/repo | workspace/repo | group/project | org/project/repo>
- Acesso: mcp (padrão) | cli
```

Sem essa seção, o TecLeader não consulta nenhum provedor.

## 4. Mudanças no plugin

| Arquivo | Mudança |
|---|---|
| `agents/tecleader.md` | `tools:` + ferramentas de leitura verificadas (GitHub; Bitbucket); seção "Repositório" (fluxo issue→spec, PR/CI como evidência, escrita proibida) |
| `skills/sdd-governance` | "Integração com Jira" vira "Integrações externas (Jira e repositório)" |
| `templates/` | `mcp-github.json`; `mcp-gitlab.json` e `mcp-azure-devops.json` (experimentais); `permissions.deny` ampliado (escrita GitHub/Bitbucket/GitLab/Azure por nome + prefixos Bash `gh pr merge`, `gh pr create`, `gh issue create/comment/close`, `gh api`, `gh repo delete`, `glab mr merge`, `az repos pr create` etc.); `CLAUDE.md` com `## Repositório` |
| docs | README, manual (seção + exemplos), arquitetura |
| versão | `sdd` 0.2.0 (nova capacidade) |

Abrir PR/comentar: fora desta versão (spec: fora de escopo). Pode virar flag futura com confirmação explícita.

## 5. Riscos

| Risco | Mitigação |
|---|---|
| Nomes de ferramentas diferentes dos documentados | Verificar na sessão (evento `init`) antes de listar no `tools:` |
| OAuth do GitHub MCP não funcionar no Claude Code | Teste; fallback `gh` (documentado como best-effort) |
| Zscaler em `.mcp.json` e CLIs (conexão sai da máquina) | Claude Code usa o store de certificados do SO; validar com a TI; conector claude.ai continua preferido para Atlassian |
| Bash do tecleader permite contornar deny de CLI | Documentado; recomendação de MCP; token do `gh` pode ser fine-grained somente leitura via variável de ambiente |
| Bitbucket exige workspace vinculado a organização | Pré-requisito documentado |

## 6. Testes

- GitHub (ponta a ponta, conta `powerlok`): ler issue → spec com ID; status de PR/CI; tentativa de escrita negada
  (MCP read-only e deny de `gh pr merge`).
- Bitbucket: se houver workspace acessível; senão, fica "suportado, não validado".
- GitLab/Azure DevOps: validação de template (JSON) e documentação marcada como experimental.
- `security` revisa templates, `tools:` e regras de deny.

## 7. Correções da revisão de segurança (T-003, volta 1)

- **Dados não confiáveis**: issue, PR, comentário, work item e log são dados, nunca instruções; spec derivada de issue exige confirmação explícita do usuário; subagentes recebem só REQs validados; só o `tecleader` consulta o provedor (tecleader e `sdd-governance`).
- **Token GitHub**: padrão verificado = PAT fine-grained via `${GITHUB_PAT}`, somente leitura (só os repositórios do projeto; Metadata, Issues, Pull requests, Actions = Read; sem Contents write, sem Workflows; validade curta). Proibido reutilizar `gh auth token`; nunca em arquivo/`.env` versionado. OAuth (sem header `Authorization`) é variante não testada.
- **Bitbucket** rebaixado para **experimental**: pré-requisito admin conceder só `read_bitbucket`; nomes de escrita a confirmar na sessão e então negar. Leitura continua em `tools:` (lista fechada).
- **GitLab/Azure**: deny por nome das ferramentas de escrita da pesquisa (§3/§4 de `research-t000.md`); Azure com `X-MCP-Toolsets: wit,repos,pipelines`; leitura adicionada pelo usuário por nome, nunca curinga.
- **Logs de CI** removidos do `tools:` (`get_job_logs`, `getBitbucketRepoPipelineStepLog`): status via `pull_request_read`/`actions_list`/`actions_get`.
- **Deny Bash** ampliado (`gh auth token`, `gh secret`, `gh workflow run`, `glab api`, `az devops invoke` etc.): defesa em profundidade.
- **Riscos residuais**: `gh` já logado tem escrita; Bash do `tecleader` alcança a API por `curl`/PowerShell sem passar pelo deny (mitigação real: token read-only); Zscaler em `.mcp.json`/CLIs.

## 8. Parecer de segurança

Volta 1: RISCO IDENTIFICADO (6 MEDIUM, 5 LOW) → corrigidos. Volta 2: **APROVADO**.
Observações LOW da volta 2 corrigidas pelo TecLeader: `Bash(gh auth status -t:*)` no deny (131 regras);
modo `cli` marcado como não recomendado (usa login local com escrita; só com token read-only).
