# Spec: workspace com vários projetos (gatilho de migração e trabalho entre projetos)

Relacionada a: done/claude-md-layers. Pedido do usuário (2026-10-10).

## Fase 0 — Spike de validação (antes de qualquer mudança)

Pedido explícito: "faça os testes e valide isso antes de seguir". Sem alterar o plugin; só observar a 0.6.2.

Hipóteses a validar:

- H1: após a migração, sessão no workspace com `CLAUDE.md` curto (sem `## Stack`) e/ou `.claude/` mínimo faz o TecLeader
  propor migração de novo (falha do gatilho).
- H2: sessão aberta dentro do projeto A não lê o projeto B sem permissão (modo default: bloqueio/pedido).
- H3: com `--add-dir ../B` (ou `/add-dir`), agentes e subagentes leem/editam B.
- H4: com `--add-dir`, o `CLAUDE.md` de B **não** é carregado por padrão (e verificar se existe opção para carregá-lo).
- H5: sessão no workspace (com `.claude/` mínimo) lê todos os projetos; subagentes herdam o acesso.
- H6: como a 0.6.2 trata hoje um pedido de ajuste que toca dois projetos (onde cria spec/tasks, se commita).

## Resultado do spike

Ver `tasks.md` (T-000): H1 parcial (falha confirmada com `.claude/` no workspace; hook não vê `.claude/`), H2–H5
confirmadas, H6 confirmada com problema (ajuste entre projetos sem perguntas, spec só no alvo, nada no projeto de
referência). Documentação oficial: deny de pasta adicionada (`--add-dir`) e dos projetos não vale numa sessão em outra
raiz; só o settings da raiz da sessão.

## Requisitos (aprovados pelo usuário em 2026-10-10)

- **REQ-001 — Hook vê `.claude/` e `.specs/`**: `onboarding-check.sh` acrescenta `claude_dir=yes|no` e `specs_dir=yes|no`
  (existência de pasta, sem seguir symlink, sem ler conteúdo; saída só com constantes, como hoje).
- **REQ-002 — Gatilho de migração preciso**: com `git=none` e `subrepos>0`, propor migração **somente** se houver `.specs/`
  no workspace ou `## Stack` (conteúdo de projeto) no `CLAUDE.md` do workspace. `CLAUDE.md` curto de workspace e
  `.claude/` de workspace são camadas legítimas: não propor migração nem perguntar "qual projeto" por causa deles.
- **REQ-003 — Workspace como modo de trabalho**: sessão no workspace pode trabalhar em qualquer projeto abaixo. Antes de
  planejar, o TecLeader identifica os projetos envolvidos e lê o `CLAUDE.md` de cada um (`## Stack`, comandos, `## SDD`),
  pois eles não são carregados automaticamente. Specs sempre em `<projeto>/.specs/`. O `.claude/settings.json` do
  workspace deve ter o deny do modelo ∪ deny dos projetos envolvidos (o deny dos projetos não vale nessa sessão); se faltar, avisar em 1 linha
  e incluir a correção no plano.
- **REQ-004 — Sessão num projeto com acesso a outro**: a resposta traz sempre os 3 itens: (1) `--add-dir <outro>` (ou
  `/add-dir`); (2) `CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=1` **se** o usuário declarar o outro repositório confiável
  — senão o TecLeader lê o `CLAUDE.md` dele como dado (ajuste da revisão de segurança S-2); (3) o deny do projeto da
  sessão é o que protege o outro (listar entradas de deny do outro ausentes na sessão).
- **REQ-005 — Mudança entre projetos**: o plano lista os projetos **alterados** e os de **referência** (só leitura) e o
  que muda em cada um; **uma** confirmação. Spec + tasks em cada projeto alterado, com
  `Relacionada a: <projeto>/.specs/<feature>` entre elas; projeto de referência citado na spec (sem spec própria).
  Tasks por repositório (arquivos permitidos de um único repositório por task); comandos de build/teste do
  `CLAUDE.md` de cada projeto; nunca commit; `git status` de cada repositório alterado ao final. Ambiguidade de alvo
  ou valor → perguntar (dentro da mesma pergunta de confirmação).
- **REQ-006 — Docs e versão**: README/manual: seção "Trabalhar entre projetos" (os 3 modos: dentro do projeto, com
  `--add-dir`, no workspace; e o efeito no deny); `templates/CLAUDE.workspace.md` cita o `.claude/` com deny do modelo ∪ projetos;
  `sdd` 0.6.3; CHANGELOG.

## Critérios de aceite

- Workspace com `CLAUDE.md` curto + `.claude/` com deny do modelo ∪ projetos + 2 repos: "oi" → sem proposta de migração, sem
  pergunta "qual projeto". Workspace com `.specs/` ou `## Stack` no `CLAUDE.md`: propõe migração (comportamento 0.6.2).
- Hook: `claude_dir`/`specs_dir` corretos (com/sem pasta; symlink não seguido); sem nomes do projeto na saída.
- Workspace com `.claude/` com deny incompleto (modelo ∪ projetos): aviso em 1 linha.
- "padronize B igual a A" no workspace: plano com B alterado e A referência, 1 confirmação; spec só em B citando A;
  sem commit. "altere A e B" : spec em A e em B ligadas por `Relacionada a:`; tasks separadas por repositório.
- Sessão em A pedindo algo de B sem acesso: resposta com os 3 itens do REQ-004.
- Workspace com deny incompleto: somente leitura (sem escrita, build/teste ou delegação) até corrigir e reiniciar.

## Validação

`claude plugin validate`; teste do hook; pilotos do TecLeader (headless) para cada critério; revisão `sdd:security`
(hook, deny no workspace, escrita em dois repositórios).
