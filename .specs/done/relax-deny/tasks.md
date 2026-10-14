# Tasks: relax-deny

| ID | Objetivo | REQ | Responsável | Depende | Estado |
|----|----------|-----|-------------|---------|--------|
| T-001 | Mover git e escrita externa de `deny` para `ask` nos modelos | REQ-001 | techlead | — | DONE |
| T-002 | Textos do TechLead, `sdd-rules`, `sdd-governance`, `git-workflow` | REQ-002 | techlead | T-001 | DONE |
| T-003 | Testes (`req007`, `req009`, `req010`) e sandbox no CLI real | REQ-003 | techlead | T-002 | DONE (req007 93 ok; CLI real: os modelos carregam sem regra inválida, só os 2 avisos informativos de `:**`; o prompt interativo de `ask` não foi exercitado) |
| T-004 | Docs, CHANGELOG, `sdd` 0.10.0, arquivo proposto do workspace | REQ-003, REQ-004 | techlead | T-003 | DONE |
