# Reprodutibilidade

Parte da skill [sdd-rules](../SKILL.md).

## Experimentos

Devem registrar:

- seed
- modelo utilizado
- versão
- dataset
- parâmetros relevantes

O resultado deve poder ser reproduzido posteriormente.

## Nunca versionar

- caches
- logs
- artefatos temporários
- ambientes virtuais
- arquivos gerados automaticamente

Exemplos (variam conforme a stack):

```text
.venv/
node_modules/
coverage/
dist/
build/
.cache/
```
