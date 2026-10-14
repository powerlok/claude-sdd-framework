# Spec: gestão de contexto conforme a documentação oficial (autoCompactWindow, Compact instructions, o que sobrevive à compactação)

Pedido do usuário (2026-10-14): "precisa definir essa parte do contexto conforme a documentação oficial para melhor gerenciamento" (seguimento de `done/context-hygiene`, que deixou
pendente a proposta de `autoCompactWindow`). Relacionada a: done/context-hygiene, done/plugin-review.

## Base na documentação (code.claude.com/docs: model-config, context-window, costs, sub-agents, settings; verificado em 2026-10-14)

- Compactação automática: sem configuração, modelos com janela nativa de 1M compactam perto de ~967 mil tokens; `autoCompactWindow` (100.000 a 1.000.000), `/autocompact`,
  `claude --autocompact` e `CLAUDE_CODE_AUTO_COMPACT_WINDOW` antecipam. `autoCompactWindow` vale em qualquer arquivo de settings (`Any file`).
- Subagente: campo de frontmatter `autoCompactWindow` (inteiro de 100.000 a 1.000.000, exige Claude Code 2.1.296+; `200k` seria lido como 200); não tem efeito quando a sessão
  inteira roda como esse agente. A doc não o marca como ignorado para plugin (`hooks`, `mcpServers`, `permissionMode` e `initialPrompt` são).
- O que sobrevive à compactação: system prompt do agente (continua valendo); `CLAUDE.md` da raiz (relido do disco); corpos de skills invocadas (reinjetados, **limite de 5.000 tokens por
  skill e 25.000 no total**, o mais antigo cai primeiro; truncamento mantém o **início** do arquivo); hooks `SessionStart` com matcher `compact` rodam; até 5 arquivos lidos/editados.
  A lista de skills disponíveis não é reinjetada.
- "Compact instructions" no `CLAUDE.md` orientam o resumo; `/compact <foco>` e `/rewind` (Summarize from here) também.

## Requisitos

- **REQ-001**: modelos `project-settings.git.json` e `.local.json` ganham `"autoCompactWindow": 200000` (no-op em modelos de 200K; antecipa a compactação em modelos de 1M, reduzindo o
  contexto reenviado a cada mensagem). Alinhado à regra existente "tasks para caber em 200K, alvo 70%". Documentar como mudar (`/autocompact`, remover a chave).
- **REQ-002**: subagentes que implementam e rodam testes (`backend`, `frontend`, `mobile`, `tests`) ganham `autoCompactWindow: 140000` (70% de 200K, a meta que o TechLead já usa); `security`
  e `infra-architect` herdam a janela da sessão (revisão e desenho de infra precisam de mais contexto). `techlead` não (o campo não vale para a sessão principal).
- **REQ-003**: `templates/CLAUDE.md` ganha `## Compact instructions` (o que preservar: spec ativa, REQs, estado das tasks, decisões, arquivos alterados, testes, pendências, comandos); o onboarding
  (skill `project-setup`) passa a incluí-la no `CLAUDE.md` criado.
- **REQ-004**: "Gestão de Contexto" do TechLead: o que sobrevive à compactação (e que o prompt do agente continua valendo), `/compact <foco>` pronto para sugerir, `/rewind`, `/context`,
  a janela configurada; skills com o mais importante no **topo** e cada `SKILL.md` ≤ 15.000 bytes (teto de 5.000 tokens por skill reinjetada).
- **REQ-005**: testes (`req012-context.test.sh`), docs (README "Contexto e tokens"), CHANGELOG, `sdd` 0.11.1.

## Limites e riscos

Compactar em 200K em modelo de 1M perde detalhe da conversa no resumo (o estado fica em `.specs/`/`tasks.md`) e a compactação em si é uma requisição grande; quem prefere a janela cheia remove a chave.
`/autocompact` salvo por modelo no settings do usuário tem precedência. O frontmatter `autoCompactWindow` exige Claude Code 2.1.296+ (em versões anteriores o campo é ignorado).

## Critérios de aceite

Testes verdes; `validate --strict`; CLI real carrega as chaves sem aviso (`--debug` sem "invalid autoCompactWindow").
