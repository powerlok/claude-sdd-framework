# Tasks: docs-conformance

| ID | Objetivo | REQ | Responsável | Depende | Estado |
|----|----------|-----|-------------|---------|--------|
| T-000 | Reteste H1–H4 com o CLI atual | Fase 0 | sdd:tests | — | DONE |
| T-001 | Correções de texto, descrições, licença, release, deny, versões | REQ-001..007 | general-purpose | T-000 | DONE |
| T-002 | Revisão de segurança (deny/hook) | REQ-006 | sdd:security | T-001 | DONE (volta 2: APROVADO) |
| T-003 | Validação (validate --strict, JSON, linkcheck, piloto) | todos | sdd:tests | T-001 | DONE (17 casos x 2 modos) |
| T-004 | Docs, INDEX, arquivar, commit/push, update | — | tecleader | T-002, T-003 | DONE |

## Observações

- Auditoria (2026-10-11): estrutura conforme; divergências em afirmações (precedência, CLAUDE_PLUGIN_ROOT em skill,
  subagentes aninhados, carregamento sob demanda), descrições sem gatilho, sem LICENSE, controles só em prosa.
- T-000 (2026-10-11, CLI 2.1.296): H1 CONFIRMADA (${CLAUDE_PLUGIN_ROOT} substituído no corpo de skill ao carregar; disco guarda o literal); H2 CONFIRMADA (agente principal e subagente); H3 CONFIRMADA (subagente com Agent delega a neto; sem Agent não); H4 CONFIRMADA por comportamento (CLAUDE.md de subpasta carregado ao ler arquivo dela; não aparece no stream). Doc oficial correta; nossos textos antigos estavam errados (teste antigo em versão anterior do CLI). REQ-004 (licença) aguarda decisão do usuário; T-001 segue sem ela.
- T-001 (2026-10-11): REQ-001/002/003/005/006/007 feitos; validate --strict ✔ (sdd, authoring, marketplace); templates 142 deny; linkcheck 108/0. Correção de premissa do TecLeader: segundo a doc de permissões, deny de Read também cobre cat/head/tail/sed/tee e redirecionamentos reconhecidos no Bash; não cobre grep -r sem nomear arquivo nem scripts. REQ-004 (licença) pendente.
- T-003 (2026-10-11): validate --strict ✔ x3; 142 deny únicos; linkcheck 108/0. Empírico (bypassPermissions): Read .env/.env.local/.pem, cat .env, git push --force e -f BLOQUEADOS, sem vazamento, remoto inalterado; controle notes.txt executou. Limite confirmado: grep -r SECRET . expôs os valores (documentado).
- T-002 volta 1 (2026-10-11): RISCO. R1 MEDIUM deny de push forçado só pega flag logo após 'push' (git push origin main --force passa; README promete cobertura); R2 MEDIUM faltam credenciais comuns (pfx/p12/jks, .npmrc/.pypirc/.netrc/.git-credentials, credentials.json, tfvars/tfstate, ~/.ssh, ~/.aws...); R3 LOW .env.example bloqueado (usar '!'); R4 LOW Edit(**/.env); R5 LOW Limites: ancoragem no cwd, link sandboxing; R6 LOW ordem com 'skills do plugin'. Fora de escopo (observação): incluir 'dado não confiável' na lista de não relaxáveis. Hook: não necessário. Correção → FIXING; T-003 refeito para as regras novas.
- Correção R1–R6 (2026-10-11): push destrutivo com curingas + ask git push; +23 regras de credenciais; '!' para .env.example/.sample/.template (doc confirma; só regras do mesmo arquivo, não ancoradas); Edit .env; Limites; ordem com skills. TecLeader acrescentou Bash(git push -d*). deny 177, ask 1.
- T-002 volta 2 (2026-10-11): APROVADO. LOW: R7 -uf/:refspec só no ask (documentado); R8 '+' em nome de branch (aceito); R9 PowerShell sem Git Bash não coberto por Bash(...) (documentado); R10 .npmrc/tfvars sem segredo bloqueados (aceito). CHANGELOG alinhado.
- T-003 rodada 2 (2026-10-11, CLI 2.1.296): 17 casos em bypass e default: leituras de segredo, Write/Edit .env, 6 pushes destrutivos e ~/.ssh BLOQUEADOS; .env.example lido (exceção '!' funciona); push comum pediu confirmação também em bypass (ask aplicado); remoto e .env inalterados (md5); sem vazamento. Sem defeitos. Pendente só REQ-004 (licença, decisão do usuário).
- REQ-004 (2026-10-11): licença MIT escolhida pelo usuário; LICENSE na raiz (com nota do material Apache-2.0), license nos plugin.json; validate --strict ✔ x3. T-004: arquivamento, INDEX, commit, tag v0.6.4, push, update no workspace.
