---
name: mobile-engineering
description: Princípios de engenharia mobile agnósticos de plataforma (ciclo de vida, offline, permissões, deep links, armazenamento seguro, performance, acessibilidade, testes). Usar ao implementar, revisar ou testar apps mobile; a stack vem do CLAUDE.md do projeto e a referência específica fica em references/.
---

# Engenharia Mobile

Princípios válidos para qualquer plataforma. A stack do projeto vem da seção
`## Stack` do `CLAUDE.md` ou da delegação; comandos de build, lint e testes
são sempre os reais do `CLAUDE.md`. Versões de SDK e bibliotecas mudam rápido:
usar a versão do `## Stack` e conferir a documentação oficial dela.

## Como escolher a referência

Ler somente a referência da stack informada.

| Stack | Referência | Quando ler |
|---|---|---|
| React Native com Expo | [react-native-expo.md](references/react-native-expo.md) | Implementar, otimizar, testar ou publicar app React Native/Expo |
| Flutter, Swift (iOS), Kotlin (Android) e demais | nenhuma | Seguir as convenções do código e declarar a lacuna |

Stack sem referência: seguir as convenções já presentes no código e declarar a lacuna
(o TechLead registra em `tasks.md`).

## Ciclo de vida

- O app pode ir para segundo plano ou ser encerrado a qualquer momento: persistir o que importa
  e restaurar o estado ao retomar.
- Não depender de timers ou trabalho contínuo em segundo plano; usar mecanismos da plataforma
  para tarefas agendadas e declarar o motivo.
- Liberar assinaturas, listeners e requisições ao sair da tela.

## Offline e rede instável

- Assumir rede ausente, lenta ou intermitente; toda tela com dados trata esse caso.
- Separar cache de dados remotos de estado de UI; definir validade do cache.
- Ações do usuário sem rede: enfileirar com idempotência ou informar claramente a falha.
- Timeout e nova tentativa com espera crescente; nunca repetir sem limite.
- Regra de negócio fica no backend; o app valida só para UX.

## Permissões

- Pedir sob demanda, no momento e no contexto da ação, nunca na abertura do app.
- Explicar o motivo antes do pedido do sistema; tratar recusa e "não perguntar novamente"
  com caminho alternativo e atalho para as configurações.
- Declarar somente as permissões realmente usadas (menor privilégio) e justificar os textos de uso.

## Deep links e entrada externa

- Deep link, notificação, intent e clipboard são entrada não confiável: validar esquema, host,
  parâmetros e tipos antes de navegar ou agir.
- Preferir links verificados (universal links/app links) a esquemas customizados para fluxos sensíveis.
- Nunca executar ação destrutiva ou autenticada apenas por um link, sem confirmação e sessão válida.

## Armazenamento seguro

- Segredos, tokens e credenciais só no armazenamento seguro da plataforma
  (Keychain/Keystore ou seu wrapper); nunca em armazenamento comum, bundle, variável pública ou log.
- Variáveis embutidas no app são públicas por definição: chave de API de servidor não vai no cliente.
- Dados sensíveis em cache ou banco local: minimizar, criptografar quando necessário e limpar no logout.
- Considerar backup do sistema: excluir do backup o que não deve sair do aparelho.
- TLS sempre; pinning de certificado só por decisão explícita com plano de rotação.

## Performance

- Medir antes de otimizar (profiler da plataforma, relatório de bundle).
- Listas longas: virtualizar, chaves estáveis, itens leves e sem recriação desnecessária.
- Evitar trabalho pesado na thread de UI; adiar o que não é crítico para depois da primeira renderização.
- Imagens: tamanho adequado à tela, cache e formatos eficientes.
- Tempo de inicialização e consumo de bateria e dados são requisitos, não detalhes.

## Acessibilidade

- Todo elemento interativo com rótulo e papel acessíveis para o leitor de tela (VoiceOver/TalkBack).
- Alvos de toque com pelo menos 44x44 pt (iOS) / 48x48 dp (Android); contraste mínimo 4.5:1 para texto.
- Respeitar tamanho de fonte do sistema, modo escuro e redução de movimento.
- Ordem de foco lógica; mudanças importantes (erro, resultado) anunciadas ao leitor de tela.
- Não transmitir informação só por cor.

## Estados de UX obrigatórios

Toda tela com dados trata: carregando, erro (com ação de recuperação), vazio (com convite à ação),
sucesso, dados parciais e offline. Considerar teclado e área segura.

## Testes

- Componente: renderização por estado, consulta por papel/rótulo acessível, não por detalhe de implementação.
- Interação: formulários, validação, navegação, permissões concedidas e negadas.
- Lógica e armazenamento: simular o armazenamento seguro e a rede nos testes; nunca usar segredo real.
- E2E (fluxo principal em simulador/emulador ou dispositivo): somente quando o TechLead delegar.
- Rastreabilidade: REQ-001 vira teste `req001` (arquivo ou nome do caso), seguindo a convenção da stack.
- Todo defeito corrigido ganha teste de regressão.
- Ferramentas e comandos: os do `CLAUDE.md`; os exemplos de referências são ilustrativos.
