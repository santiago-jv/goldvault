import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const PORT = 3000;
const SB_URL = 'https://spjvxvmhosptezmteypm.supabase.co';
const SB_KEY = 'sb_publishable_uXP3oxhMoUXdsMDdIv71Cg_L1SA4C6B';

const MIME_TYPES = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'application/javascript; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.png': 'image/png',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
  '.css': 'text/css; charset=utf-8',
};

const PREVIEW_HTML = `<!DOCTYPE html>
<html lang="es-CO">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no, viewport-fit=cover">
  <title>GoldVault — Finanzas Personales & Puente OAuth APK</title>
  <meta name="description" content="GoldVault — Claridad sobre tu dinero: registro automático de bancos, metas y análisis en tiempo real.">
  <meta property="og:title" content="GoldVault — Finanzas Personales">
  <meta property="og:description" content="GoldVault — Claridad sobre tu dinero: registro automático de bancos, metas y análisis en tiempo real.">
  <link rel="icon" type="image/png" href="/favicon.png"/>
  <link rel="manifest" href="/manifest.json">
  <style>
    :root {
      --bg: #0e0f12;
      --card: #14161b;
      --card2: #191c22;
      --txt: #ece7dd;
      --mut: #8b867c;
      --line: rgba(236, 231, 221, 0.12);
      --acc: #d9b87a;
      --ink: #17130b;
      --green: #6fa882;
    }
    * { box-sizing: border-box; }
    html, body {
      margin: 0;
      padding: 0;
      background-color: var(--bg);
      color: var(--txt);
      font-family: -apple-system, BlinkMacSystemFont, "Plus Jakarta Sans", "Segoe UI", Roboto, sans-serif;
      min-height: 100vh;
    }
    .wrap {
      max-width: 960px;
      margin: 0 auto;
      padding: 28px 20px 60px;
    }
    .header {
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 16px;
      padding-bottom: 20px;
      border-bottom: 1px solid var(--line);
      margin-bottom: 28px;
    }
    .logo {
      font-size: 22px;
      font-weight: 800;
      letter-spacing: -0.4px;
      color: var(--txt);
      text-decoration: none;
    }
    .logo span { color: var(--acc); }
    .grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
      gap: 20px;
    }
    .card {
      background: var(--card);
      border: 1px solid var(--line);
      border-radius: 18px;
      padding: 24px;
    }
    h1 {
      font-size: 24px;
      font-weight: 800;
      letter-spacing: -0.4px;
      margin: 0 0 10px;
    }
    h2 {
      font-size: 16px;
      font-weight: 700;
      margin: 0 0 8px;
    }
    p {
      font-size: 14px;
      line-height: 1.55;
      color: var(--mut);
      margin: 0 0 18px;
    }
    .btn {
      display: inline-flex;
      align-items: center;
      justify-content: center;
      min-height: 46px;
      padding: 0 18px;
      border-radius: 11px;
      font-size: 14px;
      font-weight: 800;
      text-decoration: none;
      cursor: pointer;
      border: none;
      background: var(--acc);
      color: var(--ink);
      width: 100%;
      margin-bottom: 10px;
    }
    .btn-sec {
      display: inline-flex;
      align-items: center;
      justify-content: center;
      min-height: 44px;
      padding: 0 16px;
      border-radius: 11px;
      font-size: 13px;
      font-weight: 600;
      text-decoration: none;
      cursor: pointer;
      background: transparent;
      color: var(--txt);
      border: 1px solid var(--line);
      width: 100%;
    }
    code {
      font-family: ui-monospace, SFMono-Regular, Menlo, monospace;
      font-size: 12px;
      background: var(--card2);
      padding: 3px 6px;
      border-radius: 6px;
      color: var(--acc);
      word-break: break-all;
    }
    .step-list {
      margin: 0;
      padding-left: 18px;
      color: var(--txt);
      font-size: 13px;
      line-height: 1.65;
    }
    .step-list li { margin-bottom: 8px; }
  </style>
</head>
<body>
  <script>
    (function() {
      var search = window.location.search || '';
      var hash = window.location.hash || '';
      var params = new URLSearchParams(search);
      var hashParams = new URLSearchParams(hash.replace(/^#/, ''));

      var isApkBridge = params.get('apk_redirect') === '1' ||
                        hashParams.get('apk_redirect') === '1' ||
                        window.location.pathname.indexOf('/apk-callback') === 0;

      var hasAuthPayload = params.has('code') ||
                           params.has('error') ||
                           hashParams.has('access_token') ||
                           hashParams.has('error');

      if (isApkBridge) {
        var deepLink = 'goldvault://login-callback' + search + hash;
        var intentPath = 'login-callback' + search + hash;
        var intentUrl = 'intent://' + intentPath + '#Intent;scheme=goldvault;package=app.goldvault.goldvault;end';

        document.body.innerHTML =
          '<div style="display:flex;align-items:center;justify-content:center;min-height:100vh;padding:24px;">' +
            '<div class="card" style="max-width:360px;width:100%;text-align:center;">' +
              '<div class="logo" style="margin-bottom:12px;">Gold<span>Vault</span></div>' +
              '<p>' +
                (hasAuthPayload
                  ? 'Autenticación completada. Redirigiendo de vuelta a la aplicación GoldVault en tu teléfono...'
                  : 'Conectando con la aplicación GoldVault...') +
              '</p>' +
              '<a class="btn" href="' + deepLink + '">Abrir en la app GoldVault</a>' +
              '<a class="btn-sec" href="' + intentUrl + '">Reintentar apertura directa</a>' +
            '</div>' +
          '</div>';

        try { window.location.replace(deepLink); } catch (_) {}
        setTimeout(function() {
          try { window.location.href = intentUrl; } catch (_) {}
        }, 650);
      }
    })();
  </script>

  <div class="wrap">
    <header class="header">
      <a href="/" class="logo">Gold<span>Vault</span></a>
      <span style="font-size:13px;color:var(--mut);">Flutter Android APK + Web Bridge</span>
    </header>

    <div class="grid">
      <div class="card">
        <h1>Puente OAuth Google → APK</h1>
        <p>
          Cuando inicias sesión con Google desde la APK de Android, GoldVault envía
          <code>redirectTo: https://goldvault-app.vercel.app/?apk_redirect=1</code>.
          Al recibir la respuesta de Google/Supabase, el puente web redirige al instante a
          <code>goldvault://login-callback</code> sin consumir el código PKCE en el navegador.
        </p>
        <a class="btn" href="/?apk_redirect=1&code=demo_auth_code_apk">Probar pantalla puente APK (?apk_redirect=1)</a>
        <a class="btn-sec" href="goldvault://login-callback">Probar Deep Link directo (goldvault://)</a>
      </div>

      <div class="card">
        <h2>Flujo configurado en el proyecto Flutter</h2>
        <ol class="step-list">
          <li><strong>lib/state/app_state.dart</strong>: <code>googleLogin()</code> usa <code>$prodWebUrl/?apk_redirect=1</code> con <code>LaunchMode.externalApplication</code> y procesa el retorno mediante <code>handleAuthDeepLink()</code> y <code>sb.auth.getSessionFromUrl(uri)</code>.</li>
          <li><strong>web/index.html</strong>: Intercepta <code>?apk_redirect=1</code> antes de cargar <code>flutter_bootstrap.js</code>, dispara <code>goldvault://login-callback</code> y muestra el botón manual de respaldo.</li>
          <li><strong>MainActivity.kt & AndroidManifest.xml</strong>: Captura los Intents en <code>onCreate</code> y <code>onNewIntent</code> para los esquemas <code>goldvault://</code> e <code>io.supabase.goldvault://</code>.</li>
        </ol>
      </div>
    </div>
  </div>
</body>
</html>`;

async function handleBankWebhook(req, res, urlObj) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-Vault-Token');

  if (req.method === 'OPTIONS') {
    res.writeHead(200);
    res.end();
    return;
  }

  let rawBody = '';
  for await (const chunk of req) {
    rawBody += chunk;
  }

  let body = {};
  if (rawBody) {
    try {
      body = JSON.parse(rawBody);
    } catch {
      body = { text: rawBody };
    }
  }

  const q = Object.fromEntries(urlObj.searchParams.entries());
  const authHeader = req.headers['authorization'] || '';
  const token =
    q.token ||
    body.token ||
    req.headers['x-vault-token'] ||
    authHeader.replace(/^Bearer\s+/i, '');

  const text =
    q.text || q.body || q.message || q.not_text ||
    body.text || body.body || body.message || body.notification || body.bigText || '';
  const title = q.title || q.not_title || body.title || body.not_title || '';
  const app = q.app || q.pkg || q.package || body.app || body.pkg || body.package || body.appName || '';

  if (!token) {
    res.writeHead(400, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ ok: false, error: 'Falta el parámetro token (ej: /api/bank?token=vaq_...)' }));
    return;
  }

  if (!text && !title) {
    res.writeHead(400, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ ok: false, error: 'Falta el texto de la notificación (parámetro text o body)' }));
    return;
  }

  let fxRate = Number(q.fx || body.fx) || 4200;
  if (/us\$|usd|usdc|usdt/i.test(`${title} ${text}`)) {
    try {
      const fxRes = await fetch('https://open.er-api.com/v6/latest/USD');
      if (fxRes.ok) {
        const fxJson = await fxRes.json();
        if (fxJson?.rates?.COP) {
          fxRate = Number(fxJson.rates.COP);
        }
      }
    } catch {}
  }

  try {
    const rpcRes = await fetch(`${SB_URL}/rest/v1/rpc/ingest_bank_notification`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        apikey: SB_KEY,
        Authorization: `Bearer ${SB_KEY}`,
      },
      body: JSON.stringify({
        p_token: String(token).trim(),
        p_text: String(text).trim(),
        p_title: String(title).trim(),
        p_app: String(app).trim(),
        p_fx: fxRate,
      }),
    });
    const data = await rpcRes.json();
    res.writeHead(rpcRes.ok ? 200 : 400, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify(data));
  } catch (err) {
    res.writeHead(500, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ ok: false, error: err?.message || 'Error interno' }));
  }
}

const server = http.createServer(async (req, res) => {
  const urlObj = new URL(req.url || '/', `http://${req.headers.host || 'localhost'}`);
  const pathname = urlObj.pathname;

  if (pathname === '/api/bank') {
    await handleBankWebhook(req, res, urlObj);
    return;
  }

  // Check static files in build/web or web/ or root
  const candidates = [
    path.join(__dirname, 'build', 'web', pathname),
    path.join(__dirname, 'web', pathname),
    path.join(__dirname, pathname),
  ];

  for (const filePath of candidates) {
    if (fs.existsSync(filePath) && fs.statSync(filePath).isFile()) {
      const ext = path.extname(filePath).toLowerCase();
      // If requesting /web/index.html without compiled flutter_bootstrap.js, serve PREVIEW_HTML instead
      if (ext === '.html' && !fs.existsSync(path.join(__dirname, 'build', 'web', 'flutter_bootstrap.js'))) {
        break;
      }
      res.writeHead(200, { 'Content-Type': MIME_TYPES[ext] || 'application/octet-stream' });
      fs.createReadStream(filePath).pipe(res);
      return;
    }
  }

  res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
  res.end(PREVIEW_HTML);
});

if (process.argv.includes('--build-bridge')) {
  const outDir = path.join(__dirname, 'build', 'web');
  const webDir = path.join(__dirname, 'web');
  if (!fs.existsSync(outDir)) {
    fs.mkdirSync(outDir, { recursive: true });
  }
  if (fs.existsSync(webDir)) {
    for (const entry of fs.readdirSync(webDir)) {
      const srcPath = path.join(webDir, entry);
      const destPath = path.join(outDir, entry);
      if (entry === 'index.html' || !fs.existsSync(destPath)) {
        fs.cpSync(srcPath, destPath, { recursive: true });
      }
    }
  }
  console.log('GoldVault build/web bridge ready');
  process.exit(0);
}

server.listen(PORT, '0.0.0.0', () => {
  console.log(`GoldVault server running at http://0.0.0.0:${PORT}`);
});
