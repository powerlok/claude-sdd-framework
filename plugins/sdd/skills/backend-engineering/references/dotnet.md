# Referência: .NET

Stack típica: ASP.NET Core (minimal APIs ou controllers), C#, EF Core, xUnit.
Usar a versão LTS vigente definida no projeto (`global.json`/`TargetFramework`).
Princípios gerais em [../SKILL.md](../SKILL.md).

## Estrutura de projeto típica

```text
src/
  <App>.Domain/           # entidades, value objects, erros de domínio (sem framework)
  <App>.Application/      # casos de uso, portas (interfaces), DTOs internos
  <App>.Infrastructure/   # EF Core DbContext, repositórios, clientes externos
  <App>.Api/              # endpoints/controllers, contratos, Program.cs (composição)
tests/
  <App>.Domain.Tests/ <App>.Application.Tests/ <App>.Api.IntegrationTests/
<App>.sln  global.json  Directory.Build.props  .editorconfig
```

- Endpoints/controllers só traduzem HTTP <-> caso de uso; sem regra de negócio nem `DbContext` direto.
- Composição via DI nativa (`builder.Services`); registrar por extensão (`AddApplication()`, `AddInfrastructure()`).
- Minimal APIs: agrupar com `MapGroup` por feature.
  Controllers: `[ApiController]`, finos.

## Tipagem e contratos

- `<Nullable>enable</Nullable>` e `<TreatWarningsAsErrors>` (ao menos para nullable) em `Directory.Build.props`.
- Contratos como `record` imutáveis, separados de entidades e de modelos EF.
- Sem `object`/`dynamic` nas fronteiras; usar tipos genéricos e enums.
- `async`/`await` de ponta a ponta, `CancellationToken` propagado; nunca `.Result`/`.Wait()`.
- Versionamento de API: pacote oficial de API versioning ou rota versionada.
- OpenAPI: geração nativa/Swashbuckle/NSwag conforme o projeto; validar contrato no CI.

## Validação

- DataAnnotations para regras simples (`[Required]`, `[StringLength]`, `[Range]`);
  `[ApiController]` retorna 400 automático.
- FluentValidation para regras complexas, registrado por DI e executado na fronteira
  (filtro de endpoint ou behavior).
- Invariantes de negócio no domínio, com erros de domínio explícitos.
- Opções de configuração com `IOptions<T>` + `ValidateOnStart()`.

## Erros

- `ProblemDetails` (RFC 9457): `AddProblemDetails()` + `IExceptionHandler`/`UseExceptionHandler`
  mapeando erros de domínio para status e `type`/`title`/`detail`.
- `ValidationProblemDetails` para erros de validação.
- Não expor stack trace fora de desenvolvimento; incluir `traceId` na resposta.
- Evitar `catch (Exception)` sem relançar ou registrar.

## Persistência e migrações

- EF Core: `DbContext` na infraestrutura, configurações por `IEntityTypeConfiguration<T>`.
- Repositório/consulta atrás de porta quando houver ganho; consultas LINQ parametrizadas;
  `FromSql`/`FromSqlInterpolated` (nunca concatenar string em SQL).
- `AsNoTracking` em leituras; `Include`/projeções contra N+1; paginação.
- Migrações: `dotnet ef migrations add` com `Up` e `Down` revisados;
  testar aplicação e reversão em banco descartável; gerar script SQL para revisão em mudanças destrutivas.
- Concorrência otimista com `rowversion`/token de concorrência.

## Testes

- xUnit (alternativas aceitas: NUnit, MSTest, conforme o projeto); asserções com FluentAssertions/Shouldly
  se já adotadas; dublês com NSubstitute/Moq apenas nas portas.
- Nomeação: `REQ-001` -> `Req001Tests.cs` (classe `Req001Tests`);
  métodos `Req001_<Comportamento>`; opcional `[Trait("Requirement", "REQ-001")]`.
- Integração de API: `WebApplicationFactory<Program>` (expor `public partial class Program`).
- Banco real em contêiner com Testcontainers (ou banco efêmero do CI) em vez de InMemory
  para validar SQL e migrações.
- Relógio injetado (`TimeProvider`) para determinismo.

## Lint, formato e análise estática

- `.editorconfig` versionado; `dotnet format --verify-no-changes` no CI.
- Analyzers do SDK (`<EnableNETAnalyzers>`/`<AnalysisMode>`) e, se adotados, Roslynator/StyleCop;
  avisos novos tratados como erro.

## Segurança e auditoria de dependências

- Autenticação: `AddAuthentication().AddJwtBearer(...)` validando emissor, audiência, assinatura e expiração;
  autorização por política (`AddAuthorization`) e checagem de propriedade do objeto no caso de uso.
- Segredos: variáveis de ambiente, User Secrets apenas em desenvolvimento, cofre em produção.
- Rate limiting nativo (`AddRateLimiter`), CORS com origens explícitas, HSTS/HTTPS.
- Hash de senha: ASP.NET Core Identity `PasswordHasher` ou Argon2/bcrypt.
- Auditoria: `dotnet list package --vulnerable --include-transitive`; versões fixadas
  (`packages.lock.json`/Central Package Management).

## Observabilidade

- `ILogger<T>` com templates estruturados (sem interpolação de strings); Serilog ou
  provedor JSON conforme o projeto; escopos (`BeginScope`) com correlation id.
- Middleware de correlation id (lê/gera cabeçalho e propaga em `Activity`/logs).
- Health checks: `AddHealthChecks()` com `MapHealthChecks` separando liveness e readiness (tags).
- Métricas e traces com OpenTelemetry (`System.Diagnostics.Metrics`/`ActivitySource`).

## Comandos típicos

Exemplos; usar os comandos reais do `CLAUDE.md` do projeto.

```bash
dotnet restore && dotnet build --no-restore -warnaserror
dotnet format --verify-no-changes
dotnet test --no-build --filter "FullyQualifiedName~Req001"
dotnet ef migrations add <Name> -p src/<App>.Infrastructure -s src/<App>.Api
dotnet ef database update  # somente em banco local/descartável; outros ambientes exigem confirmação explícita
dotnet list package --vulnerable --include-transitive
dotnet run --project src/<App>.Api
```
