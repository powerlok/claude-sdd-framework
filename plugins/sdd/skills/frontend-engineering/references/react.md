# Referência React (SPA)

Complementa os princípios de [SKILL.md](../SKILL.md). Vale para SPA em React
(sem renderização no servidor). Comandos abaixo são exemplos; usar os comandos
reais do `CLAUDE.md` do projeto. Ferramentas citadas (Vite, Vitest, Jest,
Playwright, React Query, Zustand) são exemplos; seguir as já adotadas no projeto.

## Estrutura

- Organizar por feature (`features/<nome>/` com componentes, hooks, api, testes), com
  `shared/` para o que é realmente comum.
- Um componente por arquivo, nome em PascalCase; hooks começam com `use`.
- Tipos de props e de resposta de API ficam explícitos e exportados na fronteira da feature.
- Importar direto do arquivo, não por arquivos barrel grandes (reduz o bundle e o tempo de build).

## Componentes e hooks

- Componentes de função; props tipadas com TypeScript; sem `any`.
- Nunca declarar componente dentro de outro componente (remonta a cada render).
- Hooks só no nível superior; efeitos para sincronizar com o mundo externo, não para derivar estado.
- Efeito que só responde a ação do usuário deve virar manipulador de evento.
- Listas com `key` estável e única (id do dado, não o índice, se a lista muda).
- Renderização condicional explícita (`cond ? <A /> : null`) para evitar renderizar `0` ou texto indesejado.
- Dependências de efeito e memoização completas; objetos e funções recriados a cada render
  não entram como dependência sem `useMemo`/`useCallback` quando causarem repetição.

## Estado

| Tipo | Ferramenta típica | Regra |
|---|---|---|
| Local de UI | `useState`/`useReducer` | Mais próximo possível de quem usa |
| Compartilhado de UI | Context ou store (ex.: Zustand) | Selecionar fatias (`useStore(s => s.x)`) para limitar re-render |
| Servidor | Biblioteca de cache (ex.: React Query) | Não copiar dado remoto para estado local |

- Estado derivado: calcular durante o render (ou `useMemo` se custar caro), não em `useEffect` + `setState`.
- Atualização baseada no valor anterior: forma funcional `setX(prev => ...)`.
- Valor inicial caro: inicialização preguiçosa `useState(() => compute())`.
- Valor que muda sem precisar renderizar (timers, último evento): `useRef`.

## Dados remotos (exemplo com React Query)

- Reutilizar a mesma `queryKey` em todos os componentes: requisições em voo são deduplicadas
  e o cache é compartilhado.
- Definir `staleTime` coerente com a volatilidade do dado.
- Extrair hook ou `queryOptions` por recurso para manter a chave única.
- Mutação com `useMutation` e `invalidateQueries` ao concluir.
- Tratar sempre os quatro estados: carregando, erro, vazio, sucesso.

## Performance

Medir primeiro (React DevTools Profiler, relatório de bundle, Lighthouse). Só então aplicar.

Cascatas de requisições
- Independentes em paralelo com `Promise.all`; dependentes encadeados sem bloquear o que não depende.
- Adiar `await` até o ponto em que o resultado é necessário; checar condições baratas antes de aguardar.

Bundle
- Dividir por rota e por recurso pesado: `React.lazy(() => import('./Heavy'))` com `<Suspense fallback={...}>`.
- Carregar bibliotecas de terceiros não críticas (analytics, editores) depois da interação ou do primeiro render.
- Pré-carregar o módulo ao sinal de intenção (hover, foco) quando a navegação for provável.
- Import dinâmico com caminho analisável (evitar caminho totalmente calculado em tempo de execução).

Re-render
- Não criar objetos/arrays/funções literais como props de componente memoizado sem estabilizar.
- `React.memo` só em componente caro que recebe props estáveis; extrair valores padrão para constantes fora do componente.
- Separar hooks que combinam dados com ritmos de mudança diferentes.
- Atualizações não urgentes (filtro, busca): `useTransition` ou `useDeferredValue`.
- Ler valores voláteis (ex.: posição de scroll) somente onde são usados, ou via ref.
- Expressão simples e barata não precisa de `useMemo`.

Renderização
- Listas longas: paginar ou virtualizar; `content-visibility: auto` para seções fora da tela.
- Elevar JSX estático para fora do componente.
- Animar SVG pelo wrapper, não pelo elemento interno; reduzir precisão numérica de SVG gerado.
- `Activity`/ocultação para preservar estado de telas escondidas, quando disponível na versão usada.

Eventos e armazenamento
- Listeners de scroll/touch com `{ passive: true }` quando não chamam `preventDefault`.
- Um listener global compartilhado (módulo com `Map` de callbacks) em vez de um por componente.
- Dados em `localStorage` com versão/esquema e tratamento de falha de parse; ler uma vez e guardar em cache.

JavaScript
- Índices com `Map`/`Set` em vez de busca linear repetida; sair cedo de laços; combinar iterações.
- Não ordenar com mutação em estado: usar `toSorted`/cópia.
- Hoist de `RegExp` constante para fora de funções chamadas com frequência.
- Trabalho não crítico em `requestIdleCallback`; agrupar leituras e escritas de DOM.

## Testes

- Componente e interação: Testing Library com Vitest ou Jest; consultar por papel/rótulo
  (`getByRole`, `getByLabelText`), simular o usuário com `user-event`.
- Hooks: testar via componente de teste ou `renderHook`.
- Rede: simular na fronteira (ex.: MSW) em vez de mockar o componente.
- E2E (somente se delegado): Playwright, fluxo principal da feature, seletores por papel.
- Rastreabilidade: REQ-001 em `req001` (ex.: `req001.test.tsx` ou `describe('REQ-001 ...')`
  e, em E2E, `req001.spec.ts`).
- Cada teste cobre os estados: carregando, erro, vazio, sucesso.

## Build e validação (exemplos; usar os comandos reais do CLAUDE.md)

```text
npm run lint
npm run test
npm run build      # exemplo com Vite
npm run e2e        # exemplo com Playwright, se delegado
```

- Variáveis expostas ao cliente (prefixo `VITE_` no Vite) são públicas: nunca colocar segredos.
- Verificar o tamanho do bundle após adicionar dependência.
- Falha de build ou teste: reportar comando, saída real e causa; não mascarar.
