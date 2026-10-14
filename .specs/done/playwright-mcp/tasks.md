# Tasks: playwright-mcp

| ID | Objetivo | REQ | Responsável | Depende | Estado |
|----|----------|-----|-------------|---------|--------|
| T-001 | `.mcp.json` + lançador `mcp/playwright.js` | REQ-001 | techlead | — | DONE |
| T-002 | `frontend.md` (tools + regras), skill `frontend-engineering`, modelos de settings | REQ-002..004 | techlead | T-001 | DONE |
| T-003 | Teste `req010-playwright.test.sh`, CLI real, `validate --strict` | REQ-005 | techlead | T-002 | DONE (52 ok; CLI real: frontend abre página local, lê título, recusa injeção de prompt; janela visível e TUI interativa não verificadas) |
| T-004 | Parecer de segurança independente | todos | revisor independente | T-003 | DONE (APROVADO COM CONDIÇÕES, 0 HIGH; C1-C5 cumpridas) |
| T-005 | Docs, CHANGELOG, `sdd` 0.9.8 | REQ-005 | techlead | T-004 | DONE |
