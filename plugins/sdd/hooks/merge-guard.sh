#!/usr/bin/env bash
# sdd: guarda de merge e push forçado (PreToolUse, matcher "Bash"). .specs/merge-guard/spec.md
# "O merge é sempre do usuário": bloqueia (exit 2) o comando que faria merge de PR ou push forçado/destrutivo, em qualquer modo de
# permissão e também dentro de sh -c, $(...), depois de ; && || | e com caminho absoluto (o que Bash(...) em deny não pega).
# Não é sandbox: variável, eval, base64 ou script externo escapam; o deny dos settings continua como segunda camada.
# Só builtins (sem rede, sem eval, sem escrever); falha aberta (exit 0) sem stdin. bash 3.2 (macOS) e Git Bash.

LC_ALL=C
export LC_ALL

in="$(head -c 65536 2>/dev/null)"
[ -n "$in" ] || exit 0

# Escapes do JSON viram separador de comando/aspas para os padrões enxergarem o comando como o shell o veria.
bs='\'
t="${in//"$bs"n/ ; }"
t="${t//"$bs"r/ }"
t="${t//"$bs"t/ }"
t="${t//"$bs\""/\"}"

b='(^|[^A-Za-z0-9_.-])'      # antes do programa: início ou qualquer separador/aspas/barra
s='[[:space:]]'
a='[^;&|]*'                  # argumentos do mesmo comando (não cruza ; & |)
e='([^A-Za-z0-9_-]|$)'

m() { [[ $1 =~ $2 ]]; }   # regex sempre em variável (bash 3.2)

shopt -s nocasematch
hit=""
m "$t" "${b}gh(\.exe)?${s}+(${a}${s}+)?pr${s}+merge${e}" && hit=1
m "$t" "${b}glab(\.exe)?${s}+(${a}${s}+)?mr${s}+(merge|accept)${e}" && hit=1
m "$t" "${b}az(\.cmd|\.exe)?${s}+(${a}${s}+)?repos${s}+pr${s}+update${e}" && hit=1
m "$t" "${b}(gh|glab)(\.exe)?${s}+(${a}${s}+)?api${s}+${a}merge" && hit=1
if m "$t" "${b}git(\.exe)?${s}+(${a}${s}+)?push(${s}${a})?(\$|[^A-Za-z0-9_.-])"; then
  # depois do "push", no mesmo comando: --force*, --mirror, --delete, -f/-d (inclusive em grupo, ex. -fu), +ref ou :ref.
  seg="${BASH_REMATCH[4]}"
  seg="$seg "
  m "$seg" "${s}(--force|--mirror|--delete)" && hit=1
  m "$seg" "${s}-[A-Za-z]*[fd][A-Za-z]*([^A-Za-z0-9_-]|\$)" && hit=1
  m "$seg" "${s}\+[^[:space:]]" && hit=1
  m "$seg" "${s}:[A-Za-z0-9_./-]" && hit=1
fi
shopt -u nocasematch

if [ -n "$hit" ]; then
  echo "sdd: bloqueado. Merge de PR e push forcado/destrutivo sao do usuario (regra do processo SDD). Pare na abertura do PR e entregue a URL; o usuario faz o merge. Se este comando apenas cita o texto (ex.: mensagem de commit), reescreva sem o comando literal." >&2
  exit 2
fi
exit 0
