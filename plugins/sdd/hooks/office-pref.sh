#!/usr/bin/env bash
# sdd: preferência da "salinha dos agentes" (REQ-001; .specs/done/agents-office/design.md 5.3 e 5.4).
# Uso: office-pref.sh on|off|status   (sem argumento = status; qualquer outro valor: uso e exit 2).
# Única escrita permitida: a constante "on" ou "off" em ${CLAUDE_CONFIG_DIR:-$HOME/.claude}/sdd/office.conf.
# Sem rede, sem eval, nada vindo do chamador além de HOME/CLAUDE_CONFIG_DIR/CLAUDE_PROJECT_DIR/TMPDIR.
# "status" também é usado como hook síncrono de SessionStart (diagnóstico lido pelo TecLeader): sempre exit 0.

# Confiança no ambiente: CLAUDE_CONFIG_DIR (e HOME) vêm do ambiente do usuário/CLI, não de conteúdo de projeto; é onde
# fica a preferência office.conf (o script só lê/grava a constante on|off nele).

LC_ALL=C
export LC_ALL
umask 077

cmd="${1:-status}"
case "$cmd" in
  on|off|status) ;;
  *) printf '%s\n' "uso: office-pref.sh on|off|status"; exit 2 ;;
esac

cfgdir="${CLAUDE_CONFIG_DIR:-${HOME:-}/.claude}/sdd"
cfg="$cfgdir/office.conf"

# Ausente = nunca perguntado (unset). Só a primeira linha exatamente "on" liga; o resto é desligado.
pref=unset
if [ -f "$cfg" ]; then
  p=""
  { IFS= read -r p < "$cfg"; } 2>/dev/null
  if [ "$p" = on ]; then pref=on; else pref=off; fi
fi

if [ "$cmd" = status ]; then
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
  room=no
  # TMPDIR só vale se absoluto (senão /tmp); pasta por usuário (sdd-office-<uid>) para não colidir em /tmp compartilhado.
  case "${TMPDIR:-}" in /*|[A-Za-z]:[/\\]*) base="$TMPDIR" ;; *) base="/tmp" ;; esac
  base="${base%/}"
  office_root="$base/sdd-office-${UID:-0}"
  [ -d "$office_root/$id" ] && room=yes
  printf '%s\n' "[sdd:office] pref=$pref room=$room"
  exit 0
fi

# on|off: grava a constante de forma atômica (tmp + mv).
if ! mkdir -p -m 700 "$cfgdir" 2>/dev/null; then
  printf '%s\n' "[sdd:office] erro=nao_foi_possivel_gravar_a_preferencia"
  exit 1
fi
tmp="$cfg.tmp.$$"
if ! { printf '%s\n' "$cmd" > "$tmp" && mv -f "$tmp" "$cfg"; } 2>/dev/null; then
  rm -f "$tmp" 2>/dev/null
  printf '%s\n' "[sdd:office] erro=nao_foi_possivel_gravar_a_preferencia"
  exit 1
fi
printf '%s\n' "[sdd:office] pref=$cmd"

# "on" tenta abrir a tela agora (decisão D6), com a mesma proteção de falha do hook de início.
if [ "$cmd" = on ]; then
  self="${BASH_SOURCE[0]}"
  case "$self" in */*) sdir="${self%/*}" ;; *) sdir="." ;; esac
  bash "$sdir/office-start.sh" --now 2>/dev/null
fi
exit 0
