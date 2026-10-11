---
name: office
description: Liga, desliga ou consulta a "salinha dos agentes" (tela no navegador com os agentes SDD trabalhando). Uso /sdd:office on, /sdd:office off ou /sdd:office status.
argument-hint: on|off|status
disable-model-invocation: true
---

# Salinha dos agentes

Preferência do usuário (fora do repositório, vale para todos os projetos): arquivo `office.conf` em
`${CLAUDE_CONFIG_DIR:-~/.claude}/sdd/`. Desligada por padrão.

## Execução

Executar somente este comando, com o argumento recebido (`on`, `off` ou `status`; se não houver argumento, usar `status`):

```bash
bash "${CLAUDE_PLUGIN_ROOT}/hooks/office-pref.sh" <argumento>
```

Rodar a partir da raiz do projeto (o Bash tool não define `CLAUDE_PROJECT_DIR`; o script então usa o diretório atual,
normaliza para a forma longa no Windows e sobe até a raiz com `.claude/settings.json` ou `.git`, para achar a mesma sala
dos hooks). Não passar nenhum outro valor (o script rejeita com `exit 2`) e não escrever em nenhum outro lugar.

## Resposta (pt-BR, curta)

- `on`: informar que a salinha abre sozinha no início das próximas sessões e que já tentei abri-la agora
  (se não abrir, o navegador pode estar indisponível; a sessão não é afetada).
- `off`: informar que a salinha não abre mais e que nenhum evento é gravado.
- `status`: dizer se está ligada, desligada ou nunca configurada (`unset`) e se há sala ativa neste projeto.
- Lembrar que a tela mostra só o tipo de atividade (nunca comandos, arquivos ou conteúdo).
