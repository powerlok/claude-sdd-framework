#!/usr/bin/env bash
# REQ-005 (context-management): configuração de contexto conforme a doc oficial. .specs/done/context-management/spec.md. Só leitura, sem rede.
. "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"
PLUGIN="$HOOKS_DIR/.."; T="$PLUGIN/../../templates"

# 1) autoCompactWindow nos dois modelos de settings: inteiro entre 100000 e 1000000, igual nos dois
res="$(node -e '
const fs=require("fs");const r=[];
for(const f of ["project-settings.git.json","project-settings.local.json"]){
  const v=JSON.parse(fs.readFileSync(process.argv[1]+"/"+f,"utf8")).autoCompactWindow; r.push(v);}
console.log(JSON.stringify([r[0]===r[1], Number.isInteger(r[0]) && r[0]>=100000 && r[0]<=1000000, r[0]]));' "$T")"
eq "req012 modelos de settings: autoCompactWindow inteiro 100000..1000000, igual nos dois (200000)" "[true,true,200000]" "$res"

# 2) subagentes: o campo vale só nos que implementam/testam, inteiro puro (200k seria lido como 200), < 200000; techlead/security/infra sem o campo
for a in backend frontend mobile tests; do
  v="$(grep -m1 '^autoCompactWindow:' "$PLUGIN/agents/$a.md" | tr -d '\r' | sed 's/^autoCompactWindow: *//')"
  check "req012 $a: autoCompactWindow inteiro puro entre 100000 e 199999 ($v)" bash -c '[[ "$1" =~ ^[0-9]+$ ]] && [ "$1" -ge 100000 ] && [ "$1" -lt 200000 ]' _ "$v"
done
for a in techlead security infra-architect; do
  check "req012 $a: sem autoCompactWindow no frontmatter" bash -c '! head -30 "$1" | grep -q "^autoCompactWindow:"' _ "$PLUGIN/agents/$a.md"
done

# 3) Compact instructions no modelo de CLAUDE.md e no onboarding
check "req012 templates/CLAUDE.md tem ## Compact instructions" grep -q '^## Compact instructions' "$T/CLAUDE.md"
check "req012 project-setup manda incluir ## Compact instructions" grep -q '## Compact instructions' "$PLUGIN/skills/project-setup/SKILL.md"

# 4) cada SKILL.md cabe no teto de reinjeção após compactação (5.000 tokens por skill; margem em bytes) e o TechLead explica o que sobrevive
for f in "$PLUGIN"/skills/*/SKILL.md; do
  n="$(wc -c < "$f" | tr -d ' ')"
  check "req012 $(basename "$(dirname "$f")")/SKILL.md <= 15000 bytes ($n)" bash -c '[ "$1" -le 15000 ]' _ "$n"
done
TL="$PLUGIN/agents/techlead.md"
check "req012 techlead: o que sobrevive à compactação, /compact com foco, /rewind e /context" bash -c 'grep -q "O que sobrevive à compactação" "$1" && grep -q "/compact Preserve" "$1" && grep -q "/rewind" "$1" && grep -q "/context" "$1"' _ "$TL"
check "req012 techlead.md continua <= 24000 bytes" bash -c '[ "$(wc -c < "$1" | tr -d " ")" -le 24000 ]' _ "$TL"

finish
