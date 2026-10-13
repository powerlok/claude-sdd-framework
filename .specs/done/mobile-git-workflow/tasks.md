# Tasks: mobile-git-workflow

| ID | Objetivo | REQ | Responsável | Depende | Estado |
|----|----------|-----|-------------|---------|--------|
| T-001 | Design curto: agente mobile, skill, seção `## Git`, comando `git-lang`, permissões | REQ-001..009 | techlead | — | DONE (aprovado 2026-10-11) |
| T-002 | Agente `sdd:mobile` + skill `mobile-engineering` (+ react-native-expo.md) + delegação no TechLead | REQ-001..004 | general-purpose | T-001 | IMPLEMENTED (validate pendente: CLI fora do PATH; salinha sem `mobile`, office.html em uso pela office-working-state) |
| T-003 | `git-workflow.md`, `## Git` no onboarding, comando `/sdd:git-lang`, regras de commit/branch no TechLead, deny/templates | REQ-005..009 | general-purpose | T-001 | IMPLEMENTED (run-all --no-page ok; validate pendente: CLI fora do PATH) |
| T-004 | Checklist mobile no `sdd:security` + parecer de REQ-007/008/009 | REQ-003, 007..009 | sdd:security | T-002, T-003 | DONE (APROVADO na volta 2; motor de permissões real não testado) |
| T-005 | Docs, CHANGELOG, plugin.json 0.9.0, validate, suíte | REQ-010 | general-purpose | T-002, T-003 | DONE |
| T-006 | Validação ponta a ponta (Expo temporário, git temporário, CLI real) | todos | sdd:tests | T-004, T-005 | PARCIAL: Expo, git temporário, regex, suíte e links ok; NÃO EXECUTADO: CLI real (validate, delegação, /sdd:git-lang, permissões) |
| T-007 | Arquivar spec; commit só com confirmação | — | techlead | T-006 | ENCERRADA (validação parcial aceita pelo usuário, 2026-10-13) |
