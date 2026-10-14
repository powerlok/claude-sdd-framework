#!/usr/bin/env bash
# Executa todos os testes da salinha dos agentes (.specs/done/agents-office). Não altera ~/.claude (cada teste usa sandbox).
# Uso: bash run-all.sh [--no-page]   (--no-page pula o teste de página em navegador headless)
D="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
rc=0
for t in "$D"/req00[1-5]-*.test.sh "$D"/req008-*.test.sh "$D"/req009-*.test.sh; do
  echo "== ${t##*/}"; bash "$t" || rc=1
done
echo "== req007-publicacao.test.js"; node "$D/req007-publicacao.test.js" || rc=1
if [ "${1:-}" != "--no-page" ]; then
  echo "== req005-page.test.js"; node "$D/req005-page.test.js" || rc=1
  echo "== req006-working.test.js"; node "$D/req006-working.test.js" || rc=1
fi
[ "$rc" -eq 0 ] && echo "TODOS OS TESTES PASSARAM" || echo "HÁ FALHAS"
exit $rc
