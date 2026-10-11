# Tasks: pin-ref

| ID | Objetivo | REQ | Responsável | Depende | Estado |
|----|----------|-----|-------------|---------|--------|
| T-001 | ref no template, procedimento, CHANGELOG, versão × release | REQ-001..004 | tecleader | — | DONE |

## Observações

- 2026-10-11: template com ref v0.6.4; procedimento de release (tag + ref); README/manual/CHANGELOG. JSON ok; validate --strict ✔. ref não testado empiricamente (registraria marketplace no perfil do usuário); comportamento conforme doc oficial (marketplace-reference: ref = branch ou tag). Workspace usa source directory (ref não se aplica).
- 2026-10-11 (REQ-004): regra Versão × release no CLAUDE.md e README do repositório; metadata.version 0.6.4; CHANGELOG "Release v0.6.4"; validate --strict ✔ x3. Tag v0.6.4 mantida em d936397 (não mover).
