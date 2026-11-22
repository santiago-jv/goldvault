const SB_URL = 'https://spjvxvmhosptezmteypm.supabase.co';
const SB_KEY = 'sb_publishable_uXP3oxhMoUXdsMDdIv71Cg_L1SA4C6B';

export default async function handler(req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-Vault-Token');

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  try {
    const q = req.query || {};
    let body = req.body || {};
    if (typeof body === 'string') {
      try {
        body = JSON.parse(body);
      } catch (_) {
        body = { text: body };
      }
    }

    const token =
      q.token ||
      body.token ||
      req.headers['x-vault-token'] ||
      (req.headers.authorization ? req.headers.authorization.replace(/^Bearer\s+/i, '') : '');

    const text =
      q.text ||
      q.body ||
      q.message ||
      q.not_text ||
      body.text ||
      body.body ||
      body.message ||
      body.notification ||
      body.bigText ||
      '';

    const title =
      q.title ||
      q.not_title ||
      body.title ||
      body.not_title ||
      '';

    const app =
      q.app ||
      q.pkg ||
      q.package ||
      body.app ||
      body.pkg ||
      body.package ||
      body.appName ||
      '';

    if (!token) {
      return res.status(400).json({
        ok: false,
        error: 'Missing required token parameter (example: /api/bank?token=vaq_...)'
      });
    }

    if (!text && !title) {
      return res.status(400).json({
        ok: false,
        error: 'Missing notification content (provide text or body parameter)'
      });
    }

    // Fetch live USD->COP exchange rate when the notification mentions USD/US$
    let fxRate = Number(q.fx || body.fx) || 4200;
    if (/us\$|usd|usdc|usdt/i.test(`${title} ${text}`)) {
      try {
        const fxRes = await fetch('https://open.er-api.com/v6/latest/USD');
        if (fxRes.ok) {
          const fxJson = await fxRes.json();
          if (fxJson && fxJson.rates && fxJson.rates.COP) {
            fxRate = Number(fxJson.rates.COP);
          }
        }
      } catch (_) {}
    }

    const rpcRes = await fetch(`${SB_URL}/rest/v1/rpc/ingest_bank_notification`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'apikey': SB_KEY,
        'Authorization': `Bearer ${SB_KEY}`
      },
      body: JSON.stringify({
        p_token: String(token).trim(),
        p_text: String(text).trim(),
        p_title: String(title).trim(),
        p_app: String(app).trim(),
        p_fx: fxRate
      })
    });

    const data = await rpcRes.json();
    return res.status(rpcRes.ok ? 200 : 400).json(data);
  } catch (err) {
    return res.status(500).json({
      ok: false,
      error: err && err.message ? err.message : 'Internal server error while processing bank notification'
    });
  }
};
