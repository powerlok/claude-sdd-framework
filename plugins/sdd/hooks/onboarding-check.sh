#!/usr/bin/env bash
# sdd: verificação de onboarding no início da sessão (SessionStart, matcher "startup").
# REQ-001 (.specs/done/onboarding-check/spec.md).
# SOMENTE LEITURA: sem rede, sem escrita, sem eval, não executa nada do projeto.
# Só testa existência de arquivos no nível raiz e lê CLAUDE.md com grep -q (nada é ecoado).
# A saída contém apenas constantes do script e contagens: nenhum texto vindo do projeto.
# Nunca aborta a sessão: sem "set -e" e sempre "exit 0".

LC_ALL=C
export LC_ALL

dir="${CLAUDE_PROJECT_DIR:-$PWD}"

if [ ! -d "$dir" ]; then
  printf '%s\n' "[sdd:onboarding] error=project_dir_not_found"
  printf '%s\n' "TecLeader: trate este diagnostico na primeira resposta (secao 'Inicio de sessao' do agente)."
  exit 0
fi

claude_md=no
stack=no
specs_index=no
empty=yes

if [ -f "$dir/CLAUDE.md" ]; then
  claude_md=yes
  # Não segue symlink (evita ler fora do projeto) e limita a leitura a 1 MiB (arquivo enorme sem quebra de linha).
  if [ ! -L "$dir/CLAUDE.md" ] && head -c 1048576 -- "$dir/CLAUDE.md" 2>/dev/null | grep -q -- '^## Stack'; then
    stack=yes
  fi
fi

if [ -f "$dir/.specs/INDEX.md" ]; then
  specs_index=yes
fi

# Pasta vazia: ignora .git, .claude, .vscode e .idea (inclui arquivos ocultos).
for entry in "$dir"/* "$dir"/.[!.]* "$dir"/..?*; do
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
  [ -f "$dir/$name" ] && add "$name"
done
for pattern in csproj sln tf; do
  n=0
  for entry in "$dir"/*."$pattern"; do
    [ -f "$entry" ] && n=$((n + 1))
  done
  [ "$n" -gt 0 ] && add "*.$pattern($n)"
done
[ -n "$manifests" ] || manifests=none

printf '%s\n' "[sdd:onboarding] claude_md=$claude_md stack=$stack specs_index=$specs_index empty=$empty manifests=$manifests"
printf '%s\n' "TecLeader: trate este diagnostico na primeira resposta (secao 'Inicio de sessao' do agente)."
exit 0
