# Spec: conformidade com a documentação oficial do Claude Code

Pedido do usuário (2026-10-11), após auditoria (2 agentes `claude-code-guide`, somente leitura, code.claude.com/docs).

## Fase 0 — Reteste (antes de corrigir)

- H1: `${CLAUDE_PLUGIN_ROOT}` é substituído no corpo de **skill** de plugin (doc diz sim; nosso teste antigo disse não).
- H2: idem no corpo de **agente** de plugin, inclusive quando ele é o agente **principal** (`--agent`).
- H3: subagente **com** a ferramenta `Agent` consegue chamar outro subagente; **sem** ela, não (doc: até 3 níveis).
- H4: `CLAUDE.md` de subpasta é carregado sob demanda ao ler arquivo dela (sessão no workspace).

## Requisitos (a confirmar após a Fase 0)

- **REQ-001 — Precedência real**: `claude-md-layers.md` e `sdd-rules`: o Claude Code concatena os `CLAUDE.md` (sem
  sobreposição automática; em conflito o modelo pode escolher qualquer um). Regra do processo: uma fonte por regra;
  havendo conflito, o agente aplica a do projeto e sinaliza (exceto controles não relaxáveis).
- **REQ-002 — Textos factuais**: corrigir conforme a Fase 0: `${CLAUDE_PLUGIN_ROOT}` (R/CLAUDE.md, docs, authoring),
  subagentes (sem `Agent` em `tools` → não delegam), carregamento sob demanda de `CLAUDE.md` de subpasta.
- **REQ-003 — Descrições de subagentes** com gatilho "Use quando ..." (backend, frontend, tests, security,
  infra-architect) e caso de uso no início da description de `sdd-rules`.
- **REQ-004 — Licença**: `LICENSE` na raiz e campo `license` (SPDX) nos `plugin.json` (licença definida pelo usuário;
  `authoring` mantém o material Apache-2.0 com seu LICENSE.txt).
- **REQ-005 — Release**: `claude plugin validate --strict` (sdd, authoring e marketplace) no procedimento de
  manutenção (R/CLAUDE.md, README) e executado nesta entrega; README explica `ref` opcional (fixar branch/tag).
- **REQ-006 — Imposição dos controles**: ampliar `permissions.deny` dos templates com leitura de segredos
  (`.env`, `.env.*`, chaves privadas) e `git push --force`; documentar o limite (deny de Bash não é barreira).
  Hook `PreToolUse` somente se a revisão de segurança indicar necessidade.
- **REQ-007 — Versão** `sdd` 0.6.4, `authoring` 0.2.1; CHANGELOG.

Fora de escopo (decisão separada): dividir `tecleader.md`, tirar Bash do `security`, `agent` no `plugin.json`.

## Critérios de aceite

- Fase 0 registrada com evidência; textos coerentes com o resultado.
- `claude plugin validate --strict` ✔ nos 2 plugins e no marketplace.
- Templates: JSON válido; nenhum deny com parênteses em `mcp__`; regras novas presentes.
- Linkcheck sem quebras.
