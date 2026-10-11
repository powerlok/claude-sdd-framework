#!/usr/bin/env bash
# sdd: registro de eventos da "salinha dos agentes" (REQ-003/REQ-004; .specs/done/agents-office/design.md 5.1 e 5.2).
# Hooks: SubagentStart, SubagentStop, PreToolUse, UserPromptSubmit, Stop (registrados com "async": true).
# Entrada: JSON do hook no stdin. Saída: stdout SEMPRE vazio. Sempre "exit 0" (sem "set -e"): nunca derruba a sessão.
# Sem rede, sem eval, sem jq: extração por regex em builtins e allowlist estrita.
# Desligado (preferência diferente de "on"): sai ANTES de ler o stdin e sem criar nada.
#
# Grava SOMENTE (uma linha por evento em <tmp>/sdd-office-<uid>/<id>/events.js): id do evento, horário, tipo do evento
# (enum), tipo e id do agente, CATEGORIA da ferramenta (enum; o nome bruto nunca é gravado) e, só para delegação
# (ferramenta Agent/Task), descrição curta saneada e agente de destino. Nada de comandos, caminhos, prompts,
# saídas, session_id, cwd ou transcript.

# Confiança no ambiente: CLAUDE_CONFIG_DIR (e HOME) vêm do ambiente do usuário/CLI, não de conteúdo de projeto; é onde
# fica a preferência office.conf (o script só lê/grava a constante on|off nele).

LC_ALL=C
export LC_ALL

cfg="${CLAUDE_CONFIG_DIR:-${HOME:-}/.claude}/sdd/office.conf"
p=""
{ IFS= read -r p < "$cfg"; } 2>/dev/null
[ "$p" = on ] || exit 0

umask 077

# Limite de leitura: 64 KiB (entrada maior é truncada; campo que ficar de fora simplesmente não é gravado).
in=""
IFS= read -r -d '' -n 65536 in 2>/dev/null
[ -n "$in" ] || exit 0

# Achata o JSON em dois textos, sem subprocesso (L1): "top" = só o nível 1 (objetos/arrays aninhados descartados) e
# "ti" = só o nível imediato de "tool_input". Strings são lidas inteiras (com escapes), então chave forjada dentro de
# string ou de objeto aninhado (tool_input/tool_response) nunca vira campo. Limite de 1000 tokens (entrada patológica:
# o que não foi lido simplesmente não é gravado).
top=""; ti=""
flatten() {
  local rest="$in" pre c add depth=0 cap=0 guard=0
  local sp='[]"{}[]' strre='^([^"\\]*(\\.[^"\\]*)*)"' tire='"tool_input"[[:space:]]*:[[:space:]]*$'
  while [ -n "$rest" ] && [ $((guard++)) -lt 1000 ]; do
    pre="${rest%%$sp*}"
    add="$pre"; c=""
    if [ "$pre" = "$rest" ]; then rest=""; else c="${rest:${#pre}:1}"; rest="${rest:$((${#pre} + 1))}"; fi
    # O texto antes do token e a string pertencem ao nível ATUAL (antes de abrir/fechar objeto).
    if [ "$c" = '"' ]; then
      if [[ $rest =~ $strre ]]; then add="$add\"${BASH_REMATCH[0]}"; rest="${rest:${#BASH_REMATCH[0]}}"; else rest=""; fi
    fi
    if [ "$depth" -eq 1 ]; then top="$top$add"; elif [ "$depth" -eq 2 ] && [ "$cap" -eq 1 ]; then ti="$ti$add"; fi
    case "$c" in
      '{'|'[')
        depth=$((depth + 1))
        if [ "$depth" -eq 2 ] && [ "$c" = '{' ] && [[ $top =~ $tire ]]; then cap=1; fi
        ;;
      '}'|']')
        depth=$((depth - 1))
        [ "$depth" -le 1 ] && cap=0
        [ "$depth" -lt 1 ] && break
        ;;
    esac
  done
}
flatten

# Campo string simples [A-Za-z0-9_:.-] (chave NÃO precedida de barra: ignora chave forjada dentro de string escapada).
# get CHAVE TAMANHO [top|ti]: nível 1 por padrão; "ti" = dentro de tool_input.
V=""
get() {
  V=""
  local re='(^|[^\\])"KEY"[[:space:]]*:[[:space:]]*"([A-Za-z0-9_:.-]{1,LEN})"' txt="${3:-top}"
  re="${re/KEY/$1}"
  re="${re/LEN/$2}"
  [[ ${!txt} =~ $re ]] && V="${BASH_REMATCH[2]}"
}

# Nome de agente: remove o prefixo "sdd:"; fora de [A-Za-z0-9_.-]{1,32} é DESCARTADO (nunca "limpo e aceito").
A=""
agent_name() {
  A=""
  local v="${1#sdd:}"
  [[ $v =~ ^[A-Za-z0-9_.-]{1,32}$ ]] && A="$v"
}

get hook_event_name 32
case "$V" in
  SubagentStart) e=start ;;
  SubagentStop) e=stop ;;
  PreToolUse) e=tool ;;
  UserPromptSubmit) e=prompt ;;
  Stop) e=end ;;
  *) exit 0 ;;
esac

a=""; d=""; k=""; m=""; g=""

case "$e" in
  start|stop|tool)
    get agent_type 64
    agent_name "$V"; a="$A"
    get agent_id 64
    d="${V//[^A-Za-z0-9]/}"; d="${d:0:12}"
    ;;
esac

if [ "$e" = tool ]; then
  get tool_name 100
  case "$V" in
    Read|Grep|Glob|LS|NotebookRead) k=read ;;
    Edit|Write|MultiEdit|NotebookEdit) k=edit ;;
    Bash|BashOutput|KillShell|PowerShell) k=run ;;
    WebFetch|WebSearch) k=web ;;
    Agent|Task) k=delegate ;;
    TodoWrite|EnterPlanMode|ExitPlanMode|TaskCreate|TaskUpdate|TaskList|TaskGet) k=plan ;;
    AskUserQuestion) k=ask ;;
    mcp__*) k=mcp ;;
    *) k=other ;;
  esac
fi

# Descrição curta e destino: apenas para delegação.
if [ "$k" = delegate ]; then
  get subagent_type 64 ti
  agent_name "$V"; g="$A"

  bs='\'
  re_desc='(^|[^\\])"description"[[:space:]]*:[[:space:]]*"([^"\\]*(\\.[^"\\]*)*)"'
  if [[ $ti =~ $re_desc ]]; then
    m="${BASH_REMATCH[2]:0:240}"
    raw="$m"
    # Escapes JSON viram espaço (sempre com aspas nos padrões: "$bs$bs" é UMA barra dupla).
    m="${m//"$bs$bs"/ }"
    m="${m//"$bs\""/ }"
    m="${m//"$bs"u[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]/ }"
    m="${m//"$bs"?/ }"
    # Allowlist de caracteres: ASCII A-Za-z0-9 espaço . , : ; ( ) # _ / + - e bytes UTF-8 altos (nada de aspas, barra
    # invertida, <, >, =, controles).
    m="${m//[^A-Za-z0-9 .,:;()#_\/+$'\200'-$'\377'-]/ }"
    # Separadores de linha Unicode, bidi, largura zero, BOM e controles C1 viram espaço.
    m="${m//$'\xe2\x80'[$'\x8b'-$'\x8f']/ }"
    m="${m//$'\xe2\x80'[$'\xa8'-$'\xae']/ }"
    m="${m//$'\xe2\x81'[$'\xa6'-$'\xa9']/ }"
    m="${m//$'\xef\xbb\xbf'/ }"
    m="${m//$'\xc2'[$'\x80'-$'\x9f']/ }"
    while [[ $m == *"  "* ]]; do m="${m//  / }"; done
    m="${m# }"
    m="${m:0:80}"
    # UTF-8 válido: se o corte partiu um caractere, apara até 3 bytes; se ainda inválido, descarta os bytes altos.
    x80=$'\x80'; x8f=$'\x8f'; x90=$'\x90'; x9f=$'\x9f'; xa0=$'\xa0'; xbf=$'\xbf'
    xc2=$'\xc2'; xdf=$'\xdf'; xe0=$'\xe0'; xe1=$'\xe1'; xec=$'\xec'; xed=$'\xed'; xee=$'\xee'; xef=$'\xef'
    xf0=$'\xf0'; xf1=$'\xf1'; xf3=$'\xf3'; xf4=$'\xf4'
    cn="[$x80-$xbf]"
    u8="^([ -~]|[$xc2-$xdf]$cn|$xe0[$xa0-$xbf]$cn|[$xe1-$xec$xee$xef]$cn$cn|$xed[$x80-$x9f]$cn|$xf0[$x90-$xbf]$cn$cn|[$xf1-$xf3]$cn$cn$cn|$xf4[$x80-$x8f]$cn$cn)*\$"
    n=0
    while ! [[ $m =~ $u8 ]] && [ "$n" -lt 3 ]; do m="${m%?}"; n=$((n + 1)); done
    if ! [[ $m =~ $u8 ]]; then m="${m//[$x80-$'\377']/ }"; fi
    m="${m% }"
    # Defesa em profundidade: padrões de segredo (sem diferenciar caixa) ou sequência longa de 24+ caracteres de
    # token => a descrição inteira é substituída (o segredo costuma vir DEPOIS do marcador).
    re_secret='(sk-|ghp_|gho_|ghs_|ghu_|github_pat|AKIA|ASIA|Bearer|password|passwd|secret|token|api[-_ ]?key|authorization|credential|eyJ|AIza|xox[a-z]|glpat|private[-_ ]?key|senha|chave|credenc|segredo|pwd)|[A-Za-z0-9+_.-]{24,}'
    # L3: padrão de caminho/arquivo sensível, verificado também no texto BRUTO (antes de "\" virar espaço).
    re_path='[A-Za-z]:[/\\]|~/|(^|[ (:=])/[A-Za-z0-9_.~-]+/|\.env|id_rsa|\.pem|\.key'
    # N3: UNC (\\host: no JSON bruto são 4 barras; //host) e caminho relativo com "/" + extensão (src/app/main.ts);
    # "e/ou" sem extensão passa.
    re_path="$re_path"'|\\\\\\\\[A-Za-z0-9_.$-]|(^|[ (:=])//[A-Za-z0-9_.$-]|[A-Za-z0-9_.-]+/[A-Za-z0-9_./-]*\.[A-Za-z0-9]{1,8}([^A-Za-z0-9]|$)'
    shopt -s nocasematch
    if [[ $m =~ $re_secret || $raw =~ $re_secret || $m =~ $re_path || $raw =~ $re_path ]]; then m='[omitido]'; fi
    shopt -u nocasematch
  fi
fi

# Pasta da sala: <tmp absoluto>/sdd-office-<uid>/<hash>-<tamanho do caminho>; o caminho nunca é gravado.
# Id da sala = hash djb2 do caminho canônico do projeto (o caminho nunca é impresso nem gravado). Mesma regra nos 3 scripts.
# Com CLAUDE_PROJECT_DIR (hooks): usa-o. Sem ele (Bash tool do CLI, onde vem vazio) usa $PWD, que pode vir em forma 8.3
# (PAULO~1.LAR) ou em subpasta: no Windows normaliza para a forma longa (cygpath -ml, se existir) e sobe até a raiz do
# projeto = diretório mais próximo com .claude/settings.json, .claude/settings.local.json ou .git (monorepo: vence o
# mais próximo; nunca HOME nem acima; CLAUDE.md não serve de marcador porque existe também em subpastas).
norm_path() {
  NP="${1//\\//}"
  if [[ $NP =~ ^([A-Za-z]):/(.*)$ ]]; then
    local dv="${BASH_REMATCH[1]}" rest="${BASH_REMATCH[2]}" lc=abcdefghijklmnopqrstuvwxyz uc=ABCDEFGHIJKLMNOPQRSTUVWXYZ pre
    case "$dv" in [a-z]) pre="${lc%%$dv*}" ;; *) pre="${uc%%$dv*}" ;; esac
    NP="/${lc:${#pre}:1}/$rest"
  fi
  NP="${NP%/}"
}
# Resolve a raiz do projeto em PD (variáveis locais: nunca reutilizar nomes do chamador, p.ex. "d" = agent_id).
# HOME é normalizado como o PWD (cygpath -ml quando existe) e comparado sem diferenciar caixa nesse caso (Windows);
# o próprio HOME e qualquer ancestral dele nunca são aceitos como raiz.
resolve_dir() {
  PD="${CLAUDE_PROJECT_DIR:-}"
  if [ -n "$PD" ]; then norm_path "$PD"; PD="$NP"; return 0; fi
  local w="$PWD" hm="${HOME:-}" cur tmp ci=0
  if command -v cygpath >/dev/null 2>&1; then
    ci=1
    tmp="$(cygpath -ml "$PWD" 2>/dev/null)"; [ -n "$tmp" ] && w="$tmp"
    if [ -n "$hm" ]; then tmp="$(cygpath -ml "$hm" 2>/dev/null)"; [ -n "$tmp" ] && hm="$tmp"; fi
  fi
  norm_path "$w"; PD="$NP"; cur="$PD"
  norm_path "$hm"; hm="$NP"
  [ "$ci" -eq 1 ] && shopt -s nocasematch
  while [ -n "$cur" ]; do
    if [ -n "$hm" ] && { [[ $cur == "$hm" ]] || [[ $hm == "$cur"/* ]]; }; then break; fi
    if [ -f "$cur/.claude/settings.json" ] || [ -f "$cur/.claude/settings.local.json" ] || [ -e "$cur/.git" ]; then PD="$cur"; break; fi
    [ "$cur" = "${cur%/*}" ] && break; cur="${cur%/*}"
  done
  [ "$ci" -eq 1 ] && shopt -u nocasematch
  return 0
}
resolve_dir
dir="$PD"
# Hash djb2 em builtins (sem subprocesso: no Windows cada fork custa ~100 ms); id = <hash 32 bits>-<tamanho>.
h=5381; n=${#dir}
for ((i = 0; i < n; i++)); do printf -v c '%d' "'${dir:i:1}"; h=$(( (h * 33 + c) & 4294967295 )); done
id="$h-$n"
[[ $id =~ ^[0-9]+-[0-9]+$ ]] || id="0-0"

# Só grava em pasta própria (dono = usuário atual, não symlink): evita pré-criação hostil em /tmp compartilhado.
safe_dir() {
  [ -d "$1" ] || mkdir -m 700 "$1" 2>/dev/null
  [ -d "$1" ] && [ ! -L "$1" ] && [ -O "$1" ]
}
# TMPDIR só vale se absoluto (senão /tmp); pasta por usuário (sdd-office-<uid>) para não colidir em /tmp compartilhado.
case "${TMPDIR:-}" in /*|[A-Za-z]:[/\\]*) base="$TMPDIR" ;; *) base="/tmp" ;; esac
base="${base%/}"
office_root="$base/sdd-office-${UID:-0}"
room="$office_root/$id"
safe_dir "$office_root" && safe_dir "$room" || exit 0
f="$room/events.js"
[ -L "$f" ] && exit 0

if (( BASH_VERSINFO[0] > 4 || (BASH_VERSINFO[0] == 4 && BASH_VERSINFO[1] >= 2) )); then
  printf -v t '%(%s)T' -1
else
  t="$(date +%s)"
fi
[[ $t =~ ^[0-9]{1,12}$ ]] || exit 0

# Defesa em profundidade (N1): revalida TODOS os campos imediatamente antes de montar a linha. Campo inválido = vazio;
# evento (e), id (i) ou horário (t) inválido = não grava. Só A-Za-z0-9 _ . - e a descrição saneada entram na linha.
re_i='^[0-9-]{1,24}$'; re_t='^[0-9]{1,12}$'; re_ag='^[A-Za-z0-9_.-]{0,32}$'; re_d='^[A-Za-z0-9]{0,12}$'
re_e='^(start|stop|tool|prompt|end)$'; re_k='^(read|edit|run|web|delegate|plan|ask|mcp|other)?$'
ev_id="$t-$$-$RANDOM"
[[ $ev_id =~ $re_i && $t =~ $re_t && $e =~ $re_e ]] || exit 0
[[ $k =~ $re_k ]] || k=""
[[ $a =~ $re_ag ]] || a=""
[[ $g =~ $re_ag ]] || g=""
[[ $d =~ $re_d ]] || d=""
lo=$'\001'; hi=$'\037'; del=$'\177'
bad_m="[\"\\\\<>]|[$lo-$hi$del]"
if [ "${#m}" -gt 80 ] || [[ $m =~ $bad_m ]]; then m=""; fi
line="E({\"i\":\"$ev_id\",\"t\":$t,\"e\":\"$e\",\"a\":\"$a\",\"d\":\"$d\",\"k\":\"$k\",\"m\":\"$m\",\"g\":\"$g\"});"
# Linha total limitada a 400 bytes: acima disso a descrição é descartada.
if [ "${#line}" -gt 400 ]; then
  line="E({\"i\":\"$ev_id\",\"t\":$t,\"e\":\"$e\",\"a\":\"$a\",\"d\":\"$d\",\"k\":\"$k\",\"m\":\"\",\"g\":\"$g\"});"
fi
printf '%s\n' "$line" >> "$f" 2>/dev/null

# Rotação atômica: em ~5% dos eventos e em todo start/stop, acima de 400 linhas ou 64 KiB mantém as últimas 200.
if [ "$e" != tool ] && [ "$e" != prompt ] || [ $((RANDOM % 20)) -eq 0 ]; then
  s="$(<"$f")" 2>/dev/null
  t2="${s//[!$'\n']/}"
  if [ "${#s}" -gt 65536 ] || [ "${#t2}" -gt 400 ]; then
    tail -n 200 "$f" > "$f.tmp.$$" 2>/dev/null && mv -f "$f.tmp.$$" "$f" 2>/dev/null
    rm -f "$f.tmp.$$" 2>/dev/null
  fi
fi
exit 0
