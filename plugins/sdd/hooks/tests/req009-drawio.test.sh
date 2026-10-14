#!/usr/bin/env bash
# REQ-005 (drawio-mcp): MCP draw.io empacotado no plugin. .specs/drawio-mcp/spec.md. Só leitura, sem rede, não inicia o servidor.
. "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"
PLUGIN="$HOOKS_DIR/.."
MCP="$PLUGIN/.mcp.json"; LAUNCH="$PLUGIN/mcp/drawio.js"; ARCH="$PLUGIN/agents/infra-architect.md"

# 1) .mcp.json: JSON válido, só o servidor drawio, iniciado pelo lançador em Node.
res="$(node -e '
const m=JSON.parse(require("fs").readFileSync(process.argv[1],"utf8"));
const k=Object.keys(m.mcpServers||{});
const d=(m.mcpServers||{}).drawio||{};
console.log(JSON.stringify([Object.keys(m), k, d.command, d.args, d.env||null, d.url||null]));' "$MCP" 2>&1)"
eq "req009 .mcp.json: só mcpServers.drawio, command node, lançador do plugin, sem env/url" \
  '[["mcpServers"],["drawio"],"node",["${CLAUDE_PLUGIN_ROOT}/mcp/drawio.js"],null,null]' "$res"

# 2) lançador: sintaxe válida, versão EXATA fixada (sem latest/faixa), npx -y, stdio herdado, sem rede própria.
check "req009 lançador existe e passa em node --check" bash -c 'node --check "$1"' _ "$LAUNCH"
ver="$(grep -o 'const PKG = "[^"]*"' "$LAUNCH" | sed 's/.*"\(.*\)"/\1/')"
check "req009 lançador: versão exata fixada (@drawio/mcp@X.Y.Z)" bash -c '[[ "$1" =~ ^@drawio/mcp@[0-9]+\.[0-9]+\.[0-9]+$ ]]' _ "$ver"
check "req009 lançador: sem latest, ranges ou outros pacotes" bash -c '! grep -Eq "latest|\^|~|@next" "$1" && [ "$(grep -c "@drawio/mcp" "$1")" -ge 1 ]' _ "$LAUNCH"
check "req009 lançador: stdio herdado e npx -y" bash -c 'grep -q "stdio: \"inherit\"" "$1" && grep -q "\"-y\", PKG" "$1"' _ "$LAUNCH"
check "req009 lançador: sem fetch/http/net próprios nem eval" bash -c '! grep -Eq "require\(.(http|https|net|dgram).\)|fetch\(|eval\(|new Function" "$1"' _ "$LAUNCH"
check "req009 lançador: nada no stdout (sem console.log/process.stdout)" bash -c '! grep -Eq "console\.log|process\.stdout" "$1"' _ "$LAUNCH"

# 3) infra-architect: tools do drawio = exatamente as 5 permitidas; nenhuma ferramenta de arquivo por caminho.
tools="$(grep '^tools:' "$ARCH" | tr -d '\r')"
for t in open_drawio_xml open_drawio_csv open_drawio_mermaid get_drawio_reference search_shapes; do
  check "req009 arquiteto tem mcp__plugin_sdd_drawio__$t" bash -c 'echo "$1" | grep -q "mcp__plugin_sdd_drawio__$2\b"' _ "$tools" "$t"
done
for t in list_pages get_page set_page; do
  check "req009 arquiteto NÃO tem $t" bash -c '! echo "$1" | grep -q "$2"' _ "$tools" "$t"
done
eq "req009 arquiteto: 5 ferramentas drawio (nenhuma a mais)" "5" "$(echo "$tools" | grep -o 'mcp__plugin_sdd_drawio__[a-z_]*' | sort -u | wc -l | tr -d ' ')"
check "req009 nenhum outro agente recebe ferramentas drawio" bash -c '! grep -l "mcp__plugin_sdd_drawio__" "$1"/agents/*.md | grep -v infra-architect | grep -q .' _ "$PLUGIN"

# 4) regras de uso do arquiteto e da skill.
check "req009 arquiteto: nunca segredo/IP/ID de conta no diagrama" bash -c 'grep -q "nome.* lógico" "$1" && grep -q "segredo" "$1"' _ "$ARCH"
check "req009 arquiteto: diagrama só quando pedido e nunca de texto externo" bash -c 'grep -q "só quando o" "$1" && grep -q "nunca\*\* de texto externo" "$1"' _ "$ARCH"
check "req009 arquiteto: libavoid/elk só se o usuário pedir" bash -c 'grep -q "viewer.diagrams.net" "$1"' _ "$ARCH"
check "req009 skill infra-engineering tem a seção Diagramas" grep -q '^## Diagramas' "$PLUGIN/skills/infra-engineering/SKILL.md"

# 5) (parecer de segurança C3/C4) todo agente declara `tools` explícito (senão herda todas as ferramentas, inclusive set_page/get_page).
for f in "$PLUGIN"/agents/*.md; do
  check "req009 agente ${f##*/}: tools explícito no frontmatter" bash -c 'head -30 "$1" | grep -q "^tools:"' _ "$f"
done
# 6) modelos de settings: ferramentas de arquivo do drawio em deny; open_* em ask (abrem o navegador); sem allow.
T="$PLUGIN/../../templates"
res="$(node -e '
const P="mcp__plugin_sdd_drawio__";
const r=[];
for(const f of ["project-settings.git.json","project-settings.local.json"]){
  const p=JSON.parse(require("fs").readFileSync(process.argv[1]+"/"+f,"utf8")).permissions;
  r.push(["list_pages","get_page","set_page"].every(n=>p.deny.includes(P+n)),
         ["open_drawio_xml","open_drawio_csv","open_drawio_mermaid"].every(n=>p.ask.includes(P+n)),
         !p.allow);
}
console.log(JSON.stringify(r));' "$T")"
eq "req009 modelos: deny das ferramentas de arquivo, ask dos open_*, sem allow (git e local)" "[true,true,true,true,true,true]" "$res"
check "req009 a lista de permissões drawio não está no grupo de publicação" bash -c '! grep -q drawio "$1"' _ "$T/project-settings.publicacao.json"

finish
