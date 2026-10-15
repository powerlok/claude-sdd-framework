# Spec: a pergunta da salinha dos agentes é feita no `/sdd:start`

Pedido do usuário (2026-10-15): "salinha deve estar com default off e não on, e deve fazer uma pergunta se o usuário gostaria de ativar" → "as perguntas iniciais precisam serem feitas no momento que rodarmos /sdd:start".
Relacionada a: done/agents-office, done/start-command, done/start-banner.

## Estado atual (verificado em 2026-10-15)

- Default: sem `office.conf` (`pref=unset`) a salinha não abre nem grava; já era desligada por padrão.
- A pergunta existia "ao FIM da primeira resposta" do TechLead (qualquer mensagem) e no fim do onboarding; o `/sdd:start` só citava a salinha na lista de perguntas.
- O hook que injeta `[sdd:office] pref=...` roda só em `startup`; depois de `/clear` o TechLead perde a informação.

## Requisitos

- **REQ-001**: a pergunta "Quer ligar a salinha dos agentes...?" é feita pelo `/sdd:start` (passo 3), uma única vez, só com `pref=unset`; aceite explícito liga (`office-pref.sh on`), recusa grava `off`.
  Com `pref=on|off` não pergunta. O `/sdd:start` define o texto e a ordem (depois do onboarding, antes de pedir o primeiro pedido).
- **REQ-002**: fora do `/sdd:start` o TechLead NÃO oferece a salinha por conta própria (nem no fim da primeira resposta); pedido do usuário em texto livre ("liga a salinha") continua valendo.
  O fim do onboarding só oferece quando ele roda dentro do `/sdd:start`.
- **REQ-003**: o hook `office-pref.sh status` também roda em `SessionStart` `clear`, para `/sdd:start` depois de `/clear` ainda enxergar a preferência.
- **REQ-004**: default continua desligado (sem arquivo = nada abre); testes, docs (README, primeiros passos, manual), CHANGELOG (dentro da `sdd` 0.12.0, ainda sem tag).
