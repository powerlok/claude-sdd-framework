# Tasks: office-working-state

| ID | Objetivo | REQ | Responsável | Depende | Estado |
|----|----------|-----|-------------|---------|--------|
| T-001 | Diagnosticar (reproduzir H1–H3) e corrigir | REQ-001..005 | sdd:frontend | — | DONE |
| T-002 | Validação (suíte + piloto real com comando longo) | todos | sdd:tests | T-001 | PARCIAL: suíte completa e validate ok; piloto real NÃO executado |
| T-003 | Versão 0.8.1, CHANGELOG, arquivar, commit; release só com confirmação | REQ-005 | techlead | T-002 | DONE (release v0.9.1) |
