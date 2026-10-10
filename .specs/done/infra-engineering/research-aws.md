# Pesquisa AWS — insumo para `references/aws.md` (T-001a)

- Data de consulta: 2026-10-10
- Escopo: REQ-002, REQ-004, REQ-005 da `spec.md`. Somente leitura; nenhum comando executado contra nuvem.
- Legenda: **[C]** = confirmado na fonte citada nesta data; **[NC]** = não confirmado nesta sessão (conhecimento prévio; validar antes de usar).
- Regra de redação: a documentação AWS é CC BY-SA 4.0 (ver §15). Este arquivo traz só **fatos** em texto próprio; quem
  escrever `aws.md` NÃO deve copiar nem parafrasear de perto frases da AWS.

## 1. Well-Architected Framework

- Seis pilares: Operational Excellence, Security, Reliability, Performance Efficiency, Cost Optimization,
  Sustainability. [C] https://docs.aws.amazon.com/wellarchitected/latest/framework/the-pillars-of-the-framework.html
- WA Tool: gratuito no console; revisão por perguntas de cada pilar; lens "AWS Well-Architected Framework" aplicada
  por padrão. [C] https://docs.aws.amazon.com/wellarchitected/latest/userguide/lenses.html
- Lenses: catálogo oficial + custom lenses; até 20 por workload (5 por vez). [C] (mesma URL)
- Lenses oficiais relevantes: Serverless Applications, Container Build, SaaS, Generative AI, Machine Learning, Data
  Analytics, DevOps, Migration, IoT, SAP, Financial Services, Healthcare, Government, entre outras.
  [C] https://docs.aws.amazon.com/wellarchitected/latest/userguide/lens-catalog.html
- "AWS Well-Architected Agent" aparece em preview na doc do WA Tool. [C] (mesma URL)

## 2. Organização / landing zone

- Conta AWS = fronteira de isolamento de IAM; sem acesso entre contas por padrão; custo não depende do nº de contas;
  recomenda-se várias contas por workload/ambiente (prod separada de não-prod).
  [C] https://docs.aws.amazon.com/whitepapers/latest/organizing-your-aws-environment/organizing-your-aws-environment.html
- OUs recomendadas: fundacionais (Security, Infrastructure), aplicação (Workloads, prod e não-prod), experimentais
  (Sandbox), procedurais (Exceptions, Transitional, Suspended, Policy Staging), avançadas (Deployments, Business
  Continuity, Individual Business Users). Nem todas são obrigatórias.
  [C] https://docs.aws.amazon.com/whitepapers/latest/organizing-your-aws-environment/recommended-ous-and-accounts.html
- Security OU deve conter só as contas de segurança exigidas pelo Control Tower. [C] (whitepaper acima)
- Control Tower: orquestra Organizations + IAM Identity Center + Service Catalog; cria landing zone; controles
  preventivos, detectivos e proativos (obrigatórios / fortemente recomendados / eletivos); Account Factory; detecção
  de drift. [C] https://docs.aws.amazon.com/controltower/latest/userguide/what-is-control-tower.html
- SCPs (limitam principals) e RCPs (limitam recursos) são guardrails; **não concedem** permissão.
  [C] https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html
- IAM Identity Center é o recomendado para acesso humano centralizado multi-conta. [C] (mesma URL)

## 3. Identidade e acesso

- Humanos: federação via IdP + credenciais temporárias; workloads: roles IAM (temporárias). [C]
  https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html
- Fora da AWS (CI/CD, on-prem): IAM Roles Anywhere, `AssumeRoleWithWebIdentity` (OIDC/JWT), SAML — evitar chaves
  longas. [C] (mesma URL)
- Chaves de acesso longas só em casos sem alternativa; usar "last used" para rotacionar/remover. [C] (mesma URL)
- MFA obrigatório onde houver usuário IAM/root; preferir MFA resistente a phishing (passkey/security key). [C]
- Menor privilégio: começar com managed policies e reduzir para customer managed; usar condições (ex.: TLS). [C]
- Access Analyzer: gera política a partir do CloudTrail, valida políticas (>100 checks), aponta acesso público e
  cross-account. [C] (mesma URL)
- Permission boundaries: teto de permissões ao delegar criação de roles; não concedem nada. [C] (mesma URL)
- Root: não criar access keys; MFA (até 8 dispositivos); e-mail de grupo; em Organizations, centralizar root access e
  remover credenciais de root das contas membro; monitorar uso do root.
  [C] https://docs.aws.amazon.com/IAM/latest/UserGuide/root-user-best-practices.html

## 4. Rede

- Subnets em múltiplas AZs; Flow Logs; Network Access Analyzer; Network Firewall; GuardDuty usa flow logs.
  [C] https://docs.aws.amazon.com/vpc/latest/userguide/vpc-security-best-practices.html
- VPCs separadas por workload/entidade; subnets por camada; subnets privadas para o que não deve ser exposto; rotas
  mínimas. [C] https://docs.aws.amazon.com/vpc/latest/userguide/infrastructure-security.html
- Security group (instância, só allow, stateful, referencia outros SGs) = controle primário; NACL (subnet,
  allow+deny, stateless, avaliação por ordem) = camada secundária/defesa em profundidade. [C] (mesma URL)
- PrivateLink (interface endpoints) evita IGW/NAT para serviços AWS. [C] (mesma URL)
- Gateway endpoints: só S3 e DynamoDB, sem custo adicional, via rota/prefix list; não usam PrivateLink.
  [C] https://docs.aws.amazon.com/vpc/latest/privatelink/gateway-endpoints.html
- Transit Gateway: hub regional para VPCs, VPN, Direct Connect; peering inter-região; cobrança por attachment/hora +
  tráfego. [C] https://docs.aws.amazon.com/vpc/latest/tgw/what-is-transit-gateway.html

## 5. Computação (critérios)

- Camadas: capacidade (EC2, Fargate, Outposts) / orquestração (ECS, EKS, ROSA) / soluções verticais (App Runner,
  Lambda, Lightsail, Batch).
  [C] https://docs.aws.amazon.com/decision-guides/latest/containers-on-aws-how-to-choose/choosing-aws-container-service.html
- Critérios oficiais: overhead operacional, padrão de workload, portabilidade, tamanho/skills do time, facilidade de
  deploy. EKS exige time com SRE (Kubernetes ~3 releases/ano); ECS = mais controle de rede/segurança sem Kubernetes;
  App Runner = caminho mais simples para web/API. [C] (mesma URL)
- Fargate funciona com ECS e EKS (sem gerenciar instâncias). [C] (mesma URL)
- Lambda: timeout máximo 900 s (15 min); default 3 s.
  [C] https://docs.aws.amazon.com/lambda/latest/dg/configuration-timeout.html
- EC2: máximo controle (SO, tipo de instância, GPU, licenças). [NC]

## 6. Dados

- RDS Multi-AZ: "DB instance" (1 standby, não serve leitura) vs "DB cluster" (2 standbys legíveis, 3 AZs).
  [C] https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Concepts.MultiAZ.html
- Aurora Global Database: replicação entre regiões tipicamente < 1 s; promoção < 1 min; até 5 regiões secundárias.
  DynamoDB global tables: multi-região ativo/ativo, "last writer wins".
  [C] https://docs.aws.amazon.com/whitepapers/latest/disaster-recovery-workloads-on-aws/disaster-recovery-options-in-the-cloud.html
- S3: Block Public Access (inclusive em nível de Organizations); ACLs desabilitadas por padrão (Object Ownership
  "bucket owner enforced"); SSE-S3 por padrão em todo bucket; opções SSE-KMS/DSSE-KMS; SSE-C desabilitado por padrão
  em buckets novos desde abr/2026; exigir TLS via `aws:SecureTransport`; versionamento; Object Lock (WORM); CRR exige
  versionamento; VPC endpoints; regras do Config (`s3-bucket-public-read-prohibited` etc.); evitar deletar buckets do
  namespace global (nome pode ser reusado por terceiros).
  [C] https://docs.aws.amazon.com/AmazonS3/latest/userguide/security-best-practices.html
- Lifecycle: Storage Lens aponta buckets sem regra de abortar multipart incompleto. [C] (mesma URL); detalhes de
  transição de classes de armazenamento [NC].

## 7. Segredos e chaves

- Secrets Manager: rotação automática, replicação entre regiões, recomendado para credenciais de banco/API keys/
  tokens; Parameter Store: pares chave-valor curtos, standard tier sem custo, sem rotação nativa; secrets > 4 KB ou
  com rotação → Secrets Manager.
  [C] https://docs.aws.amazon.com/prescriptive-guidance/latest/aws-startup-security-baseline/wkld-03.html
- KMS: rotação automática opcional para customer managed keys (padrão 365 dias, período configurável); AWS managed
  keys rotacionam anualmente; rotação on-demand; rotação não re-criptografa dados; assimétricas/HMAC/custom key
  store só rotação manual. [C] https://docs.aws.amazon.com/kms/latest/developerguide/rotate-keys.html

## 8. Observabilidade

- CloudTrail habilitado por padrão: event history = 90 dias de eventos de gerenciamento por região, sem custo; para
  retenção/organização, criar trail ou event data store (CloudTrail Lake); data events (ex.: S3 objeto) só via trail.
  [C] https://docs.aws.amazon.com/awscloudtrail/latest/userguide/view-cloudtrail-events.html
- X-Ray SDKs/Daemon em modo manutenção desde 25/02/2026; recomendação: OpenTelemetry (ADOT ou OTel SDK) + CloudWatch
  Agent/OTel Collector; CloudWatch Application Signals.
  [C] https://docs.aws.amazon.com/xray/latest/devguide/xray-sdk-migration.html
- AWS Config: avalia configurações contra regras gerenciadas e histórico de mudanças.
  [C] https://docs.aws.amazon.com/AmazonS3/latest/userguide/security-best-practices.html
- CloudWatch: métricas, logs, alarmes, dashboards. [NC]

## 9. Custo

- Tags de alocação de custo definidas pelo usuário precisam ser **ativadas** no Billing (pela management account);
  não retroagem; prefixo `aws:` reservado; não colocar dado sensível em tag; reativar ao mudar de organização.
  [C] https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/custom-tags.html
- Estratégia de tagging (whitepaper). [C] https://docs.aws.amazon.com/whitepapers/latest/tagging-best-practices/tagging-best-practices.html
- Budgets: orçamentos de custo, uso, utilização/cobertura de RI e Savings Plans; alertas real e previsto; budget
  actions (ex.: aplicar política IAM de deny); atualização até 3x/dia (há atraso).
  [C] https://docs.aws.amazon.com/cost-management/latest/userguide/budgets-managing-costs.html
- Savings Plans: compromisso $/hora por 1 ou 3 anos; Compute SP cobre EC2 (qualquer família/região), Fargate e
  Lambda; até 72% de economia; recomendações no Cost Explorer.
  [C] https://docs.aws.amazon.com/savingsplans/latest/userguide/what-is-savings-plans.html
- Compute Optimizer: rightsizing e ociosos (EC2, ASG, EBS, Lambda, ECS/Fargate, RDS/Aurora, NAT GW, DynamoDB…);
  exige opt-in; 14 dias de métricas (93 com recurso pago).
  [C] https://docs.aws.amazon.com/compute-optimizer/latest/ug/what-is-compute-optimizer.html

## 10. Resiliência / DR

- 4 estratégias (custo/complexidade crescentes, RTO/RPO decrescentes): backup & restore, pilot light, warm standby,
  multi-site active/active (ou hot standby). Pilot light = núcleo de dados ligado, app "desligada"; warm standby =
  cópia reduzida já servindo.
  [C] https://docs.aws.amazon.com/whitepapers/latest/disaster-recovery-workloads-on-aws/disaster-recovery-options-in-the-cloud.html
- Multi-AZ cobre perda de data center; multi-Region quando o "desastre" é a região ou por regulação. [C] (mesma URL)
- Failover deve usar operações de **data plane** (mais disponíveis que control plane); ARC (Application Recovery
  Controller) para failover manual via data plane; failover automático com cautela (falso alarme). [C] (mesma URL)
- IaC é pré-requisito para restaurar infra rápido; testar backups/restores regularmente; replicação contínua não
  protege contra corrupção → manter backups point-in-time. [C] (mesma URL)
- AWS Backup: centraliza backups, cópia cross-Region e cross-account (protege contra comprometimento de conta).
  [C] (mesma URL)
- Elastic Disaster Recovery (DRS): replicação em bloco de servidores, modelo pilot light. [C] (mesma URL)
- Resilience Hub: define metas (RTO/RPO), avalia postura, recomenda melhorias, integra Fault Injection Service.
  [C] https://docs.aws.amazon.com/resilience-hub/latest/userguide/what-is.html

## 11. Segurança / compliance

- Security Hub foi reformulado em solução unificada (correlaciona GuardDuty, Inspector, Macie e Security Hub CSPM);
  o Security Hub "clássico" agora se chama **Security Hub CSPM**.
  [C] https://docs.aws.amazon.com/securityhub/latest/userguide/what-is-securityhub-v2.html
- GuardDuty: detecção de ameaças (CloudTrail, flow logs, DNS, S3 protection). [C]
  https://docs.aws.amazon.com/AmazonS3/latest/userguide/security-best-practices.html
- Inspector: gestão de vulnerabilidades (EC2, imagens ECR, Lambda). [NC]
- WAF: protege CloudFront, API Gateway REST, ALB, AppSync, Cognito, App Runner, Verified Access, Amplify, AgentCore
  Gateway; managed rule groups; modo Count para testar regras. Shield Standard incluso sem custo; Shield Advanced
  pago (L3/4/7, SRT). Firewall Manager centraliza multi-conta.
  [C] https://docs.aws.amazon.com/waf/latest/developerguide/what-is-aws-waf.html

## 12. IaC (nativo + Terraform/OpenTofu)

- CloudFormation change set: `create-change-set` e `describe-change-set` **não alteram** a stack (preview);
  `execute-change-set` **aplica**. Há drift-aware change sets.
  [C] https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/using-cfn-updating-stacks-changesets.html
- Aplicam mudança (exigir confirmação): `aws cloudformation deploy`, `create-stack`, `update-stack`, `delete-stack`,
  `execute-change-set`. [NC] (nomes de comandos da CLI; confirmar no CLI reference)
- `cdk diff`: preview; por padrão cria um change set **somente leitura** usando a deploy role e pode **publicar
  assets** (build/upload) antes do diff; `--method=template` evita change set (menos preciso, usa lookup role).
  `cdk deploy`/`cdk destroy` aplicam. [C] https://docs.aws.amazon.com/cdk/v2/guide/ref-cli-cmd-diff.html
  → Atenção REQ-005: `cdk diff` não é 100% inerte (publica assets em bucket/ECR de bootstrap).
- `terraform plan` não executa mudanças; `-out` salva plano; `-refresh-only`; `terraform apply`/`destroy` aplicam.
  [C] https://developer.hashicorp.com/terraform/cli/commands/plan
- OpenTofu: fork MPL-2.0 com fluxo plan/apply equivalente (`tofu plan`). [C] licença https://github.com/opentofu/opentofu;
  equivalência de comando [NC].
- Provider AWS (hashicorp/terraform-provider-aws) é MPL-2.0 e usado por ambos. [C] https://github.com/hashicorp/terraform-provider-aws

## 13. CLI somente leitura (exemplos seguros)

- `aws sts get-caller-identity` (quem sou) [NC — comando padrão]
- `aws organizations list-accounts`, `aws ec2 describe-vpcs`, `aws ec2 describe-security-groups`,
  `aws s3api get-public-access-block --bucket <nome>`, `aws iam list-roles`,
  `aws cloudformation describe-stacks`, `aws cloudformation describe-change-set` [NC — prefixos describe/list/get
  são leitura por convenção]
- `aws cloudtrail lookup-events` (event history). [C] https://docs.aws.amazon.com/awscloudtrail/latest/userguide/view-cloudtrail-events.html
- `aws login` para credenciais temporárias na CLI (inclusive root, em vez de access keys).
  [C] https://docs.aws.amazon.com/IAM/latest/UserGuide/root-user-best-practices.html
- Exemplos devem usar placeholders (`<account-id>`, `<bucket>`), nunca IDs reais (REQ-005).

## 14. Skills/guias públicos para agentes

| Fonte | Licença | O que acrescenta |
| --- | --- | --- |
| Agent Toolkit for AWS — https://github.com/aws/agent-toolkit-for-aws (doc: https://docs.aws.amazon.com/agent-toolkit/latest/userguide/plugins.html) | Apache-2.0 [C] | Plugins oficiais (aws-core, aws-agents, aws-data-analytics, aws-agents-for-devsecops) para Claude Code/Codex com skills + config do AWS MCP Server; permite restringir agente a ações read-only via IAM context keys; auditoria via CloudTrail [C] |
| Agent Plugins for AWS — https://github.com/awslabs/agent-plugins | Apache-2.0 [C] | Plugins deploy-on-aws, aws-serverless, databases-on-aws, migration-to-aws etc.; recomenda revisar código gerado, menor privilégio e scan de IaC [C] |
| AWS MCP Servers — https://github.com/awslabs/mcp | Apache-2.0 [C] | MCP de documentação/knowledge, IaC (CFN/CDK), pricing, bancos; vários com modo read-only. Fora de escopo como integração (spec), útil só como contexto [C] |
| aws-agent-skills (itsmostafa), aws-skills (zxkane) | [NC] | Comunitários, não oficiais — não usar como base sem revisão de licença [NC] |

## 15. Licenças

- docs.aws.amazon.com: documentação em **CC BY-SA 4.0**; código de exemplo em **MIT-0**; demais conteúdo do site
  aws.amazon.com sob licença limitada (sem reprodução comercial). [C] https://aws.amazon.com/terms/
- Repositórios awsdocs no GitHub: doc CC BY-SA 4.0, código de exemplo MIT modificado. [C — via busca, várias cópias
  dos repos awsdocs; validar no repo original se for citar]
- Consequência: ShareAlike → usar apenas fatos (não protegidos), reescrever do zero, citar fonte; não adaptar
  estrutura/frases; snippets de código só se forem MIT-0 e atribuídos, ou próprios.

| URL | Licença | Uso permitido aqui |
| --- | --- | --- |
| docs.aws.amazon.com/* (guias, whitepapers, prescriptive guidance, decision guides) | CC BY-SA 4.0 | Fatos + link; texto próprio |
| aws.amazon.com (páginas de produto/terms) | Licença limitada AWS Site Terms | Somente fatos + link |
| developer.hashicorp.com (Terraform docs) | [NC] (Terraform core BUSL-1.1 [C] https://github.com/hashicorp/terraform/blob/main/LICENSE) | Fatos + link |
| github.com/hashicorp/terraform-provider-aws | MPL-2.0 [C] | Fatos + link |
| github.com/opentofu/opentofu | MPL-2.0 [C] | Fatos + link |
| github.com/aws/agent-toolkit-for-aws | Apache-2.0 [C] | Fatos/ideias + link (texto próprio) |
| github.com/awslabs/agent-plugins | Apache-2.0 [C] | idem |
| github.com/awslabs/mcp | Apache-2.0 [C] | idem |
| github.com/awsdocs/aws-doc-sdk-examples | Apache-2.0 [C] | não necessário |

## 16. Armadilhas comuns

- Bucket S3 público / política com `"Principal": "*"` ou ação `*`; ACLs "Everyone". [C] (S3 best practices)
- Access keys no root, root sem MFA, uso rotineiro do root. [C] (root best practices)
- Access keys de longa duração em app/CI em vez de role/OIDC. [C] (IAM best practices)
- SG com 0.0.0.0/0 em portas administrativas (22/3389). [NC] (controles Security Hub CSPM EC2 — confirmar IDs)
- Subnets em uma única AZ / RDS sem Multi-AZ em produção. [C] (VPC best practices; RDS Multi-AZ)
- Tags de custo criadas mas não ativadas (não aparecem em relatórios; não retroagem). [C] (custom-tags)
- Confiar só em replicação (propaga corrupção/deleção) sem backup point-in-time e sem teste de restore. [C] (DR whitepaper)
- Failover dependente de control plane (ex.: Auto Scaling, mudar pesos DNS) — menos resiliente. [C] (DR whitepaper)
- Quotas de serviço não ajustadas na região de DR. [C] (DR whitepaper)
- Tratar `cdk diff` como inerte (publica assets). [C] (cdk diff)
- Deletar bucket do namespace global (nome pode ser registrado por outra conta). [C] (S3 best practices)
- Contar com SCP para conceder acesso (SCP só limita). [C] (IAM best practices)
- Usar X-Ray SDK em projeto novo (modo manutenção). [C] (X-Ray migration)
