#!/usr/bin/env node
// sdd: lançador do servidor MCP Context7 (stdio). .specs/mcp-context7-devtools/spec.md (REQ-001)
// Multiplataforma (no Windows o Claude Code não inicia "npx" direto). Executa exatamente
// `npx -y @upstash/context7-mcp@<versão fixa>`; o stdio é herdado (stdout só carrega o protocolo MCP).
// O servidor consulta a API do Context7 (terceiro): as consultas saem da máquina. Por isso o ambiente do servidor é uma LISTA DE
// PERMISSÃO: tokens de GitHub, Atlassian, nuvem etc. nunca chegam a um pacote de terceiros. Única variável de credencial repassada:
// CONTEXT7_API_KEY (opcional, definida pelo próprio usuário; maior limite de uso). NUNCA passar a chave por argumento (--api-key) nem por arquivo.
// NUNCA trocar para `--transport http` nem `--port` sem nova spec e parecer de segurança. A versão é fixa de propósito (pacote de terceiros
// com dependências em faixas do npm executado na máquina do usuário; troca só com spec e revisão). Falha ao iniciar nunca derruba a sessão:
// uma linha no stderr e exit 1.
"use strict";
const { spawn } = require("child_process");
const fs = require("fs");
const path = require("path");

const PKG = "@upstash/context7-mcp@4.4.2";
const ARGS = ["-y", PKG];
const ALLOW = /^(PATH|PATHEXT|HOME|HOMEDRIVE|HOMEPATH|USERPROFILE|APPDATA|LOCALAPPDATA|PROGRAMDATA|PROGRAMFILES(\(X86\))?|TEMP|TMP|TMPDIR|SYSTEMROOT|SYSTEMDRIVE|WINDIR|COMSPEC|OS|USERNAME|USER|LOGNAME|SHELL|TERM|LANG|LANGUAGE|LC_[A-Z]+|TZ|XDG_[A-Z_]+|HTTPS?_PROXY|NO_PROXY|ALL_PROXY|NODE_EXTRA_CA_CERTS|SSL_CERT_FILE|SSL_CERT_DIR|npm_config_(registry|cache|proxy|https_proxy|noproxy|strict_ssl|cafile|userconfig|globalconfig|prefix)|CONTEXT7_API_KEY)$/i;
const ENV = {};
for (const k of Object.keys(process.env)) {
  if (ALLOW.test(k)) ENV[k] = process.env[k];
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
  process.stderr.write("sdd context7: não consegui iniciar o npx (Node.js/npm instalado?): " + e.message + "\n");
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
