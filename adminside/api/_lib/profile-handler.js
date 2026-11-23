// Only the verified Firebase UID can select the row. No caller-supplied IDs.
const PROFILE_COLUMNS = 'id, email, display_name, phone, address, photo_url, is_active';
function createProfileHandler({ initFirebase, initServiceSupabase }) {
  return async (req, res) => {
    res.setHeader('Cache-Control', 'no-store');
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    res.setHeader('Access-Control-Allow-Methods', 'GET, PATCH, OPTIONS');
    if (req.method === 'OPTIONS') return res.status(200).end();
    if (!['GET', 'PATCH'].includes(req.method)) return res.status(405).json({ error: 'method_not_allowed' });
    const token = /^Bearer\s+(\S+)$/i.exec(req.headers.authorization || '')?.[1];
    if (!token) return res.status(401).json({ error: 'authentication_required' });
    try {
      const auth = initFirebase().auth();
      let identity;
      try { identity = await auth.verifyIdToken(token, true); }
      catch (_) { return res.status(401).json({ error: 'invalid_authentication' }); }
      if (!identity?.uid) return res.status(401).json({ error: 'invalid_authentication' });
      const db = initServiceSupabase();
      if (req.method === 'GET') {
        const { data, error } = await db.from('users').select(PROFILE_COLUMNS).eq('id', identity.uid).maybeSingle();
        if (error) throw error;
        return res.status(200).json({ profile: data });
      }
      const body = req.body;
      const limits = { display_name: 200, phone: 50, address: 1000, photo_url: 2048 };
      if (!body || typeof body !== 'object' || Array.isArray(body) ||
          Object.keys(body).some(key => !Object.hasOwn(limits, key))) {
        return res.status(400).json({ error: 'invalid_profile_fields' });
      }
      const updates = {};
      for (const [key, value] of Object.entries(body)) {
        if (typeof value !== 'string' && !(key === 'photo_url' && value === null)) {
          return res.status(400).json({ error: 'invalid_profile_value' });
        }
        if (value !== null && value.length > limits[key]) return res.status(400).json({ error: 'profile_value_too_long' });
        if (key === 'photo_url' && value && !/^https:\/\//i.test(value)) return res.status(400).json({ error: 'invalid_photo_url' });
        updates[key] = value;
      }
      // Email and identity come from Firebase, not request data. Never write is_active.
      const firebaseUser = await auth.getUser(identity.uid);
      if (!firebaseUser.email) return res.status(400).json({ error: 'email_required' });
      const { data, error } = await db.from('users').upsert({
        ...updates, id: identity.uid, email: firebaseUser.email,
        updated_at: new Date().toISOString()
      }, { onConflict: 'id' }).select(PROFILE_COLUMNS).single();
      if (error) throw error;
      return res.status(200).json({ profile: data });
    } catch (error) {
      console.error('Profile operation failed:', error.code || 'server_error');
      return res.status(500).json({ error: 'profile_unavailable' });
    }
  };
}
module.exports = { createProfileHandler };
