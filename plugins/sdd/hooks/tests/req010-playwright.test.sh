#!/usr/bin/env bash
# REQ-005 (playwright-mcp): MCP Playwright empacotado no plugin. .specs/playwright-mcp/spec.md. Só leitura, sem rede, não inicia o servidor.
. "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"
PLUGIN="$HOOKS_DIR/.."
MCP="$PLUGIN/.mcp.json"; LAUNCH="$PLUGIN/mcp/playwright.js"; FE="$PLUGIN/agents/frontend.md"
P="mcp__plugin_sdd_playwright__"
ALLOW="browser_navigate browser_navigate_back browser_snapshot browser_click browser_hover browser_type browser_fill_form browser_press_key browser_select_option browser_wait_for browser_take_screenshot browser_console_messages browser_network_requests browser_network_request browser_resize browser_handle_dialog browser_emulate_media browser_find browser_close"
FORBID="browser_evaluate browser_run_code_unsafe browser_file_upload browser_drop browser_tabs browser_drag"

# 1) .mcp.json: servidor playwright iniciado pelo lançador do plugin, sem env/url/args extras.
res="$(node -e '
const m=JSON.parse(require("fs").readFileSync(process.argv[1],"utf8"));
const d=(m.mcpServers||{}).playwright||{};
console.log(JSON.stringify([d.command, d.args, d.env||null, d.url||null]));' "$MCP" 2>&1)"
eq "req010 .mcp.json: playwright com command node, só o lançador do plugin, sem env/url" '["node",["${CLAUDE_PLUGIN_ROOT}/mcp/playwright.js"],null,null]' "$res"

# 2) lançador: sintaxe, versão exata, --isolated obrigatório, nenhuma flag proibida, stdout limpo, sem rede própria.
check "req010 lançador existe e passa em node --check" bash -c 'node --check "$1"' _ "$LAUNCH"
ver="$(grep -o 'const PKG = "[^"]*"' "$LAUNCH" | sed 's/.*"\(.*\)"/\1/')"
check "req010 lançador: versão exata fixada (@playwright/mcp@X.Y.Z)" bash -c '[[ "$1" =~ ^@playwright/mcp@[0-9]+\.[0-9]+\.[0-9]+$ ]]' _ "$ver"
check "req010 lançador: ARGS obrigatórios (-y, pacote, --isolated, --no-webmcp, --block-service-workers, --blocked-origins de metadata)" bash -c 'grep -q "const ARGS = \[\"-y\", PKG, \"--isolated\", \"--no-webmcp\", \"--block-service-workers\"," "$1" && grep -q "\"--blocked-origins\", \"http://169.254.169.254;http://metadata.google.internal\"\]" "$1"' _ "$LAUNCH"
check "req010 lançador: --headless só pela variável explícita SDD_PLAYWRIGHT_HEADLESS=1" bash -c '[ "$(grep -v "^[[:space:]]*//" "$1" | grep -c -- "--headless")" = "1" ] && grep -q "SDD_PLAYWRIGHT_HEADLESS === \"1\") ARGS.push(\"--headless\")" "$1"' _ "$LAUNCH"
check "req010 lançador: ambiente filtrado (PLAYWRIGHT_MCP_, PLAYWRIGHT_DOWNLOAD, npm_config_) e passado ao spawn" bash -c 'grep -q "PLAYWRIGHT_MCP_|PLAYWRIGHT_DOWNLOAD|npm_config_" "$1" && [ "$(grep -c "env: ENV" "$1")" = "2" ]' _ "$LAUNCH"
# flags proibidas só podem aparecer em comentário (linha começando com //)
for f in "--caps" "--no-sandbox" "--extension" "--allow-unrestricted-file-access" "--ignore-https-errors" "--user-data-dir" "--save-session" "--allowed-hosts"; do
  check "req010 lançador: sem $f no código" bash -c '! grep -v "^[[:space:]]*//" "$1" | grep -q -- "$2"' _ "$LAUNCH" "$f"
done
check "req010 lançador: sem latest/next (faixas já barradas pela versão exata acima)" bash -c '! grep -v "^[[:space:]]*//" "$1" | grep -Eq "latest|@next"' _ "$LAUNCH"
check "req010 lançador: stdio herdado" grep -q 'stdio: "inherit"' "$LAUNCH"
check "req010 lançador: sem fetch/http/net próprios, eval nem stdout" bash -c '! grep -Eq "require\(.(http|https|net|dgram).\)|fetch\(|eval\(|new Function|console\.log|process\.stdout" "$1"' _ "$LAUNCH"

# 3) frontend: tools do playwright = exatamente as 21 permitidas; nenhuma das 4 proibidas.
tools="$(grep '^tools:' "$FE" | tr -d '\r')"
for t in $ALLOW; do
  check "req010 frontend tem ${P}${t}" bash -c 'echo "$1" | grep -Eq "(: |, )$2(,|$)"' _ "$tools" "${P}${t}"
done
for t in $FORBID; do
  check "req010 frontend NÃO tem $t" bash -c '! echo "$1" | grep -q "$2"' _ "$tools" "$t"
done
eq "req010 frontend: 19 ferramentas playwright (nenhuma a mais)" "19" "$(echo "$tools" | grep -o 'mcp__plugin_sdd_playwright__[a-z_]*' | sort -u | wc -l | tr -d ' ')"
check "req010 nenhum outro agente recebe ferramentas do playwright" bash -c '! grep -l "mcp__plugin_sdd_playwright__" "$1"/agents/*.md | grep -v "/frontend.md" | grep -q .' _ "$PLUGIN"

# 4) regras de uso do frontend e da skill.
check "req010 frontend: escopo local e confirmação de navegação" bash -c 'grep -q "http://localhost" "$1" && grep -q "browser_navigate" "$1"' _ "$FE"
check "req010 frontend: perfil isolado, sem credencial" bash -c 'grep -q "Perfil isolado" "$1" && grep -q "credencial" "$1"' _ "$FE"
check "req010 frontend: conteúdo da página é dado não confiável (prompt injection)" bash -c 'grep -q "dado não confiável" "$1" && grep -q "prompt injection" "$1"' _ "$FE"
check "req010 frontend: não usar filename; rede só com part e sem cabeçalhos/tokens; não abrir abas" bash -c 'grep -q "Não use o parâmetro \`filename\`" "$1" && grep -q "nunca\*\* cabeçalhos" "$1" && grep -q "Não abra abas" "$1"' _ "$FE"
check "req010 skill frontend-engineering tem a seção Verificação no navegador" grep -q '^## Verificação no navegador' "$PLUGIN/skills/frontend-engineering/SKILL.md"
check "req010 .gitignore do framework ignora .playwright-mcp/" grep -q '^\.playwright-mcp/$' "$PLUGIN/../../.gitignore"

# 5) modelos de settings: 4 ferramentas proibidas em deny, browser_navigate em ask, sem allow (git e local).
T="$PLUGIN/../../templates"
res="$(node -e '
const P="mcp__plugin_sdd_playwright__";
const r=[];
for(const f of ["project-settings.git.json","project-settings.local.json"]){
  const p=JSON.parse(require("fs").readFileSync(process.argv[1]+"/"+f,"utf8")).permissions;
  r.push(["browser_evaluate","browser_run_code_unsafe","browser_file_upload","browser_drop"].every(n=>p.deny.includes(P+n)),
         p.ask.includes(P+"browser_navigate") && p.ask.includes(P+"browser_tabs"), !p.allow);
}
console.log(JSON.stringify(r));' "$T")"
eq "req010 modelos: deny das 4 ferramentas, ask de navigate e tabs, sem allow (git e local)" "[true,true,true,true,true,true]" "$res"
check "req010 as ferramentas do playwright não estão no grupo de publicação" bash -c '! grep -q playwright "$1"' _ "$T/project-settings.publicacao.json"

finish
