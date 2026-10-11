#!/usr/bin/env bash
# REQ-001 (D-001): office-pref.sh status pelo Bash tool (CLAUDE_PROJECT_DIR vazio, PWD em 8.3 ou em subpasta) tem de achar a
# MESMA sala que os hooks (CLAUDE_PROJECT_DIR em caminho longo). Nada toca ~/.claude real (sandbox).
. "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"
new_sandbox
EV="$HOOKS_DIR/office-event.sh"; P="$HOOKS_DIR/office-pref.sh"
printf 'on\n' > "$CLAUDE_CONFIG_DIR/sdd/office.conf"
proj="$SB/proj"; mkdir -p "$proj/.claude" "$proj/pkg/sub" "$SB/other/sub"
printf '{}\n' > "$proj/.claude/settings.json"
long="$proj"; command -v cygpath >/dev/null 2>&1 && long="$(cygpath -ml "$proj")"
stop_in() { CLAUDE_PROJECT_DIR="$1" bash -c 'printf "%s" "{\"hook_event_name\":\"Stop\"}" | bash "$1"' _ "$EV"; }
# Hook real: CLAUDE_PROJECT_DIR em caminho longo cria a sala.
stop_in "$long"
eq "req001 hook cria 1 sala" "1" "$(ls "$TMPDIR/sdd-office-$UID" | wc -l | tr -d ' ')"
st() { ( unset CLAUDE_PROJECT_DIR; cd "$1" && bash "$P" status ); }
eq "req001 status na raiz sem CLAUDE_PROJECT_DIR = room=yes" "[sdd:office] pref=on room=yes" "$(st "$proj")"
eq "req001 status em subpasta (sobe até .claude/settings.json) = room=yes" "[sdd:office] pref=on room=yes" "$(st "$proj/pkg/sub")"
out="$( cd "$proj/pkg" && CLAUDE_PROJECT_DIR= bash "$P" status )"
eq "req001 CLAUDE_PROJECT_DIR vazio (como no Bash tool) = room=yes" "[sdd:office] pref=on room=yes" "$out"
eq "req001 outro projeto = room=no" "[sdd:office] pref=on room=no" "$(st "$SB/other/sub")"
# Forma 8.3 (só quando o sistema a oferece): PWD curto + subpasta.
if command -v cygpath >/dev/null 2>&1; then
  short="$(cygpath -u "$(cygpath -d "$proj/pkg/sub")")"
  case "$short" in
    *~*) eq "req001 PWD 8.3 [$short] em subpasta = room=yes" "[sdd:office] pref=on room=yes" "$(st "$short")" ;;
    *) ok "req001 (sem forma 8.3 neste caminho: ignorado)" ;;
  esac
fi
# Raiz por .git (sem .claude): monorepo = marcador mais próximo vence.
mkdir -p "$SB/g/.git" "$SB/g/a/b"; gl="$SB/g"; command -v cygpath >/dev/null 2>&1 && gl="$(cygpath -ml "$SB/g")"
stop_in "$gl"
eq "req001 subpasta de repo git (.git) = sala da raiz" "[sdd:office] pref=on room=yes" "$(st "$SB/g/a/b")"
# Desligado: status não grava nada (preferência e pastas).
printf 'off\n' > "$CLAUDE_CONFIG_DIR/sdd/office.conf"
before="$(ls -R "$SB/tmp" "$CLAUDE_CONFIG_DIR" | md5sum)"
st "$proj/pkg" >/dev/null
eq "req001 status desligado não grava nada" "$before" "$(ls -R "$SB/tmp" "$CLAUDE_CONFIG_DIR" | md5sum)"
drop_sandbox
finish
