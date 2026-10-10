# Validação T-003 (specs-location): pilotos do TecLeader nos 4 cenários

Comando: `claude -p "olá, faça o onboarding" --plugin-dir plugins/sdd --agent sdd:tecleader --allowedTools "Read,Glob,Grep" --output-format stream-json --verbose < /dev/null` (execução em 2026-10-10).

| Cenário | Esperado | Obtido | Status |
|---|---|---|---|
| W (workspace sem git, `ict_app/` é repo) | `git=none subrepos=1`; não cria/propõe `.specs/`/`CLAUDE.md` em W; avisa fora do repo; sugere abrir em `ict_app/` | Hook: `git=none subrepos=1`. Ferramentas: só Glob/Skill. "Não fiz o onboarding nesta pasta... contém um repositório"; "Por que não criei nada aqui"; sugere `cd ict_app` + `claude` | VALIDADO |
| RR (raiz de repo) | `git=root subrepos=0`; onboarding normal na raiz | Hook: `git=root subrepos=0`. Propõe `.specs/INDEX.md` e `CLAUDE.md` na raiz do repo; perguntas de stack. Write em `RR\.specs\INDEX.md` tentado e negado pela permissão | VALIDADO |
| MONO/apps/web | `git=inside subrepos=0`; `.specs/` em `apps/web` ou explica a escolha; não fora do git | Hook: `git=inside subrepos=0`. Pergunta 1/3: A) `MONO/apps/web`, "um `.specs/` por app" (recomendada) vs B) `MONO`. Nada fora do repo | VALIDADO |
| NOGIT | `git=none subrepos=0`; segue, avisa não versionado, sugere `git init` sem executar | Hook: `git=none subrepos=0`. "as specs e o `CLAUDE.md` não ficarão versionados... `git init` só se você confirmar". Write em `NOGIT\.specs\INDEX.md` tentado e negado | VALIDADO |
| Transversal: sem escrita, sem `git init`, status inalterado | nada criado/alterado | Nenhum Edit; Write só RR e NOGIT, ambos na raiz correta e negados (`is_error`); Bash só leitura (ls/cat/find); sem `.specs` em nenhum cenário; `git status --porcelain` vazio em `W/ict_app`, `RR`, `MONO`; NOGIT sem `.git` | VALIDADO |

Observações:
- Escrita foi tentada (e bloqueada) em RR e NOGIT: comportamento esperado do onboarding, o alvo foi sempre a raiz do projeto (REQ-001/004). Em MONO e W não houve tentativa por faltarem respostas/ser fora do repo.
- Mapeamento: REQ-002 (diagnóstico do hook nos 4 cenários), REQ-003 (4 linhas da tabela), REQ-004 (nenhum `.specs/` fora da raiz).
- Escopo: pilotos manuais via CLI (LLM, não determinístico); uma execução por cenário. Segurança do hook fica com o agente `security`.

Resultado geral: VALIDADO (4/4). Encerramento da task cabe ao tecleader.
