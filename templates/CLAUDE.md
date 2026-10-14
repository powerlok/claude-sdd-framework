# CLAUDE.md — <NOME_DO_PROJETO>

> Modelo de `CLAUDE.md` de projeto para uso com o plugin `sdd`.
> Não inventar: preencher somente com informação verificada (código, arquivos de
> configuração, comandos executados). O que não for conhecido fica como `<A DEFINIR>`.
> Remover este bloco de instruções após o preenchimento.

## Visão do projeto

- Objetivo: <O QUE O PROJETO FAZ E PARA QUEM>
- Escopo atual: <FUNCIONALIDADES EXISTENTES>
- Especificações: `.specs/<feature>/spec.md` e `tasks.md`

## Stack

Fonte da stack para os agentes `sdd:backend`, `sdd:frontend`, `sdd:mobile` e `sdd:infra-architect`.

### Backend

- Linguagem e versão: <EX.: LINGUAGEM X.Y>
- Framework e versão: <FRAMEWORK X.Y>
- Gerenciador de pacotes/build: <GERENCIADOR>
- Banco de dados: <BANCO E VERSÃO | NÃO SE APLICA>
- Referência do plugin: `backend-engineering/references/<stack>.md` <OU "SEM REFERÊNCIA">

### Frontend

- Linguagem e versão: <LINGUAGEM X.Y>
- Framework e versão: <FRAMEWORK X.Y>
- Gerenciador de pacotes/build: <GERENCIADOR>
- Referência do plugin: `frontend-engineering/references/<stack>.md` <OU "SEM REFERÊNCIA">

### Mobile

Opcional. Remover se o projeto não tem app mobile.

- Plataforma: <REACT NATIVE COM EXPO | FLUTTER | SWIFT | KOTLIN>
- Linguagem e versão: <LINGUAGEM X.Y>
- Framework e versão: <EX.: EXPO SDK NN>
- Gerenciador de pacotes/build: <GERENCIADOR>
- Referência do plugin: `mobile-engineering/references/<stack>.md` <OU "SEM REFERÊNCIA">

### Infra

- Nuvem/infra: <AWS | Azure | Google Cloud | on-prem>; referência `infra-engineering/references/<nuvem>.md` <OU "SEM REFERÊNCIA">

## Comandos

Registrar apenas comandos executados com sucesso neste projeto.

| Ação | Comando |
|---|---|
| Instalar dependências | `<COMANDO>` |
| Build | `<COMANDO>` |
| Lint | `<COMANDO>` |
| Testes | `<COMANDO>` |
| Teste único | `<COMANDO> <ARQUIVO_OU_FILTRO>` |
| E2E | `<COMANDO>` |
| Executar | `<COMANDO>` |
| Porta / URL | `<http://localhost:PORTA>` |

## Arquitetura

<RESUMO DAS CAMADAS, MÓDULOS E INTEGRAÇÕES>

```text
<ÁRVORE DE PASTAS RELEVANTES COM A RESPONSABILIDADE DE CADA UMA>
```

## Repositório

Opcional. Somente leitura (issue → spec; status de PR/CI como evidência).
Se o projeto não usa integração com o provedor de código, remover esta seção inteira:
sem ela, o `sdd:techlead` não consulta nenhum provedor.

- Provedor: <github | bitbucket | gitlab | azure-devops>
- Repositório: <owner/repo | workspace/repo | group/project | org/project/repo>
- Acesso: <mcp (padrão, recomendado) | cli (não recomendado: usa o login do `gh`/`glab`/`az`, que costuma ter escrita; só com token somente leitura, ex.: `GH_TOKEN` = PAT fine-grained read-only)>

## Git

Opcional. Habilita o fluxo Git do `sdd:techlead` (branch e commit local, sempre com confirmação). Sem esta seção,
nenhuma branch nem commit é criado. O idioma é perguntado no onboarding; para alterar depois: `/sdd:git-lang pt|en`.

```text
Modelo: trunk-based
Branch: <tipo>/<ISSUE>-<slug>   (sem issue: <tipo>/<slug>)
Commits: Conventional Commits
Idioma: pt | en
```

## Regras específicas do projeto

Complementam as regras do plugin `sdd` e prevalecem sobre elas quando mais específicas.
Não podem relaxar: segredos/credenciais, verificação SSL, confirmação de ações irreversíveis,
Jira somente leitura e menor privilégio.

- <REGRA>

## Compact instructions

Orienta o resumo quando a conversa é compactada (`/compact` ou automática). Ajuste ao projeto.

```text
Ao compactar, preserve: a spec ativa (`.specs/<feature>/`) e os REQs em andamento, o estado de cada task (TODO a DONE), as decisões tomadas e o porquê,
os arquivos alterados, os testes executados e o resultado, os comandos reais de build/teste e as pendências. Descarte saídas longas de ferramentas e logs.
```

## SDD

Opções do processo SDD neste projeto (ausente = padrão).

- Arquivar specs concluídas: sim (padrão) | não
- Versionar artefatos SDD: sim (padrão) | não
  (`não`: `.claude/settings.local.json` + exclude (`git rev-parse --git-path info/exclude`) com `/CLAUDE.md`, `/.specs/`, `/.claude/`; `.gitignore` intocado)
