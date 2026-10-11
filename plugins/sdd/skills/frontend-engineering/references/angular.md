# Referência Angular

Complementa os princípios de [SKILL.md](../SKILL.md). Vale para aplicações Angular
modernas (standalone, signals). Comandos abaixo são exemplos; usar os comandos
reais do `CLAUDE.md` do projeto. Ferramentas citadas (Vitest, Karma, Playwright,
angular-eslint) são exemplos; seguir as já adotadas no projeto.

## Primeiro passo obrigatório: versão do Angular

Antes de escrever código, descobrir a versão do projeto (`@angular/core` no
`package.json` ou `ng version`) e seguir os padrões dessa versão. Não aplicar
prática de versão mais nova sem confirmar que o projeto a suporta.

| Padrão | A partir de |
|---|---|
| Componentes standalone por padrão (não declarar `standalone: true`) | v20 |
| Zoneless por padrão (detecção de mudança sem zone.js) | v21 |
| OnPush por padrão (estratégia antiga passa a se chamar `Eager`) | v22 |
| `@Service()` como atalho de serviço raiz | v22 |
| Signal Forms, `resource`/`httpResource` e Angular Aria estáveis | v22 |

- Projeto em versão antiga: não migrar por conta própria. Seguir os padrões da versão
  atual do projeto e propor a migração como task separada ao TechLead
  (`ng update`; schematics `ng generate @angular/core:<migração>`, ex.: `standalone`,
  `control-flow`, `inject-function`, `signal-inputs`, `route-lazy-loading`).
- Em v20/v21, declarar `ChangeDetectionStrategy.OnPush` explicitamente nos componentes novos.
- Seguir a convenção existente do código quando divergir deste guia.

## Estrutura

- Organizar por feature (`features/<nome>/` com componentes, serviços, rotas, testes),
  não por tipo; `shared/` só para o realmente comum. Um conceito por arquivo.
- Arquivos em kebab-case, nome do arquivo igual ao identificador principal; template e
  estilo com o mesmo nome base; testes `.spec.ts`.
- Nomes: desde a v20 o style guide e o CLI não usam sufixo de papel (`user-profile.ts`,
  classe `UserProfile`). Projeto que já usa `.component.ts`/`Component` mantém a convenção.
- Tipos de entrada, saída e respostas de API explícitos na fronteira da feature; sem `any`.

## Componentes

- Standalone; importar só as diretivas e pipes usados (sem `CommonModule`).
- `input()`, `input.required()`, `output()` e `model()` (two-way `[(x)]`) no lugar de
  `@Input`/`@Output`. `input()` é somente leitura; só `model()` aceita `set`/`update`.
  Transforms prontos: `booleanAttribute`, `numberAttribute`.
- `inject()` no lugar de injeção por construtor.
- OnPush (ver tabela). Objeto `host` do decorator no lugar de `@HostBinding`/`@HostListener`.
- Membros usados só no template: `protected`; inputs, outputs e queries: `readonly`.
- Handlers nomeados pela ação (`saveUser`), não pelo evento (`onClick`).
- Template inline para componentes pequenos; caminhos relativos para arquivos externos.
- Lifecycle hooks curtos, delegando a métodos nomeados.

## Templates

- Control flow nativo: `@if`, `@for`, `@switch` (não `*ngIf`/`*ngFor`).
- `@for` sempre com `track` por identidade estável (id), nunca `$index` em lista que muda.
- Sem lógica pesada no template: mover cálculo para `computed` ou pipe puro; não usar
  globais como `new Date()` no template.
- `[class.x]`/`[style.x]` no lugar de `ngClass`/`ngStyle`; `async` pipe para observables.
- `@defer` para trechos pesados ou abaixo da dobra: `@placeholder`, `@loading`, `@error`;
  gatilhos `idle` (padrão), `viewport`, `interaction`, `hover`, `timer`, `when`; `prefetch`.
  Dependências do bloco devem ser standalone e não ser usadas fora dele no mesmo arquivo.
  Não adiar conteúdo visível no carregamento inicial (causa deslocamento de layout).

## Estado e reatividade

| Tipo | Ferramenta típica | Regra |
|---|---|---|
| Local de UI | `signal` | Mais próximo possível de quem usa |
| Derivado | `computed` | Nunca copiar para outro `signal` via `effect` |
| Gravável derivado de outra fonte | `linkedSignal` | Reinicia quando a fonte muda |
| Compartilhado de UI | serviço com signals | Expor leitura (`asReadonly()`), mutar por métodos |
| Servidor | `resource`/`httpResource` (v22) ou RxJS | Não duplicar dado remoto em estado local |

- Atualizar com `set`/`update`; nunca mutar objeto/array dentro do sinal nem usar `mutate`:
  criar nova referência.
- `effect` com parcimônia: só para sincronizar com APIs imperativas (log, storage,
  canvas, biblioteca de terceiros). Não usar para propagar estado (loops e erros de
  expressão alterada). Exige contexto de injeção; usar `onCleanup` para cancelar e
  `afterRenderEffect` quando precisar do DOM já atualizado.
- RxJS continua válido para fluxos de eventos e composição assíncrona. Interop em
  `@angular/core/rxjs-interop`: `toSignal` (assina na hora, cancela ao destruir;
  `initialValue` ou `requireSync`), `toObservable`, `takeUntilDestroyed`.
  Chamar `toSignal` uma vez e reutilizar o sinal; exige contexto de injeção.
- Dados remotos de leitura: `httpResource()` (v22; confirme na versão do projeto) expõe
  `value`, `isLoading`, `error`, `status`, cancela a requisição anterior quando a
  entrada muda e aceita `parse` para validar com schema. Não usar para mutações
  (POST/PUT/DELETE): usar `HttpClient`. Em versão sem suporte estável, `HttpClient` + `toSignal`.
- Tratar sempre os quatro estados: carregando, erro, vazio, sucesso.

## Serviços e injeção de dependência

- Serviço com responsabilidade única, fornecido na raiz (`providedIn: 'root'`).
- v22: `@Service()` é o atalho do serviço raiz; só aceita `inject()` (sem construtor),
  sem `useClass`/`useValue`/`useFactory` e sem escopo diferente de raiz. Antes da v22,
  usar `@Injectable({ providedIn: 'root' })`.
- Configuração injetada por `InjectionToken` tipado; não ler `window` diretamente.

## Roteamento

- Rotas de feature com lazy loading: `loadComponent` e `loadChildren`.
- Guards e resolvers funcionais (`CanActivateFn`, `CanMatchFn`, `ResolveFn`); retornam
  boolean, `UrlTree`/`RedirectCommand`, Promise ou Observable.
- Guard é só UX. A autorização real fica no servidor.
- Gerenciar foco e título a cada navegação (ver acessibilidade).

## Formulários

- v22 em projeto novo: Signal Forms (`form()`, diretiva `FormField`, validadores em schema,
  de `@angular/forms/signals`). Projeto existente: manter a estratégia atual.
- Entre os clássicos, reactive forms tipados (`FormControl<string>`, `NonNullable`)
  são preferíveis a template-driven.
- Mensagem de erro associada ao campo, visível e anunciada; validação de UX no cliente,
  regra de negócio no backend.

## HTTP

- `provideHttpClient(withInterceptors([...]))`; interceptors funcionais (`HttpInterceptorFn`).
  `withInterceptorsFromDi()` é legado (ordem difícil de prever).
- Requisições são imutáveis: usar `req.clone()`. Metadados por requisição com `HttpContextToken`.
- Interceptor de autenticação anexa credencial somente a requisições para a(s) origem(ns)
  da API configurada(s) (allowlist via `InjectionToken`), nunca a terceiros.
- Tipar a resposta (`http.get<User[]>()`) e validar o formato antes de usar.
- XSRF é automático (cookie `XSRF-TOKEN` para header `X-XSRF-TOKEN`); ajustar com
  `withXsrfConfiguration`, nunca desligar sem justificativa.
- Tratar erro em um ponto central (interceptor) e mostrar estado de erro com ação de recuperação.

## SSR e hidratação (resumo)

- Só adotar SSR se a spec exigir. Habilitar com `provideClientHydration()`.
- Na v22 a hidratação incremental é padrão com SSR: blocos `@defer` aceitam gatilhos
  `hydrate on ...`, `hydrate when` e `hydrate never`; opt-out com `withNoIncrementalHydration()`.
- Código de navegador (`window`, `document`, `localStorage`) fora do caminho de servidor.
- Não transferir dados sensíveis ou por usuário do servidor ao cliente via estado serializado
  ou cache de hidratação. No servidor, não guardar estado por usuário fora da DI (variáveis
  de módulo, singletons): vaza entre requisições.
- Confirmar na documentação da versão do projeto quais respostas HTTP são reaproveitadas na hidratação.
- SSRF: configurar `allowedHosts` (nunca `["*"]`); `trustProxyHeaders` só atrás de proxy confiável.

## Segurança

- Interpolação é sempre escapada; o Angular sanitiza por contexto (HTML, estilo, URL, resource URL).
- Nunca usar `DomSanitizer.bypassSecurityTrust*` sem justificativa registrada e revisada
  pelo `security`; auditar todo uso existente.
- `[innerHTML]` somente com conteúdo passado pelo sanitizador padrão. Evitar acesso
  direto ao DOM (`ElementRef.nativeElement.innerHTML`, `document`).
- Nunca montar templates com entrada do usuário; manter compilação AOT (padrão).
- CSP com nonce (`ngCspNonce` ou token `CSP_NONCE`); Trusted Types quando a política exigir.
- Manter o Angular atualizado (correções de segurança); não alterar cópia do framework.
- Tokens e segredos nunca vão para `environment`/bundle: tudo que vai ao cliente é público.

## Acessibilidade

- Elementos nativos primeiro (`<button>`, `<a>`); ARIA dinâmico com `[attr.aria-*]`.
- CDK a11y: `LiveAnnouncer` para anúncios, `cdkTrapFocus` em diálogos.
- Em rotas: mover o foco ao conteúdo principal em `NavigationEnd`; `ariaCurrentWhenActive`
  no `RouterLinkActive`; envolver conteúdo de `@defer` em região live quando relevante.
- Padrões complexos (menu, abas, listbox, combobox, árvore): v22 tem `@angular/aria`
  (diretivas headless, estável); antes disso, usar o CDK ou componentes de biblioteca já adotada.
- Meta: AXE sem violações e WCAG 2.2 AA, conforme o SKILL.md.

## Performance

Medir primeiro (DevTools, relatório de bundle, Lighthouse). Só então aplicar.

- Lazy por rota (`loadComponent`) e por bloco (`@defer`).
- `NgOptimizedImage`: `ngSrc` com `width`/`height` ou `fill`, `priority` na imagem LCP,
  `sizes` em imagens responsivas; não funciona com imagem base64 inline.
- `track` com id estável em `@for`; `computed` no lugar de método chamado no template.
- Budgets em `angular.json` (bundle inicial e estilo de componente): respeitar e não
  aumentar sem justificativa; o build falha ao ultrapassar o limite de erro.
- Evitar cascatas de requisições: paralelizar o que é independente.
- Zoneless/OnPush: código que dependia de zone.js (`setTimeout` esperando renderização,
  `NgZone.onStable`) deve usar sinais, `markForCheck` ou `afterNextRender`.

## Testes

- Usar o runner que o projeto já tem. Vitest é o padrão de projetos novos
  (`@angular/build:unit-test`, DOM `jsdom` ou `happy-dom`); Karma segue suportado.
  Não migrar de runner por conta própria.
- Componente: `TestBed`, consultar por papel/rótulo, cobrir carregando, erro, vazio, sucesso.
  Em zoneless, preferir `await fixture.whenStable()` a `detectChanges()` manual.
- HTTP: `provideHttpClient()` antes de `provideHttpClientTesting()`; `HttpTestingController`
  (`expectOne`, `flush`) e `verify()` no `afterEach`.
- Harnesses do CDK (`TestbedHarnessEnvironment.loader`) para componentes de biblioteca,
  sem depender do DOM interno.
- E2E (somente se delegado): o CLI não traz framework; `ng e2e` exige um esquema configurado.
  `ng add` instala dependência e executa schematic: se o projeto não tiver E2E configurado,
  não instalar por conta própria; registrar a lacuna e propor ao TechLead. Nome exato do
  pacote definido na task ou no `CLAUDE.md`; pacote novo passa pela revisão do `security`.
  Fluxo principal, seletores por papel.
- Rastreabilidade: REQ-001 em `req001` (ex.: `req001.spec.ts` ou `describe('REQ-001 ...')`).
- Defeito corrigido ganha teste de regressão.

## Build, lint e validação (exemplos; usar os comandos reais do CLAUDE.md)

```text
ng lint            # exige lint já configurado no projeto (ver nota abaixo)
ng test
ng build           # builder @angular/build:application; saída em dist/<projeto>
ng e2e             # se delegado e configurado
```

- Sem lint configurado: não rodar `ng add` por conta própria (instala dependência e executa
  schematic); registrar a lacuna e propor ao TechLead; pacote novo passa pelo `security`.
- Rodar `ng build` após gerar código; falha de budget ou de tipo é falha de build.
- Variáveis e arquivos de ambiente entram no bundle: nunca colocar segredos.
- Conferir o tamanho do bundle após adicionar dependência.
- Falha de build ou teste: reportar comando, saída real e causa; não mascarar.

## Armadilhas comuns

- `subscribe()` manual sem cancelamento vaza memória: `toSignal`, `async` ou `takeUntilDestroyed()`.
- `effect()` para derivar ou copiar estado: usar `computed`/`linkedSignal`.
- `toSignal` repetido para o mesmo observable ou fora do contexto de injeção.
- Lógica ou chamada cara de método no template.
- `any` em resposta HTTP: tipar e validar (`parse` no `httpResource`, schema).
- `@for` com `track $index` em lista mutável: perde estado e recria DOM.
- Mutar objeto/array do sinal: OnPush/zoneless não detecta; criar nova referência.
- Gerar código legado em projeto moderno: NgModule, `standalone: true` (v20+), `*ngIf`/`*ngFor`,
  `@Input`/`@Output`, construtor, `ngClass`/`ngStyle`, `CommonModule`, `@HostBinding`.
- `httpResource` para POST/PUT; interceptor de classe com `withInterceptorsFromDi`.
- Guard como única proteção de acesso.
- `bypassSecurityTrust*` ou `innerHTML` com dado do usuário: XSS.
- `provideHttpClientTesting()` antes de `provideHttpClient()`.
- `@defer` acima da dobra (deslocamento de layout) ou dependência usada fora do bloco (não é adiada).
- `NgOptimizedImage` sem dimensões ou sem `priority` na imagem LCP.
- Impor nomes sem sufixo em projeto que usa `.component.ts`.
- Supor que `ng lint` funciona sem `angular-eslint`.
- Aplicar práticas de v22 (Signal Forms, `@Service`, OnPush padrão) em versão anterior.
- Supor que Karma foi removido: segue suportado; Vitest é só o padrão de projetos novos.

---

Fontes e atribuição:

- `https://angular.dev` (documentação Angular, Google LLC / Angular team, licença CC BY 4.0 —
  https://creativecommons.org/licenses/by/4.0/).
- `https://github.com/angular/skills@ff69483` (Angular team / Google LLC; HEAD de main em 2026-10-10): MIT conforme declarado no
  frontmatter do SKILL.md; repositório sem arquivo LICENSE.
- Alterações: conteúdo parafraseado, traduzido para pt-BR e condensado; nenhum trecho copiado.
- Consultado em 2026-10-10; parte dos dados da v22 veio de resumo do anúncio oficial —
  confirme na versão do projeto.
