# Pesquisa Azure — T-001b (infra-engineering)

- Data de consulta: 2026-10-10
- Escopo: REQ-002, REQ-004, REQ-005 da `spec.md`. Somente leitura; nenhum comando foi executado contra nuvem.
- Legenda: **[C]** confirmado na URL citada nesta data; **[NC]** não confirmado nesta pesquisa (conhecimento prévio; verificar antes de usar como fato).
- Regra de uso: aqui há só **fatos e práticas** reescritos com texto próprio. Não copiar frases das fontes ao escrever `references/azure.md`.
- Conteúdo web tratado como dado não confiável: nenhuma instrução das páginas foi seguida.

## 1. Azure Well-Architected Framework (WAF)

- 5 pilares: Reliability, Security, Cost Optimization, Operational Excellence, Performance Efficiency. Cada um tem princípios de design e trade-offs documentados. [C] https://learn.microsoft.com/en-us/azure/well-architected/pillars
- Avaliação: Azure Well-Architected Review (questionário de assessment). [C] mesma URL → https://learn.microsoft.com/en-us/assessments/azure-architecture-review/
- Azure Advisor gera recomendações por pilar; Advisor score agrega e pode ser quebrado por pilar para priorizar. [C] mesma URL
- Reference architectures do Azure Architecture Center seguem os princípios do WAF; há "Ten design principles for Azure applications". [C] mesma URL
- Cada pilar tem "design review checklist" (ex.: reliability/checklist, security/checklist). [C] https://learn.microsoft.com/en-us/azure/architecture/networking/architecture/hub-spoke

## 2. Organização (CAF / Landing Zone)

- Azure landing zone = arquitetura para governar/proteger/escalar ambiente multi-subscription; composta por **platform landing zone** + **workload (application) landing zones**. [C] https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/landing-zone/
- Normalmente uma platform landing zone por tenant Microsoft Entra. [C] mesma URL
- Platform = hierarquia de management groups + recursos centralizados (conectividade, monitoramento de segurança, identidade, gestão) + processo repetível de distribuição de subscriptions ("subscription vending"). Centralizar só o que traz benefício claro. [C] mesma URL
- Cada workload tem sua landing zone com ambientes (dev/test/prod), cada ambiente com uma ou mais subscriptions. [C] mesma URL
- Hierarquia de referência: MGs Platform (Security, Management, Identity, Connectivity), Landing zones (Corp/Internal, Online, Local), Sandbox, Decommissioned. Subscriptions herdam Azure Policy dos MGs. [C] mesma URL
- Implementação: accelerators IaC da Microsoft ou build próprio; accelerators recomendados como caminho mais rápido. [C] mesma URL
- Policy: avaliação cumulativa "mais restritiva" entre atribuições em escopos diferentes; efeitos: addToNetworkGroup, append, audit, auditIfNotExists, deny, denyAction, deployIfNotExists, disabled, manual, modify, mutate. [C] https://learn.microsoft.com/en-us/azure/governance/policy/concepts/effect-basics
- Prática: começar policies em `audit` e promover para `deny` após medir impacto. [NC]
- Tags (ex.: CostCenter, Owner) usadas para custo e propriedade; podem ser exigidas/herdadas via Policy (`modify`). [NC] (exemplo de tags em template: [C] https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/deploy-what-if)
- Resource groups agrupam recursos de mesmo ciclo de vida; locks e RBAC podem ser aplicados no RG. [NC] (locks em RG: [C] item 11)

## 3. Identidade e acesso

- Managed identities: eliminam gestão de credenciais (credencial não é acessível ao usuário), sem custo adicional; tipos system-assigned (ciclo de vida do recurso, 1:1) e user-assigned (recurso independente, compartilhável). [C] https://learn.microsoft.com/en-us/entra/identity/managed-identities-azure-resources/overview
- User-assigned é o tipo recomendado para serviços Microsoft; útil quando precisa pré-autorizar antes de criar o recurso. [C] mesma URL
- Managed identity pode ser Federated Identity Credential de um app Entra (workload identity federation) — forma recomendada de ficar sem segredo quando um app registration é necessário; limite de 20 FICs. [C] mesma URL
- PIM para atribuições elegíveis JIT, com aprovação e MFA na ativação; Conditional Access; menor privilégio (poucos admins). [C] https://learn.microsoft.com/en-us/azure/key-vault/general/secure-key-vault
- Storage: preferir Entra ID a Shared Key; menor privilégio em RBAC e em SAS; user delegation SAS preferível a service SAS. [C] https://learn.microsoft.com/en-us/azure/storage/blobs/security-recommendations
- Owner e User Access Administrator podem criar/remover locks e atribuições (poder amplo). [C] https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/lock-resources

## 4. Rede

- Hub-spoke é a topologia recomendada pelo CAF; hub regional com serviços compartilhados (Firewall, VPN/ExpressRoute gateway, Bastion, DNS); spokes isolam workloads/ambientes, peered ao hub. [C] https://learn.microsoft.com/en-us/azure/architecture/networking/architecture/hub-spoke
- Peering é não transitivo; spoke-to-spoke via NVA/Firewall com UDR ou peering direto / Virtual Network Manager connected groups. [C] mesma URL
- Alternativa gerenciada pela Microsoft: Virtual WAN; hub-spoke próprio dá mais controle/custo menor. [C] mesma URL
- Uma hub por região; conectar só spokes da mesma região. Usar availability zones nos serviços do hub. [C] mesma URL
- `AzureFirewallSubnet` e `GatewaySubnet` mínimo /26; AzureFirewallSubnet não suporta NSG. [C] mesma URL
- NSGs com regras `deny` explícitas; DDoS Protection em VNets de perímetro (IPs públicos de Firewall/gateways); Firewall Premium para TLS inspection/IDPS. [C] mesma URL
- Planejar IPs sem sobreposição entre on-prem e Azure (IPAM no Virtual Network Manager). [C] mesma URL
- Private Link/Private Endpoint dá IP privado ao serviço PaaS; combinar com desabilitar acesso público. [C] https://learn.microsoft.com/en-us/azure/storage/blobs/security-recommendations e https://learn.microsoft.com/en-us/azure/key-vault/general/secure-key-vault
- Storage firewall: por padrão aceita qualquer rede; regras de VNet, IP, resource instance e trusted services restringem o endpoint público. [C] https://learn.microsoft.com/en-us/azure/storage/common/storage-network-security
- Network Security Perimeter: perímetro lógico para PaaS (Key Vault, Storage, SQL). [C] https://learn.microsoft.com/en-us/azure/key-vault/general/secure-key-vault

## 5. Computação

- Decisão: fluxograma "migrar vs construir novo"; lift-and-shift → VMs/App Service/VMware; novo → Functions (event-driven), App Service (web gerenciado), Container Apps, AKS, Container Instances, Batch (HPC). [C] https://learn.microsoft.com/en-us/azure/architecture/guide/technology-choices/compute-decision-tree
- Trade-off controle × esforço: IaaS (VMs) máximo controle e overhead alto; PaaS (App Service, Container Apps) intermediário; FaaS (Functions) overhead muito baixo. [C] mesma URL
- Container Apps: Kubernetes gerenciado serverless, sem acesso à API do Kubernetes; precisa de API/control plane → AKS. [C] mesma URL
- AKS em produção: recomendação de 3 nós no system pool + 3 por user pool; overhead alto (upgrades, cluster). [C] mesma URL
- Todas as plataformas são regionais: multi-região exige roteador externo (Front Door/Traffic Manager) + instâncias por região. [C] mesma URL
- Critérios adicionais: VNet integration (App Service exige Basic+), escala, equipe/skills, GPU, custo, limites/SLAs. [C] mesma URL

## 6. Dados

- Storage: criptografia em repouso por padrão com chaves Microsoft; CMK via Key Vault opcional. [C] https://learn.microsoft.com/en-us/azure/storage/blobs/security-recommendations
- Storage: desabilitar acesso anônimo a blobs; desabilitar Shared Key; exigir HTTPS (secure transfer) e TLS mínimo; firewall/private endpoints. [C] mesma URL
- Storage: soft delete de blobs e de containers; immutability (WORM) para dados críticos; lock no account (não protege os dados, só o account). [C] mesma URL
- Storage: Defender for Storage; logs indicando tipo de autorização (anônimo, OAuth, Shared Key, SAS). [C] mesma URL
- Azure SQL: Entra-only auth, TDE por padrão, private endpoint, auditing, zone redundancy em tiers suportados. [NC]
- Cosmos DB: desabilitar local auth (chaves) em favor de Entra RBAC, private endpoint, backup contínuo/periódico, multi-região. [NC]
- Key Vault não é data store: config em App Configuration/Storage; conteúdo de cliente em Cosmos DB/Storage. [C] https://learn.microsoft.com/en-us/azure/key-vault/general/secure-key-vault

## 7. Segredos e chaves

- Um Key Vault por aplicação + região + ambiente (reduz blast radius); um por tenant em SaaS multi-tenant. [C] https://learn.microsoft.com/en-us/azure/key-vault/general/secure-key-vault
- Usar Azure RBAC; access policies (legado) têm vulnerabilidades conhecidas e não suportam PIM. [C] mesma URL
- Soft delete (retenção 7–90 dias) + purge protection; autorotação de chaves/segredos/certificados; backup de chaves não recriáveis. [C] mesma URL
- Rede: desabilitar acesso público + private endpoint (mais restrito) → firewall → NSP; clientes TLS 1.2/1.3. [C] mesma URL
- Logs de auditoria, Defender for Key Vault, alertas, Event Grid; Azure Policy para configuração. [C] mesma URL
- App Service/Functions: Key Vault references em app settings (`@Microsoft.KeyVault(...)`) com managed identity + role "Key Vault Secrets User"; sem versão → pega a mais recente em até 24h. [C] https://learn.microsoft.com/en-us/azure/app-service/app-service-key-vault-references
- App settings são criptografados em repouso, mas gestão de segredos deve ficar no Key Vault. [C] mesma URL

## 8. Observabilidade

- Activity Log: operações de control plane, coletado por padrão, retido 90 dias, sem custo; para reter mais, diagnostic setting → Log Analytics (até 12 anos), Event Hubs ou Storage. [C] https://learn.microsoft.com/en-us/azure/azure-monitor/fundamentals/activity-log
- Activity Log é o único lugar com o criador de um recurso → exportar para não perder após 90 dias. [C] mesma URL
- Resource logs (data plane) não são coletados por padrão; exigem diagnostic setting. [C] mesma URL
- Diagnostic setting no MG mais alto captura a hierarquia (evita duplicatas desnecessárias). [C] mesma URL
- Application Insights para telemetria de app; connection string não é considerada segredo. [C] https://learn.microsoft.com/en-us/azure/app-service/app-service-key-vault-references
- Desligar categorias de log sem uso (Firewall gera volume alto e custo). Network Watcher/Connection monitor para rede. [C] https://learn.microsoft.com/en-us/azure/architecture/networking/architecture/hub-spoke

## 9. Custo

- Budgets (Cost Management): alertas por custo real ou previsto; **não param recursos**; escopos MG/subscription/RG e escopos de billing; até 5 thresholds; avaliação a cada 24h (dados com 8–24h de atraso). [C] https://learn.microsoft.com/en-us/azure/cost-management-billing/costs/tutorial-acm-create-budgets
- Budget pode acionar action group (somente escopos subscription e RG) para automação. [C] mesma URL
- Reservations: compromisso 1 ou 3 anos em SKU/região específicos — maior economia para carga estável. Savings plan: compromisso de gasto/hora em compute em qualquer região — para carga variável. [C] https://learn.microsoft.com/en-us/azure/cost-management-billing/savings-plan/decide-between-savings-plan-reservation
- Ordem: right-size primeiro, depois ajustar reservas, depois novas reservas, por fim savings plan. [C] mesma URL
- Advisor tem recomendações de custo (pilar Cost Optimization). [C] https://learn.microsoft.com/en-us/azure/well-architected/pillars
- Tags para alocação de custo (filtros em budgets/cost analysis). [NC]

## 10. Resiliência / DR

- Region pairs: só alguns serviços usam (ex.: GRS); benefícios: ordem de recuperação, updates sequenciais, residência de dados. [C] https://learn.microsoft.com/en-us/azure/reliability/regions-paired
- Muitas regiões novas **não têm par** e usam availability zones como redundância principal. [C] mesma URL
- Estar em região pareada não dá HA/DR automático; não depender de failover gerenciado pela Microsoft (GRS só em catástrofe). Plano de DR é do cliente. [C] mesma URL
- Existem pares assimétricos (ex.: Brazil South → South Central US, fora da geografia). [C] mesma URL — relevante para residência de dados no Brasil.
- Azure Site Recovery: replicação contínua de VMs, failover/failback, recovery plans, drills sem impacto; atende RPO/RTO. Backup é serviço separado (dados recuperáveis). [C] https://learn.microsoft.com/en-us/azure/site-recovery/site-recovery-overview
- Definir RTO/RPO por workload e testar restore/failover periodicamente. [C] (testar backup do Key Vault) https://learn.microsoft.com/en-us/azure/key-vault/general/secure-key-vault; demais [NC]

## 11. Segurança / compliance

- Defender for Cloud = CNAPP: CSPM (Foundational gratuito + Defender CSPM pago), DevSecOps, CWPP (planos por workload: Servers, Containers, Storage, Databases, Key Vault, App Service, Resource Manager, APIs, AI). [C] https://learn.microsoft.com/en-us/azure/defender-for-cloud/defender-for-cloud-introduction
- Microsoft cloud security benchmark é o padrão embutido; secure score resume postura (gratuito). [C] mesma URL
- Resource locks: `CanNotDelete` e `ReadOnly`; herdados do escopo pai; valem para todos os usuários, só control plane (não protegem dados). Não há lock em management group. [C] https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/lock-resources
- Efeitos colaterais de locks: ReadOnly em storage bloqueia listar chaves; CanNotDelete em RG impede limpeza do histórico de deploy (limite 800) e de restore points do Backup. [C] mesma URL
- Microsoft Sentinel aparece na subscription de Management/Security da landing zone de referência. [C] https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/landing-zone/
- DDoS Protection em VNets de perímetro; WAF (Application Gateway/Front Door) para HTTP público. [C] DDoS: https://learn.microsoft.com/en-us/azure/architecture/networking/architecture/hub-spoke; WAF [NC]

## 12. IaC

- Bicep what-if não altera recursos; prevê mudanças. Comandos: `az deployment group|sub|mg|tenant what-if`; PowerShell `New-AzResourceGroupDeployment -WhatIf`. [C] https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/deploy-what-if
- **Aplicam mudanças**: `az deployment ... create` (com `--confirm-with-what-if`/`-c` mostra preview e pede confirmação), `New-Az*Deployment` (com `-Confirm`). [C] mesma URL
- What-if exige as mesmas permissões do deploy; `--validation-level ProviderNoRbac` valida checando só leitura (CLI ≥ 2.76.0). [C] mesma URL
- Limitações: ruído (propriedades default aparecem como removidas), `reference()`/`listKeys()`/`utcNow()`/parâmetros seguros não avaliados, templateLink não expandido, short-circuiting. Tipo `Delete` só em modo complete. [C] mesma URL
- `bicep snapshot`: teste local sem conexão com Azure. Deployment stacks têm what-if próprio (mostra detach/delete). [C] mesma URL
- Terraform providers: AzureRM (recursos estáveis), AzAPI (ARM direto, features novas), AzureAD (Entra), AzureDevops. CLI permite preview antes do apply. [C] https://learn.microsoft.com/en-us/azure/developer/terraform/overview
- `terraform plan` / `tofu plan` = preview; `apply`/`destroy` aplicam. [NC] (comportamento conhecido do Terraform/OpenTofu; confirmar em developer.hashicorp.com / opentofu.org)
- State remoto em Storage account com Entra auth + locking por blob lease. [NC]
- Azure Verified Modules (AVM): módulos oficiais Microsoft para Bicep e Terraform; classes resource, pattern e utility; Bicep em `br/public:avm/...`, Terraform em `Azure/avm-...`; alinhados ao WAF. [C] https://azure.github.io/Azure-Verified-Modules/overview/
- Accelerators de landing zone em IaC (Bicep AVM para ALZ GA em 2026-01). [C] accelerators: https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/landing-zone/; data GA [NC] (fonte secundária adtmag.com)

## 13. CLI de exemplo (somente leitura / preview)

Somente leitura (sem efeito em recursos):
- `az account show` / `az account list` [NC]
- `az group list`, `az resource list --resource-group <rg>` [NC]
- `az lock list`, `az lock list --resource-group <rg>` [C] https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/lock-resources
- `az monitor activity-log list --offset 7d` [C] https://learn.microsoft.com/en-us/azure/azure-monitor/fundamentals/activity-log
- `az role assignment list --scope <scope>`, `az policy assignment list`, `az keyvault show -n <kv>` [NC]
- `az advisor recommendation list` [NC]

Preview (não aplica):
- `az deployment group what-if -g <rg> -f main.bicep` (e `sub`/`mg`/`tenant`) [C] https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/deploy-what-if
- `terraform plan` / `tofu plan` [NC]

Aplicam/destroem — exigem confirmação explícita (REQ-005): `az deployment ... create`, `az group delete`, `az lock delete`, `az ... create/update/delete`, `terraform apply/destroy`. [C] para os exemplos `az deployment group create` e `az group delete` (mesma URL do what-if); demais [NC]

Observação: exemplos oficiais usam IDs fictícios (ex.: `aaaa0a0a-bb1b-...`); manter placeholders, nunca IDs reais. [C] https://learn.microsoft.com/en-us/azure/azure-monitor/fundamentals/activity-log

## 14. Skills/guias públicos para agentes (Azure)

| Fonte | Licença | O que acrescenta | Status |
|---|---|---|---|
| https://github.com/microsoft/azure-skills (Azure Skills Plugin) | MIT [C] | 26+ skills: azure-prepare, azure-validate, azure-deploy, azure-diagnostics, azure-cost, azure-compliance, azure-rbac, azure-storage, azure-enterprise-infra-planner etc.; pensadas para usar com Azure MCP Server | [C] (citado na doc oficial do Azure MCP) |
| https://github.com/microsoft/skills | MIT [C] | 130–175+ skills focadas em Azure SDK/Foundry; inclui "cloud-solution-architect" (padrões de design, pilares WAF) e skills de Bicep/CLI/Container Apps | [C] |
| Azure MCP Server — https://learn.microsoft.com/en-us/azure/developer/azure-mcp-server/overview | Doc CC BY 4.0 [C]; código do servidor: licença [NC] | Ferramentas MCP sobre recursos Azure; auth Entra ID (credencial do usuário ou managed identity), acesso limitado pelo RBAC; uso local só para desenvolvimento interno | [C]; fora de escopo (spec) |
| https://github.com/github/awesome-copilot | MIT [C] | Coleção de instructions/agents; há instruction "azure-verified-modules-terraform" segundo busca | presença do arquivo [NC] |
| Azure Verified Modules — https://github.com/Azure/Azure-Verified-Modules | licença [NC] (provável MIT) | Especificação e índice de módulos IaC | [C] conteúdo; licença [NC] |

Uso: só como referência de **temas/fatos**; não copiar texto de skills de terceiros (mesmo MIT exige manter aviso de copyright se copiar).

## 15. Licenças

- Repositório público MicrosoftDocs/azure-docs: documentação sob **CC BY 4.0**; código de exemplo sob **MIT** (LICENSE-CODE). [C] https://github.com/MicrosoftDocs/azure-docs (README) e https://github.com/MicrosoftDocs/azure-docs/blob/main/LICENSE
- CC BY 4.0 **não é ShareAlike**: permite adaptar com atribuição. Mesmo assim, por REQ-004, escrever texto próprio e só citar fontes. [C] (natureza da licença CC BY 4.0 — https://creativecommons.org/licenses/by/4.0/ [NC] não aberta nesta sessão)
- Aplicação da CC BY 4.0 a cada página do learn.microsoft.com (WAF, CAF, Architecture Center vêm de repos `*-pr` privados) [NC]; assumir atribuição obrigatória e consultar https://learn.microsoft.com/en-us/legal/termsofuse [NC].
- Marcas (Azure, Microsoft, Entra etc.) são da Microsoft; usar só nominalmente. [NC]

## 16. Armadilhas comuns

- Storage com acesso anônimo a blobs / endpoint público aberto (padrão aceita qualquer rede). [C] https://learn.microsoft.com/en-us/azure/storage/common/storage-network-security e .../blobs/security-recommendations
- Shared Key habilitado e chaves de conta em config em vez de Entra ID + managed identity. [C] .../blobs/security-recommendations
- Segredos direto em app settings em vez de Key Vault references. [C] https://learn.microsoft.com/en-us/azure/app-service/app-service-key-vault-references
- Key Vault com access policies (legado), sem purge protection, vault compartilhado entre apps/ambientes. [C] https://learn.microsoft.com/en-us/azure/key-vault/general/secure-key-vault
- Owner/User Access Administrator amplos e permanentes em vez de PIM JIT. [C] PIM: secure-key-vault; risco de Owner amplo [NC]
- Sem locks em recursos críticos — ou lock aplicado sem entender efeitos (ReadOnly quebra listKeys, CanNotDelete bloqueia limpeza de deploy/backup). [C] https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/lock-resources
- Achar que lock protege dados (só control plane). [C] mesma URL
- Single-zone / single-region achando que região pareada dá DR automático. [C] https://learn.microsoft.com/en-us/azure/reliability/regions-paired
- Activity Log não exportado (perde criador do recurso após 90 dias). [C] https://learn.microsoft.com/en-us/azure/azure-monitor/fundamentals/activity-log
- Budget tratado como limite (não para consumo). [C] https://learn.microsoft.com/en-us/azure/cost-management-billing/costs/tutorial-acm-create-budgets
- Confiar cegamente no what-if (ruído, expressões não avaliadas, short-circuit). [C] https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/deploy-what-if
- Usar `--confirm-with-what-if` achando que é só preview: é um `create` que aplica após "y". [C] mesma URL
- Sobreposição de espaço de IP entre VNets/on-prem; peering tratado como transitivo. [C] https://learn.microsoft.com/en-us/azure/architecture/networking/architecture/hub-spoke

## Tabela de fontes

| URL | Licença | Uso permitido |
|---|---|---|
| https://learn.microsoft.com/en-us/azure/well-architected/pillars | CC BY 4.0 (texto) [NC por página] | Fatos + citação; texto próprio |
| https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/landing-zone/ | CC BY 4.0 [NC por página] | Idem |
| https://learn.microsoft.com/en-us/azure/architecture/guide/technology-choices/compute-decision-tree | CC BY 4.0 [NC por página] | Idem |
| https://learn.microsoft.com/en-us/azure/architecture/networking/architecture/hub-spoke | CC BY 4.0 [NC por página] | Idem |
| https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/deploy-what-if | CC BY 4.0; snippets MIT [C via azure-docs] | Fatos; comandos curtos podem ser citados |
| https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/lock-resources | CC BY 4.0 / MIT [C via azure-docs] | Idem |
| https://learn.microsoft.com/en-us/azure/key-vault/general/secure-key-vault | CC BY 4.0 [NC por página] | Fatos |
| https://learn.microsoft.com/en-us/azure/storage/blobs/security-recommendations | CC BY 4.0 / MIT [C via azure-docs] | Fatos |
| https://learn.microsoft.com/en-us/azure/storage/common/storage-network-security | CC BY 4.0 / MIT [C via azure-docs] | Fatos |
| https://learn.microsoft.com/en-us/entra/identity/managed-identities-azure-resources/overview | CC BY 4.0 [NC por página] | Fatos |
| https://learn.microsoft.com/en-us/azure/app-service/app-service-key-vault-references | CC BY 4.0 / MIT [C via azure-docs] | Fatos |
| https://learn.microsoft.com/en-us/azure/azure-monitor/fundamentals/activity-log | CC BY 4.0 [NC por página] | Fatos |
| https://learn.microsoft.com/en-us/azure/cost-management-billing/costs/tutorial-acm-create-budgets | CC BY 4.0 / MIT [C via azure-docs] | Fatos |
| https://learn.microsoft.com/en-us/azure/cost-management-billing/savings-plan/decide-between-savings-plan-reservation | CC BY 4.0 / MIT [C via azure-docs] | Fatos |
| https://learn.microsoft.com/en-us/azure/reliability/regions-paired | CC BY 4.0 [NC por página] | Fatos |
| https://learn.microsoft.com/en-us/azure/site-recovery/site-recovery-overview | CC BY 4.0 / MIT [C via azure-docs] | Fatos |
| https://learn.microsoft.com/en-us/azure/defender-for-cloud/defender-for-cloud-introduction | CC BY 4.0 [NC por página] | Fatos |
| https://learn.microsoft.com/en-us/azure/governance/policy/concepts/effect-basics | CC BY 4.0 / MIT [C via azure-docs] | Fatos (nomes de efeitos) |
| https://learn.microsoft.com/en-us/azure/developer/terraform/overview | CC BY 4.0 [NC por página] | Fatos |
| https://learn.microsoft.com/en-us/azure/developer/azure-mcp-server/overview | CC BY 4.0 [NC por página] | Fatos |
| https://azure.github.io/Azure-Verified-Modules/overview/ | [NC] (provável MIT) | Fatos/nomes de registry |
| https://github.com/microsoft/azure-skills | MIT [C] | Referência de temas; não copiar |
| https://github.com/microsoft/skills | MIT [C] | Referência de temas; não copiar |
| https://github.com/github/awesome-copilot | MIT [C] | Referência de temas; não copiar |
| https://github.com/MicrosoftDocs/azure-docs | CC BY 4.0 (docs) + MIT (código) [C] | Base da conclusão de licença |
