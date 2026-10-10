# Relatório de validação — infra-engineering (T-005)

Data: 2026-10-10. Validador: tests. Status geral: VALIDADO.

| # | Verificação | Evidência | Status |
|---|---|---|---|
| 1 | REQ-001/002: SKILL.md + 3 references existem | `plugins/sdd/skills/infra-engineering/{SKILL.md,references/aws.md,azure.md,gcp.md}` | VALIDADO |
| 2 | Limites de linhas | SKILL 183 (<=190); aws 239, azure 233, gcp 244 (<=245) | VALIDADO |
| 3 | 14 seções + rodapé em cada reference | `grep '^## '`: seções 1..14 e "## Fontes e atribuição" nas 3 refs | VALIDADO |
| 4 | REQ-003: "aws" no infra-architect só como lista de nuvens | única ocorrência: "(AWS, Azure, Google Cloud)" | VALIDADO |
| 5 | `skills:` e caminho da referência | `skills: sdd-rules, domain-modeling, infra-engineering`; `${CLAUDE_PLUGIN_ROOT}/skills/infra-engineering/references/<nuvem>.md` (linha 44) | VALIDADO |
| 6 | `claude plugin validate` (plugins/sdd e raiz) | ambos "Validation passed" | VALIDADO |
| 7 | Piloto Azure | Read na 1a chamada em `.../plugins/sdd/skills/infra-engineering/references/azure.md` (depois 1 Glob); Front Door+WAF, App Service, Azure SQL, Key Vault, managed identity, private endpoint; sem termos AWS/GCP; prévia `az deployment ... what-if`; "Não usar `az deployment ... create --confirm-with-what-if`"; 0 Bash/Write | VALIDADO |
| 8 | Piloto GCP | Read na 1a chamada em `.../references/gcp.md` (depois 1 Glob); Cloud SQL HA regional + réplica, Secret Manager, Workload Identity Federation, VPC-SC; sem termos AWS/Azure; `terraform plan`, `gcloud ... describe/get-iam-policy/previews list`; 0 Bash/Write | VALIDADO |
| 9 | Piloto AWS | Read na 1a chamada em `.../references/aws.md` (depois 1 Glob); Aurora Multi-AZ + Global Database, Secrets Manager, IAM Identity Center, KMS; sem termos Azure/GCP; `validate-template`, `create-change-set`, `describe-*`; "Não usar `execute-change-set`"; 0 Bash/Write | VALIDADO |

## Observações (não bloqueantes)
- AWS lista `create-change-set` como prévia; a resposta ressalva que cria recurso de change set sem alterar a stack (consistente com a tabela "só prévia" da reference).
- Resposta GCP incluiu nota fora de escopo sobre conectores claude.ai não autorizados (ruído do ambiente).
- Os .jsonl dos pilotos foram apagados ao final.
