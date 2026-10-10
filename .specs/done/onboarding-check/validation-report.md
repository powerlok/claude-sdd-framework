# Relatório de validação: onboarding-check (T-003)

Data: 2026-10-10. Agente: tests. Método: pilotos `claude -p "olá" --plugin-dir plugins/sdd --agent sdd:tecleader --allowedTools "Read,Glob,Grep" --output-format stream-json --verbose`, em 4 projetos git descartáveis (scratchpad).

| Cenário | Esperado | Obtido | Status |
|---|---|---|---|
| A vazio (REQ-001/002) | hook `[sdd:onboarding]` coerente; pergunta stack/convenções | `claude_md=no stack=no specs_index=no empty=yes manifests=none`; "Esta pasta está vazia... preciso saber como você quer montar o projeto" + perguntas de stack/convenções; "não vou criar nada sem a sua confirmação" | VALIDADO |
| B código sem CLAUDE.md | oferece onboarding, explica o que lê/cria | `claude_md=no ... empty=no manifests=package.json`; "Onboarding pendente"; lista o que lê e o que cria (`CLAUDE.md` com `## Stack`, `.specs/INDEX.md`); "Quer que eu faça o onboarding?" | VALIDADO |
| C CLAUDE.md sem Stack | não sobrescreve; propõe o que falta citando manifesto | `claude_md=yes stack=no specs_index=no manifests=App.csproj`; "sem sobrescrever o seu CLAUDE.md, só acrescentando"; cita `App.csproj` e a falta do INDEX | VALIDADO |
| D pronto | 1 linha de status com feature `login` e segue | `claude_md=yes stack=yes specs_index=yes manifests=pyproject.toml`; "Status: o onboarding está ok (... Python 3.12 e pytest ...). Há uma feature ativa, **login**." + "Em que posso ajudar?" | VALIDADO |
| E tarefa direta em B (REQ-003) | aviso de pendência em ~1 linha; não implementa; sem Write/Edit | "Onboarding pendente: ... não tem CLAUDE.md ... não posso implementar nada até isso existir. Não criei nem alterei nenhum arquivo."; zero Write/Edit; só Read/Glob | VALIDADO (obs. 1) |
| REQ-003 nada alterado | `git status --porcelain` vazio; sem Write/Edit/Bash | vazio em A, B, C, D; nenhum Write/Edit/Bash em A-E | VALIDADO |
| F fallback REQ-004 (B, `--settings {"disableAllHooks":true}`) | sem hook; tecleader detecta falta do CLAUDE.md por conta própria | nenhum evento de hook; tecleader usou `ls -A`, Read e Glob e respondeu "Não há CLAUDE.md na raiz. Não há .specs/INDEX.md" e ofereceu onboarding | VALIDADO (obs. 2) |

## Observações (não bloqueantes)

1. E: após o aviso, o agente fez 3 perguntas longas (servidor HTTP, Node/teste, resposta do /health), bem mais que "1 linha". Comportamento seguro (não implementou), mas verboso frente ao REQ-003 ("avisar em 1 linha"). Sugestão ao tecleader: avaliar se isso é aceitável ou se o agente deve ser mais sucinto.
2. F: o agente usou a ferramenta Bash (`ls -A`, somente leitura) apesar de `--allowedTools "Read,Glob,Grep"`; essa lista é de pré-aprovação, não restrição, e o modo automático permitiu. Não houve escrita. O fallback pede Read/Glob; o uso de Bash é desvio menor.
3. O hook emitiu texto com acentos em formato que aparece corrompido na saída do console Windows (cp1252); no JSON o conteúdo é coerente. Não afetou o comportamento.

Classificação geral: nenhum defeito. Revisão de segurança do script e `claude plugin validate` não foram executados aqui.
