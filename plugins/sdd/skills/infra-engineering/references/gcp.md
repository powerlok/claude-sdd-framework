# Referência: Google Cloud

Complementa [../SKILL.md](../SKILL.md) com particularidades do Google Cloud.
Ler somente quando a nuvem do projeto for Google Cloud.

## 1. Framework oficial

- Nome atual: **Google Cloud Well-Architected Framework**.
- Seis pilares: Operational excellence; Security, privacy, and compliance; Reliability;
  Cost optimization; Performance optimization; Sustainability.
- Perspectivas transversais publicadas: AI and ML; Financial services.
- Pontos de cada pilar úteis para revisão de design:
  - Reliability: metas guiadas pela experiência do usuário e realistas, redundância, escala horizontal,
    observabilidade, degradação graciosa, testes de recuperação (falha e perda de dados), postmortems.
  - Security: security by design, zero trust, shift-left, defesa preventiva, conformidade regulatória.
  - Cost optimization: gasto alinhado a valor, cultura de custo, otimização de uso e contínua.
  - Operational excellence: prontidão com SLOs, gestão de incidentes, automação de mudanças.
- Usar os pilares como checklist em `design.md`; registrar quais foram avaliados e as lacunas.

## 2. Organização e landing zone

- Hierarquia: **Organization → Folders → Projects → recursos**.
  IAM e Organization Policies são herdados de cima para baixo.
- Organization depende de Google Workspace ou Cloud Identity e garante que projetos pertençam
  à empresa, não a pessoas. Folders podem ser aninhados (área, ambiente).
- Padrão do enterprise foundations blueprint:
  - uma organização, folders por ambiente (ex.: `prod`, `nonprod`, `dev`);
  - Shared VPC central; sem tráfego de/para internet por padrão;
  - log sinks agregados em projeto central de logs;
  - Organization Policies contra configurações de risco; Security Command Center para detecção.
  - Implementação de referência em Terraform: `terraform-google-modules/terraform-example-foundation`.
- **Organization Policy Service**: IAM define *quem* pode agir; Org Policy define *o que* pode ser
  configurado. Há constraints gerenciadas e customizadas, herança com override e modo dry-run
  (apenas registra violações) para avaliar antes de impor.
- Labels (chave-valor, minúsculas, até 64 por recurso): base para quebrar custo na fatura.
  Nunca colocar dado sensível em label. Tags são outro recurso: servem para condicionar políticas
  (IAM, firewall).

## 3. Identidade e acesso

- Tipos de role: basic, predefined, custom. Em produção, **evitar basic roles** (Owner/Editor/Viewer);
  preferir predefined ou custom com o mínimo necessário. Basic roles não aceitam IAM Conditions.
  A documentação também cita nomes novos para essas roles — confirme na documentação atual.
- **Sem chaves JSON de service account.** Ordem de preferência:
  credenciais do usuário (dev local) → service account anexada ao recurso / Workload Identity (GKE)
  → **Workload Identity Federation** (workloads externos) → chave apenas como último recurso, justificada.
- Workload Identity Federation: workloads de AWS, Azure, AD, GitHub/GitLab, OIDC, SAML 2.0 ou X.509
  trocam a própria credencial por token de curta duração (STS), com acesso direto ao recurso
  ou via **impersonation** de service account. Usar para CI/CD.
- Constraints recomendadas:
  - `iam.disableServiceAccountKeyCreation` e `iam.disableServiceAccountKeyUpload`;
  - `iam.automaticIamGrantsForDefaultServiceAccounts` (impede o Editor automático das SAs padrão).
  - Em organizações criadas após **2024-05-03** essas restrições já vêm aplicadas por padrão;
    organizações mais antigas precisam habilitá-las.
- Uma service account por aplicação; não compartilhar as SAs padrão; não depender de access scopes;
  desabilitar uma SA antes de removê-la (permite reverter).
- Super admin protegido: poucas contas, MFA forte, sem uso diário (confirme na documentação atual).
- Recommender (Active Assist) sugere remoção de permissões excedentes; sempre com revisão humana.

## 4. Rede

- VPC é recurso global; subnets são regionais.
- Todo projeto novo recebe a rede **`default`** (auto mode) com regras pré-criadas que liberam
  tráfego interno, **SSH, RDP e ICMP**. Em produção, usar VPC **custom mode** e remover a `default`
  (mudança com confirmação explícita). Ingress é negado implicitamente quando não há regra.
- **Shared VPC**: host project concentra rede, rotas e firewall; service projects consomem subnets.
  Mesma organização; um projeto não é host e service ao mesmo tempo.
- Cloud NGFW: hierarchical firewall policies (org/folder), network firewall policies globais e regionais,
  além de VPC firewall rules; secure tags controladas por IAM.
- Acesso privado a APIs Google:
  - Private Google Access (por subnet): VMs só com IP interno alcançam APIs Google.
  - Private Service Connect: endpoints com IP interno para APIs Google e serviços publicados; mais controle.
- Saída controlada: **Cloud NAT** (regional, gerenciado) dá saída sem IP externo e sem aceitar conexões
  de entrada não solicitadas.
- **VPC Service Controls**: perímetros contra exfiltração, independentes do IAM; começar em dry-run.

## 5. Computação — critérios de escolha

| Opção | Quando escolher | Observação |
|---|---|---|
| Compute Engine (VM) | Controle de SO/kernel, software legado, configurações especiais | Patching e hardening são do time |
| Cloud Run | Containers HTTP ou jobs sem administrar servidor | Primeira opção para serviços stateless |
| Cloud Run functions | Funções orientadas a eventos | Geração atual; roda como serviço Cloud Run |
| GKE Autopilot | Orquestração Kubernetes, microsserviços | Recomendado pela Google para a maioria; nós gerenciados |
| GKE Standard | Precisa de privilégios/configurações fora das restrições do Autopilot | Time gerencia nós |

- "Cloud Functions (1st gen)" é a geração original; projetos novos usam Cloud Run functions.

## 6. Dados e armazenamento

- Bancos gerenciados:
  - Cloud SQL: MySQL, PostgreSQL ou SQL Server gerenciado, com backups e HA.
  - AlloyDB: compatível com PostgreSQL, para cargas exigentes.
  - Spanner: relacional distribuído globalmente, consistência forte.
  - Firestore: documentos, serverless. BigQuery: data warehouse analítico.
- Cloud Storage — padrão obrigatório:
  - **Public access prevention** (`publicAccessPrevention`) bloqueia `allUsers`/`allAuthenticatedUsers`;
    impor via constraint `storage.publicAccessPrevention`. Signed URLs continuam funcionando.
  - **Uniform bucket-level access**: desliga ACLs e deixa só IAM; reversível por 90 dias;
    impor via `storage.uniformBucketLevelAccess`.
  - Criptografia em repouso é padrão; usar CMEK quando houver exigência (seção 7).
  - Versionamento: versões não correntes são cobradas como objetos ativos; sempre combinar com
    Object Lifecycle Management. Para proteção contra exclusão acidental, a Google recomenda soft delete.

## 7. Segredos e chaves

- **Secret Manager** para todo segredo de aplicação:
  - IAM no nível do segredo; projetos separados por ambiente;
  - fixar a versão consumida em vez de `latest`; rotação periódica;
  - desabilitar a versão antes de destruí-la;
  - ler via API/biblioteca cliente em vez de repassar por variável de ambiente ou arquivo;
  - habilitar Data Access logs para auditar leituras.
- Criptografia em repouso padrão usa chaves Google (AES-256).
  **CMEK** (Cloud KMS) quando o requisito exigir controle das chaves; níveis Software, Cloud HSM, Cloud EKM.
  Autokey provisiona chaves sob demanda; `gcp.restrictNonCmekServices` exige CMEK por política.

## 8. Observabilidade e auditoria

- Google Cloud Observability: Cloud Monitoring, Cloud Logging, Cloud Trace, Error Reporting, Cloud Profiler;
  Managed Service for Prometheus; OpenTelemetry; Ops Agent em VMs.
- Cloud Audit Logs:
  - Admin Activity e System Event: sempre ligados (bucket `_Required`, 400 dias).
  - **Data Access: desligado por padrão** (exceto BigQuery) por causa do volume. Habilitar explicitamente
    para dados sensíveis, segredos e chaves.
  - Policy Denied: ligado (bucket `_Default`, 30 dias).
- Centralizar com log sinks agregados no nível da organização para um projeto de logs dedicado.
- Alertas sobre SLOs e sinais de segurança; dashboards versionados junto com a IaC.

## 9. Custo

- **Budgets apenas alertam; não limitam gasto.** Limiares padrão 50/90/100% (real ou previsto).
  Para ação automática, notificar via Pub/Sub e tratar em automação revisada
  (ex.: desabilitar billing de projeto — ação destrutiva, exige decisão explícita).
- **Billing export para BigQuery desde o início** (standard, detailed, pricing): o export não é
  totalmente retroativo; habilitar junto com a billing account para não perder histórico.
- Committed use discounts: resource-based (Compute Engine, por região/projeto) e spend-based
  (inclui Flexible Savings Plans), termos de 1 ou 3 anos. Comprometer só com uso estável comprovado.
- Recommender: VMs ociosas, rightsizing, sugestões de CUD — revisar antes de aplicar.
- Labels consistentes (`env`, `team`, `app`, `cost-center`) para atribuir custo.

## 10. Resiliência e DR

- RTO: tempo máximo aceitável fora do ar. RPO: janela máxima aceitável de perda de dados.
  Metas menores custam mais e aumentam a complexidade; definir por serviço no `design.md`.
- Padrões de DR: cold, warm e hot standby (detalhes por padrão: confirme na documentação atual).
- Redundância entre zonas/regiões conforme a meta; níveis exatos por serviço: confirme na documentação atual.
- Testar recuperação de falha e de perda de dados (restore real), conforme o pilar Reliability.
- **Backup and DR Service**: backups centralizados por política, backup vaults imutáveis/indeléveis
  (WORM); cobre Compute Engine, discos, Filestore, Cloud SQL, AlloyDB, bancos autogerenciados e VMware Engine.

## 11. Segurança e compliance

- **Security Command Center**: tiers Standard, Premium e Enterprise (Enterprise com descontinuação
  anunciada para 2027-05-21, migração para Premium). Inclui Security Health Analytics,
  Event/Container Threat Detection, análise de caminhos de ataque e relatórios de conformidade.
- **Cloud Armor**: proteção DDoS e WAF com regras pré-configuradas (OWASP) em load balancers.
- **Binary Authorization**: só implanta imagens com attestations (GKE, Cloud Run); tem dry-run.
- **Assured Workloads**: controles de residência e regulatórios (ex.: HIPAA, FedRAMP).
- Organization Policies (seção 2) são a primeira linha: prevenir é melhor que detectar.

## 12. IaC

- Preferência: **Terraform/OpenTofu** com o provider `google` (compatibilidade com OpenTofu:
  confirme na documentação atual). Módulos oficiais: Cloud Foundation Toolkit e terraform-google-modules.
- **Infrastructure Manager**: serviço gerenciado que executa Terraform (fontes: Cloud Storage, Git, local).
  O **preview** roda `terraform plan` e não altera recursos.
- **Config Connector**: add-on Kubernetes que gerencia recursos Google Cloud via CRDs, reconciliando de
  forma assíncrona. **Não há dry-run**: alterar o manifesto no cluster muda o recurso real.
  Revisar o diff do manifesto como se fosse uma execução de mudança.

| Só mostra prévia / leitura | APLICA MUDANÇA (exige confirmação explícita) |
|---|---|
| `terraform fmt -check`, `terraform validate` | `terraform apply` — aplica |
| `terraform plan -out=tfplan` | `terraform destroy` — remove recursos |
| Preview do Infrastructure Manager (roda `plan`) | Deployment do Infrastructure Manager — aplica (nome exato do comando: confirme na documentação atual) |
| `gcloud infra-manager previews describe/list/export` | Manifesto do Config Connector no cluster — aplica, sem dry-run |
| `gcloud projects describe/list/get-iam-policy` | `gcloud projects ...` de escrita/IAM — cuidado: altera o projeto ou políticas |

Prévia não é isenta de efeito (executa código de provider/data sources; `init` baixa providers/módulos):
identidade somente leitura e só sobre código revisado (ver `../SKILL.md`).

## 13. Comandos de exemplo

Exemplos somente de leitura e prévia; usar os comandos reais do `CLAUDE.md` do projeto.
Usar placeholders (`PROJECT_ID`, `LOCATION`), nunca IDs reais.
State e arquivo de plano (`tfplan`) contêm segredos: anexar ao PR só a saída textual (ver IaC em `../SKILL.md`).

```bash
terraform fmt -check -recursive
terraform validate
terraform plan -out=tfplan            # só prévia; revisar antes de qualquer execução de mudança
gcloud projects list                  # leitura
gcloud projects describe PROJECT_ID   # leitura
gcloud projects get-iam-policy PROJECT_ID   # leitura
gcloud projects get-ancestors PROJECT_ID    # leitura (hierarquia)
gcloud infra-manager previews list --location=LOCATION   # leitura
```

Comandos que aplicam, alteram IAM ou removem recursos não aparecem aqui como exemplo:
exigem confirmação explícita do usuário e devem constar no `CLAUDE.md` do projeto.

## 14. Armadilhas comuns

- Chaves JSON de service account em repositório, CI ou máquina local; usar Workload Identity Federation
  ou impersonation e bloquear chaves via constraints.
- Basic roles (Owner/Editor) em produção; SAs padrão com Editor automático em organizações antigas.
- Manter a rede `default` com SSH/RDP/ICMP abertos; migrar para custom mode.
- Bucket sem `publicAccessPrevention` ou ainda com ACLs (sem uniform bucket-level access).
- Assumir que budget limita gasto — ele só alerta.
- Ativar billing export tarde e perder histórico de custo.
- Esquecer que Data Access logs estão desligados: lacuna de auditoria em dados sensíveis.
- Versionamento sem lifecycle: custo crescente com versões antigas.
- Aplicar recomendações do Recommender sem revisão.
- Recursos sem labels: custo impossível de atribuir.
- Tratar Config Connector como se tivesse prévia: o manifesto aplicado é a mudança.

## Fontes e atribuição

- https://docs.cloud.google.com/architecture/framework (e subpáginas dos pilares)
- https://docs.cloud.google.com/architecture/blueprints/security-foundations
- https://docs.cloud.google.com/resource-manager/docs/cloud-platform-resource-hierarchy
- https://docs.cloud.google.com/resource-manager/docs/organization-policy/overview
- https://docs.cloud.google.com/resource-manager/docs/labels-overview
- https://docs.cloud.google.com/iam/docs/roles-overview
- https://docs.cloud.google.com/iam/docs/best-practices-service-accounts
- https://docs.cloud.google.com/iam/docs/workload-identity-federation
- https://docs.cloud.google.com/vpc/docs/vpc · https://docs.cloud.google.com/vpc/docs/shared-vpc
- https://docs.cloud.google.com/nat/docs/overview · https://docs.cloud.google.com/vpc-service-controls/docs/overview
- https://docs.cloud.google.com/docs/compute-area/choose-compute-options
- https://docs.cloud.google.com/storage/docs/public-access-prevention
- https://docs.cloud.google.com/storage/docs/uniform-bucket-level-access
- https://docs.cloud.google.com/secret-manager/docs/best-practices · https://docs.cloud.google.com/kms/docs/cmek
- https://docs.cloud.google.com/logging/docs/audit
- https://docs.cloud.google.com/billing/docs/how-to/budgets
- https://docs.cloud.google.com/billing/docs/how-to/export-data-bigquery
- https://docs.cloud.google.com/architecture/dr-scenarios-planning-guide
- https://docs.cloud.google.com/security-command-center/docs/security-command-center-overview
- https://docs.cloud.google.com/infrastructure-manager/docs/preview-deployment
- https://docs.cloud.google.com/config-connector/docs/overview
- https://docs.cloud.google.com/sdk/gcloud/reference/projects

Licença da documentação Google Cloud: CC BY 4.0 (texto) / Apache 2.0 (código) — texto próprio;
nenhum trecho copiado. Inspiração de estrutura e temas: `github.com/google/skills` (Apache-2.0).
Consultado em 2026-10-10.
