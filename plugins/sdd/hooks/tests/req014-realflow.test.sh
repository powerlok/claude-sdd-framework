#!/usr/bin/env bash
# REQ-005f (docs-install): o fluxo de instalação do tipo F (marketplace por caminho local → install → list → check-env) executado com o
# claude REAL numa configuração temporária (CLAUDE_CONFIG_DIR), sem tocar na configuração do usuário nem usar a rede. Pulado sem claude.
. "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"
ROOT="$(cd "$HOOKS_DIR/../../.." && pwd)"
VER="$(node -e 'process.stdout.write(JSON.parse(require("fs").readFileSync(process.argv[1],"utf8")).version)' "$ROOT/plugins/sdd/.claude-plugin/plugin.json")"

CL=""
for c in claude "$HOME/.local/bin/claude" "$HOME/.local/bin/claude.exe"; do
  if "$c" --version >/dev/null 2>&1; then CL="$c"; break; fi
done
if [ -z "$CL" ]; then ok "req014-realflow: sem claude neste sistema, pulado"; finish; exit $?; fi

new_sandbox
CFG="$SB/cfg"; PRJ="$SB/meu-projeto"; mkdir -p "$CFG" "$PRJ"
export CLAUDE_CONFIG_DIR="$CFG"
RM="$ROOT"; PM="$PRJ"
if command -v cygpath >/dev/null 2>&1; then RM="$(cygpath -ml "$ROOT")"; PM="$(cygpath -ml "$PRJ")"; fi
cd "$PRJ" || exit 1
git init -q

# passo 3 (tipo F): modelo local com o placeholder trocado pelo caminho do clone
mkdir -p .claude
sed "s|<CAMINHO_ABSOLUTO_DO_CLONE_claude-sdd-framework>|$RM|g" "$ROOT/templates/project-settings.local.json" > .claude/settings.json
check "req014-realflow: settings gerado sem placeholder" bash -c '! grep -q "CAMINHO_ABSOLUTO" .claude/settings.json'
check "req014-realflow: settings declara o sdd e o TechLead" bash -c 'grep -q "sdd@claude-sdd-framework" .claude/settings.json && grep -q "\"agent\": \"sdd:techlead\"" .claude/settings.json'

# antes de instalar: o verificador aponta o que falta
OUT="$(bash "$ROOT/scripts/check-env.sh" 2>&1)"
check "req014-realflow: antes do add, o verificador manda registrar o marketplace ou instalar o plugin" bash -c 'echo "$1" | grep -qE "marketplace claude-sdd-framework não registrado|plugin sdd não instalado"' _ "$OUT"

# registrar o marketplace e instalar o plugin (os comandos do guia)
OUT="$("$CL" plugin marketplace add "$RM" --scope project 2>&1)"; rc=$?
eq "req014-realflow: marketplace add (caminho local) sai com 0" "0" "$rc"
check "req014-realflow: marketplace add confirma" bash -c 'echo "$1" | grep -qi "successfully added marketplace"' _ "$OUT"
OUT="$("$CL" plugin install sdd@claude-sdd-framework --scope project 2>&1)"; rc=$?
eq "req014-realflow: plugin install --scope project sai com 0" "0" "$rc"
check "req014-realflow: plugin install confirma" bash -c 'echo "$1" | grep -qi "successfully installed"' _ "$OUT"

# conferir: claude plugin list e o JSON
OUT="$("$CL" plugin list 2>&1)"
check "req014-realflow: plugin list mostra sdd $VER, project, enabled" bash -c 'echo "$1" | grep -q "Version: '"$VER"'" && echo "$1" | grep -q "Scope: project" && echo "$1" | grep -qi "enabled"' _ "$OUT"
JS="$("$CL" plugin list --json 2>&1)"
check "req014-realflow: plugin list --json traz id, enabled e projectPath" bash -c 'echo "$1" | grep -q "\"id\": \"sdd@claude-sdd-framework\"" && echo "$1" | grep -q "\"enabled\": true" && echo "$1" | grep -q "projectPath"' _ "$JS"

# depois de instalar: o verificador reconhece o plugin habilitado (login e CLAUDE.md ficam pendentes: sem conta nesta configuração)
OUT="$(bash "$ROOT/scripts/check-env.sh" 2>&1)"
check "req014-realflow: verificador reconhece o plugin habilitado neste projeto" bash -c 'echo "$1" | grep -q "plugin sdd '"$VER"' instalado e habilitado"' _ "$OUT"
check "req014-realflow: verificador reconhece o tipo D (settings com sdd) e o agente" bash -c 'echo "$1" | grep -q "Tipo: D" && echo "$1" | grep -q "agente da sessão = sdd:techlead"' _ "$OUT"
check "req014-realflow: onboarding ainda pendente (aviso com /sdd:start)" bash -c 'echo "$1" | grep -q "/sdd:start"' _ "$OUT"

# desabilitar e conferir que o verificador detecta (claude plugin disable)
"$CL" plugin disable sdd@claude-sdd-framework --scope project >/dev/null 2>&1
OUT="$(bash "$ROOT/scripts/check-env.sh" 2>&1)"
check "req014-realflow: com o plugin desabilitado o verificador manda habilitar" bash -c 'echo "$1" | grep -q "DESABILITADO" && echo "$1" | grep -q "claude plugin enable sdd@claude-sdd-framework --scope project"' _ "$OUT"
"$CL" plugin enable sdd@claude-sdd-framework --scope project >/dev/null 2>&1
OUT="$(bash "$ROOT/scripts/check-env.sh" 2>&1)"
check "req014-realflow: reabilitado volta a OK" bash -c 'echo "$1" | grep -q "instalado e habilitado"' _ "$OUT"

# o plugin que acabou de ser instalado passa na validação estrita
OUT="$("$CL" plugin validate "$RM/plugins/sdd" --strict 2>&1)"; rc=$?
eq "req014-realflow: plugin validate --strict sai com 0" "0" "$rc"

cd / || true
drop_sandbox
finish
