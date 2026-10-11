#!/usr/bin/env bash
# sdd: verificação de onboarding no início da sessão (SessionStart, matcher "startup").
# REQ-001 (.specs/done/onboarding-check/spec.md); git/subrepos: REQ-002 (.specs/done/specs-location/spec.md);
# claude_dir/specs_dir: REQ-001 (.specs/done/workspace-multi-project/spec.md).
# SOMENTE LEITURA: sem rede, sem escrita, sem eval, não executa nada do projeto.
# Só testa existência de arquivos no nível raiz e lê CLAUDE.md com grep -q (nada é ecoado).
# Para git/subrepos só testa existência de ".git" (pasta, ancestrais até 20 níveis, subpastas diretas); nunca executa o git.
# A saída contém apenas constantes do script e contagens: nenhum texto vindo do projeto.
# Nunca aborta a sessão: sem "set -e" e sempre "exit 0".

LC_ALL=C
export LC_ALL

dir="${CLAUDE_PROJECT_DIR:-$PWD}"

if [ ! -d "$dir" ]; then
  printf '%s\n' "[sdd:onboarding] error=project_dir_not_found"
  printf '%s\n' "TechLead: trate este diagnostico na primeira resposta (secao 'Inicio de sessao' do agente)."
  exit 0
fi

# Base para montar caminhos sem barra dupla: com dir="/", "//x" e lido como servidor de rede no Git Bash.
base="${dir%/}"

claude_md=no
stack=no
specs_index=no
empty=yes

if [ -f "$base/CLAUDE.md" ]; then
  claude_md=yes
  # Não segue symlink (evita ler fora do projeto) e limita a leitura a 1 MiB (arquivo enorme sem quebra de linha).
  if [ ! -L "$base/CLAUDE.md" ] && head -c 1048576 -- "$base/CLAUDE.md" 2>/dev/null | grep -q -- '^## Stack'; then
    stack=yes
  fi
fi

if [ -f "$base/.specs/INDEX.md" ]; then
  specs_index=yes
fi

# Pasta vazia: ignora .git, .claude, .vscode e .idea (inclui arquivos ocultos).
for entry in "$base"/* "$base"/.[!.]* "$base"/..?*; do
  [ -e "$entry" ] || [ -L "$entry" ] || continue
  case "${entry##*/}" in
    .git|.claude|.vscode|.idea) continue ;;
  esac
  empty=no
  break
done

# Manifestos de stack somente no nível raiz (sem varrer subpastas).
# Segurança: NUNCA imprimir nomes vindos de glob — um nome com quebra de linha ou texto hostil
# forjaria o diagnóstico no contexto da sessão. Nomes fixos são impressos como constantes;
# padrões (*.csproj, *.sln, *.tf) aparecem só como padrão + quantidade.
manifests=""
add() {
  if [ -z "$manifests" ]; then manifests="$1"; else manifests="$manifests,$1"; fi
}
for name in package.json angular.json pyproject.toml requirements.txt pom.xml \
  build.gradle build.gradle.kts go.mod Cargo.toml Dockerfile; do
  [ -f "$base/$name" ] && add "$name"
done
for pattern in csproj sln tf; do
  n=0
  for entry in "$base"/*."$pattern"; do
    [ -f "$entry" ] && n=$((n + 1))
  done
  [ "$n" -gt 0 ] && add "*.$pattern($n)"
done
[ -n "$manifests" ] || manifests=none

# Situacao git SEM executar o git (o git pode executar comandos configurados no repositorio):
# so testes de existencia de ".git" (arquivo ou diretorio) no sistema de arquivos.
# git=root (.git na pasta), git=inside (.git num ancestral, ate 20 niveis), git=none.
has_git() {
  [ -e "$1/.git" ] || [ -L "$1/.git" ]
}
git=none
if has_git "$dir"; then
  git=root
else
  # Normaliza separadores do Windows (\ -> /) e remove barras finais.
  bs='\'
  p="${dir//"$bs"//}"
  while [ "${#p}" -gt 1 ] && [ "${p%/}" != "$p" ]; do p="${p%/}"; done
  i=0
  while [ "$i" -lt 20 ]; do
    i=$((i + 1))
    case "$p" in
      */*) parent="${p%/*}" ;;
      *) break ;;
    esac
    [ -n "$parent" ] || parent="/"
    [ "$parent" != "$p" ] || break
    if [ "$parent" = "/" ]; then
      [ -e "/.git" ] || [ -L "/.git" ] && git=inside
      break
    fi
    if has_git "$parent"; then
      git=inside
      break
    fi
    # Raiz de unidade (ex.: C: ou /c): ja verificada, parar.
    case "$parent" in
      [A-Za-z]:|/[A-Za-z]) break ;;
    esac
    p="$parent"
  done
fi

# claude_dir/specs_dir: so existencia de pasta no nivel raiz (sem ler conteudo); symlink conta como "no" (nao seguir).
# REQ-001 (.specs/done/workspace-multi-project/spec.md).
claude_dir=no
if [ -d "$base/.claude" ] && [ ! -L "$base/.claude" ]; then
  claude_dir=yes
fi
specs_dir=no
if [ -d "$base/.specs" ] && [ ! -L "$base/.specs" ]; then
  specs_dir=yes
fi

# subrepos: subpastas DIRETAS com .git (sem recursao, sem seguir symlink; so a contagem, nunca nomes).
subrepos=0
for entry in "$base"/* "$base"/.[!.]* "$base"/..?*; do
  [ -d "$entry" ] || continue
  [ -L "$entry" ] && continue
  case "${entry##*/}" in
    .git) continue ;;
  esac
  has_git "$entry" && subrepos=$((subrepos + 1))
done

printf '%s\n' "[sdd:onboarding] claude_md=$claude_md stack=$stack specs_index=$specs_index empty=$empty manifests=$manifests git=$git subrepos=$subrepos claude_dir=$claude_dir specs_dir=$specs_dir"
printf '%s\n' "TechLead: trate este diagnostico na primeira resposta (secao 'Inicio de sessao' do agente)."
exit 0
