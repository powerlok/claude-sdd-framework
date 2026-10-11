#!/usr/bin/env bash
# REQ-003/REQ-004 (correções L1-L6): JSON aninhado, campo d, caminhos e segredos na descrição, pasta por usuário, TMPDIR.
. "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"
new_sandbox
EV="$HOOKS_DIR/office-event.sh"
printf 'on\n' > "$CLAUDE_CONFIG_DIR/sdd/office.conf"
fire() { printf '%s' "$1" | bash "$EV"; }
fire '{"hook_event_name":"Stop"}'
room="$(room_dir)"; f="$room/events.js"
reset() { : > "$f"; }
mval() { tail -n 1 "$f" | sed -E 's/.*"m":"([^"]*)".*/\1/'; }
dly() { reset; fire '{"hook_event_name":"PreToolUse","tool_name":"Agent","tool_input":{"description":"'"$1"'","subagent_type":"sdd:backend"}}'; mval; }

# L5: pasta por usuário.
check "req004 L5 pasta sdd-office-<uid>" test -d "$TMPDIR/sdd-office-$UID"
check "req004 L5 sem pasta sdd-office genérica" test ! -e "$TMPDIR/sdd-office"

# L1: só nível 1 (e tool_input para description/subagent_type).
reset
fire '{"hook_event_name":"PreToolUse","tool_input":{"tool_name":"Agent","hook_event_name":"Stop","agent_type":"sdd:forjado","agent_id":"FORJADO"},"tool_name":"Read","agent_type":"sdd:tests","agent_id":"real1"}'
check "req004 L1 tool_input antes de tool_name: k=read, a=tests, d=real1" grep -q '"e":"tool","a":"tests","d":"real1","k":"read"' "$f"
reset
fire '{"hook_event_name":"PreToolUse","tool_name":"Bash","tool_input":{"command":"x","tool_name":"Agent","description":"forjada","subagent_type":"sdd:x"}}'
check "req004 L1 tool_name aninhado ignorado (k=run)" grep -q '"k":"run"' "$f"
check "req004 L1 description fora de delegação não gravada" grep -q '"m":"","g":""' "$f"
reset
fire '{"hook_event_name":"PreToolUse","tool_name":"Read","tool_input":{"s":"{ \"tool_name\":\"Agent\" } ]"},"agent_type":"sdd:tests"}'
check "req004 L1 chaves/colchetes dentro de string não quebram o nível" grep -q '"a":"tests","d":"","k":"read"' "$f"
reset
fire '{"hook_event_name":"SubagentStart","last_assistant_message":{"hook_event_name":"Stop","agent_type":"sdd:forjado"},"agent_type":"sdd:backend","agent_id":"z9"}'
check "req004 L1 objeto aninhado em SubagentStart ignorado" grep -q '"e":"start","a":"backend","d":"z9"' "$f"
reset
fire '{"hook_event_name":"PreToolUse","tool_name":"Agent","tool_input":{"deep":{"description":"profunda","subagent_type":"sdd:fundo"},"description":"Revisar T-003","subagent_type":"sdd:security"}}'
check "req004 L1 description/subagent_type do nível de tool_input" grep -q '"m":"Revisar T-003","g":"security"' "$f"
reset
fire '{"hook_event_name":"PreToolUse","tool_name":"Agent","tool_input":{"description":"ok","subagent_type":"sdd:backend"},"agent_type":"sdd:tecleader"}'
check "req004 L1 campo depois do objeto aninhado ainda é lido" grep -q '"a":"tecleader"' "$f"

# L2: d só alfanumérico, máx. 12.
reset
fire '{"hook_event_name":"SubagentStart","agent_type":"sdd:tests","agent_id":"a.b:c-d_e.f:g1h2i3j4k5"}'
check "req004 L2 d alfanumérico (sem . : - _) e <= 12" grep -q '"d":"abcdefg1h2i3"' "$f"
reset
fire '{"hook_event_name":"SubagentStart","agent_type":"sdd:tests","agent_id":"..::--"}'
check "req004 L2 d só pontuação = vazio" grep -q '"d":""' "$f"

# L3: caminhos/arquivos sensíveis => [omitido] (barras invertidas já escapadas no JSON).
for s in 'Ler C:/Users/x/a' 'Ler C:\\Users\\x' 'Ler ~/.ssh/config' 'Abrir /etc/passwd' 'Ver /home/u/proj' 'Ler o .env' 'Ler id_rsa' 'Ler a.pem' 'Ler a.key'; do
  eq "req004 L3 [$s] omitido" "[omitido]" "$(dly "$s")"
done
# N3: UNC e caminho relativo com "/" + extensão.
for s in 'Ler \\\\host\\share\\x' 'Ver //srv/share' 'Editar src/app/main.ts' 'Abrir docs/a.md.' 'Ler ./lib/x.js'; do
  eq "req004 N3 [$s] omitido" "[omitido]" "$(dly "$s")"
done
eq "req004 N3 e/ou sem extensão preservado" "Revisar login e/ou logout" "$(dly 'Revisar login e/ou logout')"
eq "req004 L3 texto normal preservado" "Revisar login e/ou logout (T-003)" "$(dly 'Revisar login e/ou logout (T-003)')"

# L4: palavras de segredo pt-BR e sequência longa.
for s in 'Trocar a senha do admin' 'Rotacionar chave do servico' 'Revisar credenciais' 'Vazou segredo' 'definir pwd root' 'Usar abcdefghijklmnopqrstuvwx' 'Usar abcd.efgh-ijkl_mnop+qrstuv1'; do
  eq "req004 L4 [$s] omitido" "[omitido]" "$(dly "$s")"
done
eq "req004 L4 sequência de 23 não dispara" "Usar abcdefghijklmnopqrstuvw" "$(dly 'Usar abcdefghijklmnopqrstuvw')"

# L6: TMPDIR relativo cai em /tmp (nunca cria pasta relativa); pasta por usuário também lá.
mkdir -p "$SB/cwd"; export CLAUDE_PROJECT_DIR="/c/fake/l6-$$-$RANDOM"
before="$(ls "/tmp/sdd-office-$UID" 2>/dev/null)"
( cd "$SB/cwd" && TMPDIR="rel/tmp" bash -c 'printf "%s" "{\"hook_event_name\":\"Stop\"}" | bash "$1"' _ "$EV" )
check "req004 L6 TMPDIR relativo não cria pasta relativa" test -z "$(ls "$SB/cwd")"
after="$(ls "/tmp/sdd-office-$UID" 2>/dev/null)"
new="$(comm -13 <(printf '%s\n' "$before" | sort) <(printf '%s\n' "$after" | sort) | grep -v '^$')"
check "req004 L6 TMPDIR relativo usa /tmp/sdd-office-<uid>" test -n "$new"
( cd "$SB/cwd" && TMPDIR="rel/tmp" SDD_OFFICE_OS=linux DISPLAY= bash "$HOOKS_DIR/office-start.sh" >/dev/null )
check "req004 L6 start com TMPDIR relativo não cria pasta relativa" test -z "$(ls "$SB/cwd")"
after2="$(ls "/tmp/sdd-office-$UID" 2>/dev/null)"
new="$(comm -13 <(printf '%s\n' "$before" | sort) <(printf '%s\n' "$after2" | sort) | grep -v '^$')"
for d in $new; do rm -rf "/tmp/sdd-office-$UID/$d"; done
[ -z "$before" ] && rmdir "/tmp/sdd-office-$UID" 2>/dev/null
check "req004 L6 scripts documentam CLAUDE_CONFIG_DIR do ambiente" bash -c 'for s in office-event office-start office-pref; do grep -q "CLAUDE_CONFIG_DIR (e HOME) vêm do ambiente" "$1/$s.sh" || exit 1; done' _ "$HOOKS_DIR"
drop_sandbox
finish
