# Tasks: first-run-guide

| ID | Objetivo | REQ | Responsável | Depende | Estado |
|----|----------|-----|-------------|---------|--------|
| T-000a | Doc oficial do fluxo de primeiro uso | Fase 0 | claude-code-guide | — | DONE |
| T-000b | Teste prático do fluxo (H2–H5) | Fase 0 | sdd:tests | — | DONE |
| T-000c | Máquina virgem (CLAUDE_CONFIG_DIR isolado) | Fase 0 | sdd:tests | — | DONE (rodado pelo usuário) |
| T-001 | Guia, README, manual, CHANGELOG | REQ-001..004 | general-purpose | T-000 | DONE |
| T-002 | Validação de usabilidade (seguir o guia) | todos | sdd:tests | T-001 | DONE (validado com melhorias) |
| T-003 | INDEX, arquivar, commit/push | — | tecleader | T-002 | DONE |

## Observações
- T-000a doc oficial (2026-10-11): 1) diálogo de confiança só interativo; plugin de projeto só carrega após confiar
  (-p e pasta-mãe confiada não bastam); 2) marketplace declarado é clonado em background, mas plugin habilitado em
  settings de projeto **não é instalado sozinho** (aparece em /plugin › Errors: "enabled in project settings but
  isn't installed here") → cada dev roda `claude plugin install sdd@claude-sdd-framework --scope project` (ou
  /plugin install), depois `/reload-plugins` ou nova sessão; 3) repo privado: usa credenciais git da máquina sem
  prompt (HTTPS via helper, ex. `gh auth setup-git`; ou SSH com agent); erros típicos e `git ls-remote <url>` para
  testar; 4) `marketplace add` aceita `owner/repo#ref` / `url#ref`, `--scope user|project|local`; 5) conferir:
  `claude plugin list`, `claude plugin marketplace list`, `/plugin` (Installed/Errors), `claude doctor`; agente
  ativo não documentado; 6) -p não instala; 7) hooks no Windows: shell padrão bash (Git Bash) ou powershell se não
  houver Git Bash — nosso hook usa `bash` → Git for Windows é pré-requisito (registrar).
- T-000b prático (2026-10-11, CLI 2.1.296, marketplace já registrado no user desta máquina): só o settings NÃO carrega
  o plugin (-p); `claude plugin install sdd@claude-sdd-framework --scope project` resolve (reordena chaves do settings,
  preserva `ref`); hook roda e TecLeader oferece onboarding (A: lê código, propõe CLAUDE.md+INDEX, pergunta versionar;
  B: pergunta stack/convenções/versionar, nada criado antes). Onboarding em A criou CLAUDE.md (Stack, comandos reais,
  ## SDD) e .specs/INDEX.md, sem commit. Init não traz `agent` → conferir pela 1ª resposta ("Sou o TecLeader").
  `marketplace add` sem flag de ref no help. claude fora do PATH do Git Bash. Não testado: máquina virgem → T-000c.
- T-000c (2026-10-11): isolamento OK. Máquina virgem: `plugin install` sozinho FALHA ("Plugin sdd not found in marketplace
  claude-sdd-framework") → precisa `marketplace add` antes. `marketplace add url#v0.6.4` é traduzido em
  `git clone --branch v0.6.4` (ref aceito), mas o clone falha dentro do sandbox da sessão ("'$GIT_DIR' too big / remote
  helper 'https' aborted"); git manual funciona. Bypass do sandbox negado pelo classificador (não contornado).
  Pendente: rodar o roteiro num terminal comum (usuário).
- T-000c concluída pelo usuário (2026-10-11, PowerShell fora do Claude Code, CLAUDE_CONFIG_DIR isolado):
  `claude plugin marketplace add "https://github.com/powerlok/claude-sdd-framework.git#v0.6.4"` → "Cloning ... (ref:
  v0.6.4)", "Successfully added marketplace: claude-sdd-framework (declared in user settings)"; clone HEAD = d936397
  (tag v0.6.4) ✔; `claude plugin install sdd@claude-sdd-framework --scope project` → "Successfully installed (scope:
  project)"; `plugin list`: sdd 0.6.4, project, enabled. Sequência oficial para máquina nova = add#tag + install.
  Rodado como administrador (não há indício de que seja necessário).
- T-001 (2026-10-11): docs/primeiros-passos.md (294 linhas), README Início rápido enxuto + seção Proteções, manual seção 2; TecLeader corrigiu manual ex-2 e 'not found in marketplace' para o fluxo verificado. linkcheck 127/0; validate --strict ✔.
- T-002 (2026-10-11): usabilidade — dois caminhos seguidos só pelo guia, sem bloqueantes; 'você vai ver' bateu (Sou o TecLeader; onboarding A cria CLAUDE.md+INDEX sem commit; B pergunta stack/nuvem/convenções e cria após ok; 'Plugin not found' e resposta genérica sem install reproduzidos). Melhorias D1, D2, M1–M6 em aplicação. Não reproduzível aqui: marketplace add (usuário verificou), diálogo de confiança, /plugin, /reload-plugins.
- Melhorias aplicadas (2026-10-11): D1, D2 (guia + manual), M1–M6; linkcheck 128/0. Docs só → sem bump, não é release. Arquivado em .specs/done/.
