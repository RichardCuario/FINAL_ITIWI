const express = require('express');
const admin = require('firebase-admin');
const cors = require('cors');
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
const supabaseKey = process.env.SUPABASE_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpiaGxidWt4YW5rcnRjd2hxb2xsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ0NzAxODgsImV4cCI6MjA5MDA0NjE4OH0.DebtVdw7bF5nRaXQg8Ta2SsO2Qv42QnGSzoS8hT2vJc';
const supabase = createClient(supabaseUrl, supabaseKey);

const app = express();
const PORT = process.env.PORT || 5000;

// Middleware
app.use(cors());
app.use(express.json());

// Route to get user count
app.get('/api/user-count', async (req, res) => {
  try {
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

      return {
        id: user.uid,
        email: user.email || '',
        display_name: displayName,
        photo_url: user.photoURL || null,
        updated_at: new Date().toISOString()
      };
    });

    console.log('Sample user data:', userData.slice(0, 2));

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
      usersSynced: userData.length,
      sampleData: userData.slice(0, 3)
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
