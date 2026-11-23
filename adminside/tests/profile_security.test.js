const test = require('node:test');
const assert = require('node:assert/strict');
const { createProfileHandler } = require('../api/_lib/profile-handler');
function harness({ invalid = false } = {}) {
  const calls = [];
  const auth = {
    verifyIdToken: async (token, revoked) => { calls.push(['verify', token, revoked]); if (invalid) throw Error('invalid'); return { uid: 'citizen-a' }; },
    getUser: async uid => ({ uid, email: 'verified@example.com' })
  };
  const db = { from: table => ({
    select: columns => ({ eq: (key, id) => ({ maybeSingle: async () => {
      calls.push(['read', table, columns, key, id]); return { data: { id } };
    } }) }),
    upsert: (data, options) => ({ select: () => ({ single: async () => {
      calls.push(['write', table, data, options]); return { data };
    } }) })
  }) };
  const handler = createProfileHandler({ initFirebase: () => ({ auth: () => auth }), initServiceSupabase: () => db });
  const res = { code: 200, setHeader() {}, status(code) { this.code = code; return this; }, json(body) { this.body = body; return this; }, end() {} };
  const invoke = async (method, body, headers = { authorization: 'Bearer valid' }) => {
    await handler({ method, body, headers, query: { id: 'victim' } }, res);
    return res;
  };
  return { invoke, calls };
}
test('profile requires a valid non-revoked Firebase session', async () => {
  assert.equal((await harness().invoke('GET', null, {})).code, 401);
  assert.equal((await harness({ invalid: true }).invoke('GET')).code, 401);
});
test('profile reads only verified UID even when another id is supplied in query', async () => {
  const h = harness();
  assert.equal((await h.invoke('GET')).body.profile.id, 'citizen-a');
  assert.deepEqual(h.calls[0], ['verify', 'valid', true]);
  assert.equal(h.calls[1][4], 'citizen-a');
});
test('citizens cannot submit IDs, emails, roles, or account-block fields', async () => {
  for (const body of [{ id: 'victim' }, { email: 'spoof@example.com' }, { is_active: true }, { role: 'admin' }, { is_super_admin: true }]) {
    const h = harness();
    assert.equal((await h.invoke('PATCH', body)).code, 400);
    assert.equal(h.calls.some(call => call[0] === 'write'), false);
  }
});
test('profile edits retain ownership and use Firebase email without changing block state', async () => {
  const h = harness();
  assert.equal((await h.invoke('PATCH', { phone: '09123', address: 'Tiwi', display_name: 'Citizen' })).code, 200);
  const saved = h.calls.find(call => call[0] === 'write')[2];
  assert.equal(saved.id, 'citizen-a');
  assert.equal(saved.email, 'verified@example.com');
  assert.equal(saved.phone, '09123');
  assert.equal(Object.hasOwn(saved, 'is_active'), false);
});
test('rejects invalid profile values and unsupported methods', async () => {
  for (const body of [{ phone: 123 }, { address: 'x'.repeat(1001) }, { photo_url: 'javascript:alert(1)' }]) {
    assert.equal((await harness().invoke('PATCH', body)).code, 400);
  }
  assert.equal((await harness().invoke('DELETE')).code, 405);
});
