#!/usr/bin/env bash
# REQ-005 (start-banner): aviso de início de sessão. .specs/start-banner/spec.md. Só leitura; usa pasta temporária própria.
. "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"
new_sandbox
S="$HOOKS_DIR/start-banner.sh"
P="$SB/proj"; mkdir -p "$P"
jq_msg() { node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{try{const o=JSON.parse(s);const k=Object.keys(o);if(k.length!==1||k[0]!=="systemMessage"||typeof o.systemMessage!=="string")process.exit(2);process.stdout.write(o.systemMessage)}catch(e){process.exit(3)}})'; }

# 1) projeto sem CLAUDE.md: UM objeto JSON só com systemMessage; manda escrever a primeira mensagem.
out="$(CLAUDE_PROJECT_DIR="$P" bash "$S")"; rc=$?
eq "req008 sem onboarding: exit 0" "0" "$rc"
msg="$(printf '%s' "$out" | jq_msg)"; mrc=$?
eq "req008 sem onboarding: saída é um único JSON só com systemMessage" "0" "$mrc"
check "req008 sem onboarding: aponta /sdd:start e cita onboarding" bash -c 'echo "$1" | grep -q "/sdd:start" && echo "$1" | grep -q "onboarding"' _ "$msg"
eq "req008 stdout é uma linha só" "1" "$(printf '%s\n' "$out" | wc -l | tr -d ' ')"

# 2) CLAUDE.md sem ## Stack ainda é "sem onboarding".
printf '# Projeto\n' > "$P/CLAUDE.md"
msg="$(CLAUDE_PROJECT_DIR="$P" bash "$S" | jq_msg)"
check "req008 CLAUDE.md sem Stack: ainda sem onboarding" bash -c 'echo "$1" | grep -q "ainda não passou pelo onboarding"' _ "$msg"

# 3) com ## Stack: "TechLead pronto".
printf '# Projeto\n\n## Stack\n- node\n' > "$P/CLAUDE.md"
out="$(CLAUDE_PROJECT_DIR="$P" bash "$S")"
msg="$(printf '%s' "$out" | jq_msg)"; mrc=$?
eq "req008 com onboarding: JSON válido" "0" "$mrc"
check "req008 com onboarding: TechLead pronto e /sdd:start" bash -c 'echo "$1" | grep -q "TechLead pronto" && echo "$1" | grep -q "/sdd:start"' _ "$msg"

# 4) nenhum texto do projeto vaza (nome de arquivo hostil, conteúdo do CLAUDE.md).
printf '# X\n\n## Stack\nSEGREDO-NO-CLAUDE-MD\n' > "$P/CLAUDE.md"
: > "$P/arquivo\"hostil\$(whoami)"
out="$(CLAUDE_PROJECT_DIR="$P" bash "$S")"
check "req008 conteúdo do CLAUDE.md não vaza" bash -c '! echo "$1" | grep -q SEGREDO' _ "$out"
check "req008 nome de arquivo hostil não vaza" bash -c '! echo "$1" | grep -q hostil' _ "$out"
check "req008 caminho do projeto não vaza" bash -c '! echo "$1" | grep -qF "$2"' _ "$out" "$P"

# 5) pasta inexistente: sai calado (exit 0, sem saída); CLAUDE.md symlink não conta como onboarding.
out="$(CLAUDE_PROJECT_DIR="$SB/nao-existe" bash "$S")"; rc=$?
eq "req008 pasta inexistente: exit 0" "0" "$rc"; eq "req008 pasta inexistente: sem saída" "" "$out"

# 6) hooks.json: o banner roda só em SessionStart/startup, sem async, com timeout curto; JSON válido.
res="$(node -e '
const h=JSON.parse(require("fs").readFileSync(process.argv[1],"utf8")).hooks;
const hits=[];
for(const [ev,blocks] of Object.entries(h)) for(const b of blocks) for(const x of b.hooks){
  if(/start-banner\.sh/.test(x.command||"")) hits.push([ev,b.matcher,x.async===true,x.timeout]);
}
console.log(JSON.stringify(hits));' "$HOOKS_DIR/hooks.json")"
eq "req008 hooks.json: banner só em SessionStart startup e clear, síncrono, timeout 5" '[["SessionStart","startup",false,5],["SessionStart","clear",false,5]]' "$res"
res="$(node -e '
const h=JSON.parse(require("fs").readFileSync(process.argv[1],"utf8")).hooks;
const hits=[];
for(const b of h.SessionStart) for(const x of b.hooks) if(/onboarding-check\.sh/.test(x.command||"")) hits.push(b.matcher);
console.log(JSON.stringify(hits));' "$HOOKS_DIR/hooks.json")"
eq "req008 hooks.json: onboarding-check roda em startup e clear (diagnóstico reinjetado depois do /clear)" '["startup","clear"]' "$res"
tl="$HOOKS_DIR/../agents/techlead.md"
check "req008 techlead: higiene de contexto (sugerir /clear, só o usuário executa, mesma tarefa não)" bash -c 'grep -q "Higiene de contexto" "$1" && grep -q "só o \*\*usuário\*\* executa" "$1" && grep -q "Mesma tarefa" "$1"' _ "$tl"

# 7) skill start (/sdd:start): só leitura, só o usuário invoca, aponta as seções do agente.
SK="$HOOKS_DIR/../skills/start/SKILL.md"
check "req008 skill start existe" test -f "$SK"
check "req008 skill start: name start" grep -q '^name: start$' "$SK"
check "req008 skill start: disable-model-invocation" grep -q '^disable-model-invocation: true$' "$SK"
eq "req008 skill start: allowed-tools só leitura" "allowed-tools: Read, Glob, Grep" "$(grep '^allowed-tools:' "$SK" | tr -d '\r')"
check "req008 skill start: nenhuma ferramenta de escrita/Bash" bash -c '! grep "^allowed-tools:" "$1" | grep -Eq "Bash|Edit|Write"' _ "$SK"
check "req008 skill start: usa a seção Início de sessão e Onboarding de Projeto" bash -c 'grep -q "Início de sessão" "$1" && grep -q "Onboarding de Projeto" "$1"' _ "$SK"

drop_sandbox
finish
