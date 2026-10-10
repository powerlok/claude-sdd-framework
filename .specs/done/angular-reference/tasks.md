# Tasks: angular-reference (GH#1)

| ID | Objetivo | REQ | Responsável | Depende | Estado |
|----|----------|-----|-------------|---------|--------|
| T-001 | Pesquisa: fontes oficiais Angular + skills/guias públicos (licenças) | REQ-005 | general-purpose (leitura web) | — | DONE (research.md; v22 estável; fontes e licenças) |
| T-002 | Escrever `references/angular.md` + atualizar `SKILL.md` | REQ-001, 002, 003, 005 | frontend | T-001 | IMPLEMENTED (angular.md 223 linhas; SKILL.md atualizado; validate OK) |
| T-003 | Revisão de segurança (cópia, atribuição, injeção) | REQ-005 | security | T-002 | DONE (volta 2 APROVADO; O-01 resolvido: commit ff69483 no rodapé) |
| T-004 | Validação + piloto `sdd:frontend` Stack Angular | REQ-003, 004 | tests | T-003 | DONE (validation-report.md: REQ-001..004 VALIDADO; piloto v21 correto) |
| T-005 | Docs (README, manual, arquitetura), versão `sdd` 0.3.0, commit/push | — | tecleader | T-004 | DONE (README, manual, arquitetura, CHANGELOG; sdd 0.3.0; push com Closes #1) |
