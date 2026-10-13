# Parecer de segurança: publish-opt-in (sdd 0.9.2)

Revisor: papel `sdd:security`, independente, somente leitura. Data: 2026-10-13.
Revisado: `spec.md`, `design.md`, `templates/project-settings.git.json`, `plugins/sdd/agents/techlead.md`
(deny exigido, migração, Git, Repositório), `plugins/sdd/skills/sdd-rules/references/git-workflow.md`,
`plugins/sdd/agents/security.md`. Nenhum comando de modificação executado.

## Parecer final: APROVADO COM CONDIÇÕES

A spec não pode ser implementada como está. As condições C1 a C4 (achados HIGH) bloqueiam a implementação;
C5 a C10 devem entrar na spec antes do `DONE`.

## Fonte da documentação oficial (consultada em 2026-10-13, code.claude.com/docs/en/permissions)

Verificado:
- Ordem de avaliação: deny, depois ask, depois allow; o primeiro que casa decide. Allow não abre exceção em deny nem em ask.
- Precedência entre escopos: "se uma ferramenta é negada em qualquer nível, nenhum outro nível pode permiti-la".
  Managed é o mais alto. O ask do escopo local, portanto, nunca "libera" um deny do `settings.json` do projeto (confirma o design 2).
- Regras de deny e ask valem para qualquer subcomando de comando composto (`&&`, `$(...)`, subshell, `for`), inclusive em auto mode.
- Wrappers removidos antes de casar: `timeout`, `time`, `nice`, `nohup`, `stdbuf`, `command`, `builtin`, `noglob`.
- Limite documentado: regra Bash "não é fronteira de segurança". `Bash(git push *)` não pega `git -C . push`, `git -c ... push`,
  `git 'push'`; `Bash(curl *)` não pega `/usr/bin/curl` nem `sh -c '...'`. Quem decide esses casos são as demais regras e o modo.
- `dontAsk` nega automaticamente tudo que perguntaria. `bypassPermissions` "pula os prompts" (exceto ações que nenhum modo aprova).
  Deny continua valendo; `permissions.disableBypassPermissionsMode`/`disableAutoMode` existem.
- `settings.local.json` com sessão no diretório do projeto aplica as regras sem trust, mas se estiver **rastreado no git** é
  tratado como conteúdo do repositório. O `~/.claude/settings.local.json` só vale em sessões abertas no home.
- `claude -p`/SDK não mostram o diálogo de trust.
- Hook PreToolUse não contorna deny nem ask.

Não verificado no texto lido (tratar como premissa conservadora): comportamento exato de `ask` em `claude -p` sem
`--permission-prompt-tool` (premissa: sem prompt possível, a chamada não executa, ou executa conforme o modo; não depender disso);
se `ask` é ignorado em `bypassPermissions` (premissa: **sim, ask não protege em bypass**; só deny protege); `acceptEdits`
(premissa: não aprova Bash arbitrário, ask continua perguntando). Em auto mode o classificador revisa, mas regra `ask` casada
ainda pergunta (documentado para `git clean`).

## Respostas às questões obrigatórias

1. Mover publicação do deny versionado para `settings.local.json` enfraquece a barreira? **Sim**, para quem não responde ao
   onboarding ("sem decisão") e para sessões abertas fora da pasta do projeto: o grupo não está em deny nem em ask, e o efeito
   passa a ser o do modo (default: prompt; auto: classificador; bypass: executa; qualquer `allow` amplo do usuário, ex. `Bash(gh *)`,
   libera). Hoje o deny barra em todos os modos. A garantia "TechLead não publica sem decisão" é regra de prompt do agente, não controle da
   plataforma. Alternativas: (A, recomendada) manter o grupo no template versionado em `ask` e a opção "bloqueada" vira `deny` no
   `settings.local.json` (deny local se soma; o default fica sem allow e com confirmação; segue o desejo "ask, nunca allow"); (B) manter o
   deny versionado e exigir edição consciente dele (status quo; o usuário pediu para evitar); (C) manter a spec com a mitigação:
   onboarding sempre grava decisão, SessionStart avisa "sem decisão", `disableBypassPermissionsMode` recomendado, e o usuário aceita por
   escrito o risco residual de bypass/auto. Também possível: hook PreToolUse do plugin que nega o grupo sem preferência `confirmar`
   (hook só restringe; falha de hook = fail open, então é complemento, não substituto).
2. Ver bloco "Fonte". Consequência: `ask` só protege em modos que perguntam (default, acceptEdits, auto, plan); não protege em
   `bypassPermissions`; em `-p`/CI é indefinido, tratar como sem proteção. Escopos: deny em qualquer escopo vence; ask local não anula deny de usuário/projeto/managed.
3. Contornos: ver achados M1 a M3 e L2. Os padrões atuais são todos de prefixo; nenhum cobre binário por caminho, `sh -c`, `.exe`, alias.
4. Prompt injection: ver M7. Em modo `confirmar`, o texto de PR/issue/CI lido é o vetor para induzir `gh pr comment` (exfiltração em
   repositório público), `release upload`, `merge`. A única barreira real é o prompt `ask` humano.
5. Regras de push: **insuficientes e contraditórias**, ver H1.
6. Agente editando `settings.local.json`: ver M5.
7. Merge irreversível: ver M2.
8. Itens que ficam no deny fixo: ver M3 e M4.

## Achados

### HIGH

**H1. REQ-004 (push sem force) conflita com o deny fixo e as regras atuais não impedem push na default.**
Local: spec.md REQ-004; template deny linhas 185 a 206; techlead.md Git item 5; git-workflow.md "Limites".
- `Bash(git push *-*f*)` casa `git push -u origin feat/x` (hífen de `-u` seguido de "f" em `feat`) e quase todo push de branch
  com `f` no nome. O push "permitido" do REQ-004 será negado pelo deny fixo; o implementador será tentado a afrouxar o deny (controle não relaxável).
- Não negados hoje: `git push origin HEAD:main`, `HEAD:refs/heads/main`, `git push origin main`, `git push` com upstream na default,
  `--all`, `--tags`, `--prune`, `-o`, `git -C . push`, `git -c ... push`, binário por caminho. Só o `ask` genérico protege.
- Contradiz techlead.md Git passo 5 ("Nunca executar push") e "Repositório" ("Nunca usar Bash gh/glab/az para escrever").
Correção: remover o push do REQ-004. Publicação = `gh pr create` etc. sobre branch **já enviada pelo usuário**, que continua rodando
`git push -u origin <branch>` ele mesmo. Se o usuário insistir em push pelo agente, vira feature própria com spec e parecer
próprios (deny cirúrgico novo: `git push *main*`, `*master*`, `*HEAD:*`, `*--all*`, `*--tags*`, `*--prune*`, regex-free; proteção de branch no servidor como controle principal).

**H2. Barreira padrão enfraquecida em "sem decisão" e em sessões fora do projeto (questão 1).**
Local: spec.md REQ-001/REQ-003; design.md 2 e 6.
Correção: adotar A (grupo em `ask` no template versionado; "bloqueada" = deny local), ou C com as mitigações listadas, registrando a
decisão do usuário. Em qualquer caso: `sem decisão` deve ser tratado como `bloqueada` pelo TechLead (já é), documentado como controle de
prompt e não de plataforma; README/manual devem dizer que `ask` não vale em `bypassPermissions`/`-p` e recomendar
`disableBypassPermissionsMode`.

**H3. Estado lido do arquivo não prova que o `ask` está em vigor na sessão.**
Local: spec.md REQ-003/REQ-004; design.md 3 e 4; techlead.md "Trabalho entre projetos".
Em sessão no workspace, ou com `--add-dir`, só o settings do workspace/diretório da sessão vale; o `settings.local.json` de um projeto
filho não é aplicado. O TechLead leria `confirmar` e executaria `gh pr merge` sem nenhuma regra do Claude Code atuando.
Correção: o TechLead só entra em modo publicação quando a sessão foi aberta **dentro do projeto** (raiz do repo = cwd) e o arquivo lido é o
desse `.claude/`; em sessão de workspace ou `--add-dir`, o modo é `bloqueada`. Teste: sessão de workspace com `confirmar` no projeto filho resulta em não publicar.

(H3 pode ser reclassificado MEDIUM se o usuário aceitar a restrição acima; mantido HIGH até estar na spec.)

### MEDIUM

**M1. Windows e formas alternativas.** Ambiente do usuário é Windows: `gh.exe pr merge`, `& gh ...`, caminho absoluto, `sh -c`, `bash -c`,
`env gh ...`, `cmd /c`, `powershell -c` não casam `Bash(gh pr merge:*)` (limite documentado). Vale para deny e ask. Sem sandbox/hook,
o controle real é o prompt do modo. Correção: documentar como limitação aceita; adicionar ao grupo variantes `gh.exe`; recomendar
hook PreToolUse opcional que nega `gh|glab|az` fora do formato conhecido; token do `gh` com escopo mínimo (a nota "gh já logado tem escrita" persiste).

**M2. Merge irreversível e flags perigosas.** Em `ask`: `gh pr merge --admin` (ignora proteção de branch), `--auto`, `-d/--delete-branch`
(apaga branch remota e local), `gh pr merge` sem número (merge do PR da branch atual); `az repos pr update --status completed` e
`--auto-complete true` **mesclam** sem usar o verbo `merge`; `glab mr merge --remove-source-branch`. Correção: no REQ-004, `merge` exige
confirmação específica já prevista, mais: número do PR explícito, sem `--admin`/`--auto`/`-d`; adicionar ao deny fixo
`Bash(gh pr merge *--admin*)` e padrões `az repos pr update *completed*`/`*auto-complete*` (ou mantê-los no fixo, retirando `az repos pr update` do grupo);
exigir status de CI/revisão consultado antes (leitura) e mostrado na confirmação. Merge não tem rollback (revert é novo commit; branch apagada).

**M3. Itens que devem ficar no deny fixo (acréscimo à lista do REQ-001).** Mover do grupo para o fixo: `gh pr review` (inclui `--approve`),
`glab mr approve`, `az repos pr set-vote`, `az repos pr reviewer` (aprovar/votar é autorização humana do merge: auto-aprovação anula a revisão);
`gh release edit`, `gh release upload`, `glab release` (já fixo) (upload exfiltra artefato e altera release publicada); `az repos pr update`
(ver M2). Já corretos no fixo: `gh release delete`, `gh pr checkout` (executa código de fork/baixa branch alheia), `gh api`, `gh repo *`,
`gh issue *`, `gh secret|variable|workflow|run|alias|extension|auth`, MCP de issue/pipeline. `gh pr edit`, `gh pr ready`, `gh pr reopen`,
`gh pr close`: manter no `ask` apenas se o usuário aceitar; recomendado grupo mínimo: `gh pr create`, `gh pr merge`, `gh pr comment`, `gh release create`,
`glab mr create|merge|note`, `az repos pr create`, MCP `create_pull_request`/`merge_pull_request`.

**M4. `gh release create` publica e dispara pipelines de deploy; aceita arquivos anexos e `--target`.** Confirmação deve listar tag, alvo, notas e
anexos; anexos só de caminho dentro do projeto e nunca arquivos cobertos pelo deny de leitura (`.env`, chaves).

**M5. Agente/skill editando `settings.local.json`.**
- O arquivo não está sob deny de Edit/Write (só `.git/**` e `~/.gitconfig`). Texto injetado poderia induzir o agente a mover o grupo para `ask`.
- Correção: (a) mudança para `confirmar` só com pedido do usuário em mensagem própria na conversa, nunca derivado de arquivo, issue, PR, saída
  de ferramenta ou outro agente (mesma regra da salinha); (b) adicionar ao template regra `ask` para `Edit(.claude/settings.local.json)`
  e `Write(.claude/settings.local.json)` (não deny, para a skill funcionar; ask continua perguntando em auto mode; em bypass não protege); (c) a skill
  mostra o diff exato antes de gravar; (d) `/sdd:publish confirmar` com `disable-model-invocation: true` (já previsto), não invocável pelo agente por Skill;
  (e) skill nunca toca `allow`, nem outras chaves; valida o JSON resultante e aborta se houver `allow` contendo `gh`/`glab`/`az`/`Bash(*)` e avisa;
  (f) o TechLead, ao ver `allow` com esses comandos, trata como `bloqueada` e avisa.
- Rastreamento: o arquivo é local e fora do git, sem trilha. Registrar a mudança de modo e cada publicação executada em `tasks.md`/relatório (data, comando, PR).
- Verificação "rastreado pelo git": o design diz que a skill não pode rodar `git ls-files`. Correção: permitir à skill somente
  `Bash(git ls-files -- .claude/settings.local.json)` e `Bash(git check-ignore -q .claude/settings.local.json)`, ou a skill apenas pede ao TechLead
  (que tem Bash) a checagem antes de editar. Arquivo rastreado: recusar (ele seria tratado como conteúdo de repositório e aplicado só após trust).

**M6. Contradições de documentação normativa (controle não relaxável fica ambíguo).** Ao permitir publicação, atualizar na mesma versão:
techlead.md "Repositório" (Escrita proibida, "Nunca usar Bash gh/glab/az"), "Git" passo 5 e seção de deny exigido; `git-workflow.md` "Limites";
`sdd-governance` e `sdd-rules`; `techlead.md` frontmatter `tools` não inclui as ferramentas MCP de criar/mesclar PR (se o modo exige MCP, o
acréscimo ao `tools` é mudança de permissão a constar na spec; recomendado usar apenas `gh` via Bash para reduzir superfície); `templates/CLAUDE.md`.
Os testes devem checar que não restou frase "nunca publica" sem a ressalva do modo.

**M7. Prompt injection (questão 4).** Em `confirmar`: título, corpo e comentários de PR/issue, logs de CI e arquivos do repositório são dados
não confiáveis. Correção: título/notas do PR vêm só da spec/tasks validadas (como a mensagem de commit); proibido repassar texto bruto
externo para `gh pr create --body`; `--body-file` gerado de template; confirmação mostra o comando literal e o texto integral; leitura de PR/issue
(MCP read) antes de uma publicação não pode alterar o comando proposto; `gh pr comment` só com conteúdo da spec, nunca citação de log/arquivo
(exfiltração de segredo em repositório público). Sinalizar ao usuário trechos que pareçam instrução (regra existente).

**M8. `gh pr create` pode fazer push implícito** (oferece enviar a branch/criar fork quando não há remota) e `gh pr merge` altera a árvore local
(checkout/pull) e pode apagar branch. Correção: exigir branch já enviada (verificar com `git ls-remote`/`git status -sb`, leitura) e usar `--head`/`--base` explícitos; `--fill` proibido sem revisão do texto.

### LOW

**L1.** Migração (design 6): remover o grupo do deny versionado é relaxamento de controle; só com confirmação explícita no plano mostrando o diff, e
nunca em `.claude/settings.json` versionado de equipe sem aviso de que afeta todos (a opção do usuário vale por usuário apenas no local).
**L2.** Alias pré-existente do `gh` (`gh alias`) e `GH_REPO`/`GH_HOST` no ambiente redirecionam o alvo; exigir que a confirmação mostre
`gh repo view --json nameWithOwner` (leitura) e conferir contra `## Repositório` do `CLAUDE.md`. `gh -R` não é flag global; `-R` após o subcomando é o caso real e já casa o prefixo.
**L3.** REQ-007 testa JSON e conjuntos, mas não efeito. Adicionar: teste de que `settings.local.json` com grupo em `ask` não aparece em
`allow`; teste de que o modelo versionado não contém o grupo se for adotada a alternativa C (ou contém em `ask` se A); teste de que
fixo ∩ publicação = ∅ após o movimento de M3; teste do estado `inconsistente`.
**L4.** Estado `inconsistente` tratado como `bloqueada` (design 3): correto; garantir que a correção seja só por plano confirmado.
**L5.** Hook SessionStart/office: não reutilizar leitura de `settings.local.json` para injetar valores além do estado (`bloqueada|confirmar|sem decisão`).

## Correções objetivas para a spec (resumo)

1. REQ-004: remover o push; publicação sobre branch já enviada pelo usuário; sem `--admin`/`--auto`/`-d`; número do PR explícito; texto do PR vindo só da spec.
2. REQ-001: grupo mínimo (M3); mover `review|approve|set-vote|reviewer|release edit|release upload|az repos pr update` para o fixo; deny fixo novo para `gh pr merge *--admin*`.
3. REQ-001/REQ-003: escolher alternativa A ou C (H2) e registrar a decisão do usuário; documentar limites de `ask` (bypass, `-p`, `.exe`, `sh -c`, caminho absoluto).
4. REQ-003/REQ-004: modo publicação só com sessão aberta no projeto e arquivo do próprio `.claude/` (H3); `allow` com gh/glab/az força `bloqueada`.
5. REQ-005: skill com Bash restrito a `git ls-files`/`git check-ignore` desse arquivo, mostra diff, nunca invocável pelo modelo; adicionar `ask` para Edit/Write do `settings.local.json` ao template.
6. REQ-006: atualizar as frases normativas de M6 (techlead.md "Repositório", "Git" 5, `git-workflow.md` Limites, governance, rules) e decidir o `tools` do agente.
7. REQ-007: acrescentar os testes de L3 e um teste de consistência textual (nenhuma regra "nunca publica" sem ressalva).
8. Registrar em `tasks.md` cada mudança de modo e publicação executada.

## Evidência do que foi revisado

Leitura integral dos arquivos listados acima; análise manual de casamento dos padrões do deny contra `git push -u origin feat/x`
(casa `git push *-*f*`), `git push origin HEAD:main` (não casa `git push * :*` por falta de espaço antes de `:`);
consulta à documentação oficial de permissões (WebFetch, 2026-10-13). Nenhum comando mutável executado.


## Re-revisão da implementação (2026-10-13)

Revisor: sdd:security (independente). Somente leitura; único arquivo escrito: este. Decisões do usuário consideradas: alternativa A (grupo em `ask`
no modelo versionado; `bloqueada` = deny no `settings.local.json`) e `git push -u origin <branch>` pelo TechLead com confirmação (diverge de H1,
condicionado a deny de push correto). Evidência: `node plugins/sdd/hooks/tests/req007-publicacao.test.js` = 50 ok, 0 falha; simulação própria de casamento
(glob `*`, `:*` final como ` *`, deny > ask) de 41 variantes de push e 18 de `gh pr merge` contra `templates/project-settings.git.json`; `.local.json` tem
deny e ask idênticos ao `.git.json`; `.publicacao.json` só tem `ask` (12 itens, sem `allow`).

### Parecer: APROVADO COM CONDIÇÕES

Nenhum HIGH aberto. Os controles estruturais (C1..C4, H2, H3, M1..M8) estão atendidos. Restam 4 MEDIUM de padrões de deny (todos caem em `ask`, ou seja,
o usuário vê o comando literal; nenhum é silencioso) e LOW. Condição: corrigir M-A, M-B, M-C, M-E antes do release; o resto a critério.

### Resposta aos pontos

**(1) H1 resolvido para o fluxo aprovado.** `git push -u origin feat/x` e `git -C . push -u origin feat/x` caem em `ask` (nenhum deny casa; o antigo
`*-*f*`, causa do falso positivo, foi removido). Casam em deny: `HEAD:main`, `origin main`, `origin master`, `-u origin master`, `--set-upstream origin main`,
`--all`, `-uf`, `-fu`, `-f` (início e fim), `--force-with-lease`, `+ref`, `feat/x:main`, `HEAD:refs/heads/main`, `refs/heads/feat/x:refs/heads/main`
(via `:refs/*`), `--tags`, `--mirror`, `--delete`, `git -C . push origin main`. Nome de branch válido pelo slug (`[a-z0-9-]`, chave `PROJ-1`/`GH#1`) não
casa deny por engano (os padrões exigem espaço antes de `main`/`-d`/`-f`).
Ainda escapa para `ask`:
- **M-A (MEDIUM) push ao tronco sem `:` ou com sufixo:** `git push origin refs/heads/main`, `git push origin main --no-verify` / `main -v`, `git push origin "main"`
  (o padrão `* main` é ancorado no fim e exige espaço antes). Correção: `Bash(git push * main *)`, `Bash(git push * master *)`, `Bash(git push */main*)`,
  `Bash(git push */master*)`, `Bash(git push *"main"*)` e os espelhos `git * push ...`; `*/main*` também nega `feat/main-x` (aceitável); um teste por caso.
- **M-B (MEDIUM) force por flags curtas agrupadas:** `git push -vf`, `-qf`, `-nf` escapam (a v0.9.1 negava por `*-*f*`). Correção sem falso positivo: lista explícita
  `-vf*`, `-qf*`, `-nf*`, `-vuf*`, `-uvf*` em posição inicial e `* -vf*` etc. no meio, com espelhos `git *`; documentar o limite (qualquer combinação nova escapa).
- **M-C (MEDIUM) exclusão por refspec `git push origin :x`:** `git push * :*` termina em `:*`; se o motor aplicar a regra legada (equivale a ` *`), vira
  `git push *  *` e não casa `origin :x` (minha simulação com a regra legada: `ask`). O teste cobre só `--delete`, não `:ref`. Correção: padrão que não termine em `:*`
  (ex.: `Bash(git push * :?*)` se `?` for coringa; senão `Bash(git push * :*[a-z]*)`), mais `Bash(git push :*[a-z]*)`, espelhos, teste
  `expectV("git push origin :feat/x","deny")` e conferência em sessão real.
- **LOW:** `git push origin HEAD` e `git push` sem argumentos estando no tronco (só a regra do agente e o prompt protegem); `trunk`/`develop` ou tronco com outro nome não
  estão no deny (`origin develop`, `feat/x:develop` caem em `ask`; o onboarding deveria acrescentar o tronco de `## Git` ao deny local, ou documentar); push de tag
  já existente (`origin v1.0`, `refs/tags/v1`); `--repo=<url>`, URL no lugar de `origin` e `--receive-pack=<cmd>` redirecionam o envio ou executam comando
  (exfiltração; "só `origin`" é regra do agente, o harness só pergunta). Recomendado deny de `*--repo*`, `*--receive-pack*`, `*--exec*`.
- Observação: em `bloqueada` o `git push` continua em `ask` (não faz parte do grupo): o bloqueio de push é do TechLead, não do harness. Consequência declarada da
  decisão do usuário; aceitável, mas a doc deve dizer que `bloqueada` = gh/glab/az.

**(2) `gh pr merge`.** `--admin`, `--auto`, `--delete-branch` em qualquer posição (antes ou depois do número, inclusive sem número) estão em deny, então
`gh pr merge --squash --delete-branch` e `gh pr merge --admin 12` ficam negados. `-d` só casa como palavra isolada com algo antes (`12 -d`, `-s -d 12`).
Escapam para `ask`: `gh pr merge 12 -sd`, `-ds`, `-md`, `gh pr merge -d 12`, `gh pr merge -d`.
- **M-D (LOW) delete-branch por flag curta agrupada ou inicial** (reversível; o `--admin`, crítico, está coberto). Correção: `Bash(gh pr merge -d*)`,
  `Bash(gh pr merge * -d*)`, `-sd*`, `-ds*`, `-md*` (não usar `*-*d*`: casa `--body`).
- **M-E (MEDIUM) `gh.exe`:** os deny novos só existem para `gh`; `gh.exe pr merge 12 --admin|--auto|--delete-branch|-d` cai em `ask` (este workspace é Windows).
  Correção: espelhar as 5 entradas para `gh.exe`.

**(3) H3 resolvido.** `techlead.md` "Publicação": o modo só vale com a sessão dentro do projeto (diretório da sessão = raiz do repositório); workspace ou `--add-dir`,
`sem decisão`, `inconsistente` e `allow` perigoso = `bloqueada`. Fricção única (LOW): "raiz do repositório" difere do onboarding ("em monorepo, a pasta do projeto") e da skill
("raiz do projeto"); unificar em "raiz do projeto (onde está o `.claude/` lido)". Monorepo em subpasta cai em `bloqueada` (seguro).

**(4) M5 atendido, com ressalvas.** Template com `ask` para `Edit`/`Write(.claude/settings.local.json)`; skill com `disable-model-invocation: true`, Bash restrito a
`git ls-files --`/`git check-ignore -q` deste arquivo, diff antes de gravar, recusa arquivo rastreado e `allow` com gh/glab/az/`Bash(*)`, não cria o arquivo, só aceita
`bloqueada|confirmar`; techlead exige pedido em mensagem própria e registro em `tasks.md`. Ressalvas (LOW): o `ask` cobre Edit/Write, não Bash (`sed -i`, `>`); `allowed-tools: Edit`
da skill é um allow: confirmar em sessão real que o `ask` ainda pergunta (ask deve prevalecer sobre allow); caminho relativo vale com a sessão na raiz.

**(5) M6 quase.** Ressalvas presentes em `techlead.md` (Repositório, Git passo 5), `git-workflow.md` Limites, `sdd-governance`, README, `arquitetura.md`, `primeiros-passos.md`,
manual (seção Git). O teste textual só lê `techlead.md` e `git-workflow.md`. Sobraram (LOW): `docs/manual-de-uso.html:841` ("Abrir PR, comentar, revisar, fazer merge e criar
issue não estão liberados: faça manualmente.") e `README.md:88` ("Ele nunca faz `push`, `merge`, ..."; a ressalva só vem na frase seguinte). `CHANGELOG.md:59` é histórico
(manter). Correção: acrescentar "salvo modo publicação" nos dois e estender o teste a README, docs e `sdd-governance`.

**(6) Regressão: nada do deny da v0.9.1 sumiu sem substituto, exceto push com flags agrupadas (M-B).** Itens movidos ao grupo `ask` por decisão: `gh pr merge|create|comment`,
`gh release create`, `glab mr merge|create|note`, `az repos pr create` (cada um com deny novo para flags perigosas). Trocados: `Bash(git push *-*f*)` e `Bash(git * push *-*f*)` por
`--force`, `-f` (4 posições), `-uf`/`-fu` e `+` (perda real só em M-B). Acrescentados: `--admin`, `--auto`, `--delete-branch`, `-d`, `glab --remove-source-branch`, push
`--all|--tags|--prune|--follow-tags`, tronco, `:main`, `:master`, `:refs/`.

**(7) "sem decisão" com grupo em `ask` no versionado: risco residual aceitável.** O harness pergunta (nunca executa sem o usuário), o TechLead trata como `bloqueada` e oferece a
pergunta; só roda se o usuário aprovar o prompt com o comando literal. Residuais: usuário induzido a aprovar prompt (mitigado por M7: texto só da spec, comando literal);
`bypassPermissions`/`claude -p` (limite já documentado; recomendar `disableBypassPermissionsMode`).

### Achados e correções objetivas

| Id | Sev. | Correção |
|---|---|---|
| M-A | MEDIUM | Deny de push ao tronco com sufixo/sem `:` (`main *`, `*/main*`, aspas) e espelhos `git *`; testes. |
| M-B | MEDIUM | Deny de `-vf`/`-qf`/`-nf`/`-vuf` (lista explícita); testes; documentar limite. |
| M-C | MEDIUM | `git push origin :x` não garantido (padrão termina em `:*`); trocar por padrão que não termine em `:*`; teste `:feat/x`; conferir em sessão real. |
| M-E | MEDIUM | Espelhar `--admin`/`--auto`/`--delete-branch`/`-d` para `gh.exe`. |
| M-D | LOW | `gh pr merge -sd/-ds/-md/-d 12/-d` em deny. |
| L-1 | LOW | `trunk`/`develop`, `HEAD`/`push` sem args no tronco, tag existente, `--repo`/`--receive-pack`/`--exec`; documentar que `bloqueada` não bloqueia push no harness. |
| L-2 | LOW | Uniformizar "raiz do projeto" (techlead "Publicação" vs onboarding/skill). |
| L-3 | LOW | `manual-de-uso.html:841` e `README.md:88`: ressalva do modo publicação; ampliar o teste textual. |
| L-4 | LOW | Confirmar em sessão real que `ask` de `Edit(settings.local.json)` prevalece sobre `allowed-tools: Edit`; `ask` não cobre Bash. |

Limitação: o casamento foi simulado, não executado no motor real do Claude Code (a regra do `:*` legado é a incerteza de M-C); os testes do repositório usam simulação
equivalente e declaram o mesmo limite.

## Correção das condições (TechLead, 2026-10-13)

M-A (push ao tronco por `refs/heads/main`, `main --no-verify`, `"main"`), M-B (`-vf`/`-qf`/`-nf` e inversos), M-C (`:ref` de
deleção, com `:**` para evitar o sufixo legado `:*`) e M-E (`gh.exe pr merge --admin|--auto|--delete-branch`) corrigidos nos
modelos de settings; M-D (`-sd`, `-ds`, `-md`, `-dm`, `-rd`, `-dr`, `-d 12`) também. M6: README e manual sem frase "nunca" sem
ressalva. 13 casos novos em `req007-publicacao.test.js` (63 ok). Aceitos como limite documentado: `trunk`/`develop` como tronco,
`--repo`/`--receive-pack`, `ask` sem cobertura de `sed -i`/redirecionamento, e a confirmação em sessão real de que o `ask` de
`Edit(settings.local.json)` prevalece sobre o `allowed-tools: Edit` da skill (T-007, piloto). Parecer final após as correções:
**APROVADO COM CONDIÇÕES cumpridas**, condicionado ao piloto real (T-007).
