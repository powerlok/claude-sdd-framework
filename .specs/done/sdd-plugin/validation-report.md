# Relatório de validação — feature sdd-plugin

Data: 2026-10-09. Versões: `sdd` 0.1.2, `authoring` 0.2.0. Claude Code 2.1.288.

## Requisitos

| REQ | Evidência | Resultado |
|---|---|---|
| REQ-001 plugin + marketplace | `claude plugin validate` OK (marketplace, sdd, authoring); instalação limpa em `sdd-install-test` (validation/t008a.md, cenário 1); update 0.1.1→0.1.2 executado | OK |
| REQ-002 regras chegam ao projeto | tecleader carrega `sdd:sdd-rules`/`sdd:sdd-governance` via Skill; recusou implementar sem spec e não criou arquivos (t008a, cenário 4) | OK |
| REQ-003 tecleader na sessão principal | `"agent": "sdd:tecleader"` no settings; resposta de papel (t008a, cenário 3; spike-result.md) | OK |
| REQ-004 backend/frontend agnósticos | 0 menções de linguagem/framework nos agentes; mesma delegação gerou FastAPI (t008b) e ASP.NET Core (t008c) idiomáticos | OK |
| REQ-005 skills com references por stack | Read de `references/python.md` e `references/dotnet.md` nos pilotos; após D-001, leitura direta do plugin (2 chamadas) | OK |
| REQ-006 skills de frontend corrigidas | sem links quebrados, sem URL buscada em uso, sem citação a projeto externo (T-004, security-review.md) | OK |
| REQ-007 métodos com origem/licença | rodapés com repo@commit e SPDX; authoring reescrito com texto próprio (T-010) | OK |
| REQ-008 catálogo opcional | `authoring:` ausente sem instalação (t008a, cenário 2); presente após `plugin install authoring@...` | OK |
| REQ-009 README | `README.md` com instalação local/Bitbucket, atualização, uso, árvore de pastas | OK |

## Testes executados

- Piloto Python: `pytest` 13 passed (8 do agente + 5 do validador) — validation/t008b.md
- Piloto .NET: `dotnet test` 9 passed + 3 extras do validador — validation/t008c.md
- Regressão `app-workshop`: `npm test` 9/9; `npm run build` OK; E2E 6/6 em porta isolada 4180

## Segurança

security-review.md: volta 1 RISCO IDENTIFICADO (1 MEDIUM, 4 LOW) → volta 2 APROVADO.

## Defeitos

- D-001 corrigido (sdd 0.1.2) e reverificado. D-002 documentado no README. D-003 ambiental (porta 4173 de outro projeto).

## Riscos conhecidos

- Caminho `.mcp.json` do Jira não testado com Zscaler ativo; nomes `mcp__atlassian__*` não verificados.
- Referência Angular inexistente (lacuna declarada pelos agentes).
- Carregamento de regras no tecleader depende da instrução (sem pré-carregamento na sessão principal); observado funcionando em t008a.
- Comandos de exemplo das references (lint, auditoria de dependências) não executados nos pilotos.
