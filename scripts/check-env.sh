#!/usr/bin/env bash
# Verifica o ambiente para instalar o plugin sdd: CLI do Claude Code, git, marketplace e a pasta atual. SOMENTE LEITURA.
# Uso: bash check-env.sh [--net] [--dir <pasta>]      (--net também testa o acesso ao GitHub com git ls-remote)
# Sai com 0 se está tudo pronto e com 1 se faltar algo. Passo a passo: docs/instalacao.md. Sem eval, sem escrita, bash 3.2+.

LC_ALL=C
export LC_ALL

SDD_VERSION="0.12.0"            # versão do framework (o teste confere com plugin.json)
MIN_CLAUDE="2.1.288"
REPO_URL="https://github.com/powerlok/claude-sdd-framework.git"
DOC="docs/instalacao.md"

NET=no
DIR="$PWD"
while [ $# -gt 0 ]; do
  case "$1" in
    --net) NET=yes ;;
    --dir) shift; DIR="${1:-$PWD}" ;;
    -h|--help) sed -n '2,4p' "$0"; exit 0 ;;
    *) echo "uso: check-env.sh [--net] [--dir <pasta>]"; exit 2 ;;
  esac
  shift
done
[ -d "$DIR" ] || { echo "pasta não encontrada: $DIR"; exit 2; }
cd "$DIR" || exit 2

case "$(uname -s 2>/dev/null)" in
  Darwin*) OS=macos ;;
  MINGW*|MSYS*|CYGWIN*) OS=windows ;;
  *) OS=linux ;;
esac

FAIL=0
NEXT=""
ok()   { printf '  [OK]     %s\n' "$1"; }
warn() { printf '  [AVISO]  %s\n' "$1"; if [ -n "${2:-}" ]; then printf '           -> %s\n' "$2"; fi; return 0; }
miss() {
  printf '  [FALTA]  %s\n' "$1"
  if [ -n "${2:-}" ]; then printf '           -> %s\n' "$2"; fi
  FAIL=1
  if [ -z "$NEXT" ]; then NEXT="${3:-$2}"; fi
  return 0
}

# a >= b para versões X.Y.Z (só números).
ver_ge() {
  local IFS=. i
  local -a x y
  read -r -a x <<< "$1"; read -r -a y <<< "$2"
  for i in 0 1 2; do
    [ "${x[$i]:-0}" -gt "${y[$i]:-0}" ] && return 0
    [ "${x[$i]:-0}" -lt "${y[$i]:-0}" ] && return 1
  done
  return 0
}

echo "Verificação do ambiente (somente leitura) - sdd $SDD_VERSION"
echo
echo "1. Claude Code (CLI)"
CLAUDE=""
if command -v claude >/dev/null 2>&1; then
  CLAUDE="claude"
elif [ -x "$HOME/.local/bin/claude" ] || [ -x "$HOME/.local/bin/claude.exe" ]; then
  miss "claude está instalado, mas fora do PATH ($HOME/.local/bin)" 'export PATH="$PATH:$HOME/.local/bin"   (PowerShell: $env:Path += ";$HOME\.local\bin")' "Corrija o PATH ($DOC#a-máquina-sem-claude-code)"
else
  case "$OS" in
    windows) fix='PowerShell: irm https://claude.ai/install.ps1 | iex' ;;
    *)       fix='curl -fsSL https://claude.ai/install.sh | bash' ;;
  esac
  miss "claude não encontrado" "$fix" "Instale o Claude Code: $fix (detalhes: $DOC#a-máquina-sem-claude-code)"
fi

if [ -n "$CLAUDE" ]; then
  v="$("$CLAUDE" --version 2>/dev/null | head -n 1)"
  num="$(printf '%s' "$v" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n 1)"
  if [ -z "$num" ]; then
    warn "não consegui ler a versão de 'claude --version' ($v)"
  elif ver_ge "$num" "$MIN_CLAUDE"; then
    ok "claude $num (mínimo $MIN_CLAUDE)"
  else
    miss "claude $num é anterior ao mínimo $MIN_CLAUDE" "claude update" "Atualize o Claude Code: claude update"
  fi
  if "$CLAUDE" auth status >/dev/null 2>&1; then
    ok "login feito (claude auth status)"
  else
    miss "sem login no Claude Code" "claude auth login   (ou rode claude e siga o login no navegador)" "Faça login: rode claude (ou claude auth login) e siga o navegador"
  fi
fi

echo
echo "2. Git e shell"
if command -v git >/dev/null 2>&1; then
  ok "$(git --version 2>/dev/null | head -n 1)"
else
  case "$OS" in
    windows) fix='instale o Git for Windows: https://git-scm.com/download/win (traz o Git Bash)' ;;
    macos)   fix='xcode-select --install   (ou: brew install git)' ;;
    *)       fix='sudo apt install git   (ou o gerenciador da sua distro)' ;;
  esac
  miss "git não encontrado" "$fix" "Instale o git: $fix"
fi
if command -v bash >/dev/null 2>&1; then
  ok "bash disponível (os hooks do plugin usam bash)"
else
  miss "bash não encontrado" "instale o Git for Windows (traz o Git Bash)" "Instale o Git for Windows (traz o Git Bash)"
fi

if [ "$NET" = yes ]; then
  echo
  echo "3. Rede (GitHub)"
  if command -v git >/dev/null 2>&1 && GIT_TERMINAL_PROMPT=0 git ls-remote --heads "$REPO_URL" >/dev/null 2>&1; then
    ok "git ls-remote do repositório do framework funcionou"
  else
    miss "sem acesso a $REPO_URL" "git ls-remote $REPO_URL   (veja proxy/firewall/DNS)" "Resolva o acesso ao github.com (proxy, firewall ou DNS)"
  fi
fi

echo
echo "4. Marketplace do framework (nesta máquina)"
MP_OK=no
if [ -n "$CLAUDE" ]; then
  mp="$("$CLAUDE" plugin marketplace list 2>/dev/null)"
  if printf '%s\n' "$mp" | grep -q 'claude-sdd-framework'; then
    src="$(printf '%s\n' "$mp" | grep -A3 'claude-sdd-framework' | grep -m1 'Source:')"
    if printf '%s' "$src" | grep -q "@v$SDD_VERSION"; then
      ok "claude-sdd-framework registrado em v$SDD_VERSION"; MP_OK=yes
    elif printf '%s' "$src" | grep -q '@v'; then
      warn "registrado em outra versão:${src#*Source:}" "veja $DOC#e-atualizar-a-versão"; MP_OK=yes
    else
      warn "registrado sem versão fixada (acompanha a branch principal)" "para fixar a versão: $DOC#e-atualizar-a-versão"; MP_OK=yes
    fi
  else
    miss "marketplace claude-sdd-framework não registrado" "claude plugin marketplace add \"$REPO_URL#v$SDD_VERSION\"" "Registre o marketplace: claude plugin marketplace add \"$REPO_URL#v$SDD_VERSION\""
  fi
else
  warn "pulado (sem claude)"
fi

echo
echo "5. Pasta atual: $DIR"
# Tipo do projeto: workspace (sem git e com subrepositórios), novo (vazia), com código, já com sdd.
is_git=no
root=""
d="$PWD"; n=0
while [ "$n" -lt 20 ]; do
  [ -e "$d/.git" ] && { is_git=yes; root="$d"; break; }
  p="$(dirname "$d")"; [ "$p" = "$d" ] && break
  d="$p"; n=$((n + 1))
done
subrepos=0
for s in "$PWD"/*/; do [ -e "${s}.git" ] && subrepos=$((subrepos + 1)); done

entries=0
for f in "$PWD"/* "$PWD"/.[!.]*; do
  [ -e "$f" ] || continue
  case "${f##*/}" in .git|.claude|.vscode|.idea) continue ;; esac
  entries=$((entries + 1))
done
code=no
for m in package.json angular.json pyproject.toml requirements.txt pom.xml build.gradle build.gradle.kts go.mod Cargo.toml Dockerfile; do
  [ -e "$PWD/$m" ] && code=yes
done
for g in "$PWD"/*.csproj "$PWD"/*.sln "$PWD"/*.tf; do [ -e "$g" ] && code=yes; done

has_sdd=no
if [ -f "$PWD/.claude/settings.json" ] && grep -q 'sdd@claude-sdd-framework' "$PWD/.claude/settings.json" 2>/dev/null; then has_sdd=yes; fi

if [ "$is_git" = no ] && [ "$subrepos" -gt 0 ]; then
  echo "  Tipo: workspace com $subrepos repositórios (sem git na raiz)"
  warn "o sdd é instalado em cada projeto (repositório), não na pasta-mãe" "entre na pasta de um projeto e rode este script de novo ($DOC)"
  TYPE=workspace
elif [ "$has_sdd" = yes ]; then
  echo "  Tipo: D, projeto que já usa o sdd"
  TYPE=D
elif [ "$entries" -eq 0 ]; then
  echo "  Tipo: B, projeto novo (pasta vazia)"
  TYPE=B
elif [ "$code" = yes ]; then
  echo "  Tipo: C, projeto com código existente"
  TYPE=C
else
  echo "  Tipo: C, pasta com arquivos (sem manifesto de código conhecido)"
  TYPE=C
fi

if [ "$TYPE" != workspace ]; then
  if [ "$is_git" = yes ]; then
    ok "dentro de um repositório git"
    if [ -n "$root" ] && [ "$root" != "$PWD" ]; then
      warn "a raiz do repositório git é $root, acima desta pasta" "o sdd é instalado na raiz do repositório: rode este script (e os passos) em $root"
    fi
  else
    miss "a pasta não é um repositório git" "git init" "Crie o repositório: git init (a raiz do repositório é a raiz do projeto)"
  fi

  if [ -f "$PWD/.claude/settings.json" ]; then
    if [ "$has_sdd" = yes ]; then
      ok ".claude/settings.json declara o sdd"
      if grep -q '"agent"[[:space:]]*:[[:space:]]*"sdd:techlead"' "$PWD/.claude/settings.json"; then
        ok "agente da sessão = sdd:techlead"
      elif grep -q 'sdd:tecleader' "$PWD/.claude/settings.json"; then
        miss "o settings usa sdd:tecleader (removido na 0.11.0)" 'troque por "agent": "sdd:techlead"' 'Troque "agent": "sdd:tecleader" por "agent": "sdd:techlead" no .claude/settings.json'
      else
        warn "sem \"agent\": \"sdd:techlead\" no settings (a sessão não abre como TechLead)" 'acrescente "agent": "sdd:techlead" (modelo: templates/project-settings.git.json)'
      fi
    else
      miss ".claude/settings.json existe, mas não declara o sdd" "mescle o modelo templates/project-settings.git.json" "Mescle o modelo templates/project-settings.git.json no .claude/settings.json ($DOC)"
    fi
  else
    miss "sem .claude/settings.json" "copie templates/project-settings.git.json para .claude/settings.json" "Copie templates/project-settings.git.json para .claude/settings.json ($DOC)"
  fi

  if [ -n "$CLAUDE" ] && [ "$MP_OK" = yes ]; then
    # claude plugin list --json: um objeto por instalação (id, version, scope, enabled, projectPath). Compara com a raiz do projeto.
    here="${root:-$PWD}"
    here="$(cd "$here" 2>/dev/null && pwd -P || printf '%s' "$here")"   # caminho físico (macOS: /var é link para /private/var)
    if command -v cygpath >/dev/null 2>&1; then here="$(cygpath -ml "$here" 2>/dev/null || printf '%s' "$here")"; fi
    here="$(printf '%s' "$here" | tr 'A-Z' 'a-z')"
    found=""
    while IFS='|' read -r fscope fen fver fpp; do
      [ -n "$fscope" ] || continue
      fpp="$(printf '%s' "$fpp" | sed 's#[\]#/#g' | tr -s '/' | tr 'A-Z' 'a-z')"
      here_n="$(printf '%s' "$here" | tr -s '/')"
      # vale a instalação do usuário, do próprio projeto ou de uma pasta-mãe (o escopo project cobre as subpastas)
      case "$here_n/" in "$fpp"/*) [ -n "$fpp" ] && { found="$fscope|$fen|$fver"; break; } ;; esac
      if [ "$fscope" = user ]; then found="$fscope|$fen|$fver"; break; fi
    done <<EOF_LIST
$("$CLAUDE" plugin list --json 2>/dev/null | awk '
      function flush() { if (id == "sdd@claude-sdd-framework") print scope "|" en "|" ver "|" pp; id = ""; ver = ""; scope = ""; en = ""; pp = "" }
      /"id":/ { id = $2; gsub(/[",]/, "", id) }
      /"version":/ { ver = $2; gsub(/[",]/, "", ver) }
      /"scope":/ { scope = $2; gsub(/[",]/, "", scope) }
      /"enabled":/ { en = $2; gsub(/[",]/, "", en) }
      /"projectPath":/ { pp = $0; sub(/^[^:]*: *"/, "", pp); sub(/",? *$/, "", pp) }
      /^  }/ { flush() }')
EOF_LIST
    if [ -z "$found" ]; then
      miss "plugin sdd não instalado neste projeto" "claude plugin install sdd@claude-sdd-framework --scope project" "Instale o plugin na raiz do projeto: claude plugin install sdd@claude-sdd-framework --scope project"
    else
      fscope="${found%%|*}"; rest="${found#*|}"; fen="${rest%%|*}"; fver="${rest#*|}"
      if [ "$fen" = true ]; then
        ok "plugin sdd $fver instalado e habilitado (escopo $fscope)"
      else
        miss "plugin sdd $fver instalado, mas DESABILITADO (escopo $fscope)" "claude plugin enable sdd@claude-sdd-framework --scope $fscope" "Habilite o plugin: claude plugin enable sdd@claude-sdd-framework --scope $fscope"
      fi
    fi
  fi

  if [ -f "$PWD/CLAUDE.md" ] && grep -q '^## Stack' "$PWD/CLAUDE.md" 2>/dev/null; then
    ok "CLAUDE.md com ## Stack (onboarding feito)"
  else
    warn "sem CLAUDE.md com ## Stack: o onboarding ainda não foi feito" "abra o claude e rode /sdd:start (o TechLead cria o CLAUDE.md com a sua confirmação)"
  fi
fi

echo
if [ "$FAIL" -eq 0 ]; then
  echo "PRÓXIMO PASSO: abra o claude nesta pasta e digite /sdd:start"
  exit 0
fi
echo "PRÓXIMO PASSO: $NEXT"
exit 1
