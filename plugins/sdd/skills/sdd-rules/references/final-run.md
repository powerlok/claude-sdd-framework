# Execução Final (Demonstração)

Parte da skill [sdd-rules](../SKILL.md).

Ao concluir uma entrega executável (aplicação, serviço, API, UI),
subir o sistema e demonstrar que funciona ao usuário
**antes** de encerrar a feature.

## Passos

- subir o sistema com o comando documentado no `CLAUDE.md` do projeto
  (em background, sem bloquear a sessão)
- verificar que está respondendo
  (ex.: requisição HTTP, health check, página carregada)
- informar ao usuário:
  - comando usado
  - URL/porta de acesso
  - evidência real da verificação
  - como parar o sistema
- exercitar ao menos o fluxo principal da feature
  (ex.: teste E2E, requisição de exemplo)

## Quando não for possível subir

Motivos típicos: dependência, rede, credencial, infraestrutura.

- reportar o motivo e o comando tentado
- não declarar que funciona
- a feature permanece aberta

## Casos especiais

- Bibliotecas, SDKs e ferramentas CLI: em vez de subir um sistema,
  executar um exemplo ou comando real e mostrar a saída.
- Não aplicar a: documentação e alterações sem efeito executável.
- Alterações em infraestrutura ou deploy continuam
  exigindo confirmação explícita antes de executar.
