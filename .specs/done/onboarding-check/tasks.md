# Tasks: onboarding-check

| ID | Objetivo | REQ | Responsável | Depende | Estado |
|----|----------|-----|-------------|---------|--------|
| T-001 | Script + hook + regras no tecleader, versão 0.6.0 | REQ-001..004 | general-purpose | — | DONE (script + hook startup + seção no tecleader; 0.6.0; validado) |
| T-002 | Revisão de segurança (hook/script) | REQ-001 | security | T-001 | DONE (volta 2 APROVADO) |
| T-003 | Validação nos 4 cenários | todos | tests | T-002 | DONE (6 cenários VALIDADOS; C e E retestados com a versão final) |
| T-004 | Docs, INDEX, commit/push, arquivar | — | tecleader | T-003 | DONE (docs 0.6.0; arquivada; push) |
