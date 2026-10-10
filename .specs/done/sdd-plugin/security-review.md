# Revisão de segurança (T-007)

Revisor: agente `security` (somente leitura, sem rede, sem execução de scripts).

## Volta 1 — RISCO IDENTIFICADO (sem HIGH/CRITICAL)

| # | Sev. | Achado | Correção |
|---|---|---|---|
| 1 | MEDIUM | `authoring` redistribuía cópias de anthropics/claude-code ("All rights reserved") | T-010: reescrito com texto próprio a partir da doc pública; cópias removidas; `skill-creator-original.md` (anthropics/skills@83291af, Apache-2.0) mantido com LICENSE e aviso de modificação |
| 2 | LOW | Jira só leitura dependia apenas do `tools:` do tecleader | `permissions.deny` (16 regras) nos templates de settings |
| 3 | LOW | Rodapé de `web-interface.md` sem commit/licença | `vercel-labs/web-interface-guidelines@434b7f9 (MIT)` |
| 4 | LOW | Comandos de migração sem aviso | "somente em banco local/descartável; outros ambientes exigem confirmação explícita" |
| 5 | LOW | URL do Bitbucket sem orientação sobre credenciais | Orientar no README (T-009) |
| I7 | INFO | Scripts inexistentes citados | Marcados "(não incluído neste plugin)" |
| I9 | INFO | Projeto podia relaxar regras de segurança | Exceção de não-relaxamento em `sdd-rules` e `templates/CLAUDE.md` |

## Volta 2 — APROVADO

Achados 1–4, I7 e I9 resolvidos com evidência arquivo:linha. Achado 5 segue para o README (T-009).
Sem novos achados LOW ou superiores. Observações informativas (não bloqueiam):
- `skill-creator-original.md:143,180,186`: linhas de comando sem marca (parágrafo anterior já avisa).
- Rodapés dos SKILL.md do `authoring` usam formato "baseado na documentação pública" (coerente; regra pode citar esse caso).
- Exemplo `tests` com Edit/Write: justificado, espelha o agente real.

Fora do escopo: `spike/` e `.specs/`. Defeito funcional observado (fora de escopo, arquivo removido): `validate-agent.sh` abortava no 1º erro.
