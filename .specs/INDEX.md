# Índice de specs

Mantido pelo `sdd:techlead`: atualizado ao criar e ao arquivar features.
Ativas ficam em `.specs/<feature>/`; concluídas em `.specs/done/<feature>/` (não editar; mudança vira feature nova
com `Relacionada a: done/<feature>`).

## Ativas

| Feature | Estado | Início | Origem | Resumo |
|---|---|---|---|---|
| — | — | — | — | nenhuma |

## Concluídas

| Feature | Concluída | Origem | Resumo |
|---|---|---|---|
| [sdd-plugin](done/sdd-plugin/spec.md) | 2026-10-09 | pedido do usuário | Plugin e marketplace com agentes e skills agnósticos de linguagem (`sdd` 0.1.x, `authoring`) |
| [docs-manual](done/docs-manual/spec.md) | 2026-10-09 | pedido do usuário | Manual de uso em HTML, arquitetura e docs atualizadas |
| [vcs-integration](done/vcs-integration/spec.md) | 2026-10-10 | pedido do usuário | Leitura opcional de GitHub/Bitbucket/GitLab/Azure DevOps: issue → spec, PR/CI como evidência (`sdd` 0.2.0) |
| [angular-reference](done/angular-reference/spec.md) | 2026-10-10 | GH#1 | Referência Angular no `frontend-engineering`, por versão (`sdd` 0.3.0) |
| [infra-engineering](done/infra-engineering/spec.md) | 2026-10-10 | pedido do usuário | Skill de infraestrutura com referências AWS, Azure e Google Cloud (`sdd` 0.4.0) |
| [specs-done-archive](done/specs-done-archive/spec.md) | 2026-10-10 | pedido do usuário | Arquivar specs concluídas em `.specs/done/` e manter este índice (`sdd` 0.5.0) |
| [onboarding-check](done/onboarding-check/spec.md) | 2026-10-10 | pedido do usuário | Verificar onboarding no início da sessão e orientar a primeira resposta do TecLeader (`sdd` 0.6.0) |
| [specs-location](done/specs-location/spec.md) | 2026-10-10 | pedido do usuário | `.specs/` sempre na raiz do projeto (repositório git); hook detecta git sem executá-lo (`sdd` 0.6.1) |
| [claude-md-layers](done/claude-md-layers/spec.md) | 2026-10-10 | pedido do usuário | Camadas do CLAUDE.md; migração com plano padrão e uma confirmação; `Versionar artefatos SDD` (`sdd` 0.6.2) |
| [workspace-multi-project](done/workspace-multi-project/spec.md) | 2026-10-10 | pedido do usuário | Gatilho de migração preciso; trabalho entre projetos (workspace, `--add-dir`), deny exigido e somente leitura (`sdd` 0.6.3) |
| [docs-conformance](done/docs-conformance/spec.md) | 2026-10-11 | pedido do usuário | Conformidade com a doc oficial: precedência real, textos corrigidos, deny de segredos/push destrutivo, licença MIT (`sdd` 0.6.4, `authoring` 0.2.1) |
| [pin-ref](done/pin-ref/spec.md) | 2026-10-11 | pedido do usuário | Template git fixa a versão com `ref`; regra versão × release (tag só em release, com confirmação) |
| [first-run-guide](done/first-run-guide/spec.md) | 2026-10-11 | pedido do usuário | Guia de primeiro uso (código existente e projeto do zero), verificado em máquina nova e por teste de usabilidade |
| [agents-office](done/agents-office/spec.md) | 2026-10-11 | pedido do usuário | Salinha dos agentes no navegador: opt-in, abre sozinha, popup do processo, sem terceiros (`sdd` 0.7.0) |
| [office-visual](done/office-visual/spec.md) | 2026-10-11 | pedido do usuário | Salinha: texto nítido, layout melhor, balões sem sobreposição (`sdd` 0.7.1) |
| [rename-techlead](done/rename-techlead/spec.md) | 2026-10-11 | pedido do usuário | Renomear `sdd:tecleader` para `sdd:techlead`, com agente obsoleto de migração (`sdd` 0.8.0, mudança incompatível) |
| [office-working-state](done/office-working-state/spec.md) | 2026-10-12 | pedido do usuário | Salinha: agente ativo aparece trabalhando até o stop (`sdd` 0.8.1; publicada na release v0.9.1) |
| [repo-publico-salinha-mobile](done/repo-publico-salinha-mobile/spec.md) | 2026-10-12 | pedido do usuário | Docs sem premissa de repo privado e agente `mobile` na salinha (`sdd` 0.9.1) |
| [office-single-open](done/office-single-open/spec.md) | 2026-10-13 | pedido do usuário | Salinha: não abrir de novo quando já estiver aberta, por atividade recente da sala (`sdd` 0.9.3) |
| [mobile-git-workflow](done/mobile-git-workflow/spec.md) | 2026-10-11 | pedido do usuário | Agente `sdd:mobile` (React Native/Expo) e fluxo Git trunk-based com Conventional Commits (`sdd` 0.9.0; validação parcial aceita) |
| [publish-opt-in](done/publish-opt-in/spec.md) | 2026-10-13 | pedido do usuário | Publicação (push da branch, PR, release) como escolha do usuário no `settings.local.json` (`sdd` 0.9.2; validação parcial aceita) |
| [spec-pr-flow](done/spec-pr-flow/spec.md) | 2026-10-13 | pedido do usuário | Fim da spec abre o PR; o merge é sempre do usuário (`sdd` 0.9.4; validação parcial aceita) |
| [start-banner](done/start-banner/spec.md) | 2026-10-14 | pedido do usuário | Aviso de início de sessão (`systemMessage` no `SessionStart`): o TechLead só responde depois da primeira mensagem (`sdd` 0.9.5) |
| [start-command](done/start-command/spec.md) | 2026-10-14 | pedido do usuário | Comando `/sdd:start` para o usuário iniciar o fluxo e as perguntas iniciais com o TechLead (`sdd` 0.9.6) |
| [drawio-mcp](done/drawio-mcp/spec.md) | 2026-10-14 | pedido do usuário | MCP draw.io empacotado no plugin `sdd` (versão fixada, lançador Node) para o `sdd:infra-architect` (`sdd` 0.9.7) |
| [playwright-mcp](done/playwright-mcp/spec.md) | 2026-10-14 | pedido do usuário | MCP Playwright empacotado no plugin `sdd` (versão fixada, perfil isolado, 19 ferramentas) para o `sdd:frontend` acessar o navegador (`sdd` 0.9.8) |
| [relax-deny](done/relax-deny/spec.md) | 2026-10-14 | pedido do usuário | Git, escrita em sistemas externos e comandos de nuvem liberados com confirmação (`deny` → `ask`); merge, credenciais e segredos seguem em `deny` (`sdd` 0.10.0) |
| [jira-write](done/jira-write/spec.md) | 2026-10-14 | pedido do usuário | TechLead pode escrever no Jira (4 ferramentas, 2 prefixos), só com pedido e confirmação (`sdd` 0.10.1) |
| [context-hygiene](done/context-hygiene/spec.md) | 2026-10-14 | pedido do usuário | Higiene de contexto: o TechLead sugere `/clear` ao arquivar spec e ao mudar de tarefa; hook `clear` reinjeta o diagnóstico (`sdd` 0.10.2) |
| [plugin-review](done/plugin-review/spec.md) | 2026-10-14 | pedido do usuário | Revisão do plugin: TechLead enxuto (−54%, playbooks em skills sob demanda), agente `tecleader` removido, CI (`sdd` 0.11.0) |
| [context-management](done/context-management/spec.md) | 2026-10-14 | pedido do usuário | Gestão de contexto pela doc oficial: `autoCompactWindow` (settings e subagentes), `Compact instructions`, o que sobrevive à compactação (`sdd` 0.11.1) |
| [merge-guard](done/merge-guard/spec.md) | 2026-10-14 | pedido do usuário | Hook `merge-guard` bloqueia merge de PR e push forçado em qualquer modo, inclusive `sh -c` (`sdd` 0.12.0) |
| [office-ask-at-start](done/office-ask-at-start/spec.md) | 2026-10-15 | pedido do usuário | A pergunta da salinha passa a ser feita pelo `/sdd:start` (uma vez, só com `pref=unset`); padrão desligado (`sdd` 0.12.0) |
| [docs-install](done/docs-install/spec.md) | 2026-10-15 | pedido do usuário | Documentação refeita: instalação por tipo (A a F), CLI por SO, verificadores `check-env` e testes (`sdd` 0.12.0) |
