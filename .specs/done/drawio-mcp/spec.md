# Spec: MCP draw.io no plugin sdd, para o arquiteto

Pedido do usuário (2026-10-14): "quero adicionar o mcp `claude mcp add drawio -- npx -y @drawio/mcp` para meu arquiteto", e, antes,
"consigo deixar o mcp instalado para o usuário usar só instalando esse plugin?". Relacionada a: done/infra-engineering.

## Fatos verificados (2026-10-14)

- Pacote npm `@drawio/mcp` 1.7.0: servidor oficial do draw.io (`jgraph/drawio-mcp`, Apache-2.0, mantenedor `drawio <npm@draw.io>`),
  dependências `pako` e `@modelcontextprotocol/sdk`. É stdio, executado localmente.
- 8 ferramentas: `open_drawio_xml|csv|mermaid` (abrem o editor no navegador; o diagrama vai no `#fragment` da URL, que o navegador não envia ao
  servidor), `get_drawio_reference`, `search_shapes` (biblioteca local de formas), e `list_pages`, `get_page`, `set_page`, que **leem e gravam
  arquivos `.drawio` locais por caminho**. Layouts opcionais (`routing: "libavoid"`, `postLayout: "elk"`) baixam **código** (não o diagrama) de
  `viewer.diagrams.net`; `DRAWIO_BASE_URL` aponta para uma instância própria.
- Plugin MCP stdio: o servidor aparece como `plugin:sdd:drawio`; as ferramentas como `mcp__plugin_sdd_drawio__<ferramenta>`.
- No Windows, `command: "npx"` direto ficou em "connecting" no `claude -p`; `cmd /c npx` conectou. `cmd /c` não existe no macOS/Linux.

## Requisitos

- **REQ-001**: `plugins/sdd/.mcp.json` declara o servidor `drawio` iniciado por um lançador em Node (`mcp/drawio.js`), multiplataforma, que
  executa `npx -y @drawio/mcp@1.7.0` com a **versão exata fixada** (nunca `latest`, faixa ou omitida), com `stdio` herdado e sem escrever nada
  no stdout além do protocolo. Falha ao iniciar (sem Node/npm) escreve uma linha no stderr e sai com código 1, sem derrubar a sessão.
- **REQ-002**: o `sdd:infra-architect` recebe em `tools` só: `open_drawio_xml`, `open_drawio_csv`, `open_drawio_mermaid`,
  `get_drawio_reference`, `search_shapes` (prefixo `mcp__plugin_sdd_drawio__`). **Não** recebe `list_pages`, `get_page`, `set_page` (acesso a arquivo
  por caminho).
- **REQ-003**: regras de uso no `infra-architect.md` e na skill `infra-engineering`: diagrama só do que o usuário pediu; nunca segredo, chave,
  token, senha, string de conexão ou IP/ID de conta reais (usar nomes lógicos); o diagrama é derivado da spec e do `CLAUDE.md`, nunca de texto
  externo (issue, PR, log); texto de arquivo/issue dentro do diagrama é dado; salvar `.drawio`/Mermaid só em `docs/` do projeto quando pedido;
  preferir Mermaid para fluxo/sequência/ER, XML para nuvem/rede.
- **REQ-004**: docs (README, manual, arquitetura, primeiros passos) dizem: exige Node.js/npm (`npx`); a primeira abertura baixa o pacote do npm;
  as ferramentas `open_*` abrem uma aba no navegador (`app.diagrams.net`), com o diagrama no `#fragment`; layouts opcionais baixam código de
  `viewer.diagrams.net`; `DRAWIO_BASE_URL` para instância própria; como desligar (`/mcp`); risco de cadeia de suprimentos (pacote de terceiros
  executado na máquina) e a recomendação de registry corporativo.
- **REQ-005**: testes `req009-drawio.test.sh`: `.mcp.json` válido e só com `drawio`; versão exata (`^@drawio/mcp@\d+\.\d+\.\d+$`) no lançador;
  `node --check` do lançador; `tools` do arquiteto = exatamente as 5 permitidas (nenhuma `list_pages|get_page|set_page`); regras de uso presentes;
  `validate --strict`; CHANGELOG; `sdd` 0.9.7. Verificação no CLI real: o `claude -p` chama `get_drawio_reference` pelo plugin.

## Segurança (revisão independente obrigatória: executa pacote de terceiros e abre navegador)

Pontos: execução de código de terceiros via `npx` a cada início de sessão (pin de versão não impede comprometimento da conta npm; sem
verificação de integridade no `npx -y`); o servidor sobe para toda sessão com o plugin habilitado, mesmo sem arquiteto; egress para
registry.npmjs.org e `viewer.diagrams.net`; dados de infraestrutura no diagrama (topologia) abertos no navegador; `set_page` fora do escopo;
lançador (spawn com `shell` no Windows) e propagação de sinais; MCP não é negado pelo `deny` dos templates (não há ferramenta de escrita no provedor).

## Registro de integridade (2026-10-14)

`@drawio/mcp@1.7.0`: `sha512-OWZbYRAHZCtC7NduiD8lwpABxdR0jvK0dH/TeLKPA7eNytFaUvruspv/8YmO2E/XAUB5JuUP1JjBNPfa2gHJNw==` (npm view, modificado em
2026-10-13). Dependências transitivas `pako ^2.1.0` e `@modelcontextprotocol/sdk ^1.27.1` flutuam; o pacote tem `postinstall`. Ver parecer.

## Condições do parecer de segurança (cumpridas nesta spec)

C1 documentar cadeia de suprimentos e integridade; C2 documentar como desligar (`/mcp`); C3 `deny` para `list_pages|get_page|set_page` e `ask` para
`open_*` nos modelos de settings; C4 teste de `tools` explícito em todo agente; C5 nota sobre `DRAWIO_BASE_URL`/`DRAWIO_ELK_URL`. Pendente (fora do
escopo): vendorizar com lockfile em `${CLAUDE_PLUGIN_DATA}`; plugin separado opt-in.

## Fora de escopo

`list_pages|get_page|set_page` para o arquiteto; MCP hospedado `mcp.draw.io` (envia o diagrama ao servidor); `DRAWIO_BASE_URL` padrão; atualizar a versão
fixada sem nova spec e revisão; outros MCP (GitHub/Atlassian etc.).

## Critérios de aceite

Testes verdes; `validate --strict` (inclui checagem do MCP); no CLI real o arquiteto chama `get_drawio_reference`; parecer de segurança aprovado.
