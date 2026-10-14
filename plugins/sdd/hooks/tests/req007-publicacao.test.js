// REQ-007 (publish-opt-in): permissões do modelo de settings. Sem dependências (Node), sem rede, só leitura.
// Casamento de padrões: simulação de glob (`*` = qualquer sequência), deny > ask, como na doc de permissões.
// Limite: não é o motor real do Claude Code (ver parecer de segurança).
"use strict";
const fs = require("fs");
const path = require("path");
const ROOT = path.resolve(__dirname, "../../../..");
let pass = 0, fail = 0;
const check = (m, c, x) => { if (c) { pass++; console.log("  ok   " + m); } else { fail++; console.log("  FAIL " + m + (x !== undefined ? " [" + x + "]" : "")); } };
const load = (p) => JSON.parse(fs.readFileSync(path.join(ROOT, p), "utf8"));
const text = (p) => fs.readFileSync(path.join(ROOT, p), "utf8");

const git = load("templates/project-settings.git.json");
const loc = load("templates/project-settings.local.json");
const pub = load("templates/project-settings.publicacao.json");
const GROUP = pub.permissions.ask;
const deny = git.permissions.deny, ask = git.permissions.ask;

check("modelo git e local têm o mesmo deny e o mesmo ask",
  JSON.stringify(deny) === JSON.stringify(loc.permissions.deny) && JSON.stringify(ask) === JSON.stringify(loc.permissions.ask));
check("publicacao.json só tem permissions.ask (sem allow/deny)",
  JSON.stringify(Object.keys(pub)) === '["permissions"]' && JSON.stringify(Object.keys(pub.permissions)) === '["ask"]');
check("grupo publicação ⊆ ask do modelo", GROUP.every((x) => ask.includes(x)));
check("grupo publicação ∩ deny do modelo = ∅", GROUP.every((x) => !deny.includes(x)));
check("nenhum allow no modelo nem em publicacao.json", !git.permissions.allow && !pub.permissions.allow);
check("sem duplicatas no grupo", new Set(GROUP).size === GROUP.length);
const bashCli = /^Bash\((gh|gh\.exe|glab|az) /;
check("merge nunca no grupo e sempre em deny (o merge é do usuário)",
  ["Bash(gh pr merge:*)", "Bash(gh.exe pr merge:*)", "Bash(glab mr merge:*)"].every((x) => deny.includes(x) && !GROUP.includes(x) && !ask.includes(x)));
check("grupo é só Bash gh/glab/az (sem MCP)", GROUP.every((x) => bashCli.test(x)), GROUP.filter((x) => !bashCli.test(x)).join(","));
check("aprovar/revisar/editar release ficam fora do grupo e sempre com confirmação (ask)",
  ["Bash(gh pr review:*)", "Bash(glab mr approve:*)", "Bash(az repos pr set-vote:*)", "Bash(az repos pr reviewer:*)",
   "Bash(gh release edit:*)", "Bash(gh release upload:*)", "Bash(gh release delete:*)", "Bash(gh pr checkout:*)"].every((x) => ask.includes(x) && !deny.includes(x) && !GROUP.includes(x)));
check("az repos pr update (completa PR) segue em deny", deny.includes("Bash(az repos pr update:*)"));
check("MCP de mesclar PR continua em deny; MCP de criar PR/issue vai para ask (liberado com confirmação)",
  ["mcp__github__merge_pull_request", "mcp__gitlab__accept_merge_request"].every((x) => deny.includes(x)) &&
  ["mcp__github__create_pull_request", "mcp__github__issue_write", "mcp__azure-devops__repo_pull_request_write", "mcp__atlassian__createJiraIssue"].every((x) => ask.includes(x) && !deny.includes(x)));
// relax-deny: git e escrita externa liberados com confirmação; credencial/execução/segredos/.git seguem em deny.
check("nenhuma regra Bash(git ...) no deny (liberado com confirmação)", !deny.some((x) => x.startsWith("Bash(git ")));
check("regras git que eram deny estão em ask (force push, reset --hard, clean, rebase, config, -c)",
  ["Bash(git push *--force*)", "Bash(git reset --hard*)", "Bash(git clean*)", "Bash(git rebase*)", "Bash(git config*)", "Bash(git -c*)", "Bash(git tag*)"].every((x) => ask.includes(x)));
check("credencial e execução continuam em deny", ["Bash(gh auth token:*)", "Bash(gh auth status --show-token:*)", "Bash(glab auth:*)", "Bash(gh extension install:*)", "Bash(gh alias set:*)"].every((x) => deny.includes(x)));
check("segredos e .git seguem em deny (Read .env/chaves, Edit .git e ~/.gitconfig)",
  ["Read(**/.env)", "Read(**/*.pem)", "Read(~/.ssh/**)", "Edit(**/.git/**)", "Edit(~/.gitconfig)"].every((x) => deny.includes(x)));
check("ask protege a edição do settings.local.json (só Edit(...) é casado; Write(...) é ignorado pelo Claude Code)",
  ask.includes("Edit(.claude/settings.local.json)") && !ask.some((x) => x.startsWith("Write(")));
check("nenhuma regra Write(...) nem padrão `* :*` ineficaz (avisos do Claude Code real)",
  ![...deny, ...ask].some((x) => x.startsWith("Write(") || /^Bash\(.*\*.* :\*\)$/.test(x) || /^Bash\(.*\* :\*\)$/.test(x)));

// Nada some em relação ao deny da v0.9.1 (lista congelada em deny-v0.9.1.txt).
const frozen = path.join(__dirname, "deny-v0.9.1.txt");
if (fs.existsSync(frozen)) {
  const old = fs.readFileSync(frozen, "utf8").split(/\r?\n/).filter(Boolean);
  const swapped = ["Bash(git push *-*f*)", "Bash(git * push *-*f*)", "Bash(git push * :*)", "Bash(git * push * :*)", "Write(**/.git/**)", "Write(~/.gitconfig)"];
  const missing = old.filter((x) => !deny.includes(x) && !ask.includes(x) && !GROUP.includes(x) && !swapped.includes(x));
  check("todo item do deny da v0.9.1 continua coberto por deny ∪ ask ∪ grupo (nada some; exceto os padrões trocados)", missing.length === 0, missing.join(" | "));
}

// Simulador de glob de permissões.
const re = (p) => new RegExp("^" + p.replace(/[.+?^${}()|[\]\\]/g, "\\$&").replace(/\*/g, ".*") + "$");
// Sufixo ":*" sem "*" antes = prefixo (casa o comando exato e o comando seguido de espaço e argumentos).
const prefixRe = (base) => new RegExp("^" + base.replace(/[.+?^${}()|[\]\\]/g, "\\$&") + "( .*)?$");
const rules = (list) => list.filter((r) => /^Bash\(/.test(r)).map((r) => r.slice(5, -1)).map((r) => (/^[^*]*:\*$/.test(r) ? prefixRe(r.slice(0, -2)) : re(r)));
const D = rules(deny), A = rules(ask);
const verdict = (cmd) => (D.some((r) => r.test(cmd)) ? "deny" : A.some((r) => r.test(cmd)) ? "ask" : "livre");
const expectV = (cmd, v) => check(`${v.padEnd(5)} <- ${cmd}`, verdict(cmd) === v, verdict(cmd));

// Push: o fluxo aprovado cai em ask; contornos de tronco, refspec e flags caem em deny.
expectV("git push -u origin feat/fix-login", "ask");
expectV("git push -u origin fix/PROJ-1-ajuste", "ask");
expectV("git push origin feat/x", "ask");
expectV("git push origin HEAD:main", "ask");
expectV("git push origin HEAD:feat/x", "ask");
expectV("git push origin HEAD:refs/heads/main", "ask");
expectV("git push -u origin main", "ask");
expectV("git push origin master", "ask");
expectV("git -C . push origin HEAD:main", "ask");
expectV("git push --all", "ask");
expectV("git push origin --tags", "ask");
expectV("git push --prune origin feat/x", "ask");
expectV("git push -uf origin feat/x", "ask");
expectV("git push -fu origin feat/x", "ask");
expectV("git push --force origin feat/x", "ask");
expectV("git push origin +feat/x", "ask");
expectV("git push --delete origin feat/x", "ask");
expectV("git push origin refs/heads/main", "ask");
expectV("git push origin main --no-verify", "ask");
expectV('git push origin "main"', "ask");
expectV("git push -vf origin feat/x", "ask");
expectV("git push -qf origin feat/x", "ask");
expectV("git push -nf origin feat/x", "ask");
expectV("git push origin :feat/x", "ask");
expectV("git -C . push origin :feat/x", "ask");
expectV("git push -u origin feat/maintenance-fix", "ask");
expectV("gh.exe pr merge 12 --admin", "deny");
expectV("gh.exe pr merge 12 --delete-branch", "deny");
expectV("gh pr merge 12 -sd", "deny");
expectV("gh pr merge -d 12", "deny");
// Publicação: grupo em ask; perigosos em deny.
expectV("gh pr create --base main --head feat/x --title t --body-file b.md", "ask");
expectV("gh pr merge 12 --squash", "deny");
expectV("gh pr merge 12 --admin", "deny");
expectV("gh pr merge 12 --auto --squash", "deny");
expectV("gh pr merge 12 --delete-branch", "deny");
expectV("gh pr merge 12 -d", "deny");
expectV("gh release create v1.0.0 --notes-file n.md", "ask");
expectV("gh.exe pr merge 12", "deny");
expectV("glab mr merge 3", "deny");
expectV("gh pr merge", "deny");
expectV("glab mr merge 3 --remove-source-branch", "deny");
expectV("az repos pr create --title t", "ask");
expectV("az repos pr update --id 3 --status completed", "deny");
expectV("gh pr review 12 --approve", "ask");
expectV("gh release upload v1 a.zip", "ask");
expectV("gh api repos/o/r/pulls", "ask");
// relax-deny (cloud): todo comando de az/azd/aws/gcloud pergunta (ask); az repos pr update (completa PR) segue em deny; nada fica livre.
expectV("aws s3 ls", "ask");
expectV("aws ec2 terminate-instances --instance-ids i-123", "ask");
expectV("aws.exe sts get-caller-identity", "ask");
expectV("gcloud compute instances list", "ask");
expectV("gcloud projects delete meu-projeto", "ask");
expectV("gcloud.cmd config list", "ask");
expectV("az group delete --name rg-x --yes", "ask");
expectV("az account show", "ask");
expectV("azd up", "ask");
expectV("az repos pr update --id 3 --status completed", "deny");
expectV("gh issue create --title t", "ask");
expectV("gh repo delete o/r --yes", "ask");
expectV("gh auth token", "deny");
expectV("gh pr merge 12", "deny");
expectV("git status", "livre");
expectV("git diff --stat", "livre");
expectV("git log --oneline", "livre");
expectV("git reset --hard HEAD~1", "ask");
expectV("git clean -fdx", "ask");
expectV("git config user.name x", "ask");

// Transformação bloqueada <-> confirmar (REQ-005): move o grupo inteiro entre chaves; reversível; nunca cria allow.
const move = (s, from, to) => {
  const n = JSON.parse(JSON.stringify(s)); const P = n.permissions;
  P[from] = (P[from] || []).filter((x) => !GROUP.includes(x)); if (!P[from].length) delete P[from];
  P[to] = (P[to] || []).concat(GROUP.filter((x) => !(P[to] || []).includes(x)));
  return n;
};
const conf = { permissions: { ask: GROUP.slice() } };
const bloq = move(conf, "ask", "deny");
check("bloqueada: grupo só em deny", GROUP.every((x) => bloq.permissions.deny.includes(x)) && !bloq.permissions.ask);
check("confirmar -> bloqueada -> confirmar é reversível", JSON.stringify(move(bloq, "deny", "ask")) === JSON.stringify(conf));
check("mover não cria allow", !bloq.permissions.allow && !move(bloq, "deny", "ask").permissions.allow);
check("estado parcial/duplo é detectável (inconsistente)", (() => {
  const both = { permissions: { deny: GROUP.slice(0, 1), ask: GROUP.slice(1) } };
  const inD = GROUP.filter((x) => both.permissions.deny.includes(x)).length;
  const inA = GROUP.filter((x) => both.permissions.ask.includes(x)).length;
  return inD !== GROUP.length && inA !== GROUP.length && inD + inA === GROUP.length;
})());

// Consistência textual: as regras "nunca publica/push" trazem a ressalva do modo publicação.
// techlead.md + os playbooks movidos para skills (0.11.0): as regras de publicação/Git/Jira podem estar em qualquer dos três.
const tl = [text("plugins/sdd/agents/techlead.md"), text("plugins/sdd/skills/vcs-delivery/SKILL.md"), text("plugins/sdd/skills/project-setup/SKILL.md")].join("\n");
const gw = text("plugins/sdd/skills/sdd-rules/references/git-workflow.md");
const MODO = /modo\s+publicação/i;
check("techlead.md: merge nunca, é do usuário; fim da spec abre o PR e para",
  /Merge: nunca/.test(tl) && /Fim da spec/.test(tl) && /merge do usuário|Aguardando sua revisão e\s+merge/i.test(tl));
check("techlead.md define o modo publicação (settings.local.json)", MODO.test(tl) && /settings\.local\.json/.test(tl));
check("git-workflow.md cita o modo publicação nos limites", MODO.test(gw));
const fim = tl.split("5. Fim:")[1] || "";
check("techlead.md: 'Fim' do fluxo Git traz a ressalva do modo publicação", MODO.test(fim.slice(0, 1200)));
check("skill publish existe e não é invocável pelo modelo",
  fs.existsSync(path.join(ROOT, "plugins/sdd/skills/publish/SKILL.md")) && /disable-model-invocation: true/.test(text("plugins/sdd/skills/publish/SKILL.md")));

// jira-write: o TechLead tem exatamente as 4 ferramentas de escrita do Jira (2 prefixos); nunca os executores genéricos nem Confluence; ask na plataforma.
const tools = (tl.match(/^tools:.*$/m) || [""])[0];
const jw = ["addOrEditJiraIssueComment", "createJiraIssue", "editJiraIssue", "transitionJiraIssue"];
check("techlead: 4 ferramentas de escrita do Jira nos 2 prefixos", ["mcp__claude_ai_Atlassian__", "mcp__atlassian__"].every((px) => jw.every((n) => tools.includes(px + n + ","))|| jw.every((n) => tools.endsWith(px + n))));
check("techlead: sem executeWrite/executeDestructive nem Confluence", !/executeWrite|executeDestructive|ConfluenceContent/.test(tools));
check("escrita do Jira também em ask nos modelos (plataforma pergunta)", jw.every((n) => ask.includes("mcp__claude_ai_Atlassian__" + n) && ask.includes("mcp__atlassian__" + n)));
check("techlead.md: escrita no Jira só com pedido explícito e confirmação", /Escrever no Jira[\s\S]{0,200}pedido explícito do usuário/.test(tl));
console.log(`req007-publicacao.test.js: ${pass} ok, ${fail} falha(s)`);
process.exit(fail ? 1 : 0);
