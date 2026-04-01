export default async function handler(req, res) {
  if (req.method !== 'POST') {
    res.setHeader('Allow', 'POST');
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

  const body = typeof req.body === 'string' ? safeJsonParse(req.body) : req.body;
  const reportId = String(body?.reportId ?? '').trim();
  const status = normalizeStatus(body?.status);
  const rejectionReason = status === 'rejected' ? sanitizeRejectionReason(body?.rejectionReason) : null;
  const allowedRejectionReasons = getAllowedRejectionReasons();

  if (!reportId) {
    return res.status(400).json({ error: 'reportId is required.' });
  }

  if (!status) {
    return res.status(400).json({
      error: 'Invalid status value.',
      details: 'Allowed values: pending, reviewing, resolved, rejected.'
    });
  }

  if (status === 'rejected' && !rejectionReason) {
    return res.status(400).json({
      error: 'rejectionReason is required when rejecting a report.'
    });
  }

  if (status === 'rejected' && !allowedRejectionReasons.includes(rejectionReason)) {
    return res.status(400).json({
      error: 'Invalid rejectionReason value.',
      details: allowedRejectionReasons
    });
  }

  try {
    const updatedAt = new Date().toISOString();
    let response = await fetch(`${supabaseUrl}/rest/v1/reports?id=eq.${encodeURIComponent(reportId)}`, {
      method: 'PATCH',
      headers: {
        apikey: serviceRoleKey,
        Authorization: `Bearer ${serviceRoleKey}`,
        'Content-Type': 'application/json',
        Prefer: 'return=representation'
      },
      body: JSON.stringify({
        status,
        rejection_reason: rejectionReason,
        updated_at: updatedAt
      })
    });

    let responseText = await response.text();
    let responseJson = safeJsonParse(responseText);

    const missingRejectionReasonColumn = !response.ok &&
      JSON.stringify(responseJson ?? responseText).includes('rejection_reason');

    if (missingRejectionReasonColumn) {
      response = await fetch(`${supabaseUrl}/rest/v1/reports?id=eq.${encodeURIComponent(reportId)}`, {
        method: 'PATCH',
        headers: {
          apikey: serviceRoleKey,
          Authorization: `Bearer ${serviceRoleKey}`,
          'Content-Type': 'application/json',
          Prefer: 'return=representation'
        },
        body: JSON.stringify({
          status,
          updated_at: updatedAt
        })
      });

      responseText = await response.text();
      responseJson = safeJsonParse(responseText);
    }

    if (!response.ok) {
      return res.status(response.status).json({
        error: 'Failed to update report status.',
        details: responseJson ?? responseText
      });
    }

    const updatedReport = Array.isArray(responseJson) ? responseJson[0] ?? null : responseJson;

    return res.status(200).json({
      success: true,
      report: updatedReport
        ? {
            ...updatedReport,
            rejection_reason: missingRejectionReasonColumn
              ? null
              : updatedReport.rejection_reason ?? rejectionReason
          }
        : updatedReport,
      warning: missingRejectionReasonColumn
        ? 'Report status updated, but rejection_reason could not be stored because the database column does not exist yet.'
        : null
    });
  } catch (error) {
    return res.status(500).json({
      error: 'Unexpected error while updating report status.',
      details: error instanceof Error ? error.message : String(error)
    });
  }
}

function normalizeStatus(value) {
  const status = String(value ?? '').trim().toLowerCase();

  if (['pending', 'reviewing', 'resolved', 'rejected'].includes(status)) {
    return status;
  }

  if (status === 'under review') return 'reviewing';
  if (status === 'processing' || status === 'in progress') return 'reviewing';

  return '';
}

function sanitizeRejectionReason(value) {
  if (typeof value !== 'string') {
    return null;
  }

  const sanitized = value.trim();
  return sanitized ? sanitized : null;
}

function getAllowedRejectionReasons() {
  return [
    'Duplicate report',
    'Insufficient information',
    'Outside barangay jurisdiction',
    'Invalid or unclear attachment',
    'Prank or non-emergency request',
    'Request already handled',
    'Other administrative reason'
  ];
}

function safeJsonParse(value) {
  try {
    return JSON.parse(value);
  } catch (_) {
    return null;
  }
}
