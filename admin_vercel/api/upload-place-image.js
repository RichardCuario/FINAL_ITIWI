export default async function handler(req, res) {
  if (req.method !== 'POST') {
    res.setHeader('Allow', 'POST');
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
  const fileName = String(body?.fileName || '').trim();
  const mimeType = String(body?.mimeType || '').trim().toLowerCase();
  const base64Data = String(body?.base64Data || '').trim();

  if (!fileName || !mimeType || !base64Data) {
    return res.status(400).json({
      error: 'fileName, mimeType, and base64Data are required.'
    });
  }

  if (!['image/jpeg', 'image/png', 'image/webp', 'image/gif'].includes(mimeType)) {
    return res.status(400).json({
      error: 'Unsupported image type.',
      details: 'Allowed types: image/jpeg, image/png, image/webp, image/gif'
    });
  }

  try {
    await ensureBucketExists({ supabaseUrl, serviceRoleKey, bucketName });

    const objectPath = buildObjectPath(fileName);
    const binaryBuffer = Buffer.from(base64Data, 'base64');

    const uploadResponse = await fetch(`${supabaseUrl}/storage/v1/object/${bucketName}/${objectPath}`, {
      method: 'POST',
      headers: {
        apikey: serviceRoleKey,
        Authorization: `Bearer ${serviceRoleKey}`,
        'Content-Type': mimeType,
        'x-upsert': 'true'
      },
      body: binaryBuffer
    });

    const uploadText = await uploadResponse.text();
    const uploadJson = safeJsonParse(uploadText);

    if (!uploadResponse.ok) {
      return res.status(uploadResponse.status).json({
        error: 'Failed to upload image.',
        details: uploadJson ?? uploadText
      });
    }

    const publicUrl = `${supabaseUrl}/storage/v1/object/public/${bucketName}/${encodeURI(objectPath)}`;

    return res.status(200).json({
      success: true,
      bucket: bucketName,
      path: objectPath,
      publicUrl
    });
  } catch (error) {
    return res.status(500).json({
      error: 'Unexpected error while uploading image.',
      details: error instanceof Error ? error.message : String(error)
    });
  }
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

function buildObjectPath(fileName) {
  const sanitizedName = fileName
    .toLowerCase()
    .replace(/[^a-z0-9._-]+/g, '-')
    .replace(/-+/g, '-')
    .replace(/^-|-$/g, '');

  return `places/${Date.now()}-${sanitizedName || 'image'}`;
}

function safeJsonParse(value) {
  try {
    return JSON.parse(value);
  } catch (_) {
    return null;
  }
}
