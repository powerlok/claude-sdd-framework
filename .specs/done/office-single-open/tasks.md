# Tasks: office-single-open

| ID | Objetivo | REQ | Responsável | Depende | Estado |
|----|----------|-----|-------------|---------|--------|
| T-001 | Atividade da sala no `office-start.sh` (30 min) | REQ-001..004 | techlead | — | DONE |
| T-002 | Testes em `req002-start.test.sh` | REQ-005 | techlead | T-001 | DONE (36 ok) |
| T-003 | Docs, CHANGELOG, `sdd` 0.9.3; validate e suíte | REQ-005 | techlead | T-002 | DONE (run-all completo verde; 4 falhas de carga numa rodada concorrente, reexecução limpa) |
