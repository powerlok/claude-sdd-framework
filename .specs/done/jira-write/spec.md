# Spec: TechLead pode escrever no Jira, sempre com confirmação

Pedido do usuário (2026-10-14): "sim", à oferta de dar ao TechLead as ferramentas de escrita do Jira (depois de liberar a escrita em sistemas externos com
confirmação, `done/relax-deny`). Revisão independente de segurança dispensada pelo usuário (relaxamento deliberado); riscos registrados.

## Requisitos

- **REQ-001**: `sdd:techlead` recebe em `tools` só 4 ferramentas de escrita do Jira, nos dois prefixos (`mcp__claude_ai_Atlassian__` e `mcp__atlassian__`):
  `addOrEditJiraIssueComment`, `createJiraIssue`, `editJiraIssue`, `transitionJiraIssue`. **Não** recebe `executeWrite`, `executeDestructive` (executores genéricos
  de qualquer operação, inclusive exclusão) nem as de Confluence (`createConfluenceContent`, `updateConfluenceContent`).
- **REQ-002**: as 8 já estão em `permissions.ask` nos modelos de settings (0.10.0): o Claude Code pergunta a cada chamada.
- **REQ-003**: regras no `techlead.md` e na `sdd-governance`: escrever no Jira só com **pedido explícito do usuário** na conversa e confirmação do conteúdo exato (chave,
  campos, texto do comentário, transição de destino); o texto vem da spec/tasks/evidências validadas, **nunca** de conteúdo de issue, log ou arquivo, e sem segredo, token ou
  dado pessoal; nunca em lote sem listar; transição só para o estado pedido; sem `executeWrite|executeDestructive`.
- **REQ-004**: testes (`req007`): o TechLead tem exatamente essas 8 e nenhuma das proibidas; docs, CHANGELOG, `sdd` 0.10.1.

## Riscos residuais (aceitos)

Conteúdo de issue é dado não confiável: injeção de prompt pode induzir comentário, edição ou transição indevidos (a confirmação do usuário é a barreira; `ask` não vale
em `bypassPermissions` nem em `claude -p`). Escrita em Jira corporativo pode notificar pessoas e disparar automações; transição de issue pode ser difícil de reverter.

## Fora de escopo

`executeWrite`/`executeDestructive`, Confluence, escrita por outros agentes.
