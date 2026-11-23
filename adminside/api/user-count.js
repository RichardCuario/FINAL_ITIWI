const { requireSuperAdmin } = require('./_lib/require-super-admin');
const { initFirebase, initSupabase } = require('./_lib/init');

module.exports = async (req, res) => {
  // Set CORS headers
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (req.method === 'OPTIONS') {
    res.status(200).end();
    return;
  }

  if (req.method !== 'GET') return res.status(405).json({ success: false, error: 'Method not allowed' });
  try {
    const authorizedClient = await requireSuperAdmin(req, res, initSupabase);
    if (!authorizedClient) return;
    const admin = initFirebase();
    const listUsersResult = await admin.auth().listUsers(1000);
    const userCount = listUsersResult.users.length;

    res.status(200).json({
      success: true,
      userCount: userCount,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Error fetching user count:', error);
    res.status(500).json({
      success: false,
      error: 'Unable to process user request.'
    });
  }
};
