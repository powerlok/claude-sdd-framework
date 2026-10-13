# Spec: repositório público nos docs e agente mobile na salinha

Origem: pedido do usuário (2026-10-12): "o repo não é privado e pode dar push"; "sim, e atualize a salinha".
Relacionada a: `mobile-git-workflow` (0.9.0). Versão alvo: `sdd` 0.9.1.

## Requisitos

- **REQ-001**: remover a premissa de repositório privado: docs (`manual-de-uso.html`, `primeiros-passos.md`),
  regra "Marketplace privado" do `techlead.md` e de `claude-md-layers.md`, e `CLAUDE.md` do workspace.
- **REQ-002**: o agente `mobile` é conhecido pela salinha (mesa própria, placa "MOBILE", cor distinta) e o próximo
  slot dinâmico passa a 7.
- **REQ-003**: teste estático cobre REQ-002; suíte completa (inclusive página) passa.

## Critérios de aceite

- REQ-001: grep sem "privado" referente ao repositório (fora de `.specs/done/`).
- REQ-002/003: `req005-static` verifica `mobile: { slot: 6,` e `nextSlot = 7;`; `run-all.sh` completo passa.

## Fora de escopo

Renomear "tecleader" no `CLAUDE.md` do workspace e nos guias em `..\docs`; mudar `ref`/tag.
