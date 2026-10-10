# Tasks: claude-md-layers

| ID | Objetivo | REQ | Responsável | Depende | Estado |
|----|----------|-----|-------------|---------|--------|
| T-001 | Regras (sdd-rules, tecleader), modelos, versão 0.6.2 | REQ-001..005 | general-purpose | — | DONE |
| T-002 | Revisão de segurança | REQ-002, REQ-003 | sdd:security | T-001 | DONE (volta 3: APROVADO) |
| T-003 | Validação (proposta e execução da migração; versionar=não) | todos | sdd:tests | T-001 | DONE (rodada 3: A, B, D1, D2, F PASSARAM) |
| T-004 | Docs, INDEX, commit/push, arquivar | — | tecleader | T-003 | DONE |

## Observações

- T-001 (2026-10-10): `claude plugin validate` ✔; SKILL.md 255 linhas; tecleader.md 609. Extra aceito: passo 5 do Onboarding
  (aplicar `Versionar artefatos SDD` também sem migração). Modelos em `templates/` ficam fora do cache do plugin; o texto
  descreve o conteúdo essencial do settings. README/manual (REQ-005 docs) ficam para T-004.
- T-002 e T-003 rodam em paralelo; se T-002 gerar correção, T-003 é refeito.
- T-002 volta 1 (2026-10-10): APROVADO sem HIGH/CRITICAL; MEDIUM: M-1 remoção do `.claude/` do workspace pode apagar
  conteúdo não migrado; M-2 modelo de settings fora do repo/deny do workspace perdido; M-3 allow/env/defaultMode do workspace
  no settings versionado; M-4 exclude sem efeito em arquivo rastreado. LOW: L-1 symlinks/nomes; L-2 `git rev-parse --git-path`;
  L-3 "sem perguntar" × confirmação; L-4 inconsistências. Decisão: corrigir todos (T-001 → FIXING), refazer T-002 e T-003.
- T-001 correção (2026-10-10): M-1..M-4 e L-1..L-4 tratados (pré-verificações, plano em 6 passos, `.claude.bak-<data>`); validate ✔; SKILL.md 256 linhas. T-002 volta 2 iniciada.
- T-002 volta 2 (2026-10-10): RISCO IDENTIFICADO, sem HIGH. N-1 MEDIUM settings.local.json com env/allow pode não estar ignorado (check-ignore); N-2 spec/CHANGELOG/template com texto antigo (spec corrigida pelo TecLeader); N-3 origem de `.specs`/`CLAUDE.md` do workspace sem regra (→ `.bak-<data>`); N-4 known_marketplaces: chave `claude-sdd-framework` e só chaves permitidas do modelo; N-5 avisar perda de deny no workspace. T-001 → FIXING.
- T-003 rodada 1 (texto anterior às correções de segurança): A–E PASSARAM (A: 1 pergunta; B: mesclado, 133 deny, sem commit; C: parou no conflito; D: settings.local + exclude sem duplicar, .gitignore intocado; E: só 'qual projeto'). O-001 (remover × renomear inconsistente) resolvido pela correção M-1/N-3. O-002: modelos em `templates/` fora do plugin — achados via clone do marketplace (só atualizado após push); com --plugin-dir, só se o repo do framework estiver local. Aceito como limitação; revalidar após push. T-003 será refeito (B, C, D) sobre o texto final.
- T-001 correção 2 (2026-10-10): N-1..N-5 tratados; validate ✔. T-002 volta 3 (última) e T-003 rodada 2 (B, C, D, F) iniciadas.
- T-002 volta 3 (2026-10-10): APROVADO, sem HIGH/CRITICAL/MEDIUM. O-2 (CHANGELOG 'settings completo') corrigido. O-1 LOW (settings.local.json já rastreado com Versionar=sim; `git -C <repo>`) a aplicar após T-003 rodada 2. Docs (README, manual, arquitetura) atualizados para 0.6.2.
- T-003 rodada 2 (2026-10-10): A, B, C, F PASSARAM (B: deny 133, sem allow/env, fake-123 ausente do repo, commands/x.md mantido e .claude não renomeado; F: parou, sem git rm/update-index). D FALHOU: D-001 settings.local.json não criado no onboarding com Versionar=não (flaky). O-001: segunda pergunta sobre allow/env. Correção: D-001 + O-001 + O-1 (segurança) → FIXING (ciclo 1/3).
- Correção ciclo 1 (2026-10-10): D-001 (settings sempre criado do modelo), O-001 (allow/env não migrados, sem pergunta), O-1 (`git -C <repo>`, ls-files dos settings) + oferta de onboarding cita o settings (tecleader.md:268, TecLeader). validate ✔. T-003 rodada 3: A, B, D, F.
- T-003 rodada 3 (2026-10-10): A, B, D1, D2, F PASSARAM; 1 pergunta por proposta; sem defeito aberto. T-004: docs 0.6.2 (README, manual, arquitetura), CHANGELOG, arquivamento, commit/push, update no workspace.
- Arquivamento (2026-10-10): `.specs/claude-md-layers/` → `.specs/done/claude-md-layers/`; CHANGELOG atualizado; INDEX atualizado; linkcheck 104/0.
