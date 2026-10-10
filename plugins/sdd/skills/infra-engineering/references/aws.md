# Referência: AWS

Complementa os princípios agnósticos de [../SKILL.md](../SKILL.md).
Ler somente quando a nuvem do projeto (seção `## Stack`/`## Infra` do `CLAUDE.md` ou campo `Stack:`) for AWS.

## 1. Framework oficial

- AWS Well-Architected Framework, com seis pilares: Operational Excellence, Security, Reliability,
  Performance Efficiency, Cost Optimization e Sustainability.
- Avaliação: AWS Well-Architected Tool (console, sem custo). A revisão é feita por perguntas de cada pilar;
  a lens do próprio framework vem aplicada por padrão.
- Lenses adicionais (catálogo oficial ou custom): ex. Serverless Applications, Container Build, SaaS,
  Generative AI, Machine Learning, Data Analytics, DevOps, Financial Services. Limite: 20 por workload, 5 por vez.
- Em cada decisão, indicar o pilar afetado e o trade-off entre pilares (ex.: custo vs. confiabilidade).

## 2. Organização e landing zone

- A conta AWS é a fronteira de isolamento de IAM: sem acesso entre contas por padrão e sem custo extra por conta.
  Separar workloads e ambientes em contas distintas (produção nunca junto de não-produção).
- AWS Organizations com OUs por função. Base usual: Security e Infrastructure (fundacionais), Workloads
  com Prod e NonProd, Sandbox para experimentos. OUs procedurais (Exceptions, Transitional, Suspended,
  Policy Staging) só quando houver necessidade. A Security OU fica restrita às contas de segurança do Control Tower.
- AWS Control Tower monta a landing zone sobre Organizations, IAM Identity Center e Service Catalog:
  controles preventivos, detectivos e proativos, Account Factory e detecção de drift.
- Guardrails: SCPs restringem principals; RCPs restringem recursos. Nenhum dos dois concede permissão;
  o acesso continua dependendo de políticas IAM.
- Tags obrigatórias definidas em política da organização (ex.: `owner`, `environment`, `cost-center`);
  sem dado sensível em tag.

## 3. Identidade e acesso

- Pessoas: IAM Identity Center federado ao IdP corporativo, com credenciais temporárias e permission sets.
- Workloads na AWS: IAM roles (credenciais temporárias). Nada de access key embutida em código, imagem ou variável.
- Workloads fora da AWS: CI/CD via OIDC (`AssumeRoleWithWebIdentity`), SAML ou IAM Roles Anywhere (on-premises).
- Chave de acesso de longa duração só sem alternativa; acompanhar "last used" para rotacionar ou remover.
- MFA obrigatório para usuários IAM remanescentes e root; preferir fatores resistentes a phishing (passkey,
  security key).
- Menor privilégio: partir de managed policies, evoluir para customer managed restritas e usar condições
  (ex.: exigir TLS). Permission boundaries limitam o teto ao delegar a criação de roles; também não concedem nada.
- IAM Access Analyzer: gera política a partir da atividade no CloudTrail, valida políticas e aponta
  acesso público ou entre contas.
- Root: sem access keys, MFA ativo (aceita vários dispositivos), e-mail de grupo, uso monitorado.
  Em Organizations, centralizar o root access e remover as credenciais de root das contas membro.

## 4. Rede

- Uma VPC por workload/entidade; subnets por camada, distribuídas em múltiplas AZs; subnets privadas para tudo
  que não precisa de exposição; tabelas de rota com o mínimo necessário.
- Security groups (nível de instância, só allow, stateful, podem referenciar outros SGs) são o controle principal.
  Network ACLs (nível de subnet, allow e deny, stateless, avaliadas por ordem) são camada adicional.
- Acesso privado a serviços AWS: interface endpoints (PrivateLink) evitam IGW/NAT. Gateway endpoints existem só
  para S3 e DynamoDB, sem custo adicional, via rota/prefix list.
- Conectividade entre VPCs, VPN e Direct Connect: Transit Gateway como hub regional (cobrança por
  attachment/hora e por tráfego), com peering entre regiões.
- Saída e inspeção: AWS Network Firewall; VPC Flow Logs ligados; Network Access Analyzer para achar caminhos
  de rede não pretendidos.

## 5. Computação — critérios de escolha

Critérios oficiais: overhead operacional, padrão do workload, portabilidade, tamanho e skills do time,
facilidade de deploy.

| Opção | Escolher quando | Custo operacional |
| --- | --- | --- |
| EC2 | controle de SO, tipo de instância ou licenciamento é requisito | alto (patch, escala, imagem) |
| App Runner | web/API simples, caminho mais curto até produção | baixo |
| ECS (EC2 ou Fargate) | containers com controle de rede/segurança sem Kubernetes | médio; Fargate remove gestão de instâncias |
| EKS (EC2 ou Fargate) | portabilidade Kubernetes e time com prática de SRE | alto (cerca de 3 releases Kubernetes por ano) |
| Lambda | eventos e tarefas curtas (timeout padrão 3 s, máximo 900 s) | baixo; atenção a limites de execução |
| Batch | processamento em lote | médio |

## 6. Dados e armazenamento

- RDS Multi-AZ: modo "DB instance" (um standby sem leitura) ou "DB cluster" (dois standbys legíveis em 3 AZs).
  Produção sem Multi-AZ é exceção justificada.
- Multi-região: Aurora Global Database (replicação normalmente abaixo de 1 s, promoção abaixo de 1 min,
  até 5 regiões secundárias); DynamoDB global tables (ativo/ativo, conflito resolvido por "last writer wins").
- S3:
  - S3 Block Public Access ligado na conta e, se possível, imposto pela organização.
  - Object Ownership "bucket owner enforced" (ACLs desabilitadas, padrão atual).
  - Criptografia: SSE-S3 é aplicada por padrão; usar SSE-KMS/DSSE-KMS quando houver exigência de controle de chave.
    SSE-C vem desabilitado em buckets novos desde abril/2026.
  - Política do bucket negando requisições sem TLS (`aws:SecureTransport`).
  - Versionamento (pré-requisito da replicação entre regiões); Object Lock para retenção WORM.
  - Lifecycle com regra para abortar multipart incompleto (o S3 Storage Lens aponta buckets sem ela);
    transições de classe: confirme na documentação atual.
  - Não excluir bucket cujo nome importa: o namespace é global e outra conta pode registrar o mesmo nome.

## 7. Segredos e chaves

- AWS Secrets Manager: credenciais de banco, API keys e tokens; rotação automática e replicação entre regiões.
- SSM Parameter Store: configuração chave-valor curta; tier standard sem custo; sem rotação nativa.
  Segredo acima de 4 KB ou com rotação vai para o Secrets Manager.
- AWS KMS: customer managed keys com rotação automática opcional (padrão 365 dias, configurável) e rotação
  on-demand; AWS managed keys giram anualmente. Rotacionar não re-criptografa dados existentes.
  Chaves assimétricas, HMAC ou em custom key store só giram manualmente.
- A aplicação lê segredos em runtime via role; nunca em repositório, IaC versionado ou log.

## 8. Observabilidade e auditoria

- CloudTrail vem ativo: o event history guarda 90 dias de eventos de gerenciamento por região, sem custo.
  Para retenção maior, visão da organização ou data events (ex.: objetos S3), criar trail de organização
  ou event data store (CloudTrail Lake), gravando em conta de log separada.
- Tracing: os SDKs e o daemon do X-Ray estão em modo de manutenção desde 25/02/2026. Projeto novo usa
  OpenTelemetry (ADOT ou SDK OTel) com CloudWatch Agent ou OTel Collector; CloudWatch Application Signals
  para visão por serviço.
- AWS Config: avalia configuração contra regras gerenciadas e guarda histórico de mudanças.
- CloudWatch para métricas, logs, alarmes e dashboards (detalhes de recursos: confirme na documentação atual).

## 9. Custo

- Tags de alocação de custo definidas pelo usuário só aparecem em relatórios depois de ativadas no Billing
  (pela management account); não retroagem; prefixo `aws:` é reservado.
- AWS Budgets para custo, uso e cobertura/utilização de RI e Savings Plans, com alerta real e previsto;
  budget actions podem aplicar política de deny. Os dados atualizam até 3 vezes ao dia (há atraso).
- Savings Plans: compromisso em $/hora por 1 ou 3 anos; Compute Savings Plans cobrem EC2 (qualquer família
  e região), Fargate e Lambda; economia de até 72%. Recomendações no Cost Explorer.
- AWS Compute Optimizer (exige opt-in): rightsizing e recursos ociosos em EC2, ASG, EBS, Lambda, ECS/Fargate,
  RDS/Aurora, NAT Gateway e outros; usa 14 dias de métricas (93 na opção paga).
- Lembrar: NAT Gateway e Transit Gateway cobram por hora e por tráfego; gateway endpoints de S3/DynamoDB não.

## 10. Resiliência e DR

- Multi-AZ cobre falha de data center; multi-região quando a região inteira é o risco ou há exigência regulatória.
- Estratégias, em ordem crescente de custo e decrescente de RTO/RPO:

| Estratégia | Situação no ambiente de recuperação |
| --- | --- |
| Backup & restore | só backups; infraestrutura recriada via IaC |
| Pilot light | dados replicados e ativos; aplicação desligada |
| Warm standby | cópia reduzida já atendendo, escala no failover |
| Multi-site active/active | capacidade plena em mais de uma região |

- Failover baseado em operações de data plane (mais disponíveis que o control plane); Application Recovery
  Controller (ARC) para failover manual. Failover automático só com proteção contra falso alarme.
- Replicação propaga corrupção e exclusão: manter backups point-in-time e testar restore periodicamente.
- AWS Backup centraliza políticas e copia entre regiões e contas (protege contra conta comprometida).
- AWS Elastic Disaster Recovery: replicação em bloco de servidores no modelo pilot light.
- AWS Resilience Hub: registra metas de RTO/RPO, avalia a postura e integra com Fault Injection Service.
- Ajustar service quotas também na região de DR.

## 11. Segurança e compliance

- Security Hub agora é uma solução unificada que correlaciona achados de GuardDuty, Inspector, Macie e do
  Security Hub CSPM. O antigo Security Hub passou a se chamar Security Hub CSPM (postura e controles).
  Ao citar, deixar claro qual dos dois.
- GuardDuty: detecção de ameaças a partir de CloudTrail, flow logs, DNS e proteção de S3.
- Inspector para vulnerabilidades (cobertura exata de recursos: confirme na documentação atual).
- AWS WAF na frente de CloudFront, API Gateway REST, ALB, AppSync, Cognito, App Runner, Verified Access e
  Amplify, entre outros; managed rule groups; regra nova começa em modo Count antes de bloquear.
- Shield Standard incluso sem custo; Shield Advanced pago (L3/4/7 e equipe de resposta).
  Firewall Manager centraliza WAF/Shield em várias contas.
- Habilitar esses serviços a partir de uma conta de segurança delegada na Security OU.

## 12. IaC: CloudFormation/CDK + Terraform/OpenTofu

Qualquer coisa na coluna "APLICA MUDANÇA" exige confirmação explícita do usuário, ambiente identificado e
prévia revisada antes. Regra não relaxável.

| Ferramenta | Só mostra prévia | APLICA MUDANÇA (cuidado) |
| --- | --- | --- |
| CloudFormation | `create-change-set`, `describe-change-set` | `execute-change-set`; `deploy`, `create-stack`, `update-stack`, `delete-stack` (nomes da CLI: confirme na documentação atual) |
| CDK | `cdk diff --method=template` | `cdk deploy`, `cdk destroy` |
| Terraform | `terraform plan` (`-out`, `-refresh-only`) | `terraform apply`, `terraform destroy` |
| OpenTofu | `tofu plan` (equivalência: confirme na documentação atual) | `tofu apply`, `tofu destroy` |

- Prévia não é isenta de efeito (executa código de provider/data sources; `init` baixa providers/módulos):
  identidade somente leitura e só sobre código revisado (ver `../SKILL.md`, regra não relaxável).
- Módulos Terraform só de fonte oficial/verificada ou interna, com versão fixa; módulo da comunidade
  passa por revisão antes do uso.
- Change set: criar e descrever é prévia e não altera a stack; executar o change set aplica.
  Existem change sets drift-aware para comparar com o estado real.
- `cdk diff` sem opção não é inerte: cria um change set somente leitura usando a deploy role e pode publicar
  assets (build e upload para o bucket/ECR de bootstrap). Para prévia sem efeito colateral, usar
  `cdk diff --method=template` (menos preciso; usa a lookup role).
- Terraform e OpenTofu usam o provider `hashicorp/aws` (MPL-2.0). OpenTofu é fork MPL-2.0; Terraform core é BUSL-1.1.
- State remoto com bloqueio e criptografia, uma configuração por conta/ambiente; IaC também é pré-requisito do DR.

## 13. Comandos de exemplo (somente leitura e prévia)

Exemplos; usar os do `CLAUDE.md` do projeto. Placeholders sempre (`<account-id>`, `<bucket>`, `<stack>`),
nunca IDs reais. Fora `cloudtrail lookup-events`, `cdk diff` e `terraform plan`, os nomes seguem a convenção
`describe`/`list`/`get` de leitura: confirme na documentação atual.
Autenticação (`aws login`) é executada pelo usuário: obtém credenciais temporárias e grava cache local.
State e arquivo de plano contêm segredos: anexar ao PR só a saída textual (ver IaC em `../SKILL.md`).

```bash
aws sts get-caller-identity                 # confirmar conta e role antes de qualquer coisa
aws organizations list-accounts
aws ec2 describe-vpcs
aws ec2 describe-security-groups
aws s3api get-public-access-block --bucket <bucket>
aws iam list-roles
aws cloudtrail lookup-events --max-results 20
aws cloudformation describe-stacks --stack-name <stack>
aws cloudformation describe-change-set --stack-name <stack> --change-set-name <change-set>
cdk diff --method=template                  # prévia sem change set e sem publicar assets
terraform plan -out=<plan-file>             # prévia; não altera recursos
```

## 14. Armadilhas comuns

- Bucket público, política com `"Principal": "*"` ou ação `*`, ACL liberada para todos.
- Root com access key, sem MFA ou usado no dia a dia.
- Access key de longa duração em aplicação ou CI no lugar de role/OIDC.
- Security group aberto para `0.0.0.0/0` em portas administrativas (22/3389) — IDs dos controles: confirme na
  documentação atual.
- Subnets numa única AZ; RDS de produção sem Multi-AZ.
- Tags de custo criadas e nunca ativadas (não aparecem em relatórios e não retroagem).
- Confiar só em replicação, sem backup point-in-time nem teste de restore.
- Failover que depende de control plane (ex.: Auto Scaling ou alteração de DNS no momento da crise).
- Quotas não ajustadas na região de DR.
- Tratar `cdk diff` padrão como inerte (publica assets).
- Excluir bucket de nome conhecido (namespace global reaproveitável por terceiros).
- Esperar que uma SCP conceda acesso (SCP só restringe).
- Adotar X-Ray SDK em projeto novo (modo de manutenção).
- Confundir Security Hub CSPM com o Security Hub unificado.

---

## Fontes e atribuição

Consultado em 2026-10-10. Texto próprio; nenhum trecho copiado.
Documentação AWS licenciada em CC BY-SA 4.0 — apenas fatos; texto próprio.

- Well-Architected: https://docs.aws.amazon.com/wellarchitected/latest/framework/the-pillars-of-the-framework.html , https://docs.aws.amazon.com/wellarchitected/latest/userguide/lenses.html
- Organização: https://docs.aws.amazon.com/whitepapers/latest/organizing-your-aws-environment/organizing-your-aws-environment.html , https://docs.aws.amazon.com/controltower/latest/userguide/what-is-control-tower.html
- IAM: https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html , https://docs.aws.amazon.com/IAM/latest/UserGuide/root-user-best-practices.html
- Rede: https://docs.aws.amazon.com/vpc/latest/userguide/vpc-security-best-practices.html , https://docs.aws.amazon.com/vpc/latest/privatelink/gateway-endpoints.html , https://docs.aws.amazon.com/vpc/latest/tgw/what-is-transit-gateway.html
- Computação: https://docs.aws.amazon.com/decision-guides/latest/containers-on-aws-how-to-choose/choosing-aws-container-service.html , https://docs.aws.amazon.com/lambda/latest/dg/configuration-timeout.html
- Dados: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Concepts.MultiAZ.html , https://docs.aws.amazon.com/AmazonS3/latest/userguide/security-best-practices.html
- Segredos: https://docs.aws.amazon.com/prescriptive-guidance/latest/aws-startup-security-baseline/wkld-03.html , https://docs.aws.amazon.com/kms/latest/developerguide/rotate-keys.html
- Observabilidade: https://docs.aws.amazon.com/awscloudtrail/latest/userguide/view-cloudtrail-events.html , https://docs.aws.amazon.com/xray/latest/devguide/xray-sdk-migration.html
- Custo: https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/custom-tags.html , https://docs.aws.amazon.com/cost-management/latest/userguide/budgets-managing-costs.html , https://docs.aws.amazon.com/savingsplans/latest/userguide/what-is-savings-plans.html , https://docs.aws.amazon.com/compute-optimizer/latest/ug/what-is-compute-optimizer.html
- DR: https://docs.aws.amazon.com/whitepapers/latest/disaster-recovery-workloads-on-aws/disaster-recovery-options-in-the-cloud.html , https://docs.aws.amazon.com/resilience-hub/latest/userguide/what-is.html
- Segurança: https://docs.aws.amazon.com/securityhub/latest/userguide/what-is-securityhub-v2.html , https://docs.aws.amazon.com/waf/latest/developerguide/what-is-aws-waf.html
- IaC: https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/using-cfn-updating-stacks-changesets.html , https://docs.aws.amazon.com/cdk/v2/guide/ref-cli-cmd-diff.html , https://developer.hashicorp.com/terraform/cli/commands/plan (Terraform core BUSL-1.1), https://github.com/hashicorp/terraform-provider-aws (MPL-2.0), https://github.com/opentofu/opentofu (MPL-2.0)
- Licenças: https://aws.amazon.com/terms/
- Inspiração de formato para agentes: https://github.com/aws/agent-toolkit-for-aws (Apache-2.0); só ideias, nenhum texto reaproveitado.
