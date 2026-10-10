# Spec: referência Angular para `frontend-engineering`

Origem: GitHub powerlok/claude-sdd-framework — **GH#1** ("Adicionar referência Angular ao frontend-engineering").
Confirmação do usuário (2026-10-10): "adicione skills de angular também, busque uma completa e bem funcional,
escreva com as próprias palavras".

## Requisitos

- **REQ-001** (GH#1 CA1): `plugins/sdd/skills/frontend-engineering/references/angular.md` com a mesma estrutura de
  seções de `react.md` (estrutura, estado, performance, testes, build, comandos de exemplo), cobrindo o Angular moderno.
- **REQ-002** (GH#1 CA2): a tabela "Como escolher a referência" do `SKILL.md` lista Angular como disponível.
- **REQ-003** (GH#1 CA3): `claude plugin validate ./plugins/sdd` passa.
- **REQ-004** (GH#1 Validação): piloto — `sdd:frontend` com `Stack: Angular` lê `references/angular.md` (evidência no log).
- **REQ-005** (pedido do usuário): conteúdo baseado em pesquisa das melhores fontes (documentação oficial do Angular e
  skills/guias públicos bem avaliados), **escrito com texto próprio**, citando a inspiração com repo/URL e licença;
  nada de cópia; sem afirmar versões ou APIs não confirmadas na fonte oficial.

## Critérios de aceite

- REQ-001: seções equivalentes às de `react.md`; ≤ ~220 linhas; sem links para fora do plugin em tempo de uso.
- REQ-002: tabela atualizada; nenhuma menção a "Angular ainda não disponível" no plugin.
- REQ-003: validate OK.
- REQ-004: tool_use Read de `.../references/angular.md` no log do piloto.
- REQ-005: rodapé com fontes e licenças; revisão do `security` sem cópia/injeção.

## Validação

`claude plugin validate`; grep de "não disponível"; piloto `sdd:frontend` com `--plugin-dir`; revisão do `security`.

## Fora de escopo

Projeto Angular real completo; ferramentas MCP do Angular CLI.
