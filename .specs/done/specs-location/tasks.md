# Tasks: specs-location

| ID | Objetivo | REQ | Responsável | Depende | Estado |
|----|----------|-----|-------------|---------|--------|
| T-001 | Regra no sdd-rules + hook git=/subrepos= + tecleader; versão 0.6.1 | REQ-001..004 | general-purpose | — | DONE (hook git=/subrepos= sem executar git; regra no sdd-rules; tecleader; 0.6.1; validado) |
| T-002 | Revisão de segurança (hook) | REQ-002 | sdd:security | T-001 | DONE (APROVADO; LOW de disponibilidade em `/` corrigido: 30 s → 0,4 s) |
| T-003 | Validação nos 4 cenários | todos | sdd:tests | T-002 | DONE (4 cenários VALIDADOS; validation-report.md) |
| T-004 | Docs, INDEX, commit/push, arquivar | — | tecleader | T-003 | DONE (docs 0.6.1; arquivada; push) |
