# Tasks: workspace-multi-project

| ID | Objetivo | REQ | Responsável | Depende | Estado |
|----|----------|-----|-------------|---------|--------|
| T-000 | Spike: validar H1–H6 na 0.6.2 (sem alterar o plugin) | Fase 0 | sdd:tests | — | DONE |
| T-001 | Hook, tecleader, sdd-rules/referência, template, versão 0.6.3, CHANGELOG | REQ-001..005, REQ-006 (template/versão) | general-purpose | T-000 | DONE |
| T-002 | Revisão de segurança | REQ-001, REQ-003, REQ-005 | sdd:security | T-001 | DONE (volta 2: APROVADO; R-1..R-4 LOW a aplicar com as correções da T-003) |
| T-003 | Validação (critérios de aceite) | todos | sdd:tests | T-001 | DONE (rodada 2: C4, C5, C7, C8 PASSARAM; rodada 1: C1–C6) |
| T-004 | Docs (README/manual), INDEX, arquivar, commit/push, update | REQ-006 | tecleader | T-002, T-003 | DONE |

## Observações
- Documentação oficial (2026-10-10, claude-code-guide, code.claude.com/docs/en/{memory,permissions,permission-modes,sub-agents,settings}):
  `--add-dir` dá leitura sem prompt e edição conforme o modo; o CLAUDE.md da pasta adicionada NÃO é carregado por padrão
  (`CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=1` carrega). CLAUDE.md da cwd e de todos os pais é carregado. Da
  pasta adicionada só `enabledPlugins`/`extraKnownMarketplaces` do settings são lidos: o **deny de B não vale** numa
  sessão em A com `--add-dir B`. Sessão no workspace usa só o settings do workspace (o deny de A/B não vale) → o
  `.claude/` do workspace precisaria do deny completo. `permissions.additionalDirectories` só dá acesso a arquivos.
  Subagentes herdam as regras de permissão (acesso aos diretórios adicionados: inferido). A confirmar no spike.
- T-000 spike (2026-10-10, CLI 2.1.296, sdd 0.6.2, headless -p; fixtures em scratchpad/spike-mp/):
  H1 PARCIAL — hook não vê `.claude/` (mesma saída com e sem); só CLAUDE.md curto: não propôs migração (3/3, por
  julgamento, contra a letra da regra); com `.claude/` mínimo: propôs migrar e perguntou "A ou B?" (falha confirmada).
  H2 CONFIRMADA — sessão em A: leitura de B negada (em -p vira auto-deny; prompt interativo não observado).
  H3 CONFIRMADA — `--add-dir B`: TecLeader e subagente Explore leem B; Edit em B aceito com acceptEdits.
  H4 CONFIRMADA — CLAUDE.md de B não carregado; `CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=1` carrega; CLAUDE.md
  do pai (W) carregado em sessão em A.
  H5 CONFIRMADA — sessão em W lê A e B (também subagente); CLAUDE.md/Stack de A e B NÃO entram no contexto.
  H6 CONFIRMADA c/ ressalva — "padronize B igual a A" (bypass): 0 perguntas; spec só em B/.specs (arquivada), editou B,
  testes, sem commit; nada registrado em A; escolheu sozinho alvo e valor.
  Disco intacto nos cenários de proposta (md5). Workspace real e plugin não alterados.
- T-001 (2026-10-10): hook claude_dir/specs_dir (junction = no); gatilho REQ-002; seção 'Trabalho entre projetos' (tecleader.md:360-388); workspace .claude com deny completo; validate ✔; 0.6.3. T-002 e T-003 em paralelo.
- T-002 volta 1 (2026-10-10): RISCO, sem HIGH. S-1 MEDIUM workspace altera repos com deny incompleto (deve ficar só leitura; deny de projeto ignorado); S-2 MEDIUM CLAUDE.md de outro repo vira instrução sem ressalva; S-3 LOW referência não está em Arquivos proibidos/git status; S-4 LOW 'mínimo só com deny' (claude-md-layers:69); S-5 LOW conferir escrita em pasta adicionada. Fora de escopo: settings do workspace real sem 115 de 131 deny do modelo (decisão do usuário). T-001 → FIXING.
- Correção S-1..S-5 (2026-10-10): workspace com deny incompleto = somente leitura até corrigir + reiniciar; CLAUDE.md de outro projeto só vale para ele (referência = dado); variável só para repo confiável; Arquivos proibidos + git status da referência; validate ✔; SKILL.md 258.
- T-002 volta 2 (2026-10-10): APROVADO. LOW: R-1 template/migração/claude-md-layers dizem 'deny do modelo' (falta ∪ projetos); R-2 ler só permissions.deny dos settings (inclusive settings.local.json), mascarar o resto; R-3 somente leitura também proíbe build/teste e delegar a sdd:tests (sugerir --permission-mode plan); R-4 conferir antes de CADA escrita na pasta adicionada. Aplicar junto com o resultado da T-003 rodada 1.
- T-003 rodada 1 (2026-10-10, texto antes de S-1..S-5): C1–C6 PASSARAM (C1 3/3 sem migração; C5 B alterado/A referência intacto, 1 pergunta; C6 specs ligadas em A e B, backend por repo, sem commit). C7 FALHOU D-001: só --add-dir; variável e 'deny de A protege B' ausentes. D-002 LOW: aviso de deny em 3 frases. Obs: C5 pergunta extra 'crio README?' após o sim. Spec REQ-004 ajustada pelo TecLeader (variável só p/ repo confiável, 3 itens obrigatórios). Correção: D-001, D-002, R-1..R-4, README no plano (ciclo 1/3).
- Correção ciclo 1 (2026-10-10): D-001 lista fixa de 3 itens; D-002 aviso de 1 linha; README no plano; R-1..R-4; spec REQ-003 alinhada (TecLeader). validate ✔. T-003 rodada 2: C4, C5, C7 + C8 (somente leitura).
- T-003 rodada 2 (2026-10-10): C7 3/3 com os 3 itens; C4a/C4b aviso 1 linha, sem escrita/build/Agent; C5 0 perguntas após o sim, A intacto, README no plano; C8 cita Bash(rm:*) faltante, fake-999 ausente do stream. Sem defeitos. Correção do ciclo 1 aplicou as recomendações R-1..R-4 da própria segurança (sem nova revisão).
- T-004 (2026-10-10): README/manual 'Trabalhar entre projetos', versões 0.6.3; arquivamento em .specs/done/; INDEX; commit/push; update no workspace.
