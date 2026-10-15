#!/usr/bin/env bash
# REQ-002 (abertura automática): office-start.sh com stubs de cmd.exe/open/xdg-open no PATH (nada abre de verdade).
. "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"
new_sandbox
S="$HOOKS_DIR/office-start.sh"
STUBS="$SB/stubs"; LOG="$SB/open.log"
mkdir -p "$STUBS"
for n in cmd.exe open xdg-open; do
  cat > "$STUBS/$n" <<'STUB'
#!/usr/bin/env bash
{ printf '%s|' "NAME"; for a in "$@"; do printf '[%s]' "$a"; done; printf '\n'; } >> "LOGFILE"
exit ${STUB_RC:-0}
STUB
  sed "s|NAME|$n|; s|LOGFILE|$LOG|" "$STUBS/$n" > "$STUBS/$n.tmp" && mv "$STUBS/$n.tmp" "$STUBS/$n"  # sed -i difere no macOS (BSD)
  chmod +x "$STUBS/$n"
done
export PATH="$STUBS:$PATH"
cfg="$CLAUDE_CONFIG_DIR/sdd/office.conf"
calls() { [ -f "$LOG" ] && wc -l < "$LOG" | tr -d ' ' || echo 0; }
# Vence a atividade da sala (opened antigo e último evento antigo): a próxima chamada abre de novo.
expire() { echo 1 > "$room/opened"; echo 'E({"i":"0-0-0","t":1,"e":"tool","a":"","d":"","k":"read","m":"","g":""});' > "$room/events.js"; }
waitlog() { local i; for i in $(seq 1 40); do [ -f "$LOG" ] && [ "$(wc -l < "$LOG" | tr -d " ")" -ge 1 ] && { sleep 0.2; return; }; sleep 0.25; done; }

# 1) unset e off: nada abre, nada é criado, stdout vazio, exit 0.
export SDD_OFFICE_OS=windows
out="$(bash "$S")"; rc=$?
eq "req002 unset: exit 0" "0" "$rc"; eq "req002 unset: stdout vazio" "" "$out"
check "req002 unset: nenhuma pasta criada" test -z "$(ls "$TMPDIR")"
printf 'off\n' > "$cfg"
out="$(bash "$S")"; rc=$?
eq "req002 off: exit 0" "0" "$rc"; eq "req002 off: stdout vazio" "" "$out"
check "req002 off: nenhuma pasta criada" test -z "$(ls "$TMPDIR")"
sleep 0.5; eq "req002 off: navegador chamado 0x" "0" "$(calls)"

# 2) on (Windows): chama cmd.exe 1x com start e o caminho de office.html; cria pasta, cópia e evento de início.
printf 'on\n' > "$cfg"
out="$(bash "$S")"; rc=$?
waitlog
eq "req002 on/windows: exit 0" "0" "$rc"
eq "req002 on/windows: stdout só constante" "[sdd:office] open=attempted" "$out"
eq "req002 on/windows: navegador chamado 1x" "1" "$(calls)"
check "req002 on/windows: args /c start \"\" caminho" grep -q '^cmd.exe|\[/c\]\[start\]\[\]\[.*sdd-office-[0-9]*/[0-9]*-[0-9]*/office.html\]$' "$LOG"
room="$(room_dir)"
check "req002 pasta da sala criada" test -d "$room"
check "req002 office.html copiado" cmp -s "$room/office.html" "$HOOKS_DIR/../office/office.html"
eq "req002 events.js tem 1 linha de início" "1" "$(wc -l < "$room/events.js" | tr -d ' ')"
check "req002 evento de início é e=start" grep -q '"e":"start"' "$room/events.js"
case "$(basename "$room")" in *fake*|*projeto*) bad "req002 id da sala vaza o caminho" ;; *) ok "req002 id da sala sem caminho" ;; esac
check "req002 id da sala é <digitos>-<digitos>" bash -c '[[ "$1" =~ ^[0-9]+-[0-9]+$ ]]' _ "$(basename "$room")"

# 3) sala ativa (opened recente): segunda chamada não abre outra aba nem apaga os eventos.
echo 'E({"i":"1-1-1","t":1,"e":"tool","a":"","d":"","k":"read","m":"","g":""});' >> "$room/events.js"
bash "$S" >/dev/null; sleep 0.5
eq "req002 trava: continua 1 chamada" "1" "$(calls)"
eq "req002 trava: events.js preservado" "2" "$(wc -l < "$room/events.js" | tr -d ' ')"
# 3b) sem atividade recente (opened e último evento antigos), abre de novo e recria events.js limpo.
expire
bash "$S" >/dev/null; sleep 0.7
eq "req002 sessão nova (sala parada): 2 chamadas" "2" "$(calls)"
eq "req002 sessão nova: events.js recriado (1 linha)" "1" "$(wc -l < "$room/events.js" | tr -d ' ')"
check "req002 sessão nova: evento antigo descartado" bash -c '! grep -q "\"t\":1," "$1"' _ "$room/events.js"
# 3c) --now ignora a atividade da sala.
out="$(bash "$S" --now)"; sleep 0.7
eq "req002 --now ignora a atividade: 3 chamadas" "3" "$(calls)"
# 3d) sala ativa só pelo último evento (opened antigo, evento de agora): não abre e preserva events.js.
echo 1 > "$room/opened"
now_s="$(date +%s)"
echo "E({\"i\":\"9-9-9\",\"t\":$now_s,\"e\":\"tool\",\"a\":\"backend\",\"d\":\"\",\"k\":\"edit\",\"m\":\"\",\"g\":\"\"});" >> "$room/events.js"
lines_before="$(wc -l < "$room/events.js" | tr -d ' ')"
bash "$S" >/dev/null; sleep 0.7
eq "req002 sala ativa por evento recente: não abre (continua 3)" "3" "$(calls)"
eq "req002 sala ativa por evento recente: events.js preservado" "$lines_before" "$(wc -l < "$room/events.js" | tr -d ' ')"
# 3e) atividade há mais de 30 min (opened e evento): abre.
old=$(( now_s - 1900 ))
echo "$old" > "$room/opened"
echo "E({\"i\":\"9-9-8\",\"t\":$old,\"e\":\"tool\",\"a\":\"\",\"d\":\"\",\"k\":\"read\",\"m\":\"\",\"g\":\"\"});" > "$room/events.js"
bash "$S" >/dev/null; sleep 0.7
eq "req002 atividade de 31 min: abre (4 chamadas)" "4" "$(calls)"
# 3f) opened ou events.js symlink não contam como atividade (nem derrubam o script).
expire
rm -f "$room/opened"; ln -s /nonexistent "$room/opened" 2>/dev/null
bash "$S" >/dev/null 2>&1; rc=$?
eq "req002 opened symlink: exit 0" "0" "$rc"
rm -f "$room/opened"

# 4) navegador que falha não derruba: exit 0.
expire
STUB_RC=1 bash "$S" >/dev/null 2>&1; rc=$?
eq "req002 navegador falha: exit 0" "0" "$rc"

# 5) macOS e Linux.
rm -f "$LOG"; expire
SDD_OFFICE_OS=darwin bash "$S" >/dev/null; waitlog
check "req002 darwin: open chamado" grep -q '^open|' "$LOG"
rm -f "$LOG"; expire
SDD_OFFICE_OS=linux DISPLAY=:0 bash "$S" >/dev/null; waitlog
check "req002 linux com DISPLAY: xdg-open chamado" grep -q '^xdg-open|' "$LOG"
rm -f "$LOG"; expire
out="$(unset DISPLAY WAYLAND_DISPLAY; SDD_OFFICE_OS=linux bash "$S")"; rc=$?; sleep 0.5
eq "req002 linux sem display: exit 0" "0" "$rc"
eq "req002 linux sem display: stdout constante" "[sdd:office] open=skipped" "$out"
check "req002 linux sem display: nada aberto" test ! -f "$LOG"

# 6) R8: caminho que o cmd.exe interpretaria (&) não é aberto; a sessão segue.
rm -f "$LOG"; expire
mkdir -p "$SB/t&x"
out="$(SDD_OFFICE_OS=windows TMPDIR="$SB/t&x" bash "$S")"; rc=$?; sleep 0.5
eq "req002 caminho com '&': exit 0" "0" "$rc"
check "req002 caminho com '&': navegador não chamado" test ! -f "$LOG"

# 7) hooks.json: office-start só em SessionStart/startup, assíncrono; nenhum matcher compact/resume.
J="$HOOKS_DIR/hooks.json"
res="$(node -e '
const h=require(process.argv[1]).hooks;let bad=[];
for(const [ev,blocks] of Object.entries(h)) for(const b of blocks) for(const x of b.hooks){
  if(/office-start/.test(x.command||"")){ if(ev!=="SessionStart"||b.matcher!=="startup"||x.async!==true) bad.push(ev+":"+b.matcher); }
}
const ss=h.SessionStart.filter(b=>b.hooks.some(x=>/office-start/.test(x.command||"")));  // office-pref status também roda em clear (office-ask-at-start)
console.log(bad.length===0&&ss.length===1&&ss[0].matcher==="startup"?"ok":"bad "+bad);
' "$J")"
eq "req002 hooks.json: office-start só em startup e async" "ok" "$res"
drop_sandbox
finish
