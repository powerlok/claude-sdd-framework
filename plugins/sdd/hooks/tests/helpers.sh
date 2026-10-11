#!/usr/bin/env bash
# Utilitários dos testes da salinha dos agentes (.specs/done/agents-office). Nada aqui toca ~/.claude real:
# cada teste usa CLAUDE_CONFIG_DIR e TMPDIR apontando para uma pasta temporária própria.

HOOKS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PASS=0
FAIL=0

new_sandbox() {
  SB="$(mktemp -d)"
  export CLAUDE_CONFIG_DIR="$SB/cfg" TMPDIR="$SB/tmp" CLAUDE_PROJECT_DIR="/c/fake/projeto"
  mkdir -p "$TMPDIR" "$CLAUDE_CONFIG_DIR/sdd"
  unset SDD_OFFICE_OS
}
drop_sandbox() { [ -n "${SB:-}" ] && [ -d "$SB" ] && rm -rf "$SB"; }

room_dir() {
  local d
  for d in "$TMPDIR"/sdd-office-$UID/*/; do [ -d "$d" ] && { printf '%s' "${d%/}"; return; }; done
}

ok() { PASS=$((PASS + 1)); printf '  ok   %s\n' "$1"; }
bad() { FAIL=$((FAIL + 1)); printf '  FAIL %s\n' "$1"; }
check() { # check "descrição" comando...
  local desc="$1"; shift
  if "$@" >/dev/null 2>&1; then ok "$desc"; else bad "$desc"; fi
}
eq() { # eq "descrição" esperado real
  if [ "$2" = "$3" ]; then ok "$1"; else bad "$1 (esperado [$2], obtido [$3])"; fi
}
finish() {
  printf '%s: %d ok, %d falha(s)\n' "${0##*/}" "$PASS" "$FAIL"
  [ "$FAIL" -eq 0 ]
}
