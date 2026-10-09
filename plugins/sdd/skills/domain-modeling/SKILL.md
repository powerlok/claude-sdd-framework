---
name: domain-modeling
description: Modelagem de domínio no design técnico (linguagem ubíqua/glossário, entidades, value objects, agregados, invariantes, bounded contexts) e critério de quando registrar uma decisão em ADR, com modelo curto. Usar ao escrever ou revisar `.specs/<feature>/design.md`, ao introduzir termos ou regras de negócio, ou ao tomar decisão arquitetural difícil de reverter.
---

# Domain Modeling

Objetivo: spec, design, código e testes usam os mesmos termos com o mesmo sentido,
e decisões importantes ficam registradas com o motivo.

## Linguagem ubíqua (glossário)

- Manter a seção `## Glossário` em `.specs/<feature>/design.md`.
- Uma linha por termo: `- **Termo**: definição curta no contexto do domínio.`
- Registrar também sinônimos proibidos e termos ambíguos:
  `- **Pedido** (não usar "ordem"): ...`
- Termo novo na conversa, na spec ou no código entra no glossário antes de ser usado.
- Mesmo termo com dois sentidos: separar em dois termos ou em dois contextos.
- Nomes de classes, tabelas, endpoints e testes seguem o glossário. Identificadores
  em inglês; o glossário traz o termo em pt-BR e o identificador quando diferir.
- Testar o termo com casos de borda: "um pedido cancelado ainda é um pedido?".

## Blocos do modelo

| Conceito | Pergunta-chave | Exemplo |
|---|---|---|
| Entidade | Tem identidade que persiste ao longo do tempo? | Pedido, Usuário |
| Value object | É definido só pelos valores, imutável e substituível? | Dinheiro, Endereço |
| Agregado | Que grupo deve ser consistente na mesma transação? | Pedido + Itens |
| Raiz do agregado | Por onde toda alteração do grupo deve passar? | Pedido |
| Invariante | Que regra nunca pode ser violada? | "total = soma dos itens" |
| Evento de domínio | Que fato relevante para o negócio aconteceu? | PedidoConfirmado |

Regras práticas:

- Invariantes ficam dentro do agregado que as garante; não espalhar em controllers/UI.
- Referenciar outros agregados por identificador, não por objeto.
- Agregados pequenos; consistência entre agregados pode ser eventual.
- Value objects validam a si mesmos na criação (estado inválido não existe).
- Cada invariante tem teste.
- CRUD simples não precisa da cerimônia completa: usar só o necessário (KISS/YAGNI).

## Bounded contexts

- Contexto delimitado: fronteira onde um modelo e seu glossário são válidos.
- Sinal de contexto distinto: o mesmo termo muda de significado ou de regras
  (ex.: "Cliente" em Vendas vs em Cobrança).
- Registrar no design: contextos envolvidos, responsabilidade de cada um
  e como se integram (API, eventos, tradução de modelo).
- Integração com sistema externo: usar camada de tradução para não
  contaminar o modelo interno com o modelo externo.

## Seções sugeridas no design.md

- Glossário.
- Modelo: entidades, value objects, agregados e invariantes.
- Contextos e integrações (quando houver mais de um).
- Decisões (links para ADRs).

## Quando registrar ADR

Registrar quando ao menos um for verdadeiro:

- A decisão é difícil ou cara de reverter (dados, contrato público, infraestrutura,
  framework, fronteira de agregados).
- Existe trade-off relevante entre alternativas viáveis.
- Uma alternativa plausível foi descartada e alguém poderia propô-la de novo.
- A decisão contraria um padrão já adotado no projeto.

Não registrar: escolhas triviais, facilmente reversíveis ou já impostas por regra.

Local: `.specs/<feature>/adr/NNNN-titulo-curto.md`, ou a seção "Decisões" do
design.md quando o projeto não usar arquivos separados. ADR aceito não é editado:
uma nova decisão cria novo ADR que o substitui.

## Modelo de ADR

```markdown
# ADR-NNNN: <título curto>

- Status: Proposto | Aceito | Substituído por ADR-NNNN
- Data: AAAA-MM-DD
- Requisitos: REQ-NNN

## Contexto
<problema e forças em jogo, com evidência (arquivo:linha) quando houver>

## Decisão
<o que foi decidido, em uma ou duas frases>

## Alternativas consideradas
- <alternativa>: <por que foi descartada>

## Consequências
- Positivas: ...
- Negativas / riscos: ...
- Rollback: <como reverter, se possível>
```

---

Texto próprio; inspirado em mattpocock/skills@49dd158 (skills `domain-modeling`, `grill-with-docs`) (MIT).
