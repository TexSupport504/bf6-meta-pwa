#!/usr/bin/env bash
# deploy.sh — Push the PWA to GitHub Pages.
#
# Usage:
#   ./deploy.sh                       # uses default repo name "bf6-meta-pwa"
#   ./deploy.sh my-custom-repo-name   # custom name
#
# Prereqs:
#   - gh CLI installed and authenticated:  gh auth login
#   - git installed
#
# What it does:
#   1. Creates (or updates) a public repo on your GitHub
#   2. Pushes index.html + manifest + sw.js + icons + weapons.json
#   3. Enables GitHub Pages (free hosting, https URL)
#   4. Prints the URL where your PWA is live
#
# After running this, on your iPhone:
#   1. Open the URL in Safari
#   2. Tap Share → "Add to Home Screen"
#   3. The app icon appears on your home screen — tap it to launch

set -euo pipefail

REPO_NAME="${1:-bf6-meta-pwa}"

# Pretty colors
BOLD="$(tput bold 2>/dev/null || true)"
GREEN="$(tput setaf 2 2>/dev/null || true)"
ORANGE="$(tput setaf 208 2>/dev/null || tput setaf 3 2>/dev/null || true)"
RED="$(tput setaf 1 2>/dev/null || true)"
RESET="$(tput sgr0 2>/dev/null || true)"

step() { printf "\n${BOLD}${ORANGE}▶ %s${RESET}\n" "$*"; }
ok()   { printf "  ${GREEN}✓${RESET} %s\n" "$*"; }
fail() { printf "  ${RED}✗${RESET} %s\n" "$*"; exit 1; }

step "Checking prerequisites"
command -v gh  >/dev/null 2>&1 || fail "gh CLI not installed. Install: brew install gh (mac) or scoop install gh (windows)"
command -v git >/dev/null 2>&1 || fail "git not installed"
gh auth status >/dev/null 2>&1 || fail "Not signed in to gh. Run: gh auth login"
GH_USER="$(gh api user --jq .login)"
ok "Authenticated as $GH_USER"

[[ -f "index.html" ]] || fail "Run from inside the bf6-meta-pwa folder (where index.html lives)."
[[ -f "weapons.json" ]] || fail "weapons.json missing — should be next to index.html"
ok "Project files present"

PAGES_URL="https://${GH_USER}.github.io/${REPO_NAME}/"

# --- Init git if needed ---
if [[ ! -d ".git" ]]; then
  step "Initializing git repo"
  git init -q -b main
  ok "git initialized"
fi

# --- Stage and commit ---
step "Staging files for deploy"
git add index.html manifest.json sw.js icon-192.png icon-512.png favicon.png weapons.json README.md 2>/dev/null || true
if git diff --cached --quiet; then
  ok "(no changes to commit)"
else
  git commit -q -m "Deploy BF6 Meta PWA"
  ok "Changes committed"
fi

# --- Create or update remote ---
if gh repo view "$GH_USER/$REPO_NAME" >/dev/null 2>&1; then
  step "Repo $REPO_NAME exists — pushing updates"
  # Make sure 'origin' points at the right place
  if git remote get-url origin >/dev/null 2>&1; then
    git remote set-url origin "https://github.com/$GH_USER/$REPO_NAME.git"
  else
    git remote add origin "https://github.com/$GH_USER/$REPO_NAME.git"
  fi
  git push -q -u origin main 2>/dev/null || git push -q -u origin main --force-with-lease
  ok "Pushed to existing repo"
else
  step "Creating public repo $REPO_NAME"
  gh repo create "$REPO_NAME" --public --source=. --push --remote=origin >/dev/null
  ok "Repo created"
fi

# --- Enable Pages ---
step "Enabling GitHub Pages"
gh api -X POST "repos/$GH_USER/$REPO_NAME/pages" \
  -f "source[branch]=main" -f "source[path]=/" >/dev/null 2>&1 \
  || gh api -X PUT "repos/$GH_USER/$REPO_NAME/pages" \
       -f "source[branch]=main" -f "source[path]=/" >/dev/null 2>&1 \
  || ok "(Pages may already be enabled — check the repo settings if so)"
ok "Pages configured"

cat <<EOF

${BOLD}${GREEN}═════════════════════════════════════════════════════════════════${RESET}
${BOLD}${GREEN}  ✓ Deployed${RESET}
${BOLD}${GREEN}═════════════════════════════════════════════════════════════════${RESET}

${BOLD}Live URL (give it ~1 minute to publish):${RESET}
  ${ORANGE}${PAGES_URL}${RESET}

${BOLD}On your iPhone:${RESET}
  1. Open the URL above in Safari
  2. Tap the Share button (square with arrow)
  3. Tap "Add to Home Screen"
  4. The BF6 Meta icon appears on your home screen
  5. Tap to launch — it opens full screen, no browser chrome

${BOLD}On Windows / Android:${RESET}
  Same idea — Chrome/Edge will offer "Install app" in the address bar.

${BOLD}Updating data later:${RESET}
  Edit weapons.json → ./deploy.sh → tap Refresh on the About tab.

${BOLD}Repo:${RESET} https://github.com/${GH_USER}/${REPO_NAME}

EOF
