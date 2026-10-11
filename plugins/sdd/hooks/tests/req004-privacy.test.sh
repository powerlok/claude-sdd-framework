#!/usr/bin/env bash
# REQ-004 (privacidade): allowlist estrita. Segredos FALSOS em comando, arquivo, prompt, resposta, descrição; JSON forjado;
# UTF-8; limites. Nada fora da allowlist pode chegar ao events.js.
. "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"
new_sandbox
EV="$HOOKS_DIR/office-event.sh"
printf 'on\n' > "$CLAUDE_CONFIG_DIR/sdd/office.conf"
export CLAUDE_PROJECT_DIR="/c/Users/segredo/projeto-confidencial"
fire() { printf '%s' "$1" | bash "$EV"; }
fire '{"hook_event_name":"Stop"}'
room="$(room_dir)"; f="$room/events.js"
reset() { : > "$f"; }
last() { tail -n 1 "$f"; }
mval() { last | sed -E 's/.*"m":"([^"]*)".*/\1/'; }
absent() { # absent "descrição" "texto": o texto NÃO pode aparecer em nada dentro da pasta da sala
  if grep -rqF -- "$2" "$room" 2>/dev/null; then bad "$1 (vazou: $2)"; else ok "$1"; fi
}
u8check() { # imprime valid/INVALID (+LS se houver U+2028)
  node -e '
const fs=require("fs");const b=fs.readFileSync(process.argv[1]);let r="valid";
try{new TextDecoder("utf-8",{fatal:true}).decode(b);}catch(e){r="INVALID";}
if(b.includes(Buffer.from([0xe2,0x80,0xa8]))) r+="+LS";
console.log(r);' "$f"
}

SECRETS=(hunter2-SEGREDO AKIAFAKEFAKEFAKE1234 ghp_FAKEFAKEFAKEFAKEFAKE0123456789abcd sk-FAKE-live-0123456789 Bearer-eyJFAKE.TOKEN.PARTE
         "senha do banco" /etc/passwd C:/Users/segredo/.ssh/id_rsa transcript-secreto-xyz resposta-do-assistente-xyz saida-da-ferramenta-xyz
         prompt-confidencial-xyz projeto-confidencial sessao-secreta-xyz)

# 1) segredos em todos os campos fora da allowlist de uma chamada Bash (inclusive "description" do Bash).
reset
out="$(fire '{"session_id":"sessao-secreta-xyz","transcript_path":"C:/Users/segredo/transcript-secreto-xyz.jsonl","cwd":"C:/Users/segredo/projeto-confidencial","permission_mode":"default","hook_event_name":"PreToolUse","agent_type":"sdd:backend","agent_id":"ab12","tool_name":"Bash","tool_input":{"command":"curl -H \"Authorization: Bearer-eyJFAKE.TOKEN.PARTE\" https://x/?k=AKIAFAKEFAKEFAKE1234 && echo hunter2-SEGREDO > /etc/passwd","description":"senha do banco ghp_FAKEFAKEFAKEFAKEFAKE0123456789abcd","file_path":"C:/Users/segredo/.ssh/id_rsa"},"tool_response":{"stdout":"saida-da-ferramenta-xyz"},"prompt":"prompt-confidencial-xyz","last_assistant_message":"resposta-do-assistente-xyz"}')"
eq "req004 Bash: stdout vazio" "" "$out"
for s in "${SECRETS[@]}" curl Authorization; do absent "req004 Bash: não vaza [$s]" "$s"; done
eq "req004 Bash: linha exatamente da allowlist (descrição de Bash ignorada)" \
  'E({"i":"X","t":0,"e":"tool","a":"backend","d":"ab12","k":"run","m":"","g":""});' \
  "$(last | sed -E 's/"i":"[0-9-]+","t":[0-9]+/"i":"X","t":0/')"

# 2) segredos em SubagentStop (last_assistant_message) e UserPromptSubmit (prompt).
reset
fire '{"hook_event_name":"SubagentStop","agent_type":"sdd:tests","agent_id":"zz9","last_assistant_message":"resposta-do-assistente-xyz AKIAFAKEFAKEFAKE1234 hunter2-SEGREDO","transcript_path":"transcript-secreto-xyz"}'
fire '{"hook_event_name":"UserPromptSubmit","prompt":"prompt-confidencial-xyz sk-FAKE-live-0123456789","cwd":"C:/Users/segredo/projeto-confidencial"}'
for s in "${SECRETS[@]}"; do absent "req004 Stop/Prompt: não vaza [$s]" "$s"; done

# 3) segredo na descrição de delegação: o padrão de segredo derruba a descrição inteira.
for sec in "password=hunter2" "usar token ghp_FAKEFAKEFAKEFAKEFAKE0123456789abcd" "chave AKIAFAKEFAKEFAKE1234" "sk-FAKE-live-0123456789 no deploy" \
           "Bearer abc" "o SECRET do cofre" "eyJhbGciOiJIUzI1NiJ9" "AAAAAAAAAAAAAAAAAAAAAAAAAAAAA" "xoxb-FAKE" "Authorization header"; do
  reset
  fire '{"hook_event_name":"PreToolUse","tool_name":"Agent","tool_input":{"description":"Implementar '"$sec"' T-003","subagent_type":"sdd:backend","prompt":"prompt-confidencial-xyz"}}'
  eq "req004 descrição com segredo [$sec] => [omitido]" "[omitido]" "$(mval)"
done
reset
fire '{"hook_event_name":"PreToolUse","tool_name":"Agent","tool_input":{"description":"Implementar autenticação T-003 (login)","subagent_type":"sdd:backend","prompt":"prompt-confidencial-xyz"}}'
eq "req004 descrição normal preservada (UTF-8)" "Implementar autenticação T-003 (login)" "$(mval)"
absent "req004 prompt da delegação não vaza" "prompt-confidencial-xyz"

# 4) JSON forjado: chave escapada dentro de string não é capturada.
reset
fire '{"hook_event_name":"PreToolUse","agent_type":"sdd:backend","tool_name":"Bash","tool_input":{"command":"echo \"tool_name\":\"Agent\" \"agent_type\":\"sdd:evil\" \"hook_event_name\":\"Stop\" \"description\":\"forjada\""}}'
eq "req004 chave forjada em string: continua tool/backend/run" 'tool|backend|run|' "$(last | sed -E 's/.*"e":"([a-z]+)","a":"([^"]*)","d":"[^"]*","k":"([^"]*)","m":"([^"]*)".*/\1|\2|\3|\4/')"
reset
fire '{"hook_event_name":"PreToolUse","tool_name":"Agent","tool_input":{"prompt":"x \"description\":\"forjada\" \\\"description\\\":\"forjada2\"","description":"verdadeira","subagent_type":"sdd:tests"}}'
eq "req004 descrição forjada no prompt não vence a verdadeira" "verdadeira" "$(mval)"
reset
fire '{"hook_event_name":"PreToolUse","tool_name":"Agent","tool_input":{"prompt":"termina com barra \\","description":"depois da barra","subagent_type":"sdd:tests"}}'
eq "req004 valor terminado em barra: descrição seguinte lida" "depois da barra" "$(mval)"

# 5) nomes de agente inválidos são DESCARTADOS (não "limpos").
for v in 'sdd:../../etc' 'a\"b' 'x y' 'sdd:sdd:x' 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa' '<script>' 'evil\\u0022'; do
  reset
  fire '{"hook_event_name":"SubagentStart","agent_type":"'"$v"'","agent_id":"i1"}'
  check "req004 agent_type inválido [$v] => a vazio" grep -q '"e":"start","a":"","d":"i1"' "$f"
done
reset
fire '{"hook_event_name":"PreToolUse","tool_name":"Agent","tool_input":{"description":"ok","subagent_type":"../x\"y"}}'
check "req004 subagent_type inválido => g vazio" grep -q '"g":""' "$f"
reset
fire '{"hook_event_name":"PreToolUse","tool_name":"mcp__servidor__ferramenta-secreta","tool_input":{}}'
check "req004 ferramenta MCP => k=mcp" grep -q '"k":"mcp"' "$f"
absent "req004 nome da ferramenta MCP não gravado" "ferramenta-secreta"

# 6) saneamento da descrição: marcação, aspas, barras, controles, UTF-8.
sane() { # sane "json-da-descrição" "esperado"
  reset
  fire '{"hook_event_name":"PreToolUse","tool_name":"Agent","tool_input":{"description":"'"$1"'","subagent_type":"sdd:frontend"}}'
  eq "req004 saneia [$1]" "$2" "$(mval)"
}
sane '<script>alert(1)<\/script>' 'script alert(1) script'
sane 'a \"b\" c' 'a b c'
sane 'a\\b\\\\ c' 'a b c'
sane 'linha1\nlinha2\ttab\r\n' 'linha1 linha2 tab'
sane '<img src=x onerror=alert(1)>' 'img src x onerror alert(1)'
sane 'ctrl\u0001\u001f x' 'ctrl x'
sane 'a    b     c' 'a b c'
sane '`$(touch x)` ${HOME} ; rm -rf' '(touch x) HOME ; rm -rf'
sane '日本語 ação' '日本語 ação'
sane 'emoji 😀 ok' 'emoji 😀 ok'
reset
fire '{"hook_event_name":"PreToolUse","tool_name":"Agent","tool_input":{"description":"<b>\"x\"</b> \\ ` $ =","subagent_type":"sdd:frontend"}}'
case "$(mval)" in *[\"\\\<\>=\`\$]*) bad "req004 sem aspas, barras, <, >, =, crase ou \$ na descrição" ;; *) ok "req004 sem aspas, barras, <, >, =, crase ou \$ na descrição" ;; esac

# 7) limites.
reset
fire '{"hook_event_name":"PreToolUse","tool_name":"Agent","tool_input":{"description":"'"$(printf 'palavra%.0s ' $(seq 1 60))"'","subagent_type":"sdd:backend"}}'
check "req004 descrição longa: <= 80 bytes" test "$(mval | wc -c | tr -d ' ')" -le 80
reset
fire '{"hook_event_name":"PreToolUse","tool_name":"Agent","tool_input":{"description":"'"$(printf 'ção%.0s' $(seq 1 60))"'","subagent_type":"sdd:backend"}}'
eq "req004 corte no meio de caractere multibyte: UTF-8 válido" "valid" "$(u8check)"
check "req004 multibyte truncado ainda tem texto" grep -q '"m":"ção' "$f"
reset
printf '%s' '{"hook_event_name":"PreToolUse","tool_name":"Agent","tool_input":{"description":"ab'$'\xff\xfe\xc3''cd '$'\xe2\x80\xa8'' fim","subagent_type":"sdd:backend"}}' | bash "$EV"
eq "req004 bytes inválidos e U+2028: UTF-8 válido, sem separador de linha" "valid" "$(u8check)"
reset
fire '{"hook_event_name":"PreToolUse","tool_name":"Agent","tool_input":{"description":"'"$(head -c 200000 /dev/zero | tr '\0' 'x')"'","subagent_type":"sdd:backend"}}'
check "req004 descrição de 200 KB: linha <= 400 bytes" test "$(wc -c < "$f" | tr -d ' ')" -le 401
reset
fire '{"hook_event_name":"PreToolUse","tool_name":"Agent","tool_input":{"description":"sem fim'
absent "req004 JSON sem fechamento: descrição não gravada" "sem fim"
printf '{"hook_event_name":"PreToolUse","tool_name":"Agent","tool_input":{"description":"a\000b","subagent_type":"sdd:backend"}}' | bash "$EV"; rc=$?
eq "req004 NUL no JSON: exit 0" "0" "$rc"

# 8) varredura final: toda linha segue o formato estrito da allowlist.
reset
fire '{"hook_event_name":"SubagentStart","agent_type":"sdd:security","agent_id":"s1"}'
fire '{"hook_event_name":"PreToolUse","agent_type":"sdd:security","agent_id":"s1","tool_name":"Bash","tool_input":{"command":"rm -rf /"}}'
fire '{"hook_event_name":"PreToolUse","tool_name":"Agent","tool_input":{"description":"Revisar T-003 (login)","subagent_type":"sdd:security"}}'
fire '{"hook_event_name":"SubagentStop","agent_type":"sdd:security","agent_id":"s1"}'
fire '{"hook_event_name":"UserPromptSubmit","prompt":"x"}'
fire '{"hook_event_name":"Stop"}'
LINE_RE='^E\(\{"i":"[0-9-]{1,24}","t":[0-9]{1,12},"e":"(start|stop|tool|prompt|end)","a":"[A-Za-z0-9_.-]{0,32}","d":"[A-Za-z0-9]{0,12}","k":"(read|edit|run|web|delegate|plan|ask|mcp|other)?","m":"[^"\\<>=]{0,80}","g":"[A-Za-z0-9_.-]{0,32}"\}\);$'
n=0; badl=0
while IFS= read -r l; do n=$((n + 1)); [[ $l =~ $LINE_RE ]] || { badl=$((badl + 1)); echo "    linha fora do formato: $l"; }; done < "$f"
eq "req004 todas as $n linhas no formato estrito" "0" "$badl"
eq "req004 pasta da sala só tem events.js" "events.js" "$(ls "$room")"
drop_sandbox
finish
