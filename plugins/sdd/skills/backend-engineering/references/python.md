# Referência: Python

Stack típica: Python (versão definida no projeto), FastAPI, Pydantic, SQLAlchemy 2,
Alembic, pytest, ruff, mypy. Princípios gerais em [../SKILL.md](../SKILL.md).

## Estrutura de projeto típica

```text
src/<app>/
  domain/            # entidades, value objects, erros de domínio (sem framework)
  application/       # casos de uso, portas (Protocol/ABC), DTOs internos
  infrastructure/    # repositórios SQLAlchemy, clientes externos, config
  api/               # routers FastAPI, schemas Pydantic, dependências, handlers de erro
  main.py            # composição (app factory, DI)
migrations/          # Alembic
tests/               # espelha src; unit/, integration/
pyproject.toml
```

- Routers só traduzem HTTP <-> caso de uso; sem regra de negócio nem sessão de banco direta.
- Composição de dependências via `Depends` e app factory; sem estado global mutável.

## Tipagem e contratos

- Anotações de tipo em todas as funções públicas; `mypy` em modo estrito quando viável.
- Schemas Pydantic (v2) para request/response, separados de entidades e modelos ORM.
- Usar `Protocol` para portas; `dataclass(frozen=True)` ou value objects para domínio.
- Evitar `Any`; usar `TypedDict`, `Literal`, `Annotated` e `StrEnum` quando adequado.
- `response_model` explícito para não expor campos extras.
- Async: rotas e I/O `async` de ponta a ponta; não chamar código bloqueante no event loop
  (usar `run_in_executor` ou biblioteca async).

## Validação

- Pydantic valida na fronteira: `Field(min_length=..., max_length=..., ge=...)`,
  `model_config = ConfigDict(extra="forbid")` para rejeitar campos desconhecidos.
- Invariantes de negócio no domínio, levantando erros de domínio.
- Configuração via `pydantic-settings` lendo variáveis de ambiente.

## Erros

- Hierarquia de exceções de domínio (`DomainError` e derivadas).
- `exception_handler` do FastAPI mapeia exceções para respostas padronizadas
  (formato Problem Details ou equivalente documentado) em um único módulo.
- Sem `except Exception` genérico sem relançar ou registrar.

## Persistência e migrações

- SQLAlchemy 2 com `Mapped[...]`/`mapped_column`, sessão async (`AsyncSession`) quando a stack for async.
- Repositório encapsula consultas; sessão e transação geridas na camada de aplicação/unidade de trabalho.
- Sempre consultas parametrizadas (nunca interpolar string em SQL); `selectinload`/`joinedload` contra N+1.
- Alembic: uma revisão por mudança, com `upgrade` e `downgrade`; revisar o autogenerate.
- Testar `upgrade` e `downgrade` em banco descartável.

## Testes

- pytest (+ `pytest-asyncio` ou `anyio` para async), `httpx.AsyncClient` com `ASGITransport` para API.
- Nomeação: `REQ-001` -> `tests/.../test_req001.py` (ou `test_req001_<tema>.py`);
  funções `test_req001_<comportamento>`; opcional `@pytest.mark.req("REQ-001")`
  (registrar o marker em `pyproject.toml`).
- Integração com banco real em contêiner (ex.: Testcontainers) ou banco efêmero do CI;
  fixtures com rollback por teste.
- Unitários sem I/O; `freezegun`/relógio injetado para tempo.
- Cobertura via `pytest-cov` como indicador.

## Lint, formato e análise estática

- `ruff check` (lint) e `ruff format` (formato); configuração em `pyproject.toml`.
- `mypy` para tipos; sem `# type: ignore` sem justificativa.

## Segurança e auditoria de dependências

- Auth via dependências do FastAPI (`Security`, OAuth2/JWT validado: assinatura, `exp`, `aud`, `iss`).
- Autorização por objeto no caso de uso, não apenas por rota.
- Segredos só por ambiente; `.env` fora do versionamento.
- Hash de senha com Argon2 ou bcrypt; nunca MD5/SHA simples.
- Auditoria: `pip-audit` (ou ferramenta equivalente do projeto); dependências com versões fixadas
  (lockfile).
- Bandit ou regras `S` do ruff para padrões inseguros, quando adotado.
- CORS explícito (`CORSMiddleware` com origens permitidas, não `*` com credenciais).

## Observabilidade

- Logs estruturados (`structlog` ou `logging` com formatter JSON); `contextvars` para correlation id.
- Middleware que lê/gera `X-Correlation-ID` (ou cabeçalho definido no projeto) e o devolve na resposta.
- Endpoints `/health/live` e `/health/ready` (readiness verifica banco/cache).
- Métricas e traces com OpenTelemetry ou `prometheus-client`, conforme o projeto.

## Comandos típicos

Exemplos; usar os comandos reais do `CLAUDE.md` do projeto.

```bash
ruff check . && ruff format --check .
mypy src
pytest -q
pytest -q tests -k req001
alembic upgrade head && alembic downgrade -1  # somente em banco local/descartável; outros ambientes exigem confirmação explícita
pip-audit
uvicorn <app>.main:app --reload
```
