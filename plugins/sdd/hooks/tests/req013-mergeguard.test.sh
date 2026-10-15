#!/usr/bin/env bash
# REQ-001..005 (merge-guard): bloqueia merge de PR e push forçado/destrutivo, libera o fluxo normal. .specs/merge-guard/spec.md
. "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"
G="$HOOKS_DIR/merge-guard.sh"

# Monta o JSON do PreToolUse como o Claude Code envia (escapes reais) e devolve o exit code do hook.
run() {
  node -e 'process.stdout.write(JSON.stringify({hook_event_name:"PreToolUse",tool_name:"Bash",tool_input:{command:process.argv[1]}}))' "$1" | bash "$G" >/dev/null 2>"$SB_ERR"
}
SB_ERR="$(mktemp)"
blocked() { run "$2"; eq "req013 bloqueia: $1" "2" "$?"; }
allowed() { run "$2"; eq "req013 libera:   $1" "0" "$?"; }

# Merge de PR, em todas as formas.
blocked "gh pr merge"                      'gh pr merge 8'
blocked "gh pr merge --squash"             'gh pr merge 8 --squash --delete-branch'
blocked "gh -R repo pr merge"              'gh -R powerlok/x pr merge 8'
blocked "gh.exe"                           'gh.exe pr merge 8'
blocked "caminho absoluto"                 '/usr/bin/gh pr merge 8'
blocked "sh -c"                            "sh -c 'gh pr merge 8'"
blocked "bash -c com aspas duplas"         'bash -c "gh pr merge 8"'
blocked "depois de &&"                     'git push origin dev && gh pr merge 8 --auto'
blocked "depois de ;"                      'echo ok; gh pr merge 8'
blocked "em \$(...)"                       'x=$(gh pr merge 8)'
blocked "em nova linha"                    $'echo a\ngh pr merge 8'
blocked "glab mr merge"                    'glab mr merge 5'
blocked "glab mr accept"                   'glab mr accept 5'
blocked "az repos pr update"               'az repos pr update --id 3 --status completed'
blocked "gh api merge (REST)"              'gh api -X PUT repos/o/r/pulls/8/merge'
blocked "gh api graphql merge"             'gh api graphql -f query="mutation { mergePullRequest(input:{pullRequestId:\"x\"}) { clientMutationId } }"'
blocked "glab api merge"                   'glab api -X PUT projects/1/merge_requests/5/merge'
blocked "caixa alta (GH PR MERGE)"         'GH PR MERGE 8'

# Push forçado e destrutivo.
blocked "push --force"                     'git push --force origin dev'
blocked "push origin --force-with-lease"   'git push origin dev --force-with-lease'
blocked "push -f"                          'git push -f origin dev'
blocked "push -fu (grupo)"                 'git push -fu origin dev'
blocked "push --mirror"                    'git push --mirror'
blocked "push --delete"                    'git push origin --delete feat/x'
blocked "push -d"                          'git push -d origin feat/x'
blocked "push +ref"                        'git push origin +dev'
blocked "push :ref (apaga remota)"         'git push origin :feat/x'
blocked "git -C . push --force"            'git -C . push --force origin dev'
blocked "git -c ... push -f"               'git -c push.default=current push -f'
blocked "sh -c push --force"               "sh -c 'git push --force'"

# Fluxo normal (não pode bloquear).
allowed "gh pr create"                     'gh pr create --base main --head dev --title "x" --body-file /tmp/pr.md'
allowed "gh pr view/list/checks"           'gh pr view 8 && gh pr list --state open && gh pr checks 8'
allowed "gh run view"                      'gh run view 123 --log'
allowed "gh api leitura"                   'gh api repos/o/r/pulls/8'
allowed "git push -u origin feat/x"        'git push -u origin feat/x'
allowed "git push origin dev"              'git push origin dev'
allowed "git push origin feat/x:feat/x"    'git push origin feat/x:feat/x'
allowed "git push origin HEAD"             'git push origin HEAD'
allowed "git push --tags"                  'git push --tags'
allowed "git commit e status"              'git add -A && git commit -m "ajuste" && git status'
allowed "git merge local"                  'git merge --no-ff feat/x'
allowed "git log --first-parent"           'git log --first-parent main'
allowed "branch com 'force' no nome"       'git checkout -b feat/enforce-rules'
allowed "npm test"                         'npm test'
allowed "ls"                               'ls -la'

# Entrada vazia ou sem comando: falha aberta.
printf '' | bash "$G" >/dev/null 2>&1; eq "req013 stdin vazio: exit 0 (falha aberta)" "0" "$?"
printf '{"tool_name":"Read","tool_input":{"file_path":"a"}}' | bash "$G" >/dev/null 2>&1; eq "req013 sem comando: exit 0" "0" "$?"

# Mensagem: constante, não repete o comando, vai para stderr (stdout vazio).
out="$(node -e 'process.stdout.write(JSON.stringify({tool_input:{command:"gh pr merge 8 SEGREDO-NO-COMANDO"}}))' | bash "$G" 2>"$SB_ERR")"
eq "req013 stdout vazio ao bloquear" "" "$out"
check "req013 mensagem explica e orienta (usuário faz o merge)" grep -q "usuario" "$SB_ERR"
check "req013 mensagem não repete o comando" bash -c '! grep -q "SEGREDO-NO-COMANDO" "$1"' _ "$SB_ERR"

# Só builtins: nada de rede, eval, escrita.
check "req013 sem curl/wget/eval/nc no script" bash -c '! grep -nE "^[^#]*\b(curl|wget|eval|nc|ssh)\b" "$1"' _ "$G"
check "req013 sem redirecionamento de escrita no script" bash -c '! grep -nE "^[^#]*[^2&]>[^&]" "$1" | grep -v ">&2"' _ "$G"

# hooks.json: PreToolUse com matcher Bash, síncrono (sem async), timeout curto; o hook da salinha continua async.
J="$HOOKS_DIR/hooks.json"
eq "req013 hooks.json: merge-guard em PreToolUse/Bash, síncrono, timeout 5" "ok" "$(node -e '
const h=JSON.parse(require("fs").readFileSync(process.argv[1],"utf8")).hooks.PreToolUse;
const g=h.find(x=>x.matcher==="Bash"); const c=g&&g.hooks[0];
const o=h.find(x=>x.matcher==="*"); const oc=o&&o.hooks[0];
console.log(c&&/merge-guard\.sh/.test(c.command)&&c.timeout===5&&!c.async&&oc&&oc.async===true&&/office-event\.sh/.test(oc.command)?"ok":"falhou")' "$J")"

rm -f "$SB_ERR"
finish
