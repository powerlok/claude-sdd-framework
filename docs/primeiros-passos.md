# Primeiros passos

Para depois de **instalar** (veja [instalacao.md](instalacao.md)): a primeira conversa com o TechLead, o primeiro pedido e como a equipe trabalha.

- [1. Primeira conversa](#1-primeira-conversa) — [projeto com código](#projeto-com-código-existente) · [projeto novo](#projeto-novo)
- [2. Primeiro pedido](#2-primeiro-pedido)
- [O que versionar](#o-que-versionar)
- [Equipe](#equipe)
- [Workspace com vários repositórios](#workspace-com-vários-repositórios)
- [Problemas comuns](#problemas-comuns)

## 1. Primeira conversa

Na raiz do projeto:

```bash
claude
```

O que acontece, na ordem:

1. **Diálogo de confiança da pasta** (só na primeira vez). Aceite: sem confiar, o plugin do projeto não carrega.
2. O sdd mostra um **aviso de início**. O Claude Code **só responde depois da sua primeira mensagem**, então digite **`/sdd:start`**.
3. A resposta vem do **TechLead** ("Sou o TechLead"), com a situação do projeto, e conduz as perguntas iniciais, **uma etapa de cada vez**. Nada é criado ou alterado sem a sua confirmação.

Instalou o plugin com a sessão já aberta? Rode `/reload-plugins` ou abra uma sessão nova.

### Projeto com código existente

O TechLead diz que há código (manifestos como `package.json`), mas não há `CLAUDE.md` nem `.specs/`, explica o que vai ler (README, manifestos, configs de build, lint, teste e CI) e o que vai criar, e pergunta **"Faço o onboarding agora?"**. Também pergunta:

- o idioma das mensagens de commit e PR (`pt` ou `en`), para a seção `## Git`;
- se ele pode publicar (push da branch, PR, release, sempre com confirmação a cada comando; o merge é seu; padrão: não);
- a **salinha dos agentes** (opcional, desligada por padrão; veja [referência](referencia.md#salinha-dos-agentes-opcional)).

Responda `sim`. Ele lê o código e pode pedir aprovação para comandos de leitura (`git status`) e testes (`npm test`): aprove. No fim cria `CLAUDE.md` (`## Stack`, comandos reais, arquitetura, convenções, `## Git`, `## SDD`) e `.specs/INDEX.md`. **Não faz commit.** Revise o `CLAUDE.md` gerado e corrija o que estiver errado antes do primeiro pedido.

### Projeto novo

O TechLead diz que a pasta não tem código e pergunta a **stack** (linguagem, framework, versão), a **nuvem** (ou "nenhuma"), as **convenções** e o **idioma** de commit/PR. Responda, por exemplo, `API REST em Python com FastAPI` (pode responder "recomendações"). Ele mostra o plano e só cria `CLAUDE.md` e `.specs/INDEX.md` depois do seu "ok".

### Confira

- a resposta começa com "Sou o TechLead" (se vier genérica, veja [Problemas comuns](#problemas-comuns));
- `/plugin`: aba **Installed** mostra o `sdd`, aba **Errors** vazia;
- `CLAUDE.md` e `.specs/INDEX.md` existem na raiz do projeto.

Prefere preencher à mão? Parta do modelo [`templates/CLAUDE.md`](../templates/CLAUDE.md); o TechLead confere o que faltar.

## 2. Primeiro pedido

Descreva o que quer, em linguagem natural:

```text
Crie um endpoint POST /todos que cadastra tarefas com título obrigatório
```

O TechLead pode fazer perguntas (framework, onde guardar os dados). Depois propõe **requisitos e critérios de aceite** (e um design técnico quando necessário) e pede a sua confirmação **antes** de implementar. Confirmado, cria `.specs/<feature>/spec.md` e `tasks.md`, delega aos especialistas (backend, frontend, testes, segurança) e só encerra a task com evidência de que funciona. Ao concluir a spec, abre o PR e entrega a URL.

**Confira:** `.specs/<feature>/` existe com `spec.md` e `tasks.md`, e o `.specs/INDEX.md` lista a feature. Mais exemplos: [manual de uso](manual-de-uso.html).

## O que versionar

Padrão (`Versionar artefatos SDD: sim`, na seção `## SDD` do `CLAUDE.md`): faça commit de `.claude/settings.json`, `CLAUDE.md` e `.specs/`. O TechLead **nunca faz commit sem a sua confirmação**.

Repositório de cliente que não aceita esses arquivos: `Versionar artefatos SDD: não`. O TechLead usa `.claude/settings.local.json` e o exclude local do git, sem tocar no `.gitignore` ([camadas do CLAUDE.md](referencia.md#camadas-do-claudemd)).

## Equipe

O `.claude/settings.json` versionado **não instala nada sozinho**. Cada dev, depois de clonar o projeto, segue o [tipo D da instalação](instalacao.md#d-projeto-que-já-usa-o-sdd): registrar o marketplace (uma vez por máquina) e `claude plugin install sdd@claude-sdd-framework --scope project` (uma vez por projeto).

## Workspace com vários repositórios

Abra o `claude` **dentro do repositório** em que vai trabalhar (é lá que ficam settings, `CLAUDE.md` e `.specs/`), não na pasta-mãe. Para trabalho em mais de um projeto: [trabalhar entre projetos](referencia.md#trabalhar-entre-projetos).

## Problemas comuns

Os de instalação (PATH, marketplace, versão, plugin desabilitado) estão em [instalacao.md](instalacao.md#problemas-comuns). Os de uso:

| Sintoma | Causa provável | Solução |
|---|---|---|
| Resposta genérica, sem "Sou o TechLead" | Plugin não instalado no projeto, pasta não confiada, ou sessão aberta antes do install | `plugin install` na raiz, aceite a confiança, `/reload-plugins` ou sessão nova |
| `/plugin` › Errors: "enabled in project settings but isn't installed here" | O settings veio pelo git, mas o plugin não foi instalado nesta máquina | `claude plugin install sdd@claude-sdd-framework --scope project` |
| A sessão abre sem o TechLead | `agent` ausente, ou `sdd:tecleader` (removido na 0.11.0) | `"agent": "sdd:techlead"` no `.claude/settings.json` e reinicie |
| Verificação de onboarding (hook) sem efeito no Windows | Git for Windows ausente (o hook usa `bash`) | Instale o Git for Windows; sem ele o TechLead faz a mesma verificação lendo os arquivos |
| `git diff` mostra o `.claude/settings.json` alterado após o install | O `plugin install` reordena as chaves | Sem mudança de conteúdo; pode commitar ou descartar |
| A salinha dos agentes não abre | Preferência desligada, sem navegador padrão ou sem Git Bash | `/sdd:office status`; se `off`, `/sdd:office on`; confira o navegador padrão |

Outros: [solução de problemas](manual-de-uso.html#problemas) no manual.
