const test = require('node:test');
const assert = require('node:assert/strict');
const initPath = require.resolve('../api/_lib/init');
let uploaded;
require.cache[initPath] = { id: initPath, filename: initPath, loaded: true, exports: {
  initFirebase: () => ({ auth: () => ({ verifyIdToken: async token => {
    if (token !== 'valid') throw new Error('invalid token');
    return { uid: 'citizen-123' };
  } }) }),
  initServiceSupabase: () => ({ storage: { from: bucket => ({ upload: async (path, bytes) => {
    uploaded = { bucket, path, bytes }; return {};
  } }) } })
} };
const upload = require('../api/birth-certificate/upload');
const response = () => ({ code: 200, status(code) { this.code = code; return this; }, json(body) { this.body = body; return this; } });
test('rejects unauthenticated uploads and invalid images', async () => {
  for (const [token, body, expected] of [['invalid', {}, 401], ['valid', {kind:'owner-id', contentType:'image/jpeg', image:'aGVsbG8='}, 400]]) {
    const res = response();
    await upload({method:'POST', headers:{authorization:`Bearer ${token}`}, body}, res);
    assert.equal(res.code, expected);
  }
  assert.equal(uploaded, undefined);
});
test('stores document privately under the verified user and returns only its path', async () => {
  const res = response();
  await upload({method:'POST', headers:{authorization:'Bearer valid'}, body:{
    kind:'authorization', contentType:'image/jpeg', image:Buffer.from([255,216,255,224]).toString('base64')
  }},res);
  assert.equal(res.code,200);
  assert.equal(uploaded.bucket,'birth-certificate-documents');
  assert.match(res.body.path,/^citizen-123\/.*-authorization.jpg$/);
  assert.equal(res.body.url,undefined);
});
