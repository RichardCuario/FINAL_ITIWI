import { applyRateLimit } from './_rate_limit.js';

const FCM_SCOPE = 'https://www.googleapis.com/auth/firebase.messaging';
const IDENTITY_TOOLKIT_SCOPE = 'https://www.googleapis.com/auth/identitytoolkit';
const FIREBASE_ACCOUNTS_URL = 'https://identitytoolkit.googleapis.com/v1/projects';
const GOOGLE_TOKEN_URL = 'https://oauth2.googleapis.com/token';
const FIREBASE_LIST_USERS_MAX_RESULTS = 1000;

const ONLINE_SERVICE_TABLE_CONFIG = {
  birth_certificate_appointments: {
    userIdField: 'user_id',
    serviceLabel: 'Birth Certificate',
    nameFields: ['full_name'],
    scheduleFields: ['appointment_date', 'appointment_time'],
  },
  marriage_certificate_appointments: {
    userIdField: 'user_id',
    serviceLabel: 'Marriage Certificate',
    nameFields: ['husband_name', 'wife_name'],
    scheduleFields: ['appointment_date', 'appointment_time'],
  },
  death_certificate_appointments: {
    userIdField: 'user_id',
    serviceLabel: 'Death Certificate',
    nameFields: ['requestor_full_name', 'deceased_full_name'],
    scheduleFields: ['appointment_date', 'appointment_time'],
  },
  cenomar_appointments: {
    userIdField: 'user_id',
    serviceLabel: 'CENOMAR',
    nameFields: ['full_name'],
    scheduleFields: ['appointment_date', 'appointment_time'],
  },
  cenodeath_appointments: {
    userIdField: 'user_id',
    serviceLabel: 'CENODEATH',
    nameFields: ['full_name'],
    scheduleFields: ['appointment_date', 'appointment_time'],
  },
  facility_borrow_requests: {
    userIdField: 'user_id',
    serviceLabel: 'Facility Borrowing',
    nameFields: ['full_name', 'facility_name'],
    scheduleFields: ['event_date', 'start_time', 'end_time'],
  },
};

export default async function handler(req, res) {
  // CORS (important when dashboard is opened from file:// => origin "null")
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader(
    'Access-Control-Allow-Headers',
    'Content-Type, Authorization, apikey'
  );
  res.setHeader('Access-Control-Max-Age', '86400');

  if (String(req.method || '').toUpperCase() === 'OPTIONS') {
    return res.status(204).end();
  }

  const rateLimitResult = await applyRateLimit(req, res, {
    key: 'update-report-status',
    windowMs: 60 * 1000,
    max: 30,
    message: 'Too many status update requests. Please wait a minute before trying again.',
  });
  if (!rateLimitResult?.allowed) {
    return rateLimitResult;
  }

  const method = String(req.method || '').toUpperCase();
  const supabaseUrl = String(process.env.SUPABASE_URL || '').trim();
  const serviceRoleKey = String(process.env.SUPABASE_SERVICE_ROLE_KEY || '').trim();
  const firebaseProjectId = String(process.env.FIREBASE_PROJECT_ID || '').trim();
  const firebaseClientEmail = String(process.env.FIREBASE_CLIENT_EMAIL || '').trim();
  const firebasePrivateKey = normalizePrivateKey(process.env.FIREBASE_PRIVATE_KEY);

  if (!supabaseUrl || !serviceRoleKey) {
    return res.status(500).json({
      error: 'Missing Supabase admin environment variables.',
      details: 'Set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY in Vercel project settings.',
    });
  }

  if (method === 'GET') {
    res.setHeader('Cache-Control', 'no-store, no-cache, must-revalidate, proxy-revalidate');
    res.setHeader('Pragma', 'no-cache');
    res.setHeader('Expires', '0');

    const action = String(req.query?.action || '').trim().toLowerCase();

    if (action !== 'firebase-users') {
      res.setHeader('Allow', 'GET, POST');
      return res.status(405).json({ error: 'Method not allowed' });
    }

    if (!firebaseProjectId || !firebaseClientEmail || !firebasePrivateKey) {
      return res.status(500).json({
        error: 'Missing Firebase admin environment variables.',
        details: 'Set FIREBASE_PROJECT_ID, FIREBASE_CLIENT_EMAIL, and FIREBASE_PRIVATE_KEY in Vercel project settings.',
      });
    }

    try {
      const accessToken = await getAccessToken({
        clientEmail: firebaseClientEmail,
        privateKey: firebasePrivateKey,
        scope: `${FCM_SCOPE} ${IDENTITY_TOOLKIT_SCOPE}`,
      });

      const users = await listAllFirebaseUsers({
        projectId: firebaseProjectId,
        accessToken,
      });

      return res.status(200).json({
        success: true,
        count: users.length,
        users: users.map((user) => ({
          created_at: normalizeFirebaseCreatedAt(user),
        })),
      });
    } catch (error) {
      return res.status(500).json({
        error: 'Failed to load Firebase Authentication users.',
        details: error instanceof Error ? error.message : String(error),
      });
    }
  }

  if (method !== 'POST') {
    res.setHeader('Allow', 'GET, POST');
    return res.status(405).json({ error: 'Method not allowed' });
  }

  const body = typeof req.body === 'string' ? safeJsonParse(req.body) : req.body;
  const target = String(body?.target ?? 'report').trim().toLowerCase();

  if (target === 'online_service') {
    return handleOnlineServiceStatusUpdate({
      req,
      res,
      body,
      supabaseUrl,
      serviceRoleKey,
      firebaseProjectId,
      firebaseClientEmail,
      firebasePrivateKey,
    });
  }

  return handleReportStatusUpdate({
    req,
    res,
    body,
    supabaseUrl,
    serviceRoleKey,
    firebaseProjectId,
    firebaseClientEmail,
    firebasePrivateKey,
  });
}

async function handleReportStatusUpdate({
  res,
  body,
  supabaseUrl,
  serviceRoleKey,
  firebaseProjectId,
  firebaseClientEmail,
  firebasePrivateKey,
}) {
  const reportId = String(body?.reportId ?? '').trim();
  const status = normalizeReportStatus(body?.status);
  const rejectionReason =
    status === 'rejected' ? sanitizeRejectionReason(body?.rejectionReason) : null;
  const allowedRejectionReasons = getAllowedRejectionReasons();

  if (!reportId) {
    return res.status(400).json({ error: 'reportId is required.' });
  }

  if (!status) {
    return res.status(400).json({
      error: 'Invalid status value.',
      details: 'Allowed values: pending, reviewing, resolved, rejected.',
    });
  }

  if (status === 'rejected' && !rejectionReason) {
    return res.status(400).json({
      error: 'rejectionReason is required when rejecting a report.',
    });
  }

  if (status === 'rejected' && !allowedRejectionReasons.includes(rejectionReason)) {
    return res.status(400).json({
      error: 'Invalid rejectionReason value.',
      details: allowedRejectionReasons,
    });
  }

  try {
    const updatedAt = new Date().toISOString();
    let response = await fetch(
      `${supabaseUrl}/rest/v1/reports?id=eq.${encodeURIComponent(reportId)}`,
      {
        method: 'PATCH',
        headers: {
          apikey: serviceRoleKey,
          Authorization: `Bearer ${serviceRoleKey}`,
          'Content-Type': 'application/json',
          Prefer: 'return=representation',
        },
        body: JSON.stringify({
          status,
          rejection_reason: rejectionReason,
          updated_at: updatedAt,
        }),
      },
    );

    let responseText = await response.text();
    let responseJson = safeJsonParse(responseText);

    const missingRejectionReasonColumn =
      !response.ok &&
      JSON.stringify(responseJson ?? responseText).includes('rejection_reason');

    if (missingRejectionReasonColumn) {
      response = await fetch(
        `${supabaseUrl}/rest/v1/reports?id=eq.${encodeURIComponent(reportId)}`,
        {
          method: 'PATCH',
          headers: {
            apikey: serviceRoleKey,
            Authorization: `Bearer ${serviceRoleKey}`,
            'Content-Type': 'application/json',
            Prefer: 'return=representation',
          },
          body: JSON.stringify({
            status,
            updated_at: updatedAt,
          }),
        },
      );

      responseText = await response.text();
      responseJson = safeJsonParse(responseText);
    }

    if (!response.ok) {
      return res.status(response.status).json({
        error: 'Failed to update report status.',
        details: responseJson ?? responseText,
      });
    }

    const updatedReport = Array.isArray(responseJson) ? responseJson[0] ?? null : responseJson;
    let reportUserId = updatedReport?.user_id ? String(updatedReport.user_id).trim() : '';

    if (!reportUserId) {
      const reportLookupResponse = await fetch(
        `${supabaseUrl}/rest/v1/reports?id=eq.${encodeURIComponent(reportId)}&select=id,user_id,message,status,rejection_reason,updated_at`,
        {
          method: 'GET',
          headers: {
            apikey: serviceRoleKey,
            Authorization: `Bearer ${serviceRoleKey}`,
            'Content-Type': 'application/json',
          },
        },
      );

      const reportLookupText = await reportLookupResponse.text();
      const reportLookupJson = safeJsonParse(reportLookupText);

      if (reportLookupResponse.ok && Array.isArray(reportLookupJson) && reportLookupJson[0]) {
        reportUserId = reportLookupJson[0]?.user_id
          ? String(reportLookupJson[0].user_id).trim()
          : '';
      }
    }

    const pushOutcome = await sendPushIfConfigured({
      firebaseProjectId,
      firebaseClientEmail,
      firebasePrivateKey,
      topic: buildReportStatusTopic(reportUserId),
      message: {
        notification: {
          title: buildReportStatusTitle(status),
          body: buildReportStatusBody(status, rejectionReason),
        },
        data: {
          type: 'report_status',
          reportId,
          status,
          rejectionReason: rejectionReason ?? '',
        },
      },
      missingEnvError:
        'Report status updated, but Firebase Admin environment variables are missing.',
      pushFailureError: 'Report status updated, but push notification failed.',
    });

    return res.status(200).json({
      success: true,
      report: updatedReport
        ? {
            ...updatedReport,
            rejection_reason: missingRejectionReasonColumn
              ? null
              : updatedReport.rejection_reason ?? rejectionReason,
          }
        : updatedReport,
      warning: missingRejectionReasonColumn
        ? 'Report status updated, but rejection_reason could not be stored because the database column does not exist yet.'
        : null,
      push: pushOutcome.push,
      pushWarning: pushOutcome.pushWarning,
    });
  } catch (error) {
    return res.status(500).json({
      error: 'Unexpected error while updating report status.',
      details: error instanceof Error ? error.message : String(error),
    });
  }
}

async function handleOnlineServiceStatusUpdate({
  res,
  body,
  supabaseUrl,
  serviceRoleKey,
  firebaseProjectId,
  firebaseClientEmail,
  firebasePrivateKey,
}) {
  const table = String(body?.table ?? '').trim();
  const requestId = String(body?.requestId ?? '').trim();
  const status = normalizeOnlineServiceStatus(body?.status);
  const config = ONLINE_SERVICE_TABLE_CONFIG[table];

  if (!config) {
    return res.status(400).json({
      error: 'Invalid table value.',
      details: Object.keys(ONLINE_SERVICE_TABLE_CONFIG),
    });
  }

  if (!requestId) {
    return res.status(400).json({ error: 'requestId is required.' });
  }

  if (!status) {
    return res.status(400).json({
      error: 'Invalid status value.',
      details: 'Allowed values: pending, approved, rejected.',
    });
  }

  try {
    const updatedAt = new Date().toISOString();
    const patchResponse = await fetch(
      `${supabaseUrl}/rest/v1/${table}?id=eq.${encodeURIComponent(requestId)}`,
      {
        method: 'PATCH',
        headers: {
          apikey: serviceRoleKey,
          Authorization: `Bearer ${serviceRoleKey}`,
          'Content-Type': 'application/json',
          Prefer: 'return=representation',
        },
        body: JSON.stringify({
          status,
          updated_at: updatedAt,
        }),
      },
    );

    const patchText = await patchResponse.text();
    const patchJson = safeJsonParse(patchText);

    if (!patchResponse.ok) {
      return res.status(patchResponse.status).json({
        error: 'Failed to update online service request status.',
        details: patchJson ?? patchText,
      });
    }

    let updatedRequest = Array.isArray(patchJson) ? patchJson[0] ?? null : patchJson;

    if (!updatedRequest) {
      const lookupResponse = await fetch(
        `${supabaseUrl}/rest/v1/${table}?id=eq.${encodeURIComponent(requestId)}&select=*`,
        {
          method: 'GET',
          headers: {
            apikey: serviceRoleKey,
            Authorization: `Bearer ${serviceRoleKey}`,
            'Content-Type': 'application/json',
          },
        },
      );

      const lookupText = await lookupResponse.text();
      const lookupJson = safeJsonParse(lookupText);

      if (lookupResponse.ok && Array.isArray(lookupJson) && lookupJson[0]) {
        updatedRequest = lookupJson[0];
      }
    }

    const requestUserId = updatedRequest?.[config.userIdField]
      ? String(updatedRequest[config.userIdField]).trim()
      : '';

    const serviceLabel = buildOnlineServiceLabel(updatedRequest, config);
    const applicantName = buildOnlineServiceApplicantName(updatedRequest, config);
    const scheduleLabel = buildOnlineServiceScheduleLabel(updatedRequest, config);

    let pushOutcome;
    if (!requestUserId) {
      pushOutcome = {
        push: null,
        pushWarning: {
          error: 'Online service status updated, but request user_id was missing.',
        },
      };
    } else {
      pushOutcome = await sendPushIfConfigured({
        firebaseProjectId,
        firebaseClientEmail,
        firebasePrivateKey,
        topic: buildOnlineServiceStatusTopic(requestUserId),
        message: {
          notification: {
            title: buildOnlineServiceStatusTitle(serviceLabel, status),
            body: buildOnlineServiceStatusBody(serviceLabel, status, scheduleLabel),
          },
          data: {
            type: 'online_service_status',
            requestId,
            status,
            table,
            serviceLabel,
            applicantName,
            scheduleLabel,
          },
        },
        missingEnvError:
          'Online service status updated, but Firebase Admin environment variables are missing.',
        pushFailureError:
          'Online service status updated, but push notification failed.',
      });
    }

    return res.status(200).json({
      success: true,
      request: updatedRequest,
      push: pushOutcome.push,
      pushWarning: pushOutcome.pushWarning,
    });
  } catch (error) {
    return res.status(500).json({
      error: 'Unexpected error while updating online service request status.',
      details: error instanceof Error ? error.message : String(error),
    });
  }
}

async function sendPushIfConfigured({
  firebaseProjectId,
  firebaseClientEmail,
  firebasePrivateKey,
  topic,
  message,
  missingEnvError,
  pushFailureError,
}) {
  if (!firebaseProjectId || !firebaseClientEmail || !firebasePrivateKey) {
    return {
      push: null,
      pushWarning: {
        error: missingEnvError,
        details:
          'Set FIREBASE_PROJECT_ID, FIREBASE_CLIENT_EMAIL, and FIREBASE_PRIVATE_KEY in Vercel project settings.',
      },
    };
  }

  const accessToken = await getAccessToken({
    clientEmail: firebaseClientEmail,
    privateKey: firebasePrivateKey,
    scope: FCM_SCOPE,
  });

  const pushPayload = {
    message: {
      topic,
      notification: message.notification,
      data: message.data,
      android: {
        priority: 'high',
        notification: {
          channel_id: 'news_updates',
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
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
      },
      webpush: {
        headers: {
          Urgency: 'high',
        },
      },
    },
  };

  const pushResponse = await fetch(
    `https://fcm.googleapis.com/v1/projects/${firebaseProjectId}/messages:send`,
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(pushPayload),
    },
  );

  const pushResponseText = await pushResponse.text();
  const pushResponseJson = safeJsonParse(pushResponseText);

  if (pushResponse.ok) {
    return {
      push: pushResponseJson ?? pushResponseText,
      pushWarning: null,
    };
  }

  return {
    push: null,
    pushWarning: {
      error: pushFailureError,
      details: pushResponseJson ?? pushResponseText,
    },
  };
}

function buildReportStatusTitle(status) {
  switch (status) {
    case 'resolved':
      return 'Your report was resolved';
    case 'rejected':
      return 'Your report was rejected';
    case 'reviewing':
      return 'Your report is now processing';
    default:
      return 'Your report is under review';
  }
}

function buildReportStatusBody(status, rejectionReason) {
  switch (status) {
    case 'resolved':
      return 'The admin marked your report as resolved.';
    case 'rejected':
      return rejectionReason
        ? `The admin rejected your report. Reason: ${rejectionReason}`
        : 'The admin rejected your report.';
    case 'reviewing':
      return 'The admin started processing your report.';
    default:
      return 'The admin updated your report status.';
  }
}

function buildReportStatusTopic(reportUserId) {
  const raw = String(reportUserId || '').trim();
  const normalized = raw.replace(/[^a-zA-Z0-9-_.~%]/g, '_');
  return `report_user_${normalized || 'anonymous'}`;
}

function buildOnlineServiceStatusTopic(userId) {
  const raw = String(userId || '').trim();
  const normalized = raw.replace(/[^a-zA-Z0-9-_.~%]/g, '_');
  return `online_service_user_${normalized || 'anonymous'}`;
}

function buildOnlineServiceLabel(request, config) {
  const explicit = String(request?.service_name || '').trim();
  if (explicit) {
    return explicit;
  }

  const facility = String(request?.facility_name || '').trim();
  if (facility) {
    return facility;
  }

  return config.serviceLabel;
}

function buildOnlineServiceApplicantName(request, config) {
  if (!request || !config?.nameFields) {
    return '';
  }

  const values = config.nameFields
    .map((field) => String(request?.[field] || '').trim())
    .filter(Boolean);

  if (values.length === 0) {
    return '';
  }

  if (config === ONLINE_SERVICE_TABLE_CONFIG.marriage_certificate_appointments) {
    return values.join(' & ');
  }

  return values[0];
}

function buildOnlineServiceScheduleLabel(request, config) {
  if (!request || !config?.scheduleFields) {
    return '';
  }

  const values = config.scheduleFields
    .map((field) => String(request?.[field] || '').trim())
    .filter(Boolean);

  return values.join(' • ');
}

function buildOnlineServiceStatusTitle(serviceLabel, status) {
  switch (status) {
    case 'approved':
      return `${serviceLabel} request approved`;
    case 'rejected':
      return `${serviceLabel} request rejected`;
    default:
      return `${serviceLabel} request updated`;
  }
}

function buildOnlineServiceStatusBody(serviceLabel, status, scheduleLabel) {
  const suffix = scheduleLabel ? ` Schedule: ${scheduleLabel}.` : '';

  switch (status) {
    case 'approved':
      return `The admin approved your ${serviceLabel} request.${suffix}`;
    case 'rejected':
      return `The admin rejected your ${serviceLabel} request.${suffix}`;
    default:
      return `The admin updated your ${serviceLabel} request status.${suffix}`;
  }
}

async function getAccessToken({ clientEmail, privateKey, scope }) {
  const now = Math.floor(Date.now() / 1000);

  const jwtHeader = base64UrlEncode(JSON.stringify({ alg: 'RS256', typ: 'JWT' }));
  const jwtPayload = base64UrlEncode(
    JSON.stringify({
      iss: clientEmail,
      scope,
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
      `Failed to obtain Firebase access token: ${tokenText || tokenResponse.status}`,
    );
  }

  return tokenJson.access_token;
}

async function listAllFirebaseUsers({ projectId, accessToken }) {
  const users = [];
  let nextPageToken = '';
  let pageNum = 0;

  do {
    pageNum += 1;
    const query = new URLSearchParams({
      maxResults: String(FIREBASE_LIST_USERS_MAX_RESULTS),
    });

    if (nextPageToken) {
      query.set('nextPageToken', nextPageToken);
    }

    const response = await fetch(
      `${FIREBASE_ACCOUNTS_URL}/${encodeURIComponent(projectId)}/accounts:batchGet?${query.toString()}`,
      {
        method: 'GET',
        headers: {
          Authorization: `Bearer ${accessToken}`,
          'Content-Type': 'application/json',
        },
      },
    );

    const responseText = await response.text();
    const responseJson = safeJsonParse(responseText);

    if (!response.ok) {
      throw new Error(
        `Failed to load Firebase users: ${extractErrorMessage(responseJson) || responseText || response.status}`,
      );
    }

    const pageUsers = Array.isArray(responseJson?.users) ? responseJson.users : [];
    users.push(...pageUsers);
    nextPageToken = String(responseJson?.nextPageToken || '').trim();

  } while (nextPageToken);
  return users;
}

function normalizeFirebaseCreatedAt(user) {
  const createdAt = String(user?.createdAt || '').trim();

  if (!createdAt) {
    return null;
  }

  const timestamp = Number(createdAt);
  if (Number.isFinite(timestamp) && timestamp > 0) {
    return new Date(timestamp).toISOString();
  }

  const parsed = new Date(createdAt);
  return Number.isNaN(parsed.getTime()) ? null : parsed.toISOString();
}

function extractErrorMessage(value) {
  return value?.error?.message || value?.error_description || value?.details || '';
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

  const binary = atob(base64);
  const bytes = new Uint8Array(binary.length);

  for (let index = 0; index < binary.length; index += 1) {
    bytes[index] = binary.charCodeAt(index);
  }

  return bytes.buffer;
}

function base64UrlEncode(value) {
  const bytes =
    typeof value === 'string' ? new TextEncoder().encode(value) : new Uint8Array(value);

  let binary = '';
  for (let index = 0; index < bytes.length; index += 1) {
    binary += String.fromCharCode(bytes[index]);
  }

  return btoa(binary).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/g, '');
}

function normalizePrivateKey(value) {
  return value ? String(value).replace(/\\n/g, '\n') : '';
}

function normalizeReportStatus(value) {
  const status = String(value ?? '').trim().toLowerCase();

  if (['pending', 'reviewing', 'resolved', 'rejected'].includes(status)) {
    return status;
  }

  if (status === 'under review') return 'reviewing';
  if (status === 'processing' || status === 'in progress') return 'reviewing';

  return '';
}

function normalizeOnlineServiceStatus(value) {
  const status = String(value ?? '').trim().toLowerCase();

  if (status === 'approved' || status === 'approve') return 'approved';
  if (status === 'rejected' || status === 'reject') return 'rejected';
  if (status === 'pending') return 'pending';
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
    'Other administrative reason',
  ];
}

function safeJsonParse(value) {
  try {
    return JSON.parse(value);
  } catch (_) {
    return null;
  }
}
