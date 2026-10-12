# Changelog

Formato por versão (semver). Regras de versionamento: `.specs/done/sdd-plugin/design.md`, seção 6.

## sdd 0.9.0 — 2026-10-11

Agente mobile (React Native/Expo) e fluxo Git (`.specs/mobile-git-workflow/spec.md`). Não é release (sem tag, sem mudança de `ref` nem de `metadata.version`).

- REQ-001/REQ-002/REQ-004: `agents/mobile.md` (`sdd:mobile`, sonnet) e skill `mobile-engineering` com `references/react-native-expo.md`; Flutter, Swift e Kotlin seguem a regra de `referência: nenhuma` + lacuna registrada.
- REQ-003: `agents/techlead.md` delega a `sdd:mobile` (lista de subagentes e campo `Stack`); `agents/security.md` ganha checklist mobile.
- REQ-005: `skills/sdd-rules/references/git-workflow.md` (trunk-based, Conventional Commits, `<tipo>/<ISSUE>-<slug>`, modelo de descrição de PR).
- REQ-006: seção `## Git` no `CLAUDE.md` do projeto (idioma perguntado no onboarding) e skill `git-lang` (`/sdd:git-lang pt|en`).
- REQ-007/REQ-009: o TechLead cria branch e commit **locais** só após confirmação (branch, mensagem e arquivos listados); nunca `push`, `merge`, `rebase`, `--force`, `--no-verify`; slug sanitizado e dado externo não vira mensagem.
- REQ-008: `templates/project-settings.git.json` (e `.local.json`) ganhou `deny` para os destrutivos do git (`reset --hard/--merge/--keep`, `clean*`, `checkout .`/`-f`/`--`, `switch -f`, `restore*`, `stash drop/clear`, `update-ref`, `reflog expire`, `rebase`, `merge`, `tag`, `branch -D`, `config*`, `commit --amend/--no-verify/-n/-a`, `add -A/./-u`, `git -c`) também com opções globais entre `git` e o subcomando (`git -C . ...`), e `Edit/Write` em `.git/**` e `~/.gitconfig`; `ask` para `git commit/add/switch/checkout/branch/push` e `eas login/build/update/submit`. Limite conhecido: wrappers (`bash -c`, `sh -c`, caminho absoluto do git) não são cobertos por padrões.
- REQ-010: `README.md`, `docs/arquitetura.md`, `docs/manual-de-uso.html`, `templates/CLAUDE.md` (seções `### Mobile` e `## Git`) e `plugin.json`/`marketplace.json` (descrições) atualizados; `sdd` 0.9.0.
- Pendente: a salinha dos agentes ainda não mostra `mobile` (mesa e personagem), porque `office/office.html` está em uso pela feature `office-working-state`.

### Migração

1. Atualize o plugin: `claude plugin marketplace update claude-sdd-framework` e `claude plugin update sdd@claude-sdd-framework --scope project`.
2. Projetos existentes sem `## Git` no `CLAUDE.md` **não** criam branch nem commit (comportamento anterior mantido). Para habilitar, rode o onboarding da seção com o TechLead (pergunta o idioma) ou copie o exemplo de `templates/CLAUDE.md`.
3. O template de settings ganhou `deny`: reaplique o template ou mescle as novas regras no `.claude/settings.json` do projeto.

## sdd 0.8.0 — 2026-10-11

Renomeação do agente principal (`.specs/done/rename-techlead/spec.md`): `sdd:tecleader` → `sdd:techlead` (o nome estava errado).

**Mudança incompatível:** quem tem `"agent": "sdd:tecleader"` no `.claude/settings.json` (ou `.claude/settings.local.json`) precisa trocar para `"agent": "sdd:techlead"`.

- REQ-001/REQ-002: `agents/tecleader.md` → `agents/techlead.md` (`name: techlead`); todas as referências em agentes, skills, hooks, testes, `office/office.html`, templates, README, `docs/` e skills do `authoring` seguem o nome novo ("TechLead").
- REQ-003: `agents/tecleader.md` permanece nesta versão como agente **obsoleto** mínimo (`tools: Read`, sem escrita): avisa da troca de nome e instrui a migração; não executa trabalho. **Será removido na versão seguinte.**
- REQ-005: `sdd` 0.8.0; sem release/tag e sem mudança de `ref` ou `metadata.version` (decisão do usuário).

### Migração

1. Atualize o plugin: `claude plugin marketplace update claude-sdd-framework` e `claude plugin update sdd@claude-sdd-framework --scope project` (com `ref` fixado, troque-o antes pela nova tag).
2. No `.claude/settings.json` do projeto, troque `"agent": "sdd:tecleader"` por `"agent": "sdd:techlead"`. Se o `agent` estiver em `.claude/settings.local.json` (workspace ou projetos com `Versionar artefatos SDD: não`), troque nele também.
3. Reinicie o Claude Code (ou `/reload-plugins`). A sessão deve responder como TechLead.
4. Transição: quem ainda não trocou abre a sessão com o agente obsoleto `sdd:tecleader`, que só mostra essa instrução e não altera nada.

## sdd 0.7.1 — 2026-10-11

Salinha dos agentes: qualidade visual (`.specs/done/office-visual/spec.md`). Só renderização em `office/office.html`; sem hooks, dados ou permissões novas. Não é release (sem tag).

- Nitidez: canvas na resolução nativa da tela (`devicePixelRatio`, redimensiona com a janela/zoom); texto (nomes das mesas, "REUNIÃO") em resolução nativa, com placa de contraste; sprites continuam pixel art.
- Layout: sala maior que ocupa a largura, mesas em fileiras com o nome legível, TecLeader em destaque, sala de reunião proporcional; sem rolagem horizontal em 375 px.
- Nome exibido do agente principal na salinha: "TechLead" (placa, lista e popup); só exibição, o agente continua `sdd:tecleader`.
- Balões de fala sem sobreposição e inteiros dentro da sala; teste de regressão (50 casos de página, 35 estáticos).

## Release v0.7.0 — 2026-10-11

Inclui: `sdd` 0.7.0, `authoring` 0.2.1.

- `marketplace.json`: `metadata.version` = `0.7.0`; tag `v0.7.0` aponta para o commit que traz essa versão.
- `templates/project-settings.git.json` e a documentação de instalação fixam `v0.7.0` (`#v0.7.0` / `"ref": "v0.7.0"`).
- Conteúdo: salinha dos agentes (opcional, desligada por padrão); validada no Windows (Chrome/Edge); macOS, Linux e Firefox não testados.

## sdd 0.7.0 — 2026-10-11

Salinha dos agentes, opcional (`.specs/done/agents-office/spec.md`).

- REQ-001 (opt-in): desligada por padrão; o TecLeader oferece uma vez (recusa grava `off`); nova skill `office` com
  `/sdd:office on|off|status`; preferência em `~/.claude/sdd/office.conf` (por usuário, fora do repositório).
- REQ-002 (abertura automática): com `on`, a sessão nova abre o navegador padrão uma vez (`cmd.exe /c start`, `open`,
  `xdg-open`); falha ao abrir não interrompe a sessão.
- REQ-003 (eventos): hooks `office-event.sh`, `office-pref.sh` e `office-start.sh` registrados em `hooks.json`.
- REQ-004 (privacidade): grava só agente, categoria da ferramenta, destino da delegação, tipo do evento, horário e
  descrição curta da delegação (caminhos e termos de segredo viram `[omitido]`); nunca conteúdo, comandos, prompts,
  saídas ou caminhos. Arquivos na pasta temporária do sistema, sala por projeto (hash do caminho).
- REQ-005 (tela): `office/office.html`, sala em pixel art 16 bits com uma mesa por agente, popup com o processo atual,
  botão "Pausar animação", respeita `prefers-reduced-motion`; sem dependências de terceiros, sem servidor, sem rede.
- Custo: hooks com `"async": true`; no Windows cada hook abre um bash (~165 ms) fora do caminho crítico; desligada, o
  hook só confere a preferência. Em CLI sem suporte a `async`, bloquearia ~165 ms por evento.
- REQ-006 (docs e versão): README, `docs/primeiros-passos.md`, manual, `docs/arquitetura.md` e `CLAUDE.md`; `sdd` 0.7.0.
- Testes: 363 (shell + página); `bash plugins/sdd/hooks/tests/run-all.sh` (~4 min no Windows; `--no-page` pula a página).
  Segurança revisada em 3 voltas (aprovada). Validado em Chrome 155 e Edge 154 no Windows, Claude Code 2.1.296; não
  testado em macOS, Linux nem Firefox.

## docs — 2026-10-11

Guia de primeiro uso (`.specs/done/first-run-guide/spec.md`), sem mudança nos plugins (sem bump).

- `docs/primeiros-passos.md` (REQ-001): guia novo para quem nunca usou o framework — pré-requisitos e teste de acesso,
  instalação na máquina (`marketplace add` com tag), Caminho A (código existente) e Caminho B (projeto do zero) com
  "Faça / Você vai ver / Confira" em cada passo, primeira conversa (onboarding pelo TecLeader), primeiro pedido, o que
  versionar, o que cada dev da equipe faz, workspace com vários repositórios, atualização de versão e problemas comuns.
- README (REQ-002): "Início rápido" reescrito em 4 passos (`marketplace add` com `#v0.6.4`, copiar o template inteiro,
  `plugin install`, abrir `claude`) com link para o guia; deny/limites e nota de `ref` movidos para a nova seção
  "Proteções do template"; removido o passo de preencher `CLAUDE.md` à mão (agora opcional); dica de PATH no Git Bash.
- Manual (REQ-003): seção "2. Instalação" alinhada aos mesmos passos, com link para o guia.

## Release v0.6.4 — 2026-10-11

Primeira release com tag. Inclui: `sdd` 0.6.4, `authoring` 0.2.1.
A tag `v0.6.4` aponta para o commit `d936397` (conteúdo dos plugins); `metadata.version` e o `ref` do template vieram
no commit seguinte, sem mudança nos plugins (tag não movida: exigiria push forçado).

- `marketplace.json`: `metadata.version` = `0.6.4` (a tag versiona o marketplace inteiro).
- `templates/project-settings.git.json` fixa a versão com `"ref": "v0.6.4"` (`.specs/done/pin-ref/spec.md`).
- Regra "Versão × release" deste repositório (`CLAUDE.md`, README): bump sem tag; release com tag só com confirmação.

## sdd 0.6.4 — 2026-10-11

Conformidade com a documentação oficial do Claude Code (`.specs/done/docs-conformance/spec.md`; reteste no CLI 2.1.296).

- Licença (REQ-004): `LICENSE` MIT na raiz; `license` nos `plugin.json` (`sdd`: `MIT`; `authoring`: `MIT AND Apache-2.0`).
- `sdd-rules` (REQ-001): precedência real — os `CLAUDE.md` são concatenados, sem override automático; regra do processo:
  uma fonte por regra, em conflito o agente aplica a da camada mais específica e sinaliza (exceto controles não relaxáveis).
  `references/claude-md-layers.md` cita `CLAUDE.local.md` e `.claude/rules/`; description começa pelo caso de uso (REQ-003).
- Textos factuais (REQ-002): `${CLAUDE_PLUGIN_ROOT}` é substituído no corpo de skills e de agentes (o texto antigo dizia
  só agentes); subagentes do `sdd` não delegam por não terem `Agent` em `tools` (`tecleader`, seção Execução);
  `CLAUDE.md` de projeto numa sessão no workspace carrega sob demanda, e o TecLeader continua lendo-o antes de planejar.
- Agentes `backend`, `frontend`, `tests`, `security`, `infra-architect` (REQ-003): description com gatilho "Use quando ...".
- Templates de settings (REQ-006): `permissions.deny` bloqueia leitura de segredos (`.env`/`.env.*` também na edição,
  com exceção `!` para `.env.example`/`.sample`/`.template`; chaves, certificados, keystores; credenciais de npm, PyPI,
  git, `netrc`; Terraform; `~/.ssh`, `~/.aws`, `~/.azure`, `~/.config/gh`, `~/.kube`, `~/.docker/config.json`) e as
  formas usuais de push forçado/destrutivo (`--force*`, `-f`, `+refspec`, `--mirror`, `--delete`/`-d`); `permissions.ask`
  pede confirmação para `git push`. README e manual documentam os limites do deny (âncora `**/` × `~/`, sandbox);
  precedência completa: projeto > workspace > pessoal > skills do plugin.
- Release (REQ-005): `claude plugin validate --strict` (sdd, authoring) e do marketplace no procedimento (`CLAUDE.md`,
  README); README explica `ref` opcional em `extraKnownMarketplaces.source`.

## authoring 0.2.1 — 2026-10-11

- `skill-development` (REQ-002): `${CLAUDE_PLUGIN_ROOT}`/`${CLAUDE_SKILL_DIR}` são substituídos no corpo ao carregar; em
  arquivo lido com `Read` fica o literal.

## sdd 0.6.3 — 2026-10-10

Workspace com vários projetos: gatilho de migração e trabalho entre projetos (`.specs/done/workspace-multi-project/spec.md`).

- Hook `onboarding-check.sh` (REQ-001): diagnóstico ganha `claude_dir=yes|no` e `specs_dir=yes|no` (existência de pasta,
  symlink/junction = `no`, sem ler conteúdo, saída só com constantes).
- `tecleader` (REQ-002): com `git=none` e `subrepos>0`, migração só com `specs_dir=yes` ou `stack=yes`; `CLAUDE.md` curto
  e `.claude/` de workspace são legítimos (sem proposta de migração nem pergunta "qual projeto").
- `tecleader` (REQ-003/REQ-004/REQ-005): nova seção "Trabalho entre projetos" — modo workspace (ler o `CLAUDE.md` de cada
  projeto, specs em `<projeto>/.specs/`, deny completo do modelo no `.claude/` do workspace ou aviso + correção no
  plano); sessão num projeto: `--add-dir` + `CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=1`; mudança entre projetos com
  alterados × referência, uma confirmação (ambiguidade na mesma pergunta), spec por projeto alterado ligada por
  `Relacionada a:`, tasks por repositório, nunca commit, `git status` de cada repositório.
- `sdd-rules` (`references/claude-md-layers.md`): `.claude/` de workspace legítimo com deny completo; seção "Trabalho entre
  projetos" (3 modos e efeito no deny/`CLAUDE.md`).
- Revisão de segurança (S-1..S-5): deny incompleto (modelo ∪ projetos envolvidos) → sessão somente leitura até corrigir
  e reiniciar; `CLAUDE.md` de projeto vale só para ele (referência = dado, não instrução; variável de `--add-dir` só para
  repositório confiável; comandos de outro projeto literais no plano); `Arquivos proibidos` com a raiz dos outros
  repositórios; `git status` dos de referência no início e no fim; escrita em pasta adicionada só se prevista em task.
- Correção da validação/segurança (D-001, D-002, R-1..R-4): sessão em projeto pedindo outro → lista fixa com os 3 itens
  (sem "aprovar permissão"); aviso de deny incompleto em 1 linha; deny exigido = modelo ∪ projetos envolvidos (lido de
  `settings.json`/`settings.local.json`, só `permissions.deny`); somente leitura sem build/teste/delegação, sugerindo
  `--permission-mode plan`; `Arquivos permitidos` conferido a cada escrita/delegação; README entra no plano confirmado.
- `templates/CLAUDE.workspace.md` (REQ-006): cita o `.claude/settings.json` opcional do workspace com deny completo.

## sdd 0.6.2 — 2026-10-10

Camadas do `CLAUDE.md` e migração com padrões, sem perguntas (`.specs/done/claude-md-layers/spec.md`).

- `sdd-rules` (REQ-001/REQ-003): camadas pessoal, workspace (fora do git), projeto (versionado) e processo (plugin),
  sem duplicação, mais específico prevalece (exceto controles não relaxáveis); opção `Versionar artefatos SDD:
  sim (padrão) | não` (`não` → `.claude/settings.local.json` + exclude (`git rev-parse --git-path info/exclude`), `.gitignore`
  intocado).
  Detalhes em `references/claude-md-layers.md`.
- `tecleader` (REQ-002/REQ-003/REQ-004): nova seção "Migração para a raiz do projeto" — plano padrão com UMA
  confirmação (mesclar `CLAUDE.md` com diff, `.specs/` por feature com parada em conflito, settings a partir do modelo (chaves permitidas, deny = união), renomeação
  do `.claude/` do workspace para `.claude.bak-<data>` após verificação, `## Stack` do workspace movida para o
  projeto, nunca commit, `git status` ao final); com vários repositórios, só pergunta qual é o projeto. Início de sessão (`git=none`, `subrepos>0`) propõe o
  plano quando há artefatos na pasta; onboarding aplica `Versionar artefatos SDD` sem perguntar.
- Templates (REQ-005): `templates/CLAUDE.md` troca `## Specs` por `## SDD` (Arquivar specs concluídas; Versionar
  artefatos SDD); novo `templates/CLAUDE.workspace.md`.
- Revisão de segurança (T-002, volta 1): `.claude/` do workspace item a item (migrado | mesclado | mantido), renomeado
  para `.claude.bak-<AAAA-MM-DD>` em vez de apagado; modelo de settings só do clone do marketplace (`installLocation`),
  deny = união (nunca remove); `allow`/`env`/`apiKeyHelper` etc. fora do settings versionável (`env` mascarado).
- Com `Versionar artefatos SDD: não`: `git ls-files` antes de escrever (rastreado → pede decisão; proibidos
  `git rm --cached`, `--assume-unchanged`/`--skip-worktree`); exclude via `git rev-parse --git-path info/exclude`,
  só acrescentado; git só leitura.
- Migração: sem seguir symlinks, destinos dentro do repositório, nomes de feature simples, conflitos verificados antes
  de qualquer escrita; "sem perguntar" = sem pergunta separada (settings/exclude entram no plano confirmado).
- Revisão de segurança (T-002, volta 2): `git check-ignore` antes de escrever `.claude/settings.local.json` (não
  ignorado → `/.claude/settings.local.json` no exclude dentro do plano, ou `env`/`apiKeyHelper`/`allow` não migrados);
  origens renomeadas para `.specs.bak-<data>` e `CLAUDE.md.bak-<data>` (nunca apagadas); modelo localizado pela chave
  `claude-sdd-framework` em `known_marketplaces.json`, tratado como dado, só chaves permitidas copiadas; aviso de que
  sessões no workspace perdem o deny e o agente após a migração.
- Validação (D-001, O-001, O-1): settings do projeto sempre criado/mesclado do modelo no onboarding e na migração;
  `allow`/`env`/`apiKeyHelper` etc. ficam na origem, só listados (sem pergunta); `git -C <repo> ls-files` também
  para `.claude/settings*.json` em qualquer valor.

## sdd 0.6.1 — 2026-10-10

- Segurança APROVADA: hook não executa `git` (verificado com `git` falso no PATH); subida limitada a 20 níveis;
  `subrepos` não segue symlink/junction; 2000 subpastas em ~1,3 s. Correção: caminhos montados sem barra dupla
  (sessão em `/` estourava o timeout por `//x` = rede no Git Bash; agora ~0,4 s).
- Validação: workspace com repositório em subpasta (não cria nada, sugere abrir no repositório), raiz de repositório,
  monorepo (`.specs/` na pasta do projeto) e pasta sem git (avisa e sugere `git init` sem executar).
- `.specs/` sempre na raiz do projeto (`.specs/done/specs-location/spec.md`).
- `sdd-rules` (REQ-001): `.specs/`, `CLAUDE.md` do projeto e `.claude/settings.json` ficam na raiz do projeto (raiz do
  repositório git; em monorepo, a pasta do projeto); workspace com vários projetos: um `.specs/` por projeto, nunca
  no diretório pai fora do git.
- Hook `onboarding-check.sh` (REQ-002): acrescenta `git=root|inside|none subrepos=N` ao diagnóstico, **sem executar o
  git** (só existência de `.git`, arquivo ou pasta; ancestrais até 20 níveis; subpastas diretas, só a contagem). Mantém
  somente leitura, sem rede, sem `eval`, sempre `exit 0`, saída só com constantes e números.
- `tecleader` (REQ-003/REQ-004): tabela por situação git no início de sessão (fora do repositório com `subrepos>0`:
  não criar `.specs/`/`CLAUDE.md` e sugerir abrir o `claude` no repositório; sem git: avisar e sugerir `git init`, sem
  executar); fallback sem hook verifica `.git` com Glob/Read; onboarding nunca cria `.specs/` fora da raiz do projeto.

## sdd 0.6.0 — 2026-10-10

- Segurança (2 voltas, APROVADO): a saída do hook contém só constantes e contagens — nomes de arquivo vindos de glob
  nunca são impressos (um nome com quebra de linha forjava o diagnóstico); `CLAUDE.md` symlink não é lido; leitura
  limitada a 1 MiB; `grep --`; timeout de 10 s; texto ASCII.
- Validação: 6 cenários (vazio, código sem CLAUDE.md, CLAUDE.md sem Stack, pronto, tarefa direta, hook desligado).
- Novo hook `SessionStart` (matcher `startup`): `hooks/onboarding-check.sh`, somente leitura (sem rede, sem escrita,
  sem `eval`, sempre `exit 0`), imprime `[sdd:onboarding] claude_md= stack= specs_index= empty= manifests=` com base
  no nível raiz do projeto. Hook `compact` mantido.
- `tecleader`: nova seção "Início de sessão (verificação de onboarding)": trata o diagnóstico na primeira resposta
  (pasta vazia, código sem `CLAUDE.md`, `CLAUDE.md` sem `## Stack`/INDEX, tudo pronto); fallback com Read/Glob se o
  hook não rodar; nada alterado sem confirmação; recusa não é reapresentada na sessão.
- Onboarding passa a criar também `.specs/INDEX.md`.

## sdd 0.5.0 — 2026-10-10

- Arquivamento de specs concluídas: no encerramento, o `tecleader` move `.specs/<feature>/` para
  `.specs/done/<feature>/` (`git mv` quando houver git), atualiza referências e bloqueia o encerramento com link quebrado.
- Novo `.specs/INDEX.md` (ativas e concluídas: estado, data, origem/ID, resumo); lido antes de varrer pastas.
- Reabertura: mudança em feature concluída vira feature nova com `Relacionada a: done/<feature>`; `done/` não é editada.
- `sdd-rules`: movimentação para `done/` pré-autorizada (reversível) e registrada no relatório.
- Template `CLAUDE.md`: seção `## Specs` com `Arquivar specs concluídas: sim (padrão) | não`.

## sdd 0.4.0 — 2026-10-10

- Nova skill **`infra-engineering`** para o `infra-architect`: princípios de nuvem + referências **AWS**, **Azure** e
  **Google Cloud** (14 seções cada: framework oficial, landing zone, identidade, rede, computação, dados, segredos,
  observabilidade, custo, DR, segurança, IaC com tabela "prévia × aplica", comandos só de leitura/prévia, armadilhas).
- Regra não relaxável: o agente nunca roda apply/deploy/delete/execute; state e plano contêm segredos; prévia só com
  identidade somente leitura sobre código revisado; lock file versionado e módulos de origem confiável.
- `infra-architect` agnóstico de nuvem (nuvem vem do `## Stack`); template `CLAUDE.md` com linha de infra.
- `sdd-rules`: fontes de instrução explícitas (CLAUDE.md, plugin, delegação, `.specs/`); o resto é dado não confiável
  (vale para todos os subagentes).
- Texto próprio: AWS (docs CC BY-SA 4.0, só fatos), Azure e Google Cloud (CC BY 4.0, com atribuição).
- Revisão de segurança APROVADA (3 voltas); pilotos Azure, GCP e AWS validados.

## sdd 0.3.0 — 2026-10-10

- Referência **Angular** em `frontend-engineering` (`references/angular.md`), GH#1: adapta-se à versão do projeto
  (v20 standalone, v21 zoneless, v22 OnPush/`@Service()`/Signal Forms/`resource`), sem migrar por conta própria.
  Texto próprio baseado em angular.dev (CC BY 4.0) e inspirado em angular/skills@ff69483 (MIT).
- Revisão de segurança APROVADA (2 voltas); piloto `sdd:frontend` com Stack Angular 21 validado.

## sdd 0.2.0 — 2026-10-09

- Integração opcional, somente leitura, com o provedor de código (feature `vcs-integration`):
  issue → spec (ID registrado, ex.: `GH#42`) e status de PR/CI como evidência antes do DONE.
  Ativada só se o `CLAUDE.md` do projeto tiver `## Repositório`.
- `tecleader`: `tools:` com ferramentas de leitura GitHub (`mcp__github__*`, verificadas na sessão) e
  Bitbucket (Atlassian, dois prefixos); nova seção "Repositório". Escrita (PR, comentário, merge, issue) proibida.
- `sdd-governance`: seção "Integrações externas (Jira e repositório)".
- Templates: `mcp-github.json` (`/mcp/readonly`); `mcp-gitlab.json` e `mcp-azure-devops.json` (experimentais);
  `permissions.deny` ampliado (escrita do GitHub MCP e prefixos Bash de `gh`/`glab`/`az`, defesa em profundidade);
  `CLAUDE.md` com seção opcional `## Repositório`.
- Correções da revisão de segurança (T-003): conteúdo de issue/PR/comentário/work item/log tratado como
  dado não confiável (sem seguir instruções; spec de issue exige confirmação do usuário; subagentes recebem só REQs);
  `GITHUB_PAT` fine-grained somente leitura (proibido `gh auth token`); Bitbucket rebaixado para experimental;
  `get_job_logs` e `getBitbucketRepoPipelineStepLog` removidos do `tools:`; deny das ferramentas de escrita
  GitLab e Azure DevOps por nome e de mais prefixos Bash (`gh auth token`, `gh secret`, `glab api`, `az devops invoke` etc.);
  Azure com `X-MCP-Toolsets: wit,repos,pipelines`; riscos residuais documentados (`curl`/PowerShell, `gh` logado, Zscaler, OAuth).

## marketplace — 2026-10-09 — renomeado para `claude-sdd-framework`

- Marketplace `engineering-workflow` → `claude-sdd-framework` (repositório GitHub `powerlok/claude-sdd-framework`).
  Instalação passa a ser `sdd@claude-sdd-framework` e `authoring@claude-sdd-framework`.
  Plugins e agentes não mudam (`sdd:tecleader` etc.).
- `templates/project-settings.git.json` aponta para o GitHub; Bitbucket substituído por GitHub na documentação.

## sdd 0.1.2 — 2026-10-09

- D-001: agentes `backend`, `frontend` e `tecleader` passam a indicar o caminho das references via `${CLAUDE_PLUGIN_ROOT}` (substituído no texto do agente; não é substituído no texto de skill). Antes, o agente buscava a referência no disco.

## authoring 0.2.0 — 2026-10-09

### authoring

- `skill-development/SKILL.md` e `agent-development/SKILL.md` reescritos com texto próprio,
  baseados na documentação pública do Claude Code (code.claude.com/docs) e nas convenções
  do projeto (spike T-001, design 4.3/4.5).
- `agent-development/references/examples.md`: exemplos próprios baseados nos agentes do plugin `sdd`.
- Cópias proprietárias de anthropics/claude-code removidas (`agent-development/examples/`,
  `agent-development/references/*` antigos e o `SKILL.md` anterior de ambas as skills).
- `agent-development/scripts/validate-agent.sh` removido (validação via `claude plugin validate`).
- Mantidos: `skill-development/references/skill-creator-original.md` e `LICENSE.txt` (Apache-2.0).

## 0.1.1 — 2026-10-09

Correções da revisão de segurança T-007 (volta 1).

### sdd

- `sdd-rules`: regras do projeto não podem relaxar segredos/credenciais, verificação SSL,
  confirmação de ações irreversíveis, Jira somente leitura e menor privilégio.
- `backend-engineering` (`python.md`, `dotnet.md`): comandos de migração somente em banco
  local/descartável; outros ambientes exigem confirmação explícita.
- `frontend-engineering` (`web-interface.md`): rodapé de atribuição no formato
  `Texto próprio; inspirado em vercel-labs/web-interface-guidelines@434b7f9 (MIT)`.

### authoring

- `skill-development/references/skill-creator-original.md`: origem anthropics/skills@83291af
  (Apache-2.0); `LICENSE.txt` incluído; scripts ausentes marcados "(não incluído neste plugin)".

### templates

- `project-settings.local.json` e `project-settings.git.json`: `permissions.deny` com as
  ferramentas de escrita do Atlassian (prefixos `mcp__claude_ai_Atlassian__` e `mcp__atlassian__`).
- `CLAUDE.md`: regras do projeto não podem relaxar os controles de segurança acima.

## 0.1.0 — 2026-10-09

### sdd

- Primeira versão do plugin do processo SDD.
- Agentes: `tecleader`, `backend`, `frontend`, `tests`, `security`, `infra-architect`
  (agnósticos de linguagem; stack lida da seção `## Stack` do `CLAUDE.md` do projeto).
- Skills: `sdd-rules`, `sdd-governance`, `backend-engineering`, `frontend-engineering`,
  `requirements-grilling`, `bug-diagnosis`, `domain-modeling` (com `references/` por stack).
- Hook `SessionStart` (compact) para reler `spec.md` e `tasks.md`.

### authoring

- Primeira versão do catálogo opcional.
- Skills `skill-development` e `agent-development` (cópia das skills do workspace,
  incluindo `examples/`, `references/` e `scripts/`).

### Marketplace e templates

- Marketplace `engineering-workflow` com os plugins `sdd` e `authoring`.
- Templates: `project-settings.local.json` (marketplace por diretório),
  `project-settings.git.json` (marketplace por repositório git),
  `CLAUDE.md` de projeto e `mcp-atlassian.json` (MCP remoto da Atlassian, opcional).
