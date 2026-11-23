const { randomUUID } = require('node:crypto');
const { initFirebase, initServiceSupabase } = require('../_lib/init');

module.exports = async (req, res) => {
  if (req.method !== 'POST') return res.status(405).json({ error: 'Method not allowed' });
  const token = String(req.headers.authorization || '').replace(/^Bearer\s+/i, '');
  let user;
  try { user = await initFirebase().auth().verifyIdToken(token); }
  catch (_) { return res.status(401).json({ error: 'Please sign in again.' }); }
  const { kind, contentType, image } = req.body || {};
  const extensions = { 'image/jpeg': 'jpg', 'image/png': 'png', 'image/webp': 'webp' };
  if (!['authorization', 'owner-id'].includes(kind) || !extensions[contentType] ||
      typeof image !== 'string' || image.length > 2800000 || !/^[A-Za-z0-9+/]+={0,2}$/.test(image)) {
    return res.status(400).json({ error: 'Choose a valid document image, up to 2 MB.' });
  }
  const bytes = Buffer.from(image, 'base64');
  const matches = contentType === 'image/jpeg' ? bytes.subarray(0, 3).equals(Buffer.from([255, 216, 255]))
    : contentType === 'image/png' ? bytes.subarray(0, 8).equals(Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]))
    : bytes.toString('ascii', 0, 4) === 'RIFF' && bytes.toString('ascii', 8, 12) === 'WEBP';
  if (!matches || bytes.length > 2 * 1024 * 1024) return res.status(400).json({ error: 'Invalid image.' });
  try {
    const path = `${encodeURIComponent(user.uid)}/${randomUUID()}-${kind}.${extensions[contentType]}`;
    const { error } = await initServiceSupabase().storage.from('birth-certificate-documents')
      .upload(path, bytes, { contentType, upsert: false });
    if (error) throw error;
    return res.status(200).json({ path });
  } catch (_) {
    return res.status(500).json({ error: 'Document upload failed. Please try again.' });
  }
};
