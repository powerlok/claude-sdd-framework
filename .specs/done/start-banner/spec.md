# Spec: aviso de início de sessão (o TechLead só responde depois da primeira mensagem)

Pedido do usuário (2026-10-14): depois de instalar o plugin e abrir `claude`, nada aparece ("Faço o onboarding agora?"
não é perguntado) e o terminal fica esperando. "O ideal é ter uma mensagem de start para chamar o TechLead e o projeto começar."

## Causa

O Claude Code só gera resposta depois de uma mensagem do usuário. O hook `onboarding-check.sh` injeta o diagnóstico no
contexto do modelo (`additionalContext`/stdout), mas isso **não aparece na tela**: a pergunta de onboarding só vem na
primeira resposta, e a primeira resposta só vem depois de o usuário digitar. Os docs também nunca diziam para digitar.

## Verificado (2026-10-14)

- `initialPrompt` no frontmatter do agente (primeiro turno automático) é **ignorado para agente de plugin**: teste com cópia do
  plugin e `initialPrompt: "Responda somente BANANA"` → o TechLead respondeu normalmente. Não serve.
- Hook `SessionStart` com saída JSON `systemMessage` é mostrado ao usuário como aviso (doc oficial, code.claude.com/docs/en/hooks).

## Requisitos

- **REQ-001**: novo hook `start-banner.sh` (`SessionStart`, matcher `startup`, síncrono, `timeout` curto) que imprime **um único
  objeto JSON** `{"systemMessage": "<texto constante>"}`; nada mais no stdout. Sempre `exit 0`; falha = saída vazia.
- **REQ-002**: o texto depende só de existência de arquivos na raiz do projeto (como `onboarding-check.sh`): sem `CLAUDE.md` ou
  sem `## Stack` → "ainda sem onboarding: escreva qualquer mensagem (ex.: oi) e o TechLead mostra a situação e propõe o
  onboarding"; com onboarding → "TechLead pronto: escreva o que precisa, ou oi para ver a situação". Nenhum texto vindo do projeto
  entra na mensagem (só constantes), sem escrita, sem rede, sem executar o git.
- **REQ-003**: só no `startup` (não em `resume`/`clear`/`compact`).
- **REQ-004**: `primeiros-passos.md` (passo 3), README e manual dizem que é preciso **escrever a primeira mensagem** e que o aviso
  aparece ao abrir; troubleshooting para "abri o `claude` e nada acontece".
- **REQ-005**: testes `req008-banner.test.sh` (JSON válido, só `systemMessage`, dois estados, nome de arquivo hostil não vaza, só
  `startup`, sempre exit 0); `hooks.json` válido; `sdd` 0.9.5, CHANGELOG, `validate --strict`.

## Limites

O aviso orienta, não faz o TechLead falar sozinho (o Claude Code não permite primeiro turno automático para agente de plugin).
Se a sessão não estiver usando o agente `sdd:techlead`, o aviso não sabe disso; o texto manda conferir "Sou o TechLead" na resposta.
Sem mudança de permissão nem de formato de evento → revisão de segurança dispensada (só constantes e testes de existência).

## Critérios de aceite

Testes verdes; `validate --strict`; no CLI real (`--output-format stream-json`) a mensagem chega como mensagem de sistema do hook.
