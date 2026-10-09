---
name: backend-engineering
description: Princípios de engenharia backend agnósticos de linguagem (arquitetura em camadas, contratos de API, validação, erros, persistência, transações, observabilidade, segurança e testes). Usar ao projetar, implementar, revisar ou testar serviços backend; combinar com a referência da stack do projeto (Python, .NET).
---

# Engenharia Backend

Princípios independentes de linguagem. Detalhes de ferramentas e idiomas
ficam em `references/<stack>.md`.

## Como escolher a referência

1. Identifique a stack na seção `## Stack` do `CLAUDE.md` do projeto
   ou no campo `Stack:` da delegação do TecLeader.
2. Leia somente a referência correspondente.
3. Sem referência para a stack: aplique estes princípios, siga as convenções
   já existentes no código e declare a lacuna no relato (campo `Riscos`).
4. Stack ausente: não adivinhe; informe o TecLeader.

| Stack | Referência |
|---|---|
| Python (FastAPI, Pydantic, SQLAlchemy, Alembic, pytest) | [references/python.md](references/python.md) |
| .NET (ASP.NET Core, EF Core, xUnit) | [references/dotnet.md](references/dotnet.md) |

Comandos nas referências são exemplos; usar os comandos reais do `CLAUDE.md`.

## Arquitetura

- Camadas com dependência apontando para dentro:
  `API/transporte -> aplicação (casos de uso) -> domínio <- infraestrutura`.
- Domínio sem dependência de framework, banco ou HTTP.
- Portas (interfaces) definidas por quem as consome; adaptadores na infraestrutura
  (Hexagonal). Só criar interface quando houver mais de uma implementação
  ou necessidade real de isolamento (YAGNI).
- DDD tático quando o domínio justificar: entidades, value objects,
  agregados (fronteira transacional), serviços de domínio, eventos.
  CRUD simples não exige DDD.
- Proibido: regra de negócio em routers/controllers; acesso a banco na camada HTTP.
- Fail fast: validar pré-condições no início; falhar cedo e de forma explícita.

## Contratos de API

- Contrato explícito e tipado (schemas/DTOs) separado do modelo de domínio
  e do modelo de persistência.
- Versionar a API (caminho ou cabeçalho); mudança incompatível = nova versão.
- Mudanças compatíveis: adicionar campos opcionais; nunca remover/renomear sem versão.
- Semântica HTTP correta: verbos, status codes, paginação, filtros e ordenação documentados.
- Publicar especificação (OpenAPI) gerada ou validada contra o código.

## Validação de entrada

- Toda entrada externa é não confiável: corpo, query, cabeçalhos, arquivos, mensagens.
- Validar na fronteira (formato, tamanho, faixa, enum); invariantes de negócio no domínio.
- Lista de permitidos (allowlist) em vez de bloqueio; rejeitar campos desconhecidos quando viável.
- Limitar tamanho de payload, paginação e upload.

## Tratamento de erros

- Erros de domínio explícitos e tipados; mapear para HTTP em um único ponto.
- Formato de erro padronizado (RFC 9457 Problem Details ou equivalente documentado).
- Não vazar stack trace, SQL ou detalhes internos ao cliente; registrar no log com correlation id.
- Não engolir exceções; não usar exceção para fluxo normal.
- Distinguir erro do cliente (4xx) de falha do servidor (5xx) e de dependência (timeout/retry).

## Persistência e migrações

- Acesso a dados atrás de repositório/porta; consultas parametrizadas sempre.
- Migrações versionadas, revisadas e reversíveis (downgrade testado).
- Mudança destrutiva (drop, alteração de tipo com perda) exige confirmação explícita
  e estratégia em fases (expandir, migrar, contrair).
- Migração compatível com a versão anterior do código durante o deploy.
- Índices e constraints no banco refletem invariantes (unicidade, FK, not null).
- Evitar N+1; paginar listagens.

## Transações e idempotência

- Uma transação por caso de uso; fronteira na camada de aplicação.
- Operações de escrita expostas a retry (POST, mensagens) devem ser idempotentes:
  chave de idempotência, constraint única ou operação naturalmente idempotente.
- Consumidores de mensagens assumem entrega ao-menos-uma-vez.
- Chamadas externas com timeout, retry com backoff e limite; sem transação aberta durante I/O externo lento.
- Concorrência: controle otimista (versão/ETag) quando houver conflito de escrita.

## Observabilidade

- Logs estruturados (JSON) com nível, correlation id e contexto; sem dados sensíveis.
- Correlation/trace id recebido ou gerado na entrada e propagado em chamadas e logs.
- Health checks separados: liveness e readiness (inclui dependências críticas).
- Métricas: taxa, erros, latência (RED) e saturação das dependências.
- Tracing distribuído quando houver mais de um serviço (OpenTelemetry).

## Segurança (OWASP API Security)

- Autenticação e autorização em toda rota; checar propriedade do objeto
  (BOLA) e da função (BFLA), não só o papel.
- Expor apenas campos necessários (evitar exposição excessiva e mass assignment).
- Rate limiting e limites de recursos; CORS restritivo; cabeçalhos de segurança.
- Segredos somente por variável de ambiente ou cofre; nunca em código, logs ou repositório.
- Senhas com hash adequado (Argon2/bcrypt/PBKDF2); TLS em trânsito.
- Auditar dependências regularmente (ver referência da stack); fixar versões.
- SSRF: validar destinos em chamadas iniciadas por entrada do usuário.
- Menor privilégio para banco, filas e credenciais de serviço.

## Testes

- Pirâmide: muitos unitários (domínio, casos de uso), alguns de integração
  (repositório, API com banco real/contêiner), poucos E2E.
- TDD quando possível: teste falhando, implementação mínima, refatoração.
- Testes determinísticos: sem dependência de relógio, rede externa ou ordem de execução.
  Injetar tempo e aleatoriedade.
- Dublês apenas nas fronteiras (portas); não mockar o que você possui no domínio.
- Toda correção de defeito inclui teste de regressão.
- Rastreabilidade REQ -> teste com nome neutro de linguagem:
  `REQ-001` -> `req001` (ex.: `test_req001.py`, `Req001Tests.cs`).
  Cada teste referencia o requisito no nome do arquivo/classe e no nome do caso.
- Cobrir critérios de aceite, caminhos de erro e limites; cobertura é indicador, não meta.

## Qualidade e entrega

- Formatação, lint e análise estática automatizados e sem avisos novos.
- Tipagem explícita nas fronteiras (APIs, DTOs, integrações).
- Configuração por ambiente; sem valores mágicos; paridade dev/prod.
- Antes de relatar: executar lint, tipos/análise, testes e build do projeto
  e registrar comandos e resultados reais.
