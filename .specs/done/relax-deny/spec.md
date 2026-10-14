# Spec: liberar git e escrita em sistemas externos, sempre com confirmação (relaxamento de deny)

Decisão explícita do usuário (2026-10-14), em resposta a "por que colocamos deny nas settings?": "os do git pode remover e liberar todos e escrita
em sistemas externos pode liberar, mas sempre pergunte ao usuário antes de executar qualquer coisa". É um **relaxamento deliberado** de controles que o
`CLAUDE.md` do workspace e a skill `sdd-rules` tratavam como não relaxáveis; vale por decisão do dono do repositório. Revisão independente de
segurança dispensada por essa decisão; riscos residuais registrados abaixo. Relacionada a: done/publish-opt-in, done/spec-pr-flow, done/mobile-git-workflow.

## Interpretação (conservadora, a confirmar)

- "Liberar" = sair do `deny` e ir para `ask` (o Claude Code pergunta a cada comando); nunca `allow`. Comandos de leitura (`git status|diff|log`) continuam
  livres, pois só as entradas que eram `deny` mudam.
- **Git:** todas as regras `Bash(git ...)` do `deny` (201: force push, push para tronco, `reset --hard`, `clean`, `checkout .`, `restore`, `rebase`, `merge`, `tag`,
  `branch -D`, `config`, `commit --amend|--no-verify|-a`, `add -A|.`, `git -c`, variantes com opções globais) vão para `ask`.
- **Escrita em sistemas externos:** `gh|gh.exe|glab|az ...` e as ferramentas MCP de escrita do Atlassian, GitHub, GitLab e Azure DevOps vão para `ask`.
- **Continuam em `deny` (não são "git" nem "escrita externa comum"):** (a) **merge de PR/MR**: `gh pr merge`, `gh.exe pr merge`, `glab mr merge`,
  `az repos pr update` (completa PR), `mcp__github__merge_pull_request`, `mcp__gitlab__accept_merge_request` e as flags `--admin|--auto|--delete-branch|-d`
  (decisão anterior do usuário: "o merge é sempre do usuário"); (b) **expor ou sequestrar credencial/execução**: `gh auth token`, `gh auth status
  --show-token|-t`, `glab auth`, `gh extension install`, `gh alias set`; (c) **arquivos**: leitura/edição de segredos (`.env`, chaves, `.npmrc`, `.netrc`,
  `~/.ssh`, `~/.aws`, `tfstate` etc.), `Edit(**/.git/**)` e `Edit(~/.gitconfig)` (vetor de hooks/execução); (d) ferramentas locais do draw.io e do Playwright
  (`list_pages|get_page|set_page`, `browser_evaluate|run_code_unsafe|file_upload|drop`).

## Requisitos

- **REQ-001**: `project-settings.git.json` e `.local.json`: mover do `deny` para o `ask` as entradas das categorias "Git" e "escrita externa" acima; manter em
  `deny` as exceções; nenhuma regra some (todo item do `deny` da v0.9.1 continua coberto por `deny` ∪ `ask` ∪ grupo); sem `allow`.
- **REQ-002**: o TechLead (agente, skills, governança) deixa de tratar essas operações como "nunca": git (inclusive `push`, `rebase`, `tag`, `reset --hard`,
  `--force`, `--no-verify`) e escrita no provedor só com **pedido do usuário e confirmação do comando literal a cada vez**, com aviso de risco nas destrutivas;
  merge continua sendo do usuário. Modo publicação: sem decisão = `confirmar` (antes `bloqueada`); `bloqueada` (grupo em `deny` local) segue como trava opcional.
- **REQ-003**: docs e CHANGELOG (`sdd` 0.10.0, mudança de comportamento padrão); testes (`req007`, `req009`, `req010`) atualizados: formerly-deny git → `ask`;
  exceções em `deny`; nada "livre" que antes era negado.
- **REQ-004**: `.claude/settings.json` do workspace do usuário é decisão dele (o agente não edita as próprias permissões): entregar um arquivo proposto.

- **REQ-005** (pedido posterior do usuário, 2026-10-14: "libere todos os comandos para azure, aws e google cloud e faça o mesmo, sempre pergunte"): `Bash(az *)`,
  `Bash(azd *)`, `Bash(aws *)`, `Bash(gcloud *)` (e variantes `.cmd`/`.exe`) em `ask` nos modelos: todo comando de nuvem pergunta, inclusive leitura. `az repos pr update`
  segue em `deny` (completa PR). O `sdd:infra-architect` continua sem `Bash` (decide e desenha); quem executa é o TechLead, só com pedido e confirmação do comando literal,
  depois da prévia e do aviso de risco (skill `infra-engineering`, "Regra de execução"). Terraform/OpenTofu/kubectl não foram incluídos (não pedidos).

## Riscos residuais (aceitos pelo usuário)

`ask` **não protege** em `bypassPermissions`, em `claude -p` sem como confirmar, nem contra `sh -c`/caminho absoluto/alias (limite dos padrões `Bash`); o usuário passa a
ser a única barreira para force push, `reset --hard`, `git clean`, `git config`/`git -c` (execução de comando via config), `gh api`, `gh repo delete`, `gh secret`, issue/PR
comments (exfiltração em repositório público) e escrita em Jira/Confluence; fadiga de confirmação. Recomendado manter: `disableBypassPermissionsMode`, proteção de
branch no servidor e token do provedor com escopo mínimo.

## Fora de escopo

Liberar merge; liberar leitura de segredos; `Edit(**/.git/**)`/`~/.gitconfig`; `allow` automático; alterar o `.claude/settings.json` do workspace.

## Critérios de aceite

Testes verdes; `validate --strict`; sandbox no CLI real: `git reset --hard` e `gh issue create` caem em confirmação (não em bloqueio) e `gh pr merge` segue negado.
