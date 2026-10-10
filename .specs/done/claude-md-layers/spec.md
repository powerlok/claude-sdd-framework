# Spec: camadas do CLAUDE.md e migração com padrões (sem perguntas)

Pedido do usuário (2026-10-10): transformar em regra as decisões de onde fica cada coisa e como migrar, para o TecLeader
não precisar perguntar (caso real: `testeclaude/` com `CLAUDE.md`, `.specs/` e `.claude/` fora do repositório `ict_petro/`).

## Requisitos

- **REQ-001 — Camadas** (`sdd-rules`): pessoal `~/.claude/CLAUDE.md` (preferências); workspace (diretório pai, fora do git:
  só o que vale para todos os repositórios abaixo — lista de projetos, convenções comuns); **projeto** (raiz do repositório,
  versionado: `## Stack`, comandos, arquitetura, `## Repositório`, regras do projeto); processo = skills do plugin (nunca
  copiado em CLAUDE.md). O que o time precisa vai no do projeto; nada duplicado entre camadas; o mais específico prevalece
  (exceto controles não relaxáveis).
- **REQ-002 — Migração com padrões** (`tecleader`): ao detectar artefatos SDD fora da raiz do projeto (sessão em workspace
  com `git=none subrepos>0`, ou `CLAUDE.md`/`.specs/`/`.claude/` no diretório pai), propor de uma vez o plano padrão e pedir
  **uma única confirmação**:
  1. conteúdo específico do projeto do `CLAUDE.md` → `<repo>/CLAUDE.md` (**mesclar, nunca sobrescrever**; mostrar o diff);
     conteúdo geral fica num `CLAUDE.md` curto de workspace (ou nenhum, se houver um só projeto; o original vira
     `CLAUDE.md.bak-<AAAA-MM-DD>`, nunca apagado);
  2. `.specs/` → `<repo>/.specs/` (se já existir, mesclar por feature sem sobrescrever; conflito de nome → parar e reportar;
     origem renomeada para `.specs.bak-<AAAA-MM-DD>` após verificar);
  3. `<repo>/.claude/settings.json` a partir do modelo (só plugin/marketplace, `"agent": "sdd:tecleader"`, `permissions.deny`;
     deny = união modelo ∪ workspace ∪ destino); `allow`/`env`/`apiKeyHelper` só em `settings.local.json`, e só se ignorado
     pelo git (`git check-ignore`; senão, entrada no exclude dentro do plano);
  4. `.claude/` do workspace: item a item com destino; após verificar, renomear para `.claude.bak-<AAAA-MM-DD>` (nunca
     apagar; itens sem destino ficam e são reportados; avisar que sessões no workspace perdem o deny e o agente);
  5. **nunca** fazer commit; mostrar `git status` ao final para o usuário revisar.
  Com vários repositórios abaixo, perguntar só **qual** é o projeto (única pergunta permitida além da confirmação).
- **REQ-003 — Versionamento dos artefatos** (`CLAUDE.md` do projeto, seção `## SDD`): `Versionar artefatos SDD: sim (padrão) | não`.
  `sim` → `.claude/settings.json`, `CLAUDE.md` e `.specs/` versionados. `não` (ex.: repositório de cliente que não aceita) →
  `.claude/settings.local.json` + entradas no exclude (`git rev-parse --git-path info/exclude`) (`/CLAUDE.md`, `/.specs/`, `/.claude/`), sem tocar no
  `.gitignore` do projeto; arquivo já rastreado → pedir decisão (nunca `git rm --cached`/`skip-worktree`). O TecLeader **não pergunta**: usa o padrão e, se o marketplace for privado, apenas informa em 1 linha
  que colegas precisam de acesso ao repositório do framework.
- **REQ-004 — Stack no lugar certo**: se `## Stack`/comandos estiverem no `CLAUDE.md` do workspace, propor movê-los para o do
  projeto (dentro do mesmo plano/confirmação da migração).
- **REQ-005 — Modelos/docs**: `templates/CLAUDE.workspace.md` (curto); `templates/CLAUDE.md` com `## SDD` (Arquivar specs
  concluídas; Versionar artefatos SDD); README/manual: seção "Camadas do CLAUDE.md".

## Critérios de aceite

- Cenário do caso real: TecLeader propõe o plano completo e faz **no máximo uma pergunta** (confirmação), sem perguntar
  "onde fica o .specs" nem "mover o CLAUDE.md?" separadamente.
- Com confirmação: arquivos no lugar, `CLAUDE.md` mesclado, settings a partir do modelo,
  origens renomeadas para `.bak-<data>` (nada apagado), sem commit.
- `Versionar artefatos SDD: não`: settings.local + exclude; `.gitignore` intocado; `git status` limpo para esses artefatos.

## Validação

Pilotos do TecLeader (proposta e execução) em projetos de teste; `claude plugin validate`; revisão do `security`
(movimentação/renomeação de arquivos, settings e escrita no exclude). Alterado após T-002 voltas 1-2 (M-1..M-4, N-1..N-5).
