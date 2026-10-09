# Spec: Plugin SDD compartilhável (agentes e skills agnósticos)

Projeto: `engineering-workflow` (marketplace + plugin do Claude Code).
Destino futuro: repositório no Bitbucket (a definir). Por enquanto, somente local.

## Contexto

Os agentes (`tecleader`, `backend`, `frontend`, `tests`, `security`, `infra-architect`),
as regras e as skills vivem hoje em `workshop/.claude/`.
Objetivo: compartilhar o mesmo processo com outros devs e projetos,
sem depender de linguagem específica.

Achados que motivam a feature (auditoria de 2026-10-09):

- `backend` acoplado a Python/FastAPI e `frontend` a React/Vite
  (`.claude/agents/backend.agent.md:4-5,23-30,138`; `frontend.agent.md:5,23-28,76`).
- Nenhum agente referencia skills (sem `skills:` no frontmatter).
- `react-performance`: links para `.agents/` inexistente e referência a outro projeto
  (`.claude/skills/react-performance/SKILL.md:8,19-25`).
- `web-design-guidelines`: baixa regras de URL mutável a cada uso
  (`.claude/skills/web-design-guidelines/SKILL.md:26`).
- `skills-lock.json` desalinhado com as pastas instaladas.

## Requisitos

- **REQ-001**: O processo (agentes, skills, hook) é distribuído como plugin do Claude Code
  por um marketplace instalável a partir de diretório local e, depois, de repositório git (Bitbucket).
  Plano B (se a verificação T-000 inviabilizar): kit com script de instalação.
- **REQ-002**: As regras globais do workspace (SDD, segurança, README, execução final etc.)
  chegam a qualquer projeto que use o plugin.
- **REQ-003**: O `tecleader` continua sendo o agente da sessão principal nos projetos que usam o plugin.
- **REQ-004**: Os agentes `backend` e `frontend` não dependem de linguagem/framework;
  a stack vem do `CLAUDE.md` do projeto e é informada pelo `tecleader` na delegação.
- **REQ-005**: Skills `backend-engineering` e `frontend-engineering` com princípios gerais
  e `references/` por stack (1ª versão: backend .NET e Python; frontend React; Angular em seguida),
  pré-carregadas nos agentes correspondentes.
- **REQ-006**: As skills de frontend atuais são corrigidas e consolidadas
  (sem links quebrados, sem referência a outro projeto, sem download remoto em tempo de uso).
- **REQ-007**: Métodos incorporados aos agentes, com origem e licença registradas:
  protocolo de perguntas (grilling) no `tecleader`; diagnóstico de bugs (fases 1-5) em
  `backend`/`frontend` e reprodução determinística no `tests`; glossário e critério de ADR no design.
- **REQ-008**: Skills que não são do processo ficam num catálogo, fora do carregamento padrão.
- **REQ-009**: README do projeto com instalação (local e Bitbucket), atualização e uso.

## Critérios de aceite

- REQ-001: o plugin instala a partir do marketplace local com `/plugin`; agentes e skills aparecem.
- REQ-002: em um projeto novo, o `tecleader` aplica as regras (ex.: recusa implementar sem spec).
- REQ-003: ao abrir um projeto com a configuração modelo, a sessão principal é o `tecleader`.
- REQ-004: `backend.agent.md` e `frontend.agent.md` sem nomes de linguagem/framework;
  a mesma tarefa funciona em projeto Python e em projeto .NET.
- REQ-005: na delegação, o agente lê a referência da stack declarada (evidência no log/relato).
- REQ-006: nenhum link quebrado; nenhuma URL buscada em tempo de uso; sem citação a projeto externo.
- REQ-007: cada trecho incorporado cita origem e licença compatível.
- REQ-008: skills do catálogo não aparecem no projeto sem instalação explícita.
- REQ-009: README segue a regra "README" de `.claude/rules/global.md`.

## Validação

- T-000: verificação na documentação oficial (capacidades de plugin).
- Instalação do plugin a partir do marketplace local em um projeto de teste.
- Piloto: mesma tarefa simples (endpoint CRUD com teste) em projeto Python e em projeto .NET.
- Regressão: `app-workshop` continua funcionando com os agentes do plugin
  (`npm test`, `npm run build`, `npm run e2e`).
- Agente `tests` valida; `security` revisa (hooks, scripts, conteúdo de terceiros);
  somente o `tecleader` encerra.

## Fora de escopo (por enquanto)

- Publicar no Bitbucket (push exige confirmação e o repositório ainda será definido).
- Remover arquivos de `workshop/.claude/` (exige confirmação explícita; decidido no design).
- Conector do Jira (continua opcional, por pessoa).
