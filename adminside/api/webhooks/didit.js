const crypto = require('node:crypto');
const { initServiceSupabase } = require('../_lib/init');

function shortenFloats(value) {
  if (Array.isArray(value)) return value.map(shortenFloats);
  if (value && typeof value === 'object') {
    return Object.fromEntries(Object.entries(value).map(([key, item]) => [key, shortenFloats(item)]));
  }
  return typeof value === 'number' && !Number.isInteger(value) && value % 1 === 0
    ? Math.trunc(value)
    : value;
}

function sortKeys(value) {
  if (Array.isArray(value)) return value.map(sortKeys);
  if (value && typeof value === 'object') {
    return Object.keys(value).sort().reduce((result, key) => {
      result[key] = sortKeys(value[key]);
      return result;
    }, {});
  }
  return value;
}

function readRawBody(req) {
  return new Promise((resolve, reject) => {
    const chunks = [];
    let size = 0;
    req.on('data', chunk => {
      size += chunk.length;
      if (size > 1024 * 1024) {
        reject(new Error('Request body is too large.'));
        req.destroy();
        return;
      }
      chunks.push(chunk);
    });
    req.on('end', () => resolve(Buffer.concat(chunks)));
    req.on('error', reject);
  });
}

const handler = async (req, res) => {
  if (req.method !== 'POST') return res.status(405).send('method not allowed');
  if (!process.env.DIDIT_WEBHOOK_SECRET) return res.status(503).send('not configured');

  let payload;
  try {
    const rawBody = await readRawBody(req);
    payload = JSON.parse(rawBody.toString('utf8'));
  } catch (_) {
    return res.status(400).send('invalid json');
  }

  const expected = crypto
    .createHmac('sha256', process.env.DIDIT_WEBHOOK_SECRET)
    .update(JSON.stringify(sortKeys(shortenFloats(payload))), 'utf8')
    .digest('hex');
  const received = Buffer.from(String(req.headers['x-signature-v2'] || ''), 'utf8');
  const expectedBuffer = Buffer.from(expected, 'utf8');
  if (received.length !== expectedBuffer.length || !crypto.timingSafeEqual(received, expectedBuffer)) {
    return res.status(401).send('bad signature');
  }
  const timestamp = Number(payload.timestamp);
  if (!timestamp || Math.abs(Date.now() / 1000 - timestamp) > 300) {
    return res.status(401).send('stale');
  }
  if (!payload.event_id || !payload.vendor_data || !payload.session_id) return res.status(400).send('invalid event');

  const statusMap = {
    'Not Started': 'pending',
    'In Progress': 'in_progress',
    'Awaiting User': 'pending',
    'In Review': 'pending_review',
    Approved: 'verified',
    Declined: 'rejected',
    Resubmitted: 'pending',
    Abandoned: 'abandoned',
    Expired: 'expired',
    'Kyc Expired': 'expired',
  };

  try {
    const supabase = initServiceSupabase();
    const verificationStatus = statusMap[payload.status] || 'pending';
    const rejectionReason = payload.status === 'Declined'
      ? (payload.decision?.reason || payload.decision?.status_reason || 'Identity verification was declined.')
      : null;
    const update = {
      verification_status: verificationStatus,
      didit_status: payload.status,
      didit_decision: payload.decision || null,
      rejection_reason: rejectionReason,
      updated_at: new Date().toISOString(),
    };
    if (payload.status === 'Approved') update.verified_at = new Date().toISOString();

    const { error: updateError } = await supabase
      .from('identity_verification')
      .update(update)
      .eq('user_id', String(payload.vendor_data))
      .eq('didit_session_id', String(payload.session_id));
    if (updateError) throw updateError;

    const { error: eventError } = await supabase
      .from('didit_webhook_events')
      .insert({ event_id: payload.event_id });
    if (eventError) {
      if (eventError.code === '23505') return res.status(200).send('ok');
      throw eventError;
    }
    return res.status(200).send('ok');
  } catch (error) {
    console.error('Didit webhook processing failed:', error);
    return res.status(500).send('processing failed');
  }
};

module.exports = handler;
module.exports.config = { api: { bodyParser: false } };
