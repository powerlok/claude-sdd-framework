# Spec: renomear o agente `sdd:tecleader` para `sdd:techlead`

Pedido do usuário (2026-10-11): "preciso que mude o nome do agente sim, está errado como está" e "de todos os
documentos que o nome existir". Mudança incompatível → `sdd` 0.8.0.

## Requisitos

- **REQ-001 — Agente**: `agents/tecleader.md` → `agents/techlead.md` (`name: techlead`); toda referência `sdd:tecleader`
  → `sdd:techlead`. Texto: "TecLeader" → "TechLead"; "tecleader" → "techlead"; "TECLEADER" → "TECHLEAD".
- **REQ-002 — Abrangência**: plugins (agentes, skills, hooks, scripts, testes, `office.html` — ids e rótulos),
  `templates/` (`"agent": "sdd:techlead"`), README, `docs/`, `CLAUDE.md` do repositório, `.claude-plugin/`,
  descrições dos `plugin.json`/marketplace, skills do `authoring` (exemplos). **Não editar**: `.specs/done/**` (histórico),
  entradas antigas do CHANGELOG, backups.
- **REQ-003 — Migração sem quebrar**: manter por UMA versão `agents/tecleader.md` como agente **obsoleto** mínimo
  (`tools: Read` apenas, sem escrita): avisa que foi renomeado e instrui o usuário a trocar
  `"agent": "sdd:tecleader"` por `"agent": "sdd:techlead"` no `.claude/settings.json` (ou `settings.local.json`) e
  reiniciar; não executa nenhum trabalho. Remoção prevista na versão seguinte (registrar no CHANGELOG).
- **REQ-004 — Docs de migração**: CHANGELOG (seção 0.8.0 com "Migração" passo a passo), `docs/primeiros-passos.md`
  ("Atualizar a versão" + problemas comuns: sessão abre com o agente obsoleto), README (nota breve).
- **REQ-005 — Versão**: `sdd` 0.8.0. Release/tag e `ref` do template só com confirmação do usuário.

## Critérios de aceite

- `grep -rIni tecleader` (excluindo `.specs/done`, entradas históricas do CHANGELOG, backups e o agente obsoleto)
  retorna vazio; `claude plugin validate --strict` ✔ (plugins e marketplace); `run-all.sh` passa; links ok.
- Piloto real: `--agent sdd:techlead` → sessão responde como TechLead (diagnóstico de onboarding, skills carregadas);
  `--agent sdd:tecleader` → agente obsoleto com a instrução de migração e sem escrita; `/sdd:office` e a salinha
  continuam funcionando (rótulo "TechLead").
- Revisão de segurança: dispensada se o agente obsoleto não tiver ferramentas de escrita e nenhuma permissão mudar
  (verificado por grep de `tools:`).
