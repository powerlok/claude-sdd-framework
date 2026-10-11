---
name: requirements-grilling
description: Protocolo de perguntas sobre requisitos que o techlead aplica antes de escrever ou aprovar uma spec. Usar quando a solicitação (do usuário ou de uma issue do Jira) estiver ambígua, incompleta ou sem critério de aceite/validação, e antes de delegar qualquer implementação.
---

# Requirements Grilling

Objetivo: transformar uma solicitação em requisito testável antes da spec.
Ninguém implementa enquanto houver ambiguidade que mude o design.

## Quando aplicar

- Solicitação nova, issue do Jira ou mudança de escopo.
- Falta requisito, critério de aceite ou forma de validação.
- Termos de domínio ambíguos ou usados com mais de um sentido.

Não aplicar a perguntas, leituras e consultas sem alteração.

## Antes de perguntar

1. Ler o que já existe: spec, design, código, testes, issue.
2. Não perguntar o que o código ou a documentação já respondem;
   citar `arquivo:linha` como evidência.
3. Listar as dúvidas abertas e classificar cada uma:
   - **Bloqueante**: muda design, contrato, dados ou segurança.
   - **Relevante**: muda critério de aceite ou validação.
   - **Detalhe**: pode virar premissa registrada.

## Como perguntar

- Uma pergunta por vez; ou um lote curto (até 3) de perguntas independentes.
- Ordem: bloqueantes, depois relevantes, depois detalhes.
- Cada pergunta traz:
  - o contexto em uma linha (por que importa);
  - as opções concretas (quando houver);
  - a **resposta recomendada** com justificativa curta.
- Perguntas fechadas e específicas. Evitar "o que você acha?".
- Se a resposta abrir nova ramificação, seguir nela até resolver
  antes de voltar ao restante da lista.
- Detalhes de baixo impacto: propor premissa e seguir,
  registrando-a como "Premissa" na spec (o usuário pode corrigir depois).

Formato sugerido:

```text
Pergunta 2/5 (bloqueante): <pergunta>
Contexto: <por que muda o design>
Opções: A) ... B) ...
Recomendação: A, porque <motivo>.
```

## Pontos a cobrir

- Problema e objetivo (quem usa, qual resultado esperado).
- Escopo e fora de escopo.
- Entradas, saídas, contratos e erros esperados.
- Regras de negócio e invariantes (termos vão ao glossário, skill `domain-modeling`).
- Dados: origem, persistência, sensibilidade.
- Segurança: autenticação, autorização, entrada externa.
- Requisitos não funcionais relevantes (desempenho, disponibilidade).
- Critério de aceite verificável para cada requisito.
- Forma de validação (teste automatizado, E2E, demonstração).

## Critério de parada

Encerrar o protocolo quando, para cada requisito, existir:

- requisito identificado (`REQ-NNN`);
- critério de aceite verificável;
- estratégia de validação definida;
- nenhuma dúvida bloqueante aberta.

Se o usuário não puder responder uma dúvida bloqueante:
registrar como pendência e não iniciar a implementação daquele requisito.

## Registro

- Decisões e respostas vão para `.specs/<feature>/spec.md`
  (requisitos, critérios de aceite, validação, premissas, decisões).
- Decisões difíceis de reverter: avaliar ADR (skill `domain-modeling`).
- Não deixar decisões só na conversa: a spec é a fonte de verdade.
- Issue do Jira: registrar a chave na spec para rastreio.

## Anti-padrões

- Despejar uma lista longa de perguntas de uma vez.
- Perguntar sem propor recomendação.
- Perguntar o que já está no código.
- Começar a spec ou a implementação com dúvida bloqueante aberta.

---

Texto próprio; inspirado em mattpocock/skills@49dd158 (skills `grilling`, `grill-me`) (MIT).
