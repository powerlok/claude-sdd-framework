# Referência: Azure

Complementa os princípios agnósticos de [../SKILL.md](../SKILL.md).
Ler somente quando a nuvem do projeto (seção `## Stack`/`## Infra` do `CLAUDE.md` ou campo `Stack:`) for Azure.

## 1. Framework oficial

- Azure Well-Architected Framework (WAF), com 5 pilares: Reliability, Security, Cost Optimization,
  Operational Excellence e Performance Efficiency; cada pilar traz princípios de design, trade-offs
  e um design review checklist próprio.
- Avaliação formal: Azure Well-Architected Review (questionário de assessment).
- Azure Advisor emite recomendações por pilar; o Advisor score pode ser aberto por pilar para priorizar.
- Reference architectures do Azure Architecture Center já seguem o WAF; partir delas antes de desenhar do zero.

## 2. Organização e landing zone

- Cloud Adoption Framework (CAF): a Azure landing zone combina uma **platform landing zone**
  (normalmente uma por tenant Microsoft Entra) e **workload (application) landing zones**.
- Platform = hierarquia de management groups + recursos centrais (conectividade, identidade,
  gestão, monitoramento de segurança) + "subscription vending" repetível.
  Centralizar apenas o que traz ganho claro.
- Cada workload separa ambientes (dev/test/prod) em uma ou mais subscriptions por ambiente.
- Hierarquia de referência: Platform (Security, Management, Identity, Connectivity),
  Landing zones (Corp/Internal, Online, Local), Sandbox e Decommissioned.
- Subscriptions herdam Azure Policy dos management groups; entre atribuições em escopos diferentes,
  prevalece o resultado mais restritivo. Efeitos incluem `audit`, `auditIfNotExists`, `deny`,
  `denyAction`, `deployIfNotExists`, `modify`, `append` e `disabled`.
- Começar policies em `audit` e só depois promover para `deny` (prática comum; confirme na documentação atual).
- Tags (ex.: `CostCenter`, `Owner`) para custo e propriedade; exigência/herança via `modify`
  (confirme na documentação atual).
- Para implantar a landing zone, preferir os accelerators IaC oficiais da Microsoft a um build próprio.

## 3. Identidade e acesso

- Workloads usam **managed identity** (credencial gerenciada pela plataforma, inacessível ao usuário, sem custo extra):
  - system-assigned: vive e morre com o recurso (1:1);
  - user-assigned: recurso independente, compartilhável e pré-autorizável antes de o recurso existir
    (tipo recomendado pela Microsoft para seus serviços).
- Quando um app registration for inevitável, usar workload identity federation
  (managed identity como Federated Identity Credential; limite de 20 FICs) em vez de client secret.
- Acesso humano privilegiado via PIM: atribuições elegíveis just-in-time, com aprovação e MFA na ativação;
  Conditional Access; poucos administradores.
- Contas de acesso de emergência (break-glass) excluídas do Conditional Access e monitoradas
  (confirme na documentação atual).
- Owner e User Access Administrator podem gerenciar locks e atribuições de papel: tratar como acesso crítico.
- Em Storage, preferir Entra ID a Shared Key; se SAS for necessário, user delegation SAS com escopo e prazo mínimos.

## 4. Rede

- Topologia recomendada pelo CAF: **hub-spoke**. Hub regional com serviços compartilhados
  (Azure Firewall, VPN/ExpressRoute gateway, Bastion, DNS); spokes isolam workloads/ambientes via peering.
- Peering **não é transitivo**: spoke-to-spoke passa por Firewall/NVA com UDR, peering direto
  ou connected groups do Virtual Network Manager.
- Virtual WAN é a alternativa gerenciada; hub-spoke próprio dá mais controle e tende a custar menos.
- Um hub por região, conectando só spokes da mesma região; usar availability zones nos serviços do hub.
- `AzureFirewallSubnet` e `GatewaySubnet` com no mínimo /26; `AzureFirewallSubnet` não aceita NSG.
- NSGs com regras `deny` explícitas; DDoS Protection nas VNets de perímetro; Firewall Premium para
  TLS inspection e IDPS.
- Planejar espaço de IP sem sobreposição com on-premises (IPAM do Virtual Network Manager).
- Acesso privado a PaaS: Private Endpoint (IP privado) **combinado** com desabilitar o acesso público.
  Network Security Perimeter agrupa PaaS (Key Vault, Storage, SQL) em perímetro lógico.
- Storage firewall aceita qualquer rede por padrão: restringir por VNet, IP, resource instance ou trusted services.

## 5. Computação — critérios de escolha

Todas as opções são regionais: multi-região exige roteador global (Front Door/Traffic Manager) e uma instância por região.

| Opção | Quando usar | Trade-off |
|---|---|---|
| Virtual Machines | lift-and-shift, controle total do SO, GPU | controle máximo, maior overhead operacional |
| App Service | web/API gerenciado | PaaS; VNet integration exige tier Basic ou superior |
| Container Apps | containers sem gerir cluster, escala por eventos | sem acesso à API do Kubernetes |
| AKS | precisa da API/control plane do Kubernetes | overhead alto (upgrades, cluster); produção: 3 nós no system pool + 3 por user pool |
| Functions | event-driven, curta duração | overhead operacional muito baixo |
| Container Instances / Batch | tarefas pontuais / HPC em lote | escopo restrito ao caso de uso |

Pesar também: escala, skills do time, custo, limites e SLAs de cada serviço.

## 6. Dados e armazenamento

- Storage: criptografia em repouso por padrão (chaves Microsoft); CMK via Key Vault quando exigido.
- Storage: **desabilitar acesso anônimo** a blobs e **desabilitar Shared Key**; exigir HTTPS (secure transfer)
  e TLS mínimo; firewall/private endpoint.
- Proteção de dados: soft delete de blobs e containers; immutability (WORM) para dados críticos.
  Lock no storage account protege só o account, não os dados.
- Defender for Storage; logs registram o tipo de autorização usado (anônimo, OAuth, Shared Key, SAS).
- Azure SQL (Entra-only auth, TDE, private endpoint, zone redundancy) e Cosmos DB (desabilitar local auth,
  backup contínuo, multi-região): confirme na documentação atual.
- Key Vault não é banco de dados: configuração em App Configuration/Storage; dados de cliente em Cosmos DB/Storage.

## 7. Segredos e chaves

- **Um Key Vault por aplicação + região + ambiente** (menor blast radius); um por tenant em SaaS multi-tenant.
- Autorização por **Azure RBAC**; access policies são o modelo legado, com fragilidades conhecidas e sem suporte a PIM.
- **Soft delete** (retenção de 7 a 90 dias) + **purge protection**; autorotação de chaves, segredos e certificados;
  backup de chaves que não podem ser recriadas (e testar o restore).
- Rede: desabilitar acesso público + **private endpoint** (opção mais restrita); depois firewall; depois NSP.
  Clientes com TLS 1.2/1.3.
- Logs de auditoria, Defender for Key Vault, alertas/Event Grid e Azure Policy para conformidade de configuração.
- App Service/Functions: **Key Vault references** nas app settings (`@Microsoft.KeyVault(...)`), resolvidas pela
  **managed identity** do app com o papel "Key Vault Secrets User". Sem versão explícita, a mais recente
  é adotada em até 24 h. App settings são criptografados em repouso, mas o segredo deve morar no Key Vault.

## 8. Observabilidade e auditoria

- Activity Log: operações de control plane, coletado por padrão, sem custo, **retido por 90 dias**.
  É o único registro de quem criou um recurso: **exportar** via diagnostic setting para Log Analytics
  (até 12 anos), Event Hubs ou Storage.
- Configurar o diagnostic setting no management group mais alto para cobrir a hierarquia sem duplicatas.
- Resource logs (data plane) **não** são coletados por padrão: exigem diagnostic setting por recurso/policy.
- Application Insights para telemetria da aplicação (a connection string não é tratada como segredo).
- Desligar categorias de log sem uso (Azure Firewall gera volume e custo altos);
  Network Watcher/Connection monitor para diagnóstico de rede.

## 9. Custo

- Budgets (Cost Management) **apenas alertam** (custo real ou previsto); **não param recursos**.
  Escopos: management group, subscription, resource group e escopos de billing; até 5 thresholds;
  avaliação a cada 24 h, com dados atrasados de 8 a 24 h.
- Automação de resposta: budget aciona action group (somente nos escopos subscription e resource group).
- Reservations: compromisso de 1 ou 3 anos em SKU e região específicos; maior desconto para carga estável.
  Savings plan: compromisso de gasto por hora em compute, em qualquer região; para carga variável.
- Ordem sugerida: right-size → ajustar reservas existentes → novas reservas → savings plan.
- Advisor (pilar Cost Optimization) para encontrar ociosidade; tags para alocação (confirme na documentação atual).

## 10. Resiliência e DR

- Availability zones são a primeira linha de redundância; muitas regiões novas **não têm par**.
- **Região pareada não é DR automático**: só alguns serviços usam o par (ex.: GRS) e o failover gerenciado pela
  Microsoft é reservado a catástrofes. O plano de DR é responsabilidade do cliente.
- Pares podem ser assimétricos e **fora da geografia**: Brazil South replica para South Central US (EUA).
  Avaliar **residência de dados/LGPD** antes de usar GRS ou serviços que dependem do par.
- Azure Site Recovery: replicação contínua de VMs, failover/failback, recovery plans e drills sem impacto.
  Azure Backup é serviço separado (cópias recuperáveis); um não substitui o outro.
- Definir RTO/RPO por workload e testar restore/failover periodicamente.

## 11. Segurança e compliance

- Microsoft Defender for Cloud (CNAPP): CSPM (Foundational gratuito + Defender CSPM pago) e planos CWPP por
  workload (Servers, Containers, Storage, Databases, Key Vault, App Service, Resource Manager, APIs, AI).
- Microsoft cloud security benchmark é o padrão embutido; secure score resume a postura.
- Microsoft Sentinel como SIEM na subscription de Management/Security da landing zone.
- DDoS Protection nas VNets de perímetro; WAF em Application Gateway/Front Door para HTTP público
  (confirme na documentação atual).
- Resource locks `CanNotDelete` e `ReadOnly`: herdados do escopo pai, valem para todos (inclusive Owner),
  **atuam só no control plane** (não protegem dados) e não existem em management group.
  Efeitos colaterais: `ReadOnly` em storage impede listar chaves; `CanNotDelete` em resource group impede a
  limpeza do histórico de deployments (limite de 800) e de restore points do Backup.

## 12. IaC

Nativo: Bicep/ARM. Terraform/OpenTofu: providers AzureRM (recursos estáveis), AzAPI (ARM direto, novidades),
AzureAD (Entra) e AzureDevops. **Azure Verified Modules (AVM)**: módulos oficiais para Bicep
(`br/public:avm/...`) e Terraform (`Azure/avm-...`), nas classes resource, pattern e utility, alinhados ao WAF.
Preferir AVM a módulos caseiros.

| Só mostra prévia | APLICA MUDANÇA (exige confirmação explícita) |
|---|---|
| `az deployment group\|sub\|mg\|tenant what-if` | `az deployment ... create` (inclusive com `--confirm-with-what-if`/`-c`) |
| `New-AzResourceGroupDeployment -WhatIf` | `New-Az*Deployment` (com ou sem `-Confirm`) |
| `bicep snapshot` (local, sem conexão) | deployment stacks (o what-if deles mostra detach/delete) |
| `terraform plan` / `tofu plan` (confirme na documentação atual) | `terraform apply` / `destroy` e equivalentes `tofu` |

- Prévia não é isenta de efeito (executa código de provider/data sources; `init` baixa providers/módulos):
  identidade somente leitura e só sobre código revisado (ver `../SKILL.md`).
- **Cuidado**: `create --confirm-with-what-if` não é prévia — mostra o what-if e **APLICA** ao responder "y".
- What-if exige as **mesmas permissões do deploy**; com identidade somente leitura (regra do `../SKILL.md`),
  usar `--validation-level ProviderNoRbac` (CLI ≥ 2.76.0), que checa apenas leitura. A identidade com
  permissão de deploy fica com quem aplica (usuário/pipeline), nunca com o agente.
- Limitações do what-if: ruído (defaults aparecem como removidos), `reference()`/`listKeys()`/`utcNow()` e
  parâmetros seguros não avaliados, templateLink não expandido, short-circuiting; mudanças do tipo remoção
  só aparecem em modo complete. Revisar o resultado, não confiar cegamente.
- State remoto do Terraform em Storage com Entra auth e lock por blob lease (confirme na documentação atual).

## 13. Comandos de exemplo (somente leitura e prévia)

Exemplos; usar os comandos reais do `CLAUDE.md` do projeto. Placeholders `<...>`; nunca IDs reais.

```bash
az account show                                   # subscription ativa (confirme na documentação atual)
az lock list --resource-group <rg>                # locks existentes
az monitor activity-log list --offset 7d          # auditoria de control plane recente
az deployment group what-if -g <rg> -f main.bicep # prévia; não altera recursos
az deployment sub what-if -l <region> -f main.bicep
terraform plan -out=tfplan                        # prévia (confirme na documentação atual)
```

State e arquivo de plano (`tfplan`) contêm segredos: anexar ao PR só a saída textual (ver IaC em `../SKILL.md`).
Comandos que aplicam ou removem recursos não aparecem aqui de propósito: exigem confirmação explícita do usuário.

## 14. Armadilhas comuns

- Tratar `--confirm-with-what-if` como prévia: é um deploy que aplica após "y".
- Rodar what-if com identidade sem permissão de deploy e concluir que "não há mudanças".
- Storage com acesso anônimo, Shared Key ativo ou endpoint público aberto (padrão aceita qualquer rede).
- Segredos direto em app settings em vez de Key Vault references + managed identity.
- Key Vault com access policies, sem purge protection ou compartilhado entre apps/ambientes.
- Owner/User Access Administrator permanentes em vez de PIM just-in-time.
- Achar que lock protege dados, ou aplicar lock sem prever os efeitos (listar chaves, histórico de deploy, Backup).
- Contar com região pareada como DR automático; ignorar que Brazil South pareia fora do Brasil.
- Activity Log não exportado: o criador do recurso some após 90 dias.
- Budget tratado como teto de gasto (só alerta).
- Peering tratado como transitivo; espaço de IP sobreposto com on-premises.

---

## Fontes e atribuição

Consultado em 2026-10-10. Texto próprio; nenhum trecho copiado. Documentação Microsoft sob
CC BY 4.0 (texto) e MIT (código de exemplo) — aqui só fatos, reescritos com texto próprio.
Inspiração temática (sem cópia): `microsoft/azure-skills` (MIT).

- https://learn.microsoft.com/en-us/azure/well-architected/pillars
- https://learn.microsoft.com/en-us/assessments/azure-architecture-review/
- https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/landing-zone/
- https://learn.microsoft.com/en-us/azure/governance/policy/concepts/effect-basics
- https://learn.microsoft.com/en-us/entra/identity/managed-identities-azure-resources/overview
- https://learn.microsoft.com/en-us/azure/architecture/networking/architecture/hub-spoke
- https://learn.microsoft.com/en-us/azure/storage/common/storage-network-security
- https://learn.microsoft.com/en-us/azure/architecture/guide/technology-choices/compute-decision-tree
- https://learn.microsoft.com/en-us/azure/storage/blobs/security-recommendations
- https://learn.microsoft.com/en-us/azure/key-vault/general/secure-key-vault
- https://learn.microsoft.com/en-us/azure/app-service/app-service-key-vault-references
- https://learn.microsoft.com/en-us/azure/azure-monitor/fundamentals/activity-log
- https://learn.microsoft.com/en-us/azure/cost-management-billing/costs/tutorial-acm-create-budgets
- https://learn.microsoft.com/en-us/azure/cost-management-billing/savings-plan/decide-between-savings-plan-reservation
- https://learn.microsoft.com/en-us/azure/reliability/regions-paired
- https://learn.microsoft.com/en-us/azure/site-recovery/site-recovery-overview
- https://learn.microsoft.com/en-us/azure/defender-for-cloud/defender-for-cloud-introduction
- https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/lock-resources
- https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/deploy-what-if
- https://learn.microsoft.com/en-us/azure/developer/terraform/overview
- https://azure.github.io/Azure-Verified-Modules/overview/
- https://github.com/microsoft/azure-skills (MIT)
