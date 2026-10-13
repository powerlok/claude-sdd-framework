# Tasks: spec-pr-flow

| ID | Objetivo | REQ | Responsável | Depende | Estado |
|----|----------|-----|-------------|---------|--------|
| T-001 | Modelos de settings e `publicacao.json` sem merge no grupo; deny fixo | REQ-001 | techlead | — | DONE |
| T-002 | `techlead.md` (fim da spec, lote, nunca merge), `git-workflow.md` (modelo do PR), skill `publish`, governança | REQ-002..005 | techlead | T-001 | DONE |
| T-003 | Testes, docs, CHANGELOG, `sdd` 0.9.4, validate, suíte | REQ-006 | techlead | T-002 | DONE (req007 68 ok; validate ok) |
| T-004 | Sandbox: lote mostrado e merge recusado | critérios | techlead | T-003 | PARCIAL: merge recusado ("é seu") e nada publicado sem confirmação; o lote não chegou a ser apresentado porque o sandbox não tem remoto GitHub nem `.specs/` (pré-checagens falharam, como projetado). NÃO executado: lote completo e PR reais (sessão interativa). |
