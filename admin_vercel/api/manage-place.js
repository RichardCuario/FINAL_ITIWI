export default async function handler(req, res) {
  const method = String(req.method || '').toUpperCase();

  if (!['POST', 'PATCH', 'DELETE'].includes(method)) {
    res.setHeader('Allow', 'POST, PATCH, DELETE');
    return res.status(405).json({ error: 'Method not allowed' });
  }

  const supabaseUrl = String(process.env.SUPABASE_URL || 'https://jbhlbukxankrtcwhqoll.supabase.co').trim();
  const serviceRoleKey = String(process.env.SUPABASE_SERVICE_ROLE_KEY || '').trim();
  const bucketName = 'places-images';

  if (!supabaseUrl || !serviceRoleKey) {
    return res.status(500).json({
      error: 'Missing Supabase admin environment variables.',
      details: 'Set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY in Vercel project settings.'
    });
  }

  const body = typeof req.body === 'string' ? safeJsonParse(req.body) : req.body;
  const placeId = String(body?.id ?? body?.placeId ?? '').trim();
  const payload = sanitizePlacePayload(body?.payload ?? body);

  if (method === 'POST' && !payload) {
    return res.status(400).json({ error: 'Place payload is required.' });
  }

  if ((method === 'PATCH' || method === 'DELETE') && !placeId) {
    return res.status(400).json({ error: 'placeId is required.' });
  }

  if ((method === 'POST' || method === 'PATCH') && !payload?.name) {
    return res.status(400).json({ error: 'Place name is required.' });
  }

  if ((method === 'POST' || method === 'PATCH') && !payload?.category) {
    return res.status(400).json({ error: 'Place category is required.' });
  }

  try {
    await ensureBucketExists({ supabaseUrl, serviceRoleKey, bucketName });

    if (method === 'POST') {
      const response = await fetch(`${supabaseUrl}/rest/v1/places`, {
        method: 'POST',
        headers: {
          apikey: serviceRoleKey,
          Authorization: `Bearer ${serviceRoleKey}`,
          'Content-Type': 'application/json',
          Prefer: 'return=representation'
        },
        body: JSON.stringify(payload)
      });

      return await handleSupabaseResponse(response, res, 'Failed to create place.');
    }

    if (method === 'PATCH') {
      const response = await fetch(`${supabaseUrl}/rest/v1/places?id=eq.${encodeURIComponent(placeId)}`, {
        method: 'PATCH',
        headers: {
          apikey: serviceRoleKey,
          Authorization: `Bearer ${serviceRoleKey}`,
          'Content-Type': 'application/json',
          Prefer: 'return=representation'
        },
        body: JSON.stringify({
          ...payload,
          updated_at: new Date().toISOString()
        })
      });

      return await handleSupabaseResponse(response, res, 'Failed to update place.');
    }

    const existingPlace = await fetchPlaceById({ supabaseUrl, serviceRoleKey, placeId });

    if (existingPlace?.image_url) {
      await deletePlaceImageIfManaged({
        supabaseUrl,
        serviceRoleKey,
        bucketName,
        imageUrl: existingPlace.image_url
      });
    }

    const response = await fetch(`${supabaseUrl}/rest/v1/places?id=eq.${encodeURIComponent(placeId)}`, {
      method: 'DELETE',
      headers: {
        apikey: serviceRoleKey,
        Authorization: `Bearer ${serviceRoleKey}`,
        Prefer: 'return=representation'
      }
    });

    return await handleSupabaseResponse(response, res, 'Failed to delete place.');
  } catch (error) {
    return res.status(500).json({
      error: 'Unexpected error while managing place.',
      details: error instanceof Error ? error.message : String(error)
    });
  }
}

async function handleSupabaseResponse(response, res, fallbackMessage) {
  const responseText = await response.text();
  const responseJson = safeJsonParse(responseText);

  if (!response.ok) {
    return res.status(response.status).json({
      error: fallbackMessage,
      details: responseJson ?? responseText
    });
  }

  const record = Array.isArray(responseJson) ? responseJson[0] ?? null : responseJson;

  return res.status(200).json({
    success: true,
    place: record
  });
}

function sanitizePlacePayload(value) {
  if (!value || typeof value !== 'object') {
    return null;
  }

  return {
    name: normalizeRequiredText(value.name),
    category: normalizeRequiredText(value.category),
    location: normalizeOptionalText(value.location),
    short_location: normalizeOptionalText(value.short_location),
    full_address: normalizeOptionalText(value.full_address),
    description: normalizeOptionalText(value.description),
    image_url: normalizeOptionalText(value.image_url),
    phone: normalizeOptionalText(value.phone),
    website_url: normalizeOptionalText(value.website_url),
    latitude: normalizeOptionalNumber(value.latitude),
    longitude: normalizeOptionalNumber(value.longitude),
    distance_label: normalizeOptionalText(value.distance_label),
    is_featured: Boolean(value.is_featured),
    is_published: value.is_published !== false
  };
}

function normalizeRequiredText(value) {
  const normalized = String(value ?? '').trim();
  return normalized;
}

function normalizeOptionalText(value) {
  const normalized = String(value ?? '').trim();
  return normalized || null;
}

function normalizeOptionalNumber(value) {
  if (value === null || value === undefined || value === '') {
    return null;
  }

  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : null;
}

async function ensureBucketExists({ supabaseUrl, serviceRoleKey, bucketName }) {
  const response = await fetch(`${supabaseUrl}/storage/v1/bucket/${encodeURIComponent(bucketName)}`, {
    method: 'GET',
    headers: {
      apikey: serviceRoleKey,
      Authorization: `Bearer ${serviceRoleKey}`
    }
  });

  if (response.ok) {
    return;
  }

  if (response.status !== 404) {
    const responseText = await response.text();
    throw new Error(`Unable to verify storage bucket: ${responseText}`);
  }

  const createResponse = await fetch(`${supabaseUrl}/storage/v1/bucket`, {
    method: 'POST',
    headers: {
      apikey: serviceRoleKey,
      Authorization: `Bearer ${serviceRoleKey}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      id: bucketName,
      name: bucketName,
      public: true,
      file_size_limit: '10485760',
      allowed_mime_types: ['image/jpeg', 'image/png', 'image/webp', 'image/gif']
    })
  });

  if (!createResponse.ok) {
    const responseText = await createResponse.text();
    throw new Error(`Unable to create storage bucket: ${responseText}`);
  }
}

async function fetchPlaceById({ supabaseUrl, serviceRoleKey, placeId }) {
  const response = await fetch(`${supabaseUrl}/rest/v1/places?id=eq.${encodeURIComponent(placeId)}&select=id,image_url`, {
    method: 'GET',
    headers: {
      apikey: serviceRoleKey,
      Authorization: `Bearer ${serviceRoleKey}`
    }
  });

  if (!response.ok) {
    const responseText = await response.text();
    throw new Error(`Unable to load existing place: ${responseText}`);
  }

  const responseJson = safeJsonParse(await response.text());
  return Array.isArray(responseJson) ? responseJson[0] ?? null : null;
}

async function deletePlaceImageIfManaged({ supabaseUrl, serviceRoleKey, bucketName, imageUrl }) {
  const pathPrefix = `/storage/v1/object/public/${bucketName}/`;
  const url = String(imageUrl || '');

  const prefixIndex = url.indexOf(pathPrefix);
  if (prefixIndex === -1) {
    return;
  }

  const objectPath = decodeURIComponent(url.slice(prefixIndex + pathPrefix.length));
  if (!objectPath) {
    return;
  }

  await fetch(`${supabaseUrl}/storage/v1/object/${bucketName}/${objectPath}`, {
    method: 'DELETE',
    headers: {
      apikey: serviceRoleKey,
      Authorization: `Bearer ${serviceRoleKey}`
    }
  });
}

function safeJsonParse(value) {
  try {
    return JSON.parse(value);
  } catch (_) {
    return null;
  }
}
