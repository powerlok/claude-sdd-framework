# Tasks: rename-techlead

| ID | Objetivo | REQ | Responsável | Depende | Estado |
|----|----------|-----|-------------|---------|--------|
| T-001 | Renomeação em todo o repositório + agente obsoleto + docs/CHANGELOG/versão | REQ-001..005 | general-purpose | — | IMPLEMENTED |
| T-002 | Validação (grep, validate, suíte, pilotos reais) | todos | sdd:tests | T-001 | DONE (pilotos reais ok; D-001 corrigido pelo TecLeader) |
| T-003 | Arquivar, commit; release/tag e push só com confirmação; atualizar workspace | — | techlead | T-002 | DONE |
- T-001 (2026-10-11): 33 arquivos renomeados; agents/techlead.md (completo) + agents/tecleader.md (obsoleto, tools: Read); templates com sdd:techlead; sdd 0.8.0; CHANGELOG/primeiros-passos/README com migração; validate --strict ✔ x3; run-all --no-page ok; página 50 ok; linkcheck 134/0. TecLeader conferiu agents/ e templates. Pendente: pilotos reais (T-002).
- T-002 (2026-10-11, CLI real): casos 1–6 PASSARAM após D-001 (INDEX.md:3 corrigido). --agent sdd:techlead ok (skills, hook, delegação a sdd:tests, salinha com placa TechLead, events.js válido); --agent sdd:tecleader = obsoleto, tools Read, só instrução de migração, fixture intacto (md5); templates ok. Observações: (1) page test 375 px falhou 1x sob carga (balões), passou 2x isolado e run-all repetido — flaky, a observar; (2) premissa errada do TecLeader no prompt: ~/.claude/sdd/office.conf (on, 17:08) JÁ existia (preferência do usuário) e foi removido pelo teste; TecLeader restaurou 'on' (3 bytes); (3) stubs de PATH não interceptam 'cmd.exe /c start' no Windows: sessões de teste podem ter aberto a salinha no navegador real — testes devem usar SDD_OFFICE_OS=linux ou pref off.
