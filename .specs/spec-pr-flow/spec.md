# Spec: fim da spec abre o PR; o merge é do usuário

Relacionada a: publish-opt-in, done/mobile-git-workflow (fluxo Git). Pedido do usuário (2026-10-13): "não quero que faça o
merge, isso deve ser do usuário. Só até abrir a PR" e "o caminho feliz seria: ele terminou a spec, commita em uma branch
específica para o spec atual e cria um PR para o usuário olhar e aprovar".

## Caminho feliz

Uma branch por spec (`<tipo>/<ISSUE>-<slug>`, criada no início, com confirmação) → commits locais por task ou lote
(com confirmação) → spec DONE → o TechLead propõe **um único lote**: `git push -u origin <branch>` + PR com o texto montado
da spec → depois da confirmação, executa e entrega a **URL do PR** → para. Revisar, aprovar e fazer o **merge** é do usuário.

## Requisitos

- **REQ-001**: `gh pr merge`, `gh.exe pr merge` e `glab mr merge` saem do grupo de publicação e ficam em `deny` fixo nos
  modelos de settings e fora de `project-settings.publicacao.json` (o grupo passa a ser: PR `create|comment`, `release create`,
  `glab mr create|note`, `az repos pr create`). Merge por MCP e `az repos pr update` já estavam em `deny`.
- **REQ-002**: o TechLead nunca faz merge (nenhum modo); o texto do PR/instruções diz "o merge é do usuário".
- **REQ-003**: ao concluir a spec (todas as tasks DONE, validação sem defeito aberto), com `## Git` e modo publicação
  `confirmar`, o TechLead apresenta o lote (branch, commits a enviar, comando de push, comando e texto integral do PR) e
  pede **uma** confirmação do lote; cada comando ainda passa pelo `ask` do Claude Code. Falha ou recusa em qualquer
  passo: parar e informar o que ficou feito. Sem o modo `confirmar`: entrega o texto do PR e os comandos, como hoje.
- **REQ-004**: texto do PR (em `git-workflow.md`) ganha: link da spec, tabela REQ → evidência, resultado da validação,
  parecer de segurança (quando houver), limites conhecidos, e a linha "Aguardando revisão e merge do usuário".
- **REQ-005**: uma branch e um PR por spec; spec que reabre usa a mesma branch enquanto o PR não for mesclado.
- **REQ-006**: docs, CHANGELOG, `sdd` 0.9.4; `req007-publicacao.test.js` atualizado (merge em `deny`, fora do grupo;
  texto sem "merge" como ação do agente).

## Segurança

Só restringe (retira o merge) e orquestra ações já revisadas, mantendo confirmação e `ask`. Revisão independente
dispensada; a regra "nunca merge" é verificada pelos testes. Registrar na spec `publish-opt-in` que o merge saiu do escopo.

## Critérios de aceite

Testes verdes; `validate --strict`; docs sem "o TechLead faz merge"; sandbox: pedido de publicação mostra o lote e o merge
é recusado com "é do usuário".
