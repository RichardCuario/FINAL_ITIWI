const { initFirebase, initSupabase } = require('./_lib/init');

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
    console.log('Starting user sync from Firebase to Supabase...');
    const admin = initFirebase();
    const supabase = initSupabase();

    const listUsersResult = await admin.auth().listUsers(1000);
    const users = listUsersResult.users;

    console.log(`Found ${users.length} users in Firebase`);

    const userData = users.map(user => {
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

    console.log(`Successfully synced ${userData.length} users`);
    res.status(200).json({
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
};
