// REQ-005 (docs-install): links e âncoras, versões coerentes, comandos do CLI e conteúdo obrigatório da documentação.
// .specs/done/docs-install/spec.md. Sem rede. Os comandos `claude plugin ...` são conferidos no --help do CLI real quando ele existe.
const fs = require("fs");
const path = require("path");
const cp = require("child_process");

const ROOT = path.resolve(__dirname, "../../../..");
let pass = 0, fail = 0;
const ok = (d) => { pass++; console.log("  ok   " + d); };
const bad = (d, extra) => { fail++; console.log("  FAIL " + d + (extra ? " :: " + extra : "")); };
const check = (d, cond, extra) => (cond ? ok(d) : bad(d, extra));
const rd = (p) => fs.readFileSync(path.join(ROOT, p), "utf8").replace(/\r\n/g, "\n");

const MD = ["README.md", "docs/instalacao.md", "docs/primeiros-passos.md", "docs/referencia.md", "docs/arquitetura.md"];
const HTML = ["docs/manual-de-uso.html"];

// ---------- 1) links e âncoras ----------
// Slug do GitHub: minúsculas, sem pontuação (exceto hífen), espaços viram hífen; acentos permanecem.
const slug = (h) => h.trim().toLowerCase()
  .replace(/`/g, "").replace(/<[^>]+>/g, "")
  .replace(/[^\p{L}\p{N}\s_-]/gu, "").replace(/\s/g, "-");
function anchors(file) {
  const out = new Set();
  const seen = {};
  let inCode = false;
  for (const line of rd(file).split("\n")) {
    if (/^```/.test(line)) { inCode = !inCode; continue; }
    if (inCode) continue;
    const m = line.match(/^#{1,6}\s+(.*)$/);
    if (!m) continue;
    let s = slug(m[1]);
    if (seen[s] !== undefined) { seen[s]++; s = s + "-" + seen[s]; } else seen[s] = 0;
    out.add(s);
  }
  return out;
}
const anchorCache = {};
const anchorsOf = (f) => (anchorCache[f] = anchorCache[f] || anchors(f));
const htmlIds = (f) => new Set([...rd(f).matchAll(/\bid="([^"]+)"/g)].map((x) => x[1]));

for (const f of MD) {
  const text = rd(f).replace(/```[\s\S]*?```/g, "");
  const dir = path.dirname(f);
  const links = [...text.matchAll(/\]\(([^)\s]+)\)/g)].map((x) => x[1]).filter((u) => !/^(https?:|mailto:)/.test(u));
  const broken = [];
  for (const u of links) {
    const [rel, frag] = u.split("#");
    const target = rel ? path.normalize(path.join(dir, rel)).replace(/\\/g, "/") : f;
    if (!fs.existsSync(path.join(ROOT, target))) { broken.push(u + " (arquivo)"); continue; }
    if (frag) {
      if (target.endsWith(".md")) { if (!anchorsOf(target).has(frag)) broken.push(u + " (âncora)"); }
      else if (target.endsWith(".html")) { if (!htmlIds(target).has(frag)) broken.push(u + " (id)"); }
    }
  }
  check(`links de ${f} resolvem (${links.length})`, broken.length === 0, broken.join(" | "));
}
for (const f of HTML) {
  const text = rd(f);
  const dir = path.dirname(f);
  const links = [...text.matchAll(/\bhref="([^"#][^"]*)"/g)].map((x) => x[1]).filter((u) => !/^(https?:|mailto:|data:)/.test(u));
  const broken = [];
  for (const u of links) {
    const [rel] = u.split("#");
    if (!rel) continue;
    if (!fs.existsSync(path.join(ROOT, path.normalize(path.join(dir, rel))))) broken.push(u);
  }
  check(`links de ${f} resolvem (${links.length})`, broken.length === 0, broken.join(" | "));
}

// ---------- 2) versões coerentes ----------
const ver = JSON.parse(rd("plugins/sdd/.claude-plugin/plugin.json")).version;
const mk = JSON.parse(rd(".claude-plugin/marketplace.json"));
check(`marketplace.json metadata.version = ${ver}`, mk.metadata && mk.metadata.version === ver, mk.metadata && mk.metadata.version);
const tpl = JSON.parse(rd("templates/project-settings.git.json"));
const tplRef = tpl.extraKnownMarketplaces["claude-sdd-framework"].source.ref;
check(`ref do template = v${ver}`, tplRef === "v" + ver, tplRef);
check("README: badge do sdd", rd("README.md").includes(`plugin%20sdd-${ver}-`));
check("arquitetura: tabela de versões", rd("docs/arquitetura.md").includes(`| \`sdd\` | ${ver} |`));
check("manual: selo de versão", rd("docs/manual-de-uso.html").includes(`sdd ${ver} · authoring`));
check("check-env.sh: SDD_VERSION", rd("scripts/check-env.sh").includes(`SDD_VERSION="${ver}"`));
check("check-env.ps1: SddVersion", rd("scripts/check-env.ps1").includes(`$SddVersion = "${ver}"`));
const allDocs = [...MD, ...HTML].map((f) => [f, rd(f)]);
const refs = [];
for (const [f, t] of allDocs) {
  for (const m of t.matchAll(/claude-sdd-framework\.git[#@]v(\d+\.\d+\.\d+)/g)) if (m[1] !== ver) refs.push(`${f}: ${m[0]}`);
  for (const m of t.matchAll(/"ref":\s*"v(\d+\.\d+\.\d+)"/g)) if (m[1] !== ver) refs.push(`${f}: ${m[0]}`);
}
check(`todo "#vX.Y.Z" e "ref" das docs = v${ver}`, refs.length === 0, refs.join(" | "));

// versão mínima do CLI igual em todos os lugares
const minSh = (rd("scripts/check-env.sh").match(/MIN_CLAUDE="([\d.]+)"/) || [])[1];
const minPs = (rd("scripts/check-env.ps1").match(/\$MinClaude\s*=\s*\[version\]"([\d.]+)"/) || [])[1];
check("versão mínima do CLI igual em check-env.sh e .ps1", minSh && minSh === minPs, `${minSh} / ${minPs}`);
check("versão mínima do CLI no README (badge) e na instalação", rd("README.md").includes(`Claude%20Code-%E2%89%A5%20${minSh}-`) && rd("docs/instalacao.md").includes(minSh), minSh);

// ---------- 3) conteúdo obrigatório da instalação ----------
const inst = rd("docs/instalacao.md");
for (const h of ["A. Máquina sem Claude Code", "B. Projeto novo (pasta vazia)", "C. Projeto com código existente", "D. Projeto que já usa o sdd", "E. Atualizar a versão", "F. Clone local (quem mexe no framework)", "Problemas comuns"]) {
  check(`instalacao.md tem a seção "${h}"`, new RegExp("^## " + h.replace(/[.*+?^${}()|[\]\\]/g, "\\$&") + "$", "m").test(inst));
}
for (const need of ["https://claude.ai/install.sh", "https://claude.ai/install.ps1", "claude --version", "claude auth status", "claude doctor", "git --version".replace("--version", "ls-remote"), "Git for Windows", "claude plugin marketplace add", "claude plugin install sdd@claude-sdd-framework --scope project", "claude plugin list", "/sdd:start", "scripts/check-env.sh", "check-env.ps1"]) {
  check(`instalacao.md cita "${need}"`, inst.includes(need));
}
check("instalacao.md tem o fluxograma de decisão (mermaid)", /```mermaid[\s\S]*Q1[\s\S]*```/.test(inst));
check("instalacao.md: README aponta para cada tipo A a F", ["a-máquina-sem-claude-code", "b-projeto-novo-pasta-vazia", "c-projeto-com-código-existente", "d-projeto-que-já-usa-o-sdd", "e-atualizar-a-versão", "f-clone-local-quem-mexe-no-framework"].every((a) => rd("README.md").includes("instalacao.md#" + a)));
check("README curto (<= 130 linhas)", rd("README.md").split("\n").length <= 130, String(rd("README.md").split("\n").length));
for (const f of ["scripts/check-env.sh", "scripts/check-env.ps1", "templates/project-settings.git.json", "templates/project-settings.local.json"]) check(`${f} existe`, fs.existsSync(path.join(ROOT, f)));

// ---------- 4) comandos `claude plugin ...` existem no CLI ----------
let claude = null;
for (const c of ["claude", path.join(process.env.HOME || process.env.USERPROFILE || "", ".local", "bin", "claude" + (process.platform === "win32" ? ".exe" : ""))]) {
  const r = cp.spawnSync(c, ["--version"], { encoding: "utf8" });
  if (r.status === 0) { claude = c; break; }
}
if (!claude) {
  ok("claude não disponível: conferência dos subcomandos pulada");
} else {
  const help = (args) => cp.spawnSync(claude, args.concat("--help"), { encoding: "utf8" }).stdout || "";
  const names = (txt) => new Set([...txt.matchAll(/^\s{2}([a-z][a-z-]*)(?:\|[a-z]+)?\s/gm)].map((m) => m[1]));
  const top = names(help(["plugin"]));
  const mp = names(help(["plugin", "marketplace"]));
  const used = new Set();
  const usedMp = new Set();
  const src = [...allDocs.map(([, t]) => t), rd("scripts/check-env.sh"), rd("scripts/check-env.ps1")].join("\n");
  for (const m of src.matchAll(/claude plugin (marketplace )?([a-z][a-z-]*)/g)) (m[1] ? usedMp : used).add(m[2]);
  used.delete("marketplace");
  const missTop = [...used].filter((c) => !top.has(c));
  const missMp = [...usedMp].filter((c) => !mp.has(c));
  check(`subcomandos "claude plugin <x>" citados existem (${[...used].join(", ")})`, missTop.length === 0, missTop.join(","));
  check(`subcomandos "claude plugin marketplace <x>" citados existem (${[...usedMp].join(", ")})`, missMp.length === 0, missMp.join(","));
  check("claude plugin install aceita --scope", /--scope/.test(help(["plugin", "install"])));
  check("claude plugin update aceita --scope", /--scope/.test(help(["plugin", "update"])));
  check("claude plugin enable aceita --scope", /--scope/.test(help(["plugin", "enable"])));
  check("claude plugin list aceita --json", /--json/.test(help(["plugin", "list"])));
  check("claude auth status existe", /status/.test(help(["auth"])));
}

console.log(`req014-docs.test.js: ${pass} ok, ${fail} falha(s)`);
process.exit(fail ? 1 : 0);
