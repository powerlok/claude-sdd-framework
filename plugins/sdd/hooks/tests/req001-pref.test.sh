#!/usr/bin/env bash
# REQ-001 (opt-in): office-pref.sh on/off/status/inválido, conteúdo exato do arquivo, preferência fora do repositório.
. "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"
new_sandbox
P="$HOOKS_DIR/office-pref.sh"
cfg="$CLAUDE_CONFIG_DIR/sdd/office.conf"
unset SDD_OFFICE_OS

out="$(bash "$P" status)"; eq "req001 status sem arquivo = unset" "[sdd:office] pref=unset room=no" "$out"
out="$(bash "$P")"; eq "req001 sem argumento = status" "[sdd:office] pref=unset room=no" "$out"
check "req001 status não cria o arquivo" test ! -e "$cfg"

# Em 'on' a abertura é tentada: neste teste não pode abrir nada de verdade (SDD_OFFICE_OS=linux sem DISPLAY).
export SDD_OFFICE_OS=linux; unset DISPLAY WAYLAND_DISPLAY
out="$(bash "$P" on)"; rc=$?
eq "req001 on: exit 0" "0" "$rc"
case "$out" in "[sdd:office] pref=on"*) ok "req001 on imprime pref=on" ;; *) bad "req001 on imprime pref=on [$out]" ;; esac
eq "req001 on: conteúdo exato do arquivo" "on" "$(cat "$cfg")"
eq "req001 on: arquivo com 1 linha" "1" "$(wc -l < "$cfg" | tr -d ' ')"
case "$(bash "$P" status)" in "[sdd:office] pref=on room=yes") ok "req001 status após on = on room=yes" ;; *) bad "req001 status após on" ;; esac

out="$(bash "$P" off)"; rc=$?
eq "req001 off: exit 0" "0" "$rc"
eq "req001 off: saída" "[sdd:office] pref=off" "$out"
eq "req001 off: conteúdo exato do arquivo" "off" "$(cat "$cfg")"

for bad_arg in "ON" "true" "on;touch $SB/pwned" '$(touch '"$SB"'/pwned)' "../x" "--now" "'" "on off"; do
  bash "$P" "$bad_arg" >/dev/null 2>&1; rc=$?
  eq "req001 argumento inválido [$bad_arg]: exit 2" "2" "$rc"
done
check "req001 argumento inválido não executa nada" test ! -e "$SB/pwned"
eq "req001 arquivo intacto após inválidos" "off" "$(cat "$cfg")"

# Arquivo ilegível/estranho = desligado (não unset): só a primeira linha exatamente "on" liga.
printf 'ON\n' > "$cfg"; case "$(bash "$P" status)" in *"pref=off"*) ok "req001 'ON' = off" ;; *) bad "req001 'ON' = off" ;; esac
printf 'on \n' > "$cfg"; case "$(bash "$P" status)" in *"pref=off"*) ok "req001 'on ' (espaço) = off" ;; *) bad "req001 'on ' = off" ;; esac
printf 'x\non\n' > "$cfg"; case "$(bash "$P" status)" in *"pref=off"*) ok "req001 segunda linha 'on' não liga" ;; *) bad "req001 segunda linha" ;; esac

# O caminho do projeto nunca aparece na saída.
out="$(bash "$P" status)"
case "$out" in *fake*|*projeto*) bad "req001 status vaza caminho" ;; *) ok "req001 status sem caminho do projeto" ;; esac

# Pasta de configuração de uso: o repositório não é tocado.
check "req001 nada criado no PWD" test -z "$(ls "$SB" | grep -v -e '^cfg$' -e '^tmp$')"
check "req001 pasta sdd modo restrito" test "$(stat -c %a "$CLAUDE_CONFIG_DIR/sdd" 2>/dev/null || echo 700)" != "777"

# Skill: frontmatter mínimo.
S="$HOOKS_DIR/../skills/office/SKILL.md"
check "req001 skill tem name: office" grep -q '^name: office$' "$S"
check "req001 skill tem argument-hint on|off|status" grep -q '^argument-hint: on|off|status$' "$S"
check "req001 skill disable-model-invocation" grep -q '^disable-model-invocation: true$' "$S"
check "req001 techlead oferece opt-in (pref=unset)" grep -q 'pref=unset' "$HOOKS_DIR/../agents/techlead.md"
check "req001 techlead cita /sdd:office on|off" grep -q '/sdd:office on|off' "$HOOKS_DIR/../agents/techlead.md"
drop_sandbox
finish
