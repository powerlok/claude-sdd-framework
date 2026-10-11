# Spec: guia de primeiro uso (projeto do zero e código existente)

Pedido do usuário (2026-10-11): "não estou entendendo na documentação como um usuário faz para rodar a primeira vez,
com um projeto do zero ou com código. Precisa dar o passo a passo certinho para que o usuário não fique perdido."

Público: dev que nunca usou o framework (pode não conhecer plugins do Claude Code).

## Problemas no README atual (Início rápido)

Não separa projeto do zero × código existente; passo 1 mostra JSON parcial (sem deny) após dizer "a partir do
template"; parágrafo de deny/limites no meio do passo 1; passos 1 e 2 redundantes (settings já declara o marketplace;
`marketplace add` por URL ignora o `ref`); passo 3 manda preencher `CLAUDE.md` à mão (contradiz o onboarding); não
diz o que aparece (confiança da pasta, instalação, reinício) nem como verificar; não diz o que versionar.

## Fase 0 — Verificar o fluxo real (antes de escrever)

- H1: com só `.claude/settings.json` (template) no projeto, abrir `claude` → o que acontece (diálogo de confiança,
  pedido para instalar marketplace/plugin, precisa reiniciar?) — doc oficial + o que der para testar.
- H2: comandos explícitos de instalação respeitando o `ref` (sintaxe de `marketplace add` com ref/tag?).
- H3: como verificar: `claude plugin list`, `/plugin`, agente ativo (TecLeader), diagnóstico de onboarding.
- H4: primeira resposta do TecLeader em (a) pasta vazia com `git init`; (b) código existente sem `CLAUDE.md`.
- H5: pré-requisitos reais (versão do Claude Code, git com acesso ao repositório privado, Windows PATH, Git Bash para o hook).

## Requisitos (após a Fase 0)

- **REQ-001**: `docs/primeiros-passos.md`: dois caminhos (A: código existente; B: projeto do zero), passos numerados
  com "o que você vai ver" e "como conferir"; seção "Workspace com vários repositórios"; "O que versionar"
  (`Versionar artefatos SDD`); "Problemas comuns".
- **REQ-002**: README "Início rápido" enxuto (pré-requisitos, 4–5 passos, link para o guia); detalhes de deny/limites
  movidos para seção própria.
- **REQ-003**: manual (`docs/manual-de-uso.html`, seção Instalação) alinhado com os dois caminhos.
- **REQ-004**: CHANGELOG (docs). Sem mudança de plugin (sem bump; não é release por si).

## Critérios de aceite

- Um agente que só lê o guia consegue seguir os dois caminhos em projetos de teste e chega ao resultado descrito em
  cada passo (validação de usabilidade).
- Nenhum passo contradiz o comportamento verificado; linkcheck sem quebras.
