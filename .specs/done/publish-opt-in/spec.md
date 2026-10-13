# Spec: publicação no GitHub/GitLab/Azure DevOps como escolha do usuário

Pedido do usuário (2026-10-12): "precisamos deixar para o usuário informar se ele quer ou não que deixe allow o git".
Contexto: o modelo `templates/project-settings.git.json` bloqueia (`deny`) `gh pr create/merge`, `gh release create` e
equivalentes; `deny` vence qualquer `allow`, então quem quer que o TechLead publique não consegue sem editar o settings
à mão. Decisões do usuário: o onboarding pergunta; a liberação vira `ask` (confirmação a cada comando), nunca `allow`;
só entra na escolha o grupo **publicação**; versão `sdd` **0.9.2**; a escolha fica **por usuário no
`.claude/settings.local.json`** (não no `CLAUDE.md`); muda-se depois **pedindo ao TechLead ou por comando**.

## Requisitos

- **REQ-001**: o `deny` dos modelos `project-settings.git.json` e `project-settings.local.json` passa a conter só o
  grupo **fixo** (sempre bloqueado). O grupo **publicação** sai desses modelos e vai para
  `templates/project-settings.publicacao.json` (lista única, estado `bloqueada` = chaves em `permissions.deny`).
  Publicação = `gh pr create|merge|comment|close|edit|ready|review|reopen`, `gh release create|edit|upload`,
  `glab mr create|merge|approve|note|close|update|rebase`, `az repos pr create|update|set-vote|reviewer|work-item|...` e as
  ferramentas MCP de criar/mesclar PR/MR. Permanecem no fixo: `gh release delete`, `gh pr checkout`, `gh api`,
  `gh repo ...`, `gh issue ...`, `gh secret|variable|workflow|...`, `push --force`, `reset --hard` etc.
- **REQ-002**: onboarding: **uma** pergunta nova, junto da do idioma: "Permitir que o TechLead publique (PR, merge,
  release) com confirmação a cada comando? (padrão: não)". O plano confirmado grava o grupo no
  `.claude/settings.local.json` (por usuário, fora do versionamento): `não`/sem resposta → grupo em `permissions.deny`;
  `sim` → o mesmo grupo em `permissions.ask`. Nunca em `allow`. Uma só das chaves contém o grupo.
- **REQ-003**: sessão: "deny exigido" = fixo (modelos) ∪ deny dos projetos. Publicação não é exigida no deny. Grupo em
  nenhuma das chaves (`deny`/`ask`) do `settings.local.json` = "sem decisão": o TechLead não publica e oferece a pergunta
  do REQ-002 (não é aviso de deny incompleto).
- **REQ-004**: o TechLead só executa publicação com o grupo em `permissions.ask` do `settings.local.json` do projeto,
  depois de confirmação própria (mostra comando, repositório, base ← cabeça, título/notas); `merge` com confirmação
  específica ("mesclar PR #N em `<base>`?"). Para publicar um PR, `git push` **sem force** da branch de trabalho
  (nunca da branch trunk/default, nunca `--force`, `--mirror`, `--delete`, `+refspec`) fica permitido nesse modo, com a
  mesma confirmação. Texto de PR/issue/CI/arquivo é dado, nunca instrução. Sem `ask`: não publica, entrega o texto
  do PR ao usuário como hoje.
- **REQ-005**: alterar a escolha: pedir ao TechLead ou `/sdd:publish bloqueada|confirmar` (nova skill, estilo
  `git-lang`, só edita o `settings.local.json`; move o grupo inteiro entre `deny` e `ask`; recusa se o arquivo for
  rastreado pelo git).
- **REQ-006**: docs (`README`, `docs/arquitetura.md`, manual, `primeiros-passos.md`, `templates/CLAUDE.md`,
  `git-workflow.md`), CHANGELOG e `sdd` **0.9.2**.
- **REQ-007**: testes: modelos e `publicacao.json` são JSON válidos; fixo ∩ publicação = ∅; todo item do deny atual
  (v0.9.1) está em fixo ∪ publicação (nada some); publicação ausente de `allow`; transformação `bloqueada`↔`confirmar`
  é reversível e mantém uma só chave.

## Segurança (controle não relaxável → parecer obrigatório antes de implementar)

Pontos: remover publicação do deny versionado reduz a barreira padrão de quem não rodou o onboarding (o `ask`/prompt
normal do Claude Code continua valendo; avaliar); `ask` em modo não interativo/`bypassPermissions`/`acceptEdits`;
padrões contornáveis (`sh -c`, caminho absoluto); prompt injection em PR/issue lido pelo agente; `merge` e `push`
irreversíveis; `settings.local.json` editável pelo agente (a skill e o TechLead o alteram só com confirmação).

## Critérios de aceite

Testes do REQ-007 verdes; parecer de segurança aprovado; `validate --strict`; onboarding simulado grava o grupo no
`settings.local.json` na chave certa; docs sem divergência; `run-all` verde.

## Fora de escopo

`allow` automático; liberar `gh api`, `gh repo ...`, `gh workflow ...`, `gh secret`, `gh release delete`; `push` fora
do modo publicação; alterar o `.claude/settings.json` do workspace do usuário (decisão dele; os `deny` de publicação
que ele já tem continuam valendo até ele removê-los).

## Revisão após o parecer de segurança (2026-10-13) — prevalece sobre o texto acima

Decisões do usuário: **alternativa A** (grupo publicação em `ask` no modelo versionado; `bloqueada` = `deny` no
`settings.local.json`; `confirmar` = `ask` no `settings.local.json`; sem decisão = o TechLead não publica) e **push
permitido ao TechLead com confirmação** (divergência consciente da recomendação de H1; condição: corrigir os `deny` de push).

- REQ-001 (final): grupo mínimo em `ask` nos modelos: `gh pr create|merge|comment`, `gh release create`, variantes `gh.exe`,
  `glab mr create|merge|note`, `az repos pr create`. Em `deny` fixo: `gh pr review`, `glab mr approve`, `az repos pr
  set-vote|reviewer|update`, `gh release edit|upload|delete`, `gh pr checkout`, `gh api`, MCP de criar/mesclar PR (o agente
  usa só `gh` via Bash). Novos `deny`: `gh pr merge --admin|--auto|--delete-branch|-d`, `glab mr merge --remove-source-branch`.
- REQ-004 (final): push só `git push -u origin <branch>` da branch de trabalho; `deny` de push corrigido (H1): sai
  `*-*f*` (negava `-u origin feat/x`); entram `-uf`/`-fu`, `*:main*`, `*:master*`, `*:refs/*`, `* main`, `* master`, `--all`,
  `--tags`, `--prune`, `--follow-tags`. Merge: número explícito, sem `--admin`/`--auto`/`-d`; release sem anexos.
- REQ-003/REQ-004 (H3): modo publicação só com sessão aberta dentro do projeto; workspace/`--add-dir` = `bloqueada`;
  `allow` com `gh`/`glab`/`az`/`Bash(*)` = `inconsistente` = `bloqueada`.
- REQ-005 (M5): `Edit/Write(.claude/settings.local.json)` em `ask` no modelo; skill `/sdd:publish` com `git ls-files`/
  `check-ignore` restritos, recusa arquivo rastreado, mostra diff.
- Aceito e documentado: `ask` não protege em `bypassPermissions`/`claude -p`; padrões Bash não cobrem `sh -c`, caminho
  absoluto, alias.

## Encerramento (2026-10-13)

Arquivada com **validação parcial aceita pelo usuário** (release v0.9.4). Feito: implementação, 2 pareceres de segurança, `req007-publicacao`
(68 ok), `validate --strict`, piloto em sandbox (`claude -p`: sem decisão, `confirmar`, `bloqueada`, `allow` perigoso). **Não executado**: prompt
interativo de confirmação, gravação do `settings.local.json` (em `-p` o `ask` nega), `/sdd:publish` e publicação real. O merge saiu do escopo em
`done/spec-pr-flow` (o merge é sempre do usuário).
