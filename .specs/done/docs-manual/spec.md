# Spec: Documentação atualizada e manual de uso

Pedido do usuário (2026-10-09): "atualize as documentações do projeto e faça um manual de uso
com vários exemplos. Crie um template bem legal".
Público: devs do time que vão instalar e usar o plugin `sdd` em seus projetos (qualquer stack).

## Requisitos

- **REQ-001**: Manual de uso `engineering-workflow/docs/manual-de-uso.html`: arquivo único, offline
  (sem CDN, fontes ou scripts externos), visual caprichado, navegação lateral, busca simples,
  modo claro/escuro, botões de copiar comandos, responsivo e acessível.
- **REQ-002**: O manual tem ao menos 10 exemplos passo a passo (pedido → o que o TecLeader faz →
  o que você responde → resultado), cobrindo: instalação local, instalação Bitbucket, projeto novo
  (onboarding), feature em projeto existente, bug com regressão, backend .NET, backend Python,
  frontend React, revisão de segurança, Jira, retomar após compact, stack sem referência,
  atualização do plugin, criar skill/agente com `authoring`.
- **REQ-003**: Conteúdo verificado: só comandos e comportamentos confirmados
  (README, spike-result.md, validation/*.md, validation-report.md). Exemplos ilustrativos marcados.
- **REQ-004**: `engineering-workflow/docs/arquitetura.md` (Markdown): arquitetura do plugin
  (componentes, fluxo SDD, agentes e ferramentas, skills e references, carregamento, hooks,
  segurança, limitações) — atualizada a partir de `workshop/docs/arquitetura-de-agentes.md`.
- **REQ-005**: Documentos do workspace atualizados para o plugin: `workshop/docs/arquitetura-de-agentes.md`
  e `workshop/docs/como-usar-os-agentes.md` (nomes `sdd:`, stack agnóstica, caminhos atuais, links
  para o manual); `engineering-workflow/README.md` com seção "Documentação".

## Critérios de aceite

- REQ-001: abre via `file://` sem nenhuma requisição externa; sem erros no console; sem rolagem
  horizontal em 320px; navegação por teclado; contraste adequado; copiar funciona.
- REQ-002: ≥ 10 exemplos, cada um com os 4 blocos.
- REQ-003: todo comando do manual existe no README/relatórios; nenhum fato inventado.
- REQ-004/005: nenhuma menção a `*.agent.md`, `.claude/rules/global.md`, `"agent": "tecleader"`
  (sem prefixo) ou stack fixa nos docs atualizados; todos os links relativos resolvem.

## Validação

- Agente `tests`: Playwright (do `app-workshop`) abrindo o HTML via `file://`: requisições externas = 0,
  console sem erros, 320px sem overflow, Tab percorre a navegação, botão copiar.
- Checagem de links e grep de termos obsoletos.

## Fora de escopo

- `workshop/docs/arquitetura-de-agentes.pptx` (registrar como desatualizado).
