# Spec: higiene de contexto por spec (sugerir /clear no momento certo)

Pedido do usuário (2026-10-14): validar se cada spec nova abre um contexto novo para gastar menos tokens; "só se for a mesma tarefa continuar no mesmo contexto". "sim" à
regra proposta. Relacionada a: done/onboarding-check, done/spec-pr-flow.

## Validação (doc oficial, code.claude.com/docs/en/costs e /commands, 2026-10-14)

- O framework **não** abre contexto novo por spec: a sessão do TechLead segue até o usuário rodar `/clear` ou `/compact`; só as delegações a subagentes têm janela isolada.
- Cada mensagem reenvia a conversa inteira; a doc recomenda `/clear` ao trocar para tarefa **não relacionada** (`/rename` antes, `/resume` para voltar), `/compact` para continuar a
  mesma conversa; `/clear` não custa nada e `/compact` é uma requisição grande.
- Comandos nativos só são reconhecidos quando o **usuário** os digita no início da mensagem: o agente não consegue executar `/clear` nem `/compact`. Automação possível só da
  compactação: `autoCompactWindow`, `--autocompact`, `CLAUDE_CODE_AUTO_COMPACT_WINDOW`, `idleCompaction`.

## Requisitos

- **REQ-001**: regra "Higiene de contexto" no `techlead.md` e na `sdd-governance`: sugerir `/clear` em **uma linha** (a) ao arquivar uma spec (estado em `.specs/`), (b) ao receber pedido de spec
  ou tarefa **diferente** da que a conversa vem tratando; **não** sugerir na mesma tarefa (correção, nova rodada, bug da mesma spec); no máximo uma vez por spec; recusa = não insistir; antes
  de sugerir, garantir `tasks.md` atualizado e dizer o que fica salvo; `/rename` antes se quiser voltar com `/resume`.
- **REQ-002**: hook `SessionStart` com matcher `clear` roda `onboarding-check.sh` e `start-banner.sh` (o diagnóstico de onboarding só era injetado no `startup`, então depois de `/clear` o
  TechLead ficava sem ele).
- **REQ-003**: docs (README, manual, primeiros passos), CHANGELOG, `sdd` 0.10.2, testes (`req008`: banner também em `clear`; texto da regra).

## Fora de escopo

Executar `/clear`/`/compact` pelo agente (impossível); `autoCompactWindow` no modelo de settings (decisão do usuário, a propor); rodar cada spec em subagente/sessão própria.

## Critérios de aceite

Testes verdes; `validate --strict`; CLI real: `hooks.json` aceita o matcher `clear`.
