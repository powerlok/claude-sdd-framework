# Validação T-003 — docs-manual

Data: 2026-10-09. Validador: agente `tests`. Resultado geral: **VALIDADO** (0 defeitos bloqueantes; 2 observações).

Scripts (fora dos projetos): `<TEMP_DA_SESSÃO>` (`t.js`, `t2.js`). Playwright/Chromium do app-workshop, `file:///`.
Screenshots no mesmo diretório: `s1280-claro.png`, `s1280-escuro.png`, `s320.png`, `s320-menu.png`.

| # | Verificação | Evidência | Status |
|---|---|---|---|
| 1a | Requisições não-file/data = 0 | lista vazia (REQ-001) | VALIDADO |
| 1b | console error + pageerror = 0 | `errs: []` | VALIDADO |
| 1c | Sem overflow horizontal | 320x640: 320/320; 1280x800: 1280/1280 | VALIDADO |
| 1d | Teclado 1280 | Tab: skip-link, busca (#q), theme-btn, 12 links do índice (#visao-geral..#referencias), depois conteúdo; outline solid 3px em todos | VALIDADO |
| 1d | Teclado 320 | skip-link, menu-btn, busca, theme-btn, table-wrap, links, copy-btn; outline solid 3px; menu abre (aria-expanded=true) | VALIDADO |
| 1e | Copiar | 33 botões; 1º clique: botão vira "Copiado!", `#live` = "Código copiado para a área de transferência"; texto = bloco (idêntico, exceto CRLF do clipboard Windows; blocos 2 e 3 idênticos byte a byte) | VALIDADO |
| 1f | Busca | "dotnet": 15 -> 1 exemplo, 1 seção, status "1 seção com resultados."; limpar: 15 exemplos, 12 seções | VALIDADO |
| 1g | Tema | claro -> escuro (aria-pressed=true); persiste após reload (dark); volta a claro e persiste | VALIDADO |
| 1h | Contraste (claro / escuro) | corpo 15.79 / 15.43; links 6.09 / 8.52; índice 5.20 / 6.55; código inline 14.47 / 14.15; bloco de código 16.02 / 16.57; selo Verificado 7.26 / 9.03; selo Ilustrativo 7.53 / 9.35; texto atenuado/tags 7.56 / 7.63; botão copiar 11.14 / 11.14. Todos >= 4.5 | VALIDADO |
| 1i | Exemplos | 15 `.example` (>= 10); todos com os 4 blocos (Pedido, O que o TecLeader faz, O que você responde, Resultado) (REQ-002) | VALIDADO |
| 1j | Screenshots | gerados (caminhos acima) | VALIDADO |
| 2 | REQ-003: 8 comandos amostrados | `marketplace add` + `install sdd@` + `plugin list` (README:33-35); `claude --agent sdd:tecleader` (README:42); `install authoring@` (README:55); `marketplace update`/`plugin update` (README:61-62; spike-result.md #7); `plugin validate` (README:102-103); `claude -p ... --plugin-dir ... --allowedTools` (README:110); `MCP_CONNECTION_NONBLOCKING=false claude -p` (spike-result.md #4). Todos com fonte | VALIDADO |
| 3 | Links | 74 links relativos (md + href HTML) resolvem para arquivos existentes; âncoras internas do HTML e de .md existem | VALIDADO |
| 4 | Grep termos obsoletos nos 5 arquivos | 0 ocorrências | VALIDADO |

## Observações (não bloqueantes)

- OBS-1 (INFO): bloco powershell `$env:Path += ";$HOME\.local\bin"` (manual, bloco 30) tem fonte apenas indireta (spike-result.md:3 cita `~/.local/bin/claude.exe` fora do PATH); o comando em si não consta literalmente em README/relatórios.
- OBS-2 (INFO): ordem de Tab em 1280px segue skip-link -> busca -> tema -> índice; botão de menu fica oculto (display:none) em desktop, como esperado.
- Escopo não verificado: fidelidade semântica do texto dos exemplos "Ilustrativos" (por definição sem fonte); `arquitetura-de-agentes.pptx` fora de escopo.

Volta: 1/3. Nenhum arquivo de entregável ou plugin foi alterado.

## Revalidação (TecLeader) — defeito D-001

- Achado pelo TecLeader após a volta 1: o print `s320.png` do validador tinha 1280px; no print real de 320px
  (`v320-ex.png`) o texto dos exemplos era cortado na borda do card (`.example { overflow:hidden }` + `.steps`
  em grid sem `grid-template-columns`).
- Correção (frontend): `.steps { grid-template-columns: minmax(0,1fr) }`, `min-width:0` e `overflow-wrap:anywhere`
  em steps/cards/callouts/timeline; header compacto em telas estreitas (≈150px → 95px).
- Revalidação: 320x640 — 0 elementos ultrapassando a borda do `.example` ou cortados por overflow (script do
  frontend `d001.cjs`); `scrollWidth = clientWidth = 320`; 0 requisições externas (script do TecLeader `v320.cjs`);
  print 320x640 conferido visualmente: texto e `code` inline quebram dentro do card; `pre` com rolagem interna.
  1280x800 sem regressão (0 erros de console, 0 requisições externas).
- OBS-1 do validador improcedente: `$env:Path += ";$HOME\.local\bin"` está no README (Pré-requisitos).
