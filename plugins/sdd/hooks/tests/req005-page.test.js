// REQ-005 (tela): teste de página em Chrome/Edge headless controlado por CDP (Node >= 22, sem dependências).
// Fluxo real ponta a ponta: office-start.sh cria a sala e copia a página; eventos entram por office-event.sh.
// Segurança do teste (A6): perfil temporário dedicado; encerra SÓ o PID iniciado aqui (nunca por nome de processo);
// não abre o navegador padrão; não toca ~/.claude (CLAUDE_CONFIG_DIR temporário).
// Uso: node req005-page.test.js   (OFFICE_TEST_BROWSER=caminho do chrome/msedge; OFFICE_TEST_SHOTS=pasta dos screenshots)
"use strict";
const fs = require("fs");
const os = require("os");
const path = require("path");
const net = require("net");
const http = require("http");
const { spawn, spawnSync, execFileSync } = require("child_process");
const { pathToFileURL } = require("url");

const HOOKS = path.resolve(__dirname, "..");
const SHOTS = process.env.OFFICE_TEST_SHOTS || fs.mkdtempSync(path.join(os.tmpdir(), "office-shots-"));
fs.mkdirSync(SHOTS, { recursive: true });

let pass = 0, fail = 0;
const ok = (m) => { pass++; console.log("  ok   " + m); };
const bad = (m) => { fail++; console.log("  FAIL " + m); };
const check = (m, cond, extra) => (cond ? ok(m) : bad(m + (extra !== undefined ? " [" + extra + "]" : "")));
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const posix = (p) => p.replace(/\\/g, "/").replace(/^([A-Za-z]):/, (m, d) => "/" + d.toLowerCase());

// No Windows, "bash" no PATH pode ser o do WSL; os hooks do plugin assumem o Git Bash.
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

  // ---- sandbox do projeto/sala
  const sb = fs.mkdtempSync(path.join(os.tmpdir(), "office-page-"));
  const env = Object.assign({}, process.env, {
    CLAUDE_CONFIG_DIR: posix(path.join(sb, "cfg")), TMPDIR: posix(path.join(sb, "tmp")), CLAUDE_PROJECT_DIR: "/c/fake/page-test",
    SDD_OFFICE_OS: "linux", DISPLAY: "", WAYLAND_DISPLAY: "" });
  fs.mkdirSync(path.join(sb, "cfg", "sdd"), { recursive: true });
  fs.mkdirSync(path.join(sb, "tmp"), { recursive: true });
  fs.writeFileSync(path.join(sb, "cfg", "sdd", "office.conf"), "on\n");
  const start = spawnSync(BASH, [posix(path.join(HOOKS, "office-start.sh"))], { env, encoding: "utf8" });
  check("start cria a sala sem abrir navegador (open=skipped)", /open=skipped/.test(start.stdout), start.stdout);
  const officeRoot = path.join(sb, "tmp", fs.readdirSync(path.join(sb, "tmp")).filter((n) => n.startsWith("sdd-office-"))[0]);
  const room = path.join(officeRoot, fs.readdirSync(officeRoot)[0]);
  const eventsFile = path.join(room, "events.js");
  fs.writeFileSync(eventsFile, ""); // começa sem eventos: estado "aguardando"
  const hook = (obj) => spawnSync(BASH, [posix(path.join(HOOKS, "office-event.sh"))], { env, input: typeof obj === "string" ? obj : JSON.stringify(obj), encoding: "utf8" });

  // ---- navegador headless com perfil temporário dedicado
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
    try { fs.rmSync(sb, { recursive: true, force: true, maxRetries: 5, retryDelay: 300 }); } catch (e) { /* perfil ainda travado: pasta temporária própria */ }
    console.log("req005-page.test.js: " + pass + " ok, " + fail + " falha(s)");
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
    let id = 0; const pend = {}; const problems = []; let expectMissing = false;
    ws.onmessage = (e) => {
      const m = JSON.parse(e.data);
      if (m.id && pend[m.id]) { pend[m.id](m); delete pend[m.id]; return; }
      if (m.method === "Runtime.exceptionThrown") problems.push("exceção: " + JSON.stringify(m.params.exceptionDetails.text) + " " + (m.params.exceptionDetails.exception && m.params.exceptionDetails.exception.description || ""));
      if (m.method === "Log.entryAdded" && m.params.entry.level === "error" && expectMissing && /events\.js\?t=/.test(m.params.entry.url || "")) return; // falta intencional do arquivo (passo 9)
      if (m.method === "Log.entryAdded" && (m.params.entry.level === "error")) problems.push("log: " + m.params.entry.text + " " + (m.params.entry.url || ""));
      if (m.method === "Runtime.consoleAPICalled" && m.params.type === "error") problems.push("console.error");
    };
    const cdp = (method, params) => new Promise((r) => { const i = ++id; pend[i] = r; ws.send(JSON.stringify({ id: i, method, params: params || {} })); });
    const js = async (expr) => { const r = await cdp("Runtime.evaluate", { expression: expr, returnByValue: true }); if (r.result.exceptionDetails) throw new Error(JSON.stringify(r.result.exceptionDetails)); return r.result.result.value; };
    const waitFor = async (expr, ms) => { const t0 = Date.now(); while (Date.now() - t0 < (ms || 8000)) { try { const v = await js(expr); if (v) return v; } catch (e) { /* ignore */ } await sleep(150); } return false; };
    const shot = async (name) => { const r = await cdp("Page.captureScreenshot", { format: "png" }); fs.writeFileSync(path.join(SHOTS, name + ".png"), Buffer.from(r.result.data, "base64")); };
    const logText = () => js("Array.from(document.querySelectorAll('#log li')).map(function(l){return l.textContent;}).join(' || ')");
    const node = (agent) => js("(function(){var l=document.querySelector('#roster li[data-agent=\"" + agent + "\"]');return l?l.dataset.node+'/'+l.dataset.state:null;})()");
    const waitLog = (needle, ms) => waitFor("document.getElementById('log').textContent.indexOf(" + JSON.stringify(needle) + ")>=0", ms || 12000);

    await cdp("Page.enable"); await cdp("Runtime.enable"); await cdp("Log.enable");
    await cdp("Page.navigate", { url: pathToFileURL(path.join(room, "office.html")).href });
    check("página carrega (título)", await waitFor("document.title==='Salinha dos agentes (sdd)'"));

    // 1) aguardando / vazio
    await sleep(1800);
    check("aguardando: status 'Aguardando agentes...'", (await js("document.getElementById('status').textContent")) === "Aguardando agentes...");
    check("vazio: convite à ação visível", (await js("!document.getElementById('empty').hidden")) === true);
    check("tecleader presente e ocioso na mesa", (await node("tecleader")) === "seat/idle", await node("tecleader"));
    check("canvas tem role=img e aria-label", (await js("document.getElementById('cv').getAttribute('role')+'|'+document.getElementById('cv').getAttribute('aria-label')")).startsWith("img|Salinha dos agentes"));
    check("html lang=pt-BR e botão de pausa presente", (await js("document.documentElement.lang+'|'+!!document.getElementById('pause')")) === "pt-BR|true");
    await shot("1-aguardando");

    // 2) pedido do usuário e delegação em paralelo
    hook({ hook_event_name: "UserPromptSubmit", prompt: "texto-secreto-do-usuario" });
    check("prompt: popup 'TecLeader: recebeu um pedido'", await waitLog("TecLeader: recebeu um pedido"));
    check("status vira 'Ativo' e vazio some", (await js("document.getElementById('status').textContent")) === "Ativo" && (await js("document.getElementById('empty').hidden")) === true);
    check("tecleader trabalhando", (await node("tecleader")) === "seat/working", await node("tecleader"));
    hook({ hook_event_name: "PreToolUse", tool_name: "Agent", tool_input: { description: "Implementar T-003", subagent_type: "sdd:backend", prompt: "x" } });
    hook({ hook_event_name: "PreToolUse", tool_name: "Agent", tool_input: { description: "Tela de login T-004", subagent_type: "sdd:frontend", prompt: "x" } });
    check("delegação: 'TecLeader → delegou \"Implementar T-003\" ao backend'", await waitLog('TecLeader → delegou "Implementar T-003" ao backend'));
    check("delegação paralela: frontend também", await waitLog('"Tela de login T-004" ao frontend'));
    hook({ hook_event_name: "SubagentStart", agent_type: "sdd:backend", agent_id: "b1b1b1" });
    hook({ hook_event_name: "SubagentStart", agent_type: "sdd:frontend", agent_id: "f1f1f1" });
    check("backend e frontend chegam e sentam (animação de caminhada concluída)",
      await waitFor("(function(){var b=document.querySelector('#roster li[data-agent=backend]'),f=document.querySelector('#roster li[data-agent=frontend]');return b&&f&&b.dataset.node==='seat'&&f.dataset.node==='seat';})()", 15000));
    await shot("2-delegacao-paralela");
    hook({ hook_event_name: "PreToolUse", agent_type: "sdd:backend", agent_id: "b1b1b1", tool_name: "Edit", tool_input: { file_path: "C:/segredo/arquivo-privado.cs", new_string: "senha=hunter2" } });
    check("popup 'backend: editando arquivos' (sem nome de arquivo)", await waitLog("backend: editando arquivos"));
    check("trabalhando: backend working", (await node("backend")) === "seat/working", await node("backend"));
    hook({ hook_event_name: "SubagentStart", agent_type: "sdd:tests", agent_id: "t1" });
    hook({ hook_event_name: "PreToolUse", agent_type: "sdd:tests", agent_id: "t1", tool_name: "Bash", tool_input: { command: "dotnet test --secret abc" } });
    check("popup 'tests: rodando validação'", await waitLog("tests: rodando validação"));
    const allText = await js("document.body.innerText");
    check("privacidade na tela: sem segredos/arquivos/comandos", !/hunter2|arquivo-privado|segredo|dotnet test|texto-secreto/.test(allText));
    await shot("3-trabalhando");

    // 3) entrega: backend anda até a mesa do TecLeader e volta
    hook({ hook_event_name: "SubagentStop", agent_type: "sdd:backend", agent_id: "b1b1b1", last_assistant_message: "resposta-secreta" });
    check("entrega: popup 'backend entregou o resultado ao TecLeader'", await waitLog("backend entregou o resultado ao TecLeader"));
    check("entrega: backend caminha", await waitFor("document.querySelector('#roster li[data-agent=backend]').dataset.node==='walking'", 6000));
    check("entrega: backend chega à mesa do TecLeader", await waitFor("document.querySelector('#roster li[data-agent=backend]').dataset.node==='tec'", 15000));
    await shot("4-entrega");
    check("entrega: backend volta à própria mesa e fica ocioso", await waitFor("(function(){var l=document.querySelector('#roster li[data-agent=backend]');return l.dataset.node==='seat'&&l.dataset.state==='idle';})()", 20000), await node("backend"));

    // 4) segurança vai para a reunião
    hook({ hook_event_name: "SubagentStart", agent_type: "sdd:security", agent_id: "s1" });
    hook({ hook_event_name: "PreToolUse", agent_type: "sdd:security", agent_id: "s1", tool_name: "Read", tool_input: { file_path: "x" } });
    check("security: vai à sala de reunião", await waitFor("document.querySelector('#roster li[data-agent=security]')&&document.querySelector('#roster li[data-agent=security]').dataset.node==='meet'", 20000), await node("security"));
    check("security: estado 'em reunião'", (await node("security")) === "meet/meeting", await node("security"));
    await shot("5-reuniao-seguranca");

    // 5) agente desconhecido ganha mesa; nomes perigosos são tratados como dado
    hook({ hook_event_name: "SubagentStart", agent_type: "sdd:zeta-novo", agent_id: "z1" });
    check("agente desconhecido aparece no roster", await waitFor("!!document.querySelector('#roster li[data-agent=\"zeta-novo\"]')", 6000));
    // forjados direto no arquivo (sem passar pelo hook): a página também valida.
    const forged = [
      { i: "9-1-1", t: Math.floor(Date.now() / 1000), e: "tool", a: "__proto__", d: "", k: "read", m: "", g: "" },
      { i: "9-1-2", t: Math.floor(Date.now() / 1000), e: "tool", a: "constructor", d: "", k: "edit", m: "", g: "" },
      { i: "9-1-3", t: Math.floor(Date.now() / 1000), e: "tool", a: "<script>x</script>", d: "", k: "read", m: "", g: "" },
      { i: "9-1-4", t: Math.floor(Date.now() / 1000), e: "eval", a: "backend", d: "", k: "", m: "", g: "" },
      { i: "9-1-5", t: Math.floor(Date.now() / 1000), e: "tool", a: "", d: "", k: "delegate", m: "<img src=x onerror=\"window.__pwn=1\"> <b>negrito</b>", g: "backend" },
      { i: "9-1-6", t: "agora", e: "tool", a: "backend", d: "", k: "read", m: "", g: "" },
      { i: "9-1-7", t: Math.floor(Date.now() / 1000), e: "tool", a: "backend", d: "", k: "read", m: 12345, g: ["x"] },
    ];
    fs.appendFileSync(eventsFile, forged.map((o) => "E(" + JSON.stringify(o) + ");").join("\n") + "\nE(null);\nE(42);\nE({});\n");
    check("XSS: descrição forjada com <img onerror> é tratada como texto", await waitLog("img src x onerror"), await logText());
    await sleep(1500);
    check("XSS: nenhum <img> nem <b> no DOM e nada executou", (await js("document.querySelectorAll('img,b,svg').length+'|'+String(window.__pwn)")) === "0|undefined");
    check("XSS: log/balões não contêm '<'", (await js("document.body.innerHTML.indexOf('<img')<0 && document.getElementById('log').textContent.indexOf('<')<0")) === true);
    check("forjados: eventos inválidos não criam personagens (__proto__, <script>)", (await js("Array.from(document.querySelectorAll('#roster li')).map(function(l){return l.dataset.agent;}).join(',')")).indexOf("script") < 0);
    check("página continua viva após eventos forjados", (await js("document.getElementById('status').textContent")) === "Ativo");
    await shot("6-forjados-tratados-como-texto");

    // 6) pausa
    await js("document.getElementById('pause').click()");
    check("pausa: aria-pressed=true e rótulo 'Retomar animação'", (await js("document.getElementById('pause').getAttribute('aria-pressed')+'|'+document.getElementById('pause').textContent")) === "true|Retomar animação");
    hook({ hook_event_name: "SubagentStop", agent_type: "sdd:tests", agent_id: "t1" });
    await waitLog("tests entregou o resultado");
    await sleep(2500);
    const frozen = await node("tests");
    check("pausa: personagem fica parado (não chega à mesa do TecLeader)", frozen === "walking/delivering" || frozen === "seat/delivering", frozen);
    await js("document.getElementById('pause').click()");
    check("retomar: personagem segue e volta ao normal", await waitFor("(function(){var l=document.querySelector('#roster li[data-agent=tests]');return l.dataset.node==='seat'&&l.dataset.state==='idle';})()", 25000), await node("tests"));

    // 7) prefers-reduced-motion (emulado): sem caminhada, posições instantâneas
    await cdp("Emulation.setEmulatedMedia", { features: [{ name: "prefers-reduced-motion", value: "reduce" }] });
    await sleep(400);
    hook({ hook_event_name: "SubagentStop", agent_type: "sdd:frontend", agent_id: "f1f1f1" });
    let sawWalking = false, sawTec = false;
    const t0 = Date.now();
    while (Date.now() - t0 < 6000) {
      const n = await node("frontend");
      if (n && n.indexOf("walking") === 0) sawWalking = true;
      if (n && n.indexOf("tec/") === 0) sawTec = true;
      await sleep(40);
    }
    check("reduced-motion: nunca em 'walking' (troca de posição instantânea)", !sawWalking);
    check("reduced-motion: ainda faz a entrega (passa por 'tec')", sawTec);
    check("reduced-motion: lista de texto continua atualizando", await waitLog("frontend entregou o resultado ao TecLeader"));
    await shot("7-reduced-motion");
    await cdp("Emulation.setEmulatedMedia", { features: [{ name: "prefers-reduced-motion", value: "no-preference" }] });

    // 8) sem atividade (relógio avançado 6 min dentro da página)
    await js("(function(){window.__rn=Date.now;Date.now=function(){return window.__rn()+6*60*1000;};})()");
    check("sem atividade: status 'Sem atividade'", await waitFor("document.getElementById('status').textContent.indexOf('Sem atividade')===0", 4000));
    check("sem atividade: todos ociosos", await waitFor("Array.from(document.querySelectorAll('#roster li')).every(function(l){return l.dataset.state==='idle';})", 4000));
    await shot("8-sem-atividade");
    await js("(function(){Date.now=window.__rn;})()");

    // 9) erro: events.js some => aviso com ação de recuperação; volta => aviso some
    expectMissing = true;
    fs.unlinkSync(eventsFile);
    check("erro: aviso 'Não foi possível ler os eventos' visível", await waitFor("!document.getElementById('notice').hidden", 8000));
    check("erro: aviso tem botão Recarregar e não mostra caminho", (await js("document.getElementById('notice').textContent")).indexOf("Recarregar a página") >= 0 && !/Users|AppData|sdd-office/.test(await js("document.getElementById('notice').textContent")));
    await shot("9-erro");
    fs.writeFileSync(eventsFile, "");
    check("erro: aviso some quando o arquivo volta", await waitFor("document.getElementById('notice').hidden", 8000));
    expectMissing = false;

    // 10) layout responsivo (mobile) e sem rolagem horizontal
    await cdp("Emulation.setDeviceMetricsOverride", { width: 375, height: 800, deviceScaleFactor: 1, mobile: true });
    await sleep(500);
    check("mobile 375px: sem rolagem horizontal", (await js("document.documentElement.scrollWidth<=document.documentElement.clientWidth+1")) === true, await js("document.documentElement.scrollWidth+'/'+document.documentElement.clientWidth"));
    await shot("10-mobile");
    await cdp("Emulation.clearDeviceMetricsOverride");

    check("nenhuma exceção/erro de console/violação de CSP durante o teste", problems.length === 0, problems.join(" ; "));
    console.log("  info screenshots em " + SHOTS);
    await done();
  } catch (e) {
    bad("erro inesperado no teste: " + (e && e.stack || e));
    await done(1);
  }
})();
