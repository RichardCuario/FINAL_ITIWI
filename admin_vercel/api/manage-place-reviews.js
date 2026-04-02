export default async function handler(req, res) {
  const method = String(req.method || '').toUpperCase();

  if (!['GET', 'PATCH'].includes(method)) {
    res.setHeader('Allow', 'GET, PATCH');
    return res.status(405).json({ error: 'Method not allowed' });
  }

  const supabaseUrl = String(process.env.SUPABASE_URL || 'https://jbhlbukxankrtcwhqoll.supabase.co').trim();
  const serviceRoleKey = String(process.env.SUPABASE_SERVICE_ROLE_KEY || '').trim();

  if (!supabaseUrl || !serviceRoleKey) {
    return res.status(500).json({
      error: 'Missing Supabase admin environment variables.',
      details: 'Set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY in Vercel project settings.'
    });
  }

  try {
    if (method === 'GET') {
      const status = normalizeStatus(req.query?.status);

      if (req.query?.status !== undefined && !status && String(req.query.status).trim().toLowerCase() !== 'all') {
        return res.status(400).json({
          error: 'Invalid status value.',
          details: 'Allowed values: all, pending, approved, rejected.'
        });
      }

      const reviews = await fetchPlaceReviews({ supabaseUrl, serviceRoleKey, status });

      return res.status(200).json({
        success: true,
        reviews
      });
    }

    const body = typeof req.body === 'string' ? safeJsonParse(req.body) : req.body;
    const reviewId = String(body?.reviewId ?? body?.id ?? '').trim();
    const status = normalizeStatus(body?.status);
    const adminNotes = sanitizeAdminNotes(body?.adminNotes ?? body?.admin_notes);

    if (!reviewId) {
      return res.status(400).json({ error: 'reviewId is required.' });
    }

    if (!status) {
      return res.status(400).json({
        error: 'Invalid status value.',
        details: 'Allowed values: pending, approved, rejected.'
      });
    }

    const response = await fetch(`${supabaseUrl}/rest/v1/place_reviews?id=eq.${encodeURIComponent(reviewId)}&select=id,user_id,place_id,reviewer_name,rating,review_text,status,admin_notes,created_at,updated_at,places(name)`, {
      method: 'PATCH',
      headers: {
        apikey: serviceRoleKey,
        Authorization: `Bearer ${serviceRoleKey}`,
        'Content-Type': 'application/json',
        Prefer: 'return=representation'
      },
      body: JSON.stringify({
        status,
        admin_notes: adminNotes,
        updated_at: new Date().toISOString()
      })
    });

    const responseText = await response.text();
    const responseJson = safeJsonParse(responseText);

    if (!response.ok) {
      return res.status(response.status).json({
        error: 'Failed to update place review.',
        details: responseJson ?? responseText
      });
    }

    const updatedReview = Array.isArray(responseJson) ? responseJson[0] ?? null : responseJson;

    return res.status(200).json({
      success: true,
      review: formatReview(updatedReview)
    });
  } catch (error) {
    return res.status(500).json({
      error: 'Unexpected error while managing place reviews.',
      details: error instanceof Error ? error.message : String(error)
    });
  }
}

async function fetchPlaceReviews({ supabaseUrl, serviceRoleKey, status }) {
  const queryParts = [
    'select=id,user_id,place_id,reviewer_name,rating,review_text,status,admin_notes,created_at,updated_at,places(name)',
    'order=created_at.desc'
  ];

  if (status) {
    queryParts.push(`status=eq.${encodeURIComponent(status)}`);
  }

  const response = await fetch(`${supabaseUrl}/rest/v1/place_reviews?${queryParts.join('&')}`, {
    method: 'GET',
    headers: {
      apikey: serviceRoleKey,
      Authorization: `Bearer ${serviceRoleKey}`
    }
  });

  const responseText = await response.text();
  const responseJson = safeJsonParse(responseText);

  if (!response.ok) {
    throw new Error(`Failed to fetch place reviews: ${responseText}`);
  }

  const reviews = Array.isArray(responseJson) ? responseJson : [];
  return reviews.map(formatReview);
}

function formatReview(review) {
  if (!review || typeof review !== 'object') {
    return null;
  }

  const placeRelation = Array.isArray(review.places) ? review.places[0] ?? null : review.places;

  return {
    id: review.id ?? null,
    user_id: review.user_id ?? null,
    place_id: review.place_id ?? null,
    place_name: placeRelation?.name ?? null,
    reviewer_name: review.reviewer_name ?? null,
    rating: review.rating ?? null,
    review_text: review.review_text ?? null,
    status: review.status ?? null,
    admin_notes: review.admin_notes ?? null,
    created_at: review.created_at ?? null,
    updated_at: review.updated_at ?? null
  };
}

function normalizeStatus(value) {
  const status = String(value ?? '').trim().toLowerCase();

  if (['pending', 'approved', 'rejected'].includes(status)) {
    return status;
  }

  return '';
}

function sanitizeAdminNotes(value) {
  if (value === undefined) {
    return null;
  }

  const sanitized = String(value ?? '').trim();
  return sanitized || null;
}

function safeJsonParse(value) {
  try {
    return JSON.parse(value);
  } catch (_) {
    return null;
  }
}
