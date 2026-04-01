export default async function handler(req, res) {
  if (req.method !== 'POST') {
    res.setHeader('Allow', 'POST');
    return res.status(405).json({ error: 'Method not allowed' });
  }

  const appId = process.env.ONESIGNAL_APP_ID;
  const apiKey = process.env.ONESIGNAL_REST_API_KEY;

  if (!appId || !apiKey) {
    return res.status(500).json({
      error: 'Missing OneSignal environment variables.',
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

  const payload = {
    app_id: appId,
    included_segments: ['Subscribed Users'],
    headings: {
      en: 'New Announcement',
    },
    contents: {
      en: title,
    },
    data: {
      type: 'news',
      newsId,
      title,
      description,
      imageUrl,
    },
  };

  if (description) {
    payload.contents.en = description.length > 120
      ? `${description.slice(0, 117)}...`
      : description;
  }

  if (imageUrl) {
    payload.big_picture = imageUrl;
    payload.chrome_web_image = imageUrl;
  }

  try {
    const response = await fetch('https://api.onesignal.com/notifications', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Key ${apiKey}`,
      },
      body: JSON.stringify(payload),
    });

    const responseText = await response.text();
    const responseJson = safeJsonParse(responseText);

    if (!response.ok) {
      return res.status(response.status).json({
        error: 'Failed to send OneSignal notification.',
        details: responseJson ?? responseText,
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

function safeJsonParse(value) {
  try {
    return JSON.parse(value);
  } catch (_) {
    return null;
  }
}
