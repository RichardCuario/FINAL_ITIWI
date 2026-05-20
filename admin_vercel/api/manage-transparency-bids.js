export default async function handler(req, res) {
  const method = String(req.method || '').toUpperCase();

  if (!['GET', 'POST', 'PATCH', 'DELETE'].includes(method)) {
    res.setHeader('Allow', 'GET, POST, PATCH, DELETE');
    return res.status(405).json({ error: 'Method not allowed' });
  }

  const supabaseUrl = String(
    process.env.SUPABASE_URL || 'https://jbhlbukxankrtcwhqoll.supabase.co',
  ).trim();
  const serviceRoleKey = String(
    process.env.SUPABASE_SERVICE_ROLE_KEY || '',
  ).trim();
  const tableName = 'transparency_bids_projects';

  if (!supabaseUrl || !serviceRoleKey) {
    return res.status(500).json({
      error: 'Missing Supabase admin environment variables.',
      details:
        'Set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY in Vercel project settings.',
    });
  }

  const body = typeof req.body === 'string' ? safeJsonParse(req.body) : req.body;
  const transparencyId = String(
    body?.id ?? body?.transparencyId ?? body?.recordId ?? '',
  ).trim();
  const payload = sanitizeTransparencyPayload(body?.payload ?? body);

  if (method === 'GET') {
    try {
      const response = await fetch(
        `${supabaseUrl}/rest/v1/${tableName}?select=id,title,description,pdf_url,is_published,display_order,created_at,updated_at&order=display_order.asc.nullslast,created_at.desc`,
        {
          method: 'GET',
          headers: {
            apikey: serviceRoleKey,
            Authorization: `Bearer ${serviceRoleKey}`,
          },
        },
      );

      const responseText = await response.text();
      const responseJson = safeJsonParse(responseText);

      if (!response.ok) {
        return res.status(response.status).json({
          error: 'Failed to load transparency records.',
          details: responseJson ?? responseText,
        });
      }

      return res.status(200).json({
        success: true,
        records: Array.isArray(responseJson) ? responseJson : [],
      });
    } catch (error) {
      return res.status(500).json({
        error: 'Unexpected error while loading transparency records.',
        details: error instanceof Error ? error.message : String(error),
      });
    }
  }

  if (method === 'POST' && !payload) {
    return res.status(400).json({ error: 'Transparency payload is required.' });
  }

  if ((method === 'PATCH' || method === 'DELETE') && !transparencyId) {
    return res.status(400).json({ error: 'transparencyId is required.' });
  }

  if ((method === 'POST' || method === 'PATCH') && !payload?.title) {
    return res.status(400).json({ error: 'Title is required.' });
  }

  try {
    if (method === 'POST') {
      const response = await fetch(`${supabaseUrl}/rest/v1/${tableName}`, {
        method: 'POST',
        headers: {
          apikey: serviceRoleKey,
          Authorization: `Bearer ${serviceRoleKey}`,
          'Content-Type': 'application/json',
          Prefer: 'return=representation',
        },
        body: JSON.stringify(payload),
      });

      return await handleSupabaseResponse(
        response,
        res,
        'Failed to create transparency record.',
      );
    }

    if (method === 'PATCH') {
      const response = await fetch(
        `${supabaseUrl}/rest/v1/${tableName}?id=eq.${encodeURIComponent(transparencyId)}`,
        {
          method: 'PATCH',
          headers: {
            apikey: serviceRoleKey,
            Authorization: `Bearer ${serviceRoleKey}`,
            'Content-Type': 'application/json',
            Prefer: 'return=representation',
          },
          body: JSON.stringify({
            ...payload,
            updated_at: new Date().toISOString(),
          }),
        },
      );

      return await handleSupabaseResponse(
        response,
        res,
        'Failed to update transparency record.',
      );
    }

    const response = await fetch(
      `${supabaseUrl}/rest/v1/${tableName}?id=eq.${encodeURIComponent(transparencyId)}`,
      {
        method: 'DELETE',
        headers: {
          apikey: serviceRoleKey,
          Authorization: `Bearer ${serviceRoleKey}`,
          Prefer: 'return=representation',
        },
      },
    );

    return await handleSupabaseResponse(
      response,
      res,
      'Failed to delete transparency record.',
    );
  } catch (error) {
    return res.status(500).json({
      error: 'Unexpected error while managing transparency record.',
      details: error instanceof Error ? error.message : String(error),
    });
  }
}

async function handleSupabaseResponse(response, res, fallbackMessage) {
  const responseText = await response.text();
  const responseJson = safeJsonParse(responseText);

  if (!response.ok) {
    return res.status(response.status).json({
      error: fallbackMessage,
      details: responseJson ?? responseText,
    });
  }

  const record = Array.isArray(responseJson) ? responseJson[0] ?? null : responseJson;

  return res.status(200).json({
    success: true,
    transparency: record,
  });
}

function sanitizeTransparencyPayload(value) {
  if (!value || typeof value !== 'object') {
    return null;
  }

  return {
    title: normalizeRequiredText(value.title),
    description: normalizeOptionalText(value.description),
    pdf_url: normalizeOptionalText(value.pdf_url),
    is_published: value.is_published !== false,
    display_order: normalizeOptionalNumberWithDefault(value.display_order, 0),
  };
}

function normalizeRequiredText(value) {
  return String(value ?? '').trim();
}

function normalizeOptionalText(value) {
  const normalized = String(value ?? '').trim();
  return normalized || null;
}

function normalizeOptionalNumberWithDefault(value, defaultValue) {
  if (value === null || value === undefined || value === '') {
    return defaultValue;
  }

  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : defaultValue;
}

function safeJsonParse(value) {
  try {
    return JSON.parse(value);
  } catch (_) {
    return null;
  }
}
