# Tasks: start-command

| ID | Objetivo | REQ | Responsável | Depende | Estado |
|----|----------|-----|-------------|---------|--------|
| T-001 | Skill `start` | REQ-001, REQ-002 | techlead | — | DONE |
| T-002 | Banner, testes, docs, CHANGELOG, `sdd` 0.9.6 | REQ-003..005 | techlead | T-001 | DONE |
| T-003 | Verificação no CLI real (sandbox) | REQ-005 | techlead | T-002 | DONE (`claude -p "/sdd:start"`: TechLead + pergunta de onboarding; TUI interativa não verificada) |
