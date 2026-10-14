# Spec: comando /sdd:start para iniciar o fluxo com o TechLead

Relacionada a: done/start-banner, done/onboarding-check. Pedido do usuário (2026-10-14): "e se colocarmos um comando para que o
usuário inicie ele, ao invés de ser automático? Assim ele pode startar o fluxo e as perguntas iniciais para concluir os passos
iniciais."

## Contexto

O Claude Code não faz primeiro turno automático para agente de plugin (`initialPrompt` é ignorado, testado em 0.9.5). Uma skill chamada
pelo usuário (`/sdd:start`) vira a mensagem do usuário e dispara a resposta do TechLead, então o usuário inicia o fluxo com um comando.

## Requisitos

- **REQ-001**: nova skill `start` (`/sdd:start`, sem argumento), `disable-model-invocation: true`, `allowed-tools: Read, Glob, Grep` (só
  leitura; toda escrita continua sendo do TechLead, com confirmação). Sem `Bash`, `Edit` nem `Write` na skill.
- **REQ-002**: o corpo da skill manda o agente: (a) se a sessão não é do `sdd:techlead`, avisar em poucas linhas como ativá-lo
  (`"agent": "sdd:techlead"` no `.claude/settings.json` ou `claude --agent sdd:techlead`) e parar; (b) aplicar a seção "Início de sessão
  (verificação de onboarding)" do agente como se fosse a primeira resposta, mesmo que a sessão já tenha começado; (c) conduzir os passos
  iniciais pendentes **só com as perguntas já definidas** nas seções "Início de sessão" e "Onboarding de Projeto" (stack se pasta vazia,
  idioma de commit/PR, publicação, versionar artefatos SDD, salinha), pedindo confirmação antes de criar ou alterar qualquer coisa; (d) ao
  terminar, perguntar qual é o primeiro pedido; com tudo pronto, 1 linha de status e a mesma pergunta.
- **REQ-003**: o aviso de início (`start-banner.sh`) passa a apontar para `/sdd:start` ("digite /sdd:start"; escrever qualquer mensagem
  continua funcionando).
- **REQ-004**: docs (passo 3 dos primeiros passos, README, manual, troubleshooting, tabela de skills, contagem de skills), CHANGELOG, `sdd`
  0.9.6.
- **REQ-005**: testes: skill existe com os campos acima e sem ferramentas de escrita; o banner cita `/sdd:start`; no CLI real, `/sdd:start`
  num projeto sem `CLAUDE.md` leva à resposta "Sou o TechLead" com a pergunta de onboarding.

## Segurança

Skill só lê; não muda permissões, hooks de escrita nem formato de eventos. Dados do projeto continuam sendo dados, não instruções.
Revisão independente dispensada (nenhum acesso novo).

## Critérios de aceite

Testes verdes; `validate --strict`; `claude -p "/sdd:start"` no sandbox responde como TechLead e pergunta do onboarding.
