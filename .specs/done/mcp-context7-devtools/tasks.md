# Tasks: mcp-context7-devtools

| ID | Objetivo | REQ | Responsável | Depende | Estado |
|----|----------|-----|-------------|---------|--------|
| T-001 | Lançadores `mcp/context7.js` e `mcp/devtools.js` + `.mcp.json` | REQ-001, REQ-003 | techlead | — | DONE |
| T-002 | Agentes (tools e regras) e skills | REQ-002, REQ-004 | techlead | T-001 | DONE |
| T-003 | Modelos de settings (deny/ask) | REQ-005 | techlead | T-001 | DONE |
| T-004 | Testes `req015` e `req016`; teste de docs (versão lançada) | REQ-006 | techlead | T-002, T-003 | DONE |
| T-005 | Docs, CHANGELOG, `sdd` 0.13.0; parecer de segurança | REQ-006 | techlead | T-004 | DONE |
| T-006 | Validação real: `tools/list`, piloto no CLI | REQ-007 | techlead | T-005 | DONE |
