const express = require('express');
const admin = require('firebase-admin');
const cors = require('cors');
const crypto = require('node:crypto');
require('dotenv').config();

// Initialize Firebase Admin
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'itiwi-c7340'
});

// Initialize Supabase
const { createClient } = require('@supabase/supabase-js');
const supabaseUrl = process.env.SUPABASE_URL || 'https://jbhlbukxankrtcwhqoll.supabase.co';
const supabaseServiceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
const supabaseKey = supabaseServiceRoleKey || process.env.SUPABASE_KEY || '';
const supabase = createClient(supabaseUrl, supabaseKey);

const { requireUserAdmin } = require('../adminside/api/_lib/require-user-admin');
const adminUserClient = token => createClient(supabaseUrl, supabaseKey, {
  global: { headers: { Authorization: 'Bearer ' + token } }
});
const app = express();
const PORT = process.env.PORT || 5000;

// Middleware
app.use(cors());

const DIDIT_WORKFLOW_ID = '03b0f41b-6a1f-4784-be2c-cccc1ce0645b';
const DIDIT_SESSION_URL = 'https://verification.didit.me/v3/session/';
const DIDIT_CALLBACK_URL = 'https://itiwi-admin.vercel.app/verification-complete';

function requireDiditConfiguration(res) {
  if (process.env.DIDIT_API_KEY && supabaseServiceRoleKey) return false;
  res.status(503).json({
    error: 'identity_verification_unavailable',
    message: 'The identity verification service has not been configured.',
  });
  return true;
}

async function requireFirebaseUser(req, res) {
  const authorization = req.get('authorization') || '';
  const token = authorization.startsWith('Bearer ') ? authorization.slice(7) : '';
  if (!token) {
    res.status(401).json({ error: 'authentication_required' });
    return null;
  }

  try {
    return await admin.auth().verifyIdToken(token);
  } catch (_) {
    res.status(401).json({ error: 'invalid_authentication' });
    return null;
  }
}

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

// Didit posts directly to this endpoint. It must be registered at a public HTTPS URL.
app.post('/api/webhooks/didit', express.raw({ type: 'application/json' }), async (req, res) => {
  const signature = req.get('x-signature-v2') || '';
  if (!process.env.DIDIT_WEBHOOK_SECRET || !supabaseServiceRoleKey) {
    return res.status(503).send('not configured');
  }

  let payload;
  try {
    payload = JSON.parse(req.body.toString('utf8'));
  } catch (_) {
    return res.status(400).send('invalid json');
  }

  const canonical = JSON.stringify(sortKeys(shortenFloats(payload)));
  const expected = crypto
    .createHmac('sha256', process.env.DIDIT_WEBHOOK_SECRET)
    .update(canonical, 'utf8')
    .digest('hex');
  const received = Buffer.from(signature, 'utf8');
  const expectedBuffer = Buffer.from(expected, 'utf8');
  if (received.length !== expectedBuffer.length || !crypto.timingSafeEqual(received, expectedBuffer)) {
    return res.status(401).send('bad signature');
  }
  const timestamp = Number(payload.timestamp);
  if (!timestamp || Math.abs(Date.now() / 1000 - timestamp) > 300) {
    return res.status(401).send('stale');
  }
  if (!payload.event_id || !payload.vendor_data || !payload.session_id) return res.status(400).send('invalid event');

  try {
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

    // Store the event only after its idempotent database update succeeds. A retry
    // after a transient failure can therefore safely finish the update.
    const { error: eventError } = await supabase
      .from('didit_webhook_events')
      .insert({ event_id: payload.event_id });
    if (eventError) {
      if (eventError.code === '23505') return res.status(200).send('ok');
      throw eventError;
    }

    if (['Approved', 'Declined'].includes(payload.status)) {
      await admin.messaging().send({
        topic: `identity_verification_user_${String(payload.vendor_data).replace(/[^a-zA-Z0-9-_.~%]/g, '_')}`,
        notification: {
          title: payload.status === 'Approved' ? 'Your identity verification was approved' : 'Your identity verification was declined',
          body: payload.status === 'Approved'
            ? 'You can now access all verification-based features.'
            : 'Please review the result and try again if needed.',
        },
        data: { type: 'identity_verification_status', status: verificationStatus, rejectionReason: rejectionReason || '' },
      });
    }
    return res.status(200).send('ok');
  } catch (error) {
    console.error('Didit webhook processing failed:', error);
    return res.status(500).send('processing failed');
  }
});

app.use(express.json());
const { createProfileHandler } = require('../adminside/api/_lib/profile-handler');
app.all('/api/profile', createProfileHandler({
  initFirebase: () => admin,
  initServiceSupabase: () => {
    if (!supabaseServiceRoleKey) throw new Error('SUPABASE_SERVICE_ROLE_KEY is required');
    return supabase;
  }
}));

// The authenticated app user cannot choose vendor_data; their verified Firebase UID is used.
app.post('/api/identity-verification/session', async (req, res) => {
  if (requireDiditConfiguration(res)) return;
  const user = await requireFirebaseUser(req, res);
  if (!user) return;

  try {
    const diditResponse = await fetch(DIDIT_SESSION_URL, {
      method: 'POST',
      headers: { 'x-api-key': process.env.DIDIT_API_KEY, 'Content-Type': 'application/json' },
      body: JSON.stringify({
        workflow_id: DIDIT_WORKFLOW_ID,
        vendor_data: user.uid,
        callback: process.env.DIDIT_CALLBACK_URL || DIDIT_CALLBACK_URL,
      }),
    });
    if (!diditResponse.ok) {
      console.error('Didit session creation failed:', diditResponse.status, await diditResponse.text());
      return res.status(502).json({ error: 'session_create_failed' });
    }
    const session = await diditResponse.json();
    if (!session.session_id || !session.session_token || !session.url) {
      throw new Error('Didit returned an incomplete session response');
    }

    const { error: saveError } = await supabase.from('identity_verification').upsert({
      user_id: user.uid,
      verification_status: 'in_progress',
      didit_session_id: session.session_id,
      didit_status: session.status || 'Not Started',
      didit_decision: null,
      rejection_reason: null,
      updated_at: new Date().toISOString(),
    }, { onConflict: 'user_id' });
    if (saveError) throw saveError;

    return res.status(201).json({
      session_id: session.session_id,
      session_token: session.session_token,
      url: session.url,
    });
  } catch (error) {
    console.error('Identity verification session failed:', error);
    return res.status(502).json({ error: 'session_create_failed' });
  }
});

// Route to get user count
app.get('/api/user-count', async (req, res) => {
  try {
    if (!await requireUserAdmin(req, res, adminUserClient)) return;
    const listUsersResult = await admin.auth().listUsers(1000);
    const userCount = listUsersResult.users.length;

    res.json({
      success: true,
      userCount: userCount,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Error fetching user count:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// Route to get detailed user list (for debugging)
app.get('/api/users', async (req, res) => {
  try {
    if (!await requireUserAdmin(req, res, adminUserClient)) return;
    const listUsersResult = await admin.auth().listUsers(1000);
    const users = listUsersResult.users.map(user => ({
      uid: user.uid,
      email: user.email,
      displayName: user.displayName || 'N/A',
      creationTime: user.metadata.creationTime,
      lastSignInTime: user.metadata.lastSignInTime
    }));

    res.json({
      success: true,
      total: users.length,
      users: users
    });
  } catch (error) {
    console.error('Error fetching users:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// Route to sync Firebase users to Supabase
app.post('/api/sync-users', async (req, res) => {
  try {
    if (!await requireUserAdmin(req, res, adminUserClient)) return;
    console.log('Starting user sync from Firebase to Supabase...');

    const listUsersResult = await admin.auth().listUsers(1000);
    const users = listUsersResult.users;

    console.log(`Found ${users.length} users in Firebase`);

    // Prepare data for Supabase
    const userData = users.map(user => {
      // Use displayName if available, otherwise use email, otherwise use a fallback
      const displayName = (user.displayName && user.displayName.trim())
        ? user.displayName
        : (user.email || `User ${user.uid.substring(0, 8)}`);

      // Convert Firebase creationTime (e.g. "Mon, 01 Jan 2024 00:00:00 GMT") to ISO string
      let createdAt = null;
      if (user.metadata && user.metadata.creationTime) {
        createdAt = new Date(user.metadata.creationTime).toISOString();
      }

      return {
        id: user.uid,
        email: user.email || '',
        display_name: displayName,
        photo_url: user.photoURL || null,
        created_at: createdAt,
        updated_at: new Date().toISOString()
      };
    });


    // Upsert users into Supabase
    const { error } = await supabase
      .from('users')
      .upsert(userData, { onConflict: 'id' });

    if (error) {
      console.error('Supabase upsert error:', error);
      return res.status(500).json({
        success: false,
        error: error.message
      });
    }

    console.log(`✅ Successfully synced ${userData.length} users`);
    res.json({
      success: true,
      message: `Synced ${userData.length} users from Firebase to Supabase`,
      usersSynced: userData.length
    });
  } catch (error) {
    console.error('Error syncing users:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// Route to send FCM notification (news, report status, online service status)
app.post('/api/send-notification', async (req, res) => {
  try {
    const {
      title,
      description,
      image_url,
      topic,
      type,
      reportId,
      status,
      rejectionReason,
      serviceLabel,
      requestId,
      applicantName,
      scheduleLabel,
      table,
    } = req.body;

    const notificationType = type || 'news';
    let targetTopic = topic || 'news_updates';

    // Build notification title
    let notificationTitle = title;
    if (!notificationTitle) {
      if (notificationType === 'report_status') {
        const s = (status || '').toLowerCase();
        if (s === 'resolved') notificationTitle = 'Your report was resolved';
        else if (s === 'rejected') notificationTitle = 'Your report was rejected';
        else if (s === 'reviewing' || s === 'processing') notificationTitle = 'Your report is being reviewed';
        else notificationTitle = 'Your report status was updated';
      } else if (notificationType === 'online_service_status') {
        const label = serviceLabel || 'Online service';
        const s = (status || '').toLowerCase();
        if (s === 'approved') notificationTitle = `${label} request approved`;
        else if (s === 'rejected') notificationTitle = `${label} request rejected`;
        else notificationTitle = `${label} request updated`;
      } else if (notificationType === 'identity_verification_status') {
        const s = (status || '').toLowerCase();
        if (s === 'verified') notificationTitle = 'Your identity verification was approved';
        else if (s === 'rejected') notificationTitle = 'Your identity verification was rejected';
        else notificationTitle = 'Your identity verification status was updated';
      } else {
        notificationTitle = 'New Announcement';
      }
    }

    // Build notification body
    let notificationBody = description;
    if (!notificationBody) {
      if (notificationType === 'report_status') {
        const s = (status || '').toLowerCase();
        if (s === 'rejected') {
          const reason = rejectionReason || '';
          notificationBody = reason ? `The admin rejected your report. Reason: ${reason}` : 'The admin rejected your report.';
        } else if (s === 'resolved') {
          notificationBody = 'The admin marked your report as resolved.';
        } else if (s === 'reviewing' || s === 'processing') {
          notificationBody = 'The admin started processing your report.';
        } else {
          notificationBody = 'The admin updated your report status.';
        }
      } else if (notificationType === 'online_service_status') {
        const label = serviceLabel || 'online service';
        const s = (status || '').toLowerCase();
        const schedule = scheduleLabel ? ` Schedule: ${scheduleLabel}.` : '';
        if (s === 'approved') notificationBody = `The admin approved your ${label} request.${schedule}`;
        else if (s === 'rejected') notificationBody = `The admin rejected your ${label} request.${schedule}`;
        else notificationBody = `The admin updated your ${label} request status.${schedule}`;
      } else if (notificationType === 'identity_verification_status') {
        const s = (status || '').toLowerCase();
        if (s === 'verified') {
          notificationBody = 'Your identity verification has been approved. You can now access all verification-based features.';
        } else if (s === 'rejected') {
          const reason = rejectionReason || '';
          notificationBody = reason
            ? `Your identity verification was rejected. Reason: ${reason}`
            : 'Your identity verification was rejected. Please review the requirements and resubmit.';
        } else {
          notificationBody = 'Your identity verification status was updated.';
        }
      } else {
        notificationBody = 'Tap to view the latest news.';
      }
    }

    // Build data payload
    const dataPayload = { type: notificationType, click_action: 'FLUTTER_NOTIFICATION_CLICK' };

    if (notificationType === 'report_status') {
      dataPayload.reportId = reportId || '';
      dataPayload.status = status || '';
      dataPayload.rejectionReason = rejectionReason || '';
      dataPayload.title = notificationTitle;
      dataPayload.description = notificationBody;
    } else if (notificationType === 'online_service_status') {
      dataPayload.requestId = requestId || '';
      dataPayload.status = status || '';
      dataPayload.serviceLabel = serviceLabel || '';
      dataPayload.applicantName = applicantName || '';
      dataPayload.scheduleLabel = scheduleLabel || '';
      dataPayload.table = table || '';
      dataPayload.title = notificationTitle;
      dataPayload.description = notificationBody;
    } else if (notificationType === 'identity_verification_status') {
      dataPayload.userId = userId || '';
      dataPayload.status = status || '';
      dataPayload.rejectionReason = rejectionReason || '';
      dataPayload.title = notificationTitle;
      dataPayload.description = notificationBody;
    } else {
      dataPayload.title = notificationTitle;
      dataPayload.description = notificationBody || '';
      dataPayload.image_url = image_url || '';
    }

    const message = {
      topic: targetTopic,
      notification: {
        title: notificationTitle,
        body: notificationBody
          ? (notificationBody.length > 150 ? notificationBody.substring(0, 150) + '…' : notificationBody)
          : 'Tap to view the latest update.',
      },
      data: dataPayload,
      android: {
        priority: 'high',
        notification: {
          channelId: 'news_updates',
          priority: 'high',
          sound: 'default',
          defaultSound: true,
          defaultVibrateTimings: true,
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
            contentAvailable: true,
          },
        },
      },
    };

    const response = await admin.messaging().send(message);
    console.log(`✅ FCM ${notificationType} notification sent to topic "${targetTopic}":`, response);

    res.json({
      success: true,
      messageId: response,
      topic: targetTopic,
      type: notificationType,
    });
  } catch (error) {
    console.error('Error sending FCM notification:', error);
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

// Health check
app.get('/api/health', (req, res) => {
  res.json({ status: 'Backend is running' });
});

app.listen(PORT, () => {
  console.log(`✅ Server running on http://localhost:${PORT}`);
  console.log(`📊 Get user count: http://localhost:${PORT}/api/user-count`);
  console.log(`👥 Get all users: http://localhost:${PORT}/api/users`);
  console.log(`🔄 Sync users: POST http://localhost:${PORT}/api/sync-users`);
});
