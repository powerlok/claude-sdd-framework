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
check("grupo é só Bash gh/glab/az (sem MCP)", GROUP.every((x) => bashCli.test(x)), GROUP.filter((x) => !bashCli.test(x)).join(","));
check("aprovar/revisar/editar release ficam fora do grupo (deny fixo)",
  ["Bash(gh pr review:*)", "Bash(glab mr approve:*)", "Bash(az repos pr set-vote:*)", "Bash(az repos pr reviewer:*)",
   "Bash(az repos pr update:*)", "Bash(gh release edit:*)", "Bash(gh release upload:*)", "Bash(gh release delete:*)",
   "Bash(gh pr checkout:*)"].every((x) => deny.includes(x) && !GROUP.includes(x)));
check("MCP de criar/mesclar PR continua em deny",
  ["mcp__github__create_pull_request", "mcp__github__merge_pull_request", "mcp__gitlab__accept_merge_request",
   "mcp__azure-devops__repo_pull_request_write"].every((x) => deny.includes(x)));
check("ask protege a edição do settings.local.json (só Edit(...) é casado; Write(...) é ignorado pelo Claude Code)",
  ask.includes("Edit(.claude/settings.local.json)") && !ask.some((x) => x.startsWith("Write(")));
check("nenhuma regra Write(...) nem padrão `* :*` ineficaz (avisos do Claude Code real)",
  ![...deny, ...ask].some((x) => x.startsWith("Write(") || /^Bash\(.*\*.* :\*\)$/.test(x) || /^Bash\(.*\* :\*\)$/.test(x)));

// Nada some em relação ao deny da v0.9.1 (lista congelada em deny-v0.9.1.txt).
const frozen = path.join(__dirname, "deny-v0.9.1.txt");
if (fs.existsSync(frozen)) {
  const old = fs.readFileSync(frozen, "utf8").split("\n").filter(Boolean);
  const swapped = ["Bash(git push *-*f*)", "Bash(git * push *-*f*)", "Bash(git push * :*)", "Bash(git * push * :*)", "Write(**/.git/**)", "Write(~/.gitconfig)"];
  const missing = old.filter((x) => !deny.includes(x) && !GROUP.includes(x) && !swapped.includes(x));
  check("todo item do deny da v0.9.1 está em deny ∪ grupo (exceto os 2 padrões de push trocados)", missing.length === 0, missing.join(" | "));
}

// Simulador de glob de permissões.
const re = (p) => new RegExp("^" + p.replace(/[.+?^${}()|[\]\\]/g, "\\$&").replace(/\*/g, ".*") + "$");
const rules = (list) => list.filter((r) => /^Bash\(/.test(r)).map((r) => r.slice(5, -1)).map((r) => (/^[^*]*:\*$/.test(r) ? r.replace(/:\*$/, " *") : r)).map(re);
const D = rules(deny), A = rules(ask);
const verdict = (cmd) => (D.some((r) => r.test(cmd)) ? "deny" : A.some((r) => r.test(cmd)) ? "ask" : "livre");
const expectV = (cmd, v) => check(`${v.padEnd(5)} <- ${cmd}`, verdict(cmd) === v, verdict(cmd));

// Push: o fluxo aprovado cai em ask; contornos de tronco, refspec e flags caem em deny.
expectV("git push -u origin feat/fix-login", "ask");
expectV("git push -u origin fix/PROJ-1-ajuste", "ask");
expectV("git push origin feat/x", "ask");
expectV("git push origin HEAD:main", "deny");
expectV("git push origin HEAD:feat/x", "ask");
expectV("git push origin HEAD:refs/heads/main", "deny");
expectV("git push -u origin main", "deny");
expectV("git push origin master", "deny");
expectV("git -C . push origin HEAD:main", "deny");
expectV("git push --all", "deny");
expectV("git push origin --tags", "deny");
expectV("git push --prune origin feat/x", "deny");
expectV("git push -uf origin feat/x", "deny");
expectV("git push -fu origin feat/x", "deny");
expectV("git push --force origin feat/x", "deny");
expectV("git push origin +feat/x", "deny");
expectV("git push --delete origin feat/x", "deny");
expectV("git push origin refs/heads/main", "deny");
expectV("git push origin main --no-verify", "deny");
expectV('git push origin "main"', "deny");
expectV("git push -vf origin feat/x", "deny");
expectV("git push -qf origin feat/x", "deny");
expectV("git push -nf origin feat/x", "deny");
expectV("git push origin :feat/x", "deny");
expectV("git -C . push origin :feat/x", "deny");
expectV("git push -u origin feat/maintenance-fix", "ask");
expectV("gh.exe pr merge 12 --admin", "deny");
expectV("gh.exe pr merge 12 --delete-branch", "deny");
expectV("gh pr merge 12 -sd", "deny");
expectV("gh pr merge -d 12", "deny");
// Publicação: grupo em ask; perigosos em deny.
expectV("gh pr create --base main --head feat/x --title t --body-file b.md", "ask");
expectV("gh pr merge 12 --squash", "ask");
expectV("gh pr merge 12 --admin", "deny");
expectV("gh pr merge 12 --auto --squash", "deny");
expectV("gh pr merge 12 --delete-branch", "deny");
expectV("gh pr merge 12 -d", "deny");
expectV("gh release create v1.0.0 --notes-file n.md", "ask");
expectV("gh.exe pr merge 12", "ask");
expectV("glab mr merge 3 --remove-source-branch", "deny");
expectV("az repos pr create --title t", "ask");
expectV("az repos pr update --id 3 --status completed", "deny");
expectV("gh pr review 12 --approve", "deny");
expectV("gh release upload v1 a.zip", "deny");
expectV("gh api repos/o/r/pulls", "deny");

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
const tl = text("plugins/sdd/agents/techlead.md");
const gw = text("plugins/sdd/skills/sdd-rules/references/git-workflow.md");
const MODO = /modo\s+publicação/i;
check("techlead.md define o modo publicação (settings.local.json)", MODO.test(tl) && /settings\.local\.json/.test(tl));
check("git-workflow.md cita o modo publicação nos limites", MODO.test(gw));
const fim = tl.split("5. Fim:")[1] || "";
check("techlead.md: 'Fim' do fluxo Git traz a ressalva do modo publicação", MODO.test(fim.slice(0, 1200)));
check("skill publish existe e não é invocável pelo modelo",
  fs.existsSync(path.join(ROOT, "plugins/sdd/skills/publish/SKILL.md")) && /disable-model-invocation: true/.test(text("plugins/sdd/skills/publish/SKILL.md")));

console.log(`req007-publicacao.test.js: ${pass} ok, ${fail} falha(s)`);
process.exit(fail ? 1 : 0);
