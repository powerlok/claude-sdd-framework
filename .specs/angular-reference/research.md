# Pesquisa: referência Angular (T-001, GH#1)

Data da coleta: 2026-10-10. Pesquisa somente leitura. Conteúdo web tratado como dado
não confiável. Nada abaixo é cópia; são fatos parafraseados para redação própria posterior.

Legenda: **[C]** Confirmado em fonte oficial (URL citada) · **[NC]** Não confirmado em
fonte oficial (só terceiros) · Status de API: estável / developer preview / experimental.

Abreviações de fonte usadas nos bullets (URLs completas na tabela de fontes):
`rel` releases · `bp` best-practices.md (contexto LLM oficial) · `ai` develop-with-ai ·
`sg` style guide · `sec` segurança · `zl` zoneless · `tst` testing · `blog22` anúncio v22 ·
`ns22` Ninja Squad v22 (terceiro).

---

## 1. Versão e política

- Versão estável atual: **v22** (lançada 2026-06-03). [C] `rel`
- v21 (2025-11-19) em LTS até 2027-06; v20 em LTS até 2026-11-28. [C] `rel`
- Cadência mudou na v22: major a cada **12 meses** com 4-6 minors (antes: 6 meses, 1-3 minors). [C] `rel`
- Suporte: 12 meses ativo + 12 meses LTS (só correções críticas e segurança). [C] `rel`
- Depreciação: API depreciada permanece por pelo menos uma major (>= 12 meses); remoção só em major. [C] `rel`
- v22 exige TypeScript 6 (5.9 sai) e remove Node 20. [NC] `ns22`
- Implicação para a referência: sempre detectar a versão do projeto (`package.json`/`ng version`) antes
  de aplicar regras; várias práticas abaixo dependem de v20/v21/v22. (O skill oficial também
  manda checar a versão primeiro.) [C] skill oficial `angular-developer`

## 2. Componentes

- Standalone é o padrão desde v20; não declarar `standalone: true`. [C] `bp`
- Preferir standalone a NgModules. [C] `bp`, `ai`
- `input()`, `input.required()`, `output()`, `model()` (two-way `[(x)]`) — estáveis; `@Input` segue suportado
  para código legado. [C] https://angular.dev/guide/components/inputs
- Transforms de input embutidos: `booleanAttribute`, `numberAttribute`. [C] mesma URL
- `input()` é somente leitura; só `model()` aceita `set`/`update`. [C] mesma URL
- Usar o objeto `host` do decorator em vez de `@HostBinding`/`@HostListener`. [C] `bp`
- Não importar `CommonModule`; importar só diretivas/pipes usados. [C] `bp`
- Bindings `[class]`/`[style]` em vez de `ngClass`/`ngStyle`. [C] `bp`, `sg`
- Membros usados só no template: `protected`; propriedades inicializadas pelo Angular
  (inputs, outputs, queries): `readonly`. [C] `sg`
- Agrupar inputs/outputs/queries no topo da classe; lifecycle hooks curtos delegando a métodos
  nomeados; implementar interfaces de hooks. [C] `sg`
- Nomear handlers pela ação (`saveUser`) e não pelo evento (`onClick`). [C] `sg`
- Template inline para componentes pequenos; caminhos relativos para template/estilo externos. [C] `bp`

## 3. Sinais e reatividade

- `signal`, `computed` — estáveis; estado local com sinais; derivado com `computed`. [C] `bp`
- `set`/`update`, nunca `mutate`. [C] `bp`
- `linkedSignal` — estável; estado gravável derivado de fontes reativas. [C] `bp`
  (status estável desde v20 [NC] — página mostra só "Updated").
- `effect` — estável; só para sincronizar com APIs imperativas (log, storage, canvas, libs de terceiros);
  **não** usar para propagar estado (risco de loop, `ExpressionChanged...`). Exige contexto de injeção;
  `onCleanup` para cancelamento; `afterRenderEffect` quando precisa do DOM já atualizado.
  [C] https://angular.dev/guide/signals/effect
- `resource`, `rxResource`, `httpResource` — **estáveis na v22** (eram experimentais). [C] `blog22` (resumo via
  busca; página retornou 403), [C] `bp` indiretamente; detalhes [NC] `ns22`: novo `chain()` para requisições
  dependentes, cache via opção `id` para SSR, `debounced()` experimental.
- RxJS interop (`@angular/core/rxjs-interop`): `toSignal` (assina na hora; desinscreve ao destruir; `initialValue`,
  `requireSync`), `toObservable`, `takeUntilDestroyed`, `rxResource`. Exigem contexto de injeção.
  Reutilizar o sinal em vez de chamar `toSignal` repetidamente. [C] https://angular.dev/ecosystem/rxjs-interop
- Template: `async` pipe para observables. [C] `bp`

## 4. Templates e control flow

- Control flow nativo `@if`, `@for`, `@switch` em vez de `*ngIf/*ngFor/*ngSwitch`. [C] `bp`
- `@for` exige `track` (identidade estável, ex. id). [C] (sintaxe obrigatória; doc de control flow) — detalhe de
  exigência do compilador [NC] nesta coleta.
- Manter templates simples, sem lógica complexa; não assumir globais (ex. `new Date()`) no template. [C] `bp`
- `strictTemplates` ativo por padrão na v22. [NC] `ns22`
- `@defer`: `@placeholder` (`minimum`), `@loading` (`after`, `minimum`), `@error`; gatilhos `idle` (padrão),
  `viewport`, `interaction`, `hover`, `immediate`, `timer`, `when`; `prefetch`. Dependências precisam ser
  standalone e não referenciadas fora do bloco no mesmo arquivo. Não adiar conteúdo visível no carregamento
  inicial (CLS). [C] https://angular.dev/guide/templates/defer

## 5. Change detection

- **OnPush é o padrão na v22**; não declarar explicitamente; estratégia antiga renomeada para `Eager`. [C] `bp`,
  `blog22`; migração adiciona `Eager` a componentes existentes [NC] `ns22`.
- **Zoneless é o padrão desde v21**; `provideZonelessChangeDetection()` era necessário na v20;
  `provideZoneChangeDetection()` volta para Zone. [C] `zl`
- Notificações válidas em zoneless: sinal lido no template, `markForCheck` (o `async` faz), `setInput`,
  listeners de evento ligados no template. Remover uso de `NgZone.onStable/onMicrotaskEmpty/isStable`;
  `run`/`runOutsideAngular` continuam ok. [C] `zl`
- TestBed é zoneless por padrão; preferir `await fixture.whenStable()` a `detectChanges()` manual. [C] `zl`

## 6. Injeção de dependência e serviços

- `inject()` em vez de injeção por construtor. [C] `bp`, `sg`
- `@Service()` (v22): atalho para `@Injectable({providedIn: 'root'})`; só `inject()` (sem construtor),
  sem `useClass/useValue/useFactory`, sem escopos não-root. [C] https://angular.dev/guide/di/creating-and-using-services
- `ng generate service` gera `@Service()` por padrão na v22. [NC] `ns22`
- `injectAsync()` para carregar serviço sob demanda (code split). [NC] `ns22` (doc oficial de serviços não menciona).
- Serviço com responsabilidade única. [C] `bp`

## 7. Roteamento

- Lazy loading de rotas de feature (`loadComponent`, `loadChildren`). [C] `bp`; migração `route-lazy-loading` [C].
- Guards funcionais: `CanActivate`, `CanActivateChild`, `CanDeactivate`, `CanMatch`; retornam boolean,
  `UrlTree`/`RedirectCommand`, Promise ou Observable; guards assíncronos rodam em paralelo.
  [C] https://angular.dev/guide/routing/route-guards
- **Guard é só UX; autorização real fica no servidor.** [C] mesma URL
- Resolvers com `ResolveFn`. [C] (referência `data-resolvers.md` do skill oficial)
- v22: `paramsInheritanceStrategy` padrão `'always'`; `canMatch` recebe `currentSnapshot`; `withComponentInputBinding()`
  com opções. [NC] `ns22`

## 8. Formulários

- **Signal Forms estável na v22** (experimental na v21): `form()`, diretiva `FormField`, validadores em schema
  (`required`, `email`, ...), importados de `@angular/forms/signals`. [C] `bp`, `blog22`,
  https://angular.dev/guide/forms/signals/overview
  - Divergência: a página overview diz "production-ready em v21+"; `bp` e o anúncio dizem estável na v22.
    Tratar como estável a partir de v22.
- Regra: form novo em v22+ → Signal Forms; projeto existente → manter a estratégia atual;
  entre os clássicos, reactive (tipados) > template-driven. [C] `bp`, skill oficial

## 9. HTTP

- `provideHttpClient()`; interceptors **funcionais** (`HttpInterceptorFn` + `withInterceptors`) recomendados;
  `withInterceptorsFromDi()` é legado (ordem difícil de prever). Requisições imutáveis (`clone()`);
  `HttpContextToken` para metadados por requisição. [C] https://angular.dev/guide/http/interceptors
- `httpResource()` para leitura reativa (sinais `value`, `isLoading`, `error`, `hasValue`, `status`); cancela
  requisição anterior quando a entrada muda; opção `parse` para validar com schema (Zod/Valibot);
  **não usar para mutações** (POST/PUT) — usar `HttpClient`. [C] https://angular.dev/guide/http/http-resource
- v22: fetch passa a ser o backend padrão (`withXhr()` para XHR); `reportProgress` depreciado. [NC] `ns22`
- XSRF automático (cookie `XSRF-TOKEN` → header `X-XSRF-TOKEN`); `withXsrfConfiguration`, `withNoXsrfProtection`. [C] `sec`

## 10. SSR e hydration

- Incremental hydration **padrão na v22** com `provideClientHydration()`; opt-out `withNoIncrementalHydration()`;
  requer SSR, usa blocos `@defer` com gatilhos `hydrate on idle|viewport|interaction|hover|immediate|timer`,
  `hydrate when`, `hydrate never`; event replay automático. [C] https://angular.dev/guide/incremental-hydration
- SSRF: configurar `allowedHosts` (nunca `["*"]`) e `trustProxyHeaders` só atrás de proxy confiável. [C] `sec`

## 11. Segurança

- Interpolação sempre escapada; sanitização por contexto: HTML, style, URL, resource URL. [C] `sec`
- `DomSanitizer.bypassSecurityTrust*` (Html, Style, Script, Url, ResourceUrl) desliga a proteção: só com valor
  confiável e revisado; auditar todo uso. [C] `sec`
- Evitar acesso direto ao DOM (`document`, `ElementRef.nativeElement.innerHTML`). [C] `sec`
- Nunca gerar templates com entrada do usuário nem no servidor (template injection); usar AOT (padrão). [C] `sec`
- CSP: nonce via atributo `ngCspNonce` ou token `CSP_NONCE`; `security.autoCsp` (hashes) para hosting estático. [C] `sec`
- Trusted Types: políticas `angular`, `angular#unsafe-bypass`, `angular#bundler`, `angular#unsafe-jit`. [C] `sec`
- XSSI: prefixo `)]}',` removido automaticamente do JSON. [C] `sec`
- Manter Angular atualizado; não modificar cópia do framework. [C] `sec`

## 12. Acessibilidade

- Deve passar AXE e WCAG AA (foco, contraste, ARIA). [C] `bp`
- Elementos nativos primeiro (`<button>`, `<a>`); ARIA dinâmico via `[attr.aria-*]`/`[aria-*]`. [C]
  https://angular.dev/best-practices/a11y
- CDK a11y: `LiveAnnouncer`, `cdkTrapFocus` (também `FocusMonitor` [NC]). [C] mesma URL
- Rotas: gerenciar foco em `NavigationEnd`; `ariaCurrentWhenActive` no `RouterLinkActive`; envolver `@defer` em
  região live. [C] mesma URL
- **Angular Aria** (`@angular/aria`): diretivas headless WAI-ARIA (Accordion, Listbox, Select, Multiselect, Combobox,
  Autocomplete, Menu, Menubar, Toolbar, Tabs, Tree, Grid) — **estável na v22** (era developer preview).
  [C] https://angular.dev/guide/aria/overview, `blog22`

## 13. Performance

- `NgOptimizedImage` (`ngSrc`, `width`/`height` ou `fill`, `priority` na imagem LCP, `sizes` para responsivo,
  loaders de CDN); lazy por padrão; incompatível com imagem base64 inline. [C]
  https://angular.dev/guide/image-optimization, `bp`
- Lazy por rota + `@defer` por bloco. [C] `bp`, doc defer
- Budgets em `angular.json`: padrão inicial aviso 500kB/erro 1MB; estilo de componente aviso 2kB/erro 4kB
  (valores do template padrão). [C] https://angular.dev/tools/cli/build
- Critical CSS inline por padrão. [C] mesma URL
- `track` em `@for` com id estável. [C] (control flow)
- v22: otimização de chunks padrão; Rolldown voltou a experimental. [NC] `ns22`

## 14. Estrutura e nomes (style guide)

- Arquivos em kebab-case; nome do arquivo = identificador principal; template/estilo com o mesmo nome base;
  testes `.spec.ts`. [C] `sg`
- Organizar por feature, não por tipo (evitar pastas `components/`, `services/`). Um conceito por arquivo. [C] `sg`
- Desde v20 o style guide e o CLI não usam sufixo de papel (`user-profile.ts`, classe `UserProfile`); projetos
  com sufixo existentes devem manter a convenção. [C] `sg` + skill oficial `naming-conventions.md`

## 15. Testes

- **Vitest é o runner padrão** de novos projetos (builder `@angular/build:unit-test`); DOM via `jsdom` (padrão) ou
  `happy-dom`; modo navegador via Playwright/WebdriverIO. [C] `tst`
- **Karma não está depreciado**: segue suportado (`ng new --test-runner=karma` ou `runner: "karma"`). [C]
  https://angular.dev/guide/testing/karma
- Jest: não citado pela doc oficial do CLI. [C] (ausência) `tst`
- Migração Karma→Vitest: experimental; schematic `ng g @schematics/angular:refactor-jasmine-vitest`. [C]
  https://angular.dev/guide/testing/migrating-to-vitest; v22 adiciona `migrate-karma-to-vitest` e suporte a
  `fakeAsync` com Vitest via patch zone.js [NC] `ns22`
- HTTP: `provideHttpClient()` **antes** de `provideHttpClientTesting()`; `HttpTestingController`
  (`expectOne`, `match`, `expectNone`, `flush`, `verify` no `afterEach`). [C] https://angular.dev/guide/http/testing
- Harnesses do CDK (`TestbedHarnessEnvironment.loader`, `documentRootLoader`): testes desacoplados do DOM interno. [C]
  https://material.angular.dev/cdk/test-harnesses/overview
- `@defer` em teste: `DeferBlockBehavior` [NC] (não confirmado nesta coleta).
- E2E: CLI não traz framework; `ng add playwright-ng-schematics` / `@cypress/schematic` etc.; `ng e2e`. [C] skill
  oficial `e2e-testing.md` (MIT, Google).

## 16. CLI, build, lint, migrações

- Builder padrão `@angular/build:application` (esbuild; dev server Vite); saída `dist/<projeto>`. [C]
  https://angular.dev/tools/cli/build
- Comandos: `ng new`, `ng generate` (`component|service|guard|...`), `ng serve`, `ng build`, `ng test`, `ng e2e`,
  `ng update`, `ng add`. [C] angular.dev/cli
- `ng lint` só funciona após `ng add angular-eslint` (adiciona builder de lint). [C] https://angular.dev/cli/lint
- Schematics de migração (`ng generate @angular/core:<nome>`): `standalone`, `control-flow`, `inject-function`,
  `route-lazy-loading`, `signal-inputs`, `outputs`, `signal-queries`, `cleanup-unused-imports`, `self-closing-tags`,
  `ngclass-to-class`, `ngstyle-to-style`; também RouterTestingModule, CommonModule→imports e Injectable→Service.
  [C] https://angular.dev/reference/migrations
- MCP do CLI: `npx @angular/cli mcp` (`--read-only`, `--local-only`); ferramentas `list_projects`,
  `get_best_practices`, `search_documentation`, `run_target`, `devserver_start/stop/wait_for_build`,
  `onpush_zoneless_migration`, `ai_tutor`. Status: experimental. [C] https://angular.dev/ai/mcp, `ai`
- Validação sugerida pelo skill oficial: rodar `ng build` após gerar código. [C] skill oficial

---

## Guias e skills para agentes de IA

| Fonte | Autor | Licença | O que acrescenta |
|---|---|---|---|
| https://angular.dev/ai/develop-with-ai + `best-practices.md`, `llms.txt`, `llms-full.txt` | Angular (Google) | Docs angular.dev: CC BY 4.0 (conteúdo), código MIT; arquivo `best-practices.md` sem cabeçalho de licença | Regras curtas e atualizadas por versão (OnPush/standalone padrão, `@Service`, Signal Forms) — base ideal de fatos |
| https://github.com/angular/skills (`angular-developer`, `angular-new-app`) | Angular team / Google LLC | Repo sem LICENSE (GitHub: null); frontmatter do SKILL.md declara `MIT`; origem `angular/angular` é MIT | Estrutura SKILL + ~45 references por tema; regra "checar versão antes"; `ng build` como validação; decisão de forms; naming "intent over role" respeitando projeto existente; E2E via `ng add` |
| https://angular.dev/ai/mcp | Angular | CC BY 4.0 (doc) | Ferramentas MCP (best practices, docs, run_target, migração OnPush/zoneless) |
| https://github.com/analogjs/angular-skills | AnalogJS | MIT | **Depreciado** em favor do oficial — não usar |
| https://github.com/alfredoperez/angular-best-practices | Alfredo Perez | Repo sem LICENSE; `plugin.json` declara MIT (ambíguo) | ~112 regras curtas com impacto, plugin Claude; útil como checklist de inspiração |
| https://github.com/Mindrally/skills (`angular/`, `angular-development/`) | Mindrally | Apache-2.0 | Skills genéricas; menor valor (qualidade não verificada) |
| https://github.com/PatrickJS/awesome-cursorrules (`rules/angular-*.mdc`) | PatrickJS + comunidade | CC0-1.0 | Regras Cursor comunitárias, frequentemente desatualizadas (NgModule/constructor) |

## Tabela de fontes

| URL | Tipo | Licença | Uso permitido |
|---|---|---|---|
| https://angular.dev/reference/releases (`rel`) | Oficial | CC BY 4.0 | fatos |
| https://angular.dev/assets/context/best-practices.md (`bp`) | Oficial | sem cabeçalho; site CC BY 4.0 | fatos/inspiração |
| https://angular.dev/ai/develop-with-ai (`ai`) | Oficial | CC BY 4.0 | fatos |
| https://angular.dev/style-guide (`sg`) | Oficial | CC BY 4.0 | fatos |
| https://angular.dev/best-practices/security (`sec`) | Oficial | CC BY 4.0 | fatos |
| https://angular.dev/best-practices/a11y | Oficial | CC BY 4.0 | fatos |
| https://angular.dev/guide/zoneless (`zl`) | Oficial | CC BY 4.0 | fatos |
| https://angular.dev/guide/testing (`tst`), /karma, /migrating-to-vitest | Oficial | CC BY 4.0 | fatos |
| https://angular.dev/guide/http/interceptors, /http-resource, /testing | Oficial | CC BY 4.0 | fatos |
| https://angular.dev/guide/signals/effect, /ecosystem/rxjs-interop | Oficial | CC BY 4.0 | fatos |
| https://angular.dev/guide/components/inputs | Oficial | CC BY 4.0 | fatos |
| https://angular.dev/guide/templates/defer, /guide/incremental-hydration | Oficial | CC BY 4.0 | fatos |
| https://angular.dev/guide/forms/signals/overview | Oficial | CC BY 4.0 | fatos |
| https://angular.dev/guide/di/creating-and-using-services | Oficial | CC BY 4.0 | fatos |
| https://angular.dev/guide/routing/route-guards | Oficial | CC BY 4.0 | fatos |
| https://angular.dev/guide/image-optimization | Oficial | CC BY 4.0 | fatos |
| https://angular.dev/guide/aria/overview | Oficial | CC BY 4.0 | fatos |
| https://angular.dev/tools/cli/build, /cli/lint, /reference/migrations, /ai/mcp | Oficial | CC BY 4.0 | fatos |
| https://material.angular.dev/cdk/test-harnesses/overview | Oficial | CC BY 4.0 (presumido, mesmo projeto) [NC] | fatos |
| https://blog.angular.dev/announcing-angular-v22-c52bb83a4664 (`blog22`) | Oficial (403 no fetch; lido via resumo de busca) | não informada | fatos |
| https://github.com/angular/skills | Oficial | MIT (frontmatter); sem LICENSE no repo | fatos/inspiração |
| https://blog.ninja-squad.com/2026/06/03/what-is-new-angular-22.0 (`ns22`) | Terceiro | não informada | fatos a confirmar |
| Repos comunitários (tabela acima) | Terceiros | ver tabela | inspiração |

Licença CC BY 4.0 das docs angular.dev: declarada na página agent-skills (rodapé do site). Mesmo assim, usar
apenas fatos e texto próprio, sem transcrever trechos.

## Armadilhas comuns

- `subscribe()` manual sem cancelamento → vazamento; usar `toSignal`, `async` pipe ou `takeUntilDestroyed()`.
- `effect()` para copiar/derivar estado → loops e re-render; usar `computed`/`linkedSignal`.
- `toSignal` chamado várias vezes para o mesmo observable (várias assinaturas) ou fora do contexto de injeção.
- Lógica, chamadas de método caras ou `new Date()` no template → mover para `computed`/pipe puro.
- `any` em respostas HTTP → tipar e validar (`parse` no `httpResource`, schema).
- `@for` com `track $index` em lista que muda → recriação de DOM e perda de estado; usar id.
- Mutar objeto/array dentro do sinal (ou usar `mutate`) → OnPush/zoneless não detecta; criar nova referência com `update`.
- Código dependente de Zone (`setTimeout` esperando CD, `NgZone.onStable`) quebra em zoneless/OnPush (padrões v21/v22).
- Gerar código legado: NgModule, `standalone: true`, `*ngIf/*ngFor`, `@Input/@Output`, injeção por construtor,
  `ngClass/ngStyle`, `CommonModule`, `@HostBinding`.
- `httpResource` para POST/PUT → usar `HttpClient` em mutações.
- Interceptor de classe com `withInterceptorsFromDi` → ordem imprevisível; usar funcional.
- Guard como única proteção de acesso → autorização no backend.
- `bypassSecurityTrust*` ou `innerHTML` com dado do usuário → XSS.
- `provideHttpClientTesting()` antes de `provideHttpClient()` → testes quebram.
- `@defer` no conteúdo acima da dobra → CLS; dependência referenciada fora do bloco → não é adiada.
- `NgOptimizedImage` sem dimensões ou sem `priority` na LCP; imagem base64 inline não suportada.
- Impor nomes sem sufixo (v20+) em projeto que usa `.component.ts` → seguir a convenção existente.
- Assumir que `ng lint` funciona sem `angular-eslint` instalado.
- Aplicar práticas de v22 em projeto de versão anterior (Signal Forms, `@Service`, OnPush padrão) → checar versão.
- Supor que Karma foi removido/depreciado: segue suportado; Vitest é só o padrão de projetos novos.

## Lacunas / não confirmado

- Detalhes v22 vindos só de `ns22`: `injectAsync`, fetch padrão, `strictTemplates` padrão, mudanças de router,
  `migrate-karma-to-vitest`, TS 6/Node. Confirmar no changelog oficial antes de citar como fato.
- Página do anúncio v22 bloqueou fetch (403); conteúdo obtido via resultado de busca.
- `DeferBlockBehavior` e `FocusMonitor` não verificados nesta coleta.
