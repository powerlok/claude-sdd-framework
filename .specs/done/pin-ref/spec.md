# Spec: fixar a versão do framework nos projetos (ref)

Pedido do usuário (2026-10-11): "sim 1 e 2" (2 = fixar `ref` nos projetos que usam o framework pelo git).

- **REQ-001**: `templates/project-settings.git.json` com `"ref": "v0.6.4"` em `extraKnownMarketplaces...source`
  (doc oficial: `ref` = branch ou tag; padrão = branch padrão). `project-settings.local.json` (directory) não usa `ref`.
- **REQ-002**: procedimento de release (R/CLAUDE.md, README): criar tag anotada `vX.Y.Z` e atualizar o `ref` do template;
  projetos sobem de versão trocando o `ref` e rodando `claude plugin marketplace update` + `plugin update`.
- **REQ-003**: CHANGELOG (seção de templates).
- **REQ-004 (aprovado pelo usuário em 2026-10-11)**: versão × release, só para este repositório (não vai para o plugin):
  bump de versão em toda feature que altera um plugin (commit em `main`, sem tag); **release** = conjunto pronto para
  consumo (validate --strict, segurança aprovada quando aplicável, validação sem defeito aberto, CHANGELOG fechado),
  com tag anotada `vX.Y.Z` = `metadata.version` do `marketplace.json`, `ref` do template apontando para ela e seção
  "Release vX.Y.Z" no CHANGELOG listando as versões dos plugins. Só docs/specs, trabalho em andamento ou mudança não
  validada não é release. O TecLeader pergunta "é release?" ao encerrar; a tag só com confirmação do usuário.
  `v0.6.4` (já publicada) é a primeira release: `metadata.version` = `0.6.4`.

Sem mudança de permissão (só versão da fonte) → revisão de segurança dispensada (registrado).

## Critérios de aceite

Regra no `CLAUDE.md` e README do repositório; `metadata.version` 0.6.4; JSON válido; `claude plugin validate . --strict` ✔; linkcheck sem quebras; tag `v0.6.4` existe no remoto.
