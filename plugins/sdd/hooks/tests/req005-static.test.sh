#!/usr/bin/env bash
# REQ-005 (tela), inspeção estática do office.html: sem URLs externas, sem APIs perigosas, CSP, movimento reduzido, pausa.
. "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"
H="$HOOKS_DIR/../office/office.html"
check "req005 arquivo existe" test -f "$H"
check "req005 sem http:// nem https:// (nem protocolo-relativo //host)" bash -c '! grep -nE "https?://|[\"'"'"'(= ]//[a-z]" "$1"' _ "$H"
check "req005 sem ws:// wss:// ftp:// data: javascript:" bash -c '! grep -nE "wss?://|ftp://|javascript:|data:text/html" "$1"' _ "$H"
for api in innerHTML outerHTML insertAdjacentHTML "document.write" "eval(" "new Function" "setTimeout(\"" "setInterval(\"" XMLHttpRequest "fetch(" WebSocket "import(" sendBeacon localStorage sessionStorage "document.cookie" "<link" "<img" "<iframe" "<object" "<embed" "@import" "url("; do
  check "req005 sem [$api]" bash -c '! grep -qF -- "$1" "$2"' _ "$api" "$H"
done
check "req005 CSP via meta restritiva" grep -q 'http-equiv="Content-Security-Policy" content="default-src '"'"'none'"'"'; script-src '"'"'self'"'"' '"'"'unsafe-inline'"'"'; style-src '"'"'unsafe-inline'"'"'"' "$H"
check "req005 CSP sem connect-src/img-src/font-src externos" bash -c '! grep -E "Content-Security-Policy" "$1" | grep -qE "connect-src|img-src|font-src|\*"' _ "$H"
check "req005 prefers-reduced-motion (CSS e JS)" bash -c 'grep -q "@media (prefers-reduced-motion: reduce)" "$1" && grep -q "matchMedia(\"(prefers-reduced-motion: reduce)\")" "$1"' _ "$H"
check "req005 botão Pausar animação" grep -q 'id="pause"' "$H"
check "req005 painel com role=log e aria-live" grep -q 'role="log" aria-live="polite"' "$H"
check "req005 foco visível definido" grep -q ':focus-visible' "$H"
check "req005 textContent usado para dados" grep -q 'textContent' "$H"
check "req005 lang pt-BR" grep -q '<html lang="pt-BR">' "$H"
check "req005 'use strict'" grep -q '"use strict"' "$H"
check "req005 agente mobile conhecido (slot 6; próximo slot dinâmico 7)" bash -c 'grep -q "mobile: { slot: 6," "$1" && grep -q "nextSlot = 7;" "$1"' _ "$H"
drop_sandbox 2>/dev/null
finish
