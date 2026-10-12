# React Native com Expo

Referência específica da stack. Princípios gerais: [SKILL.md](../SKILL.md).

## Versão

Expo e React Native mudam rápido. Citar no relato a versão do `## Stack` do projeto
(por exemplo, Expo SDK e React Native) e usar a documentação dessa versão
(`docs.expo.dev`, `reactnative.dev`). Conferido em 2026-10-11: a documentação "latest" do Expo
listava o SDK 57 com React Native 0.86; o projeto pode estar em outra versão, e ela prevalece.
Instalar dependências nativas com `npx expo install <pacote>` (escolhe a versão compatível com o SDK).
Comandos abaixo são ilustrativos; os reais são os do `CLAUDE.md`.

## Estrutura (Expo Router)

- Rotas por arquivo em `app/` (ou `src/app/`, conforme o projeto): `index.tsx` é a raiz do diretório,
  `_layout.tsx` envolve as rotas filhas, `(grupo)/` agrupa sem alterar a URL, `[id].tsx` é rota dinâmica.
- Todo arquivo dentro de `app/` vira rota: componentes, hooks e utilitários ficam fora
  (`components/`, `hooks/`, `lib/`).
- O `_layout.tsx` raiz concentra provedores, fontes, tema e splash screen.
- Arquivos por plataforma: sufixo `.native.tsx`, `.ios.tsx`, `.android.tsx`, `.web.tsx`.
- Configuração em `app.json`/`app.config.ts`; esquema de deep link em `scheme`.

## Navegação

- Navegar por rotas tipadas quando o projeto habilitar `typedRoutes`; não montar caminhos por concatenação
  de texto externo.
- Validar parâmetros de rota (`useLocalSearchParams`) antes de usar: vêm como texto e podem ser forjados
  por deep link.
- Proteger rotas autenticadas no layout (redirecionar sem sessão), sem tratar isso como segurança:
  a autorização real é do backend.

## Estado

- Estado de servidor (cache, revalidação) separado do estado de UI; usar a biblioteca já adotada no projeto.
- Estado de UI no menor escopo (`useState`/`useReducer`); contexto ou store global só com consumidores comuns.
- Persistência: dados comuns em armazenamento assíncrono do projeto; segredos só em `expo-secure-store`.

## Acessibilidade

- Elementos interativos com `accessibilityRole`, `accessibilityLabel` e `accessibilityState` quando o
  componente nativo não os fornece; `accessible` para agrupar.
- Alvos de toque mínimos (44 pt / 48 dp), `hitSlop` quando o visual for menor.
- Respeitar fonte do sistema (`allowFontScaling`), modo escuro (`useColorScheme`) e redução de movimento.
- Anunciar mudanças relevantes (`AccessibilityInfo.announceForAccessibility`).
- Testar por papel e rótulo (`getByRole`, `getByLabelText`).

## Permissões

- Cada módulo (câmera, localização, notificações, etc.) expõe `request...PermissionsAsync` e
  `get...PermissionsAsync`: consultar antes, pedir sob demanda, tratar `canAskAgain === false`
  levando o usuário às configurações (`Linking.openSettings()`).
- Textos de uso (iOS) e permissões (Android) declarados no `app.json`/config plugin de cada módulo,
  somente os necessários.
- Alterar permissões nativas exige novo build (não vai por update OTA).

## Segredos e `expo-secure-store`

- `npx expo install expo-secure-store`; API: `setItemAsync`, `getItemAsync`, `deleteItemAsync`
  (preferir as assíncronas; as síncronas bloqueiam a thread JS). Chaves aceitam letras, números, `.`, `-`, `_`.
- Usar para tokens e credenciais; apagar no logout. `requireAuthentication` exige biometria/senha do
  aparelho e só se testa em dispositivo real (não em Expo Go nem emulador); a leitura retorna `null`
  se a biometria cadastrada mudar: tratar como sessão expirada.
- Valores grandes: a documentação alerta que algumas versões do iOS recusam valores acima de cerca de
  2048 bytes; tratar o erro e não guardar blobs.
- Android: excluir o SecureStore do backup automático; iOS: o valor pode sobreviver à reinstalação,
  não depender disso. Não é a única cópia de dado crítico.
- Variáveis `EXPO_PUBLIC_*` vão para o bundle e são públicas: nunca colocar segredo nelas.

## Listas

- `FlatList` (ou `SectionList`) para listas longas, com `keyExtractor` estável, `renderItem` memoizado
  e `getItemLayout` quando a altura for fixa; evitar funções anônimas e objetos novos por item.
- `@shopify/flash-list` (`FlashList`) quando o perfil mostrar gargalo em listas grandes; instalar com
  `npx expo install`, seguir a documentação da versão e medir antes e depois.
- Nunca `ScrollView` com `map` para listas de tamanho ilimitado.

## Testes

- Unitário e componentes: Jest com preset `jest-expo` e React Native Testing Library
  (`@testing-library/react-native`).
  - Instalação ilustrativa: `npx expo install jest-expo jest @types/jest --dev` e
    `npx expo install @testing-library/react-native --dev` (no Windows, `--` antes de `--dev`).
  - `package.json`: `"jest": { "preset": "jest-expo" }` e script `"test": "jest"` (o template do Expo não o traz). Nas versões recentes da RNTL, `render` é assíncrono: `await render(...)` (conferir a versão do projeto).
  - `react-test-renderer` está obsoleto (não suporta React 19+): não usar.
- Simular módulos nativos (secure store, permissões, rede) com `jest.mock`; sem segredo real nos testes.
- Consultar por papel/rótulo; estados de loading, erro, vazio e sucesso por tela.
- Rastreabilidade: `describe('req001 ...')` ou arquivo `req001.test.tsx`, conforme o projeto.
- E2E (opcional; só quando o TechLead delegar): Maestro (fluxos em YAML) ou Detox; exigem build de
  desenvolvimento/simulador. Seguir a documentação da ferramenta adotada no `CLAUDE.md`.

## Build e publicação (EAS)

- EAS CLI: `npx eas-cli@<versão>` com versão fixada (conferir a versão atual no npm antes de fixar; preferir
  `cli.version` no `eas.json` ou devDependency do projeto; evitar `@latest`).
- Build: `eas build:configure`, depois `eas build --platform android|ios|all`; perfis
  (`development`, `preview`, `production`) em `eas.json`. Acompanhar com `eas build:list`.
- Cliente de desenvolvimento: `npx expo install expo-dev-client`.
- EAS Update (OTA, só JavaScript e assets): `eas update:configure`, canal no perfil do `eas.json` e
  `eas update --channel <canal> --message "<mensagem>"`; nas versões recentes do SDK o `--environment`
  é obrigatório (conferir a doc da versão do projeto). Update só chega a builds com o mesmo
  `runtimeVersion`: mudança em código nativo, permissões ou dependências nativas exige novo build.
- Segredos de build (chaves de assinatura, tokens): variáveis/segredos do EAS, nunca em `eas.json`,
  `app.json` ou no repositório.
- `eas login`, `eas build`, `eas update` (publicação OTA para usuários) e `eas submit`, além da publicação em lojas e
  do envio de builds, exigem decisão explícita do usuário: o agente não os executa por conta própria.
