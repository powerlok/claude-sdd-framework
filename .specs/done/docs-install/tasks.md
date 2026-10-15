# Tasks: docs-install

| ID | Objetivo | REQ | Responsável | Depende | Estado |
|----|----------|-----|-------------|---------|--------|
| T-001 | `scripts/check-env.sh` e `.ps1` + testes com stubs | REQ-003, REQ-005 | techlead | — | DONE |
| T-002 | `docs/instalacao.md` (tipos A–F, CLI por SO) com comandos conferidos | REQ-001, REQ-002 | techlead | T-001 | DONE |
| T-003 | README curto, `docs/referencia.md`, `primeiros-passos.md`, manual e arquitetura | REQ-004 | techlead | T-002 | DONE |
| T-004 | Testes de docs (links, versões, comandos) e fluxo real em sandbox; CI; CHANGELOG | REQ-005, REQ-006 | techlead | T-003 | DONE |
