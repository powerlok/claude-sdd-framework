# Tasks: specs-done-archive

| ID | Objetivo | REQ | Responsável | Depende | Estado |
|----|----------|-----|-------------|---------|--------|
| T-001 | Regras no plugin (tecleader, sdd-rules, sdd-governance, template), versão 0.5.0 | REQ-001..005 | general-purpose | — | DONE (tecleader, sdd-rules, sdd-governance, template, hook; 0.5.0; validado na T-003) |
| T-002 | Migração deste repositório + `.specs/INDEX.md` + links | REQ-006 | tecleader | T-001 | DONE (5 features em done/ via git mv; INDEX.md; links 93/0 quebrados; validado na T-003) |
| T-003 | Validação: links, piloto de arquivamento | todos | tests | T-002 | DONE (validation-report.md: estático + 2 pilotos VALIDADOS) |
| T-004 | Docs, commit/push, arquivar esta feature | — | tecleader | T-003 | DONE (docs 0.5.0; arquivada em .specs/done/; push) |
