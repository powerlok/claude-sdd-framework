# Spec: documentação simples e objetiva; instalação clara por tipo e verificação do ambiente (`sdd` 0.12.0)

Pedido do usuário (2026-10-15): "refazer as documentações do projeto, deixá-las mais simples e objetivas. O processo de instalação está confuso; mostrar da melhor forma como instalar o plugin e, se preciso, separar de
forma clara e visual os tipos de instalação. Quando o projeto for novo, com ou sem código existente, validar se existe CLI do claude instalado e como fazer cada passo até instalar o plugin. Valide cada passo e faça
testes para validar se está claro e correto."
Relacionada a: done/docs-manual, done/start-command, done/start-banner.

## Problemas encontrados (2026-10-15)

- A instalação está espalhada: README (início rápido de 80 linhas com 5 `<details>`), `primeiros-passos.md` (428 linhas; passos A/B/C misturados com Caminho A/B) e o manual HTML; nenhum deles diz como
  instalar o CLI do Claude nem confere se ele existe.
- Textos desatualizados dentro do mesmo guia (`plugin list` mostra `0.9.4` enquanto a versão atual é outra).
- O README tem 472 linhas (instalação, proteções, salinha, MCPs, Jira, VCS, desenvolvimento) e o leitor novo não acha o caminho.

## Requisitos

- **REQ-001**: `docs/instalacao.md` é a página única da instalação. Começa por "Em que situação você está?" (tabela + fluxograma) com tipos claramente separados e numerados: **A** máquina sem Claude Code,
  **B** projeto novo (pasta vazia), **C** projeto com código existente, **D** projeto que já usa o sdd (clonar e abrir), **E** atualizar versão, **F** clone local do framework (contribuidor). Cada tipo tem passos
  numerados, o que se vê e como conferir, em ordem até o plugin instalado e o `/sdd:start`.
- **REQ-002**: a página cobre a instalação do CLI por SO (Windows, macOS, Linux/WSL), conferência (`claude --version`, versão mínima), PATH, login, Git (e Git Bash no Windows), e a rede para o GitHub; comandos
  conferidos na documentação oficial e marcados com a data.
- **REQ-003**: scripts de verificação somente leitura `scripts/check-env.sh` (macOS/Linux/Git Bash) e `scripts/check-env.ps1` (Windows/PowerShell): checam CLI (presença e versão mínima), git, bash no Windows,
  marketplace, e, na pasta atual, o tipo de projeto (novo vazio, com código, já com sdd), `.claude/settings.json`, plugin instalado/habilitado e `CLAUDE.md`/`## Stack`; imprimem `[OK]`, `[FALTA]` ou `[AVISO]`, o
  comando exato para corrigir e o PRÓXIMO PASSO. Sem rede por padrão (`--net` testa o GitHub), sem escrever, sem `eval`; exit 0 se tudo pronto, 1 se faltar algo.
- **REQ-004**: README curto (visão geral, instalação em 4 linhas apontando para `instalacao.md`, time, fluxo, links). O conteúdo de referência (proteções, camadas, salinha, contexto, MCPs, Jira, repositórios,
  limitações, desenvolvimento) vai para `docs/referencia.md`, condensado e sem perder fatos. `primeiros-passos.md` passa a cobrir só o que vem DEPOIS da instalação (primeira conversa, primeiro pedido, equipe).
  O manual HTML e `arquitetura.md` são conferidos e corrigidos onde divergirem.
- **REQ-005**: testes: (a) links e âncoras internos de README e docs resolvem; (b) versões coerentes (`plugin.json`, badge, `ref` do template, comandos `#vX.Y.Z` das docs); (c) todo `claude plugin ...` citado
  existe no `--help` do CLI real (quando disponível); (d) `check-env.sh` em sandboxes com `claude`/`git` falsos cobre CLI ausente, versão antiga, OK, pasta vazia, código existente, já com sdd, workspace
  (rodado também no CI nos 3 sistemas); (e) `check-env.ps1` no Windows; (f) o fluxo real (marketplace add → install → list) executado num `CLAUDE_CONFIG_DIR` temporário, sem tocar na configuração do usuário.
- **REQ-006**: CHANGELOG, `sdd` 0.12.0 (ainda sem tag), CLAUDE.md do framework.
