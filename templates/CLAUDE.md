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

Fonte da stack para os agentes `sdd:backend` e `sdd:frontend`.

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

## Regras específicas do projeto

Complementam as regras do plugin `sdd` e prevalecem sobre elas quando mais específicas.
Não podem relaxar: segredos/credenciais, verificação SSL, confirmação de ações irreversíveis,
Jira somente leitura e menor privilégio.

- <REGRA>
