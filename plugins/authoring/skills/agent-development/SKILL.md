---
name: agent-development
description: Guia para criar ou revisar agentes (subagentes) do Claude Code em projeto ou plugin (arquivo agents/<nome>.md, frontmatter, description com gatilhos, ferramentas mínimas, model, skills, system prompt, delegação e validação). Usar quando o pedido for criar, ajustar, restringir ou revisar um agente ou o agente principal da sessão.
---

# Desenvolvimento de Agentes

Um agente é um arquivo Markdown: o frontmatter configura, o corpo vira o
system prompt. Ele roda em contexto isolado e devolve só o relato final.

## 1. Arquivo e local

| Escopo | Caminho | Nome usado na delegação |
|---|---|---|
| Projeto | `.claude/agents/<nome>.md` | `<nome>` |
| Usuário | `~/.claude/agents/<nome>.md` | `<nome>` |
| Plugin | `<plugin>/agents/<nome>.md` | `<plugin>:<nome>` |

- Nome do arquivo: `<nome>.md` (não `*.agent.md`). Subpastas em plugin viram parte
  do nome (`plugin:pasta:nome`).
- Exemplos reais: `plugins/sdd/agents/` (`techlead`, `backend`, `tests`, `security`...).
  Exemplos comentados: [references/examples.md](references/examples.md).

## 2. Frontmatter

```yaml
---
name: reviewer
description: <papel em uma frase>. Usar quando <gatilhos>.
tools: Read, Grep, Glob
model: sonnet
skills: sdd-rules
---
```

| Campo | Regra |
|---|---|
| `name` | obrigatório; kebab-case; sem `:`; igual ao arquivo |
| `description` | obrigatório; decide a delegação automática |
| `tools` | lista de permissão; omitido = herda todas (evitar) |
| `disallowedTools` | remove ferramentas herdadas (ex.: `mcp__*`) |
| `model` | `sonnet`, `opus`, `haiku`, ID completo ou `inherit` |
| `skills` | skills pré-carregadas (subagentes); nomes sem prefixo do plugin |
| `color`, `effort`, `maxTurns`, `memory`, `isolation` | opcionais |

Arquivo sem `name`/`description` ou com YAML inválido é ignorado ou carregado
sem configuração: sempre validar (seção 8).

### Campos ignorados em agente de plugin

`permissionMode`, `hooks`, `mcpServers` e `initialPrompt` não têm efeito em agente
de plugin. Hooks vão em `hooks/hooks.json` do plugin; servidores MCP em `.mcp.json`.
Não declarar esses campos achando que restringem algo.

## 3. Description com gatilhos

- Primeira frase: papel e foco ("QA Lead responsável pela validação de requisitos...").
- Depois: quando delegar ("Usar após implementação para validar critérios de aceite").
- Específica e curta: todas as descriptions somadas pesam no contexto da sessão.
- Diferenciar de agentes vizinhos (ex.: `tests` valida; `security` revisa segurança).
- "Usar proativamente após ..." incentiva delegação automática.

## 4. Ferramentas: menor privilégio

- Listar só o necessário. Revisor: `Read, Grep, Glob` (+ `Bash` se precisar rodar
  ferramenta de análise). Implementador: `Read, Edit, Write, Grep, Glob, Bash`.
- `Agent` só para orquestrador; restringir alvos com `Agent(nome1, nome2)` quando possível.
- `Skill` quando o agente precisa carregar skills sob demanda (ver seção 5).
- Ferramentas MCP: nome completo `mcp__<servidor>__<ferramenta>`, ex.:
  `mcp__claude_ai_Atlassian__getJiraIssue`.
- **Verificar o nome real na sessão** antes de listar: nomes inexistentes são
  ignorados em silêncio. Achado do spike: `getVisibleJiraProjects` não existe no
  conector Atlassian; os de leitura confirmados são `atlassianUserInfo`,
  `getAccessibleAtlassianResources`, `getJiraIssue`, `searchJiraIssuesUsingJql`.
- Preferir somente leitura em integrações externas; escrita exige decisão explícita
  do usuário e, se possível, `permissions.deny` no settings do projeto.

## 5. Agente principal e skills

- Para rodar a sessão inteira como um agente: `"agent": "<plugin>:<nome>"` no
  settings do projeto, `"agent": "<nome>"` no `settings.json` do próprio plugin,
  ou `claude --agent <plugin>:<nome>`.
- **Achado do spike (T-001)**: `skills:` não pré-carrega no agente da sessão
  principal. Incluir `Skill` em `tools:` e instruir no corpo:
  "No início da sessão e após compact, carregar `sdd:sdd-rules` com a ferramenta Skill".
  Manter no corpo o essencial para o agente ser autossuficiente.
- Em subagentes, `skills:` funciona: o conteúdo completo entra na partida;
  `references/` não, o agente lê a indicada.

## 6. Delegação

- Delegar pelo nome completo: `sdd:backend`, `sdd:tests` (agente de plugin).
- O subagente não vê o histórico: a mensagem de delegação deve trazer objetivo,
  requisitos (REQ), arquivos/caminhos, restrições e formato do relato.
- Preferir caminhos e símbolos a colar arquivos inteiros.

## 7. Estrutura do system prompt

Seções recomendadas (padrão dos agentes do plugin `sdd`):

1. **Papel**: quem é e qual pergunta responde ("A funcionalidade atende aos requisitos?").
2. **Fontes**: skills pré-carregadas e arquivos do projeto a ler (ex.: `CLAUDE.md`, spec).
3. **Responsabilidades**: lista curta e verificável.
4. **Proibições**: o que nunca faz (ex.: "alterar código de produção", "encerrar tasks").
5. **Processo**: passos numerados.
6. **Contrato de entrega**: formato fixo do relato (status permitidos, evidências,
   arquivos alterados, comandos executados, riscos).
7. **Segurança**: nunca expor segredos; validar entrada externa.

Regras de escrita:

- Imperativo, frases curtas, sem narrativa.
- Status e formatos enumerados explicitamente (ex.: `VALIDADO` | `REPROVADO`).
- Escalonamento definido (ex.: 3 tentativas sem progresso → reportar ao líder).
- Sem buscar URL em tempo de uso para obter instruções; sem segredos no prompt.
- Textos em pt-BR; identificadores em inglês.

## 8. Checklist e validação

- [ ] Arquivo `agents/<nome>.md`; `name` igual ao arquivo, sem `:`
- [ ] `description` com papel + "Usar quando ..."
- [ ] `tools` mínimo; nomes MCP conferidos na sessão
- [ ] Sem `permissionMode`/`hooks`/`mcpServers` em agente de plugin
- [ ] `skills` listadas existem no plugin; agente principal usa `Skill`
- [ ] Corpo com papel, responsabilidades, proibições e contrato de entrega
- [ ] Delegações citam `plugin:agente`
- [ ] Sem segredos

```bash
claude plugin validate <caminho-do-plugin>
claude plugin validate <caminho-do-marketplace>
```

Esperado: `Validation passed`. Depois, testar: pedir uma tarefa que deve
delegar ao agente e conferir o nome usado (`<plugin>:<nome>`) e as ferramentas disponíveis.

---

Texto próprio; baseado na documentação pública do Claude Code (https://code.claude.com/docs/en/sub-agents, https://code.claude.com/docs/en/plugins/components, https://code.claude.com/docs/en/plugins-reference, https://code.claude.com/docs/en/skills) e nas convenções deste projeto.
