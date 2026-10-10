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

## Comandos (verificados em 2026-10-09, Claude Code 2.1.288)

`claude` = `~/.local/bin/claude.exe` (fora do PATH no bash desta máquina).

- Validar: `claude plugin validate .` | `./plugins/sdd` | `./plugins/authoring`
- Testar um agente sem instalar: `claude -p "<prompt>" --plugin-dir ./plugins/sdd --agent sdd:<agente> --allowedTools "..."`
  (prompt logo após `-p`; `--allowedTools` é variádica)
- Inspecionar carregamento: `--output-format stream-json --verbose` (evento `init`: agentes, skills, MCP)
- Após editar o plugin instalado: bump de `version` + `claude plugin marketplace update` + `claude plugin update`

## Arquitetura e decisões

Ver `README.md` e `.specs/done/sdd-plugin/design.md`. Limitações confirmadas: `skills:` não pré-carrega
no agente da sessão principal; `${CLAUDE_PLUGIN_ROOT}` só é substituído no texto de agentes.
