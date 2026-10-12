// REQ-006 (office-working-state): o agente fica "trabalhando" de SubagentStart até SubagentStop, mesmo em silêncio.
// Cobre REQ-001..003 e REQ-005 da spec .specs/office-working-state. Chrome/Edge headless via CDP (Node >= 22, sem dependências).
// Tempo virtual: Date.now da página é deslocado (nada de esperar minutos). Segurança do teste: perfil temporário dedicado,
// encerra SÓ o PID iniciado aqui, não abre o navegador padrão (SDD_OFFICE_OS=linux + preferência só no sandbox), não toca ~/.claude.
// Uso: node req006-working.test.js   (OFFICE_TEST_BROWSER=caminho do chrome/msedge; OFFICE_TEST_SHOTS=pasta dos screenshots)
"use strict";
const fs = require("fs");
const os = require("os");
const path = require("path");
const net = require("net");
const http = require("http");
const { spawn, spawnSync, execFileSync } = require("child_process");
const { pathToFileURL } = require("url");

const HOOKS = path.resolve(__dirname, "..");
const SHOTS = process.env.OFFICE_TEST_SHOTS || fs.mkdtempSync(path.join(os.tmpdir(), "office-shots6-"));
fs.mkdirSync(SHOTS, { recursive: true });

let pass = 0, fail = 0;
const ok = (m) => { pass++; console.log("  ok   " + m); };
const bad = (m) => { fail++; console.log("  FAIL " + m); };
const check = (m, cond, extra) => (cond ? ok(m) : bad(m + (extra !== undefined ? " [" + extra + "]" : "")));
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const posix = (p) => p.replace(/\\/g, "/").replace(/^([A-Za-z]):/, (m, d) => "/" + d.toLowerCase());
const BASH = [process.env.OFFICE_TEST_BASH, "C:/Program Files/Git/usr/bin/bash.exe", "C:/Program Files/Git/bin/bash.exe"].filter(Boolean).find((p) => fs.existsSync(p)) || "bash";

function findBrowser() {
  const c = [process.env.OFFICE_TEST_BROWSER,
    "C:/Program Files/Google/Chrome/Application/chrome.exe",
    "C:/Program Files (x86)/Google/Chrome/Application/chrome.exe",
    "C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe",
    "C:/Program Files/Microsoft/Edge/Application/msedge.exe",
    "/usr/bin/google-chrome", "/usr/bin/chromium", "/usr/bin/chromium-browser",
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"].filter(Boolean);
  return c.find((p) => fs.existsSync(p));
}
function freePort() {
  return new Promise((res) => { const s = net.createServer(); s.listen(0, "127.0.0.1", () => { const p = s.address().port; s.close(() => res(p)); }); });
}
function getJson(url) {
  return new Promise((res, rej) => http.get(url, (r) => { let d = ""; r.on("data", (c) => (d += c)); r.on("end", () => { try { res(JSON.parse(d)); } catch (e) { rej(e); } }); }).on("error", rej));
}

(async () => {
  const browser = findBrowser();
  if (!browser) { console.log("SKIP: nenhum Chrome/Edge encontrado (defina OFFICE_TEST_BROWSER)"); process.exit(0); }

  const sb = fs.mkdtempSync(path.join(os.tmpdir(), "office-work-"));
  const env = Object.assign({}, process.env, {
    CLAUDE_CONFIG_DIR: posix(path.join(sb, "cfg")), TMPDIR: posix(path.join(sb, "tmp")), CLAUDE_PROJECT_DIR: "/c/fake/work-test",
    SDD_OFFICE_OS: "linux", DISPLAY: "", WAYLAND_DISPLAY: "" });
  fs.mkdirSync(path.join(sb, "cfg", "sdd"), { recursive: true });
  fs.mkdirSync(path.join(sb, "tmp"), { recursive: true });
  fs.writeFileSync(path.join(sb, "cfg", "sdd", "office.conf"), "on\n");
  const start = spawnSync(BASH, [posix(path.join(HOOKS, "office-start.sh"))], { env, encoding: "utf8" });
  check("start cria a sala sem abrir navegador (open=skipped)", /open=skipped/.test(start.stdout), start.stdout);
  const officeRoot = path.join(sb, "tmp", fs.readdirSync(path.join(sb, "tmp")).filter((n) => n.startsWith("sdd-office-"))[0]);
  const room = path.join(officeRoot, fs.readdirSync(officeRoot)[0]);
  const eventsFile = path.join(room, "events.js");
  fs.writeFileSync(eventsFile, "");
  const hook = (obj) => spawnSync(BASH, [posix(path.join(HOOKS, "office-event.sh"))], { env, input: JSON.stringify(obj), encoding: "utf8" });

  const port = await freePort();
  const profile = path.join(sb, "profile");
  const child = spawn(browser, ["--headless=new", "--remote-debugging-port=" + port, "--user-data-dir=" + profile,
    "--no-first-run", "--no-default-browser-check", "--disable-extensions", "--disable-gpu", "--window-size=1280,900", "about:blank"],
    { stdio: "ignore", windowsHide: true });
  const killBrowser = () => {
    try {
      if (process.platform === "win32") execFileSync("taskkill", ["/PID", String(child.pid), "/T", "/F"], { stdio: "ignore" });
      else process.kill(child.pid);
    } catch (e) { /* já encerrado */ }
  };
  let ws;
  const done = async (code) => {
    try { if (ws) ws.close(); } catch (e) { /* ignore */ }
    killBrowser();
    await sleep(800);
    try { fs.rmSync(sb, { recursive: true, force: true, maxRetries: 5, retryDelay: 300 }); } catch (e) { /* pasta temporária própria */ }
    console.log("req006-working.test.js: " + pass + " ok, " + fail + " falha(s)");
    process.exit(code !== undefined ? code : fail ? 1 : 0);
  };

  try {
    let tries = 0, ver;
    while (!ver && tries++ < 60) { try { ver = await getJson("http://127.0.0.1:" + port + "/json/version"); } catch (e) { await sleep(250); } }
    if (!ver) throw new Error("navegador não respondeu no CDP");
    console.log("  info navegador: " + ver.Browser + " (pid " + child.pid + ", perfil temporário dedicado)");
    const targets = await getJson("http://127.0.0.1:" + port + "/json");
    const page = targets.find((t) => t.type === "page");
    ws = new WebSocket(page.webSocketDebuggerUrl);
    await new Promise((r, j) => { ws.onopen = r; ws.onerror = j; });
    let id = 0; const pend = {}; const problems = [];
    ws.onmessage = (e) => {
      const m = JSON.parse(e.data);
      if (m.id && pend[m.id]) { pend[m.id](m); delete pend[m.id]; return; }
      if (m.method === "Runtime.exceptionThrown") problems.push("exceção: " + JSON.stringify(m.params.exceptionDetails.text));
      if (m.method === "Log.entryAdded" && m.params.entry.level === "error") problems.push("log: " + m.params.entry.text);
    };
    const cdp = (method, params) => new Promise((r) => { const i = ++id; pend[i] = r; ws.send(JSON.stringify({ id: i, method, params: params || {} })); });
    const js = async (expr) => { const r = await cdp("Runtime.evaluate", { expression: expr, returnByValue: true }); if (r.result.exceptionDetails) throw new Error(JSON.stringify(r.result.exceptionDetails)); return r.result.result.value; };
    const waitFor = async (expr, ms) => { const t0 = Date.now(); while (Date.now() - t0 < (ms || 8000)) { try { const v = await js(expr); if (v) return v; } catch (e) { /* ignore */ } await sleep(150); } return false; };
    const shot = async (name) => { const r = await cdp("Page.captureScreenshot", { format: "png" }); fs.writeFileSync(path.join(SHOTS, name + ".png"), Buffer.from(r.result.data, "base64")); };
    const node = (agent) => js("(function(){var l=document.querySelector('#roster li[data-agent=\"" + agent + "\"]');return l?l.dataset.node+'/'+l.dataset.state:null;})()");
    const rosterText = (agent) => js("(function(){var l=document.querySelector('#roster li[data-agent=\"" + agent + "\"]');return l?l.textContent:null;})()");
    const logAll = () => js("document.getElementById('log').textContent");
    // Tempo virtual: desloca o relógio da página em ms (acumulativo sobre o relógio real).
    const skew = (ms) => js("(function(){if(!window.__rn)window.__rn=Date.now;window.__off=" + ms + ";Date.now=function(){return window.__rn()+window.__off;};})()");
    const open = async () => { await cdp("Page.navigate", { url: pathToFileURL(path.join(room, "office.html")).href }); await waitFor("document.title==='Salinha dos agentes (sdd)'"); await sleep(1500); };
    const seconds = () => Math.floor(Date.now() / 1000);
    const ev = (n, t, e, a, k) => "E(" + JSON.stringify({ i: "7-" + n + "-1", t: t, e: e, a: a || "", d: a ? "d" + a : "", k: k || "", m: "", g: "" }) + ");\n";

    await cdp("Page.enable"); await cdp("Runtime.enable"); await cdp("Log.enable");
    await open();

    // ---- REQ-001/REQ-005: start -> tool(read) -> silêncio de 90 s (virtual) => continua trabalhando
    hook({ hook_event_name: "SubagentStart", agent_type: "sdd:tests", agent_id: "t1" });
    hook({ hook_event_name: "PreToolUse", agent_type: "sdd:tests", agent_id: "t1", tool_name: "Read", tool_input: { file_path: "x" } });
    check("req001: tests chega, senta e trabalha", await waitFor("(function(){var l=document.querySelector('#roster li[data-agent=tests]');return l&&l.dataset.node==='seat'&&l.dataset.state==='working';})()", 15000), await node("tests"));
    await skew(90 * 1000);
    await sleep(2500);
    check("req001: após 90 s sem eventos continua trabalhando", (await node("tests")) === "seat/working", await node("tests"));
    await shot("w1-silencio-90s");
    await skew(10 * 60 * 1000);
    await sleep(2500);
    check("req001: após 10 min sem eventos continua trabalhando", (await node("tests")) === "seat/working", await node("tests"));
    check("req003: roster mostra 'trabalhando' com o tempo ('há 10 min')", /trabalhando.*10 min/.test(await rosterText("tests")), await rosterText("tests"));
    check("req003: log indica agente ativo em silêncio ('tests: trabalhando há')", await waitFor("document.getElementById('log').textContent.indexOf('tests: trabalhando há')>=0", 6000), await logAll());
    check("req001: status segue 'Ativo' (proteção só após 30 min)", (await js("document.getElementById('status').textContent")) === "Ativo");
    await shot("w2-silencio-10min");

    // ---- stop encerra o trabalho
    hook({ hook_event_name: "SubagentStop", agent_type: "sdd:tests", agent_id: "t1" });
    check("req001: stop dispara a entrega (estado 'entregando')", await waitFor("document.querySelector('#roster li[data-agent=tests]').dataset.state==='delivering'", 6000), await node("tests"));
    check("req001: stop encerra (volta à mesa e ocioso)", await waitFor("(function(){var l=document.querySelector('#roster li[data-agent=tests]');return l.dataset.node==='seat'&&l.dataset.state==='idle';})()", 25000), await node("tests"));
    await sleep(2500);
    check("req001: após stop permanece ocioso (não volta a trabalhando)", (await node("tests")) === "seat/idle", await node("tests"));

    // ---- REQ-002: abrir a página tarde reconstrói o estado do events.js
    const now = seconds();
    fs.writeFileSync(eventsFile,
      ev(1, now - 900, "prompt") +
      ev(2, now - 890, "start", "backend") + ev(3, now - 880, "tool", "backend", "edit") + ev(4, now - 800, "stop", "backend") +
      ev(5, now - 600, "start", "tests") + ev(6, now - 599, "tool", "tests", "read"));
    await open();
    check("req002: abertura tardia: tests (start sem stop) aparece trabalhando", (await node("tests")) === "seat/working", await node("tests"));
    check("req002: abertura tardia: backend (start e stop) fica ocioso", (await node("backend")) === "seat/idle", await node("backend"));
    check("req002/003: roster mostra tempo ativo ('há 10 min') só com horários gravados", /trabalhando.*10 min/.test(await rosterText("tests")), await rosterText("tests"));
    check("req003: log da abertura tardia mostra 'tests: trabalhando há'", await waitFor("document.getElementById('log').textContent.indexOf('tests: trabalhando há')>=0", 6000), await logAll());
    await skew(5 * 60 * 1000);
    await sleep(2500);
    check("req002: abertura tardia segue trabalhando após mais 5 min virtuais", (await node("tests")) === "seat/working", await node("tests"));
    await shot("w3-abertura-tardia");

    // ---- REQ-001: proteção de >= 30 min sem nenhum evento => "sem atividade", distinto de "ocioso"
    await skew(31 * 60 * 1000);
    check("req001: 31 min sem eventos: status 'Sem atividade'", await waitFor("document.getElementById('status').textContent.indexOf('Sem atividade')===0", 4000), await js("document.getElementById('status').textContent"));
    check("req001: tests fica 'sem atividade' (estado quiet, não 'ocioso')", await waitFor("(function(){var l=document.querySelector('#roster li[data-agent=tests]');return l.dataset.state==='quiet'&&/sem atividade/.test(l.textContent)&&!/ocioso/.test(l.textContent);})()", 4000), await rosterText("tests"));
    await shot("w4-sem-atividade-30min");
    // novo evento: sai do "sem atividade" e o agente ativo volta a trabalhar
    await skew(0);
    hook({ hook_event_name: "PreToolUse", agent_type: "sdd:tests", agent_id: "t2", tool_name: "Bash", tool_input: { command: "x" } });
    check("req001: novo evento tira o agente de 'sem atividade' (volta a trabalhando)", await waitFor("(function(){var l=document.querySelector('#roster li[data-agent=tests]');return l.dataset.state==='working';})()", 6000), await node("tests"));

    // ---- reduced-motion e pausa: continua trabalhando, sem caminhar
    await cdp("Emulation.setEmulatedMedia", { features: [{ name: "prefers-reduced-motion", value: "reduce" }] });
    await skew(3 * 60 * 1000);
    await sleep(2500);
    check("reduced-motion: ativo em silêncio segue trabalhando", (await node("tests")) === "seat/working", await node("tests"));
    await js("document.getElementById('pause').click()");
    await skew(6 * 60 * 1000);
    await sleep(2500);
    check("pausa: estado 'trabalhando' preservado", (await node("tests")) === "seat/working", await node("tests"));
    await js("document.getElementById('pause').click()");
    await cdp("Emulation.setEmulatedMedia", { features: [{ name: "prefers-reduced-motion", value: "no-preference" }] });

    check("nenhuma exceção/erro durante o teste", problems.length === 0, problems.join(" ; "));
    console.log("  info screenshots em " + SHOTS);
    await done();
  } catch (e) {
    bad("erro inesperado no teste: " + (e && e.stack || e));
    await done(1);
  }
})();
