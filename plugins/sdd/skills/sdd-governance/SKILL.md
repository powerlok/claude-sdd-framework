---
name: sdd-governance
description: Governança do processo SDD (papel do tecleader, agentes e responsabilidades, especificações, rastreabilidade REQ→teste, estados, regra de correção, escalonamento, evidências, gestão de contexto, compactação e integração somente leitura com o Jira). Usar no tecleader no início da sessão e após compact, ou ao decidir delegação, estados ou encerramento de tasks.
---

# Governança SDD

Um projeto pode ter seu próprio `CLAUDE.md`, regras, arquitetura e agentes.
Esta governança se aplica a todo projeto que usa o plugin `sdd`, salvo quando
substituída por regra mais específica do `CLAUDE.md` do projeto.
Regras de engenharia (escopo, qualidade, segurança, README, execução final):
skill `sdd:sdd-rules`.

---

## Regra Principal: toda tarefa passa primeiro pelo TecLeader

Antes de qualquer implementação, alteração arquitetural, correção ou criação de
código, a solicitação deve ser analisada pelo `tecleader` (`sdd:tecleader`).

O TecLeader é responsável por:

- entender a solicitação
- identificar o projeto envolvido
- localizar specs e regras aplicáveis
- avaliar impacto técnico
- dividir o trabalho em tasks
- delegar para agentes especializados
- coordenar validações
- consolidar resultados
- encerrar o ciclo SDD

Exceções: perguntas, leitura de arquivos, esclarecimentos e consultas sem alteração.

---

## Agentes

Os agentes vêm do plugin e são chamados com o prefixo `sdd:`:

- `sdd:tecleader` (agente da sessão principal)
- `sdd:backend`
- `sdd:frontend`
- `sdd:security`
- `sdd:tests`
- `sdd:infra-architect`

A composição do time pode variar entre projetos. Nem todo projeto precisa de
todos os agentes. O TecLeader escolhe apenas os necessários para cada tarefa.

---

## Desenvolvimento Orientado por Especificação (SDD)

```text
Requirement → Specification → Technical Design (quando obrigatório) → Task
→ Test Design → Implementation → Security Review (quando aplicável)
→ Validation → Correction → Validation → Done
```

Implementação sem especificação é proibida.

### Especificações

Sempre que aplicável utilizar `.specs/<feature>/spec.md` e `tasks.md`.

Antes da implementação deve existir:

- requisito
- critério de aceite
- forma de validação

Caso alguma dessas informações esteja ausente: atualizar a especificação,
solicitar complementação e não iniciar implementação.

---

## Requisitos e Testes

Todo requisito deve possuir: `REQ → Task → Teste → Validação`.

Exemplo: `REQ-001` deve ser rastreável até um teste cujo nome ou identificação
referencie o requisito (ex.: arquivo ou caso de teste `req001`, conforme a
convenção da stack do projeto).

---

## Encerramento de Tasks

Uma task NÃO é concluída quando o código foi implementado. Só é concluída quando:

- requisitos implementados
- critérios de aceite atendidos
- testes executados
- validação aprovada
- evidências registradas

Somente o TecLeader encerra tasks.

---

## Controle de Estado

```text
TODO
IN_PROGRESS
IMPLEMENTED
SECURITY_REVIEW (quando aplicável)
VALIDATING
FAILED_VALIDATION
FIXING
VALIDATING_AGAIN
DONE
```

## Regra de Correção

Quando uma validação falhar:

```text
VALIDATING → FAILED_VALIDATION → FIXING → VALIDATING_AGAIN → VALIDATING
```

O ciclo se repete até aprovação.

## Escalonamento

Se a mesma falha ocorrer repetidamente sem progresso significativo
(**3 tentativas**), o agente responsável informa o TecLeader.

O TecLeader deve:

- registrar o bloqueio
- resumir o motivo
- escalar ao usuário

---

## Responsabilidade dos Agentes

### Implementadores (`backend`, `frontend`)

Responsáveis por: design técnico (quando obrigatório), análise técnica,
implementação, testes da própria feature (unitários, integração local,
componentes) e correções. Não podem encerrar tasks.

### Revisão de Segurança (`security`)

Responsáveis por: revisar segurança (AppSec, APIs, dependências, segredos,
infraestrutura) e reportar riscos com severidade e evidência.
Não implementam. Não corrigem. Não podem encerrar tasks.

### Validadores (`tests`, e outros validadores do projeto, ex.: `aws-test`)

Responsáveis por: validar requisitos e critérios de aceite, reportar defeitos
e gerar evidências. Não podem corrigir produção. Não podem encerrar tasks.

### Arquiteturais (`infra-architect`)

Responsáveis por: decisões arquiteturais, análise de trade-offs, critérios
verificáveis e estratégias de rollback. Não implementam mudanças.

---

## Evidências Obrigatórias

Toda entrega deve conter, quando aplicável:

- requisitos atendidos
- arquivos alterados
- testes executados
- comandos executados
- resultado da validação
- riscos conhecidos

Sem evidência não existe conclusão.

---

## Segurança

Nunca: expor credenciais, tokens ou segredos; registrar chaves privadas;
armazenar dados sensíveis em memória de agentes.

Aplicar sempre: menor privilégio, segregação de responsabilidades e
validação explícita de alterações críticas.

---

## Gestão de Contexto

Ao compartilhar contexto entre agentes:

- Preferir: caminhos de arquivos, símbolos, requisitos, resultados de testes.
- Evitar: copiar arquivos inteiros, replicar grandes blocos de código,
  enviar contexto irrelevante.

## Compactação de Conversa

Ao resumir uma sessão preservar: objetivo da tarefa, requisitos envolvidos,
decisões tomadas, arquivos alterados, testes executados, validações realizadas
e pendências.

Após um compact: reler `spec.md` e `tasks.md` e recarregar as skills
`sdd:sdd-rules` e `sdd:sdd-governance` (o hook do plugin lembra disso).

---

## Integração com Jira (MCP)

Opcional e somente leitura. Sem Jira, o fluxo SDD funciona normalmente:
o requisito é informado na conversa ou escrito direto em `.specs/<feature>/spec.md`.

### Caminhos de acesso

| Caminho | Quando usar | Ferramentas |
|---|---|---|
| Conector claude.ai **Atlassian** (padrão) | dev com login claude.ai; OAuth, sem token local; a conexão sai do lado da Anthropic (preferir com Zscaler ativo) | `mcp__claude_ai_Atlassian__*` |
| `.mcp.json` com o MCP remoto oficial da Atlassian (opcional, desligado por padrão) | dev sem login claude.ai (API key, Bedrock, Vertex); OAuth por usuário, sem token em arquivo | `mcp__atlassian__*` |

Configuração do conector (cada pessoa, uma vez):

1. claude.ai → Settings → Connectors → Atlassian → Connect
2. Login na Atlassian e aprovar o site `*.atlassian.net`
3. Nova sessão do Claude Code → `/mcp` → Atlassian `connected`

Em caso de erro, registrar a mensagem exata e acionar a TI.
Nunca desabilitar verificação de SSL.

### Acesso

- Somente o `tecleader` acessa o Jira, apenas com as ferramentas de leitura
  (nos dois conjuntos de nomes):
  `atlassianUserInfo`, `getAccessibleAtlassianResources`,
  `getJiraIssue`, `searchJiraIssuesUsingJql`.
- Leitura: issue por chave e busca JQL.
- Os demais agentes não acessam o Jira; recebem apenas a spec.
- Escrever no Jira (comentar, transicionar, editar) não está liberado.
  Exige decisão explícita do usuário e inclusão da ferramenta.

### Fluxo Jira → SDD

1. Usuário informa a chave (ex.: `PROJ-123`) ou um JQL
2. TecLeader lê a issue (descrição, critérios de aceite, subtasks)
3. Converte para `.specs/<feature>/spec.md` (REQs + critérios de aceite)
   e `tasks.md`, registrando a chave da issue para rastreio
4. Issue sem critério de aceite: solicitar complementação,
   não iniciar implementação
5. Segue o fluxo SDD normal até DONE

A spec no repositório é a fonte de verdade durante a execução;
o Jira é a origem do requisito.
