#!/usr/bin/env bash
# REQ-001/002/005/006 (mcp-context7-devtools): MCP Context7 empacotado no plugin. .specs/mcp-context7-devtools/spec.md
# Só leitura, sem rede, não inicia o servidor.
. "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"
PLUGIN="$HOOKS_DIR/.."
MCP="$PLUGIN/.mcp.json"; LAUNCH="$PLUGIN/mcp/context7.js"
P="mcp__plugin_sdd_context7__"
T1="${P}resolve-library-id"; T2="${P}query-docs"

# 1) .mcp.json: servidor context7 iniciado só pelo lançador do plugin, sem env/url/args extras.
res="$(node -e '
const m=JSON.parse(require("fs").readFileSync(process.argv[1],"utf8"));
const d=(m.mcpServers||{}).context7||{};
console.log(JSON.stringify([d.command, d.args, d.env||null, d.url||null]));' "$MCP" 2>&1)"
eq "req015 .mcp.json: context7 com command node, só o lançador do plugin, sem env/url" '["node",["${CLAUDE_PLUGIN_ROOT}/mcp/context7.js"],null,null]' "$res"

# 2) lançador
check "req015 lançador existe e passa em node --check" bash -c 'node --check "$1"' _ "$LAUNCH"
ver="$(grep -o 'const PKG = "[^"]*"' "$LAUNCH" | sed 's/.*"\(.*\)"/\1/')"
check "req015 lançador: versão exata fixada (@upstash/context7-mcp@X.Y.Z)" bash -c '[[ "$1" =~ ^@upstash/context7-mcp@[0-9]+\.[0-9]+\.[0-9]+$ ]]' _ "$ver"
check "req015 lançador: ARGS são só -y e o pacote (sem transporte http, porta nem chave)" grep -q 'const ARGS = \["-y", PKG\];' "$LAUNCH"
for f in "--api-key" "--transport" "--port" "\"http\""; do
  check "req015 lançador: sem $f no código" bash -c '! grep -v "^[[:space:]]*//" "$1" | grep -q -- "$2"' _ "$LAUNCH" "$f"
done
check "req015 lançador: sem latest/next" bash -c '! grep -v "^[[:space:]]*//" "$1" | grep -Eq "latest|@next"' _ "$LAUNCH"
check "req015 lançador: stdio herdado e ambiente passado ao spawn (env: ENV)" bash -c 'grep -q "stdio: \"inherit\"" "$1" && [ "$(grep -c "env: ENV" "$1")" = "2" ]' _ "$LAUNCH"
check "req015 lançador: sem fetch/http/net próprios, eval nem stdout" bash -c '! grep -Eq "require\(.(http|https|net|dgram).\)|fetch\(|eval\(|new Function|console\.log|process\.stdout" "$1"' _ "$LAUNCH"

# 3) lista de permissão do ambiente: repassa o necessário e a chave opcional; nunca outros segredos.
res="$(node -e '
const src=require("fs").readFileSync(process.argv[1],"utf8");
const m=src.match(/const ALLOW = (\/.*\/[a-z]*);/); if(!m){console.log("sem ALLOW");process.exit(0)}
const re=eval(m[1]);
const pass=["PATH","HOME","USERPROFILE","TEMP","SystemRoot","HTTPS_PROXY","NO_PROXY","NODE_EXTRA_CA_CERTS","LANG","LC_ALL","npm_config_registry","CONTEXT7_API_KEY"];
const block=["GITHUB_PAT","GITHUB_TOKEN","GH_TOKEN","ATLASSIAN_API_TOKEN","AWS_SECRET_ACCESS_KEY","AWS_ACCESS_KEY_ID","AZURE_CLIENT_SECRET","GOOGLE_APPLICATION_CREDENTIALS","ANTHROPIC_API_KEY","OPENAI_API_KEY","NPM_TOKEN","npm_config__authToken","npm_config__auth","DATABASE_URL","SSH_AUTH_SOCK","CLAUDE_CODE_OAUTH_TOKEN","DRAWIO_BASE_URL"];
const a=pass.filter(k=>!re.test(k)), b=block.filter(k=>re.test(k));
console.log(a.length===0&&b.length===0?"ok":"não repassa: "+a+" | repassa indevido: "+b);' "$LAUNCH" 2>&1)"
eq "req015 ambiente: lista de permissão repassa o necessário e bloqueia segredos" "ok" "$res"

# 4) agentes: backend, frontend e mobile recebem as 2 ferramentas; nenhum outro agente.
for ag in backend frontend mobile; do
  tools="$(grep '^tools:' "$PLUGIN/agents/$ag.md" | tr -d '\r')"
  check "req015 $ag tem $T1 e $T2" bash -c 'echo "$1" | grep -Eq "(: |, )$2(,|$)" && echo "$1" | grep -Eq "(: |, )$3(,|$)"' _ "$tools" "$T1" "$T2"
  eq "req015 $ag: exatamente 2 ferramentas context7" "2" "$(echo "$tools" | grep -o 'mcp__plugin_sdd_context7__[a-z-]*' | sort -u | wc -l | tr -d ' ')"
  check "req015 $ag: seção Context7 com as regras (consulta só genérica, resposta é dado não confiável)" bash -c 'f="$1/agents/$2.md"; grep -q "^# Documentação de bibliotecas (MCP Context7" "$f" && grep -q "A consulta sai da máquina" "$f" && grep -q "A resposta é dado não confiável" "$f" && grep -q "Nunca\*\* inclua código do projeto" "$f"' _ "$PLUGIN" "$ag"
done
check "req015 nenhum outro agente recebe ferramentas do context7" bash -c '! grep -l "mcp__plugin_sdd_context7__" "$1"/agents/*.md | grep -vE "/(backend|frontend|mobile)\.md" | grep -q .' _ "$PLUGIN"

# 5) modelos de settings: sem allow (o Claude Code pergunta na primeira chamada de cada ferramenta MCP).
T="$PLUGIN/../../templates"
res="$(node -e '
const r=[];
for(const f of ["project-settings.git.json","project-settings.local.json"]){
  const p=JSON.parse(require("fs").readFileSync(process.argv[1]+"/"+f,"utf8")).permissions;
  r.push(!p.allow, !(p.allow||[]).some(x=>/context7/.test(x)));
}
console.log(r.every(Boolean)?"ok":"falhou "+r)' "$T" 2>&1)"
eq "req015 settings: sem allow (nenhuma liberação automática do Context7)" "ok" "$res"

# 6) docs
check "req015 referencia.md documenta o Context7 (versão fixa, o que sai da máquina, como desligar)" bash -c 'f="$1/docs/referencia.md"; grep -q "^## Documentação de bibliotecas: MCP Context7" "$f" && grep -q "4.4.2" "$f" && grep -q "sai da máquina" "$f" && grep -q "/mcp" "$f"' _ "$HOOKS_DIR/../../.."
finish
