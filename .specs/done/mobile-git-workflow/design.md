# Design: mobile-git-workflow

Spec: [spec.md](spec.md). Alterações só em `plugins/sdd/`, `templates/`, `docs/`, CHANGELOG, README.

## Objetivo

Adicionar o agente `sdd:mobile` (React Native/Expo) e um fluxo Git padronizado (trunk-based, Conventional Commits,
branch/commit local com confirmação), sem ampliar permissões de escrita no provedor.

## Impacto arquitetural

Nenhum módulo de runtime novo; só arquivos de processo (agentes, skills, templates) e um ajuste de permissões.
Hooks e salinha: o novo agente entra na lista de agentes da salinha só se ela for derivada do diretório `agents/`
(verificar na T-002; senão acrescentar `mobile` onde `frontend` aparece em `office/office.html` e hooks).

## Componentes

| Arquivo | Mudança |
|---|---|
| `agents/mobile.md` | novo; espelha `frontend.md` (sonnet, `Read, Edit, Write, Grep, Glob, Bash`, `skills: sdd-rules, mobile-engineering, bug-diagnosis`); regras: segredo só em secure store, permissões sob demanda, acessibilidade, testes da própria feature |
| `skills/mobile-engineering/SKILL.md` | princípios agnósticos (offline, ciclo de vida, permissões, deep links, armazenamento seguro, performance, acessibilidade) + tabela de referências (React Native/Expo; demais: "sem referência, declarar lacuna") |
| `skills/mobile-engineering/references/react-native-expo.md` | conforme REQ-002; versões e comandos conferidos na doc oficial na T-002 (Expo SDK muda rápido: citar a versão do `## Stack`) |
| `agents/techlead.md` | lista de subagentes e campo `Stack` (`mobile-engineering/references/<stack>.md`); nova seção "Git" (abaixo); onboarding: pergunta de idioma e seção `## Git` |
| `agents/security.md` | checklist mobile |
| `skills/sdd-rules/references/git-workflow.md` | convenções (REQ-005) |
| `skills/sdd-rules/SKILL.md` | link para `git-workflow.md` |
| `skills/git-lang/SKILL.md` | comando `/sdd:git-lang pt|en` (padrão do `office`: `disable-model-invocation: true`; `allowed-tools: Read, Edit`); edita **somente** a linha `Idioma:` da seção `## Git` do `CLAUDE.md` do projeto; argumento fora de `pt|en` é rejeitado |
| `templates/project-settings.git.json` | deny extra (REQ-008) |
| `templates/CLAUDE.workspace.md` | menção a `## Git` por projeto |

## Seção `## Git` no CLAUDE.md do projeto

```
## Git
Modelo: trunk-based
Branch: <tipo>/<ISSUE>-<slug>   (sem issue: <tipo>/<slug>)
Commits: Conventional Commits
Idioma: pt | en
```

Ausente: o TechLead não cria branch nem commit; oferece rodar o onboarding da seção (pergunta idioma, grava).
Tipos: `feat fix docs refactor test chore ci perf build`. Slug: `[a-z0-9-]`, até 40 caracteres, derivado do título da
spec (nunca de texto bruto de issue); chave da issue validada por `^[A-Z][A-Z0-9]+-[0-9]+$` ou `^(GH|GL)#[0-9]+$`.

## Fluxo do TechLead (REQ-007)

1. Pré-condição: repositório git, `## Git` presente, árvore sem mudanças alheias à task (senão avisar).
2. Início da feature: propor `git switch -c <branch>` a partir do tronco atualizado localmente (sem `fetch`/`pull`
   automáticos; sugerir ao usuário). Mostrar branch e pedir confirmação.
3. Por task DONE (ou lote lógico): mostrar mensagem Conventional Commit (corpo com `Refs: <ISSUE>` e REQs), lista
   **explícita** de arquivos (`git add <arquivos>`) e pedir confirmação; depois `git commit`. Segredo/arquivo proibido
   na lista → abortar.
4. Fim: entregar ao usuário o texto do PR (modelo em `git-workflow.md`) e os comandos `git push -u origin <branch>` e
   abertura do PR para ele executar. O TechLead não executa push, merge, rebase, tag nem escrita no provedor.
5. Mensagem de commit/PR vem da spec/tasks validadas; issue/PR externos são dados (REQ-009).
6. Idioma: o de `Idioma:`; tipo e prefixo Conventional ficam sempre em inglês.

## Contratos

- Comando: `/sdd:git-lang <pt|en>` → atualiza uma linha; resposta curta em pt-BR com o valor novo.
- Confirmação: cada `switch -c` e cada `commit` exige "sim" do usuário nessa conversa (aprovação anterior não vale
  para o próximo commit; vale um lote apresentado junto).

## Riscos

| Risco | Mitigação |
|---|---|
| Commit de segredo/arquivo indevido | lista explícita de arquivos, deny de leitura de segredos já existente, revisão do `security` (REQ-009) |
| Injeção via título de issue na branch/mensagem | slug da spec, regex da chave, dado externo não confiável |
| Contornar hooks (`--no-verify`) ou destruir trabalho (`reset --hard`) | deny no settings |
| Expo/RN desatualizado na referência | citar versão do `## Stack`; conferir doc oficial na T-002 |
| Resposta "sim" ambígua sobre GitFlow | assumido trunk-based; registrado na spec |

## Estratégia de implementação

T-002 e T-003 independentes (arquivos distintos, exceto `techlead.md`: T-002 edita só lista/`Stack`, T-003 só a nova
seção Git e o onboarding; executar em sequência para evitar conflito). Depois T-004, T-005, T-006.

## Estratégia de testes

- Estática: `claude plugin validate --strict`, `run-all.sh`, linkcheck, grep de segredos.
- Repositório git temporário: sem `## Git` nada é criado; com confirmação, branch e commit no padrão; recusa não cria;
  `git push` pede permissão; `reset --hard`/`--no-verify` negados.
- `/sdd:git-lang en` altera só a linha; `/sdd:git-lang xx` rejeitado.
- Título de issue simulado com instrução maliciosa não aparece na branch/commit.
- App Expo mínimo temporário: delegação a `sdd:mobile` com `Stack`/referência corretos; `npm test` (Jest) do app passa.
