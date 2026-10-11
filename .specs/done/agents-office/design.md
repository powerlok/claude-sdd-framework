# Design técnico: agents-office (salinha dos agentes)

Spec: `.specs/agents-office/spec.md` (REQ-001..006). Task: T-001. Status: PROPOSTO (aguarda aprovação do TecLeader).
Stack: bash (hooks) + HTML/CSS/JS puro com Canvas 2D. Referência: `frontend-engineering/references/web-interface.md`
(usada só para o checklist de estados/acessibilidade; não há referência de stack para "bash + canvas": lacuna declarada).

## 1. Objetivo

Com opt-in do usuário, abrir sozinho no navegador padrão uma "salinha" em pixel art 16 bits em que cada agente SDD é um
personagem numa mesa, e um popup mostra o processo atual ("TecLeader delegou ... ao backend", "tests: rodando validação"),
atualizando em cerca de 1 s, sem servidor, sem dependências e sem gravar nada sensível.

## 2. Impacto Arquitetural

Módulo novo e hooks novos no plugin `sdd` (design obrigatório). Nenhum serviço, nenhuma rede, nenhum dado no repositório.

```text
Claude Code --(hooks, JSON no stdin)--> office-event.sh --append--> <tmp>/sdd-office/<id>/events.js
SessionStart(startup) --> office-start.sh --copia office.html para <tmp>/sdd-office/<id>/ e abre no navegador
office.html (file://) --<script src="events.js?t=...">, a cada 1 s--> estado em memória --> canvas + popup
/sdd:office on|off|status  e  TecLeader --> office-pref.sh --> ~/.claude/sdd/office.conf
```

Separação: (a) preferência, (b) coleta (hooks), (c) transporte (arquivo), (d) apresentação (HTML). Cada uma tem um
script/arquivo e um contrato.

### 2.1 Prova de conceito (decide REQ-005): `file://` FUNCIONA, sem servidor

Resultado medido (pasta `office-poc/` do scratchpad, fora do repositório):

- `index.html` aberto por `file:///...` no **Google Chrome headless (`--headless=new`) controlado por CDP**
  (`--remote-debugging-port`, leitura do DOM a cada 1 s por um script Node), enquanto um laço bash reescrevia
  `state.js` (`printf > state.js.tmp; mv -f`). A página injeta `<script src="state.js?t=<Date.now()>">` a cada 1 s e
  remove o elemento no `onload`. Saída real (hh:mm:ss.s, texto do DOM): `44.9 seq=0`, `45.9 seq=1`, `47.0 seq=2`,
  `48.0 seq=3`, `50.0 seq=5`, `51.0 seq=6`... (uma atualização por segundo, `reloads` incrementando de 1 a 7).
- Por que funciona: scripts clássicos (`<script src>`) não passam por CORS em `file://`; `fetch`/`XHR` de `file://` seriam
  bloqueados, então a estratégia é "arquivo de estado em formato JS".
- Não verificado: Edge (existe na máquina, mesmo motor Chromium, esperado igual), Firefox e Safari (não disponíveis).
  Firefox trata `file://` de pasta irmã como mesma origem para script clássico e deve funcionar; a confirmar no T-004.
- Tentativa anterior com `--dump-dom --virtual-time-budget` mostrou só 1 atualização (tempo virtual não sincroniza com
  o escritor externo): limitação do método, não da estratégia.
- **Fallback 127.0.0.1 em bash puro: NÃO é viável** sem `nc`/`socat`/Python/Node (bash `/dev/tcp` só conecta, não escuta).
  Não é preciso: `file://` basta. Se algum navegador falhar, o plano B é abrir a página já em modo "snapshot" (sem
  atualização) com aviso na própria tela; não implementar servidor.
- Achado importante de custo: nesta máquina Windows, **cada invocação de `bash` custa ~145 ms** (10 execuções de
  `bash -c 'exit 0'` = 1,44 s); a extração completa do hook custou ~175 ms. Ver risco R4.

### 2.2 Prova de conceito da extração de JSON em bash puro (sem jq)

`office-poc/extract.sh`: lê o stdin com `read -n 65536` (limite), extrai campos com `[[ =~ ]]` e builtins (sem
subprocessos). Verificado com `j1.json`/`j2.json`:

- `"tool_name":"Evil"` embutido (escapado como `\"tool_name\":\"Evil\"`) dentro de `tool_input.command` NÃO é capturado:
  saída `tool=Bash`. A regex exige que a aspa de abertura da chave não seja precedida de `\`.
- Descrição com `\n`, `\"`, `<b>`, `\\` sai saneada: `Implementar autenticação T-003 rm -rf  x ` (UTF-8 preservado).
- Armadilhas encontradas (a implementação deve evitar): `${d//$bs$bs/x}` sem aspas casa 1 barra, não 2 (usar
  `"$bs$bs"`); em padrões de substituição usar sempre expansões entre aspas.

## 3. Entidades

| Entidade | Descrição |
|---|---|
| Preferência | `on` ou `off` em `${CLAUDE_CONFIG_DIR:-$HOME/.claude}/sdd/office.conf`. Arquivo ausente = nunca perguntado (tratado como desligado) |
| Pasta da sala | `${TMPDIR:-/tmp}/sdd-office/<projeto-id>/` (modo 700): `events.js`, `office.html` (cópia) |
| Evento | uma linha de `events.js` (contrato 5.1) |
| Personagem | agente na tela: `key` (tipo do agente), mesa, estado, posição, frase atual |
| Estado | `idle`, `working`, `delivering`, `meeting` (+ `arriving` visual na entrada) |

## 4. Casos de Uso

- **UC-1 Oferecer opt-in (REQ-001)**: no início de sessão o hook imprime `[sdd:office] pref=unset|on|off`; com `unset` o
  TecLeader faz UMA pergunta (ver 7) e grava a resposta (`on` ou `off`, para nunca perguntar de novo).
- **UC-2 Ligar/desligar/consultar**: `/sdd:office on|off|status` ou texto livre ao TecLeader; ambos chamam
  `office-pref.sh`. `on` já tenta abrir a tela na hora (decisão D6).
- **UC-3 Abrir (REQ-002)**: `SessionStart` `startup` com `pref=on` copia o HTML e abre o navegador.
- **UC-4 Registrar atividade (REQ-003/004)**: hooks gravam eventos allowlist.
- **UC-5 Ver o processo (REQ-005)**: a página consome eventos, anima personagens e mostra o popup.
- **UC-6 Estados de UX da página**: aguardando (arquivo ausente/sem eventos: "Aguardando agentes..."), pausada
  (sem eventos há > 5 min: personagens ociosos e aviso "sem atividade"), erro (script de eventos não carrega: mensagem
  "Não foi possível ler os eventos" com a pasta no texto SEM caminho completo), vazio, sucesso (entrega concluída).

## 5. Contratos

### 5.1 Arquivo de eventos `events.js` (transporte)

Uma linha por evento, chamando uma função global definida pela página antes de cada recarga:

```js
E({"i":"1760200000-12345","t":1760200000,"e":"tool","a":"backend","d":"a1b2c3","k":"edit","m":"","g":""});
```

| Campo | Tipo/charset | Limite | Origem |
|---|---|---|---|
| `i` | `[0-9-]` id do evento (epoch + `$RANDOM`) para dedupe | 24 | gerado |
| `t` | inteiro epoch segundos | 12 | gerado (`printf '%(%s)T'` se bash >= 4.2, senão `date +%s`) |
| `e` | enum: `start`, `stop`, `tool`, `prompt`, `end` | fixo | evento do hook (mapeado, nunca copiado) |
| `a` | tipo do agente `[A-Za-z0-9_.-]`, prefixo `sdd:` removido; vazio = sessão principal (a página mostra "tecleader") | 32 | `agent_type` |
| `d` | id do agente `[A-Za-z0-9]` | 12 | `agent_id` truncado |
| `k` | CATEGORIA da ferramenta (enum fixo): `read`, `edit`, `run`, `web`, `delegate`, `plan`, `ask`, `mcp`, `other` | fixo | mapeada de `tool_name` por `case`; o nome bruto e qualquer nome `mcp__*` NUNCA é gravado |
| `m` | descrição curta: só quando `tool_name` é `Agent`/`Task`; caracteres `A-Za-z0-9 .,:;()#_/+-` e bytes UTF-8 altos; sem `"` e `\`; controles viram espaço; espaços colapsados | 80 bytes | `tool_input.description` |
| `g` | agente de destino da delegação, mesmo charset de `a` | 32 | `tool_input.subagent_type` |

Linha total no máximo 400 bytes; campo fora do charset/tamanho é descartado (campo vazio), nunca "limpo e aceito" no caso
de `a`, `d`, `k`, `g`. NÃO gravar: `session_id`, `cwd`, `transcript_path`, `last_assistant_message`, `tool_input` (exceto
`description`/`subagent_type` de `Agent`), `tool_response`, `prompt`, caminhos.
Redação extra em `m`: se casar `sk-`, `ghp_`, `AKIA`, `Bearer`, `password`, `secret`, `token` (sem diferenciar caixa),
trocar por `[omitido]` (descrição de delegação não deveria conter segredos; defesa em profundidade).

Rotação: em ~5% dos eventos (`RANDOM % 20 == 0`) e em todo `stop`/`start` de sessão, se o arquivo passar de 400 linhas
ou 64 KiB, `tail -n 200 > events.js.tmp && mv -f` (atômico). Perda de linha por corrida entre hooks paralelos é
aceitável (efeito só visual). Sessão nova (`startup`) recria o arquivo vazio.
Escrita: `umask 077`; append de uma linha por `printf >>` (atômico para linhas curtas).

### 5.2 Id do projeto sem vazar caminho

`projeto-id` = saída de `printf '%s' "$CLAUDE_PROJECT_DIR" | cksum`, reduzida a `<crc>-<tamanho>` (apenas dígitos e
hífen; POSIX, presente em Git Bash, macOS e Linux), calculado em cada hook (custo ~10 ms; decisão D5). O caminho em si
nunca é escrito em arquivo, na página ou na saída; a pasta não revela o nome do projeto. Sem `CLAUDE_PROJECT_DIR`, usar
`$PWD`. Colisão de CRC32 entre dois projetos só mistura animações (R7).

Pasta no Windows: `/tmp` do Git Bash = `%TEMP%`. O navegador recebe o caminho Windows via `cygpath -m` (se existir).

### 5.3 Preferência `office.conf`

Conteúdo exatamente `on` ou `off` mais `\n`. Hooks tratam como ligado SOMENTE se a primeira linha for `on` (qualquer
outra coisa, inclusive arquivo ilegível, = desligado). Fora do repositório e por usuário; vale para todos os projetos.
`CLAUDE_CONFIG_DIR` respeitado; fallback `$HOME/.claude`. (`${CLAUDE_PLUGIN_DATA}` seria alternativa, mas não consta nos
fatos confirmados; não usar sem verificação.)

### 5.4 `office-pref.sh on|off|status` (única escrita permitida à skill/TecLeader)

- Valida o argumento com `case` (qualquer outro valor: uso e `exit 2`); não aceita caminho nem texto livre.
- `on`/`off`: `mkdir -p` (modo 700) da pasta `sdd`, escreve só a constante, imprime `[sdd:office] pref=on|off`.
- `status`: imprime `pref=on|off|unset` e se há sala ativa (pasta existe), sem caminhos.
- `on` chama `office-start.sh --now` (abrir agora, mesma proteção de falha).
- Nada de `eval`, nada de rede, nada vindo de variáveis além de `HOME`/`CLAUDE_CONFIG_DIR`.

### 5.5 Skill `skills/office/SKILL.md` (`/sdd:office`)

`description` curta; `argument-hint: on|off|status`; `disable-model-invocation: true` (só o usuário dispara o slash);
`allowed-tools: Bash(bash ${CLAUDE_PLUGIN_ROOT}/hooks/office-pref.sh:*)`. Instrução: executar o script com o argumento
(se faltar, `status`), mostrar a saída em pt-BR e, para `on`, avisar "abre sozinha nas próximas sessões; já tentei abrir
agora". A skill NÃO escreve em nenhum outro lugar. O TecLeader usa o mesmo script (confirmar que o agente tem a
ferramenta Bash e a permissão; senão pedir ao usuário para digitar `/sdd:office on`).

### 5.6 Hooks (`hooks/hooks.json`)

| Evento | Matcher | Script | Registra |
|---|---|---|---|
| `SessionStart` | `startup` (novo bloco, em paralelo ao onboarding) | `office-start.sh` | imprime `[sdd:office] pref=...`; se `on`: recria pasta, copia HTML, abre navegador, grava `e=start` (sessão) |
| `SubagentStart` | (sem matcher = todos) | `office-event.sh` | `e=start`, `a`=agent_type, `d` |
| `SubagentStop` | (todos) | `office-event.sh` | `e=stop`, `a`, `d` (NÃO lê `last_assistant_message`) |
| `PreToolUse` | `*` | `office-event.sh` | `e=tool`, `k`, `a`/`d` (vazios na sessão principal), `m`/`g` se `Agent` |
| `UserPromptSubmit` | (todos) | `office-event.sh` | `e=prompt` (TecLeader "recebeu o pedido"), sem texto |
| `Stop` | (todos) | `office-event.sh` | `e=end` (sessão principal ociosa) |

`PostToolUse` NÃO é registrado (decisão D3): metade do custo de processos e o "trabalhando" decai por tempo (8 s sem
evento do agente = ocioso); a conclusão de uma entrega vem de `SubagentStop`. `timeout`: 5 s no script de eventos
(execução real: dezenas de ms), 10 s no `office-start.sh` (igual ao onboarding). Todos os scripts: `exit 0` sempre,
sem `set -e`, sem `eval`, stdout vazio (evento) ou só constantes (start), stderr descartado.

Custo quando desligado: o primeiro comando do `office-event.sh` lê só o arquivo de preferência
(`read -r p < "$cfg"`, builtin) e faz `exit 0` ANTES de ler o stdin e antes de qualquer subprocesso. Risco conhecido:
o processo escritor (Claude Code) pode receber SIGPIPE/EPIPE ao fechar sem ler; hooks existentes de terceiros fazem
isso com frequência e é tratado como inofensivo, mas validar no T-004 (Windows). Ainda assim o custo mínimo é o do
próprio spawn do bash (~145 ms/hook no Windows medido aqui; ~5 ms em Linux/macOS): é inevitável porque o plugin não
pode registrar hooks condicionalmente. Ver R4 e D3.

## 6. Máquina de estados e popup

### 6.1 Estados do personagem

| De | Evento | Para | Efeito visual |
|---|---|---|---|
| (ausente) | `start` do agente | `arriving` -> `working` | entra pela porta e senta na mesa (mesa criada se desconhecido) |
| `idle` | `tool` do agente | `working` | animação de digitar |
| `working` | `tool` | `working` | renova relógio de inatividade; frase pela categoria |
| `working` | 8 s sem evento | `idle` | para de digitar, respira (2 frames) |
| `working`/`idle` | `stop` do agente | `delivering` | levanta, anda até a mesa do TecLeader (~3 s), "entrega" (ícone de papel), volta e fica `idle` |
| qualquer | `tool` ou `start` com `a` = `security` | `meeting` | vai à sala de reunião (mesa redonda) e fica lá enquanto houver eventos; ao `stop`, `delivering` |
| tecleader | `prompt` | `working` | popup "recebeu um pedido" |
| tecleader | `tool` com `k=delegate` | `working` | balão "delegou ... ao X" e o X fica `arriving`/`working` |
| tecleader | `end` | `idle` | |
| sessão | sem eventos > 5 min | todos `idle` | aviso "sem atividade" |

`prefers-reduced-motion: reduce`: sem caminhada nem transições; personagens trocam de posição instantaneamente e usam
apenas o quadro 0; a lista de texto continua atualizando.

### 6.2 Frases do popup (mapa fixo; a página nunca exibe o texto cru do evento exceto `m`)

| Origem | Frase (pt-BR) |
|---|---|
| `k=read` | "<agente>: lendo o código" |
| `k=edit` | "<agente>: editando arquivos" (sem nome de arquivo) |
| `k=run` | "<agente>: executando comandos"; se agente = `tests`: "tests: rodando validação"; se `security`: "security: revisando" |
| `k=web` | "<agente>: pesquisando" |
| `k=plan` | "<agente>: atualizando o plano" |
| `k=ask` | "<agente>: aguardando você" |
| `k=mcp` | "<agente>: consultando um serviço externo" |
| `k=other` | "<agente>: trabalhando" |
| `k=delegate` com `g` | "TecLeader → delegou \"<m>\" ao <g>" (sem `m`: "TecLeader → delegou uma tarefa ao <g>") |
| `e=start` | "<agente> chegou" |
| `e=stop` | "<agente> entregou o resultado ao TecLeader" |
| `e=prompt` | "TecLeader: recebeu um pedido" |
| `e=end` | "TecLeader: aguardando" |

Nome de agente exibido: `a` com primeira letra maiúscula (`tecleader` -> "TecLeader" via tabela dos 6 conhecidos;
desconhecidos: texto saneado). `m` é inserido sempre com `textContent` (nunca `innerHTML`). Popup: balão junto ao
personagem do evento mais recente + painel "Agora" com as últimas 5 linhas; no máximo 1 linha nova por segundo (fila).
Paralelismo: N personagens `working` ao mesmo tempo, balões de cada um por até 4 s.

## 7. Onde o TecLeader oferece o opt-in (REQ-001)

`agents/tecleader.md`:

1. Seção "Início de sessão (verificação de onboarding)": novo passo após a tabela de situação git (o diagnóstico
   `[sdd:office] pref=` chega pelo hook `office-start.sh`, no mesmo SessionStart): se `pref=unset` (e não é a primeira
   resposta de um workspace sem projeto), ao FIM da primeira resposta (depois de tratar o pedido, para não bloquear)
   fazer uma única pergunta: "Quer ligar a salinha dos agentes (tela no navegador com os agentes trabalhando)? Dá para
   mudar a qualquer momento com /sdd:office on|off". Aceitou -> `office-pref.sh on`; recusou -> `office-pref.sh off`
   (para não perguntar de novo). Se o diagnóstico estiver ausente, não oferecer.
2. Seção "Onboarding de Projeto": último item da configuração inicial: mesma oferta (aqui pode ser feita antes da
   primeira tarefa, pois o usuário já está na configuração), pulando se `pref` já definido.
3. Pedido em texto livre ("liga/desliga a salinha"): o TecLeader executa `office-pref.sh` com o argumento.
O `pref` é lido do hook, nunca de arquivos do projeto.

## 8. Arte e acessibilidade (REQ-005)

- Canvas lógico 320x200 (cena fixa; mesas extras em grade quando houver agentes desconhecidos, até 16 mesas), ampliado por
  CSS em múltiplo inteiro (`image-rendering: pixelated`, `ctx.imageSmoothingEnabled = false`). Layout: sala principal
  com mesa do TecLeader ao centro-fundo, uma mesa por agente; sala de reunião à direita (porta, mesa redonda, 4 cadeiras).
- Sprites 12x16 como matrizes de strings (uma letra = índice de paleta), 4 quadros (parado, digitando A/B, andando A/B)
  por direção horizontal (espelhamento no desenho). Paleta limitada (16 cores, estilo 16 bits); cor da camisa/cabelo
  por agente (tabela fixa para os 6 conhecidos; desconhecidos: cor derivada do hash do nome). Mobiliário e ícones
  (papel, balão, tela do monitor piscando) por `fillRect` e matrizes.
- Laço com `requestAnimationFrame` limitado a ~10 quadros/s e pausado quando `document.hidden`.
- Acessibilidade: texto do popup em HTML (não no canvas), contraste >= 4.5:1, fonte do sistema (`monospace`, sem fonte
  externa), alvo mínimo 24 px nos controles; painel "Agora" com `role="log"` `aria-live="polite"`; canvas com
  `role="img"` e `aria-label` resumo ("N agentes; X trabalhando"); botão "Pausar animação" além de
  `prefers-reduced-motion`; `<html lang="pt-BR">`; cabeçalho com status da conexão (aguardando/ativo/sem atividade).
- CSP na própria página: `<meta http-equiv="Content-Security-Policy" content="default-src 'none'; script-src 'self'
  'unsafe-inline'; style-src 'unsafe-inline'">` (em `file://` `'self'` pode não casar entre navegadores; testar; sem
  `connect-src`, `img-src` ou `font-src` externos). Nenhuma URL `http(s)://` no arquivo (teste por grep).

## 9. Riscos e mitigação

| # | Risco | Mitigação |
|---|---|---|
| R1 | Privacidade: vazar comando/arquivo/segredo | allowlist estrita (5.1), categoria da ferramenta em vez do nome, nada de `tool_input` exceto `description`/`subagent_type` de `Agent`, redação de padrões de segredo, pasta tmp modo 700, arquivo nunca no repo; teste com segredos falsos (T-004) |
| R2 | Injeção via descrição ou campos forjados | regex que ignora chave escapada (provado na PoC 2.2), charset restrito, truncamento, `"` e `\` removidos (JS seguro), só `textContent` na página |
| R3 | XSS no popup | `textContent` obrigatório; sem `innerHTML`/`eval`; CSP na página; revisão `sdd:security` |
| R4 | Latência dos hooks (PreToolUse em toda ferramenta) | ~145-175 ms por chamada no Windows medido; saída antecipada se desligado (sem stdin); sem `PostToolUse`; avaliar `"async": true` no hook de eventos (existência/semântica NÃO verificada: sem rede nesta task; verificar na documentação antes do T-002); se custo inaceitável, reduzir a `SubagentStart/Stop` + `PreToolUse` com matcher `Agent|Task` (perde frases por ferramenta) |
| R5 | Windows sem Git Bash / hooks em outro shell | mesmo pressuposto do `onboarding-check.sh`; falha vira no-op silencioso (exit 0 / comando bash ausente não derruba a sessão); documentar |
| R6 | Abrir navegador: falha, ambiente sem display/SSH, várias abas | `start`/`open`/`xdg-open` em segundo plano com stdout/stderr descartados, só se houver `DISPLAY`/`WAYLAND_DISPLAY` no Linux, `exit 0` sempre; trava `opened-<id>` com mtime < 15 s evita abas duplicadas em sessões simultâneas; cada `startup` abre uma aba (acordado em REQ-002: 1x por sessão) |
| R7 | Mais de uma sessão no mesmo projeto misturam eventos | aceito (efeito visual); `d`/`a` distinguem agentes |
| R8 | Abrir pelo `start` interpretar o caminho | caminho montado só com constantes e o id derivado (charset `[A-Za-z0-9_-]`), aspas, `start ""`; nunca usar texto do projeto na linha de comando |
| R9 | Arquivo cresce/rotação perde linhas | limite 400 linhas/64 KiB, rotação atômica; perda cosmética |
| R10 | Arquivo em `%TEMP%` legível por outros usuários | `umask 077` e pasta 700 (em Windows o ACL de `%TEMP%` já é por usuário) |
| R11 | Navegador bloqueia `file://` em algum caso (políticas corporativas) | tela mostra aviso "sem atualização automática"; sem servidor (inviável em bash puro, 2.1) |
| R12 | `PreToolUse` na sessão principal rotulado como TecLeader quando o agente da sessão não é o TecLeader | rótulo "sessão principal" -> exibido como TecLeader; documentar |

## 10. Estratégia de Implementação (T-002)

Arquivos a criar/alterar (no plugin `sdd`; versão 0.7.0):

| Arquivo | Ação | Tamanho estimado |
|---|---|---|
| `hooks/office-event.sh` | criar | ~110 linhas |
| `hooks/office-start.sh` | criar | ~80 linhas |
| `hooks/office-pref.sh` | criar | ~45 linhas |
| `hooks/hooks.json` | alterar (SessionStart novo bloco + 5 eventos) | +45 linhas |
| `office/office.html` (HTML+CSS+JS em arquivo único, sprites incluídos) | criar | ~600 linhas |
| `skills/office/SKILL.md` | criar | ~35 linhas |
| `agents/tecleader.md` | alterar (início de sessão, onboarding) | +15 linhas |
| `README.md`, manual, guia de primeiros passos, `docs/` | alterar (REQ-006) | ~60 linhas |
| `.claude-plugin/plugin.json` (versão 0.7.0), `CHANGELOG.md` | alterar | pequeno |

Ordem: (1) `office-pref.sh` + skill; (2) `office-event.sh` com testes de vazamento; (3) `office-start.sh`; (4) página
(layout e sprites, depois máquina de estados, depois popup/acessibilidade); (5) hooks.json; (6) tecleader e docs.
Esforço total ~2 a 3 dias de frontend/bash. `office.html` fica em arquivo único para a cópia ao tmp ser trivial.

## 11. Estratégia de Testes

Rastreabilidade: nomes `req001`..`req006` em arquivos/casos de teste.

| REQ | Teste |
|---|---|
| req001 | `office-pref.sh on/off/status/invalido` com `HOME` temporário: conteúdo exato, `exit 2` em argumento inválido, `unset` sem arquivo; skill valida (`claude plugin validate --strict`) |
| req002 | `office-start.sh` com stubs de `open`/`xdg-open`/`cmd.exe` no `PATH`: chamado 1x em `startup` com `on`, 0x com `off`/`unset`, `exit 0` quando o stub falha, nada em `compact`/`resume` (hooks.json só `startup`) |
| req003 | `office-event.sh` desligado: não cria arquivo, não lê stdin; ligado: linha por evento; `hooks.json` contém os eventos |
| req004 | entradas JSON com segredos falsos em `command`, `file_path`, `prompt`, `last_assistant_message`, `tool_response` e chave escapada forjada: `events.js` só contém campos da allowlist e nenhum segredo; descrição com `<script>`, `"`, `\`, controles; tamanho máximo; rotação |
| req005 | Chrome/Edge headless + CDP (como na PoC): copiar a página para uma pasta tmp, escrever `events.js` de fixtures, ler DOM e capturar screenshots (estados: aguardando, trabalhando, delegou, entrega, reunião de segurança, agente desconhecido, reduced-motion via emulação); `grep` por `http://`, `https://`, `innerHTML`, `eval` na página = vazio |
| req006 | checagem de docs/versão/CHANGELOG (T-005) |

Testes rodam em bash + Node (somente na máquina de desenvolvimento/CI; o usuário final não precisa de Node).

## 12. Decisões que exigem aprovação do TecLeader

- D1 Preferência em `~/.claude/sdd/office.conf` (valores `on`/`off`, ausente = não perguntado) escrita só por
  `office-pref.sh` com argumento validado, em vez de a skill usar a ferramenta de escrita livre.
- D2 `file://` + `events.js` recarregado a cada 1 s (provado); sem servidor 127.0.0.1 (inviável em bash puro).
- D3 Não registrar `PostToolUse`; registrar `UserPromptSubmit` e `Stop` (eventos da sessão principal) além dos 3 pedidos.
  Pendente: verificar `"async": true` para tirar o custo de ~150 ms/ferramenta do caminho crítico no Windows.
- D4 Gravar CATEGORIA da ferramenta (`k`) em vez de `tool_name`, e `g` (subagent_type) além dos campos da spec
  (é nome/tipo de agente; a spec lista "nome/tipo do agente").
- D5 Id do projeto = `cksum` do caminho em cada hook (+10 ms) em vez de id pré-calculado.
- D6 `/sdd:office on` abre a tela imediatamente além de valer nas próximas sessões.
- D7 Oferta do opt-in no FIM da primeira resposta (não antes do pedido) e no fim do Onboarding de Projeto.
- D8 CSP por `<meta>` na página e botão "Pausar animação".

## 13. Aprovação do TecLeader (2026-10-11)

**APROVADO com ajustes.** Implementação liberada (T-002) seguindo este design e os ajustes abaixo, que prevalecem.

- **A1 (D3, latência):** todos os hooks da salinha (`office-event.sh` e `office-start.sh`) com `"async": true` (doc
  oficial: "run it in the background without blocking Claude"; sem timeout imposto; saída do async não é usada). O
  onboarding-check continua síncrono. Manter PreToolUse com matcher `*`, sem PostToolUse. Registrar no CHANGELOG/README
  o custo residual (um processo por evento, fora do caminho crítico) e que, em versões do CLI sem `async`, o hook
  bloquearia ~150 ms no Windows.
- **A2 (D1):** aprovado `~/.claude/sdd/office.conf` (respeitando `CLAUDE_CONFIG_DIR`) escrito só por `office-pref.sh`.
  O TecLeader tem Bash: usa `bash "${CLAUDE_PLUGIN_ROOT}/hooks/office-pref.sh" on|off|status` (substituição confirmada
  no corpo do agente). Na skill, verificar se `${CLAUDE_PLUGIN_ROOT}` é substituído em `allowed-tools` do frontmatter;
  se não for, remover `allowed-tools` (o usuário aprova o comando) e registrar.
- **A3 (D4):** aprovado gravar a categoria (`k`) e o destino (`g`); spec atualizada (allowlist inclui `g`).
- **A4 (D5, D6, D8):** aprovados.
- **A5 (D7):** oferta ao fim da primeira resposta quando `pref=unset` e ao fim do Onboarding de Projeto; recusa grava
  `off` (não perguntar de novo); sempre citar `/sdd:office on|off`.
- **A6 (testes/POC):** é proibido encerrar processos do navegador por nome (`taskkill /IM chrome.exe` fechou janelas do
  usuário na POC). Usar perfil temporário dedicado e encerrar só o PID iniciado pelo próprio teste.
- **A7:** o `office.html` vive em `plugins/sdd/office/` (ou `hooks/`), copiado para a pasta temporária do projeto no
  início da sessão; nenhum arquivo da salinha é escrito no repositório do usuário.
