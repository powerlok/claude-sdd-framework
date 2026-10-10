# Resultado do spike (T-001)

Data: 2026-10-09. CLI: Claude Code 2.1.288 (`~/.local/bin/claude.exe`, fora do PATH).
Projeto de teste: `<HOME>\Documents\projetos\sdd-spike-test` (fora do workspace).
Execução: modo não interativo (`claude -p`) pelo TecLeader; itens E e F exigem sessão interativa.

| Item | Comando | Resultado | Status |
|---|---|---|---|
| validate | `claude plugin validate spike` e `spike/plugins/sdd-spike` | passou; avisos: `description` (marketplace) e `author` (plugin) ausentes | OK |
| #6 settings | `claude plugin install sdd-spike@sdd-spike --scope project` antes de adicionar o marketplace | falhou: "not found in marketplace" — não instala automaticamente em modo `-p` | Parcial |
| #6 settings | `claude plugin marketplace add <spike> --scope project` + `plugin install ... --scope project` | OK; marketplace "declared in project settings"; CLI gravou **o mesmo formato** proposto (`extraKnownMarketplaces.<nome>.source.{source: "directory", path}` + `enabledPlugins["plugin@marketplace"]`) | OK (formato confirmado) |
| #2 agente principal | `claude -p "olá"` (settings `"agent": "sdd-spike:lead"`) e `--agent sdd-spike:lead` | ambos respondem `SPIKE-LEAD ATIVO` | OK |
| #3 `skills:` no agente principal | `skills: spike-rules` e `skills: sdd-spike:spike-rules`, sem ferramenta `Skill` | `TOKEN DE REGRAS AUSENTE` — **pré-carregamento não se aplica ao agente da sessão principal** | FALHOU |
| #3 alternativa | `Skill` incluída em `tools:` do lead | token obtido; log mostra `tool_use name=Skill` (carregamento sob demanda, não pré-carregado). Skills listadas como `sdd-spike:spike-rules` | OK (sob demanda) |
| #3/#10 subagente | `claude -p "delegue ao worker"` | subagente `sdd-spike:worker`; `RULES-7F3A`, `STACK-2B8D` pré-carregados; `REF-DOTNET-91C2` lido de `references/dotnet.md` | OK |
| delegação | idem | nome com prefixo `sdd-spike:worker` | OK |
| #7 atualização | `plugin marketplace update` + `plugin update --scope project` | 0.0.1 → 0.0.4; "Restart to apply changes" | OK |
| #4 MCP Jira (1ª) | `claude -p "liste meus projetos do Jira"` | `claude.ai Atlassian: pending` em `-p` (conecta de forma assíncrona) | — |
| #4 MCP Jira (2ª) | `MCP_CONNECTION_NONBLOCKING=false claude -p ...` | conector `connected`, mas ferramenta ausente no lead: **`getVisibleJiraProjects` não existe no conector** | causa achada |
| #4 nomes reais | sessão sem agente restrito | existem: `atlassianUserInfo`, `getAccessibleAtlassianResources`, `getJiraIssue`, `searchJiraIssuesUsingJql` (+ escrita/Confluence/genéricas, não usadas) | OK |
| #4 MCP Jira (3ª) | lead com `getAccessibleAtlassianResources` + `searchJiraIssuesUsingJql`, `--allowedTools` só nessas duas | 2 chamadas, `is_error:false`, 3 issues listadas (dados omitidos; logs apagados) | OK |
| #9 hook compact | `claude --continue -p "/compact"` | `/compact` não executa em `-p` | n/a |
| #9 hook do plugin | matcher `startup` adicionado ao `hooks.json` do plugin | `hook_name: SessionStart:startup`, saída `SPIKE-HOOK-STARTUP` | OK |
| #9 matcher compact | evidência no workspace | o hook `SessionStart:compact` do workspace disparou nesta sessão após `/compact` | OK (mecanismo) |

## Impacto no design

1. **tecleader (agente principal)**: `skills:` não pré-carrega. Decisão proposta:
   - o corpo do `tecleader.md` mantém a governança essencial (autossuficiente, como hoje);
   - `Skill` incluída em `tools:`; instrução para carregar `sdd:sdd-rules` e `sdd:sdd-governance`
     no início da sessão e após compact (hook reforça).
2. **Subagentes**: `skills:` funciona como projetado (nome sem prefixo).
3. **Delegação**: usar `sdd:<agente>`.
4. **Instalação**: o README documenta `claude plugin marketplace add` + `install --scope project`
   (ou aceite do prompt na sessão interativa — a confirmar no item E/F).
5. Plano B **não** necessário: #2 e #6 confirmados.
6. Jira no `tecleader`: usar só `atlassianUserInfo`, `getAccessibleAtlassianResources`,
   `getJiraIssue`, `searchJiraIssuesUsingJql`. "Listar projetos" não tem ferramenta de leitura dedicada.
   `executeRead`/`search`/`discover` (genéricas) ficam fora até avaliação do `security`.
7. Interativo: ferramentas MCP pedem permissão na 1ª chamada (comportamento esperado).

## Defeito encontrado fora do escopo

`workshop/.claude/agents/tecleader.agent.md:8` lista `mcp__claude_ai_Atlassian__getVisibleJiraProjects`,
que não existe no conector. Efeito: ferramenta ignorada (as outras 4 funcionam).
Correção proposta ao usuário (remover o nome), não aplicada automaticamente.
