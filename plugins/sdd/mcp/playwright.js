#!/usr/bin/env node
// sdd: lançador do servidor MCP Playwright (stdio). .specs/done/playwright-mcp/spec.md
// Multiplataforma (no Windows o Claude Code não inicia "npx" direto). Executa exatamente
// `npx -y @playwright/mcp@<versão fixa> --isolated`; o stdio é herdado (stdout só carrega o protocolo MCP).
// --isolated: perfil só em memória (nenhum login/cookie persistido). --no-webmcp: não expõe ferramentas registradas pela página.
// --blocked-origins: endereços de metadata de nuvem (defesa em profundidade; o pacote diz que origens NÃO são fronteira de segurança).
// NUNCA acrescentar --caps, --no-sandbox, --extension, --allow-unrestricted-file-access, --ignore-https-errors, --user-data-dir nem
// --save-session sem nova spec e parecer de segurança. O ambiente é filtrado: PLAYWRIGHT_MCP_* (cada opção tem variável equivalente e anularia
// as flags fixas, até --extension), PLAYWRIGHT_DOWNLOAD* e npm_config_* não chegam ao servidor. Única exceção explícita:
// SDD_PLAYWRIGHT_HEADLESS=1 acrescenta --headless (CI/WSL/testes). Registry corporativo continua valendo pelo .npmrc do usuário.
// A versão é fixa de propósito (pacote 0.x de terceiros executado na máquina do usuário; troca só com spec e revisão).
// Falha ao iniciar nunca derruba a sessão: uma linha no stderr e exit 1.
"use strict";
const { spawn } = require("child_process");
const fs = require("fs");
const path = require("path");

const PKG = "@playwright/mcp@0.0.83";
const ARGS = ["-y", PKG, "--isolated", "--no-webmcp", "--block-service-workers",
  "--blocked-origins", "http://169.254.169.254;http://metadata.google.internal"];
if (process.env.SDD_PLAYWRIGHT_HEADLESS === "1") ARGS.push("--headless");
const ENV = {};
for (const k of Object.keys(process.env)) {
  if (!/^(PLAYWRIGHT_MCP_|PLAYWRIGHT_DOWNLOAD|npm_config_)/i.test(k)) ENV[k] = process.env[k];
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
  process.stderr.write("sdd playwright: não consegui iniciar o npx (Node.js/npm instalado?): " + e.message + "\n");
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
