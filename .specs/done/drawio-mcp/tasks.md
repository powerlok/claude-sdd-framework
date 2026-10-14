# Tasks: drawio-mcp

| ID | Objetivo | REQ | Responsável | Depende | Estado |
|----|----------|-----|-------------|---------|--------|
| T-001 | `.mcp.json` + lançador `mcp/drawio.js` | REQ-001 | techlead | — | DONE |
| T-002 | `infra-architect.md` (tools + regras) e skill `infra-engineering` | REQ-002, REQ-003 | techlead | T-001 | DONE |
| T-003 | Teste `req009-drawio.test.sh`, CLI real, `validate --strict` | REQ-005 | techlead | T-002 | DONE (31 ok; CLI real: arquiteto chama `get_drawio_reference`; a TUI interativa e `open_*` abrindo o navegador não foram exercitados) |
| T-004 | Parecer de segurança independente | todos | revisor independente | T-003 | DONE (APROVADO COM CONDIÇÕES, sem HIGH; C1-C5 cumpridas) |
| T-005 | Docs, CHANGELOG, `sdd` 0.9.7 | REQ-004, REQ-005 | techlead | T-004 | DONE |
