# BF6 Meta — PWA

Battlefield 6 weapon mod explorer as an installable web app. Works on iPhone, Android, Windows, Mac, anything with a browser. No App Store, no $99/yr fee, no Mac required to build.

**Live demo (after you deploy):** `https://YOUR_USERNAME.github.io/bf6-meta-pwa/`

---

## What's in v1

- **Browse** — class chips (Assault, Carbine, SMG, LMG, DMR, Sniper, Shotgun, Handgun) + global search
- **Detail** — tier badge, 6-stat panel, hexagonal radar chart, full 7-slot loadout, playstyle notes, favorite toggle
- **Compare** — pick any two weapons, side-by-side with the winning stat highlighted in orange
- **Loadouts** — build & save full kits: primary + secondary + 2 gadgets, named ("Conquest Anchor", etc.)
- **Favorites** — starred weapons, sorted by tier
- **About** — data version, refresh-from-server button, weapons-per-class breakdown
- **Tactical theme** — graphite background, orange accent, color-coded tier badges
- **Offline-first** — service worker caches everything; works without internet after first load
- **Installable** — "Add to Home Screen" gives it an icon and full-screen app feel

---

## Files

```
bf6-meta-pwa/
├── index.html           ← single-file React app, all 5 screens
├── weapons.json         ← 55 weapons + 19 gadgets (edit to update meta)
├── manifest.json        ← PWA install config
├── sw.js                ← service worker (offline support)
├── icon-192.png         ← home screen icon
├── icon-512.png         ← splash screen icon
├── favicon.png          ← browser tab icon
├── deploy.sh            ← one-shot deploy to GitHub Pages (Mac/Linux/WSL)
├── deploy.ps1           ← same, for Windows PowerShell
└── README.md            ← this file
```

---

## Deploy in 60 seconds

### Windows (PowerShell)

```powershell
# One-time prereqs:
winget install --id GitHub.cli
winget install --id Git.Git
gh auth login

# In the bf6-meta-pwa folder:
.\deploy.ps1
```

### Mac / Linux / WSL

```bash
# One-time prereqs:
brew install gh    # mac, or `sudo apt install gh` on linux
gh auth login

# In the bf6-meta-pwa folder:
./deploy.sh
```

What the script does:
1. Creates a public GitHub repo named `bf6-meta-pwa` (or whatever name you pass)
2. Pushes all the PWA files
3. Enables GitHub Pages on the `main` branch
4. Prints your live URL

GitHub Pages takes ~30–60 seconds to publish on first deploy. After that, every redeploy is near-instant.

---

## Install on your iPhone

1. Open the live URL in **Safari** (not Chrome — iOS only allows install from Safari)
2. Tap the Share button (square with up arrow)
3. Scroll down → **Add to Home Screen**
4. Tap **Add**
5. The BF6 Meta icon appears on your home screen
6. Tap it → opens full-screen with no Safari chrome

Now it behaves like a real app. It even appears in the app switcher with its own task.

## Install on Android / Windows / Mac

Open the URL in Chrome, Edge, or Brave. The browser will offer "Install app" in the address bar — click it. Chrome on Android adds it to your home screen automatically; on desktop, it gets a Start Menu / Dock entry like a regular app.

---

## Updating weapon data

Two ways:

### Option 1 — Edit + redeploy (clean)

```bash
# Edit weapons.json with your changes
# Then:
./deploy.sh
```

The site updates within 60 seconds. Users get fresh data next time they open the app — or sooner if they tap **Refresh from server** on the About tab.

### Option 2 — GitHub web editor (no terminal)

1. Go to your repo on GitHub
2. Click `weapons.json`
3. Click the pencil icon to edit
4. Save with a commit message
5. GitHub Pages republishes automatically in ~60 seconds

---

## Schema

To add a weapon, append to the `weapons` array in `weapons.json`:

```json
{
  "id": "assault-new-rifle",
  "name": "New Rifle",
  "class": "Assault",
  "tier": "S",
  "rpm": 700, "damage": 30, "magazine": 30,
  "rangeMeters": 60, "control": 50, "mobility": 60,
  "mods": {
    "muzzle": "Compensator",
    "barrel": "Standard Barrel",
    "underbarrel": "Vertical Grip",
    "magazine": "Default 30RND",
    "ammo": "FMJ",
    "optic": "Red Dot Sight",
    "stock": "Standard Stock"
  },
  "notes": "How it plays."
}
```

For a gadget, append to the `gadgets` array:

```json
{
  "id": "gadget-new-thing",
  "name": "New Thing",
  "classRestriction": "Engineer",
  "tier": "A",
  "role": "Anti-vehicle",
  "description": "What it does."
}
```

Tier values: `S`, `A`, `B`, `C`. Gadget classRestriction: `Any`, `Assault`, `Support`, `Engineer`, `Recon`.

---

## Testing locally

Spin up a tiny local server (the PWA needs `http://`, not `file://`):

```bash
# Python (preinstalled on Mac, easy on Windows)
python -m http.server 8000

# Or Node:
npx serve
```

Then open `http://localhost:8000` in any browser.

---

## How it works under the hood

- **No build step** — React via CDN, JSX compiled in-browser by Babel standalone, plain CSS
- **Offline-first via service worker** — caches index.html, JS, JSON; "network-first" for `weapons.json` so refresh always tries fresh data, falls back to cache
- **localStorage for favorites + loadouts** — no backend, no account
- **iOS Safari "Add to Home Screen"** uses the manifest.json + apple-touch-icon for a native-feel install
- **First load:** ~150KB total (Babel is the heaviest, ~80KB gzipped). Cached on second load.

---

## Tradeoffs vs the native iOS app

The iOS app I built earlier (in the BF6MetaApp.zip) has these things the PWA doesn't:

- iCloud sync (favorites/loadouts cross-device) — PWA uses localStorage per-device
- Lock Screen widget — PWAs can't have widgets on iOS
- App Store distribution — PWA is just a URL
- Native scroll feel and haptic feedback

What the PWA has that iOS doesn't:

- Builds on Windows
- $0 cost forever
- Updates are instant (no App Review)
- Works on Android, Mac, PC, anyone's phone
- Just send a URL to share

For a personal reference tool you check before/during BF6 sessions, the PWA wins. For App Store distribution and ecosystem polish, the iOS app wins.

---

Built 2026-04-25. Data current as of BF6 Season 2: Hunter/Prey.
