#!/usr/bin/env node
// sdd: lançador do servidor MCP draw.io (stdio). .specs/done/drawio-mcp/spec.md
// Multiplataforma: no Windows o Claude Code não consegue iniciar "npx" direto (é npx.cmd); aqui o Node resolve isso.
// Executa exatamente `npx -y @drawio/mcp@<versão fixa>`; o stdio é herdado (stdout só carrega o protocolo MCP).
// A versão é fixa de propósito: trocar só com spec e revisão de segurança (pacote de terceiros executado na máquina do usuário).
// Falha ao iniciar nunca derruba a sessão: uma linha no stderr e exit 1.
"use strict";
const { spawn } = require("child_process");
const fs = require("fs");
const path = require("path");

const PKG = "@drawio/mcp@1.7.0";
const win = process.platform === "win32";

// Preferir o npx-cli.js do próprio Node (sem shell, sem processo órfão); fallback: npx(.cmd).
function launch() {
  const npxCli = path.join(path.dirname(process.execPath), "node_modules", "npm", "bin", "npx-cli.js");
  if (win && fs.existsSync(npxCli)) {
    return spawn(process.execPath, [npxCli, "-y", PKG], { stdio: "inherit", windowsHide: true });
  }
  return spawn(win ? "npx.cmd" : "npx", ["-y", PKG], { stdio: "inherit", shell: win, windowsHide: true });
}

let child;
try {
  child = launch();
} catch (e) {
  process.stderr.write("sdd drawio: não consegui iniciar o npx (Node.js/npm instalado?): " + e.message + "\n");
  process.exit(1);
}
child.on("error", (e) => {
  process.stderr.write("sdd drawio: não consegui iniciar o npx (Node.js/npm instalado?): " + e.message + "\n");
  process.exit(1);
});
child.on("exit", (code) => process.exit(code === null ? 1 : code));
for (const s of ["SIGINT", "SIGTERM"]) process.on(s, () => { try { child.kill(s); } catch (e) { /* já encerrou */ } });
