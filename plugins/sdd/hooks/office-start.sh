#!/usr/bin/env bash
# sdd: abertura automática da "salinha dos agentes" (REQ-002; .specs/done/agents-office/design.md 5.2 e R6/R8).
# Hook: SessionStart (matcher "startup", registrado com "async": true). Também chamado por "office-pref.sh on"
# com --now (abrir agora, ignorando a trava anti-duplicidade).
# Com a preferência "on": recria a pasta da sala em <tmp absoluto>/sdd-office-<uid>/<id>/ (modo 700), copia office.html,
# grava o evento de início e abre o navegador padrão em segundo plano (Windows: start; macOS: open; Linux: xdg-open).
# Falha ao abrir NUNCA interrompe a sessão: sem "set -e", sempre "exit 0". Sem rede, sem eval.
# stdout: apenas constantes. O caminho do projeto nunca é impresso nem gravado.
# SDD_OFFICE_OS (windows|darwin|linux) só escolhe entre os 3 ramos fixos abaixo (usado nos testes); não executa nada.

# Confiança no ambiente: CLAUDE_CONFIG_DIR (e HOME) vêm do ambiente do usuário/CLI, não de conteúdo de projeto; é onde
# fica a preferência office.conf (o script só lê/grava a constante on|off nele).

LC_ALL=C
export LC_ALL
umask 077

now_mode=no
[ "${1:-}" = "--now" ] && now_mode=yes

skip() {
  [ "$now_mode" = yes ] && printf '%s\n' "[sdd:office] open=skipped"
  exit 0
}

cfg="${CLAUDE_CONFIG_DIR:-${HOME:-}/.claude}/sdd/office.conf"
p=""
{ IFS= read -r p < "$cfg"; } 2>/dev/null
[ "$p" = on ] || skip

self="${BASH_SOURCE[0]}"
case "$self" in */*) sdir="${self%/*}" ;; *) sdir="." ;; esac
src="$sdir/../office/office.html"
[ -f "$src" ] || skip

# Id da sala = hash djb2 do caminho canônico do projeto (o caminho nunca é impresso nem gravado). Mesma regra nos 3 scripts.
# Com CLAUDE_PROJECT_DIR (hooks): usa-o. Sem ele (Bash tool do CLI, onde vem vazio) usa $PWD, que pode vir em forma 8.3
# (PAULO~1.LAR) ou em subpasta: no Windows normaliza para a forma longa (cygpath -ml, se existir) e sobe até a raiz do
# projeto = diretório mais próximo com .claude/settings.json, .claude/settings.local.json ou .git (monorepo: vence o
# mais próximo; nunca HOME nem acima; CLAUDE.md não serve de marcador porque existe também em subpastas).
norm_path() {
  NP="${1//\\//}"
  if [[ $NP =~ ^([A-Za-z]):/(.*)$ ]]; then
    local dv="${BASH_REMATCH[1]}" rest="${BASH_REMATCH[2]}" lc=abcdefghijklmnopqrstuvwxyz uc=ABCDEFGHIJKLMNOPQRSTUVWXYZ pre
    case "$dv" in [a-z]) pre="${lc%%$dv*}" ;; *) pre="${uc%%$dv*}" ;; esac
    NP="/${lc:${#pre}:1}/$rest"
  fi
  NP="${NP%/}"
}
# Resolve a raiz do projeto em PD (variáveis locais: nunca reutilizar nomes do chamador, p.ex. "d" = agent_id).
# HOME é normalizado como o PWD (cygpath -ml quando existe) e comparado sem diferenciar caixa nesse caso (Windows);
# o próprio HOME e qualquer ancestral dele nunca são aceitos como raiz.
resolve_dir() {
  PD="${CLAUDE_PROJECT_DIR:-}"
  if [ -n "$PD" ]; then norm_path "$PD"; PD="$NP"; return 0; fi
  local w="$PWD" hm="${HOME:-}" cur tmp ci=0
  if command -v cygpath >/dev/null 2>&1; then
    ci=1
    tmp="$(cygpath -ml "$PWD" 2>/dev/null)"; [ -n "$tmp" ] && w="$tmp"
    if [ -n "$hm" ]; then tmp="$(cygpath -ml "$hm" 2>/dev/null)"; [ -n "$tmp" ] && hm="$tmp"; fi
  fi
  norm_path "$w"; PD="$NP"; cur="$PD"
  norm_path "$hm"; hm="$NP"
  [ "$ci" -eq 1 ] && shopt -s nocasematch
  while [ -n "$cur" ]; do
    if [ -n "$hm" ] && { [[ $cur == "$hm" ]] || [[ $hm == "$cur"/* ]]; }; then break; fi
    if [ -f "$cur/.claude/settings.json" ] || [ -f "$cur/.claude/settings.local.json" ] || [ -e "$cur/.git" ]; then PD="$cur"; break; fi
    [ "$cur" = "${cur%/*}" ] && break; cur="${cur%/*}"
  done
  [ "$ci" -eq 1 ] && shopt -u nocasematch
  return 0
}
resolve_dir
dir="$PD"
# Hash djb2 em builtins (sem subprocesso: no Windows cada fork custa ~100 ms); id = <hash 32 bits>-<tamanho>.
h=5381; n=${#dir}
for ((i = 0; i < n; i++)); do printf -v c '%d' "'${dir:i:1}"; h=$(( (h * 33 + c) & 4294967295 )); done
id="$h-$n"
[[ $id =~ ^[0-9]+-[0-9]+$ ]] || id="0-0"

safe_dir() {
  [ -d "$1" ] || mkdir -m 700 "$1" 2>/dev/null
  [ -d "$1" ] && [ ! -L "$1" ] && [ -O "$1" ]
}
# TMPDIR só vale se absoluto (senão /tmp); pasta por usuário (sdd-office-<uid>) para não colidir em /tmp compartilhado.
case "${TMPDIR:-}" in /*|[A-Za-z]:[/\\]*) base="$TMPDIR" ;; *) base="/tmp" ;; esac
base="${base%/}"
office_root="$base/sdd-office-${UID:-0}"
room="$office_root/$id"
safe_dir "$office_root" && safe_dir "$room" || skip

if (( BASH_VERSINFO[0] > 4 || (BASH_VERSINFO[0] == 4 && BASH_VERSINFO[1] >= 2) )); then
  printf -v t '%(%s)T' -1
else
  t="$(date +%s)"
fi
[[ $t =~ ^[0-9]{1,12}$ ]] || skip

# Trava: sessões simultâneas no mesmo projeto não abrem abas duplicadas (< 15 s desde a última abertura).
lock="$room/opened"
if [ "$now_mode" = no ] && [ -f "$lock" ] && [ ! -L "$lock" ]; then
  last=""
  { read -r last < "$lock"; } 2>/dev/null
  if [[ $last =~ ^[0-9]{1,12}$ ]] && [ $((t - last)) -ge 0 ] && [ $((t - last)) -lt 15 ]; then
    exit 0
  fi
fi

[ -L "$room/events.js" ] && skip
[ -L "$room/office.html" ] && skip
: > "$room/events.js" 2>/dev/null
cp -f "$src" "$room/office.html" 2>/dev/null || skip
printf '%s\n' "E({\"i\":\"$t-$$-$RANDOM\",\"t\":$t,\"e\":\"start\",\"a\":\"\",\"d\":\"\",\"k\":\"\",\"m\":\"\",\"g\":\"\"});" >> "$room/events.js" 2>/dev/null
printf '%s\n' "$t" > "$lock" 2>/dev/null

page="$room/office.html"
# O caminho da página deve ser absoluto (nunca começar por "-" ou ser relativo) antes de ir ao navegador.
case "$page" in /*|[A-Za-z]:[/\\]*) ;; *) skip ;; esac
os="${SDD_OFFICE_OS:-$OSTYPE}"
opened=no
case "$os" in
  msys*|cygwin*|win32*|windows*)
    w="$page"
    if command -v cygpath >/dev/null 2>&1; then w="$(cygpath -m "$page" 2>/dev/null)"; fi
    # R8: caminho com caractere que o cmd.exe interpretaria (& % ^ etc.) => não abre (a pasta continua pronta).
    if [[ $w =~ ^[A-Za-z0-9_./:\ ~-]+$ ]]; then
      ( MSYS2_ARG_CONV_EXCL='*' cmd.exe /c start "" "$w" >/dev/null 2>&1 & )
      opened=yes
    fi
    ;;
  darwin*)
    ( open "$page" >/dev/null 2>&1 & )
    opened=yes
    ;;
  linux*|*bsd*)
    # Sem display (SSH, contêiner) não há o que abrir.
    if [ -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]; then
      ( xdg-open "$page" >/dev/null 2>&1 & )
      opened=yes
    fi
    ;;
esac

if [ "$opened" = yes ]; then
  printf '%s\n' "[sdd:office] open=attempted"
else
  printf '%s\n' "[sdd:office] open=skipped"
fi
exit 0
