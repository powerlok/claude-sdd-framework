# T-000: Capacidades de plugin do Claude Code (pesquisa na doc oficial)

Data: 2026-10-09. Fonte: subagente `claude-code-guide`, leitura de code.claude.com/docs/en/plugins/.
Confiança: **Confirmado** = citação da doc com URL; **Revalidar** = resposta inconsistente
ou contradiz configuração que já funciona no workspace; verificar empiricamente no spike do T-001.

| # | Pergunta | Resultado | Confiança | Fonte |
|---|---|---|---|---|
| 1 | Plugin distribui CLAUDE.md / rules? | Não. Instruções devem ir como skill. `claude plugin validate` avisa que CLAUDE.md na raiz do plugin não é carregado | Confirmado | plugins/components.md#skills |
| 2 | Agente de plugin como agente principal | Sim. Nome `<plugin>:<agente>`. CLI: `claude --agent plugin:agente`. Exemplo da doc usa `"agent"` no settings **do plugin**; nome a usar no settings **do projeto** não ficou claro | Revalidar | plugins/components.md#default-settings |
| 3 | Frontmatter de agente de plugin | `skills` suportado. Ignorados: `permissionMode`, `hooks`, `mcpServers`, `initialPrompt` | Confirmado (lista completa de campos: revalidar) | plugins/components.md#frontmatter-fields-in-plugin-agents |
| 4 | Subagente de plugin usa MCP do conector claude.ai | Conectores aparecem no Claude Code; restrição via `tools`. Nome das ferramentas do conector não confirmado | Revalidar | mcp.md |
| 5 | marketplace.json / plugin.json mínimos; local e git | marketplace: `name`, `owner.name`, `plugins[].name/source`. plugin.json: `name`. Local: `claude plugin marketplace add ./caminho`. Git: URL, credenciais git do usuário | Confirmado | plugins/create-marketplace.md |
| 6 | Projeto sugere marketplace/plugin aos devs | `extraKnownMarketplaces` + `enabledPlugins`. **Formato do JSON relatado (array de URLs) parece incorreto**; esperado objeto por marketplace e chave `plugin@marketplace` | Revalidar | settings-reference.md |
| 7 | Versão e atualização | `version` no plugin.json fixa a versão; sem `version` em marketplace git usa o SHA do commit. `/plugin update`. Auto-update desligado por padrão | Confirmado | plugins/publish.md |
| 8 | Nome dos arquivos de agentes | `agents/<nome>.md` (subpastas viram `plugin:pasta:nome`). `*.agent.md` não é o padrão: renomear | Confirmado | plugins/components.md#agents |
| 9 | Hooks em plugin | `hooks/hooks.json`, `${CLAUDE_PLUGIN_ROOT}` suportado. Relatado que matcher `compact` em SessionStart não é documentado, mas o workspace já usa esse matcher | Revalidar | plugins/components.md#hooks |
| 10 | Skills com `references/` | `skills/<nome>/SKILL.md` com arquivos de apoio; caminho via `${CLAUDE_PLUGIN_ROOT}` | Confirmado (leitura de references pelo subagente: revalidar) | plugins/manifest-reference.md |

## Impacto no design (T-001)

- REQ-002 (regras globais): virar skill(s) do plugin, pré-carregadas nos agentes via `skills:`;
  `CLAUDE.md` do projeto continua local, criado pelo onboarding do `tecleader`.
- Arquivos de agentes renomeados de `*.agent.md` para `<nome>.md`.
- Itens "Revalidar" (2, 4, 6, 9 e parte de 3 e 10): spike com plugin mínimo em marketplace local,
  testado numa sessão interativa (o comando `claude` não está disponível no shell desta sessão).
- Plano B (kit + script) só se o spike falhar nos itens 2 ou 6.
