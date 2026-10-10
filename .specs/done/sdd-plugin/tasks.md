# Tasks: Plugin SDD compartilhável

| ID | Objetivo | REQ | Responsável | Depende | Estado |
|----|----------|-----|-------------|---------|--------|
| T-000 | Verificar na doc oficial: regras em plugin, agente principal de plugin, frontmatter, `skills:`, MCP, marketplace local/git, settings do projeto, hooks, references | REQ-001..005 | claude-code-guide (leitura) | — | DONE (ver research-t000.md; itens "Revalidar" seguem para o spike do T-001) |
| T-001 | Design técnico (`design.md`): estrutura do plugin, onde ficam as regras, versionamento, migração do workspace | REQ-001..009 | tecleader (+ infra-architect se necessário) | T-000 | DONE (design APROVADO 2026-10-09; spike em spike-result.md) |
| T-002 | Agentes agnósticos de linguagem + `skills:` + delegação com stack/referência; skills `sdd-rules` e `sdd-governance`; `plugin.json`; `hooks.json` | REQ-002, REQ-003, REQ-004 | general-purpose (artefatos de processo, sem stack) | T-001 | DONE (validate OK, sem menções de stack; validação comportamental na T-008; validado na T-008, security APROVADO) |
| T-003 | Skill `backend-engineering` (.NET, Python) | REQ-005 | backend | T-001 | DONE (verificado: links OK, sem versões afirmadas; comandos de exemplo validados no piloto T-008; validado na T-008, security APROVADO) |
| T-004 | Skill `frontend-engineering` consolidando e corrigindo as 3 skills de frontend (React) | REQ-005, REQ-006 | frontend | T-001 | DONE (verificado: links OK, sem URL remota, licença Apache-2.0 copiada; validado na T-008, security APROVADO) |
| T-005 | Incorporar grilling, diagnosing-bugs, domain-modeling (checar licença) | REQ-007 | general-purpose | T-001 | DONE (verificado: texto próprio, inspiração MIT citada com commit; validate OK; validado na T-008, security APROVADO) |
| T-006 | Marketplace local + configuração modelo de projeto + catálogo | REQ-001, REQ-008 | general-purpose | T-002..T-005 | DONE (verificado: validate OK em marketplace, sdd e authoring; JSON OK; cópia idêntica; validado na T-008, security APROVADO) |
| T-007 | Revisão de segurança (hooks, scripts, conteúdo de terceiros) | REQ-001, REQ-006, REQ-007 | security | T-006 | DONE (volta 2 APROVADO; ver security-review.md; achado 5 → README T-009) |
| T-008 | Validação: instalação local, piloto Python e .NET, regressão `app-workshop` | todos | tests | T-007 | DONE (T-008a 5/5 + regressão app-workshop 9/9 unit, build OK, 6/6 e2e em porta isolada; T-008b Python 13/13; T-008c .NET 12/12; ver validation/t008{a,b,c}.md; D-001 corrigido e reverificado; D-003 ambiental) |
| T-009 | README do projeto | REQ-009 | tecleader | T-008 | DONE (README.md; comandos executados: validate, install sdd/authoring, update) |
| T-010 | Reescrever skills `skill-development` e `agent-development` do `authoring` com texto próprio (doc oficial + convenções do spike); remover cópias proprietárias de anthropics/claude-code | REQ-007, REQ-008 | general-purpose | T-006 | DONE (security volta 2 APROVADO; decisão do usuário: opção 2; texto limpo via doc oficial; validate OK; v0.2.0) |
| T-011 | Migrar o workspace `workshop` para o plugin `sdd` (backup antes; remover duplicados de `.claude/`) | REQ-002, REQ-003 | tecleader | T-008 | DONE (backup verificado; plugin instalado; duplicados removidos com autorização do usuário em 2026-10-10) |

Somente o tecleader encerra tasks, com evidências.

## Decisões registradas

- 2026-10-09: distribuição via plugin + marketplace (preferência do usuário: compartilhar com outros devs e projetos).
- 2026-10-09: repositório no Bitbucket, a definir; por enquanto local, sem push.
- 2026-10-09: nenhuma skill de terceiros instalada como está; trechos incorporados com origem e licença.
- 2026-10-09: Jira: conector claude.ai como padrão; `.mcp.json` (MCP remoto oficial Atlassian) como modelo opcional em `templates/`; testar com Zscaler ativo.

## Defeitos abertos (T-008)

- D-001 (LOW) — CORRIGIDO em sdd 0.1.2: `${CLAUDE_PLUGIN_ROOT}` no corpo dos agentes (verificado: caminho resolvido chega ao sdd:backend). Original: agentes não recebem o caminho absoluto das `references/`; no piloto .NET o `sdd:backend` achou `dotnet.md` por busca (~5 chamadas) e leu a cópia do cache de outra instalação, não a do `--plugin-dir`. Risco: falhar sem instalação prévia. Fonte: validation/t008c.md.
- D-002 (LOW): `--allowedTools` é variádica; prompt deve vir logo após `-p` nos comandos documentados.
- D-003 — RESOLVIDO (ambiental, não é regressão): porta 4173 ocupada pelo Vite de outro projeto do usuário (outro projeto local do usuÃ¡rio); `reuseExistingServer: true` fez o Playwright testar o app errado. Reexecutado em porta isolada 4180 com config temporária fora do projeto: 6/6 passed. Observação (fora de escopo, não corrigida): `app-workshop/playwright.config.ts` reaproveita qualquer servidor na 4173.
- 2026-10-09: limpeza confirmada pelo usuário: removidos `spike/`, `sdd-spike-test`, `sdd-install-test`, `sdd-pilot-python`, `sdd-pilot-dotnet` e os marketplaces/plugins de teste do Claude Code.
