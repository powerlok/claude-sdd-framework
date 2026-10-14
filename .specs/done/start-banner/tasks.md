# Tasks: start-banner

| ID | Objetivo | REQ | Responsável | Depende | Estado |
|----|----------|-----|-------------|---------|--------|
| T-001 | `start-banner.sh` + `hooks.json` | REQ-001..003 | techlead | — | DONE |
| T-002 | Testes `req008-banner.test.sh` e `run-all.sh` | REQ-005 | techlead | T-001 | DONE (13 ok) |
| T-003 | Docs (passo 3, README, manual, troubleshooting), CHANGELOG, `sdd` 0.9.5, validate | REQ-004, REQ-005 | techlead | T-002 | DONE (CLI real: hook_response com o systemMessage; exibição na TUI interativa não verificada) |
