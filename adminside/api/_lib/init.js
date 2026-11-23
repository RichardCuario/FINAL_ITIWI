const admin = require('firebase-admin');
const { createClient } = require('@supabase/supabase-js');

// Initialize Firebase Admin with server-only environment variables.
function initFirebase() {
  if (admin.apps.length > 0) return admin;

  const projectId = process.env.FIREBASE_PROJECT_ID;
  const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;
  const privateKey = process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n');

  if (!projectId || !clientEmail || !privateKey) {
    throw new Error(
      'Firebase Admin is not configured. Set FIREBASE_PROJECT_ID, ' +
      'FIREBASE_CLIENT_EMAIL, and FIREBASE_PRIVATE_KEY.'
    );
  }

  admin.initializeApp({
    credential: admin.credential.cert({ projectId, clientEmail, privateKey }),
    projectId
  });

  return admin;
}

// Initialize Supabase. Configure server credentials through the host environment.
function initSupabase(accessToken = null) {
  const supabaseUrl = process.env.SUPABASE_URL;
  const supabaseKey = process.env.SUPABASE_KEY;

  if (!supabaseUrl || !supabaseKey) {
    throw new Error('Supabase is not configured. Set SUPABASE_URL and SUPABASE_KEY.');
  }

  return createClient(
    supabaseUrl,
    supabaseKey,
    accessToken
      ? { global: { headers: { Authorization: `Bearer ${accessToken}` } } }
      : undefined
  );
}

// Identity-provider webhooks bypass end-user RLS and therefore must use the
// Supabase service-role key. Keep it separate from the optional user-facing key.
function initServiceSupabase() {
  const supabaseUrl = process.env.SUPABASE_URL;
  const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

  if (!supabaseUrl || !serviceRoleKey) {
    throw new Error(
      'Supabase service access is not configured. Set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY.'
    );
  }

  return createClient(supabaseUrl, serviceRoleKey);
}

module.exports = { initFirebase, initSupabase, initServiceSupabase };
