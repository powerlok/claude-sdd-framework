# Tasks: office-visual

| ID | Objetivo | REQ | Responsável | Depende | Estado |
|----|----------|-----|-------------|---------|--------|
| T-001 | Nitidez e layout do office.html | REQ-001..003 | sdd:frontend | — | DONE |
| T-002 | Validação visual e suíte | todos | sdd:tests | T-001 | DONE (suíte de página 50 ok + estática 35 ok; capturas lidas pelo TecLeader) |
| T-003 | Versão 0.7.1, CHANGELOG, arquivar, commit | REQ-004 | tecleader | T-002 | DONE |
- 2026-10-11: nitidez (dpr), layout, balões sem sobreposição + teste de regressão (1280/375). Capturas 3-trabalhando e 11-baloes-simultaneos lidas pelo TecLeader. Segurança dispensada (só renderização; grep sem innerHTML/URLs). Versão 0.7.1; sem release.
