# Changelog

Formato por versão (semver). Regras de versionamento: `.specs/done/sdd-plugin/design.md`, seção 6.

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
