# Pesquisa Google Cloud — T-001c (infra-engineering)

- Data de consulta: 2026-10-10
- Requisitos: REQ-002, REQ-004, REQ-005 (`spec.md`)
- Legenda: **[C]** confirmado na URL citada nesta consulta; **[NC]** não confirmado (conhecimento prévio, verificar antes de usar).
- Observação: `cloud.google.com/...` de documentação redireciona (301) para `docs.cloud.google.com/...` [C]. Usar o domínio novo nas referências.
- Conteúdo abaixo são fatos parafraseados, não texto copiado. Escrever a referência final com texto próprio.

## 1. Well-Architected Framework

- Nome atual: "Google Cloud Well-Architected Framework". Seis pilares: Operational excellence; Security, privacy, and compliance; Reliability; Cost optimization; Performance optimization; Sustainability. [C] https://docs.cloud.google.com/architecture/framework
- Perspectivas transversais: AI and ML; Financial services. [C] (mesma URL)
- Reliability tem 9 princípios (metas baseadas na experiência do usuário, metas realistas, redundância, escala horizontal, observabilidade, degradação graciosa, testar recuperação de falhas, testar recuperação de perda de dados, postmortems). [C] https://docs.cloud.google.com/architecture/framework/reliability
- Security tem 7 princípios (security by design, zero trust, shift-left, defesa preemptiva, uso seguro de IA, IA para segurança, conformidade regulatória). [C] https://docs.cloud.google.com/architecture/framework/security
- Cost optimization tem 4 princípios (alinhar gasto a valor, cultura de custo, otimizar uso, otimizar continuamente). [C] https://docs.cloud.google.com/architecture/framework/cost-optimization
- Operational excellence: prontidão com SLOs, gestão de incidentes, otimização de recursos, automação de mudanças, melhoria contínua. [C] https://docs.cloud.google.com/architecture/framework/operational-excellence

## 2. Organização / landing zone

- Hierarquia: Organization → Folders → Projects → recursos; IAM e Organization Policies são herdados de cima para baixo. [C] https://docs.cloud.google.com/resource-manager/docs/cloud-platform-resource-hierarchy
- Organization exige Google Workspace ou Cloud Identity; garante que projetos pertençam à empresa, não a indivíduos. Folders podem ser aninhados (departamentos/ambientes). [C] (mesma URL)
- Enterprise foundations blueprint: uma organização, folders por ambiente, Shared VPC central, sem tráfego de/para internet por padrão, log sinks agregados em projeto central, Org Policies contra configurações de risco, SCC para detecção. [C] https://docs.cloud.google.com/architecture/blueprints/security-foundations
- Implementação Terraform do blueprint: `terraform-google-modules/terraform-example-foundation`. [C] (mesma URL)
- Organization Policy Service: IAM define "quem", Org Policy define "o quê" (restrições de configuração); constraints gerenciadas e customizadas; herança com override; modo dry-run que só registra violações. [C] https://docs.cloud.google.com/resource-manager/docs/organization-policy/overview
- Labels: chave-valor, até 64 por recurso, minúsculas; usados para quebrar custos na fatura; não colocar dados sensíveis. Tags (diferente de labels) servem para condicionar políticas (IAM/firewall). [C] https://docs.cloud.google.com/resource-manager/docs/labels-overview

## 3. Identidade e acesso

- Tipos de role: basic, predefined, custom. Em produção, não conceder basic roles salvo sem alternativa; preferir predefined/custom mínimos. [C] https://docs.cloud.google.com/iam/docs/roles-overview
- Owner/Editor/Viewer aparecem como roles básicos legados (não aceitam IAM Conditions); a página também cita nomes novos (Admin/Writer/Reader). [C] (mesma URL) — confirmar nomenclatura antes de citar.
- Service accounts: evitar chaves sempre que possível; ordem sugerida: credenciais de usuário (dev) → SA anexada / Workload Identity (GKE) → Workload Identity Federation (externo) → chave só em último caso. [C] https://docs.cloud.google.com/iam/docs/best-practices-service-accounts
- Constraints: `iam.disableServiceAccountKeyCreation`, `iam.disableServiceAccountKeyUpload`, `iam.automaticIamGrantsForDefaultServiceAccounts` (evita Editor automático em SAs padrão); aplicadas por padrão em organizações criadas após 2024-05-03. [C] (mesma URL)
- Uma SA por aplicação; não depender de access scopes; não compartilhar SAs padrão; desabilitar antes de excluir. [C] (mesma URL)
- Workload Identity Federation: workloads externos (AWS, Azure, AD, GitHub/GitLab, OIDC, SAML 2.0, X.509) trocam credencial por token de curta duração via STS; acesso direto a recurso ou via impersonation de SA. [C] https://docs.cloud.google.com/iam/docs/workload-identity-federation
- Recommender (Active Assist) gera recomendações de IAM (remover permissões excedentes); recomenda revisão humana antes de aplicar. [C] https://docs.cloud.google.com/recommender/docs/overview

## 4. Rede

- VPC é recurso global; subnets são regionais. [C] https://docs.cloud.google.com/vpc/docs/vpc
- Cada projeto ganha uma rede `default` (auto mode) com regras pré-criadas: `default-allow-internal`, SSH, RDP, ICMP; recomendação: custom mode em produção. Existe regra implícita de deny para ingress. [C] (mesma URL)
- Shared VPC: host project com a rede; service projects usam subnets; mesma organização; projeto não pode ser host e service ao mesmo tempo; centraliza subnets/rotas/firewall. [C] https://docs.cloud.google.com/vpc/docs/shared-vpc
- Cloud NGFW: hierarchical firewall policies (org/folder), global e regional network firewall policies, além de VPC firewall rules; secure tags governadas por IAM. [C] https://docs.cloud.google.com/firewall/docs/firewall-policies-overview
- Private Google Access: VMs só com IP interno alcançam APIs Google; habilitado por subnet. [C] https://docs.cloud.google.com/vpc/docs/private-google-access
- Private Service Connect: endpoints com IP interno para APIs Google e serviços publicados (produtores); mais controle que PGA. [C] https://docs.cloud.google.com/vpc/docs/private-service-connect
- Cloud NAT: saída para internet sem IP externo, sem conexões de entrada não solicitadas; regional; gerenciado (sem VMs proxy). [C] https://docs.cloud.google.com/nat/docs/overview
- VPC Service Controls: perímetros de serviço contra exfiltração de dados, independentes do IAM; modo dry-run para observar antes de impor. [C] https://docs.cloud.google.com/vpc-service-controls/docs/overview

## 5. Computação

- Compute Engine: controle total de SO/kernel, configurações especiais; GKE: microsserviços/orquestração Kubernetes; Cloud Run: containers/jobs sem administrar servidor. [C] https://docs.cloud.google.com/docs/compute-area/choose-compute-options
- GKE: Google recomenda Autopilot para a maioria das cargas; Standard quando precisar de privilégios/configurações fora das restrições do Autopilot; Autopilot gerencia nós e escala. [C] https://docs.cloud.google.com/kubernetes-engine/docs/concepts/choose-cluster-mode
- "Cloud Run functions" é a geração atual de funções e roda como serviço Cloud Run; "Cloud Functions (1st gen)" é a original. [C] https://docs.cloud.google.com/run/docs/functions/comparison
- Comparação Cloud Run x GKE: [C] https://docs.cloud.google.com/kubernetes-engine/docs/concepts/gke-and-cloud-run (página encontrada na busca, não lida em detalhe).

## 6. Dados

- Cloud SQL: MySQL/PostgreSQL/SQL Server gerenciado, backups e HA; AlloyDB: PostgreSQL compatível para cargas exigentes; Spanner: relacional distribuído globalmente, consistência forte, SLA até 99,999%; Firestore: documentos serverless; BigQuery: data warehouse analítico. [C] https://cloud.google.com/blog/topics/developers-practitioners/your-google-cloud-database-options-explained (blog; apenas fatos, sem números de marketing)
- Uniform bucket-level access: desliga ACLs, só IAM; reversível por 90 dias; recomendado. Constraint `storage.uniformBucketLevelAccess`. [C] https://docs.cloud.google.com/storage/docs/uniform-bucket-level-access
- Public access prevention: bloqueia `allUsers`/`allAuthenticatedUsers`; por bucket ou constraint `storage.publicAccessPrevention`; não afeta Signed URLs. [C] https://docs.cloud.google.com/storage/docs/public-access-prevention
- Versionamento: versões não-correntes cobradas como objetos vivos; combinar com Object Lifecycle Management; para proteção contra exclusão acidental/maliciosa a Google recomenda soft delete. [C] https://docs.cloud.google.com/storage/docs/object-versioning

## 7. Segredos e chaves

- Secret Manager: IAM no nível do segredo; projetos separados por ambiente; fixar versão em vez de `latest`; rotação periódica; desabilitar antes de destruir; evitar passar segredos por env/arquivo (usar API/cliente); habilitar Data Access logs. [C] https://docs.cloud.google.com/secret-manager/docs/best-practices
- Criptografia em repouso padrão (chaves Google, AES-256); CMEK = chaves do cliente no Cloud KMS; níveis de proteção Software, Cloud HSM, Cloud EKM; Autokey provisiona chaves sob demanda; constraint `gcp.restrictNonCmekServices` exige CMEK. [C] https://docs.cloud.google.com/kms/docs/cmek

## 8. Observabilidade

- Google Cloud Observability: Cloud Monitoring, Cloud Logging, Cloud Trace, Error Reporting, Cloud Profiler; Managed Service for Prometheus; OpenTelemetry; Ops Agent para VMs. [C] https://docs.cloud.google.com/stackdriver/docs
- Audit Logs: Admin Activity e System Event sempre ligados (bucket `_Required`, 400 dias); Data Access desligado por padrão exceto BigQuery (volume alto); Policy Denied ligado (bucket `_Default`, 30 dias). [C] https://docs.cloud.google.com/logging/docs/audit
- Blueprint usa sinks agregados no nível de organização para projeto central de logs. [C] https://docs.cloud.google.com/architecture/blueprints/security-foundations

## 9. Custo

- Budgets "alerts-only" não limitam gasto; limiares padrão 50/90/100%; real ou previsto; Pub/Sub para automação (ex.: desabilitar billing de projeto). [C] https://docs.cloud.google.com/billing/docs/how-to/budgets
- Billing export para BigQuery: standard, detailed, pricing (e FOCUS/CUD metadata em preview); não é totalmente retroativo; habilitar junto com a criação da billing account. [C] https://docs.cloud.google.com/billing/docs/how-to/export-data-bigquery
- CUDs: resource-based (Compute Engine, por região/projeto) e spend-based (inclui Flexible Savings Plans), termos de 1 ou 3 anos (resource-based até 6 anos), compra no billing account para spend-based. [C] https://docs.cloud.google.com/docs/cuds
- Recommender: VMs ociosas, rightsizing, recomendações de CUD. [C] https://docs.cloud.google.com/recommender/docs/overview
- Labels para alocação de custo. [C] https://docs.cloud.google.com/resource-manager/docs/labels-overview

## 10. Resiliência / DR

- RTO = tempo máximo aceitável offline; RPO = janela máxima aceitável de perda de dados; metas menores custam mais e aumentam complexidade. [C] https://docs.cloud.google.com/architecture/dr-scenarios-planning-guide
- Padrões cold / warm / hot standby descritos no guia de DR. [C] (mesma URL) — detalhamento por padrão [NC].
- Redundância e testes de recuperação (falha e perda de dados) são princípios do pilar Reliability. [C] https://docs.cloud.google.com/architecture/framework/reliability
- Zonal x regional x multirregional como níveis de redundância. [NC] (ver https://docs.cloud.google.com/docs/geography-and-regions)
- Backup and DR Service: backups centralizados por política, imutabilidade WORM, backup vaults imutáveis/indeléveis (retenção até 99 anos); cobre Compute Engine, discos, Filestore, Cloud SQL, AlloyDB, bancos autogerenciados, VMware Engine. [C] https://docs.cloud.google.com/backup-disaster-recovery/docs/concepts/backup-dr

## 11. Segurança / compliance

- Security Command Center: tiers Standard, Premium, Enterprise (Enterprise será descontinuado em 2027-05-21, migração para Premium); Security Health Analytics, Event/Container Threat Detection, análise de caminhos de ataque, conformidade (NIST, PCI-DSS). [C] https://docs.cloud.google.com/security-command-center/docs/security-command-center-overview
- Cloud Armor: DDoS e WAF com regras pré-configuradas (OWASP), em load balancers de aplicação/rede; Adaptive Protection no Enterprise. [C] https://docs.cloud.google.com/armor/docs/cloud-armor-overview
- Modo preview de regras do Cloud Armor. [NC]
- Binary Authorization: políticas de imagem com attestations para GKE, Cloud Run, Cloud Service Mesh, GDC; dry-run; validação contínua. [C] https://docs.cloud.google.com/binary-authorization/docs/overview
- Assured Workloads: fronteiras de residência, regulatórias (HIPAA, FedRAMP, ITAR) e soberanas; controle de acesso de pessoal Google; monitora violações via org policies. [C] https://docs.cloud.google.com/assured-workloads/docs/overview

## 12. IaC

- Terraform: provider `google` (e `google-beta`) [NC]; blueprints/módulos Terraform oficiais (inclui example-foundation). [C] https://docs.cloud.google.com/docs/terraform/blueprints/terraform-blueprints
- Cloud Foundation Toolkit: "best practices as code", blueprints Terraform + CLI; Apache 2.0. [C] https://github.com/GoogleCloudPlatform/cloud-foundation-toolkit
- OpenTofu com provider google: compatível via registry. [NC]
- Infrastructure Manager: serviço gerenciado que executa Terraform (fontes: Cloud Storage, Git, local). [C] https://docs.cloud.google.com/infrastructure-manager/docs/overview
- Preview no Infra Manager executa `terraform plan` e não altera recursos: `gcloud infra-manager previews create|describe|list|export|delete`. [C] https://docs.cloud.google.com/infrastructure-manager/docs/preview-deployment e https://docs.cloud.google.com/sdk/gcloud/reference/infra-manager/previews
- Comandos que APLICAM/alteram (exigem confirmação explícita): `terraform apply`, `terraform destroy`, `gcloud infra-manager deployments apply` [NC para o nome exato], `... deployments delete` [NC]. Somente leitura/plan: `terraform plan`, `terraform validate`, `previews create/describe/export`.
- Config Connector: add-on Kubernetes open source que gerencia recursos GCP via CRDs, reconcilia de forma assíncrona com SA dedicada; doc não cita dry-run (alterações em manifesto aplicadas = mudança real). [C] https://docs.cloud.google.com/config-connector/docs/overview

## 13. CLI somente leitura (exemplos)

- `gcloud projects describe|list|get-iam-policy|get-ancestors` são leitura; `create|delete|update|set-iam-policy|add/remove-iam-policy-binding|undelete` alteram. [C] https://docs.cloud.google.com/sdk/gcloud/reference/projects
- `gcloud config list`, `gcloud compute instances list`, `gcloud asset search-all-resources`, `gcloud recommender recommendations list` são leitura. [NC]
- Usar placeholders (`PROJECT_ID`, `LOCATION`), nunca IDs reais.

## 14. Skills / guias para agentes de IA

- `github.com/google/skills`: repositório oficial Google de Agent Skills (formato `SKILL.md`), Apache 2.0; cobre IAM/onboarding, arquitetura, GKE, Cloud Storage, redes, BigQuery, Spanner, Cloud SQL, AlloyDB, Cloud Run, Monitoring/Logging, custos, segurança; instalação via `npx skills add google/skills` (não executar — apenas referência). [C] https://github.com/google/skills ; anúncio: https://cloud.google.com/blog/topics/developers-practitioners/level-up-your-agents-announcing-googles-official-skills-repository/
- `github.com/google/mcp`: lista de MCP servers Google (remotos gerenciados: BigQuery, Compute Engine, GKE, Cloud Run, Cloud Storage, Cloud SQL, Spanner, Firestore, Resource Manager etc.); Apache 2.0; aviso "not an officially supported Google product", demonstração. [C] https://github.com/google/mcp (MCP está fora de escopo da spec — só citar como trabalho futuro)
- `googleapis/gcloud-mcp`: MCP do gcloud CLI, Apache 2.0, preview, possui deny list de comandos. [C] https://github.com/googleapis/gcloud-mcp
- Valor para a skill: confirma o formato SKILL.md e temas prioritários; conteúdo Apache 2.0 permite reuso com atribuição, mas a spec pede texto próprio.

## 15. Licenças

- Docs Google Cloud: texto CC BY 4.0, amostras de código Apache 2.0 (rodapé). [C] https://docs.cloud.google.com/architecture/framework
- CC BY 4.0 não é ShareAlike: permite adaptação com atribuição; ainda assim, usar texto próprio (REQ-004).
- Blog Google Cloud: licença não verificada [NC] — usar só fatos.

## 16. Armadilhas comuns

- Chaves JSON de service account (vazamento); usar WIF/SA anexada; bloquear via constraints. [C] https://docs.cloud.google.com/iam/docs/best-practices-service-accounts
- Basic roles (Owner/Editor) em produção; SAs padrão com Editor automático. [C] roles-overview + best-practices-service-accounts
- Rede `default` com SSH/RDP/ICMP abertos; usar custom mode. [C] https://docs.cloud.google.com/vpc/docs/vpc
- Buckets públicos/ACLs: aplicar UBLA e public access prevention via org policy. [C] storage docs acima
- Achar que budget limita gasto (alerts-only não limita); billing export ativado tarde perde histórico. [C] budgets + export docs
- Data Access logs desligados por padrão (lacuna de auditoria em dados sensíveis). [C] https://docs.cloud.google.com/logging/docs/audit
- Versionamento sem lifecycle (custo crescente). [C] object-versioning
- Aplicar recomendações do Recommender sem revisão. [C] recommender overview
- Sem labels → custo não atribuível. [C] labels-overview

## Fontes

| URL | Licença | Uso permitido |
|---|---|---|
| https://docs.cloud.google.com/architecture/framework (e subpáginas) | CC BY 4.0 (texto), Apache 2.0 (código) | Fatos e paráfrase com atribuição |
| https://docs.cloud.google.com/architecture/blueprints/security-foundations | CC BY 4.0 / Apache 2.0 | Fatos com atribuição |
| docs.cloud.google.com — IAM, VPC, NAT, Firewall, PSC, PGA, VPC-SC, Storage, KMS, Secret Manager, Logging, Billing, CUDs, Recommender, Backup and DR, SCC, Armor, BinAuthz, Assured Workloads, Infra Manager, Config Connector, gcloud reference | CC BY 4.0 / Apache 2.0 [C para o framework; demais assumem o mesmo rodapé, NC por página] | Fatos com atribuição |
| https://cloud.google.com/blog/... (opções de banco, google/skills) | Não verificada [NC] | Somente fatos, sem texto |
| https://github.com/google/skills | Apache 2.0 [C] | Referência; reuso permitido com atribuição (preferir texto próprio) |
| https://github.com/google/mcp | Apache 2.0 [C] | Referência (fora de escopo) |
| https://github.com/googleapis/gcloud-mcp | Apache 2.0 [C] | Referência (fora de escopo) |
| https://github.com/GoogleCloudPlatform/cloud-foundation-toolkit | Apache 2.0 [C] | Referência |
| https://github.com/terraform-google-modules/terraform-example-foundation | Não verificada [NC] (provável Apache 2.0) | Referência |
