#!/usr/bin/env bash
# REQ-003/005 (docs-install): scripts/check-env.ps1 (PowerShell) com `claude` falso. Roda onde há powershell.exe (Windows) ou pwsh;
# nos demais sistemas, o teste é pulado. .specs/done/docs-install/spec.md
. "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"
ROOT="$(cd "$HOOKS_DIR/../../.." && pwd)"
PS1="$ROOT/scripts/check-env.ps1"
VER="$(node -e 'process.stdout.write(JSON.parse(require("fs").readFileSync(process.argv[1],"utf8")).version)' "$ROOT/plugins/sdd/.claude-plugin/plugin.json")"

PSH="$(command -v powershell.exe 2>/dev/null || command -v pwsh 2>/dev/null || true)"
if [ -z "$PSH" ]; then
  ok "req014-ps1: sem PowerShell neste sistema, pulado"
  finish; exit $?
fi
case "$PSH" in *powershell.exe) WIN=yes ;; *) WIN=no ;; esac

new_sandbox
S="$SB/stubs"; mkdir -p "$S" "$SB/home"
w() { if command -v cygpath >/dev/null 2>&1; then cygpath -wl "$1"; else printf '%s' "$1"; fi; }
GITDIR="$(dirname "$(command -v git)")"

MP_OK="$SB/mp_ok.txt"; printf 'Configured marketplaces:\n\n  > claude-sdd-framework\n    Source: Git (https://github.com/powerlok/claude-sdd-framework.git@v%s)\n' "$VER" > "$MP_OK"
if [ "$WIN" = yes ]; then
  printf '%s\r\n' '@echo off' 'if "%1"=="--version" (echo %STUB_VERSION% (Claude Code)& exit /b 0)' 'if "%1"=="auth" exit /b %STUB_AUTH_RC%' 'if "%1 %2 %3"=="plugin marketplace list" (type "%STUB_MP_FILE%"& exit /b 0)' 'if "%1 %2 %3"=="plugin list --json" (if defined STUB_PLUGINS_FILE (type "%STUB_PLUGINS_FILE%") else (echo [])& exit /b 0)' 'exit /b 0' > "$S/claude.cmd"
else
  printf '%s\n' '#!/usr/bin/env bash' 'case "$1 $2 $3" in' '"--version  ") echo "$STUB_VERSION (Claude Code)";;' '"auth status "*) exit "$STUB_AUTH_RC";;' '"plugin marketplace list") cat "$STUB_MP_FILE";;' '"plugin list --json") if [ -n "$STUB_PLUGINS_FILE" ]; then cat "$STUB_PLUGINS_FILE"; else echo "[]"; fi;;' 'esac' > "$S/claude"
  chmod +x "$S/claude"
fi

plugins_json() { # <arquivo> <projectPath> <enabled>
  local pp; pp="$(w "$2" | sed 's/\\/\\\\/g')"
  printf '[\n  {\n    "id": "sdd@claude-sdd-framework",\n    "version": "%s",\n    "scope": "project",\n    "enabled": %s,\n    "projectPath": "%s"\n  }\n]\n' "$VER" "$3" "$pp" > "$1"
}

run() { # run <pasta> [-Net]
  local dir="$1"; shift
  env HOME="$SB/home" USERPROFILE="$(w "$SB/home")" PATH="$S:$GITDIR:$(dirname "$PSH"):/usr/bin:/bin" STUB_VERSION="${STUB_VERSION:-2.1.300}" STUB_AUTH_RC="${STUB_AUTH_RC:-0}" STUB_MP_FILE="$(w "$MP_OK")" STUB_PLUGINS_FILE="${STUB_PLUGINS_FILE:-}"     "$PSH" -NoProfile -ExecutionPolicy Bypass -File "$(w "$PS1")" -Dir "$(w "$dir")" "$@" > "$SB/ps.out" 2>&1
  RC=$?
  OUT="$(tr -d '' < "$SB/ps.out")"
}
has() { printf '%s\n' "$OUT" | grep -qF -- "$1"; }

# pasta vazia, sem git
E="$SB/novo"; mkdir -p "$E"; run "$E"
eq "req014-ps1 pasta vazia: exit 1" "1" "$RC"
check "req014-ps1 pasta vazia: tipo B" has "Tipo: B, projeto novo (pasta vazia)"
check "req014-ps1 pasta vazia: manda git init" has "git init"
check "req014-ps1 CLI e login OK" has "[OK]     login feito (claude auth status)"
check "req014-ps1 marketplace na versão atual" has "registrado em v$VER"

# versão antiga
STUB_VERSION=2.1.100 run "$E"
check "req014-ps1 versão antiga: FALTA e 'claude update'" bash -c 'echo "$1" | grep -q "é anterior ao mínimo" && echo "$1" | grep -q "claude update"' _ "$OUT"
STUB_VERSION=2.10.0 run "$E"
check "req014-ps1 2.10.0 > 2.1.288 (comparação de versão, não de texto)" has "[OK]     claude 2.10.0"

# sem login
STUB_AUTH_RC=1 run "$E"
check "req014-ps1 sem login: FALTA" has "[FALTA]  sem login no Claude Code"

# projeto com código, tipo C
C="$SB/codigo"; mkdir -p "$C"; ( cd "$C" && git init -q && printf '{}' > package.json )
run "$C"
check "req014-ps1 package.json: tipo C" has "Tipo: C, projeto com código existente"
check "req014-ps1 sem settings: manda copiar o modelo" has "[FALTA]  sem .claude/settings.json"

# tudo pronto: tipo D, plugin habilitado e CLAUDE.md
mkdir -p "$C/.claude"; cp "$ROOT/templates/project-settings.git.json" "$C/.claude/settings.json"
printf '# P\n\n## Stack\n- node\n' > "$C/CLAUDE.md"
PJ="$SB/pl.json"
plugins_json "$PJ" "$C" false; STUB_PLUGINS_FILE="$(w "$PJ")" run "$C"
check "req014-ps1 plugin desabilitado: FALTA e 'plugin enable'" bash -c 'echo "$1" | grep -q "DESABILITADO" && echo "$1" | grep -q "claude plugin enable sdd@claude-sdd-framework --scope project"' _ "$OUT"
plugins_json "$PJ" "$C" true; STUB_PLUGINS_FILE="$(w "$PJ")" run "$C"
eq "req014-ps1 tudo pronto: exit 0" "0" "$RC"
check "req014-ps1 tudo pronto: plugin habilitado e PRÓXIMO PASSO /sdd:start" bash -c 'echo "$1" | grep -q "plugin sdd '"$VER"' instalado e habilitado" && echo "$1" | grep -q "PRÓXIMO PASSO: abra o claude nesta pasta e digite /sdd:start"' _ "$OUT"
plugins_json "$PJ" "$SB/outro" true; STUB_PLUGINS_FILE="$(w "$PJ")" run "$C"
check "req014-ps1 plugin de outro projeto não conta" has "plugin sdd não instalado neste projeto"

# workspace
W="$SB/ws"; mkdir -p "$W/a" "$W/b"; ( cd "$W/a" && git init -q ); ( cd "$W/b" && git init -q )
run "$W"
check "req014-ps1 workspace" has "Tipo: workspace com 2 repositórios"

# arquivo: SDD_VERSION e BOM UTF-8 (PowerShell 5.1 lê sem BOM como ANSI e quebra os acentos)
check "req014-ps1 script tem BOM UTF-8" bash -c '[ "$(head -c 3 "$1" | od -An -tx1 | tr -d " ")" = "efbbbf" ]' _ "$PS1"

drop_sandbox
finish
