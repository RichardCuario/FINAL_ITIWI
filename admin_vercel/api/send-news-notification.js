import { applyRateLimit } from './_rate_limit.js';

const FCM_SCOPE = 'https://www.googleapis.com/auth/firebase.messaging';
const GOOGLE_TOKEN_URL = 'https://oauth2.googleapis.com/token';

export default async function handler(req, res) {
  const rateLimitResult = await applyRateLimit(req, res, {
    key: 'send-news-notification',
    windowMs: 60 * 1000,
    max: 5,
    message: 'Too many news notification requests. Please wait a minute before trying again.',
  });
  if (!rateLimitResult?.allowed) {
    return rateLimitResult;
  }

  if (req.method !== 'POST') {
    res.setHeader('Allow', 'POST');
    return res.status(405).json({ error: 'Method not allowed' });
  }

  const projectId = String(process.env.FIREBASE_PROJECT_ID || '').trim();
  const clientEmail = String(process.env.FIREBASE_CLIENT_EMAIL || '').trim();
  const privateKey = normalizePrivateKey(process.env.FIREBASE_PRIVATE_KEY);

  if (!projectId || !clientEmail || !privateKey) {
    return res.status(500).json({
      error: 'Missing Firebase Admin environment variables.',
      details:
        'Set FIREBASE_PROJECT_ID, FIREBASE_CLIENT_EMAIL, and FIREBASE_PRIVATE_KEY in Vercel project settings.',
    });
  }

  const body = typeof req.body === 'string' ? safeJsonParse(req.body) : req.body;
  const title = String(body?.title ?? '').trim();
  const description = String(body?.description ?? '').trim();
  const newsId = body?.newsId ?? null;
  const imageUrl = String(body?.imageUrl ?? '').trim();

  if (!title) {
    return res.status(400).json({ error: 'Title is required.' });
  }

  const accessToken = await getAccessToken({ clientEmail, privateKey });

  const payload = {
    message: {
      topic: 'news_updates',
      notification: {
        title: 'New Announcement',
        body: description || title,
      },
      data: {
        type: 'news',
        newsId: newsId == null ? '' : String(newsId),
        title,
        description,
        imageUrl,
      },
      android: {
        priority: 'high',
        notification: {
          channel_id: 'news_updates',
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
          image: imageUrl || undefined,
        },
        ttl: '259200s',
      },
      apns: {
        headers: {
          'apns-priority': '10',
        },
        payload: {
          aps: {
            sound: 'default',
          },
        },
        fcm_options: imageUrl ? { image: imageUrl } : undefined,
      },
      webpush: imageUrl
        ? {
            headers: {
              Urgency: 'high',
            },
            notification: {
              image: imageUrl,
            },
          }
        : {
            headers: {
              Urgency: 'high',
            },
          },
    },
  };

  try {
    const response = await fetch(
      `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
      {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${accessToken}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(payload),
      },
    );

    const responseText = await response.text();
    const responseJson = safeJsonParse(responseText);

    if (!response.ok) {
      return res.status(response.status).json({
        error: 'Failed to send FCM notification.',
        details: extractErrorMessage(responseJson) || responseJson || responseText,
      });
    }

    return res.status(200).json({
      success: true,
      result: responseJson,
    });
  } catch (error) {
    return res.status(500).json({
      error: 'Unexpected error while sending notification.',
      details: error instanceof Error ? error.message : String(error),
    });
  }
}

async function getAccessToken({ clientEmail, privateKey }) {
  const now = Math.floor(Date.now() / 1000);

  const jwtHeader = base64UrlEncode(
    JSON.stringify({ alg: 'RS256', typ: 'JWT' }),
  );
  const jwtPayload = base64UrlEncode(
    JSON.stringify({
      iss: clientEmail,
      scope: FCM_SCOPE,
      aud: GOOGLE_TOKEN_URL,
      exp: now + 3600,
      iat: now,
    }),
  );

  const unsignedToken = `${jwtHeader}.${jwtPayload}`;
  const signature = await signJwt(unsignedToken, privateKey);

  const assertion = `${unsignedToken}.${signature}`;

  const tokenResponse = await fetch(GOOGLE_TOKEN_URL, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion,
    }),
  });

  const tokenText = await tokenResponse.text();
  const tokenJson = safeJsonParse(tokenText);

  if (!tokenResponse.ok || !tokenJson?.access_token) {
    throw new Error(
      `Failed to obtain Firebase access token: ${extractErrorMessage(tokenJson) || tokenText || tokenResponse.status}`,
    );
  }

  return tokenJson.access_token;
}

async function signJwt(unsignedToken, privateKey) {
  const encoder = new TextEncoder();
  const keyData = pemToArrayBuffer(privateKey);
  const cryptoKey = await crypto.subtle.importKey(
    'pkcs8',
    keyData,
    {
      name: 'RSASSA-PKCS1-v1_5',
      hash: 'SHA-256',
    },
    false,
    ['sign'],
  );

  const signature = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    cryptoKey,
    encoder.encode(unsignedToken),
  );

  return base64UrlEncode(signature);
}

function pemToArrayBuffer(pem) {
  const base64 = pem
    .replace('-----BEGIN PRIVATE KEY-----', '')
    .replace('-----END PRIVATE KEY-----', '')
    .replace(/\s+/g, '');

  const binary = typeof atob === 'function'
    ? atob(base64)
    : Buffer.from(base64, 'base64').toString('binary');
  const bytes = new Uint8Array(binary.length);

  for (let i = 0; i < binary.length; i += 1) {
    bytes[i] = binary.charCodeAt(i);
  }

  return bytes.buffer;
}

function base64UrlEncode(value) {
  const bytes =
    typeof value === 'string' ? new TextEncoder().encode(value) : new Uint8Array(value);

  let binary = '';
  for (let i = 0; i < bytes.length; i += 1) {
    binary += String.fromCharCode(bytes[i]);
  }

  const encoded = typeof btoa === 'function'
    ? btoa(binary)
    : Buffer.from(binary, 'binary').toString('base64');

  return encoded.replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/g, '');
}

function normalizePrivateKey(value) {
  return value ? value.replace(/\\n/g, '\n') : '';
}

function extractErrorMessage(value) {
  const details = value?.details;

  if (typeof details === 'string') {
    return details;
  }

  if (Array.isArray(details)) {
    return details
      .map((item) => item?.message || item?.error || JSON.stringify(item))
      .filter(Boolean)
      .join('; ');
  }

  return (
    value?.error?.message ||
    value?.error?.status ||
    value?.error_description ||
    (typeof value?.message === 'string' ? value.message : '') ||
    ''
  );
}

function safeJsonParse(value) {
  try {
    return JSON.parse(value);
  } catch (_) {
    return null;
  }
}
