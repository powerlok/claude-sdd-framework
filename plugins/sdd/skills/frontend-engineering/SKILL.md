---
name: frontend-engineering
description: Princípios de engenharia frontend agnósticos de framework (componentização, estado, contratos tipados, acessibilidade WCAG 2.2 AA, performance, design visual, segurança, testes). Usar ao implementar, revisar ou testar interfaces web; a stack vem do CLAUDE.md do projeto e a referência específica fica em references/.
---

# Engenharia Frontend

Princípios válidos para qualquer framework. A stack do projeto vem da seção
`## Stack` do `CLAUDE.md` ou da delegação; comandos de build, lint e testes
são sempre os reais do `CLAUDE.md`.

## Como escolher a referência

Ler somente a referência da stack informada.

| Stack | Referência | Quando ler |
|---|---|---|
| React (Vite ou similar) | [react.md](references/react.md) | Implementar, otimizar ou testar componentes React |
| Qualquer (revisão de interface) | [web-interface.md](references/web-interface.md) | Revisar UI: acessibilidade, foco, formulários, estados, responsividade |
| Angular | [angular.md](references/angular.md) | Implementar, otimizar ou testar componentes Angular (identificar a versão do projeto primeiro) |

Stack sem referência: seguir as convenções já presentes no código e declarar a lacuna.

## Componentização

- Um componente, uma responsabilidade; compor em vez de herdar.
- Separar apresentação (sem efeito colateral) de orquestração (dados, navegação).
- Extrair lógica reutilizável em unidades próprias do framework (hook, serviço, composable), nunca copiar.
- Não criar abstração antes de existir o segundo uso real (YAGNI).

## Estado

- Manter o estado no menor escopo possível; subir somente quando houver consumidor comum.
- Separar estado de servidor (cache de dados remotos) de estado de UI (modal aberto, filtro).
- Não guardar estado derivado: calcular a partir da fonte.
- Regra de negócio fica no backend; o frontend valida só para UX e nunca decide sozinho.

## Contratos tipados

- Tipar explicitamente props/inputs, respostas de API e eventos nas fronteiras.
- Proibido `any` quando houver alternativa tipada.
- Não inventar contratos de API: usar a spec/OpenAPI existente; se faltar, pedir ao TecLeader.
- Tratar respostas externas como não confiáveis: validar o formato antes de usar.

## Estados de UX obrigatórios

Toda tela ou componente com dados trata: carregando, erro (com ação de recuperação),
vazio (com convite à ação), sucesso (confirmação) e dados parciais.
Detalhes no checklist de [web-interface.md](references/web-interface.md).

## Acessibilidade (WCAG 2.2 AA)

- HTML semântico primeiro; ARIA só quando o elemento nativo não resolve.
- Tudo operável por teclado, com ordem de foco lógica e foco visível.
- Contraste mínimo 4.5:1 para texto normal e 3:1 para texto grande e componentes de UI.
- Alvos de toque/clique com pelo menos 24x24 px (WCAG 2.2, 2.5.8).
- Toda imagem informativa tem alternativa textual; todo campo tem rótulo associado.
- Mudanças dinâmicas importantes (erro, resultado) são anunciadas a leitores de tela.
- Respeitar preferências do usuário: movimento reduzido, zoom e tamanho de fonte.

## Performance e Core Web Vitals

- Medir antes de otimizar (perfil do navegador, relatório de bundle, Lighthouse).
- Metas de referência: LCP até 2,5 s, INP até 200 ms, CLS até 0,1.
- Reduzir JS inicial: dividir por rota, carregar sob demanda o que não é crítico.
- Evitar cascatas de requisições: paralelizar o que é independente.
- Reservar espaço para imagens e conteúdo assíncrono (evita deslocamento de layout).
- Listas longas: paginar ou virtualizar.

## Design visual

Quando o projeto não impõe um design system, tratar a interface como direção de design
deliberada, não como padrão genérico.

- Identificar o assunto, o público e a tarefa principal antes de desenhar; as escolhas
  visuais nascem do domínio real do produto.
- Tipografia carrega a personalidade: uma ou duas famílias, escala definida,
  linhas com menos de 80 caracteres, mais entrelinha em fontes com serifa.
- Estrutura visual é informação: bordas, numeração e divisores só quando codificam algo
  (numerar apenas sequências reais).
- Movimento não pedido pelo usuário: pouco e com intenção, um momento orquestrado vale mais
  que efeitos espalhados. Movimento que responde a uma ação é bem-vindo.
- Evitar sinais de página genérica: fundo creme com serifa e acento terracota, fundo
  quase preto com um acento vivo, tudo em cartões idênticos com a mesma sombra,
  rótulos em caixa alta sobre todo título, setas anexadas a todo link.
- Processo: esboçar tokens (4 a 6 cores nomeadas, papéis tipográficos, conceito de layout),
  revisar contra o briefing, só então codar. Se o briefing definir a direção visual,
  ela prevalece.
- Gastar ousadia em um ponto; o resto fica discreto. Cortar o que não serve ao briefing.
- Cuidar da especificidade de seletores CSS para que regras não se anulem.
- Texto de interface: voz ativa, verbos claros ("Salvar alterações", não "Enviar"),
  mesmo nome para a mesma ação em todo o fluxo, erros que dizem o que houve e como corrigir,
  vazio como convite à ação.
- Piso de qualidade: responsivo até mobile, foco visível, movimento reduzido respeitado.

## Segurança

- Nunca inserir HTML não confiável no DOM; usar o escape padrão do framework.
  APIs de HTML bruto (por exemplo `innerHTML` e equivalentes) só com sanitização aprovada.
- Sanitizar e validar toda entrada do usuário e dado externo antes de renderizar.
- Validar URLs dinâmicas (permitir apenas esquemas esperados) antes de usar em `href`/`src`.
- Configurar CSP restritiva (sem `unsafe-inline` quando possível) e evitar `eval`.
- Nunca colocar segredos, tokens ou credenciais no bundle, em logs ou no armazenamento do navegador sem decisão explícita.
- Variáveis de ambiente expostas ao cliente são públicas por definição.
- Dependências novas exigem justificativa e revisão de segurança.

## Testes

- Componente: renderização por estado (carregando, erro, vazio, sucesso), por papel/rótulo acessível, não por detalhe de implementação.
- Interação: teclado e mouse, formulários, validação, navegação.
- E2E: somente quando o TecLeader delegar; cobrir o fluxo principal da feature.
- Rastreabilidade: REQ-001 vira teste `req001` (arquivo ou nome do caso), seguindo a
  convenção de nomes da stack.
- Todo defeito corrigido ganha teste de regressão.
- Ferramentas e comandos: os do `CLAUDE.md`; os exemplos de referências são ilustrativos.

## Atribuição

Seção de design visual adaptada de frontend-design (Anthropic), Apache-2.0.
Texto da licença: [LICENSE-frontend-design.txt](LICENSE-frontend-design.txt).
Alterações: condensado, traduzido para pt-BR e integrado aos demais princípios.
