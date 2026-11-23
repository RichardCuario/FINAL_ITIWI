const { initFirebase, initServiceSupabase } = require('../_lib/init');

const DIDIT_SESSION_URL = 'https://verification.didit.me/v3/session/';
const DIDIT_WORKFLOW_ID = '03b0f41b-6a1f-4784-be2c-cccc1ce0645b';
const DIDIT_CALLBACK_URL = 'https://itiwi-admin.vercel.app/verification-complete';

module.exports = async (req, res) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (req.method === 'OPTIONS') return res.status(200).end();
  if (req.method !== 'POST') return res.status(405).json({ error: 'method_not_allowed' });
  if (!process.env.DIDIT_API_KEY) {
    return res.status(503).json({ error: 'identity_verification_unavailable' });
  }

  const authorization = req.headers.authorization || '';
  const idToken = authorization.startsWith('Bearer ') ? authorization.slice(7) : '';
  if (!idToken) return res.status(401).json({ error: 'authentication_required' });

  try {
    const admin = initFirebase();
    const user = await admin.auth().verifyIdToken(idToken);
    const firebaseUser = await admin.auth().getUser(user.uid);
    if (!firebaseUser.email) {
      return res.status(400).json({ error: 'email_required_for_identity_verification' });
    }

    // The verification table references users(id). Sync the authenticated user
    // first so an otherwise valid first-time user can begin verification.
    const supabase = initServiceSupabase();
    const { error: userError } = await supabase.from('users').upsert({
      id: user.uid,
      email: firebaseUser.email,
      display_name: firebaseUser.displayName || firebaseUser.email,
      photo_url: firebaseUser.photoURL || null,
      updated_at: new Date().toISOString(),
    }, { onConflict: 'id' });
    if (userError) throw userError;

    const diditResponse = await fetch(DIDIT_SESSION_URL, {
      method: 'POST',
      headers: {
        'x-api-key': process.env.DIDIT_API_KEY,
        'Content-Type': 'application/json',
      },
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
      throw new Error('Didit returned an incomplete session response.');
    }

    const { error } = await supabase.from('identity_verification').upsert({
      user_id: user.uid,
      verification_status: 'in_progress',
      didit_session_id: session.session_id,
      didit_status: session.status || 'Not Started',
      didit_decision: null,
      rejection_reason: null,
      updated_at: new Date().toISOString(),
    }, { onConflict: 'user_id' });
    if (error) throw error;

    return res.status(201).json({
      session_id: session.session_id,
      session_token: session.session_token,
      url: session.url,
    });
  } catch (error) {
    console.error('Identity verification session failed:', error);
    return res.status(502).json({ error: 'session_create_failed' });
  }
};
