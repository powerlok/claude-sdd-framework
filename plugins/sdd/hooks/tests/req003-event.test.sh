#!/usr/bin/env bash
# REQ-003 (eventos): office-event.sh desligado sai sem ler stdin nem criar nada; ligado grava 1 linha por evento.
. "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"
new_sandbox
EV="$HOOKS_DIR/office-event.sh"
cfg="$CLAUDE_CONFIG_DIR/sdd/office.conf"
fire() { printf '%s' "$1" | bash "$EV"; }
nlines() { wc -l < "$1" | tr -d ' '; }

# 1) desligado (unset e off): nenhum arquivo, nenhuma pasta, stdout vazio, exit 0, e NÃO lê o stdin.
J='{"hook_event_name":"PreToolUse","tool_name":"Bash","tool_input":{"command":"ls"}}'
for state in unset off; do
  [ "$state" = off ] && printf 'off\n' > "$cfg"
  out="$(fire "$J")"; rc=$?
  eq "req003 $state: exit 0" "0" "$rc"; eq "req003 $state: stdout vazio" "" "$out"
  check "req003 $state: nada criado no tmp" test -z "$(ls "$TMPDIR")"
done
start=$(date +%s)
timeout 5 bash "$EV" < <(sleep 4)
rc=$?; el=$(( $(date +%s) - start ))
eq "req003 desligado não bloqueia no stdin (exit 0)" "0" "$rc"
check "req003 desligado não espera o stdin (< 3 s)" test "$el" -lt 3

# 2) ligado: um evento por hook.
printf 'on\n' > "$cfg"
fire '{"session_id":"s","hook_event_name":"SubagentStart","agent_id":"ab12cd34ef56gh78","agent_type":"sdd:backend"}'
room="$(room_dir)"; f="$room/events.js"
check "req003 ligado cria events.js" test -f "$f"
eq "req003 SubagentStart: 1 linha" "1" "$(nlines "$f")"
check "req003 SubagentStart: e=start a=backend d truncado em 12" grep -q '"e":"start","a":"backend","d":"ab12cd34ef56"' "$f"
fire '{"hook_event_name":"SubagentStop","agent_id":"ab12cd34ef56gh78","agent_type":"sdd:backend","last_assistant_message":"conteudo longo"}'
check "req003 SubagentStop: e=stop" grep -q '"e":"stop","a":"backend"' "$f"
fire '{"hook_event_name":"UserPromptSubmit","prompt":"faça algo secreto"}'
check "req003 UserPromptSubmit: e=prompt sem agente" grep -q '"e":"prompt","a":"","d":""' "$f"
fire '{"hook_event_name":"Stop","stop_hook_active":false}'
check "req003 Stop: e=end" grep -q '"e":"end"' "$f"
eq "req003 4 eventos = 4 linhas" "4" "$(nlines "$f")"

# 3) categorias de ferramenta (nunca o nome bruto).
declare -A CAT=( [Read]=read [Grep]=read [Glob]=read [Edit]=edit [Write]=edit [MultiEdit]=edit [Bash]=run [WebFetch]=web
  [WebSearch]=web [Agent]=delegate [Task]=delegate [TodoWrite]=plan [AskUserQuestion]=ask [mcp__github__get_me]=mcp [Skill]=other [Xyz]=other )
for tool in "${!CAT[@]}"; do
  : > "$f"
  fire '{"hook_event_name":"PreToolUse","agent_type":"sdd:tests","tool_name":"'"$tool"'","tool_input":{}}'
  check "req003 ferramenta $tool => k=${CAT[$tool]}" grep -q "\"e\":\"tool\",\"a\":\"tests\",\"d\":\"\",\"k\":\"${CAT[$tool]}\"" "$f"
    check "req003 ferramenta $tool: nome bruto não gravado" bash -c '! grep -q "\"$1\"" "$2"' _ "$tool" "$f"
done

# 4) entradas inválidas: exit 0, stdout vazio, nada gravado.
: > "$f"
for junk in "" "lixo" "{" '{"hook_event_name":"Outro"}' '{"hook_event_name":"PreToolUse'; do
  out="$(printf '%s' "$junk" | bash "$EV")"; rc=$?
  eq "req003 entrada [$junk]: exit 0 e stdout vazio" "0|" "$rc|$out"
done
# O evento truncado acima não tem tool_name: vira k=other (válido); só exigimos que nada quebre.
out="$(head -c 300000 /dev/urandom | bash "$EV")"; rc=$?
eq "req003 binário aleatório: exit 0 e stdout vazio" "0|" "$rc|$out"
out="$( (printf '{"hook_event_name":"PreToolUse","tool_name":"Read","tool_input":{"x":"'; head -c 300000 /dev/zero | tr '\0' 'a'; printf '"}}') | bash "$EV")"; rc=$?
eq "req003 entrada de 300 KB: exit 0 e stdout vazio" "0|" "$rc|$out"

# 5) rotação: arquivo grande é reduzido a ~200 linhas em stop/start.
: > "$f"
for i in $(seq 1 450); do echo "E({\"i\":\"$i\",\"t\":1,\"e\":\"tool\",\"a\":\"\",\"d\":\"\",\"k\":\"read\",\"m\":\"\",\"g\":\"\"});"; done > "$f"
fire '{"hook_event_name":"SubagentStop","agent_id":"x1","agent_type":"sdd:tests"}'
n="$(nlines "$f")"
check "req003 rotação: <= 201 linhas após stop" test "$n" -le 201
check "req003 rotação: mantém as mais recentes" grep -q '"e":"stop"' "$f"
check "req003 rotação: nenhum tmp sobrando" test -z "$(ls "$room" | grep '\.tmp')"

# 6) mesma pasta de sala que o start e o pref (id idêntico nos três scripts).
rm -rf "$TMPDIR"/sdd-office-$UID; mkdir -p "$TMPDIR"
export SDD_OFFICE_OS=linux; unset DISPLAY WAYLAND_DISPLAY
bash "$HOOKS_DIR/office-start.sh" >/dev/null
fire '{"hook_event_name":"Stop"}'
eq "req003 start e event usam 1 única pasta de sala" "1" "$(ls "$TMPDIR/sdd-office-$UID" | wc -l | tr -d ' ')"
check "req003 pref status enxerga a sala (room=yes)" bash -c 'bash "$1" status | grep -q "room=yes"' _ "$HOOKS_DIR/office-pref.sh"
# Caminho do Windows (C:\...) e Unix (/c/...) do mesmo projeto caem na mesma sala.
CLAUDE_PROJECT_DIR='C:\fake\projeto' bash -c 'printf "%s" "{\"hook_event_name\":\"Stop\"}" | bash "$1"' _ "$EV"
eq "req003 C:\... e /c/... = mesma sala" "1" "$(ls "$TMPDIR/sdd-office-$UID" | wc -l | tr -d ' ')"
CLAUDE_PROJECT_DIR='/c/outro/projeto' bash -c 'printf "%s" "{\"hook_event_name\":\"Stop\"}" | bash "$1"' _ "$EV"
eq "req003 outro projeto = outra sala" "2" "$(ls "$TMPDIR/sdd-office-$UID" | wc -l | tr -d ' ')"
# Sem CLAUDE_PROJECT_DIR usa o PWD.
( unset CLAUDE_PROJECT_DIR; cd "$SB" && printf '%s' '{"hook_event_name":"Stop"}' | bash "$EV" )
eq "req003 sem CLAUDE_PROJECT_DIR usa PWD (3 salas)" "3" "$(ls "$TMPDIR/sdd-office-$UID" | wc -l | tr -d ' ')"

# 7) hooks.json: eventos da salinha registrados, assíncronos, sem PostToolUse; onboarding intacto e síncrono.
J="$HOOKS_DIR/hooks.json"
res="$(node -e '
const h=require(process.argv[1]).hooks, want={SubagentStart:null,SubagentStop:null,PreToolUse:"*",UserPromptSubmit:null,Stop:null};
let bad=[];
for(const [ev,m] of Object.entries(want)){
  const bl=(h[ev]||[]).filter(b=>b.hooks.some(x=>/office-event\.sh/.test(x.command)));
  if(bl.length!==1){bad.push("falta "+ev);continue;}
  if((bl[0].matcher||null)!==m) bad.push("matcher "+ev);
  if(!bl[0].hooks.every(x=>x.async===true&&x.type==="command"&&x.timeout===5)) bad.push("async "+ev);
}
if(h.PostToolUse) bad.push("PostToolUse registrado");
const ob=h.SessionStart.find(b=>b.hooks.some(x=>/onboarding-check/.test(x.command)));
if(!ob||ob.hooks[0].async||ob.matcher!=="startup"||ob.hooks[0].timeout!==10) bad.push("onboarding alterado");
if(!h.SessionStart.some(b=>b.matcher==="compact")) bad.push("compact removido");
console.log(bad.length?bad.join(","):"ok");' "$J")"
eq "req003 hooks.json: 5 eventos async, sem PostToolUse, existentes intactos" "ok" "$res"
drop_sandbox
finish
