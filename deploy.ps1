# deploy.ps1 — Push the PWA to GitHub Pages (Windows PowerShell version).
#
# Usage:
#   .\deploy.ps1                      # default repo name "bf6-meta-pwa"
#   .\deploy.ps1 my-repo-name         # custom name
#
# Prereqs:
#   - gh CLI installed:   winget install --id GitHub.cli   (or: scoop install gh)
#   - gh authenticated:   gh auth login
#   - git installed:      winget install --id Git.Git

param(
    [string]$RepoName = "bf6-meta-pwa"
)

$ErrorActionPreference = "Stop"

function Step($msg) { Write-Host "`n▶ $msg" -ForegroundColor Yellow }
function Ok($msg)   { Write-Host "  ✓ $msg" -ForegroundColor Green }
function Fail($msg) { Write-Host "  ✗ $msg" -ForegroundColor Red; exit 1 }

Step "Checking prerequisites"
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Fail "gh CLI not installed. Run: winget install --id GitHub.cli"
}
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Fail "git not installed. Run: winget install --id Git.Git"
}
& gh auth status 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) { Fail "Not signed in to gh. Run: gh auth login" }
$ghUser = (& gh api user --jq .login).Trim()
Ok "Authenticated as $ghUser"

if (-not (Test-Path "index.html"))   { Fail "Run from the bf6-meta-pwa folder (where index.html lives)." }
if (-not (Test-Path "weapons.json")) { Fail "weapons.json missing." }
Ok "Project files present"

$pagesUrl = "https://$ghUser.github.io/$RepoName/"

if (-not (Test-Path ".git")) {
    Step "Initializing git repo"
    & git init -q -b main
    Ok "git initialized"
}

Step "Staging files"
$files = @("index.html", "manifest.json", "sw.js", "icon-192.png", "icon-512.png", "favicon.png", "weapons.json", "README.md")
$existing = $files | Where-Object { Test-Path $_ }
& git add $existing 2>&1 | Out-Null
& git diff --cached --quiet 2>&1 | Out-Null
if ($LASTEXITCODE -eq 0) {
    Ok "(no changes to commit)"
} else {
    & git commit -q -m "Deploy BF6 Meta PWA" 2>&1 | Out-Null
    Ok "Changes committed"
}

# Check if repo exists
& gh repo view "$ghUser/$RepoName" 2>&1 | Out-Null
if ($LASTEXITCODE -eq 0) {
    Step "Repo $RepoName exists — pushing updates"
    & git remote get-url origin 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        & git remote set-url origin "https://github.com/$ghUser/$RepoName.git"
    } else {
        & git remote add origin "https://github.com/$ghUser/$RepoName.git"
    }
    & git push -q -u origin main 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        & git push -q -u origin main --force-with-lease 2>&1 | Out-Null
    }
    Ok "Pushed to existing repo"
} else {
    Step "Creating public repo $RepoName"
    & gh repo create $RepoName --public --source=. --push --remote=origin 2>&1 | Out-Null
    Ok "Repo created"
}

Step "Enabling GitHub Pages"
$body1 = '{"source":{"branch":"main","path":"/"}}'
$body1 | & gh api -X POST "repos/$ghUser/$RepoName/pages" --input - 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    $body1 | & gh api -X PUT "repos/$ghUser/$RepoName/pages" --input - 2>&1 | Out-Null
}
Ok "Pages configured (may already be enabled)"

Write-Host "`n═════════════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "  ✓ Deployed" -ForegroundColor Green
Write-Host "═════════════════════════════════════════════════════════════════" -ForegroundColor Green

Write-Host "`nLive URL (give it ~1 minute to publish):"
Write-Host "  $pagesUrl" -ForegroundColor Yellow

Write-Host "`nOn your iPhone:"
Write-Host "  1. Open the URL above in Safari"
Write-Host "  2. Tap the Share button"
Write-Host "  3. Tap `"Add to Home Screen`""
Write-Host "  4. Tap the new icon to launch full-screen"

Write-Host "`nOn Windows / Android:"
Write-Host "  Same idea — Chrome/Edge offers `"Install app`" in the address bar."

Write-Host "`nUpdating data later:"
Write-Host "  Edit weapons.json -> .\deploy.ps1 -> tap Refresh on the About tab."

Write-Host "`nRepo: https://github.com/$ghUser/$RepoName`n"
