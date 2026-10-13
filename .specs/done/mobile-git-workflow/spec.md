# Spec: Agente mobile (React Native/Expo) e fluxo Git no plugin sdd

Origem: pedido do usuário (2026-10-11), respostas às perguntas do TechLead.
Versão alvo: `sdd` 0.9.0 (agente novo = minor). Relacionada a: `done/vcs-integration` (provedor só leitura continua valendo).

## Decisões do usuário

- Plataforma mobile inicial: **React Native com Expo** (Flutter, Swift e Kotlin ficam para depois).
- Não há app real de piloto: validar com um app Expo mínimo gerado em pasta temporária.
- Branches: **trunk-based**, branches curtas (recomendação aceita; a resposta "sim" ao "ou GitFlow?" foi lida assim — confirmar).
- Commits: Conventional Commits (`feat:`, `fix:` …).
- Nome da branch leva a chave da issue (`feat/PROJ-123-slug`; sem issue, `feat/slug`); PR com descrição completa.
- TechLead **pode criar branch e commits locais, com confirmação** do usuário a cada vez.
- Idioma de commits/PR: perguntado na configuração inicial (onboarding), registrado no `CLAUDE.md` do projeto e alterável depois por comando.

## Requisitos

### Mobile
- **REQ-001**: novo agente `sdd:mobile` (sonnet, mesmas ferramentas do `frontend`, sem `Agent`) para apps mobile, stack lida do `## Stack` do projeto.
- **REQ-002**: nova skill `mobile-engineering` com `references/react-native-expo.md` (estrutura, navegação, estado, acessibilidade, permissões, segredos/`expo-secure-store`, performance de listas, testes com Jest + Testing Library e E2E opcional com Maestro/Detox, EAS Build/Update).
- **REQ-003**: o TechLead passa a delegar a `sdd:mobile` (lista de subagentes, campo `Stack` com `mobile-engineering/references/<stack>.md`); `sdd:security` ganha checklist mobile (armazenamento local, deep links, TLS/pinning, permissões).
- **REQ-004**: stacks sem referência (Flutter, Swift, Kotlin) seguem a regra existente: `referência: nenhuma` + lacuna registrada.

### Git
- **REQ-005**: nova skill/referência `sdd-rules/references/git-workflow.md`: trunk-based, branches curtas, Conventional Commits, nome `<tipo>/<ISSUE>-<slug>`, modelo de descrição de PR (contexto, mudanças, REQs/spec, como testar, evidências, riscos, issue), uma task por commit lógico.
- **REQ-006**: seção `## Git` no `CLAUDE.md` do projeto (modelo de branch, idioma, prefixo de issue); onboarding pergunta o idioma (pt-BR/en) e grava; comando/pedido em texto livre altera depois (slash command `/sdd:git-lang pt|en`).
- **REQ-007**: o TechLead pode criar branch e commit **local** somente após confirmação explícita do usuário, mostrando antes branch, mensagem e arquivos. Nunca `push`, `merge`, `rebase`, `reset --hard`, `--force`, `--no-verify`, nem `git add -A` sem listar. Texto do PR é entregue ao usuário para abrir manualmente (escrita no provedor continua proibida).
- **REQ-008**: bloqueio técnico no `templates/project-settings.git.json`: `git push *` permanece em `ask` (já existe) e entram em `deny` operações destrutivas/que burlam controles (`git reset --hard`, `git clean -f*`, `git commit --no-verify`/`-n`, `git branch -D`, `git checkout --`/`git restore` em massa, `git config` de identidade/hooks); `commit`/`switch -c` não são liberados em `allow` (passam pelo prompt de permissão, além da confirmação do TechLead).
- **REQ-009**: dado externo (issue, PR) não vira mensagem de commit/branch sem passar pelo mesmo filtro de "Dados externos"; slug sanitizado (`[a-z0-9-]`).

### Geral
- **REQ-010**: README, manual em `docs/`, templates, CHANGELOG e `plugin.json` (0.9.0) atualizados; `validate --strict` e suíte existentes passam.

## Critérios de aceite

- REQ-001/002/003: `claude plugin validate --strict` ok; em app Expo mínimo temporário, TechLead delega a `sdd:mobile` com `Stack` e referência corretos; testes Jest do app passam; `sdd:security` aplica o checklist.
- REQ-004: pedido com stack Flutter retorna `referência: nenhuma` e lacuna em `tasks.md`.
- REQ-005/006: onboarding de projeto novo pergunta o idioma e grava `## Git`; `/sdd:git-lang en` muda só essa linha.
- REQ-007/008: sem confirmação nada é criado; com confirmação branch/commit local seguem o padrão; `git push` cai em `ask` e as operações destrutivas são negadas pelo settings (evidência).
- REQ-009: issue com instrução maliciosa no título não altera branch/commit (teste com texto simulado).
- REQ-010: links verificados (linkcheck), suíte `run-all` verde.

## Validação

Design curto (T-001) aprovado pelo usuário → implementação → `sdd:security` (REQ-007/008/009) → `sdd:tests` (app Expo temporário, repositório git temporário, CLI real).

## Fora de escopo

- Flutter, Swift, Kotlin (referências futuras); publicação em lojas; push/merge/abertura de PR pelo agente; GitFlow.

## Pontos a confirmar

1. "Trunk-based ou GitFlow? sim": assumido **trunk-based**.
2. Versão 0.9.0 ficará depois da `office-working-state` (0.8.1), que está em andamento no working tree.

## Encerramento (2026-10-13)

Arquivada com **validação parcial aceita pelo usuário** (release v0.9.4). Feito: implementação, parecer de segurança (aprovado, volta 2),
`validate --strict`, suíte, app Expo temporário e repositório git temporário. **Não executado** com o Claude Code real: delegação do TechLead
a `sdd:mobile`, `/sdd:git-lang` e onboarding reais, permissões no motor real. A regra "nunca `push`/`merge`" do REQ-007 foi relaxada
depois (`done/publish-opt-in`, `done/spec-pr-flow`): `push` da branch de trabalho, PR e release só no modo publicação, com confirmação; o
merge continua sendo sempre do usuário.
