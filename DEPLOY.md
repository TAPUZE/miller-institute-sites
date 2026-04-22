# Deploy

Site is plain static HTML/CSS/JS — deploys anywhere with zero build.

## Fastest: Netlify Drop (no account required for a test URL)
1. Visit https://app.netlify.com/drop
2. Drag the `site.zip` file (or the whole folder) onto the page.
3. You get a live URL immediately. Create a free account to keep it.

## Custom domain on Netlify / Vercel / Cloudflare Pages
All three auto-configure from this repo:
- Netlify reads `netlify.toml`
- Vercel reads `vercel.json`
- Cloudflare Pages needs no config (just "no build command", output = `/`)

### Steps
1. Push this folder to a GitHub repo (`git init && git add . && git commit && git push`).
2. In your host of choice, "New Project" → import the repo.
3. Add your custom domain in the host's dashboard.
4. Point your domain's nameservers (or a CNAME) as the host instructs.

## DNS
**You must do one manual step**: at your domain registrar, either
- change nameservers to the host's nameservers (Cloudflare/Netlify/Vercel), OR
- add a CNAME for `www` and an A/ALIAS record for the apex the host gives you.

No third-party tool can do this without API access to your registrar.
