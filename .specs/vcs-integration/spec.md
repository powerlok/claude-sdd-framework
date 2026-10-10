# Spec: Integração opcional com provedores de código (GitHub, Bitbucket e outros)

Pedido do usuário (2026-10-09): "além do jira é bom colocar o github também?" → "precisa, tem mais opções mesmo".
Interpretação: suporte a vários provedores, escolhido por projeto, opcional e seguro por padrão.

## Requisitos

- **REQ-001**: O `sdd:tecleader` pode ler, de forma opcional, dados do provedor de código do projeto:
  issue/work item como origem de requisito (com o ID registrado na spec) e status de PR e CI como evidência.
- **REQ-002**: Provedores suportados na 1ª versão: GitHub e Bitbucket Cloud (prioritários); GitLab e
  Azure DevOps se a pesquisa (T-000) mostrar caminho oficial viável.
- **REQ-003**: O provedor é declarado no `CLAUDE.md` do projeto (nova seção `## Repositório`); o TecLeader
  usa apenas o provedor declarado.
- **REQ-004**: Somente leitura por padrão, com bloqueio técnico de escrita (permissions.deny / modo read-only),
  não só instrução em texto. Ações de escrita (abrir PR, comentar) só se habilitadas e com confirmação explícita.
- **REQ-005**: Sem segredo em arquivo versionado (OAuth ou credencial local do CLI).
- **REQ-006**: Documentação: README, manual (seções e exemplos) e templates atualizados.

## Critérios de aceite

- REQ-001: em projeto de teste, o TecLeader lê uma issue real e gera spec com o ID; consulta status de PR/CI.
- REQ-002: cada provedor suportado tem template e instrução verificados (pelo menos GitHub testado de ponta a ponta).
- REQ-003: sem `## Repositório`, o TecLeader não usa nenhum provedor.
- REQ-004: tentativa de escrita (ex.: merge, comentar, `gh api` com POST) é negada pelo settings, com evidência.
- REQ-005: grep de segredos vazio; revisão do `security` APROVADA.
- REQ-006: links e comandos dos docs verificados.

## Validação

T-000 pesquisa (doc oficial) → design aprovado pelo usuário → implementação → security → tests (ponta a ponta no GitHub; demais conforme acesso disponível).

## Fora de escopo

- Escrita habilitada por padrão; merge; administração de repositório.
