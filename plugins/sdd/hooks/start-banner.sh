#!/usr/bin/env bash
# sdd: aviso de início de sessão (SessionStart, matcher "startup"). .specs/done/start-banner/spec.md
# O Claude Code só responde depois da primeira mensagem do usuário, e o diagnóstico de onboarding vai para o contexto do modelo
# (não aparece na tela). Este hook mostra ao usuário, via "systemMessage", o que fazer para começar.
# SOMENTE LEITURA: sem rede, sem escrita, sem eval, não executa o git nem nada do projeto; só testa existência de arquivos na raiz
# e lê CLAUDE.md com grep -q (nada é ecoado). A saída é UM objeto JSON com texto CONSTANTE: nenhum texto do projeto entra nela.
# As aspas do texto são tipográficas (“ ”): aspas ASCII exigiriam escape no JSON.
# Nunca aborta a sessão: sem "set -e", sempre "exit 0".

LC_ALL=C
export LC_ALL

dir="${CLAUDE_PROJECT_DIR:-$PWD}"
[ -d "$dir" ] || exit 0
base="${dir%/}"

ready=no
if [ -f "$base/CLAUDE.md" ] && [ ! -L "$base/CLAUDE.md" ] \
  && head -c 1048576 -- "$base/CLAUDE.md" 2>/dev/null | grep -q -- '^## Stack'; then
  ready=yes
fi

if [ "$ready" = yes ]; then
  msg="sdd: TechLead pronto. Digite /sdd:start para ver a situação do projeto e seguir os passos iniciais, ou escreva direto o que você precisa. A resposta deve começar com “Sou o TechLead”."
else
  msg="sdd: este projeto ainda não passou pelo onboarding. Digite /sdd:start: o TechLead mostra a situação do projeto e pergunta se pode fazer o onboarding (qualquer mensagem também funciona). A resposta deve começar com “Sou o TechLead”."
fi

printf '{"systemMessage":"%s"}\n' "$msg"
exit 0
