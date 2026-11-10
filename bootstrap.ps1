# bootstrap.ps1 -- single entry point for a partner's PC (AAAA Coalition partner setup).
#
# Run in an ADMINISTRATOR PowerShell window, during a setup session with the AAAA team:
#   irm https://raw.githubusercontent.com/AAAA-Coalition/partner-pc-bootstrap/main/bootstrap.ps1 | iex
#
# Nothing in this file is secret. The installer and the partner's parameters live in the partner's
# PRIVATE exchange repository (folder setup/), read with the partner's OWN GitHub account after
# they sign in in their browser. This script never sees a password.
#
# What it does, and nothing else:
#   1. installs GitHub CLI if missing (winget) and reloads PATH;
#   2. signs GitHub CLI in to the partner's account (browser: they click Authorize);
#   3. clones their private exchange repository;
#   4. runs setup\installer_pc_partenaire.ps1 from that clone; the installer does the rest and
#      prints GREEN / RED for each step.
# The exchange repository is asked once (owner/name), or passed in $env:PARTENAIRE_DEPOT.

$ErrorActionPreference = "Continue"
function Reload { $env:Path = [Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [Environment]::GetEnvironmentVariable("Path","User") }
function Red([string]$m) { Write-Host "RED: $m" -ForegroundColor Red }

$admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $admin) { Red "open PowerShell as administrator, then run this again."; return }

$repo = $env:PARTENAIRE_DEPOT
if (-not $repo) { $repo = Read-Host "Your exchange repository (owner/name), as given by the AAAA team" }
if ($repo -notmatch "^[A-Za-z0-9-]+/[A-Za-z0-9._-]+$") { Red "repository name not understood: $repo"; return }

# 1. GitHub CLI
Reload
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
  Write-Host "Installing GitHub CLI..." -ForegroundColor Yellow
  winget install --id GitHub.cli -e --silent --accept-package-agreements --accept-source-agreements --disable-interactivity | Out-Null
  Reload
}
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) { Red "GitHub CLI could not be installed (winget)."; return }

# 2. The partner's GitHub account (judged by the exit code, never by the text)
gh auth status *> $null
if ($LASTEXITCODE -ne 0) {
  Write-Host "GITHUB: a browser page opens. Sign in with YOUR personal account, then click Authorize." -ForegroundColor Yellow
  gh auth login --hostname github.com --git-protocol https --web
  gh auth status *> $null
  if ($LASTEXITCODE -ne 0) { Red "GitHub is not connected. Run this again."; return }
}
$who = gh api user --jq .login 2>$null
Write-Host "GitHub connected as $who." -ForegroundColor Green

# 3. The private exchange repository (setup/ holds the installer and the parameters)
$dest = Join-Path $env:USERPROFILE ($repo.Split("/")[-1])
if (-not (Test-Path (Join-Path $dest ".git"))) {
  gh repo clone $repo $dest -- -q
  if ($LASTEXITCODE -ne 0) { Red "cannot clone $repo with account $who (invitation accepted?)."; return }
} else {
  git -C $dest pull -q --ff-only
}
$inst = Join-Path $dest "setup\installer_pc_partenaire.ps1"
$par  = Join-Path $dest "setup\partenaire.json"
if (-not (Test-Path $inst) -or -not (Test-Path $par)) { Red "the setup folder is missing in $repo (installer or partenaire.json). Tell the AAAA team."; return }

# 4. Installer: it does the rest and prints GREEN / RED for each step
Write-Host "Running the installer..." -ForegroundColor Yellow
powershell -NoProfile -ExecutionPolicy Bypass -File $inst -Parametres $par
