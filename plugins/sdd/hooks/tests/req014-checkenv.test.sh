#!/usr/bin/env bash
# REQ-003/005 (docs-install): scripts/check-env.sh com `claude` falso em cada situação (sem CLI, versão antiga, sem login, sem marketplace,
# pasta vazia, código existente, já com sdd, plugin desabilitado, tudo pronto, workspace). .specs/done/docs-install/spec.md
. "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"
ROOT="$(cd "$HOOKS_DIR/../../.." && pwd)"
CE="$ROOT/scripts/check-env.sh"
VER="$(node -e 'process.stdout.write(JSON.parse(require("fs").readFileSync(process.argv[1],"utf8")).version)' "$ROOT/plugins/sdd/.claude-plugin/plugin.json")"
REL="$(node -e 'process.stdout.write(JSON.parse(require("fs").readFileSync(process.argv[1],"utf8")).metadata.version)' "$ROOT/.claude-plugin/marketplace.json")"   # versão LANÇADA (tag)

new_sandbox
S="$SB/stubs"; mkdir -p "$S"
GITDIR="$(dirname "$(command -v git)")"

# claude falso: o comportamento vem de variáveis STUB_* e de arquivos.
cat > "$S/claude" <<'STUB'
#!/usr/bin/env bash
case "$1 $2 $3" in
  "--version  ") echo "${STUB_VERSION:-2.1.300} (Claude Code)" ;;
  "auth status "*) exit "${STUB_AUTH_RC:-0}" ;;
  "plugin marketplace list") [ -n "${STUB_MP_FILE:-}" ] && cat "$STUB_MP_FILE" ;;
  "plugin list --json") [ -n "${STUB_PLUGINS_FILE:-}" ] && cat "$STUB_PLUGINS_FILE" || echo "[]" ;;
  *) exit 0 ;;
esac
STUB
chmod +x "$S/claude"
MP_OK="$SB/mp_ok.txt";  printf 'Configured marketplaces:\n\n  ❯ claude-sdd-framework\n    Source: Git (https://github.com/powerlok/claude-sdd-framework.git@v%s)\n' "$VER" > "$MP_OK"
MP_OLD="$SB/mp_old.txt"; printf 'Configured marketplaces:\n\n  ❯ claude-sdd-framework\n    Source: Git (https://github.com/powerlok/claude-sdd-framework.git@v0.9.4)\n' > "$MP_OLD"
MP_NONE="$SB/mp_none.txt"; printf 'Configured marketplaces:\n\n  ❯ claude-plugins-official\n    Source: GitHub (anthropics/claude-plugins-official)\n' > "$MP_NONE"

plugins_json() { # plugins_json <arquivo> <projectPath> <enabled>
  printf '[\n  {\n    "id": "sdd@claude-sdd-framework",\n    "version": "%s",\n    "scope": "project",\n    "enabled": %s,\n    "installPath": "x",\n    "projectPath": "%s",\n    "mcpServers": {\n      "drawio": {\n        "command": "node"\n      }\n    }\n  }\n]\n' "$VER" "$3" "$2" > "$1"
}
jpath() { # caminho do JSON como o CLI imprime (barras duplas no Windows)
  local p="$1"
  if command -v cygpath >/dev/null 2>&1; then p="$(cygpath -wl "$p" | sed 's/\\/\\\\/g')"; fi
  printf '%s' "$p"
}

# Roda o script numa pasta com PATH controlado (stub do claude + git real + utilitários do sistema).
run() { # run <pasta> [com_claude=yes|no] [args...]
  local dir="$1" wc="${2:-yes}"; shift 2
  local P
  if [ "$wc" = yes ]; then P="$S:$GITDIR:/usr/bin:/bin"; else P="$GITDIR:/usr/bin:/bin"; fi
  OUT="$(env -i HOME="$SB/home" PATH="$P" LANG=C TMPDIR="$TMPDIR" STUB_VERSION="${STUB_VERSION:-2.1.300}" STUB_AUTH_RC="${STUB_AUTH_RC:-0}" STUB_MP_FILE="${STUB_MP_FILE:-}" STUB_PLUGINS_FILE="${STUB_PLUGINS_FILE:-}" bash "$CE" --dir "$dir" "$@" 2>&1)"
  RC=$?
}
has() { printf '%s\n' "$OUT" | grep -qF -- "$1"; }
mkdir -p "$SB/home"

# 1) sem claude (só se o sistema de teste não tiver um claude em /usr/bin ou ao lado do git)
if PATH="$GITDIR:/usr/bin:/bin" command -v claude >/dev/null 2>&1; then
  ok "req014 sem claude: pulado (há um claude no PATH do sistema)"
else
  E="$SB/e1"; mkdir -p "$E"; run "$E" no
  eq "req014 sem claude: exit 1" "1" "$RC"
  check "req014 sem claude: [FALTA] claude não encontrado" has "[FALTA]  claude não encontrado"
  check "req014 sem claude: manda instalar com o instalador oficial" bash -c 'echo "$1" | grep -qE "claude.ai/install\.(sh|ps1)"' _ "$OUT"
  check "req014 sem claude: aponta a seção A da instalação" has "docs/instalacao.md#a-máquina-sem-claude-code"
  check "req014 sem claude: PRÓXIMO PASSO é instalar" bash -c 'echo "$1" | grep -q "PRÓXIMO PASSO: Instale o Claude Code"' _ "$OUT"
fi

# 2) versão antiga
E="$SB/e2"; mkdir -p "$E"; STUB_VERSION=2.1.100 STUB_MP_FILE="$MP_OK" run "$E" yes
check "req014 versão antiga: FALTA e manda 'claude update'" bash -c 'echo "$1" | grep -q "é anterior ao mínimo" && echo "$1" | grep -q "claude update"' _ "$OUT"
eq "req014 versão antiga: exit 1" "1" "$RC"
STUB_VERSION=2.1.288 STUB_MP_FILE="$MP_OK" run "$E" yes
check "req014 versão igual ao mínimo (2.1.288) passa" has "[OK]     claude 2.1.288"
STUB_VERSION=2.10.0 STUB_MP_FILE="$MP_OK" run "$E" yes
check "req014 versão 2.10.0 > 2.1.288 (comparação numérica, não de texto)" has "[OK]     claude 2.10.0"

# 3) sem login
STUB_AUTH_RC=1 STUB_MP_FILE="$MP_OK" run "$E" yes
check "req014 sem login: FALTA e manda 'claude auth login'" bash -c 'echo "$1" | grep -q "sem login" && echo "$1" | grep -q "claude auth login"' _ "$OUT"

# 4) sem marketplace
STUB_MP_FILE="$MP_NONE" run "$E" yes
check "req014 sem marketplace: manda registrar com a versão atual" has "claude plugin marketplace add \"https://github.com/powerlok/claude-sdd-framework.git#v$REL\""
STUB_MP_FILE="$MP_OLD" run "$E" yes
check "req014 marketplace em outra versão: AVISO (não falha) e aponta a seção E" bash -c 'echo "$1" | grep -q "AVISO.*outra versão" && echo "$1" | grep -q "instalacao.md#e-atualizar-a-versão"' _ "$OUT"

# 5) pasta vazia sem git => tipo B, manda git init
E="$SB/novo"; mkdir -p "$E"; STUB_MP_FILE="$MP_OK" run "$E" yes
check "req014 pasta vazia: tipo B" has "Tipo: B, projeto novo (pasta vazia)"
check "req014 pasta vazia: manda git init" has "-> git init"
check "req014 pasta vazia: PRÓXIMO PASSO = git init" bash -c 'echo "$1" | grep -q "PRÓXIMO PASSO: Crie o repositório: git init"' _ "$OUT"

# 6) git init feito => manda copiar o settings
( cd "$E" && git init -q ) ; STUB_MP_FILE="$MP_OK" run "$E" yes
check "req014 repo vazio: FALTA .claude/settings.json" has "[FALTA]  sem .claude/settings.json"
check "req014 repo vazio: PRÓXIMO PASSO = copiar o modelo" bash -c 'echo "$1" | grep -q "PRÓXIMO PASSO: Copie templates/project-settings.git.json"' _ "$OUT"

# 7) código existente => tipo C
E="$SB/codigo"; mkdir -p "$E"; ( cd "$E" && git init -q && printf '{}' > package.json && mkdir src )
STUB_MP_FILE="$MP_OK" run "$E" yes
check "req014 com package.json: tipo C" has "Tipo: C, projeto com código existente"
E2="$SB/dotnet"; mkdir -p "$E2"; ( cd "$E2" && git init -q && : > App.csproj )
STUB_MP_FILE="$MP_OK" run "$E2" yes
check "req014 com .csproj: tipo C" has "Tipo: C, projeto com código existente"

# 8) settings com sdd mas plugin não instalado => tipo D, manda instalar
mkdir -p "$E/.claude"; cp "$ROOT/templates/project-settings.git.json" "$E/.claude/settings.json"
STUB_MP_FILE="$MP_OK" run "$E" yes
check "req014 settings com sdd: tipo D" has "Tipo: D, projeto que já usa o sdd"
check "req014 settings com sdd + agent techlead: OK" has "[OK]     agente da sessão = sdd:techlead"
check "req014 plugin não instalado: manda 'plugin install --scope project'" has "claude plugin install sdd@claude-sdd-framework --scope project"
eq "req014 plugin não instalado: exit 1" "1" "$RC"

# 9) instalado em OUTRO projeto não conta; instalado e desabilitado; instalado e habilitado
PJ="$SB/pl.json"; HERE="$(cd "$E" && pwd -P)"
plugins_json "$PJ" "$(jpath "$SB/outro")" true
STUB_MP_FILE="$MP_OK" STUB_PLUGINS_FILE="$PJ" run "$E" yes
check "req014 plugin instalado em outro projeto: não conta" has "plugin sdd não instalado neste projeto"
plugins_json "$PJ" "$(jpath "$HERE")" false
STUB_MP_FILE="$MP_OK" STUB_PLUGINS_FILE="$PJ" run "$E" yes
check "req014 plugin desabilitado: FALTA e manda 'plugin enable'" bash -c 'echo "$1" | grep -q "DESABILITADO" && echo "$1" | grep -q "claude plugin enable sdd@claude-sdd-framework --scope project"' _ "$OUT"
plugins_json "$PJ" "$(jpath "$HERE")" true
STUB_MP_FILE="$MP_OK" STUB_PLUGINS_FILE="$PJ" run "$E" yes
check "req014 plugin habilitado: OK (com versão)" has "[OK]     plugin sdd $VER instalado e habilitado (escopo project)"
check "req014 sem CLAUDE.md: AVISO manda rodar /sdd:start" bash -c 'echo "$1" | grep -q "AVISO.*onboarding" && echo "$1" | grep -q "/sdd:start"' _ "$OUT"
# projeto numa subpasta do que foi instalado (escopo project vale para as subpastas)
mkdir -p "$E/sub"; plugins_json "$PJ" "$(jpath "$HERE")" true
STUB_MP_FILE="$MP_OK" STUB_PLUGINS_FILE="$PJ" run "$E/sub" yes
check "req014 subpasta do projeto instalado: plugin conta" has "plugin sdd $VER instalado e habilitado"
check "req014 subpasta: avisa que a raiz do repositório git está acima" has "a raiz do repositório git é"

# 10) tudo pronto: exit 0 e PRÓXIMO PASSO = /sdd:start
printf '# P\n\n## Stack\n- node\n' > "$E/CLAUDE.md"
STUB_MP_FILE="$MP_OK" STUB_PLUGINS_FILE="$PJ" run "$E" yes
eq "req014 tudo pronto: exit 0" "0" "$RC"
check "req014 tudo pronto: PRÓXIMO PASSO = abrir o claude e /sdd:start" has "PRÓXIMO PASSO: abra o claude nesta pasta e digite /sdd:start"
check "req014 tudo pronto: nenhum [FALTA]" bash -c '! echo "$1" | grep -q "\[FALTA\]"' _ "$OUT"

# 11) agente antigo no settings
sed 's/"agent": "sdd:techlead"/"agent": "sdd:tecleader"/' "$ROOT/templates/project-settings.git.json" > "$E/.claude/settings.json"
STUB_MP_FILE="$MP_OK" STUB_PLUGINS_FILE="$PJ" run "$E" yes
check "req014 sdd:tecleader no settings: FALTA com a correção" bash -c 'echo "$1" | grep -q "sdd:tecleader (removido na 0.11.0)" && echo "$1" | grep -q "sdd:techlead"' _ "$OUT"
eq "req014 sdd:tecleader: exit 1" "1" "$RC"

# 12) settings existente sem sdd => manda mesclar
mkdir -p "$E2/.claude"; printf '{ "permissions": { "allow": [] } }\n' > "$E2/.claude/settings.json"
STUB_MP_FILE="$MP_OK" run "$E2" yes
check "req014 settings sem sdd: manda mesclar o modelo (não sobrescrever)" has "[FALTA]  .claude/settings.json existe, mas não declara o sdd"

# 13) workspace: pasta sem git com subrepositórios
W="$SB/ws"; mkdir -p "$W/a" "$W/b"; ( cd "$W/a" && git init -q ); ( cd "$W/b" && git init -q )
STUB_MP_FILE="$MP_OK" run "$W" yes
check "req014 workspace: tipo workspace, manda entrar num projeto" bash -c 'echo "$1" | grep -q "Tipo: workspace com 2 repositórios" && echo "$1" | grep -q "entre na pasta de um projeto"' _ "$OUT"

# 14) somente leitura: nada é criado nem alterado
snap() { ( cd "$1" && find . -type f -not -path './.git/*' | sort | xargs -I{} cksum "{}" 2>/dev/null; find . -type d -not -path './.git*' | sort ); }
B1="$(snap "$E")"; STUB_MP_FILE="$MP_OK" STUB_PLUGINS_FILE="$PJ" run "$E" yes; B2="$(snap "$E")"
eq "req014 somente leitura: a pasta do projeto não muda" "$B1" "$B2"
# git que registra as chamadas e delega ao git real: ls-remote só com --net
cat > "$S/git" <<STUBGIT
#!/usr/bin/env bash
echo "\$*" >> "$SB/git.log"
exec "$GITDIR/git" "\$@"
STUBGIT
chmod +x "$S/git"
: > "$SB/git.log"; STUB_MP_FILE="$MP_OK" STUB_PLUGINS_FILE="$PJ" run "$E" yes
check "req014 sem --net não consulta a rede (nenhum ls-remote)" bash -c '! grep -q "ls-remote" "$1"' _ "$SB/git.log"
STUB_MP_FILE="$MP_OK" STUB_PLUGINS_FILE="$PJ" run "$E" yes --net
check "req014 com --net testa o GitHub (ls-remote do repositório do framework)" grep -q "ls-remote --heads https://github.com/powerlok/claude-sdd-framework.git" "$SB/git.log"
check "req014 com --net a seção 3 (Rede) aparece" has "3. Rede (GitHub)"
rm -f "$S/git"

# 15) argumentos
bash "$CE" --bogus >/dev/null 2>&1; eq "req014 argumento inválido: exit 2" "2" "$?"
bash "$CE" --dir /nao/existe >/dev/null 2>&1; eq "req014 pasta inexistente: exit 2" "2" "$?"
check "req014 --help mostra o uso" bash -c 'bash "$1" --help | grep -q "Uso: bash check-env.sh"' _ "$CE"

# 16) higiene do script
check "req014 script: nenhum eval/curl/wget executado" bash -c '! grep -nE "^[[:space:]]*(eval|curl|wget)[[:space:]]|[$][(](curl|wget|eval)" "$1"' _ "$CE"
check "req014 script: nenhuma escrita em arquivo (só /dev/null e saída padrão)" bash -c '! grep -nE "[^<>2&-]>[[:space:]]*\"?[$A-Za-z./]" "$1" | grep -vE "/dev/null|>&2|-> "' _ "$CE"
check "req014 script: SDD_VERSION = versão lançada ($REL)" grep -q "SDD_VERSION=\"$REL\"" "$CE"

drop_sandbox
finish
