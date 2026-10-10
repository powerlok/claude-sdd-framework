# Tasks: vcs-integration

| ID | Objetivo | REQ | Responsável | Depende | Estado |
|----|----------|-----|-------------|---------|--------|
| T-000 | Pesquisa: opções oficiais por provedor (CLI e MCP), modo somente leitura, regras de permissão do Claude Code para Bash/MCP, Zscaler | REQ-001..005 | general-purpose (leitura web) | — | DONE (research-t000.md; itens NC seguem para teste) |
| T-001 | Design (`design.md`) + aprovação do usuário | todos | tecleader | T-000 | DONE (design APROVADO; GitHub MCP verificado empiricamente, ver research-t000.md) |
| T-002 | Implementação (tecleader, sdd-governance, templates, CLAUDE.md template) | REQ-001..005 | general-purpose | T-001 | DONE (validate OK; tools sem escrita; deny 46; security APROVADO; validado na T-004) |
| T-003 | Revisão de segurança | REQ-004, REQ-005 | security | T-002 | DONE (volta 2 APROVADO; 2 LOW corrigidos; ver design.md §7-8) |
| T-004 | Validação ponta a ponta | todos | tests | T-003 | DONE (parte A 6/6, parte B 5/5 com issue real GH#1; ver validation-report.md) |
| T-005 | Documentação (README, manual, arquitetura) | REQ-006 | frontend (manual) + general-purpose (md) | T-004A | DONE (README, manual 18 exemplos, arquitetura; 0 recursos externos; 320px OK; exemplo 16 agora Verificado) |
