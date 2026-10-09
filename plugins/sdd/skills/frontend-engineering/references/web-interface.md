# Checklist de revisão de interface

Para revisar telas e componentes de qualquer stack. Complementa [SKILL.md](../SKILL.md).
Uso: ler o código, marcar desvios e reportar no formato `arquivo:linha — problema — correção`.
Funciona sem acesso à rede; este checklist é autocontido.

## Acessibilidade

- Elementos nativos corretos: `button` para ação, `a` para navegação, `label` para campo.
- Não usar `div`/`span` clicável; se inevitável, papel, `tabindex` e teclado completos.
- Botão só com ícone tem nome acessível (`aria-label` ou texto oculto visualmente).
- Imagem decorativa com alternativa vazia; informativa com descrição.
- Hierarquia de títulos sequencial (um `h1` por página, sem pular níveis).
- Marcos de página: `header`, `nav`, `main`, `footer`; link para pular ao conteúdo em páginas com navegação longa.
- Informação nunca só por cor: acompanhar de texto, ícone ou padrão.
- Contraste: 4.5:1 texto normal, 3:1 texto grande e bordas de controles.
- Região dinâmica (toasts, erros, resultados) anunciada com `role="status"` ou `aria-live`.
- Atributos ARIA válidos e coerentes com o papel; ARIA incorreto é pior que nenhum.
- Idioma da página declarado (`lang`).

## Foco e teclado

- Todo controle alcançável por Tab, na ordem visual.
- Foco sempre visível; não remover o contorno sem substituto equivalente.
- Preferir `:focus-visible` a `:focus` para não poluir cliques de mouse.
- Modal: foco vai para dentro ao abrir, fica preso nele, Esc fecha, foco volta ao elemento de origem.
- Menus, abas e listas compostas seguem o padrão de setas do componente equivalente.
- Atalhos não conflitam com leitores de tela e navegador.
- Sem armadilha de foco fora de modais.

## Formulários

- Todo campo com rótulo visível associado (`for`/`id` ou envolvendo o campo).
- Tipo e `autocomplete` corretos (e-mail, telefone, senha, nome) e teclado móvel apropriado (`inputmode`).
- Não bloquear colar texto.
- Erros junto ao campo, descritos em texto, ligados por `aria-describedby`, e resumo com foco no primeiro erro ao enviar.
- Validar ao sair do campo ou ao enviar, não a cada tecla antes de o usuário terminar.
- Marcar campos obrigatórios de forma textual, não só com asterisco colorido.
- Botão de envio mostra progresso e fica protegido contra duplo envio, sem perder o rótulo.
- Preservar o que o usuário digitou após erro.
- Ação destrutiva pede confirmação ou oferece desfazer.

## Estados de carregamento, erro e vazio

- Carregando: indicador ou esqueleto com a forma do conteúdo final; evitar piscar para esperas muito curtas.
- Erro: diz o que houve e como corrigir, com ação de tentar de novo; sem mensagem técnica crua.
- Vazio: explica por que está vazio e oferece a próxima ação.
- Sucesso: confirma o que aconteceu, com o mesmo nome da ação usada no botão.
- Falha parcial e sem conexão têm tratamento próprio.
- Estado de interface persistente em URL quando fizer sentido (filtros, aba, página) para permitir voltar e compartilhar.

## Responsividade e layout

- Mobile primeiro; testar de 320 px de largura até telas grandes.
- Sem rolagem horizontal inesperada; conteúdo quebra com texto longo e palavras sem espaço.
- Unidades relativas para texto; a interface aguenta zoom de 200%.
- Alvos de toque com pelo menos 24x24 px (preferir 44 px em mobile) e espaço entre eles.
- Imagens com dimensões reservadas e `srcset`/tamanhos adequados; carregamento tardio fora da primeira tela.
- Respeitar áreas seguras em dispositivos com recortes.
- Tabelas largas com estratégia explícita (rolagem contida, colunas priorizadas ou cartões).
- Evitar valores fixos de altura que cortam conteúdo.

## Animação e movimento

- Animar só `transform` e `opacity` quando possível; evitar propriedades que forçam layout.
- Respeitar `prefers-reduced-motion`: reduzir ou remover movimento não essencial.
- Duração curta (ordem de 150 a 300 ms) para respostas a ações; sem animação em loop que distraia.
- Nada pisca mais de três vezes por segundo.
- Movimento comunica mudança (abrir, confirmar), não decora.
- Animações interrompíveis; não bloquear a interação enquanto rodam.

## Conteúdo e texto

- Rótulos de ação em voz ativa e específicos ("Salvar alterações").
- Terminologia consistente em todo o fluxo.
- Textos truncados oferecem forma de ver o conteúdo completo.
- Números, datas e moedas formatados pelo locale do usuário, não à mão.
- Textos no código preparados para tradução quando o produto for multilíngue.
- Título da página e do documento descrevem a tela atual e mudam na navegação.
- Links descrevem o destino; evitar "clique aqui".

## Performance percebida

- Nada de salto de layout quando o conteúdo carrega.
- Primeira tela renderiza sem esperar recursos não críticos.
- Fontes com estratégia de exibição que evite texto invisível.
- Resposta imediata ao toque/clique (estado ativo ou otimista) antes da resposta do servidor.

## Segurança na interface

- Nenhum HTML não confiável injetado sem sanitização.
- Links externos abertos em nova aba com `rel="noopener noreferrer"`.
- Nenhum segredo ou token visível no código cliente, em logs ou no DOM.

---

Texto próprio; inspirado em vercel-labs/web-interface-guidelines@434b7f9 (MIT)
