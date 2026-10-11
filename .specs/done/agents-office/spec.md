# Spec: salinha dos agentes (visualização no navegador)

Pedido do usuário (2026-10-11): "startar uma telinha no browser se o usuário aceitar, mostrando uma salinha com os
agentes trabalhando e um popup dizendo o processo atual, sem precisar usar 3º"; "opção para aceitar na configuração
inicial e depois em qualquer momento"; "automático, sem ação do usuário para abrir a tela".

## Requisitos

- **REQ-001 — Opt-in**: desligado por padrão. Oferecido uma vez no onboarding/configuração inicial do TecLeader;
  ligável/desligável a qualquer momento (comando do plugin, ex.: `/sdd:office on|off|status`, e pedido em texto livre ao
  TecLeader). Preferência **do usuário**, fora do repositório (nunca versionada); vale para os projetos da máquina.
- **REQ-002 — Abertura automática**: com a opção ligada, o hook `SessionStart` (matcher `startup`) abre a tela no
  navegador padrão sem ação do usuário (Windows `start`, macOS `open`, Linux `xdg-open`), uma vez por sessão (não em
  `compact`/`resume`). Falha ao abrir não interrompe a sessão (exit 0).
- **REQ-003 — Eventos**: hooks do plugin (`SubagentStart`, `SubagentStop`, `PreToolUse`, `PostToolUse` e os da sessão
  principal) registram atividade. Opção desligada → o hook sai imediatamente (custo desprezível).
- **REQ-004 — Privacidade (allowlist)**: gravar **somente** nome/tipo do agente, id do agente, categoria da ferramenta (não o nome bruto), agente de destino da delegação, tipo
  do evento, horário e a descrição curta da delegação (ferramenta `Agent`, tamanho limitado, caracteres saneados).
  Nunca conteúdo de arquivos, comandos, caminhos, saídas, prompts completos ou segredos. Dados na pasta temporária do
  sistema (por projeto), nunca no repositório.
- **REQ-005 — Tela**: arquivo HTML local, sem dependências de terceiros (sem bibliotecas, sem imagens externas, sem
  rede, sem CDN), com sala em pixel art estilo 16 bits desenhada por código: uma mesa por agente (tecleader, backend,
  frontend, tests, security, infra-architect; agentes desconhecidos ganham mesa automaticamente). Animações por estado:
  trabalhando (digitando), entregando (anda até a mesa do TecLeader), revisão de segurança (sala de reunião), ocioso.
  **Popup** com o processo atual (ex.: "TecLeader → delegou T-003 ao backend", "backend: editando arquivos",
  "tests: rodando validação"). Atualização quase em tempo real (≈1 s). Preferência: sem servidor; se o navegador não
  permitir recarregar o estado via `file://`, servidor mínimo só em `127.0.0.1`, sem dependências.
- **REQ-006 — Docs e versão**: README/manual/guia de primeiros passos (seção "Salinha dos agentes"); `sdd` 0.7.0;
  CHANGELOG.

## Critérios de aceite

- Opção desligada: nenhuma tela abre; hooks não gravam nada.
- Aceite no onboarding ou via comando: na próxima sessão a tela abre sozinha uma vez; desligar impede.
- Delegação a subagentes em paralelo aparece na sala (personagens trabalhando) e o popup mostra o processo atual.
- Arquivo de eventos contém só os campos da allowlist (teste com segredos falsos em comandos/arquivos: nada vaza).
- Nenhuma dependência externa (inspeção do HTML/JS: sem URLs externas); sessão não quebra se o navegador não abrir.

## Validação

Design técnico (obrigatório: módulo novo, hooks novos) aprovado pelo TecLeader; `sdd:security` (hooks, dados,
abertura do navegador); `sdd:tests` (critérios acima, inclusive vazamento); `claude plugin validate --strict`.

Decisões assumidas (usuário não especificou; podem mudar): popup sem nome de arquivo; mesa automática para agentes
novos; pixel art 16 bits.
