# Tasks: infra-engineering

| ID | Objetivo | REQ | Responsável | Depende | Estado |
|----|----------|-----|-------------|---------|--------|
| T-001a | Pesquisa AWS | REQ-004 | general-purpose (leitura web) | — | DONE (research-aws.md; docs AWS CC BY-SA → só fatos) |
| T-001b | Pesquisa Azure | REQ-004 | general-purpose (leitura web) | — | DONE (research-azure.md) |
| T-001c | Pesquisa Google Cloud | REQ-004 | general-purpose (leitura web) | — | DONE (research-gcp.md; domínio docs.cloud.google.com) |
| T-002 | Escrever skill `infra-engineering` (SKILL.md + 3 references) | REQ-001, 002, 004, 005 | general-purpose (redação técnica) | T-001a..c | DONE (SKILL.md 170; aws 234; azure 228; gcp 239; 14 seções cada; security APROVADO; validado na T-005) |
| T-003 | `infra-architect` agnóstico + `skills:` + `${CLAUDE_PLUGIN_ROOT}`; tecleader/templates (`## Stack` com nuvem) | REQ-003 | general-purpose | T-001 | DONE (infra-architect agnóstico; skills: + infra-engineering; tecleader e template; validado na T-005) |
| T-004 | Revisão de segurança | REQ-004, 005 | security | T-003 | DONE (volta 3 APROVADO; observação LOW de alinhamento aplicada) |
| T-005 | Validação + pilotos Azure e GCP | todos | tests | T-004 | DONE (9/9; pilotos Azure, GCP e AWS corretos; validation-report.md) |
| T-006 | Docs, versão `sdd` 0.4.0, commit/push | — | tecleader | T-005 | DONE (README, arquitetura, manual, CHANGELOG; sdd 0.4.0; push) |
