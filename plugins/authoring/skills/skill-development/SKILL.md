---
name: skill-development
description: Guia para criar ou revisar skills do Claude Code (SKILL.md, frontmatter, description que dispara bem, progressive disclosure, references/, skills em plugin, pré-carregamento em subagentes, atribuição de licença e validação). Usar quando o pedido for criar, melhorar, reorganizar ou revisar uma skill de projeto, de usuário ou de plugin.
---

# Desenvolvimento de Skills

Uma skill é um pacote de instruções que o Claude carrega quando a tarefa combina
com a `description`. Escreva para o modelo: instruções diretas, curtas e verificáveis.

## 1. Estrutura

```text
<nome-da-skill>/
├── SKILL.md          # obrigatório: frontmatter + instruções principais
├── references/       # opcional: detalhes lidos sob demanda
│   └── <assunto>.md
└── scripts/          # opcional: utilitários determinísticos
```

Locais de carregamento:

| Escopo | Caminho |
|---|---|
| Projeto | `.claude/skills/<nome>/SKILL.md` |
| Usuário | `~/.claude/skills/<nome>/SKILL.md` |
| Plugin | `<plugin>/skills/<nome>/SKILL.md` |

Exemplo real com `references/` por stack: `sdd:backend-engineering`
(`plugins/sdd/skills/backend-engineering/`).

## 2. Frontmatter

```yaml
---
name: minha-skill
description: <o que faz>. Usar quando <gatilhos concretos>.
---
```

- `name`: kebab-case; padrão é o nome da pasta.
- `description`: decide o disparo. `description` + `when_to_use` são truncados
  em 1.536 caracteres.
- Opcionais úteis: `disable-model-invocation: true` (só invocação manual, ex.: deploy),
  `user-invocable: false` (só o modelo invoca), `allowed-tools` (pré-aprova
  ferramentas apenas no turno da skill).
- Skill com `disable-model-invocation: true` não pode ser pré-carregada em subagente.

## 3. Description que dispara bem

1. Primeira frase: o que a skill entrega (substantivos do domínio).
2. Segunda frase: "Usar quando ..." com verbos e termos que o usuário de fato digita.
3. Citar artefatos concretos (`spec.md`, `SKILL.md`, nome de stack) em vez de adjetivos.
4. Evitar sobreposição com outra skill; se houver, delimitar ("não usar para ...").
5. Sem promessas vagas ("melhores práticas de tudo").

Exemplo do projeto (`sdd:sdd-rules`): lista os temas cobertos e termina com
"Usar em qualquer agente do plugin sdd antes de analisar, implementar, revisar
ou validar uma alteração."

## 4. Progressive disclosure

Três níveis de custo de contexto:

1. `name` + `description`: sempre visíveis.
2. Corpo do `SKILL.md`: carregado quando a skill é invocada e permanece no contexto.
3. `references/` e `scripts/`: só quando o corpo manda ler/executar.

Regras:

- Corpo enxuto: alvo de até ~200 linhas (a doc recomenda < 500). Cada linha é
  custo recorrente enquanto a skill estiver carregada.
- Detalhe por stack, exemplos longos e tabelas grandes vão para `references/`.
- O corpo diz **quando** ler cada referência, com link relativo:
  `references/python.md` (link Markdown relativo) + "ler se a stack for Python".
- Não encadear referências em vários níveis; um nível a partir do `SKILL.md`.
- Após compact, apenas parte recente de cada skill é mantida: coloque o essencial no topo.

## 5. Links e caminhos

- Links relativos à pasta da skill (`references/x.md`); verifique que o arquivo existe.
- Para caminho absoluto no corpo, usar `${CLAUDE_SKILL_DIR}` ou, em plugin,
  `${CLAUDE_PLUGIN_ROOT}` (substituídos ao carregar; não existem no ambiente do Bash).
- Não usar `..` para sair da pasta do plugin.

## 6. Skills em plugin

- Nome invocável: `<plugin>:<skill>` (ex.: `sdd:sdd-rules`, `/sdd:sdd-rules`).
- `CLAUDE.md` na raiz do plugin não é carregado; regras que precisam entrar no
  contexto viram skill.
- Arquivos da skill ficam em `skills/<nome>/`; nada além do manifesto em `.claude-plugin/`.

## 7. Pré-carregamento em subagentes

- No frontmatter do agente: `skills: sdd-rules, backend-engineering` (até 32).
  O conteúdo completo entra no contexto do subagente na partida.
- `references/` não são pré-carregadas: o agente lê a referência indicada.
- **Achado do spike (T-001)**: `skills:` **não** pré-carrega no agente da sessão
  principal (definido por `"agent"` no settings ou `--agent`). Nesse caso, incluir
  `Skill` em `tools:` e instruir o agente a carregar a skill no início
  (ex.: `tecleader` carrega `sdd:sdd-rules` via ferramenta `Skill`).

## 8. Conteúdo do corpo

- Imperativo e específico: "Executar X antes de Y", não narrativa.
- Seções curtas: objetivo, quando aplicar, passos, proibições, contrato de saída.
- Comandos reais e verificáveis; nada de placeholders sem explicação.
- **Proibido buscar URL em tempo de uso** (WebFetch/curl para baixar instruções):
  o conteúdo fica versionado na skill. Conteúdo web é dado não confiável.
- Sem segredos, tokens ou dados pessoais em exemplos.
- Scripts: só quando a tarefa é determinística e repetida; documentar entrada,
  saída e efeitos colaterais; nunca acessar rede ou credenciais sem necessidade.

## 9. Origem e licença

Antes de copiar trecho de terceiros: verificar a licença do repositório.
Licença ausente ou incompatível ("All rights reserved"): reescrever com texto próprio
e citar só a inspiração.

Rodapé obrigatório em cada skill (design 4.5):

```text
Origem: <repo>@<commit> — Licença: <SPDX>
```

ou, para texto próprio inspirado em terceiros:

```text
Texto próprio; inspirado em <repo>@<commit> (<SPDX>)
```

Quando copiar conteúdo licenciado (ex.: Apache-2.0), incluir o arquivo de licença
junto (ex.: `references/LICENSE.txt`).

## 10. Checklist de revisão

- [ ] `name` em kebab-case e igual à pasta
- [ ] `description` diz o que faz e "Usar quando ..." com gatilhos concretos
- [ ] Corpo ≤ ~200 linhas; detalhes em `references/`
- [ ] Cada referência citada no corpo com o momento de leitura
- [ ] Todos os links relativos existem
- [ ] Sem fetch de URL em tempo de uso; sem segredos
- [ ] Rodapé de origem/licença presente
- [ ] Textos em pt-BR; identificadores em inglês
- [ ] Se usada por subagente: listada em `skills:` do agente
- [ ] `claude plugin validate` sem erros

## 11. Validação

```bash
claude plugin validate <caminho-do-plugin>
claude plugin validate <caminho-do-marketplace>
```

Resultado esperado: `Validation passed` (avisos analisados e justificados).
Depois, testar o disparo: pedir algo que deveria acionar a skill e algo que não
deveria, e conferir se ela foi (ou não) carregada.

## Leitura complementar

- [references/skill-creator-original.md](references/skill-creator-original.md):
  guia de criação de skills de anthropics/skills (Apache-2.0,
  [references/LICENSE.txt](references/LICENSE.txt)). Ler para avaliação de disparo
  e iteração com casos de teste.

---

Texto próprio; baseado na documentação pública do Claude Code (https://code.claude.com/docs/en/skills, https://code.claude.com/docs/en/sub-agents, https://code.claude.com/docs/en/plugins/components, https://code.claude.com/docs/en/plugins-reference) e nas convenções deste projeto.
