const express = require('express');
const path = require('path');
const fs = require('fs');

const app = express();
const ROOT = __dirname;
const PORT = process.env.PORT || 3000;

// host -> subfolder mapping
const HOSTS = {
  'antibullyingconference.com': 'antibullyingconference',
  'www.antibullyingconference.com': 'antibullyingconference',
  'blackstudentslead.org': 'blackstudentslead',
  'www.blackstudentslead.org': 'blackstudentslead',
  'nsldc.org': 'nsldc',
  'www.nsldc.org': 'nsldc',
  'themillerinstitute.com': 'millerinstitute',
  'www.themillerinstitute.com': 'millerinstitute',
  'latinxleads.org': 'latinxleads',
  'www.latinxleads.org': 'latinxleads',
};

const staticOpts = {
  extensions: ['html'],
  maxAge: '1h',
  setHeaders(res, filePath) {
    if (filePath.includes(`${path.sep}shared${path.sep}`) || filePath.includes(`${path.sep}img${path.sep}`)) {
      res.setHeader('Cache-Control', 'public, max-age=31536000, immutable');
    }
  },
};

app.use((req, res, next) => {
  res.setHeader('X-Content-Type-Options', 'nosniff');
  res.setHeader('Referrer-Policy', 'strict-origin-when-cross-origin');
  res.setHeader('X-Frame-Options', 'SAMEORIGIN');
  next();
});

// /shared/* is global on every host
app.use('/shared', express.static(path.join(ROOT, 'shared'), { maxAge: '1y', immutable: true }));

// Host-based routing
app.use((req, res, next) => {
  const hostHeader = (req.headers.host || '').split(':')[0].toLowerCase();
  const folder = HOSTS[hostHeader];
  if (folder) {
    // Per-host: serve from subfolder as root
    const folderPath = path.join(ROOT, folder);
    // /img/* on the custom-host site resolves from that subfolder
    express.static(folderPath, staticOpts)(req, res, next);
  } else {
    // Default: serve repo root (landing + subfolder browsing)
    next();
  }
});

// Fallback: serve repo root for the default railway domain
app.use(express.static(ROOT, staticOpts));

// 404
app.use((req, res) => {
  const hostHeader = (req.headers.host || '').split(':')[0].toLowerCase();
  const folder = HOSTS[hostHeader];
  const candidate = folder
    ? path.join(ROOT, folder, '404.html')
    : path.join(ROOT, '404.html');
  if (fs.existsSync(candidate)) return res.status(404).sendFile(candidate);
  res.status(404).type('text/plain').send('Not Found');
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Miller Institute sites running on :${PORT}`);
  console.log('Hosts configured:', Object.keys(HOSTS).join(', '));
});
