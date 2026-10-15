# Spec: guarda de merge e push forçado como hook do plugin (`sdd` 0.12.0)

Pedido do usuário (2026-10-14): "pesquise o que realmente vale restringir, veja documentações e deixe o resto como pergunta para o usuário" → "sim" (hook de proteção do merge).
Relacionada a: done/spec-pr-flow, done/relax-deny.

## Base na documentação (code.claude.com/docs: permissions, permission-modes, sandboxing, security; verificado em 2026-10-14)

- `deny` vale em todos os modos (inclusive `bypassPermissions`); `ask` não vale sem terminal (`claude -p`) e em `bypassPermissions` só o `ask` explícito pergunta.
- Regras `Bash(...)` casam o texto do comando: `Bash(git push *)` não pega `git -C . push` nem `sh -c '...'`; a doc diz que não é fronteira de segurança e recomenda hook `PreToolUse`
  quando se quer garantia. Hook com exit 2 bloqueia a chamada antes das regras, em qualquer modo.
- O sandbox não existe no Windows nativo: ali as permissões são a única barreira.
- Hoje o merge ("o merge é sempre do usuário") só está protegido por `deny` nos settings do projeto, que o projeto precisa copiar e que `sh -c`/caminho absoluto contornam.

## Requisitos

- **REQ-001**: o plugin traz o hook `hooks/merge-guard.sh` (`PreToolUse`, matcher `Bash`, síncrono, timeout 5) que lê o JSON do stdin e, se o comando contém merge de PR (`gh pr merge`,
  `glab mr merge|accept`, `az repos pr update`, `gh|glab api` com `merge`) ou `git push` forçado/destrutivo (`--force*`, `-f`, `--mirror`, `--delete`, `-d`, `+ref`, `:ref`), responde exit 2 com
  mensagem constante em stderr. Reconhece o comando também dentro de `sh -c '...'`, `bash -c`, `$(...)`, depois de `;`, `&&`, `||`, `|`, com caminho absoluto (`/usr/bin/gh`) e `.exe`.
- **REQ-002**: não bloqueia o fluxo normal: `gh pr create`, `gh pr view|list|checks`, `git push -u origin feat/x`, `git push origin dev`, `git commit`, etc. Falha aberta (exit 0) com stdin vazio.
- **REQ-003**: só builtins do bash (sem rede, sem `eval`, sem escrever); funciona no bash 3.2 do macOS e no Git Bash; a mensagem não repete o comando.
- **REQ-004**: limites declarados: variável/`eval`/base64/script externo escapam (o hook não é sandbox); comando que apenas cita o texto (ex.: mensagem de commit com `gh pr merge`) pode ser bloqueado e deve ser
  reformulado. O `deny` dos modelos de settings continua como segunda camada.
- **REQ-005**: teste `req013-mergeguard.test.sh` (bloqueios, liberações, `hooks.json`), CI nos 3 sistemas, docs (README, manual, skill `vcs-delivery`), CHANGELOG, `sdd` 0.12.0.
