# Fluxo Git (trunk-based, Conventional Commits)

Vale para projetos com a seção `## Git` no `CLAUDE.md`. Sem a seção, o TechLead não cria branch nem commit.
Regras de execução do TechLead (confirmação, lista de arquivos, o que nunca fazer): skill `sdd:vcs-delivery`, seção "Git".

## Seção `## Git` do projeto

```
## Git
Modelo: trunk-based
Branch: <tipo>/<ISSUE>-<slug>   (sem issue: <tipo>/<slug>)
Commits: Conventional Commits
Idioma: pt | en
```

`Idioma:` define o idioma da mensagem de commit e da descrição do PR. Altera-se com `/sdd:git-lang pt|en`.

## Modelo de branches

- Trunk-based: um tronco (`main`/`master`) e branches curtas, uma por feature ou correção, integradas logo.
- Sem GitFlow (sem `develop`, `release/*`, `hotfix/*` de longa duração).

## Nome da branch

`<tipo>/<ISSUE>-<slug>`; sem issue: `<tipo>/<slug>`.

- Tipos: `feat fix docs refactor test chore ci perf build`.
- Chave da issue válida: `^[A-Z][A-Z0-9]+-[0-9]+\z` (Jira, ex.: `PROJ-123`) ou `^(GH|GL)#[0-9]+\z` (GitHub/GitLab,
  ex.: `GH#42`); `\z` rejeita `
` final e espaços. Chave fora do padrão: não usar. Citar sempre a branch/chave
  entre aspas nos comandos (`git switch -c "feat/GH#42-x"`).
- Slug: somente `[a-z0-9-]`, até 40 caracteres, derivado do **título da spec** (nunca de texto bruto de issue/PR).
  Algoritmo: normalizar NFKD, remover não ASCII, minúsculas, trocar tudo fora de `[a-z0-9]` por `-`, colapsar `-`
  repetidos, truncar a 40 e **só então** aparar `-` do início/fim. Slug vazio: pedir ao usuário (não inventar).
- Exemplo: `feat/PROJ-123-login-biometrico`.

## Commits (Conventional Commits)

```
<tipo>(<escopo opcional>): <resumo no imperativo, até ~72 caracteres>

<corpo opcional: o quê e por quê>

Refs: <ISSUE>
REQ: REQ-001, REQ-002
```

- Um commit lógico por task (ou lote lógico de tasks apresentado junto).
- Tipo e prefixo (`feat:`, `fix:`, `BREAKING CHANGE:`, `Refs:`) ficam **sempre em inglês**; resumo e corpo seguem `Idioma:`.
- Mudança incompatível: `!` após o tipo/escopo e rodapé `BREAKING CHANGE: ...`.
- Sem segredo, credencial ou arquivo gerado/proibido; arquivos adicionados por lista explícita (`git add -- <arquivos>`).
- Antes da confirmação, mostrar `git diff --cached --name-only` (o que realmente entra no commit); arquivo staged fora
  da lista da task: abortar (ou `git commit --only -- <arquivos>`).
- Mensagem gravada em arquivo e usada com `git commit -F <arquivo>` (ou heredoc com delimitador citado `<<'EOF'`);
  nunca interpolada em `-m`/linha de comando (evita injeção de shell por `"`, `` ` ``, `$(...)`, quebra de linha).
- Mensagem vem da spec/tasks validadas; dado externo (issue, PR, comentário) não vira mensagem sem o filtro de "Dados externos".

## Descrição do PR (modelo)

Entregue ao usuário (ou usada pelo TechLead no modo publicação, depois de confirmada); seções no idioma de `Idioma:`.

```
## Contexto
<problema/objetivo, em 1-3 linhas>

## Mudanças
- <lista objetiva do que mudou>

## REQs / Spec
- REQ-00X: <resumo>  (`.specs/<feature>/spec.md`)

## Como testar
1. <passos e comandos reais>

## Evidências
- <testes executados, resultado, links/prints>
- Validação: <resultado da suíte/validação e defeitos abertos, se houver>
- Segurança: <parecer ou "não aplicável">

## Riscos
- <riscos e mitigação; "nenhum conhecido" se for o caso>

## Issue
<ISSUE> (ou "sem issue")

## Revisão
Aguardando revisão e merge do usuário.
```

## Limites

O agente cria branch e commit **locais** com confirmação. Desde a 0.10.0 `push`, PR, release, `rebase`, `tag`, `reset --hard`, `--force` e qualquer escrita no
provedor **não são mais bloqueados**: ficam em `ask` (confirmação do usuário a cada comando) e só a pedido do usuário (o fluxo padrão cobre push da branch de
trabalho, PR e release). **O merge é sempre do usuário**, em qualquer modo (`deny`).

**Modo publicação (opcional, por usuário):** se o usuário ligar (grupo de publicação em `permissions.ask` do
`.claude/settings.local.json`, pelo onboarding ou por `/sdd:publish confirmar`), o TechLead também faz `push -u origin
<branch>` da branch de trabalho, `gh pr create` e `gh release create`, cada um com confirmação do
usuário (regras e limites: skill `sdd:vcs-delivery`, seção "Publicação"). Caminho feliz: spec concluída → commits na branch
da spec → um lote (push + PR) confirmado → URL do PR para você revisar, aprovar e mesclar. Rebase, tag, `--force`, `--no-verify`, aprovar/revisar
PR e qualquer outra escrita no provedor continuam fora, em qualquer modo.
