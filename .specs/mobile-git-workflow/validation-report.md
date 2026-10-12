# Relatório de validação: mobile-git-workflow

Revisor/testador independente (sdd:tests). Data: 2026-10-11. Nada do plugin/templates foi editado.
Ambiente: Windows, Git Bash, Node/npm e Python disponíveis; CLI `claude` ausente do PATH.

## REQ -> resultado

| REQ | Verificação | Resultado |
|---|---|---|
| REQ-001/002/003 | Estático: `mobile.md` (sem `Agent`, regra git), skill e referência existem; `plugin validate --strict` e delegação real | PASSOU (estático) / NÃO EXECUTADO (validate, delegação: CLI ausente) |
| REQ-002 | App Expo temporário (`create-expo-app --template blank-typescript`, SDK 57, RN 0.86, sem login/EAS): jest-expo + RNTL, `npm test` | PASSOU (1/1) com divergências abaixo |
| REQ-004 | Flutter retorna `referência: nenhuma` | NÃO EXECUTADO (depende do agente real) |
| REQ-005 | `git-workflow.md`: chave, algoritmo de slug, `-F` | PASSOU (regra); testes abaixo |
| REQ-006 | `/sdd:git-lang` real e onboarding | NÃO EXECUTADO (CLI); texto da skill revisado: ok |
| REQ-007 | Repo git temporário: `switch -c`, `add -- arquivo`, `diff --cached --name-only`, `commit -F` com Conventional Commit; mensagem saiu intacta (aspas, `$(whoami)`, crases literais), branch `feat/PROJ-1-tela-de-login`, `b.txt` não entrou | PASSOU |
| REQ-008 | Matcher Python sobre deny/ask (ver security-review.md "Re-parecer volta 1"): contornos negados, `push`/`commit`/`switch`/`add` em ask, leitura livre. Motor real | PASSOU (simulado) / NÃO EXECUTADO (motor real); falso positivo D-1 |
| REQ-009 | Chave: válidas `PROJ-1 AB-12 GH#42 GL#7`; rejeitadas `PROJ-1\n`, `PROJ-1\n--force`, `proj-1`, `A-1`, `PROJ-`, dígitos full-width, `PROJ-1; rm -rf`, `../PROJ-1`, vazio, espaço final, acento. Slug: `Corrigir; rm -rf /` -> `corrigir-rm-rf`; `../../etc/passwd` -> `etc-passwd`; `$(whoami) \`id\`` -> `whoami-id`; unicode NFKD -> `autenticacao-com-acao`; japonês e vazio -> slug vazio (pedir ao usuário); 60 `a` -> 40; `--force -D` -> `force-d`; saída sempre `[a-z0-9-]` | PASSOU |
| REQ-010 | `run-all.sh --no-page`: "TODOS OS TESTES PASSARAM"; 83 links relativos nos arquivos novos/alterados, 0 quebrados; `plugin.json` 0.9.0 e CHANGELOG 0.9.0 | PASSOU (linkcheck/suíte); NÃO EXECUTADO (`validate --strict`) |

## Defeitos e divergências

1. **D-1 (MEDIUM)**: deny `git * <palavra>*` nega caminhos como `git add -- config/app.ts` ou
   `git commit -F tag-notes.txt` (detalhe e correção em security-review.md).
2. Duplicatas em `deny`: `Edit/Write(**/.git/**)` e `~/.gitconfig` aparecem duas vezes (inócuo).
3. Referência `react-native-expo.md:82-84`: `npx expo install ... --dev` não testado literalmente; usei
   `-- --save-dev` (o `--` do aviso para Windows) e funcionou (jest ~29.7, jest-expo ~57.0.5, RNTL ^14.1.0).
4. Referência: faltam os passos que o `npm test` exige no app gerado (o template não traz script `test`; a
   referência cita "script test", mas não mostra `"test": "jest"`). Com o preset e script adicionados, passou.
5. RNTL 14: `render` é assíncrono (`await render(...)`); a referência não menciona. Sugestão: uma linha.
6. `react-test-renderer` aparece como dependência transitiva de `jest-expo` (não é instalada diretamente); a nota
   "obsoleto: não usar" continua válida como orientação para o projeto.
7. `git` no Windows emitiu avisos de LF/CRLF (sem impacto).

## Não executado (CLI `claude` ausente)

`claude plugin validate --strict`, delegação real do TechLead a `sdd:mobile`, `/sdd:git-lang` real, onboarding,
motor de permissões real (deny/ask evidenciados só por simulação de glob), comportamento de `Bash(git push)` sem
argumentos no matcher real.
