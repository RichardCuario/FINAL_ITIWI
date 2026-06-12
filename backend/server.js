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
