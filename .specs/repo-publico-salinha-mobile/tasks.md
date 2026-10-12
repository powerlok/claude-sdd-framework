# Tasks: repo-publico-salinha-mobile

| ID | Objetivo | REQ | Responsável | Depende | Estado |
|----|----------|-----|-------------|---------|--------|
| T-001 | Docs e regras sem premissa de repositório privado | REQ-001 | techlead | — | DONE |
| T-002 | `mobile` em KNOWN (slot 6), nextSlot 7, teste estático | REQ-002, REQ-003 | techlead | — | DONE (run-all completo passou, SDD_OFFICE_OS=linux; 1ª execução teve uma falha não identificada, flaky conhecido da página sob carga; 2 reexecuções passaram) |
| T-003 | 0.9.1, CHANGELOG, commit com confirmação | — | techlead | T-001, T-002 | DONE |
