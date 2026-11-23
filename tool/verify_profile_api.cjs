const fs = require('node:fs');
const crypto = require('node:crypto');
const path = require('node:path');
const admin = require('../backend/node_modules/firebase-admin');
const root = path.resolve(__dirname, '..');
(async () => {
  const uid = 'security-check-' + crypto.randomUUID();
  const email = uid + '@example.invalid';
  // Cleanup targets only this generated test identity. Never print tokens/keys.
  fs.writeFileSync(path.join(__dirname, 'profile_test_cleanup.sql'),
    "delete from public.users where id = '" + uid + "' and email = '" + email + "';");
  admin.initializeApp({ credential: admin.credential.cert(require('../backend/serviceAccountKey.json')) });
  try {
    await admin.auth().createUser({ uid, email, emailVerified: true });
    const config = JSON.parse(fs.readFileSync(path.join(root, 'android/app/google-services.json'), 'utf8'));
    const key = config.client[0].api_key[0].current_key;
    const customToken = await admin.auth().createCustomToken(uid);
    const authResponse = await fetch('https://identitytoolkit.googleapis.com/v1/accounts:signInWithCustomToken?key=' + encodeURIComponent(key), {
      method: 'POST', headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ token: customToken, returnSecureToken: true })
    });
    const auth = await authResponse.json();
    if (!authResponse.ok || !auth.idToken) throw Error('Test sign-in failed');
    const headers = { Authorization: 'Bearer ' + auth.idToken, 'Content-Type': 'application/json' };
    const base = 'https://itiwi-admin.vercel.app/api/profile';
    const saved = await fetch(base, { method: 'PATCH', headers,
      body: JSON.stringify({ display_name: 'Temporary security check', phone: 'test', address: 'test' }) });
    const saveBody = await saved.json();
    if (saved.status !== 200 || saveBody.profile?.id !== uid) throw Error('Profile save failed: ' + saved.status);
    const loaded = await fetch(base + '?id=other-user', { headers });
    const loadBody = await loaded.json();
    if (loaded.status !== 200 || loadBody.profile?.id !== uid || loadBody.profile.phone !== 'test') throw Error('Own-profile read failed');
    const rejected = await fetch(base, { method: 'PATCH', headers, body: JSON.stringify({ id: 'other-user', is_active: true }) });
    if (rejected.status !== 400) throw Error('Forbidden fields accepted');
    console.log('PASS: live profile save/read; caller cannot select another UID or set block state.');
  } finally {
    await admin.auth().deleteUser(uid);
    console.log('Firebase test identity deleted; run tool/profile_test_cleanup.sql to remove its profile.');
  }
})().catch(error => { console.error(error.message); process.exitCode = 1; });
