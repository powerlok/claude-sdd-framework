# Spec: salinha — mostrar o agente trabalhando enquanto ele estiver ativo

Relacionada a: done/agents-office, done/office-visual. Pedido do usuário (2026-10-11): "o tests estava trabalhando e não
estava mostrando" (subagente `sdd:tests` em background, ~11 min, visível no painel do Claude Code como "Working").

## Hipóteses (confirmar antes de corrigir)

- H1: o estado "trabalhando" decai por tempo (design: 8 s sem evento do agente = ocioso) e `PostToolUse` não é
  registrado; num subagente que roda uma ferramenta longa (suíte de testes de minutos) ou "pensa" muito, não chegam
  eventos → o personagem volta a ocioso embora o agente esteja ativo.
- H2: a página ignora eventos antigos na primeira carga (stale > 30 s): se o usuário abre a tela depois do início do
  subagente, o `start` já passou e ele nunca aparece como trabalhando.
- H3: eventos do subagente em background (ou de ferramentas em segundo plano) chegam sem `agent_id`/`agent_type` e são
  atribuídos ao TechLead; ou o hook `SubagentStart` não dispara para subagentes em background.

## Requisitos

- **REQ-001**: um agente fica "trabalhando" desde `SubagentStart` até `SubagentStop` (ou `end` da sessão), mesmo sem
  eventos de ferramenta no intervalo; o decaimento por tempo só vale como proteção muito longa (ex.: ≥ 30 min sem
  nenhum evento → "sem atividade", com indicação visual distinta de "ocioso").
- **REQ-002**: ao abrir a página no meio da execução, o estado é reconstruído a partir do `events.js` (agentes com
  `start` sem `stop` aparecem trabalhando); eventos antigos servem para reconstruir estado, não só para animar.
- **REQ-003**: o popup/log mostra o agente ativo mesmo em silêncio (ex.: "tests: trabalhando há 10 min"), sem gravar
  dados novos além da allowlist (usar só os horários já gravados).
- **REQ-004**: se a causa for H3 (hook), corrigir `office-event.sh`/`hooks.json` mantendo a allowlist; revisão de
  segurança só se o formato dos eventos ou hooks mudar.
- **REQ-005**: testes de regressão: subagente com ferramenta longa (simulada por lacuna de 60 s+ entre eventos) segue
  trabalhando; abrir a página tarde reconstrói; `stop` encerra; reduced-motion ok. Versão `sdd` 0.8.1 + CHANGELOG.

## Critérios de aceite

Reproduzir o defeito (teste falha antes), corrigir (teste passa depois), capturas lidas pelo TecLeader; suíte completa
passando; piloto real com o Claude Code: subagente `sdd:tests` rodando um comando longo (ex.: `sleep 40` em Bash) aparece
trabalhando durante toda a espera.
