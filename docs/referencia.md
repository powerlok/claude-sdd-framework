# Referência

Detalhes dos recursos do framework. Instalar: [instalacao.md](instalacao.md). Primeira conversa: [primeiros-passos.md](primeiros-passos.md).

| Tema | Seção |
|---|---|
| Skills e Fluxo Git | [Skills](#skills) · [Fluxo Git](#fluxo-git-opcional-por-projeto) |
| Segurança do template | [Proteções do template](#proteções-do-template) |
| Organização | [Camadas do CLAUDE.md](#camadas-do-claudemd) · [Trabalhar entre projetos](#trabalhar-entre-projetos) |
| Recursos opcionais | [Salinha](#salinha-dos-agentes-opcional) · [draw.io](#diagramas-do-arquiteto-mcp-drawio-opcional) · [Playwright](#navegador-do-frontend-mcp-playwright-opcional) · [Context7](#documentação-de-bibliotecas-mcp-context7-opcional) · [Chrome DevTools](#inspeção-no-navegador-mcp-chrome-devtools-opcional) · [Jira](#jira-opcional) · [Repositório](#repositório-github-bitbucket-gitlab-azure-devops-opcional-somente-leitura) |
| Custo | [Contexto e tokens](#contexto-e-tokens) |
| Quem mexe no framework | [Desenvolvimento](#desenvolvimento-do-framework) · [Limitações](#limitações-conhecidas) |

## Skills

| Skill | Para que serve |
|---|---|
| `sdd-rules` · `sdd-governance` | Regras globais, papéis, estados, escalonamento |
| `backend-engineering` | Princípios + referências **.NET** e **Python** |
| `frontend-engineering` | Princípios + referências **React** e **Angular** e checklist de interface web |
| `mobile-engineering` | Princípios mobile + referência **React Native/Expo** (outras plataformas: sem referência, lacuna declarada) |
| `git-lang` | Comando `/sdd:git-lang pt\|en`: idioma de commits e PR (seção `## Git` do `CLAUDE.md`) |
| `project-setup`, `vcs-delivery` | Playbooks internos do TechLead (onboarding/migração/workspace; repositório/Git/publicação), carregados sob demanda para o agente principal pesar menos (0.11.0) |
| `start` | Comando `/sdd:start`: o usuário inicia o fluxo com o TechLead (situação do projeto e perguntas iniciais do onboarding) |
| `publish` | Comando `/sdd:publish bloqueada\|confirmar`: liga/desliga o modo publicação (push da branch, PR e release com confirmação a cada comando; o merge é sempre seu), só no `settings.local.json` |
| `requirements-grilling` | Perguntas certas para fechar requisitos antes da spec |
| `bug-diagnosis` | Diagnóstico de bugs em 5 fases, com teste de regressão |
| `domain-modeling` | Glossário, modelo de domínio e registro de decisões (ADR) |
| `infra-engineering` | Princípios de nuvem + referências **AWS**, **Azure** e **Google Cloud** (IaC só com prévia; mudança real exige confirmação) |

## Fluxo Git (opcional, por projeto)

Com a seção `## Git` no `CLAUDE.md` do projeto (modelo trunk-based, Conventional Commits, branch `<tipo>/<ISSUE>-<slug>`,
`Idioma: pt | en`, perguntado no onboarding), o `sdd:techlead` pode criar a **branch** e **commits locais**, sempre
**depois da sua confirmação** (mostra antes branch, mensagem e lista explícita de arquivos). Ele faz `push` da
branch de trabalho, abre o PR e cria release **só depois da sua confirmação** (padrão; dá para travar, abaixo); `rebase`, `--force`, `--no-verify`, `reset --hard` e
afins só a pedido seu, com aviso de risco; **o merge é sempre seu**. Sem a seção `## Git`, nada é criado. Convenções: `plugins/sdd/skills/sdd-rules/references/git-workflow.md`. Troque o idioma com
`/sdd:git-lang pt` ou `/sdd:git-lang en`. No `templates/project-settings.git.json`, as operações destrutivas do git
(`git reset --hard`, `git clean -f*`, `git commit --no-verify`, `git branch -D`, `git config*` etc.) pedem confirmação (`ask`).

**Modo publicação (opcional, por usuário).** Por padrão (ou com `/sdd:publish confirmar`; a escolha de travar grava só no `.claude/settings.local.json`), o TechLead faz `push -u origin <branch>` da branch de trabalho, `gh pr create` e `gh release create`, cada um com a sua confirmação. Caminho feliz: ao concluir a spec, o TechLead propõe um lote (push da branch da spec + PR com o texto montado da spec); você confirma, ele abre o PR e entrega a URL; **revisar, aprovar e fazer o merge é sempre seu**. Seguem negados: `gh pr merge`, `--admin`, `--auto`, `--delete-branch`, push para `main`/`master`, refspec, `--force`, aprovar/revisar PR e `gh api` seguem negados. Sem decisão sua, ele publica pedindo a sua confirmação a cada comando; para **travar** (nada de push, PR ou release pelo TechLead), `/sdd:publish bloqueada`.
Troque quando quiser com `/sdd:publish bloqueada|confirmar` ou pedindo ao TechLead. Limites: `ask` não vale com
`bypassPermissions` nem em `claude -p`; os padrões `Bash(...)` não cobrem `sh -c`, caminho absoluto nem alias, então o
controle real é o prompt de confirmação e a proteção de branch no servidor (recomendado: `disableBypassPermissionsMode`).
Para bloqueio total (deny), `/sdd:publish bloqueada`.

Catálogo opcional **`authoring`**: `skill-development` e `agent-development`, para criar novas skills e agentes.

## Proteções do template

[`templates/project-settings.git.json`](../templates/project-settings.git.json) declara o marketplace
(`extraKnownMarketplaces`), habilita o plugin (`enabledPlugins`) e define `"agent": "sdd:techlead"`. Por isso copie o
arquivo inteiro: o template **bloqueia** (`permissions.deny`) só o que não deve acontecer por conta do agente: o **merge de PR** (e `az repos pr update`), o token e a execução
de terceiros pelo `gh` (`auth token`, `extension install`, `alias set`), a leitura de segredos (`.env`/`.env.*`, também na edição, exceto
`.env.example`/`.sample`/`.template`; chaves e certificados; credenciais de npm, PyPI, git e `netrc`; estado e variáveis do Terraform; e, na home,
`~/.ssh`, `~/.aws`, `~/.azure`, `~/.config/gh`, `~/.kube`, `~/.docker/config.json`), a edição de `.git/**` e `~/.gitconfig` e as ferramentas locais perigosas do
draw.io e do Playwright. **Todo o git** (force push, `reset --hard`, `clean`, `rebase`, `config`, `-c`...), a **escrita em sistemas externos** (issues,
comentários, `gh api`, workflows, Jira, GitLab, Azure DevOps) e os **comandos de nuvem** (`az`, `azd`, `aws`, `gcloud`) ficam em `permissions.ask`: o Claude Code
**pergunta a cada comando** (desde a 0.10.0; antes estavam bloqueados). Leituras como `git status|diff|log` seguem livres.

**Hook `merge-guard` (desde a 0.12.0).** Regras `Bash(...)` em `deny` não pegam `sh -c '...'`, caminho absoluto nem `git -C . push` (a própria documentação diz que não são fronteira de segurança). O plugin traz
um hook `PreToolUse` que bloqueia, em **qualquer modo de permissão** e sem depender do `settings.json` do projeto, o **merge de PR** (`gh pr merge`, `glab mr merge`, `az repos pr update`, `gh|glab api` com `merge`)
e o **push forçado/destrutivo** (`--force`, `-f`, `--delete`, `+ref`, `:ref`), inclusive dentro de `sh -c`, `$(...)` e depois de `&&`. Limites: variável, `eval` ou script externo escapam (não é sandbox, que não
existe no Windows nativo), e um comando que só cita o texto (mensagem de commit com `gh pr merge`) pode ser barrado: reescreva sem o comando literal. O `deny` do template segue como segunda camada.

**Versão fixada:** o template fixa a versão com `"ref"` (tag, ex.: `"ref": "v0.12.0"`). Quem decide a versão na máquina é a entrada
`claude-sdd-framework` do `~/.claude/settings.json`; para subir de versão, troque o `ref` dela, rode
`claude plugin marketplace add "...git#vNOVA"` e `claude plugin update sdd@claude-sdd-framework --scope project`
([passo a passo](instalacao.md#e-atualizar-a-versão)). Sem `ref`, vale a branch padrão do repositório
(sempre a última versão).

> **Limites:** o deny é defesa em profundidade, não barreira. O deny de `Read` cobre as ferramentas de arquivo e os
> comandos de arquivo que o Claude Code reconhece no Bash (`cat`, `head`, `tail`, `sed`, `tee`, redirecionamentos),
> mas não um `grep -r` sem citar o arquivo nem um script (Python, Node) que abre o arquivo por conta própria. Padrões
> `**/` valem a partir da pasta onde a sessão começou; arquivos da home usam `~/`. O deny de `Bash` não pega o mesmo
> comando escrito de outro jeito (`sh -c '...'`, caminho absoluto do programa, `git -C . push`); flags combinadas
> (`-uf`) e `:refspec` caem só na confirmação (`ask`). No Windows sem Git Bash (ferramenta PowerShell), as regras
> `Bash(...)` não se aplicam ao PowerShell. Para bloqueio no
> sistema operacional, use o [sandbox](https://code.claude.com/docs/en/sandboxing) do Claude Code
> ([permissões](https://code.claude.com/docs/en/permissions)).

## Camadas do CLAUDE.md

O Claude Code carrega o `CLAUDE.md` da pasta aberta, dos diretórios pais e o pessoal. Cada camada tem um papel:

| Camada | Onde | O que vai | Versionado |
|---|---|---|---|
| Pessoal | `~/.claude/CLAUDE.md` | preferências suas (idioma, estilo) | não |
| Workspace | pasta-mãe dos repositórios | só o comum a todos: lista de projetos, convenções ([modelo](../templates/CLAUDE.workspace.md)) | não |
| **Projeto** | raiz do repositório | `## Stack`, comandos, arquitetura, `## Repositório`, `## SDD` ([modelo](../templates/CLAUDE.md)) | sim (padrão) |
| Processo | plugin `sdd` | regras, governança, fluxo | no repositório do framework |

- Nada duplicado entre camadas. Os `CLAUDE.md` são **concatenados** (sem sobreposição automática); em conflito, o agente
  aplica o mais específico e sinaliza (exceto os controles de segurança não relaxáveis).
- `Versionar artefatos SDD: não` (seção `## SDD` do projeto), para repositórios que não aceitam esses arquivos:
  `.claude/settings.local.json` + exclude local do git (`git rev-parse --git-path info/exclude`); `.gitignore` intocado.
- **Artefatos fora do repositório** (ex.: `CLAUDE.md`, `.specs/` e `.claude/` na pasta-mãe): o TechLead propõe o plano
  padrão de migração com **uma única confirmação** — mescla sem sobrescrever (com diff), renomeia as origens para
  `.bak-<data>` (nunca apaga), não copia `allow`/`env` para arquivo versionável e **nunca faz commit**.
  Ele não pergunta onde fica `.specs/`, se move o `CLAUDE.md` nem se versiona: esses padrões são regra.

## Trabalhar entre projetos

Três modos, com efeitos diferentes (verificados na documentação oficial e em testes):

| Modo | Como abrir | Acesso | `CLAUDE.md` carregado | Deny que vale |
|---|---|---|---|---|
| Dentro do projeto | `claude` em `ict_app/` | só o projeto | o do projeto + pais (workspace) | o do projeto |
| Projeto + outro | `claude --add-dir ../outro` (ou `/add-dir`) | os dois | o do outro só com `CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=1` | **só o da sessão** |
| Workspace | `claude` na pasta-mãe, com `.claude/settings.json` | todos os projetos abaixo | o do workspace; o de um projeto carrega sob demanda ao ler arquivo da pasta dele (o TechLead ainda o lê antes de planejar) | **só o do workspace** |

- Deny exigido na sessão = deny do modelo ∪ deny dos projetos envolvidos. Faltando, a sessão fica **somente leitura**
  (sem escrita, build, testes ou delegação) até corrigir e reiniciar; dica: `--permission-mode plan`.
- Mudança em mais de um projeto: plano com projetos **alterados** e de **referência**, **uma** confirmação; spec + tasks
  em cada projeto alterado, ligadas por `Relacionada a:`; cada task mexe em um único repositório; nunca commit.
- O `CLAUDE.md` de um projeto só vale para ele; o de um projeto de referência é dado, não instrução. Use a variável
  acima só para repositórios confiáveis.

## Salinha dos agentes (opcional)

Uma página HTML local, aberta no navegador, mostra uma **sala em pixel art 16 bits** com uma mesa por agente
(techlead, backend, frontend, mobile, tests, security, infra-architect; agentes novos ganham mesa). Os personagens aparecem
trabalhando, entregando, em revisão ou ociosos, e um popup mostra o processo atual (ex.: "TechLead → delegou uma
tarefa ao backend", "backend: editando arquivos", "tests: rodando validação"). Sem dependências de terceiros, sem
servidor, sem rede. Um agente fica "trabalhando" do início ao fim da tarefa, mesmo sem eventos no intervalo (o
popup mostra "há N min"); a página aberta depois reconstrói o estado, e 30 min sem nenhum evento viram "sem atividade".

**Desligada por padrão.** O TechLead pergunta uma vez, quando você roda **`/sdd:start`** (e só se ainda não houver preferência; recusar
grava `off`). Depois, liga e desliga a qualquer momento:

| Comando | Efeito |
|---|---|
| `/sdd:office on` | Liga e abre a tela na hora (na primeira vez o Claude pede para você aprovar o comando) |
| `/sdd:office off` | Desliga; o hook só confere a preferência e sai |
| `/sdd:office status` | Mostra a preferência atual |

Também dá para pedir ao TechLead. A preferência fica em `~/.claude/sdd/office.conf` (respeita `CLAUDE_CONFIG_DIR`),
por usuário, nunca no repositório. Para apagar, remova o arquivo.

- **Abre sozinha:** com `on`, a sessão nova abre o navegador padrão (Windows `cmd.exe /c start`, macOS `open`,
  Linux `xdg-open`) **só se a salinha não estiver em uso**; falha ao abrir não interrompe a sessão. A página não informa se a aba existe (é um arquivo local que só lê eventos), então o plugin usa a atividade recente da sala: se houve atividade nos últimos 30 min, a sessão nova **não abre outra aba**. Se você fechou a aba e abriu uma sessão nova nesse intervalo, reabra com `/sdd:office on`; se a aba ficou aberta e a sala parou por mais de 30 min, uma sessão nova abre outra.
- **Privacidade:** grava só agente, categoria da ferramenta (read/edit/run/web/delegate/plan/ask/mcp/other), agente de
  destino da delegação, tipo do evento, horário e a descrição curta da delegação (caminhos, termos de segredo e senhas
  viram `[omitido]`). Nunca grava conteúdo de arquivos, comandos, prompts, saídas ou caminhos. Os arquivos ficam na
  pasta temporária do sistema (`sdd-office-<uid>/<sala>/`), nunca no repositório; a sala é por projeto (hash do caminho).
- **Custo:** os hooks usam `"async": true`; no Windows cada hook abre um bash (~165 ms) fora do caminho crítico. Em
  versão do CLI sem suporte a `async`, cada hook bloquearia ~165 ms por evento.
- **Limites:** exige bash (Git Bash no Windows; atenção ao bash do WSL no PATH) e navegador moderno. Validada em Chrome 155
  e Edge 154 no Windows, com Claude Code 2.1.296; **não testada** em macOS, Linux nem Firefox. A página usa `file://` com
  reinjeção de script a cada 1 s: política corporativa que bloqueie `file://` impede a atualização (a página avisa).
  Tem botão "Pausar animação" e respeita `prefers-reduced-motion`.
- **Segurança:** revisada em 3 voltas (aprovada); 363 testes (shell + página).

## Contexto e tokens

Cada mensagem reenvia a conversa inteira, então o custo cresce com o contexto. Configuração conforme a [documentação oficial](https://code.claude.com/docs/en/costs) (verificada em 2026-10-14):

- **Compactação automática:** o modelo de settings traz `"autoCompactWindow": 200000`. Sem isso, modelos de 1 milhão de tokens só compactam perto de ~967 mil. Aceita 100.000 a 1.000.000;
  mude com `/autocompact 500k` (por modelo, vale mais que o arquivo), `claude --autocompact`, `CLAUDE_CODE_AUTO_COMPACT_WINDOW`, ou remova a chave para o padrão. Compactar em 200 mil perde detalhe da conversa no
  resumo (o estado fica em `.specs/` e `tasks.md`) e a compactação em si é uma requisição grande: se preferir a janela cheia, remova a chave.
- **Subagentes:** `backend`, `frontend`, `mobile` e `tests` compactam em 140.000 (70% de 200 mil; campo `autoCompactWindow` do agente, exige Claude Code 2.1.296+; em versões anteriores é ignorado).
  Cada delegação tem janela isolada: só o resumo volta para a conversa principal.
- **O que sobrevive à compactação:** o prompt do agente continua valendo; o `CLAUDE.md` da raiz é relido do disco; corpos de skills invocadas são reinjetados (até 5.000 tokens por skill e 25.000 no total;
  o truncamento mantém o início, então cada `SKILL.md` do framework tem ≤ 15 KB e o essencial no topo); a lista de skills não volta. O hook `SessionStart` (`compact`) manda reler a spec e as tasks.
- **`## Compact instructions`:** o modelo de `CLAUDE.md` (e o onboarding) inclui a seção que orienta o resumo: spec ativa, REQs, estado das tasks, decisões, arquivos alterados, testes e pendências.
  Em projetos já existentes, copie a seção de [`templates/CLAUDE.md`](../templates/CLAUDE.md).
- **`/clear` e `/compact` só você executa** (o Claude Code não deixa o agente digitá-los). O TechLead **sugere** `/clear` em uma linha ao arquivar uma spec e ao receber uma tarefa diferente, e **não** sugere na mesma
  tarefa; sugere `/compact Preserve: ...` para guiar o resumo. `/context` mostra o que ocupa a janela; `/rewind` (Summarize from here) compacta só uma parte. Depois de `/clear`, o diagnóstico de onboarding é reinjetado.
- **O framework não abre contexto novo por spec:** só as delegações a subagentes têm janela isolada.

## Diagramas do arquiteto: MCP draw.io (opcional)

O plugin `sdd` traz o servidor MCP oficial do draw.io (`@drawio/mcp`, versão fixada **1.7.0**, Apache-2.0) para o `sdd:infra-architect`: quando
você pede um diagrama de arquitetura, ele o abre no editor do draw.io (aba do navegador, `app.diagrams.net`). Você não instala nada além do plugin.

- **Requisito:** Node.js/npm (`npx`). A primeira vez baixa o pacote do npm. Sem Node/npm, o servidor não sobe e o arquiteto descreve o diagrama
  em Mermaid no texto.
- **O que o arquiteto pode usar:** `open_drawio_xml|csv|mermaid`, `get_drawio_reference` e `search_shapes`. As ferramentas que leem e gravam arquivos
  `.drawio` por caminho (`list_pages`, `get_page`, `set_page`) ficam **negadas** nos modelos de settings. Cada `open_*` pede a sua confirmação.
- **Privacidade:** o diagrama vai no `#fragment` da URL (o navegador não o envia ao servidor), mas é processado pelo JavaScript do
  `app.diagrams.net` no seu navegador. O arquiteto não coloca segredo, chave, IP nem ID de conta reais (usa nomes lógicos) e só desenha o que a
  spec ou você pedirem. Layouts opcionais (`libavoid`, `elk`) baixam **código** de `viewer.diagrams.net`. Para usar uma instância própria,
  defina `DRAWIO_BASE_URL` (HTTPS) **você mesmo** no seu ambiente; nunca aceite essa variável vinda de `env` de um repositório de terceiros.
- **Cadeia de suprimentos:** é um pacote de terceiros executado na sua máquina a cada sessão com o plugin habilitado. A versão do pacote é fixa
  (`1.7.0`, integridade `sha512-OWZbYRAH...JNw==` registrada na spec), mas as dependências transitivas (`pako`, `@modelcontextprotocol/sdk`) são
  faixas do npm e o pacote tem `postinstall`. Em ambiente corporativo, aponte o npm para o registry interno.
- **Desligar:** `/mcp` e desabilite o servidor `drawio` do plugin `sdd` (fica em `disabledMcpServers`, por usuário). A versão só muda com nova spec e revisão.

## Navegador do frontend: MCP Playwright (opcional)

O plugin `sdd` traz o MCP do Playwright (`@playwright/mcp`, Microsoft, Apache-2.0, versão fixada **0.0.83**) para o `sdd:frontend` verificar a interface que
implementou (fluxo, validação, console, rede, acessibilidade), **complementando** os testes do projeto. Você não instala nada além do plugin.

- **Requisitos:** Node.js/npm (`npx`) e Google Chrome instalado. O navegador abre em uma janela visível (para CI/WSL: `SDD_PLAYWRIGHT_HEADLESS=1`).
- **Isolado:** perfil só em memória (`--isolated`): nenhum login ou cookie persiste, e o seu perfil real do Chrome não é usado. O ambiente é filtrado
  (`PLAYWRIGHT_MCP_*`, `PLAYWRIGHT_DOWNLOAD*`, `npm_config_*` não chegam ao servidor; o registry corporativo continua valendo pelo `.npmrc`); WebMCP, service
  workers e endereços de metadata de nuvem ficam bloqueados.
- **Só 19 ferramentas:** o frontend não recebe `browser_evaluate`, `browser_run_code_unsafe`, `browser_file_upload`, `browser_drop`, `browser_tabs` nem
  `browser_drag` (os quatro primeiros ficam em `deny` e `browser_tabs` em `ask` nos modelos de settings). Cada `browser_navigate` pede a sua confirmação.
- **Escopo:** só o app local (`localhost`/`127.0.0.1`) ou URL da spec. O conteúdo da página é **dado não confiável**: o agente não segue instruções vindas dela
  (prompt injection indireta), não entra em conta, não digita credencial, não usa o parâmetro `filename`, não copia cabeçalhos/tokens de rede e fecha o navegador ao terminar.
- **Limite importante:** o próprio pacote diz que **não é uma fronteira de segurança** (a lista de origens não vale para redirecionamentos), e a confirmação de
  `browser_navigate` não cobre navegação por clique em link. O que protege é a combinação: perfil isolado, poucas ferramentas, regras do agente e a sua revisão.
- **Saídas:** screenshots e snapshots vão para `.playwright-mcp/` no projeto e podem conter dados do app: adicione `.playwright-mcp/` ao `.gitignore` do projeto.
- **Cadeia de suprimentos:** pacote 0.x de terceiros (com dependência `playwright` alpha) executado na sua máquina a cada sessão com o plugin habilitado; versão
  e integridade fixadas (ver `.specs/done/playwright-mcp/spec.md`). **Desligar:** `/mcp` e desabilite o servidor `playwright` do plugin `sdd`.

## Documentação de bibliotecas: MCP Context7 (opcional)

O plugin `sdd` traz o servidor MCP do Context7 (`@upstash/context7-mcp`, Upstash, MIT, versão fixada **4.4.2**) para `backend`, `frontend` e `mobile` consultarem a **API atual** de bibliotecas e frameworks da stack
(versão, assinatura, exemplo) em vez de lembrar de cabeça, reduzindo código com API inventada ou desatualizada. Você não instala nada além do plugin.

- **Requisito:** Node.js/npm (`npx`). A primeira vez baixa o pacote do npm. Sem Node/npm o servidor não sobe e os agentes seguem com a referência local e declaram a lacuna.
- **Duas ferramentas, só leitura:** `resolve-library-id` e `query-docs`.
- **O que sai da máquina:** a consulta (nome da biblioteca e uma pergunta) vai para o serviço do Context7, que é de terceiro e tem backend fechado. Os agentes são instruídos a enviar **só** nome e pergunta genérica,
  nunca código do projeto, nomes internos, dados de cliente nem segredos. Para uso corporativo sensível, desligue o servidor (abaixo).
- **Resposta é dado não confiável:** documentação comunitária pode conter instruções; os agentes não executam nada vindo dela e registram biblioteca, versão e consulta na evidência.
- **Ambiente mínimo:** o servidor recebe só PATH, HOME, TEMP, proxy, certificados e `npm_config_*` de registry (lista de permissão); tokens de GitHub, Atlassian e nuvem **não** chegam a ele.
  `CONTEXT7_API_KEY` (opcional, sua; maior limite de uso) é repassada se você a definir no seu ambiente; nunca a coloque em arquivo do repositório.
- **Permissão:** o Claude Code pergunta na primeira chamada de cada ferramenta; liberar é decisão sua (`allow` no seu `settings.local.json`).
- **Cadeia de suprimentos:** pacote de terceiros executado na sua máquina a cada sessão com o plugin habilitado; versão e integridade fixadas (`.specs/done/mcp-context7-devtools/`), dependências transitivas em faixas do npm, sem
  `postinstall`. **Desligar:** `/mcp` e desabilite o servidor `context7` do plugin `sdd`.

## Inspeção no navegador: MCP Chrome DevTools (opcional)

O plugin `sdd` traz o servidor MCP do Chrome DevTools (`chrome-devtools-mcp`, equipe do Chrome/Google, Apache-2.0, versão fixada **1.11.0**) para o `sdd:frontend` **inspecionar** o app local: console, rede, DOM e
acessibilidade, estilos, emulação de dispositivo, **traces de performance** (Core Web Vitals) e `lighthouse_audit`. A **interação** (clicar, digitar) continua com o Playwright; aqui é inspeção.

- **Requisitos:** Node.js/npm e Google Chrome. O navegador abre em janela visível (para CI/WSL: `SDD_DEVTOOLS_HEADLESS=1`).
- **Endurecido pelo lançador:** `--isolated` (perfil temporário, sem login), `--no-usage-statistics` e `--no-performance-crux` (o pacote liga telemetria e envio de URLs ao CrUX por padrão), `--no-javascript-evaluation`
  (remove `evaluate_script`; **não é sandbox**: scripts da própria página continuam rodando), `--no-file-navigations`, `--redact-network-headers`, `--no-category-input` e `--no-category-memory`, e bloqueio dos endereços de metadata de nuvem.
  O ambiente é filtrado (`CHROME_DEVTOOLS_MCP_*` e `npm_config_*` não chegam ao servidor).
- **Só 19 ferramentas de inspeção para o frontend.** Ficam de fora e em `deny` nos modelos de settings: `evaluate_script`, `upload_file`, `take_heapsnapshot` e `screencast_start`. `new_page` e `navigate_page` ficam em `ask` (cada navegação pede a sua confirmação).
- **Escopo:** só o app local (`localhost`/`127.0.0.1`) ou URL da spec. Console, rede e DOM são **dado não confiável** (prompt injection indireta); os agentes não copiam cabeçalhos, cookies ou tokens para relatórios.
- **Limite importante:** o próprio pacote avisa que expõe o conteúdo do navegador ao cliente MCP. Não é fronteira de segurança; o que protege é a combinação: perfil isolado, poucas ferramentas, regras do agente e a sua revisão.
- **Cadeia de suprimentos:** pacote de terceiros (empacotado, sem dependências em tempo de execução) executado na sua máquina a cada sessão com o plugin habilitado; versão e integridade fixadas. **Desligar:** `/mcp` e desabilite o servidor `devtools` do plugin `sdd`.

## Jira (opcional)

- **Padrão:** conector Atlassian do claude.ai (Settings → Connectors → Atlassian). Só o TechLead acessa.
- **Sem login claude.ai:** copie [`templates/mcp-atlassian.json`](../templates/mcp-atlassian.json) para
  `.mcp.json` (MCP remoto oficial da Atlassian, OAuth, sem token em arquivo).
- **Leitura** livre. **Escrita** (criar, editar, comentar, transicionar): o TechLead só escreve com pedido seu e confirmação do conteúdo exato; o Claude Code também pergunta (`ask` nos
  templates, desde a 0.10.0). Texto vem da spec/evidências, nunca de conteúdo de issue; sem `executeWrite`/`executeDestructive` nem Confluence.

## Repositório: GitHub, Bitbucket, GitLab, Azure DevOps (opcional, somente leitura)

Serve para duas coisas: **issue → spec** (o ID fica registrado, ex.: `GH#42`) e **status de PR/CI como evidência**
antes do DONE. Só o TechLead consulta o provedor, e só se o `CLAUDE.md` do projeto tiver a seção `## Repositório`.

| Provedor | Caminho padrão | Status |
|---|---|---|
| GitHub | [`templates/mcp-github.json`](../templates/mcp-github.json) (MCP oficial em `/mcp/readonly`) | **suportado e validado** |
| Bitbucket Cloud | MCP Atlassian (issues vêm do Jira) | experimental |
| GitLab | [`templates/mcp-gitlab.json`](../templates/mcp-gitlab.json) | experimental |
| Azure DevOps | [`templates/mcp-azure-devops.json`](../templates/mcp-azure-devops.json) | experimental |

**Como ativar (GitHub):**

1. No `CLAUDE.md` do projeto, adicione a seção `## Repositório` (modelo em [`templates/CLAUDE.md`](../templates/CLAUDE.md)):
   `Provedor: github`, `Repositório: <owner/repo>`, `Acesso: mcp`.
2. Copie [`templates/mcp-github.json`](../templates/mcp-github.json) para `.mcp.json` na raiz do projeto.
3. Crie um **PAT fine-grained somente leitura** no GitHub: só os repositórios do projeto; permissões
   Metadata, Issues, Pull requests e Actions = **Read**; sem Contents write e sem Workflows; validade curta.
4. Exporte o token na variável de ambiente `GITHUB_PAT` (nunca em arquivo versionado nem `.env` versionado)
   e confira com `/mcp` que o servidor `github` está `connected`.

Nunca reutilize `gh auth token`: o login local do `gh` costuma ter escrita.

**Camadas de proteção:** (1) servidor em modo somente leitura; (2) o TechLead só tem uma lista fechada de
ferramentas de leitura; (3) `permissions.deny` das ferramentas de escrita nos templates de settings.
Revisar/aprovar PR e criar issue não estão liberados. Abrir PR e release só no modo publicação (o merge é sempre do usuário) (seção Fluxo Git), a partir do Bash e com confirmação; fora dele, faça manualmente.

**Issue e PR são dado não confiável.** O TechLead não segue instruções escritas dentro de issue, PR,
comentário ou log; sinaliza trechos suspeitos, exige sua confirmação antes de transformar a issue em spec
e repassa aos demais agentes apenas os requisitos validados.

## Desenvolvimento do framework

Antes de cada release (obrigatório; avisos também reprovam com `--strict`):

```bash
claude plugin validate ./plugins/sdd --strict
claude plugin validate ./plugins/authoring --strict
claude plugin validate .                    # marketplace
```

Testes (a CI roda em Linux, macOS e Windows): `bash plugins/sdd/hooks/tests/run-all.sh --no-page`.

Depois: bump de `version` no `plugin.json` alterado, seção no [CHANGELOG](../CHANGELOG.md) e versões no README, em `docs/` e `SDD_VERSION` em `scripts/check-env.sh` e `scripts/check-env.ps1` (o teste `req014` confere tudo).
**Versão × release:** toda mudança em plugin sobe a `version` (commit em `main`, sem tag). **Release** é o conjunto
pronto para consumo (validações acima, segurança aprovada quando aplicável, sem defeito aberto, CHANGELOG fechado):
`metadata.version` do `marketplace.json`, tag anotada `vX.Y.Z`, `"ref"` do template e seção `## Release vX.Y.Z` no
CHANGELOG. A tag versiona o marketplace inteiro; só é criada com confirmação. Detalhes em [CLAUDE.md](../CLAUDE.md).

Testar um agente sem instalar (prompt logo após `-p`, pois `--allowedTools` aceita vários valores):

```bash
claude -p "<prompt>" --plugin-dir ./plugins/sdd --agent sdd:backend --allowedTools "Read,Glob,Grep"
```

Para adicionar uma stack: crie `plugins/sdd/skills/<backend|frontend|mobile>-engineering/references/<stack>.md`,
registre na tabela do `SKILL.md`, suba a versão em `plugin.json` e registre no CHANGELOG.

```text
claude-sdd-framework/
├── .claude-plugin/marketplace.json   # marketplace (plugins sdd e authoring)
├── plugins/
│   ├── sdd/                          # agentes, skills, references e hook do processo
│   └── authoring/                    # catálogo opcional
├── templates/                        # settings (git/local), CLAUDE.md de projeto, .mcp.json (Jira, GitHub, GitLab, Azure)
├── scripts/                          # check-env.sh e check-env.ps1 (verificador de instalação, somente leitura)
├── docs/                             # instalação, primeiros passos, referência, manual de uso (HTML) e arquitetura
├── .specs/                           # specs ativas, INDEX.md e done/ (concluídas)
├── CHANGELOG.md
└── CLAUDE.md
```

## Limitações conhecidas

- `skills:` só pré-carrega em subagentes; o TechLead carrega as regras pela ferramenta `Skill`.
- A verificação de onboarding no início da sessão é um hook em bash (no Windows, requer Git Bash no PATH);
  sem ele, o TechLead faz a mesma verificação lendo os arquivos.
- Stacks sem referência (ex.: Vue, Java, Go) usam os princípios gerais; o agente declara a lacuna.
- A salinha dos agentes (opcional) só foi validada no Windows (Chrome e Edge); macOS, Linux e Firefox não foram testados.
- Caminho `.mcp.json` (Jira, GitHub, GitLab, Azure DevOps) ainda não validado em rede com inspeção TLS (ex.: Zscaler).

