# Verifica o ambiente para instalar o plugin sdd (Windows/PowerShell): CLI do Claude Code, git, bash, marketplace e a pasta atual.
# SOMENTE LEITURA. Uso: powershell -ExecutionPolicy Bypass -File scripts\check-env.ps1 [-Net] [-Dir <pasta>]
# Sai com 0 se está tudo pronto e com 1 se faltar algo. Passo a passo: docs\instalacao.md. Equivalente a scripts/check-env.sh.
param(
  [switch]$Net,
  [string]$Dir = (Get-Location).Path
)

try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch { }
$SddVersion = "0.12.0"            # versão do framework (o teste confere com plugin.json)
$MinClaude  = [version]"2.1.288"
$RepoUrl    = "https://github.com/powerlok/claude-sdd-framework.git"
$Doc        = "docs/instalacao.md"

if (-not (Test-Path -LiteralPath $Dir -PathType Container)) { Write-Output "pasta não encontrada: $Dir"; exit 2 }
Set-Location -LiteralPath $Dir

$script:Fail = 0
$script:Next = ""
function Ok($m)   { Write-Output "  [OK]     $m" }
function Warn($m, $fix = "") { Write-Output "  [AVISO]  $m"; if ($fix) { Write-Output "           -> $fix" } }
function Miss($m, $fix = "", $next = "") {
  Write-Output "  [FALTA]  $m"
  if ($fix) { Write-Output "           -> $fix" }
  $script:Fail = 1
  if (-not $script:Next) { if ($next) { $script:Next = $next } else { $script:Next = $fix } }
}
function Has($name) { return [bool](Get-Command $name -ErrorAction SilentlyContinue) }

Write-Output "Verificação do ambiente (somente leitura) - sdd $SddVersion"
Write-Output ""
Write-Output "1. Claude Code (CLI)"
$claude = $null
if (Has "claude") {
  $claude = "claude"
} elseif ((Test-Path "$HOME\.local\bin\claude.exe") -or (Test-Path "$HOME\.local\bin\claude")) {
  Miss "claude está instalado, mas fora do PATH ($HOME\.local\bin)" '$env:Path += ";$HOME\.local\bin"   (permanente: veja docs/instalacao.md)' "Corrija o PATH ($Doc#a-máquina-sem-claude-code)"
} else {
  Miss "claude não encontrado" "irm https://claude.ai/install.ps1 | iex" "Instale o Claude Code: irm https://claude.ai/install.ps1 | iex (detalhes: $Doc#a-máquina-sem-claude-code)"
}

if ($claude) {
  $v = (& $claude --version 2>$null | Select-Object -First 1)
  $m = [regex]::Match("$v", '\d+\.\d+\.\d+')
  if (-not $m.Success) {
    Warn "não consegui ler a versão de 'claude --version' ($v)"
  } elseif ([version]$m.Value -ge $MinClaude) {
    Ok "claude $($m.Value) (mínimo $MinClaude)"
  } else {
    Miss "claude $($m.Value) é anterior ao mínimo $MinClaude" "claude update" "Atualize o Claude Code: claude update"
  }
  & $claude auth status *> $null
  if ($LASTEXITCODE -eq 0) {
    Ok "login feito (claude auth status)"
  } else {
    Miss "sem login no Claude Code" "claude auth login   (ou rode claude e siga o login no navegador)" "Faça login: rode claude (ou claude auth login) e siga o navegador"
  }
}

Write-Output ""
Write-Output "2. Git e shell"
if (Has "git") {
  Ok ((& git --version 2>$null | Select-Object -First 1))
} else {
  Miss "git não encontrado" "instale o Git for Windows: https://git-scm.com/download/win (traz o Git Bash)" "Instale o Git for Windows: https://git-scm.com/download/win"
}
if (Has "bash") {
  Ok "bash disponível (os hooks do plugin usam bash)"
} else {
  Miss "bash não encontrado no PATH (os hooks do plugin usam bash)" "instale o Git for Windows (traz o Git Bash) e reabra o terminal" "Instale o Git for Windows (traz o Git Bash) e reabra o terminal"
}

if ($Net) {
  Write-Output ""
  Write-Output "3. Rede (GitHub)"
  $env:GIT_TERMINAL_PROMPT = "0"
  $okNet = $false
  if (Has "git") { & git ls-remote --heads $RepoUrl *> $null; if ($LASTEXITCODE -eq 0) { $okNet = $true } }
  if ($okNet) { Ok "git ls-remote do repositório do framework funcionou" }
  else { Miss "sem acesso a $RepoUrl" "git ls-remote $RepoUrl   (veja proxy/firewall/DNS)" "Resolva o acesso ao github.com (proxy, firewall ou DNS)" }
}

Write-Output ""
Write-Output "4. Marketplace do framework (nesta máquina)"
$mpOk = $false
if ($claude) {
  $mp = (& $claude plugin marketplace list 2>$null) -join "`n"
  if ($mp -match 'claude-sdd-framework') {
    $src = ""
    $lines = $mp -split "`n"
    for ($i = 0; $i -lt $lines.Count; $i++) {
      if ($lines[$i] -match 'claude-sdd-framework') {
        for ($j = $i; $j -lt [Math]::Min($i + 4, $lines.Count); $j++) { if ($lines[$j] -match 'Source:') { $src = $lines[$j]; break } }
        break
      }
    }
    $mpOk = $true
    if ($src -match "@v$([regex]::Escape($SddVersion))") { Ok "claude-sdd-framework registrado em v$SddVersion" }
    elseif ($src -match '@v') { Warn "registrado em outra versão: $($src.Trim())" "veja $Doc#e-atualizar-a-versão" }
    else { Warn "registrado sem versão fixada (acompanha a branch principal)" "para fixar a versão: $Doc#e-atualizar-a-versão" }
  } else {
    Miss "marketplace claude-sdd-framework não registrado" "claude plugin marketplace add `"$RepoUrl#v$SddVersion`"" "Registre o marketplace: claude plugin marketplace add `"$RepoUrl#v$SddVersion`""
  }
} else {
  Warn "pulado (sem claude)"
}

Write-Output ""
Write-Output "5. Pasta atual: $Dir"
$here = (Get-Location).Path
function Norm($p) { return (("$p" -replace '\\', '/') -replace '/+', '/').TrimEnd('/').ToLower() }

# raiz do repositório git (sobe até 20 níveis)
$isGit = $false; $root = $null
$d = $here
for ($n = 0; $n -lt 20 -and $d; $n++) {
  if (Test-Path -LiteralPath (Join-Path $d ".git")) { $isGit = $true; $root = $d; break }
  $parent = Split-Path -Parent $d
  if (-not $parent -or $parent -eq $d) { break }
  $d = $parent
}
$subrepos = @(Get-ChildItem -LiteralPath $here -Directory -ErrorAction SilentlyContinue | Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName ".git") }).Count
$ignore = @('.git', '.claude', '.vscode', '.idea')
$entries = @(Get-ChildItem -LiteralPath $here -Force -ErrorAction SilentlyContinue | Where-Object { $ignore -notcontains $_.Name }).Count
$manifests = @('package.json','angular.json','pyproject.toml','requirements.txt','pom.xml','build.gradle','build.gradle.kts','go.mod','Cargo.toml','Dockerfile')
$code = $false
foreach ($mf in $manifests) { if (Test-Path -LiteralPath (Join-Path $here $mf)) { $code = $true } }
if (Get-ChildItem -LiteralPath $here -File -ErrorAction SilentlyContinue | Where-Object { $_.Extension -in '.csproj','.sln','.tf' }) { $code = $true }

$settings = Join-Path $here ".claude\settings.json"
$hasSdd = $false
if (Test-Path -LiteralPath $settings) { if ((Get-Content -LiteralPath $settings -Raw) -match 'sdd@claude-sdd-framework') { $hasSdd = $true } }

if (-not $isGit -and $subrepos -gt 0) {
  Write-Output "  Tipo: workspace com $subrepos repositórios (sem git na raiz)"
  Warn "o sdd é instalado em cada projeto (repositório), não na pasta-mãe" "entre na pasta de um projeto e rode este script de novo ($Doc)"
  $type = "workspace"
} elseif ($hasSdd) { Write-Output "  Tipo: D, projeto que já usa o sdd"; $type = "D" }
elseif ($entries -eq 0) { Write-Output "  Tipo: B, projeto novo (pasta vazia)"; $type = "B" }
elseif ($code) { Write-Output "  Tipo: C, projeto com código existente"; $type = "C" }
else { Write-Output "  Tipo: C, pasta com arquivos (sem manifesto de código conhecido)"; $type = "C" }

if ($type -ne "workspace") {
  if ($isGit) {
    Ok "dentro de um repositório git"
    if ($root -and ((Norm $root) -ne (Norm $here))) { Warn "a raiz do repositório git é $root, acima desta pasta" "o sdd é instalado na raiz do repositório: rode este script (e os passos) em $root" }
  }
  else { Miss "a pasta não é um repositório git" "git init" "Crie o repositório: git init (a raiz do repositório é a raiz do projeto)" }

  if (Test-Path -LiteralPath $settings) {
    $txt = Get-Content -LiteralPath $settings -Raw
    if ($hasSdd) {
      Ok ".claude/settings.json declara o sdd"
      if ($txt -match '"agent"\s*:\s*"sdd:techlead"') { Ok "agente da sessão = sdd:techlead" }
      elseif ($txt -match 'sdd:tecleader') { Miss "o settings usa sdd:tecleader (removido na 0.11.0)" 'troque por "agent": "sdd:techlead"' 'Troque "agent": "sdd:tecleader" por "agent": "sdd:techlead" no .claude/settings.json' }
      else { Warn 'sem "agent": "sdd:techlead" no settings (a sessão não abre como TechLead)' 'acrescente "agent": "sdd:techlead" (modelo: templates/project-settings.git.json)' }
    } else {
      Miss ".claude/settings.json existe, mas não declara o sdd" "mescle o modelo templates/project-settings.git.json" "Mescle o modelo templates/project-settings.git.json no .claude/settings.json ($Doc)"
    }
  } else {
    Miss "sem .claude/settings.json" "copie templates/project-settings.git.json para .claude/settings.json" "Copie templates/project-settings.git.json para .claude/settings.json ($Doc)"
  }

  if ($claude -and $mpOk) {
    $base = $here; if ($root) { $base = $root }
    $hereN = Norm $base
    $found = $null
    $json = (& $claude plugin list --json 2>$null) -join "`n"
    if ($json) {
      try { $items = $json | ConvertFrom-Json } catch { $items = @() }
      foreach ($it in @($items)) {
        if ($it.id -ne "sdd@claude-sdd-framework") { continue }
        $pp = Norm $it.projectPath
        if ($it.scope -eq "user" -or ($pp -and ("$hereN/").StartsWith("$pp/"))) { $found = $it; break }
      }
    }
    if (-not $found) {
      Miss "plugin sdd não instalado neste projeto" "claude plugin install sdd@claude-sdd-framework --scope project" "Instale o plugin na raiz do projeto: claude plugin install sdd@claude-sdd-framework --scope project"
    } elseif ($found.enabled -eq $true) {
      Ok "plugin sdd $($found.version) instalado e habilitado (escopo $($found.scope))"
    } else {
      Miss "plugin sdd $($found.version) instalado, mas DESABILITADO (escopo $($found.scope))" "claude plugin enable sdd@claude-sdd-framework --scope $($found.scope)" "Habilite o plugin: claude plugin enable sdd@claude-sdd-framework --scope $($found.scope)"
    }
  }

  $cmd = Join-Path $here "CLAUDE.md"
  if ((Test-Path -LiteralPath $cmd) -and ((Get-Content -LiteralPath $cmd -Raw) -match '(?m)^## Stack')) { Ok "CLAUDE.md com ## Stack (onboarding feito)" }
  else { Warn "sem CLAUDE.md com ## Stack: o onboarding ainda não foi feito" "abra o claude e rode /sdd:start (o TechLead cria o CLAUDE.md com a sua confirmação)" }
}

Write-Output ""
if ($script:Fail -eq 0) {
  Write-Output "PRÓXIMO PASSO: abra o claude nesta pasta e digite /sdd:start"
  exit 0
}
Write-Output "PRÓXIMO PASSO: $($script:Next)"
exit 1
