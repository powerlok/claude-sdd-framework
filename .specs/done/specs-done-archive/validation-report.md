# Relatório de validação: specs-done-archive (T-003)

Status: VALIDADO

| Verificação | Evidência | Resultado |
|---|---|---|
| `claude plugin validate` em R e plugins/sdd | "Validation passed" nos dois | VALIDADO |
| Regras em tecleader / sdd-rules / sdd-governance | tecleader.md:180,188,207-236,515; sdd-rules/SKILL.md:113,115; sdd-governance/SKILL.md:100 | VALIDADO |
| `Arquivar specs concluídas` em templates/CLAUDE.md | linha 80: "sim (padrão) \| não" | VALIDADO |
| Hook pós-compact cita INDEX.md | hooks/hooks.json:9 | VALIDADO |
| Verificador de links em R | 93 links, 0 quebrados | VALIDADO |
| git status: renames das 5 features | R para `.specs/done/` (angular-reference, docs-manual, infra-engineering, sdd-plugin, vcs-integration) | VALIDADO |
| INDEX.md: 1 ativa + 5 concluídas | specs-done-archive ativa; 5 concluídas com links `done/...` válidos | VALIDADO |
| Piloto 1: `.specs/done/login/` existe, `.specs/login/` não | `ls .specs` = INDEX.md, done | VALIDADO |
| Piloto 1: rename no git | `R .specs/login/spec.md -> .specs/done/login/spec.md` (+ tasks, validation-report) | VALIDADO |
| Piloto 1: README aponta para done | `[spec de login](.specs/done/login/spec.md)` | VALIDADO |
| Piloto 1: INDEX com login em concluídas | `\| [login](done/login/spec.md) \| 2026-10-10 \| ...` | VALIDADO |
| Piloto 1: links | 2 verificados, 0 quebrados | VALIDADO |
| Piloto 1: resposta registra arquivamento | "A spec da feature login foi arquivada em .specs/done/login/. Nenhum link ficou quebrado." | VALIDADO |
| Piloto 2 (desligado): nada movido | sem `.specs/done`, `.specs/login` intacto; resposta: "Não arquivei a spec, porque o CLAUDE.md do projeto desliga esse passo" | VALIDADO |

Observações (não bloqueantes):
- Piloto 2: o agente apontou que o INDEX listava login como VALIDATING e não o corrigiu (comportamento coerente com "somente arquivamento").
- Piloto 1 deixou README.md e INDEX.md como alterados não commitados (esperado).
- Em R, `specs-done-archive` consta IN_PROGRESS no INDEX; o encerramento cabe ao TecLeader.
- Arquivos temporários (.jsonl) apagados.
