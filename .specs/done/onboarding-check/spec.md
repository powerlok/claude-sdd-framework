# Spec: verificação de onboarding no início da sessão

Pedido do usuário (2026-10-10): ao instalar o plugin num projeto (novo ou existente), o usuário deveria ser
perguntado sobre o onboarding, conforme exista ou não o `CLAUDE.md`. Proposta aprovada ("sim").
Limitação do Claude Code: o agente só responde após a primeira mensagem do usuário.

## Requisitos

- **REQ-001**: Hook `SessionStart` (matcher `startup`) do plugin executa um script **somente leitura** que verifica,
  no diretório do projeto: `CLAUDE.md` existe? tem `## Stack`? `.specs/INDEX.md` existe? pasta vazia? manifestos
  de stack presentes no nível raiz (ex.: package.json, angular.json, *.csproj, *.sln, pyproject.toml,
  requirements.txt, pom.xml, build.gradle, go.mod, Cargo.toml, *.tf) — e imprime um diagnóstico curto para o
  contexto da sessão. Sem rede, sem escrita, rápido (< 1 s típico), robusto a caminhos com espaço.
- **REQ-002**: Na **primeira resposta** da sessão, o `sdd:tecleader` trata o diagnóstico:
  | Situação | Comportamento |
  |---|---|
  | pasta vazia | pergunta stack/convenções; registra só o que o usuário informar |
  | código sem `CLAUDE.md` | oferece onboarding (explicar o que lê e o que cria) |
  | `CLAUDE.md` sem `## Stack` e/ou sem `.specs/INDEX.md` | não sobrescreve; propõe só o que falta, citando manifestos detectados |
  | tudo pronto | 1 linha de status (features ativas do INDEX) e segue o pedido |
- **REQ-003**: Nada é alterado sem confirmação; se o usuário recusar, não insistir na mesma sessão; se a primeira
  mensagem for uma tarefa, avisar o onboarding pendente em 1 linha (sem `## Stack` não implementa — regra existente).
- **REQ-004**: Se o hook não rodar (ex.: shell indisponível), o TecLeader faz a mesma verificação por conta própria
  com Read/Glob na primeira resposta (fallback).

## Critérios de aceite

- 4 cenários (vazio, código sem CLAUDE.md, CLAUDE.md sem Stack, pronto): primeira resposta conforme a tabela;
  nenhum arquivo criado/alterado sem confirmação.
- Script: somente leitura (revisão do `security`), JSON do hooks válido, `claude plugin validate` OK.

## Validação

Pilotos com `--plugin-dir` e `--agent sdd:tecleader` nos 4 cenários (prompt "olá"); conferência de que nada mudou
no disco; revisão do `security`.
