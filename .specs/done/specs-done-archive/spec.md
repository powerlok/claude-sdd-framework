# Spec: arquivar specs concluídas em `.specs/done/`

Pedido do usuário (2026-10-10): ao finalizar uma spec, mover os arquivos para `.specs/done/`.
Decisões do usuário: (1) movimentação **pré-autorizada**; (2) migrar as features já concluídas deste repositório.

## Requisitos

- **REQ-001**: No encerramento de uma feature (todas as tasks DONE + relatório de validação), o `sdd:tecleader`
  move `.specs/<feature>/` para `.specs/done/<feature>/` (com `git mv` quando o projeto usar git) como último passo.
- **REQ-002**: Na mesma mudança, o TecLeader procura referências a `.specs/<feature>/` no projeto e atualiza os
  links; link quebrado impede o encerramento.
- **REQ-003**: `.specs/INDEX.md` lista features ativas e concluídas (nome, estado, data, origem/ID ex.: `GH#1`,
  resumo de 1 linha); o TecLeader o atualiza ao criar e ao arquivar features e o lê antes de varrer pastas.
- **REQ-004**: Reabertura: mudança/bug em feature concluída vira feature nova com `Relacionada a: done/<feature>`;
  `done/` não é editada (exceto correção de link).
- **REQ-005**: A movimentação para `done/` é pré-autorizada no `sdd-rules` (exceção explícita à regra
  "movimentação de arquivos exige confirmação") e registrada no relatório final; o projeto pode desligar no
  `CLAUDE.md` (template com a opção).
- **REQ-006**: Migração deste repositório: `sdd-plugin`, `docs-manual`, `vcs-integration`, `angular-reference`,
  `infra-engineering` (e esta feature, ao final) para `.specs/done/`; `.specs/INDEX.md` criado; links atualizados.

## Critérios de aceite

- REQ-001..005: textos no `tecleader.md`, `sdd-rules`, `sdd-governance` e template; `claude plugin validate` OK.
- REQ-002/006: verificador de links relativos em todo o repositório = 0 quebrados após a migração.
- Piloto: em projeto de teste com feature com todas as tasks DONE, o TecLeader arquiva, atualiza INDEX e links.

## Validação

`claude plugin validate`; verificador de links; piloto do TecLeader; `git status` mostrando renames.

## Fora de escopo

Arquivar features não concluídas; apagar specs.
