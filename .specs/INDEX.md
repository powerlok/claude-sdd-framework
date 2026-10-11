# Índice de specs

Mantido pelo `sdd:tecleader`: atualizado ao criar e ao arquivar features.
Ativas ficam em `.specs/<feature>/`; concluídas em `.specs/done/<feature>/` (não editar; mudança vira feature nova
com `Relacionada a: done/<feature>`).

## Ativas

| Feature | Estado | Início | Origem | Resumo |
|---|---|---|---|---|
| — | — | — | — | nenhuma |

## Concluídas

| Feature | Concluída | Origem | Resumo |
|---|---|---|---|
| [sdd-plugin](done/sdd-plugin/spec.md) | 2026-10-09 | pedido do usuário | Plugin e marketplace com agentes e skills agnósticos de linguagem (`sdd` 0.1.x, `authoring`) |
| [docs-manual](done/docs-manual/spec.md) | 2026-10-09 | pedido do usuário | Manual de uso em HTML, arquitetura e docs atualizadas |
| [vcs-integration](done/vcs-integration/spec.md) | 2026-10-10 | pedido do usuário | Leitura opcional de GitHub/Bitbucket/GitLab/Azure DevOps: issue → spec, PR/CI como evidência (`sdd` 0.2.0) |
| [angular-reference](done/angular-reference/spec.md) | 2026-10-10 | GH#1 | Referência Angular no `frontend-engineering`, por versão (`sdd` 0.3.0) |
| [infra-engineering](done/infra-engineering/spec.md) | 2026-10-10 | pedido do usuário | Skill de infraestrutura com referências AWS, Azure e Google Cloud (`sdd` 0.4.0) |
| [specs-done-archive](done/specs-done-archive/spec.md) | 2026-10-10 | pedido do usuário | Arquivar specs concluídas em `.specs/done/` e manter este índice (`sdd` 0.5.0) |
| [onboarding-check](done/onboarding-check/spec.md) | 2026-10-10 | pedido do usuário | Verificar onboarding no início da sessão e orientar a primeira resposta do TecLeader (`sdd` 0.6.0) |
| [specs-location](done/specs-location/spec.md) | 2026-10-10 | pedido do usuário | `.specs/` sempre na raiz do projeto (repositório git); hook detecta git sem executá-lo (`sdd` 0.6.1) |
| [claude-md-layers](done/claude-md-layers/spec.md) | 2026-10-10 | pedido do usuário | Camadas do CLAUDE.md; migração com plano padrão e uma confirmação; `Versionar artefatos SDD` (`sdd` 0.6.2) |
| [workspace-multi-project](done/workspace-multi-project/spec.md) | 2026-10-10 | pedido do usuário | Gatilho de migração preciso; trabalho entre projetos (workspace, `--add-dir`), deny exigido e somente leitura (`sdd` 0.6.3) |
| [docs-conformance](done/docs-conformance/spec.md) | 2026-10-11 | pedido do usuário | Conformidade com a doc oficial: precedência real, textos corrigidos, deny de segredos/push destrutivo, licença MIT (`sdd` 0.6.4, `authoring` 0.2.1) |
| [pin-ref](done/pin-ref/spec.md) | 2026-10-11 | pedido do usuário | Template git fixa a versão com `ref`; regra versão × release (tag só em release, com confirmação) |
| [first-run-guide](done/first-run-guide/spec.md) | 2026-10-11 | pedido do usuário | Guia de primeiro uso (código existente e projeto do zero), verificado em máquina nova e por teste de usabilidade |
