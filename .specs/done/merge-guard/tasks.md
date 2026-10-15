# Tasks: merge-guard

| ID | Objetivo | REQ | Responsável | Depende | Estado |
|----|----------|-----|-------------|---------|--------|
| T-001 | `hooks/merge-guard.sh` e entrada em `hooks.json` | REQ-001, REQ-002, REQ-003 | techlead | — | DONE (CLI real: bypassPermissions + sh -c bloqueado pelo hook; CI nos 3 sistemas a conferir) |
| T-002 | `req013-mergeguard.test.sh` + `run-all.sh` | REQ-005 | techlead | T-001 | DONE (CLI real: bypassPermissions + sh -c bloqueado pelo hook; CI nos 3 sistemas a conferir) |
| T-003 | Docs, CHANGELOG, `sdd` 0.12.0; CI nos 3 sistemas | REQ-004, REQ-005 | techlead | T-002 | DONE (CLI real: bypassPermissions + sh -c bloqueado pelo hook; CI nos 3 sistemas a conferir) |
