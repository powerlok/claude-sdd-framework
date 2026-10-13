# Parecer de segurança: mobile-git-workflow (REQ-007/008/009)

Revisor: sdd:security (somente leitura). Data: 2026-10-11.
Escopo: `agents/techlead.md` (seção Git 668-689, onboarding 441-444), `skills/git-lang/SKILL.md`,
`skills/sdd-rules/references/git-workflow.md`, `templates/project-settings.git.json` e `.local.json` (deny idêntico,
linhas 294-312), `agents/mobile.md`, `skills/mobile-engineering/**`, `agents/security.md`.

## Parecer final: RISCO IDENTIFICADO

Nenhum CRITICAL. Há 3 achados HIGH/MEDIUM no bloqueio técnico (REQ-008): os padrões `Bash(...)` casam só pelo início do
comando e são contornáveis com variações realistas. A confirmação (REQ-007) é só instrução em prosa; o controle real é o
prompt de permissão. Sem segredos reais nos arquivos mobile (grep limpo).

## Achados

### HIGH

**H-1 deny ancorado no início do comando: `git -C`/`-c`/`--git-dir` contornam tudo**
`templates/project-settings.git.json:303-312` (idem `.local.json`). Todos os padrões começam por `git <subcomando>`.
Contornos: `git -C . reset --hard`, `git -c core.hooksPath=/dev/null commit ...` (burla hooks sem `--no-verify`),
`git -c alias.x='!rm -rf .' x`, `git --no-pager reset --hard`, `git --git-dir=.. clean -fdx`. O próprio techlead usa
`git -C <repo>` (techlead.md:312), então o hábito já existe.
Correção: duplicar cada deny com curinga entre `git` e o subcomando, ex. `Bash(git * reset --hard*)`,
`Bash(git * clean *)`, `Bash(git * commit *--no-verify*)`, `Bash(git * branch -D*)`, `Bash(git * config*)`,
`Bash(git * restore*)`, e negar `Bash(git -c *)` e `Bash(git * -c *)`. Wrappers (`bash -c "git ..."`, `sh -c`,
`/usr/bin/git`, scripts) não são cobertos por padrões; registrar como limitação conhecida (risco residual aceito, o
prompt de permissão continua valendo).

### MEDIUM

**M-1 `--no-verify`/`-n` e `-a` com ordem de flags diferente**
`project-settings.git.json:306-308`. `git commit -n*` só casa `-n` logo após `commit`. Não casam: `git commit -m x -n`,
`git commit -an`, `git commit -nm x`, `git commit -a -n`, `git commit --no-verif` (git aceita prefixo único de opção
longa). `git commit -a`/`-am` ainda contorna a "lista explícita de arquivos" (stage de tudo rastreado).
Correção: `Bash(git commit *-n*)`-like é largo demais; usar `Bash(git commit * -n*)`, `Bash(git commit *-[a-z]*n*)`,
`Bash(git commit *--no-verif*)`, e `ask` para `Bash(git commit *-a*)`/`Bash(git commit *--all*)`. Alternativa mais
robusta: hook PreToolUse que normaliza e rejeita; ou exigir `git commit -F <arquivo>` e negar `-m`/flags curtas.

**M-2 `git clean`, `git checkout`, `git switch`, `git reset` e demais destrutivos incompletos**
`project-settings.git.json:303-312`. Não cobertos: `git clean -xdf`, `git clean -x -f`, `git clean --force`,
`git checkout .`, `git checkout -f`, `git checkout HEAD -- f` (só `checkout -- *` no início), `git switch -f`/
`--discard-changes`, `git reset --merge|--keep|--mixed HEAD~N` (perde commits), `git stash drop|clear`,
`git update-ref -d`, `git reflog expire`, `git gc --prune`, `git rm -rf`, `git filter-branch`.
`rebase`, `merge`, `tag`, `commit --amend` estão proibidos só em prosa (REQ-007), sem deny.
Correção: `deny` para `git clean*` (inteiro), `git checkout *.`, `git checkout -f*`, `git switch -f*`,
`git switch --discard-changes*`, `git reset *` (exceto `--soft` se necessário: usar `ask`), `git stash drop*`,
`git stash clear*`, `git rebase*`, `git merge*`, `git tag*`, `git update-ref*`, `git reflog*`, `git filter-branch*`,
`git commit *--amend*`.

**M-3 `commit`/`switch -c`/`add` sem `ask` explícito: confirmação do usuário depende de não existir `allow` amplo**
`project-settings.git.json:314-316`. REQ-008 diz "não liberados em allow", mas nada garante prompt: um `Bash(git *)`
no settings de usuário ou modo `acceptEdits/bypass` elimina a confirmação, e a seção Git do techlead (668-689) é prosa.
Precedência é deny > ask > allow, então `ask` vence um `allow` amplo.
Correção: acrescentar em `ask`: `Bash(git commit *)`, `Bash(git add *)`, `Bash(git switch *)`,
`Bash(git checkout *)`, `Bash(git branch *)`, e `Bash(git push)` (push sem argumentos pode não casar `git push *`).
Em `deny`/`ask`: `git add -A*`, `git add .`, `git add --all`, `git add -u` (REQ-007 proíbe "sem listar" só em prosa).

**M-4 arquivos já em stage entram no commit (lista confirmada diverge do commit real)**
`techlead.md:679-680`, `git-workflow.md:76`. `git add <arquivos>` + `git commit` inclui tudo que já estava no índice
(inclusive segredo/arquivo alheio adicionado antes). A confirmação mostra a lista do `git add`, não do commit.
Correção: antes de pedir confirmação executar `git diff --cached --name-only` (e `git status --porcelain`) e mostrar
essa lista; abortar se houver arquivo staged fora da lista da task; ou usar `git commit --only -- <arquivos>`.
A pré-condição "árvore sem mudanças alheias" (techlead.md:673) só "avisa"; tornar bloqueante para staged.

**M-5 Edit/Write em `.git/` e arquivos de configuração do Git não negados**
`project-settings.git.json` (ausente). `git config*` é negado, mas o agente (e subagentes com Edit/Write) pode editar
`.git/config` (alias, `core.hooksPath`, `core.sshCommand`, `credential.helper`), `.git/hooks/*`, `.gitattributes`
ou `~/.gitconfig` diretamente, contornando REQ-008 (aliases e hooks).
Correção: `Edit(**/.git/**)`, `Write(**/.git/**)`, `Edit(~/.gitconfig)`, `Write(~/.gitconfig)`,
`Edit(**/.husky/**)` (conforme política do projeto).

**M-6 `eas update`/`eas build`/`eas submit` sem gate (escrita remota/produção)**
`references/react-native-expo.md:187-197`, `agents/mobile.md:536` (tem Bash). A referência ensina `eas update
--channel` (publicação OTA para usuários) e `eas login`, e a única restrição (197) cita lojas e envio de builds, não o
update OTA nem `eas login`.
Correção: em 197 incluir "`eas update`, `eas submit`, `eas build` de produção e `eas login` só com decisão explícita
do usuário"; no settings: `ask` para `Bash(eas *)` e `Bash(npx eas-cli* update*)`/`submit*`.

### LOW

**L-1 regra "nunca git commit/push" não consta nos subagentes**
`agents/mobile.md` (sem menção; idem frontend/backend). Têm Bash. Só o techlead recebe a regra. Correção: linha em
"Regras/Nunca": "executar comandos git que alterem repositório (commit, push, reset, clean, checkout --)".

**L-2 `git push` refspec**
`project-settings.git.json:294-301,315`. `git push origin :branch` (delete por refspec com `:`), `git push -uf`,
`git push --force-if-includes` (coberto por `*--force*`). Como `push *` está em `ask` o usuário confirma; o deny é
camada extra. Correção opcional: `Bash(git push * :*)`, `Bash(git push *-*f*)`.

**L-3 regex da chave e slug: ancoragem e definição de sanitização**
`techlead.md:33-34`, `git-workflow.md:56-59`. Sem risco de ReDoS (sem quantificadores aninhados, classes ASCII).
Observações: (i) `$` em PCRE/Python casa antes de `\n` final: exigir `\z`/rejeitar qualquer espaço ou quebra de linha
(`PROJ-1\n--force`); (ii) `[0-9]` é ASCII (bom, não usar `\d`); (iii) `#` em `GH#42`: seguro dentro de branch git e no
meio de palavra no shell, mas citar sempre o nome (`git switch -c "feat/GH#42-x"`); (iv) `..`, `.lock`, `@{`, `~`, `^`,
`:`, espaço e `-` inicial são impossíveis pelo charset `[a-z0-9-]` e porque a branch começa com tipo da lista fixa;
(v) falta definir o algoritmo (normalizar NFKD, remover não ASCII, truncar a 40 e só depois aparar `-` final) e o caso de
slug vazio (usar `<tipo>/<ISSUE>` ou pedir ao usuário); (vi) o título da spec pode ter sido copiado de issue externa:
o charset neutraliza sintaxe, e a confirmação do usuário mostra a branch final. Correção: acrescentar essas linhas
em `git-workflow.md`.

**L-4 mensagem de commit via `-m` com texto vindo de spec: injeção de shell**
`techlead.md:24-26`, `git-workflow.md:77`. REQ-009 trata a injeção de instrução no LLM, mas não a de shell:
resumo/corpo com `"`, `` ` ``, `$(...)`, `!` ou nova linha em `git commit -m "..."`. Correção: gravar a mensagem em
arquivo temporário e usar `git commit -F <arquivo>` (ou heredoc com delimitador citado `<<'EOF'`), nunca interpolar
texto em linha de comando; rejeitar `Refs:` com chave fora do regex; mostrar ao usuário a mensagem exata.

**L-5 git-lang: Edit sem restrição de caminho e unicidade da linha**
`skills/git-lang/SKILL.md:6,19-20`. `allowed-tools: Read, Edit` está correto (sem Write/Bash/Agent) e
`disable-model-invocation: true` impede acionamento pelo modelo; porém Edit é pré-aprovado em qualquer arquivo, e a
restrição "só a linha Idioma" é prosa. `Idioma:` pode aparecer em outra seção ou bloco de código do `CLAUDE.md`, e o
`Edit` falha ou altera o trecho errado se `old_string` não for único. Correção: instruir a usar como `old_string` as duas
linhas `## Git` ... `Idioma: <atual>` (âncora na seção), sem `replace_all`, e a só aceitar `CLAUDE.md` na raiz do
projeto; o argumento é literal `pt|en` (`$ARGUMENTS` não é interpolado em comando: ok). O techlead também deve tratar
valor lido de `Idioma:` fora de `pt|en` como inválido (usar o padrão e avisar), e validar a resposta do onboarding
(techlead.md:443) antes de gravar.

**L-6 versões não fixadas e `ref` desatualizado**
`react-native-expo.md:187` (`npx eas-cli@latest`, `npm install --global eas-cli`): risco de cadeia de suprimentos;
preferir versão fixada no projeto (`devDependency`/`eas.json cli.version`). `templates/project-settings.git.json:116`
fixa `ref: v0.7.0` enquanto o plugin alvo é 0.9.0: confirmar se é intencional (projetos novos instalariam deny antigo
sem estas regras). Informativo.

## Verificações sem achado

- (d) Segredos: grep por padrões de chave/token em `mobile.md` e `mobile-engineering/**` limpo; exemplos usam
  placeholders. Conselhos corretos: tokens só em `expo-secure-store`, `EXPO_PUBLIC_*` alertado como público,
  AsyncStorage só para dados comuns (react-native-expo.md:130), segredos de build em EAS, mocks sem segredo real,
  checklist mobile no `security.md:66-80` coerente (deep link, TLS/pinning, permissões, OTA, logs). Sugestão menor:
  citar `usesCleartextTraffic`/ATS e logs de produção no checklist.
- (e) `git-lang`: `Read, Edit` apenas. `mobile.md:536`: `Read, Edit, Write, Grep, Glob, Bash` sem `Agent` (igual ao
  frontend), conforme REQ-001. `security.md`: `Read, Grep, Glob, Bash` sem Edit/Write.
- Provedor continua somente leitura: techlead.md:655-662 mantém proibição de escrita e `gh`/`glab`/`az` negados.
- Push: `git push *` em `ask` e fluxo entrega comandos ao usuário (techlead.md:683-685).

## Ações recomendadas antes do aceite

1. Corrigir H-1 e M-1..M-5 no `project-settings.git.json` e `.local.json` (mesmo deny nos dois) e M-6 na referência.
2. Aplicar L-1, L-3, L-4, L-5 (texto) e rodar `sdd:tests` com casos: `git -C . reset --hard`, `git -c core.hooksPath=x commit`,
   `git commit -m x -n`, `git commit -an`, `git clean -xdf`, `git checkout .`, `git add -A`, edição de `.git/config`.

## Correções (volta 1)

| Achado | Correção |
|---|---|
| H-1 | `templates/project-settings.git.json` e `.local.json` (`permissions` idênticos): cada deny git tem variante `git * <padrão>` (opções globais); `git -c*`, `git -* -c*`, `git --config-env*` negados (não se nega `git * -c *` para não bloquear `git switch -c`). Wrappers (`bash -c`, `sh -c`, `/usr/bin/git`) seguem como limitação conhecida, registrada no CHANGELOG. |
| M-1 | deny: `commit -n*`, `* -n*` (cobre `-an`/`-nm` só quando iniciam por `-n`/`-a`), `-a*`, `* -a*`, `--all`, `--no-verif*`, `--amend`. Combinações curtas com o `n` no meio (ex.: `-vn`) não são enumeradas: risco residual (o `ask` de `commit *` continua). |
| M-2 | deny: `clean*`, `checkout .`/`-f`/`--force`/`--`, `switch -f/--force/--discard-changes`, `reset --hard/--merge/--keep`, `stash drop/clear`, `update-ref*`, `reflog expire/delete`, `gc --prune*`, `filter-branch*`, `rebase*`, `merge*`, `tag*`, `branch -D/-f`, `restore*`, `config*`. |
| M-3 | `ask`: `git commit *`, `add *`, `switch *`, `checkout *`, `branch *`, `push` (sem argumento) e `push *`, com variantes `git * ...`. deny: `git add -A/--all/-u/--update/.` (coerente com "lista explícita"). Fluxo aprovado (`git switch -c`, `git add -- <arquivos>`, `git commit -F <arquivo>`) continua possível com confirmação. |
| M-4 | `techlead.md` (Git, item 3) e `git-workflow.md`: `git diff --cached --name-only` + `git status --porcelain` antes da confirmação; staged fora da lista = abortar (ou `commit --only -- <arquivos>`). |
| M-5 | deny `Edit/Write(**/.git/**)` e `Edit/Write(~/.gitconfig)`. `.husky/**` não incluído (depende da política do projeto). |
| M-6 | `react-native-expo.md`: `eas login/build/update/submit` exigem decisão explícita; `eas-cli@<versão>` fixada (placeholder, conferir a atual); `ask` para `eas *` e `npx eas-cli*` nos templates. |
| L-1 | Regra "nunca git commit/push; git é do TechLead" em `mobile.md`, `frontend.md` e `backend.md`. |
| L-2 | deny `git push * :*` e `git push *-*f*`. |
| L-3 | `\z` na chave, chave citada nos comandos, algoritmo do slug (NFKD, `[a-z0-9-]`, truncar e então aparar `-`), slug vazio = pedir ao usuário, `Refs:` inválido omitido (`techlead.md` e `git-workflow.md`). |
| L-4 | Mensagem por `git commit -F <arquivo>` ou heredoc citado, nunca em `-m` (ambos os arquivos). |
| L-5 | `git-lang`: `Edit` ancorado nas duas linhas (`## Git` + `Idioma:`), sem `replace_all`, valor lido validado como `pt|en`; `techlead.md` trata `Idioma:` inválido como `pt` com aviso. |
| L-6 | `eas-cli` fixado (ver M-6). `ref: v0.7.0` do template **não alterado** (decisão de release do usuário; projetos novos instalam o plugin 0.7.0, sem estas regras de agente, até a nova tag). |

Efeitos colaterais conhecidos do deny com curinga: comandos que contenham texto como ` clean`, ` tag`, ` -a`/` -n` em
heredoc ou em `-m` podem ser negados (falso positivo seguro); por isso a mensagem vai em arquivo (`-F`).

## Re-parecer volta 1

Revisor independente (sdd:tests). Data: 2026-10-11. Método: matcher Python (glob, `*` = qualquer sequência, casamento
da string inteira) sobre `templates/project-settings.git.json`; `.local.json` tem `permissions` idêntico (confirmado).
Motor de permissões real do Claude Code: NÃO EXECUTADO (CLI ausente); a avaliação é por simulação.

| Comando | Resultado |
|---|---|
| `git -C . reset --hard`, `git --no-pager reset --hard`, `git --git-dir=.. clean -fdx` | DENY |
| `git -c core.hooksPath=x commit -m x` | DENY (`git -c*`) |
| `git commit -an -m x`, `git commit -a` | DENY |
| `git commit -m x -n`, `git commit --no-verif` | DENY |
| `git clean -xdf`, `git add -A`, `git checkout HEAD -- f` | DENY |
| `git push`, `git push origin feat/x` | ASK |
| `git commit -vn -m x`, `git commit -m x -vn` | ASK (residual aceito, M-1) |
| `git reset HEAD~1` (mixed) | livre (não destrói arquivos; aceitável) |
| `git switch -c feat/PROJ-1-x`, `git switch -c "feat/GH#42-x"`, `git add -- a.txt`, `git commit -F msg.txt` | ASK (fluxo aprovado preservado) |
| `git status`, `git diff --cached --name-only`, `git log` | livres |

Estado dos achados: H-1 corrigido; M-1 corrigido (residual `-vn` documentado); M-2 corrigido; M-3 corrigido (ask
presente, deny de `add -A/./-u`); M-4 corrigido (texto em `techlead.md:679` e `git-workflow.md`); M-5 corrigido
(Edit/Write `.git/**`, `~/.gitconfig`; as quatro entradas aparecem duplicadas no array `deny`, inócuo, limpar);
M-6 corrigido (ask `eas`/`npx eas-cli*`, `eas-cli@<versão>`, restrição explícita em `react-native-expo.md:105`).
L-1, L-3, L-4, L-5 verificados no texto.

### Defeito novo (falso positivo que quebra o fluxo aprovado)

**D-1 (MEDIUM): os deny `git * <palavra>*` casam nomes de arquivo/pasta que comecem com a palavra.** O curinga
entre `git` e o subcomando também casa o argumento de caminho. Negados indevidamente (comprovado no matcher):
`git add -- config.json`, `git add -- config/app.ts`, `git diff -- tag-list.ts`, `git log -- merge.md`,
`git add -- restore.ts`, `git status -- clean.sh`, `git diff --cached -- rebase-notes.md`,
`git commit -F tag-notes.txt` (padrões `git * config*`, `* tag*`, `* merge*`, `* restore*`, `* clean*`, `* rebase*`).
Pastas `config/` são comuns; o `git add` de um arquivo legítimo dessa pasta é negado e o fluxo da task trava (falha
segura, mas é defeito). Correção sugerida: usar `git * clean *`/`git * clean` (espaço depois da palavra; sem `*`
colado) e equivalentes para `config`, `tag`, `merge`, `rebase`, `restore`, `update-ref`, `filter-branch`; manter o
arquivo da mensagem em caminho que não comece por essas palavras. Sem isso, documentar no CHANGELOG (o efeito
colateral descrito cita apenas `-m`/heredoc, não caminhos).

## Parecer: RISCO IDENTIFICADO

Nenhum HIGH/CRITICAL restante; H-1 e M-1..M-6 estão corrigidos. Permanece apenas D-1 (falso positivo, MEDIUM) e as
limitações já registradas (wrappers `bash -c`/`/usr/bin/git`, `-vn`). Aprovável após ajustar D-1 ou aceitá-lo por
escrito.

## Correção D-1 (volta 2, TechLead)

Deny `git * <palavra>*` casava caminhos (`git add -- config/app.ts`). Trocado por `git * <palavra>` + `git * <palavra> *`
(clean, restore, rebase, merge, tag, config, update-ref, filter-branch, --config-env) nos dois templates; duplicatas de
`Edit/Write(**/.git/**)` removidas. Simulação de glob: `git add -- config/app.ts` e `git commit -F tag-notes.txt` → ask
(fluxo normal); `git config`, `git -C . tag`, `git clean -fd`, `git rebase` → deny. Parecer: **APROVADO** (volta 2/3),
com os riscos residuais aceitos (wrappers `bash -c`/`/usr/bin/git`, `-vn`, `git reset HEAD~1` mixed).
Motor de permissões real não executado (CLI ausente).
