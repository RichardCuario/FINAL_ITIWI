const { initFirebase } = require('./_lib/init');

module.exports = async (req, res) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.status(200).end();
    return;
  }

  if (req.method !== 'POST') {
    res.status(405).json({ success: false, error: 'Method not allowed' });
    return;
  }

  try {
    const {
      // Common fields
      title,
      description,
      image_url,
      topic,
      type,

      // Report status specific
      reportId,
      status,
      rejectionReason,

      // Online service specific
      serviceLabel,
      requestId,
      applicantName,
      scheduleLabel,
      table,
    } = req.body;

    const admin = initFirebase();
    const notificationType = type || 'news';

    // Determine the topic to send to
    let targetTopic = topic || 'news_updates';

    // Build notification title based on type
    let notificationTitle = title;
    if (!notificationTitle) {
      if (notificationType === 'report_status') {
        const statusLower = (status || '').toLowerCase();
        if (statusLower === 'resolved') notificationTitle = 'Your report was resolved';
        else if (statusLower === 'rejected') notificationTitle = 'Your report was rejected';
        else if (statusLower === 'reviewing' || statusLower === 'processing') notificationTitle = 'Your report is being reviewed';
        else notificationTitle = 'Your report status was updated';
      } else if (notificationType === 'online_service_status') {
        const label = serviceLabel || 'Online service';
        const statusLower = (status || '').toLowerCase();
        if (statusLower === 'approved') notificationTitle = `${label} request approved`;
        else if (statusLower === 'rejected') notificationTitle = `${label} request rejected`;
        else notificationTitle = `${label} request updated`;
      } else {
        notificationTitle = 'New Announcement';
      }
    }

    // Build notification body based on type
    let notificationBody = description;
    if (!notificationBody) {
      if (notificationType === 'report_status') {
        const statusLower = (status || '').toLowerCase();
        if (statusLower === 'rejected') {
          const reason = rejectionReason || '';
          notificationBody = reason
            ? `The admin rejected your report. Reason: ${reason}`
            : 'The admin rejected your report.';
        } else if (statusLower === 'resolved') {
          notificationBody = 'The admin marked your report as resolved.';
        } else if (statusLower === 'reviewing' || statusLower === 'processing') {
          notificationBody = 'The admin started processing your report.';
        } else {
          notificationBody = 'The admin updated your report status.';
        }
      } else if (notificationType === 'online_service_status') {
        const label = serviceLabel || 'online service';
        const statusLower = (status || '').toLowerCase();
        const schedule = scheduleLabel ? ` Schedule: ${scheduleLabel}.` : '';
        if (statusLower === 'approved') {
          notificationBody = `The admin approved your ${label} request.${schedule}`;
        } else if (statusLower === 'rejected') {
          notificationBody = `The admin rejected your ${label} request.${schedule}`;
        } else {
          notificationBody = `The admin updated your ${label} request status.${schedule}`;
        }
      } else {
        notificationBody = 'Tap to view the latest news.';
      }
    }

    // Build data payload based on type
    const dataPayload = {
      type: notificationType,
      click_action: 'FLUTTER_NOTIFICATION_CLICK',
    };

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
      // News notification
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

    res.status(200).json({
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
};
