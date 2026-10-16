#!/usr/bin/env node
// sdd: lançador do servidor MCP Chrome DevTools (stdio). .specs/mcp-context7-devtools/spec.md (REQ-003)
// Multiplataforma (no Windows o Claude Code não inicia "npx" direto). Executa exatamente
// `npx -y chrome-devtools-mcp@<versão fixa> <flags fixas>`; o stdio é herdado (stdout só carrega o protocolo MCP).
// Flags: --isolated (perfil temporário, nenhum login/cookie persistido); --no-usage-statistics e --no-performance-crux (telemetria e envio de
// URLs ao CrUX ficam ligados por padrão no pacote); --no-javascript-evaluation (remove evaluate_script e initScript; NÃO é sandbox);
// --no-file-navigations; --redact-network-headers; --no-category-input (a interação é do Playwright; aqui só inspeção) e --no-category-memory
// (heap snapshot lê a memória da página); --blocked-url-pattern para os endereços de metadata de nuvem (defesa em profundidade).
// NUNCA acrescentar --browserUrl, --wsEndpoint, --autoConnect, --userDataDir, --acceptInsecureCerts, --chromeArg, --allowUnrestrictedPaths,
// --workspace, --experimental*, --category-extensions|pwa|third-party|webmcp nem --config sem nova spec e parecer de segurança.
// O ambiente é filtrado: CHROME_DEVTOOLS_MCP_* e npm_config_* não chegam ao servidor (poderiam anular as flags fixas). Única exceção explícita:
// SDD_DEVTOOLS_HEADLESS=1 acrescenta --headless (CI/WSL/testes). Registry corporativo continua valendo pelo .npmrc do usuário.
// A versão é fixa de propósito (pacote de terceiros executado na máquina do usuário; troca só com spec e revisão).
// Falha ao iniciar nunca derruba a sessão: uma linha no stderr e exit 1.
"use strict";
const { spawn } = require("child_process");
const fs = require("fs");
const path = require("path");

const PKG = "chrome-devtools-mcp@1.11.0";
const ARGS = ["-y", PKG, "--isolated", "--no-usage-statistics", "--no-performance-crux", "--no-javascript-evaluation",
  "--no-file-navigations", "--redact-network-headers", "--no-category-input", "--no-category-memory",
  "--blocked-url-pattern", "http://169.254.169.254/*", "--blocked-url-pattern", "http://metadata.google.internal/*"];
if (process.env.SDD_DEVTOOLS_HEADLESS === "1") ARGS.push("--headless");
const ENV = {};
for (const k of Object.keys(process.env)) {
  if (!/^(CHROME_DEVTOOLS_MCP_|npm_config_)/i.test(k)) ENV[k] = process.env[k];
}
const win = process.platform === "win32";

// Preferir o npx-cli.js do próprio Node (sem shell, sem processo órfão); fallback: npx(.cmd).
function launch() {
  const npxCli = path.join(path.dirname(process.execPath), "node_modules", "npm", "bin", "npx-cli.js");
  if (win && fs.existsSync(npxCli)) {
    return spawn(process.execPath, [npxCli, ...ARGS], { stdio: "inherit", windowsHide: true, env: ENV });
  }
  return spawn(win ? "npx.cmd" : "npx", ARGS, { stdio: "inherit", shell: win, windowsHide: true, env: ENV });
}

function fail(e) {
  process.stderr.write("sdd devtools: não consegui iniciar o npx (Node.js/npm instalado?): " + e.message + "\n");
  process.exit(1);
}

let child;
try {
  child = launch();
} catch (e) {
  fail(e);
}
child.on("error", fail);
child.on("exit", (code) => process.exit(code === null ? 1 : code));
for (const s of ["SIGINT", "SIGTERM"]) process.on(s, () => { try { child.kill(s); } catch (e) { /* já encerrou */ } });
