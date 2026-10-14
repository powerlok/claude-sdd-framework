# Parecer de segurança: MCP draw.io no plugin sdd

Revisor: sdd:security (independente, somente leitura). Data: 2026-10-14. Escopo: spec, `.mcp.json`, `mcp/drawio.js`, `infra-architect.md`, skill `infra-engineering` (Diagramas), `req009-drawio.test.sh`, agentes e templates. O servidor não foi executado. Foi consultado apenas `npm view @drawio/mcp@1.7.0` e a documentação oficial (mcp, sub-agents).

## Parecer: APROVADO COM CONDIÇÕES

Nenhum achado HIGH que bloqueie, desde que a condição C1 (documentar e mitigar a cadeia de suprimentos) e C2 (opt-in/desligar) sejam atendidas junto com REQ-004.

## Achados

### MEDIUM-1: cadeia de suprimentos (Q1)
- O pin `@drawio/mcp@1.7.0` fixa a versão do pacote, mas não a árvore: `dependencies = { pako: ^2.1.0, @modelcontextprotocol/sdk: ^1.27.1 }` são flutuantes. Sem lockfile, cada máquina resolve versões transitivas diferentes e novas no momento da execução.
- `npx -y` apenas suprime o prompt. O npm valida o `integrity` (sha512) contra o que o registry devolve na hora, mas não contra um valor conhecido previamente. Isso protege contra corrupção, não contra republicação/conta npm comprometida. O pin ajuda porque o npm não permite sobrescrever versão publicada, mas não cobre dependências transitivas.
- O pacote tem `postinstall: node src/postinstall.js`, ou seja, executa script de instalação na máquina do usuário (e `prepack` só no publicador). Isso reforça o risco, e `--ignore-scripts` pode quebrar o servidor (não validado; não executei). `time.modified` do pacote é 2026-10-13, ou seja, muito recente (um dia antes da revisão), então a versão não tem "maturidade".
- Mitigações, em ordem de custo/benefício:
  1. (Condição) Documentar registry corporativo/proxy (`npm_config_registry`, `.npmrc` do usuário) com política de cooldown/aprovação de pacotes.
  2. Vendorizar: instalar uma vez em `${CLAUDE_PLUGIN_DATA}` com `npm ci` usando `package.json` + `package-lock.json` versionados no plugin (lockfile com hashes de toda a árvore) e o lançador executa `node node_modules/@drawio/mcp/src/index.js`. Elimina a resolução a cada sessão. É a correção estrutural recomendada para uma v0.10.
  3. Mínimo no lançador agora: passar `--prefer-offline` não é segurança; preferível definir `npm_config_ignore_scripts=true` somente após testar que o servidor funciona sem postinstall (se `postinstall` for essencial, não usar). Registrar o resultado do teste em ata.
  4. Verificar o `dist.integrity` conhecido (`sha512-OWZbYRAHZCtC7NduiD8lwpABxdR0jvK0dH/TeLKPA7eNytFaUvruspv/8YmO2E/XAUB5JuUP1JjBNPfa2gHJNw==`) como parte do processo de revisão de bump (registrar na spec).
- Risco residual aceito: conta npm do mantenedor comprometida em transitivas flutuantes até a vendorização.

### MEDIUM-2: servidor sobe em toda sessão com o plugin (Q2)
- Um `.mcp.json` de plugin conecta o servidor sempre que o plugin está habilitado: executa `npx` (rede para registry.npmjs.org na primeira vez, depois cache), custo de latência/processo Node, e a superfície (8 ferramentas expostas ao agente principal quando este é uma sessão sem restrição de `tools`). Mesmo quem nunca usa o arquiteto assume o risco do pacote.
- Opt-out documentado: `/mcp` permite desligar o servidor de plugin (persiste por projeto em `disabledMcpServers` em `~/.claude.json`); desinstalar o plugin remove. Opt-in real (desligado por padrão) não é suportado de forma declarativa pelo `.mcp.json`.
- Correção: (a) documentar o desligamento (REQ-004); (b) alternativa mais segura: separar em plugin opcional (`sdd-drawio`) ou deixar o `.mcp.json` fora do `sdd` e documentar `claude mcp add` por escopo de projeto. Recomendo (a) agora, avaliar (b) na vendorização.
- Falha silenciosa: servidor indisponível não derruba a sessão (OK, REQ-001 e lançador).

### MEDIUM-3: ferramentas `open_*` e vazamento/injeção (Q3)
- O diagrama vai no `#fragment` de `app.diagrams.net`. O fragmento não é enviado ao servidor em HTTP, mas o JavaScript do draw.io hospedado o processa no navegador, e o conteúdo fica no histórico/aba do navegador do usuário. Para topologia sensível isso é egress ao serviço (a página carrega código de terceiros), embora o diagrama em si não vá ao servidor. Risco principal: dado de infraestrutura exposto a quem usa/compartilha a URL/histórico.
- Prompt injection: o agente (opus) lê arquivos/issues e poderia ser induzido a embutir segredos. As regras do `infra-architect.md` (nunca segredo/IP/ID reais, nunca de texto externo, só quando pedido) são adequadas como controle de política, mas são brandas (dependem do modelo). O agente tem `Read` (inclui `.env` etc.) e o `deny` dos templates bloqueia `Read` desses arquivos, o que reduz o risco de a injeção ter o segredo disponível. Ponto positivo.
- Condição: manter `open_*` em `ask` nos templates (ver LOW-3) para o usuário ver a chamada antes de abrir o navegador. É a defesa determinística; as regras textuais não bastam sozinhas.

### LOW-1: lançador (Q5)
- Sem injeção: argumentos constantes, nenhum dado externo; `shell: true` no fallback Windows (`npx.cmd`) é necessário (CVE-2024-27980 exige shell para .cmd) e seguro porque `PKG` é constante. OK.
- Caminho principal Windows usa `node npx-cli.js` sem shell: bom. Fallback depende de `PATH`: um `npx` malicioso no PATH/cwd é risco aceito (ambiente do usuário). No Windows, com `shell:true` o `cmd` pode resolver `npx.cmd` do cwd; cwd é o projeto do usuário. Sugestão: `cwd: os.homedir()` ou o diretório do plugin para evitar resolução de binário no projeto (baixo risco).
- Sinais: SIGINT/SIGTERM repassados ao filho; porém no Windows `child.kill` com `shell:true` mata só o `cmd.exe`, deixando `npx`/`node` órfãos (fallback apenas). Também não há tratamento do fechamento do stdin (o MCP encerra fechando stdio): se o pai fechar stdin e o filho não sair, o lançador permanece. Como o stdio é herdado, o filho recebe o EOF diretamente, então é aceitável. Melhoria: no fallback usar `taskkill /T /F /PID` ou evitar shell. No caminho principal (sem shell) não há órfão no encerramento normal.
- stdout limpo: `stdio: "inherit"`, sem escrita própria; o npm escreve avisos em stderr. OK. Atenção: `npx -y` pode imprimir progresso em stdout? O npm envia saída de instalação ao stderr; o teste de conexão real (`claude -p`) cobre isso.
- Código de saída: `exit(code===null?1:code)`; se terminado por sinal sai 1. Aceitável.

### LOW-2: ferramentas herdadas e o agente principal (Q4)
- Documentação: `tools` omitido = herda todas as ferramentas disponíveis (incluindo MCP). Frontmatter `tools` de todos os agentes: backend, frontend, mobile, tests, security usam lista explícita de built-ins (sem MCP); techlead usa lista explícita (Atlassian/GitHub, sem drawio); tecleader (obsoleto) só `Read`; infra-architect tem as 5 permitidas. Nenhum agente omite `tools`, então nenhum herda `list_pages`/`get_page`/`set_page`. Conclusão: confirmado.
- A sessão principal como `agent: sdd:techlead` (settings dos templates) honra a lista `tools` do agente (a doc diz que a thread principal assume as restrições do agente; não confirma explicitamente para agentes de plugin, mas `tools` não está na lista de campos ignorados), logo não chama drawio. Porém, se o usuário NÃO usar `--agent`/`"agent"` nos settings, a sessão padrão enxerga as 8 ferramentas MCP, inclusive `set_page`/`get_page` por caminho (sujeitas ao prompt de permissão padrão). Também subagentes genéricos (`general-purpose`, `claude`, `Explore`) herdam todas as MCP.
- O teste `req009` valida "nenhum outro agente recebe drawio", mas não que todo agente tenha `tools` explícito. Correção: adicionar teste que falha se algum agente de `plugins/sdd/agents` não tiver linha `tools:`.
- Teste `! grep -l ... | grep -v infra-architect | grep -q .` com `set -e`/pipelines: verificar que não passa em vazio por erro (aceitável).

### LOW-3: templates de settings (Q6)
- `deny` atual não cobre drawio (spec reconhece). Recomendo adicionar em todos os `project-settings.*.json`:
  - `deny`: `mcp__plugin_sdd_drawio__set_page`, `mcp__plugin_sdd_drawio__get_page`, `mcp__plugin_sdd_drawio__list_pages` (leitura/escrita de arquivo por caminho, fora do escopo; `deny` vale também para sessão padrão e subagentes genéricos, fechando a lacuna do LOW-2).
  - `ask`: `mcp__plugin_sdd_drawio__open_drawio_xml`, `..._csv`, `..._mermaid` (decisão do usuário antes de abrir o navegador).
- Os arquivos `plugins/sdd/hooks/tests` já testam templates? Incluir teste de presença dessas regras.

### LOW-4: `DRAWIO_BASE_URL` / `DRAWIO_ELK_URL` (Q8)
- O servidor herda o ambiente do usuário. Se essas variáveis apontarem para host malicioso, as URLs abertas (com o diagrama no fragmento) e o código de layout baixado vêm desse host: execução de código no navegador/Node (ELK). Ambiente é do usuário (modelo de ameaça: quem controla o ambiente já controla a máquina), mas pode ser definido por `.claude/settings.json` do projeto (`env`) clonado de repositório não confiável. Correção: documentar que essas variáveis só devem ser definidas pelo próprio usuário/organização, e que `env` em settings de projeto de repositório de terceiros é vetor; opcional: o lançador pode remover as duas variáveis do ambiente do filho, a menos que o usuário defina `SDD_DRAWIO_ALLOW_CUSTOM_URL=1` (padrão seguro). Como a spec coloca a instância própria como recurso suportado (REQ-004), a opção mais simples é registrar o risco aceito e exigir HTTPS.

### INFO: nomenclatura (Q7)
- Correta segundo a doc: `mcp__plugin_<plugin>_<server>__<tool>` => `mcp__plugin_sdd_drawio__open_drawio_xml`. O servidor aparece como `plugin:sdd:drawio`. A doc manda usar essa forma completa no `tools` de subagente e nas regras de permissão. Confirmado.
- Observação de segurança de nomes: o MCP não é negado pelo `deny` por padrão; ver LOW-3.

## Condições para aprovação final
- C1: REQ-004 documenta cadeia de suprimentos (pacote de terceiros, `postinstall`, deps flutuantes), registry corporativo e a intenção de vendorizar (lockfile) em versão futura; registrar o `integrity` da 1.7.0 na spec.
- C2: documentar o desligamento via `/mcp` e `disabledMcpServers` e a desinstalação; avisar que o servidor sobe em toda sessão.
- C3: templates `project-settings.*.json` com `deny` para `list_pages|get_page|set_page` e `ask` para `open_*`.
- C4: teste adicional: todo agente do plugin tem `tools` explícito.
- C5: documentar que `DRAWIO_BASE_URL`/`DRAWIO_ELK_URL` devem ser definidas só pelo usuário (HTTPS), e nunca por `env` de repositório de terceiros.
- Recomendadas (não bloqueiam): `cwd` fixo no lançador; encerramento da árvore de processos no fallback Windows; vendorização com `npm ci` + lockfile.
