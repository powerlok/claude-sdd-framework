# CLAUDE.md

Projeto novo: plugin e marketplace do Claude Code que distribuem o processo SDD
(agentes, skills e hooks) para outros devs e projetos.

## Informado pelo usuário

- Objetivo: compartilhar os agentes e processos do workspace com outros devs e projetos.
- Agentes e skills agnósticos de linguagem; a stack vem do `CLAUDE.md` de cada projeto.
- Repositório: GitHub `powerlok/claude-sdd-framework` (privado); marketplace `claude-sdd-framework`.
  A pasta local no workspace continua `engineering-workflow/`. Push exige confirmação explícita.

## Especificações

Ativas em `.specs/<feature>/` (`spec.md`, `tasks.md`); concluídas em `.specs/done/<feature>/`;
índice em `.specs/INDEX.md` (ler antes de varrer pastas).

## Versão × release (regra deste repositório)

- **Versão** (bump): toda feature que altera um plugin → `version` no `plugin.json` + CHANGELOG; commit em `main`,
  **sem tag**.
- **Release**: conjunto pronto para os projetos consumirem. Exige `validate --strict` (sdd, authoring, marketplace),
  revisão de segurança aprovada quando aplicável, validação sem defeito aberto e CHANGELOG fechado.
- Na release: `metadata.version` do `.claude-plugin/marketplace.json` = `X.Y.Z`; tag anotada `vX.Y.Z` (push da tag);
  `"ref"` de `templates/project-settings.git.json` = `vX.Y.Z`; seção `## Release vX.Y.Z` no CHANGELOG com as versões
  dos plugins incluídos. A tag versiona o marketplace (os dois plugins juntos), não um plugin.
- Não é release: só docs/specs, trabalho em andamento, mudança não validada.
- O TecLeader pergunta "é release?" ao encerrar uma feature; a tag só é criada com confirmação do usuário.
- Primeira release: `v0.6.4` (sdd 0.6.4, authoring 0.2.1).

## Comandos (verificados em 2026-10-09, Claude Code 2.1.288)

`claude` = `~/.local/bin/claude.exe` (fora do PATH no bash desta máquina).

- Validar: `claude plugin validate .` | `./plugins/sdd` | `./plugins/authoring`
- Antes de cada bump de versão (obrigatório): `claude plugin validate ./plugins/sdd --strict`,
  `claude plugin validate ./plugins/authoring --strict` e `claude plugin validate .` (marketplace); depois bump de
  `version`, CHANGELOG e versões no README e em `docs/` (ver "Versão × release")
- Testar a salinha dos agentes (hooks + página): `bash plugins/sdd/hooks/tests/run-all.sh` (~4 min no Windows;
  `--no-page` pula a página)
- Testar um agente sem instalar: `claude -p "<prompt>" --plugin-dir ./plugins/sdd --agent sdd:<agente> --allowedTools "..."`
  (prompt logo após `-p`; `--allowedTools` é variádica)
- Inspecionar carregamento: `--output-format stream-json --verbose` (evento `init`: agentes, skills, MCP)
- Após editar o plugin instalado: bump de `version` + `claude plugin marketplace update` + `claude plugin update`

## Arquitetura e decisões

Ver `README.md` e `.specs/done/sdd-plugin/design.md`. Limitações confirmadas: `skills:` não pré-carrega
no agente da sessão principal. `${CLAUDE_PLUGIN_ROOT}` é substituído ao carregar o corpo de skills e de agentes
(principal e subagente; reteste CLI 2.1.296); no disco fica o literal.
