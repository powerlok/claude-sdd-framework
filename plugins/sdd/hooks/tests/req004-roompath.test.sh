#!/usr/bin/env bash
# REQ-004/REQ-001 (N1/N2): a resolução da raiz do projeto nunca vaza caminho para o events.js (nem por "d"), toda linha
# casa regex estrita, e HOME (8.3, maiúsculas) nunca é aceito como raiz. Sandbox: nada toca ~/.claude real.
. "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"
new_sandbox
EV="$HOOKS_DIR/office-event.sh"
printf 'on\n' > "$CLAUDE_CONFIG_DIR/sdd/office.conf"
STRICT='^E\(\{"i":"[0-9-]{1,24}","t":[0-9]{1,12},"e":"(start|stop|tool|prompt|end)","a":"[A-Za-z0-9_.-]{0,32}","d":"[A-Za-z0-9]{0,12}","k":"(read|edit|run|web|delegate|plan|ask|mcp|other)?","m":"[^"\<>]{0,80}","g":"[A-Za-z0-9_.-]{0,32}"\}\);$'
strict_all() { local l n=0; while IFS= read -r l; do n=$((n + 1)); [[ $l =~ $STRICT ]] || return 1; done < "$1"; [ "$n" -gt 0 ]; }

# N1: PWD com aspas + .git + cygpath falhando + CLAUDE_PROJECT_DIR vazio.
bin="$SB/bin"; mkdir -p "$bin"; printf '#!/bin/sh\nexit 1\n' > "$bin/cygpath"; chmod +x "$bin/cygpath"
evil="$SB"'/pro"j);alert(1);//'; mkdir -p "$evil/.git/sub" "$evil/sub"
run_evil() { ( cd "$evil/sub" && CLAUDE_PROJECT_DIR= PATH="$bin:$PATH" bash -c 'printf "%s" "$1" | bash "$2"' _ "$1" "$EV" ); }
run_evil '{"hook_event_name":"SubagentStart","agent_type":"sdd:backend","agent_id":"ab12cd34"}' 
run_evil '{"hook_event_name":"PreToolUse","tool_name":"Agent","agent_id":"ab12cd34","tool_input":{"description":"Revisar T-003","subagent_type":"sdd:security"}}'
run_evil '{"hook_event_name":"Stop"}'
f="$(room_dir)/events.js"
check "req004 N1 events.js criado" test -s "$f"
check "req004 N1 cada linha casa regex estrita" strict_all "$f"
check "req004 N1 nenhuma linha contém caminho/aspas do diretório" bash -c '! grep -qE "alert|pro\"j|/c/|[A-Za-z]:/|tmp" "$1"' _ "$f"
check "req004 N1 d do evento preservado" grep -q '"d":"ab12cd34"' "$f"
if command -v node >/dev/null 2>&1; then
  out="$(node -e '
    const vm=require("vm"),fs=require("fs");const calls=[];let bad=0;
    const ctx={E:(o)=>calls.push(Object.keys(o).join(","))};
    const sb=new Proxy(ctx,{has:()=>true,get:(t,k)=>{if(k===Symbol.unscopables)return undefined;if(k in t)return t[k];bad++;return undefined}});
    vm.runInContext(fs.readFileSync(process.argv[1],"utf8"),vm.createContext(sb));
    console.log(calls.length+" "+bad)' "$f" 2>&1)"
  eq "req004 N1 vm: só E() chamado, nada mais referenciado" "3 0" "$out"
fi

# N2: HOME (maiúsculas / 8.3) e ancestrais nunca são raiz. O sub não tem marcador; o HOME (e o pai) têm .git.
hm="$SB/home"; mkdir -p "$hm/.git" "$hm/work/sub"
want="$PWD"; [ -d "$hm/work/sub" ] && want="$hm/work/sub"
exp_len() { local w="$1"; command -v cygpath >/dev/null 2>&1 && w="$(cygpath -ml "$1")"; w="${w%/}"; printf '%s' "${#w}"; }
room_len() { local r; r="$(ls "$TMPDIR/sdd-office-$UID" 2>/dev/null | head -n 1)"; printf '%s' "${r##*-}"; rm -rf "$TMPDIR/sdd-office-$UID"; }
stop_home() { ( cd "$hm/work/sub" && CLAUDE_PROJECT_DIR= HOME="$1" bash -c 'printf "%s" "{\"hook_event_name\":\"Stop\"}" | bash "$1"' _ "$EV" ); }
rm -rf "$TMPDIR/sdd-office-$UID"
n="$(exp_len "$hm/work/sub")"
stop_home "$hm"; eq "req004 N2 HOME com .git não vira raiz (usa PWD)" "$n" "$(room_len)"
rmdir "$hm/.git"; mkdir -p "$SB/.git"
stop_home "$hm"; eq "req004 N2 ancestral de HOME (com .git) não vira raiz" "$n" "$(room_len)"
if command -v cygpath >/dev/null 2>&1; then
  up="$(cygpath -u "$(cygpath -ml "$hm" | tr 'a-z' 'A-Z')")"
  stop_home "$up"; eq "req004 N2 HOME em maiúsculas não vira raiz" "$n" "$(room_len)"
  short="$(cygpath -u "$(cygpath -d "$hm")")"
  case "$short" in
    *~*) stop_home "$short"; eq "req004 N2 HOME 8.3 [$short] não vira raiz" "$n" "$(room_len)" ;;
    *) ok "req004 N2 (sem forma 8.3 neste caminho: ignorado)" ;;
  esac
fi
drop_sandbox
finish
