# Spec: salinha — não abrir de novo quando já estiver aberta

Relacionada a: done/agents-office, done/office-working-state. Pedido do usuário (2026-10-13): "quando a salinha estiver
aberta, não abrir novamente". Hoje só há uma trava de 15 s no `office-start.sh`: cada sessão nova abre outra aba.

## Limite técnico (premissa)

A página é um `file://` que só **lê** `events.js`; não há servidor e a página não consegue gravar nada que o hook leia.
Logo o hook não vê se a aba existe. A detecção é por **atividade recente da sala** (heurística), não por prova de aba aberta.

## Requisitos

- **REQ-001**: no `SessionStart` (sem `--now`), o `office-start.sh` não abre o navegador se a sala teve atividade nos
  últimos 30 min: o maior entre o horário gravado em `opened` (última abertura) e o `t` do último evento de `events.js`.
  Nesse caso sai com `exit 0`, sem imprimir nada, sem apagar `events.js`, sem recopiar `office.html` e sem tocar em `opened`.
- **REQ-002**: sem atividade nos últimos 30 min (ou `opened`/`events.js` ausentes, inválidos ou com relógio no futuro),
  o comportamento atual continua: recria a sala e abre.
- **REQ-003**: `/sdd:office on` (`--now`) continua abrindo sempre (é o jeito de reabrir uma aba fechada).
- **REQ-004**: `opened`/`events.js` que sejam symlink são ignorados como atividade (e o script já os recusa adiante).
- **REQ-005**: testes em `req002-start.test.sh`: sala ativa por `opened` recente; sala ativa por evento recente com `opened`
  antigo; atividade antiga abre; `--now` abre; demais casos existentes seguem passando. Docs, CHANGELOG, `sdd` 0.9.3.

## Limites a documentar

Aba fechada pelo usuário e sessão nova dentro de 30 min: não reabre automaticamente (use `/sdd:office on`). Aba aberta e
sala parada há mais de 30 min: uma sessão nova abre outra aba. Sem mudança de permissão, de formato de evento nem de hook
(`hooks.json`) → revisão de segurança dispensada (só lê o último evento, `tail -n 1`, valor validado por regex).

## Critérios de aceite

Testes do REQ-005 verdes; `run-all` verde; `validate --strict`.
