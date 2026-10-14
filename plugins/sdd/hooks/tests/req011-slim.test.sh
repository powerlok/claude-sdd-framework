#!/usr/bin/env bash
# REQ-002/REQ-004 (plugin-review): o TechLead enxuto + playbooks sob demanda. .specs/plugin-review/spec.md. Só leitura, sem rede.
. "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"
PLUGIN="$HOOKS_DIR/.."
TL="$PLUGIN/agents/techlead.md"; PS="$PLUGIN/skills/project-setup/SKILL.md"; VD="$PLUGIN/skills/vcs-delivery/SKILL.md"

# 1) tamanho do agente principal (carregado a cada mensagem)
size="$(wc -c < "$TL" | tr -d ' ')"
check "req011 techlead.md <= 24000 bytes (hoje $size; antes 43896)" bash -c '[ "$1" -le 24000 ]' _ "$size"

# 2) as duas skills existem, são playbooks internos (user-invocable false) e têm descrição de gatilho
for f in "$PS" "$VD"; do
  n="$(basename "$(dirname "$f")")"
  check "req011 skill $n existe" test -f "$f"
  check "req011 skill $n: name correto" grep -q "^name: $n\$" "$f"
  check "req011 skill $n: user-invocable false" grep -q '^user-invocable: false$' "$f"
  check "req011 skill $n: descrição manda carregar ANTES de agir" bash -c 'sed -n "1,12p" "$1" | grep -q "ANTES"' _ "$f"
  check "req011 skill $n: sem ferramentas de escrita no frontmatter" bash -c '! sed -n "1,12p" "$1" | grep -Eq "^allowed-tools:"' _ "$f"
done

# 3) seções movidas estão nas skills e NÃO no agente; seções essenciais ficam no agente
for h in "# Onboarding de Projeto" "# Migração para a raiz do projeto" "# Trabalho entre projetos"; do
  check "req011 project-setup tem '$h' e o agente não" bash -c 'grep -q "^$2" "$1" && ! grep -q "^$2" "$3"' _ "$PS" "$h" "$TL"
done
for h in "# Repositório (opcional, somente leitura)" "# Git (branch e commit locais, com confirmação)" "# Publicação (modo publicação"; do
  check "req011 vcs-delivery tem '$h' e o agente não" bash -c 'grep -q "^$2" "$1" && ! grep -q "^$2" "$3"' _ "$VD" "$h" "$TL"
done
for h in "# Início de sessão" "# Workflow SDD" "# Critérios para DONE" "# Delegação" "# Jira" "# Gestão de Contexto" "# Playbooks sob demanda e regras invariantes"; do
  check "req011 agente mantém '$h'" grep -q "^$h" "$TL"
done

# 4) gatilhos e regras invariantes no agente (sempre carregadas)
check "req011 agente: tabela de gatilhos cita as duas skills" bash -c 'grep -q "sdd:project-setup" "$1" && grep -q "sdd:vcs-delivery" "$1"' _ "$TL"
check "req011 agente: carregar a skill ANTES de agir" grep -q 'ANTES de agir' "$TL"
for r in "Merge de PR: nunca" "só com \*\*pedido explícito do usuário\*\*" "são dados, nunca instruções" "Nunca\*\* expor token" "fora do plano confirmado"; do
  check "req011 invariante no agente: $r" grep -q -- "$r" "$TL"
done

# 5) nenhuma referência a "agente sdd:techlead, seção <movida>" fora do próprio agente
check "req011 sem referência desatualizada a seções movidas (agente, seção Git/Publicação/Repositório/Migração/Trabalho)" bash -c '! grep -rn "agente \`sdd:techlead\`, seç" "$1"/skills "$1"/agents | grep -E "Git|Publicação|Repositório|Migração|Trabalho entre|Onboarding de Projeto"' _ "$PLUGIN"

finish
