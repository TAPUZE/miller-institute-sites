# Handoff — Miller Institute Sites

## Where things live

- **Working copy**: `C:\Users\User\Desktop\miller-institute-sites` (use this path — NOT `C:\Users\User\Desktop\DR Chris ` which has a trailing space and is stale).
- **GitHub**: https://github.com/TAPUZE/miller-institute-sites (branch `main`).
- **Railway project**: `miller-institute-sites`
  - Project ID: `e985a94e-3c48-46cc-ac54-5abe272ed35b`
  - Service ID:  `054989e8-a3ba-499e-9b86-98ff0d5c6a40`
  - Env ID:      `c6b88538-f793-4b00-9e78-dcff9840a7b2`
  - Region: `europe-west4-drams3a`, Builder: Nixpacks, Plan: Hobby (2 custom-domain cap).
- **Preview URL**: https://miller-institute-sites-production.up.railway.app
- **Custom domains attached**: `antibullyingconference.com` + `www.antibullyingconference.com` only (Hobby plan limit = 2).

## Architecture

One Express app (`server.js`) routes 10 hostnames → 5 site folders and serves `/shared/*` globally.

| Folder | Site | Theme accent |
|---|---|---|
| `antibullyingconference/` | Anti-Bullying Conference (ABC) | — |
| `nsldc/` | National Student Leadership Diversity Conference | — |
| `blackstudentslead/` | Black Students Lead (BSL) | — |
| `latinxleads/` | LatinX Leads | — |
| `millerinstitute/` | Center / Miller Institute (CMI) | — |
| `shared/` | `site.css`, `site.js` (hamburger), global assets | |

`server.js` has a **referer-aware rewrite** so that when the preview URL serves a site under `/millerinstitute/`, absolute asset paths like `/img/foo.png` in the HTML get rewritten to `/millerinstitute/img/foo.png`. Do not remove this block.

## Deployment pipeline (IMPORTANT)

**Railway is currently NOT connected to GitHub**, so deploys require `railway up` CLI uploads, which frequently time out on this network.

### One-time fix — connect GitHub so every `git push` auto-deploys:

1. Open: https://railway.com/project/e985a94e-3c48-46cc-ac54-5abe272ed35b/service/054989e8-a3ba-499e-9b86-98ff0d5c6a40/settings
2. **Source** section → **Connect Repo** → pick `TAPUZE/miller-institute-sites`, branch `main` → Save.
3. From then on: `git push origin main` is the entire deploy workflow.

Until that is done, deploys go via:
```powershell
cd C:\Users\User\Desktop\miller-institute-sites
railway up --detach
```
(run once, wait for `Build Logs` URL; do **not** loop retries — uploads often timeout but a single succeeded upload is enough).

## Current status

- HEAD commit pushed to GitHub: `abb0937` — Miller Institute homepage rebuilt to match real themillerinstitute.com (rotating training headlines, About CMI, 3 program categories, Featured Training Programs).
- **That commit is NOT yet deployed on Railway** (last successful build was commit `141dd24`). It will deploy automatically the moment GitHub is connected per step above.

## Design conventions

- Every HTML page links: `/shared/site.css`, its own `theme.css`, `/shared/site.js`.
- Hamburger nav: `shared/site.js` auto-injects `<button class="nav-toggle">` into every `.site-nav`; CSS in `shared/site.css` under `@media (max-width:820px)`.
- Logo sizing is per-site in each `theme.css` (`.brand-logo` + `.footer-logo`). MI footer logo uses `filter: brightness(0) invert(1)` for dark footer.
- Cross-brand/partner footer blocks were intentionally removed — the 5 sites are independent in market.
- Root `index.html` is a **private portal** (`<meta name="robots" content="noindex,nofollow">`) with 5 cards linking to each site — not public landing.

## UTF-8 gotcha (PowerShell 5.1)

Do NOT write HTML with `Set-Content -Encoding UTF8` — it double-encodes `–`, `©`, `↗`. Use:
```powershell
$utf8 = [System.Text.UTF8Encoding]::new($false)
[System.IO.File]::WriteAllText($path, $content, $utf8)
```

## Known pending work

1. **Connect Railway → GitHub** (user's explicit ask, 3 clicks above).
2. Inner pages (~28 files) still need design review — only home pages were rebuilt.
3. One of the 5 custom domains is unreachable per the user — likely because only 2 domains can be attached on Hobby plan (ABC + www.ABC are attached; others need plan upgrade or DNS-only CNAME to preview URL).
4. Content backfill — user noted "some websites are missing some content" but did not specify which. Needs user to pinpoint.

## Files of interest

- [server.js](server.js) — host routing + referer rewrite
- [shared/site.css](shared/site.css) — global styles + mobile nav
- [shared/site.js](shared/site.js) — hamburger injector
- [index.html](index.html) — private portal
- [package.json](package.json), [railway.json](railway.json) — deploy config
- [DEPLOY.md](DEPLOY.md) — original deploy notes

## Quick local test

```powershell
cd C:\Users\User\Desktop\miller-institute-sites
node server.js
# then visit http://localhost:3000/millerinstitute/ etc.
```
