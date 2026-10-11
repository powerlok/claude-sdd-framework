# Spec: salinha dos agentes — qualidade visual e layout

Relacionada a: done/agents-office. Pedido do usuário (2026-10-11), com captura de tela: nomes das mesas ilegíveis
(texto desenhado em baixa resolução e esticado); melhorar qualidade da imagem e layout.

- **REQ-001**: nitidez — canvas dimensionado por `devicePixelRatio` (resolução nativa da tela, redimensiona ao
  mudar a janela/zoom); sprites e mobília continuam pixel art (`imageSmoothingEnabled=false`), mas o TEXTO (nomes das
  mesas, "REUNIÃO") é desenhado em resolução nativa (fonte do sistema, tamanho legível ≥ 12 px CSS), nunca esticado.
- **REQ-002**: layout — sala maior e organizada: mesas em fileiras com espaçamento que não esbarre, nome legível
  acima/abaixo de cada mesa (com fundo para contraste), TecLeader em destaque, sala de reunião visível e proporcional,
  escala que preenche a largura disponível (responsivo; sem rolagem horizontal em 375 px); mesas de agentes novos
  continuam surgindo automaticamente.
- **REQ-003**: sem regressão — textContent, CSP, sem URLs externas, pausar, reduced-motion e todos os testes
  `req005-*` passam; nenhum dado novo é gravado (só renderização).
- **REQ-004**: versão `sdd` 0.7.1 + CHANGELOG (sem release/tag sem confirmação).

Critérios: captura de tela em Chrome headless (≥ 1200 px e 375 px) com nomes das mesas legíveis; suíte passando.
Segurança: só renderização em `office.html` (sem hooks, dados ou permissões novas) → revisão dispensada; grep de
ausência de `innerHTML`/URLs externas.
