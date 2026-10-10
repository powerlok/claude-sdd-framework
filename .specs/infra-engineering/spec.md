# Spec: skill `infra-engineering` (AWS, Azure, Google Cloud) para o `infra-architect`

Pedido do usuário (2026-10-10): "adicionar skills para o arquiteto de AWS, Azure, GCloud. Pesquise as melhores e
adicione escrevendo da melhor forma".

## Requisitos

- **REQ-001**: Skill `plugins/sdd/skills/infra-engineering/` com `SKILL.md` de princípios agnósticos de nuvem
  (frameworks de arquitetura bem-arquitetada, IaC, rede, identidade, segredos, observabilidade, custo, resiliência,
  DR, segurança, decisões com trade-offs, rollback) e seção "Como escolher a referência".
- **REQ-002**: Referências `references/aws.md`, `references/azure.md`, `references/gcp.md` com a mesma estrutura de
  seções, cobrindo: framework oficial de arquitetura, landing zone/organização de contas, identidade e acesso,
  rede, computação/containers/serverless, dados, segredos e chaves, observabilidade, custo, resiliência/DR,
  segurança/compliance, IaC (nativo + Terraform/OpenTofu), CLI de exemplo (somente leitura e plan), armadilhas.
- **REQ-003**: `infra-architect` agnóstico de nuvem (sem "AWS" fixo), com `skills:` incluindo `infra-engineering`;
  a nuvem vem da seção `## Stack` (ou `## Infra`) do `CLAUDE.md` do projeto e do campo `Stack:` da delegação;
  caminho das referências via `${CLAUDE_PLUGIN_ROOT}`.
- **REQ-004**: Pesquisa nas fontes oficiais (AWS Well-Architected, Azure Well-Architected/CAF, Google Cloud
  Architecture Framework) e nas skills/guias públicos para agentes mais bem avaliados; **texto próprio**, com fontes,
  licenças e data de consulta; atenção a licenças ShareAlike (não adaptar texto, só fatos).
- **REQ-005**: Segurança: nenhuma instrução que execute ação destrutiva/aplique mudança em nuvem sem confirmação
  (`apply`, `delete`, `deploy` exigem confirmação explícita — regra não relaxável); comandos de exemplo
  limitados a leitura, `plan`/`what-if`/`preview`; nenhum segredo/ID de conta real.

## Critérios de aceite

- REQ-001/002: arquivos existem; ≤ ~200 linhas (SKILL.md) e ≤ ~240 linhas por referência; seções equivalentes.
- REQ-003: `grep -i "aws"` no `infra-architect.md` só em contexto genérico/exemplo; `skills:` atualizado; validate OK.
- REQ-004: rodapé com fontes/licenças; revisão do `security` sem cópia.
- REQ-005: revisão do `security` APROVADA.
- Piloto: `sdd:infra-architect` com `Stack: Azure` lê `references/azure.md` e responde com práticas Azure (e não AWS).

## Validação

`claude plugin validate`; revisão do `security`; piloto por nuvem (no mínimo Azure e GCP; AWS opcional).

## Fora de escopo

Executar qualquer comando contra contas de nuvem; MCP servers de nuvem (pode virar feature futura).
