# CLAUDE.md — workspace <NOME_DO_WORKSPACE>

> Modelo de `CLAUDE.md` de workspace (diretório pai dos repositórios). Curto.
> NÃO é versionado com os projetos: o que o time precisa vai no `CLAUDE.md` de cada projeto.
> Com um só projeto, dispensar este arquivo. Camadas: skill `sdd:sdd-rules`.
> Para trabalhar entre projetos a partir do workspace: `.claude/settings.json` do workspace (opcional) com deny do
> modelo `templates/project-settings.git.json` ∪ deny dos projetos envolvidos (nessa sessão o deny dos projetos não vale).
> Remover este bloco de instruções após o preenchimento.

Vai aqui: só o que vale para todos os repositórios abaixo.
NÃO vai aqui: `## Stack`, comandos, arquitetura, `## Repositório`, `## SDD` e regras de um projeto
(ficam no `CLAUDE.md` do projeto); regras do processo (ficam no plugin `sdd`).

## Projetos

| Pasta | Conteúdo |
|---|---|
| `<repo>/` | <O QUE É; detalhes no `<repo>/CLAUDE.md`> |

## Convenções comuns

- <CONVENÇÃO QUE VALE PARA TODOS OS PROJETOS>
