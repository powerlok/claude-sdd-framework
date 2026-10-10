# Spec: `.specs/` sempre na raiz do projeto (repositório git)

Pedido do usuário (2026-10-10): `.specs/` deve ficar sempre dentro do projeto, nunca fora. Origem: o TecLeader perguntou,
num workspace `testeclaude/` com o repositório em `testeclaude/ict_petro/`, onde criar o `.specs/`. Proposta aprovada.

## Requisitos

- **REQ-001** (`sdd-rules`): `.specs/`, `CLAUDE.md` do projeto e `.claude/settings.json` ficam na **raiz do projeto**
  (raiz do repositório git; em monorepo, a pasta do projeto dentro do repositório). Num workspace com vários projetos,
  um `.specs/` por projeto; **nunca** no diretório pai/workspace fora do git.
- **REQ-002** (hook): o diagnóstico informa a situação git **sem executar o git** (só sistema de arquivos; o git pode
  executar comandos configurados no repositório): `git=root` (`.git` na pasta), `git=inside` (`.git` num ancestral,
  até 20 níveis), `git=none`; e `subrepos=N` (quantas subpastas diretas têm `.git`; só a contagem, nunca nomes).
- **REQ-003** (TecLeader, primeira resposta):
  | Diagnóstico | Comportamento |
  |---|---|
  | `git=root` | normal |
  | `git=inside` | normal; se for monorepo, `.specs/` na pasta do projeto; avisar se parecer subpasta sem ser projeto |
  | `git=none` e `subrepos>0` | **não criar** `.specs/`/`CLAUDE.md` aqui; avisar que a sessão está fora do repositório e sugerir abrir o `claude` dentro do repositório (listar subpastas com Glob, sem ler conteúdo) |
  | `git=none` e `subrepos=0` | pode seguir (projeto novo/sem git), avisando que as specs não ficarão versionadas e sugerindo `git init` (não executar sem confirmação) |
- **REQ-004**: o onboarding nunca cria `.specs/` fora da raiz do projeto; se a pergunta surgir, a resposta padrão é a raiz do repositório.

## Critérios de aceite

- 4 cenários: raiz de repositório; workspace com repositório em subpasta; subpasta de monorepo; pasta sem git.
- Hook continua somente leitura, sem executar git, saída só com constantes e números; revisão do `security` APROVADA.

## Validação

`claude plugin validate`; script nos 4 cenários; pilotos do TecLeader ("olá") nos 4 cenários; `git status` sem mudanças.
