# Tasks: publish-opt-in

| ID | Objetivo | REQ | Responsável | Depende | Estado |
|----|----------|-----|-------------|---------|--------|
| T-001 | Design curto (grupo × fixo, estados, fluxo do onboarding) | REQ-001..006 | techlead | spec aprovada | DONE (design.md; revisado após o parecer) |
| T-002 | Parecer de segurança do design | REQ-003..005 | revisor independente (papel sdd:security) | T-001 | DONE (APROVADO COM CONDIÇÕES; decisões do usuário: alternativa A e push com confirmação) |
| T-003 | Modelos de settings, `publicacao.json`, `techlead.md`, `git-workflow.md`, governança, skill `publish` | REQ-001..006 | techlead | T-002 | DONE |
| T-004 | Teste `req007-publicacao.test.js` (50 ok), `run-all --no-page`, `validate --strict` | REQ-007 | techlead | T-003 | DONE (simulação de glob; motor real de permissões não testado) |
| T-005 | Re-revisão de segurança da implementação | REQ-001..005 | revisor independente | T-003 | DONE (APROVADO COM CONDIÇÕES; M-A..M-E corrigidas) |
| T-006 | Docs, CHANGELOG 0.9.2, versão | REQ-006 | techlead | T-003 | DONE |
| T-007 | Piloto real no Claude Code | todos | techlead (sandbox) | T-005 | PARCIAL: sandbox com `claude -p` (CLI 2.1.296, remoto local, `gh` falso): sem decisão, `confirmar`, `bloqueada` e `inconsistente` (allow `Bash(gh *)`) se comportaram como projetado (nada publicado sem confirmação); achou e corrigiu 2 deny de push ineficazes e `Write(...)` ignorado. NÃO executado: prompt interativo de confirmação, gravação do `settings.local.json` (em `-p` o `ask` nega), `/sdd:publish` e publicação real. |
| T-008 | Arquivar spec; commit/PR só com confirmação | — | techlead | T-005, T-007 | TODO |
