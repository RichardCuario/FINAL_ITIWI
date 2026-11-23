const test = require('node:test');
const assert = require('node:assert/strict');

let service;
const initPath = require.resolve('../api/_lib/init.js');
require.cache[initPath] = {
  id: initPath, filename: initPath, loaded: true,
  exports: { initServiceSupabase: () => service }
};
const editAdminRole = require('../api/admin-roles/edit.js');

const callerId = '11111111-1111-4111-8111-111111111111';
const targetId = '22222222-2222-4222-8222-222222222222';
const newsId = '33333333-3333-4333-8333-333333333333';
const reportsId = '44444444-4444-4444-8444-444444444444';

function response() {
  return { code: 200, body: null, status(code) { this.code = code; return this; },
    json(body) { this.body = body; return this; } };
}

function request(body) {
  return { method: 'POST', headers: { authorization: 'Bearer test-token' },
    body: { roleId: newsId, roleName: 'Editor', features: ['news', 'reports'],
      reportCategories: ['Public safety'], ...body } };
}

test('a super admin can replace an account’s feature set and report categories', async () => {
  const rows = [
    { id: callerId, assigned_email: 'root@example.com', auth_user_id: callerId, is_super_admin: true, feature: 'all' },
    { id: newsId, assigned_email: 'editor@example.com', auth_user_id: targetId, is_super_admin: false, feature: 'news' },
    { id: reportsId, assigned_email: 'editor@example.com', auth_user_id: targetId, is_super_admin: false, feature: 'hotline' }
  ];
  const updated = [];
  const inserted = [];
  let removed = [];
  let metadata;
  service = {
    auth: {
      getUser: async () => ({ data: { user: { id: callerId, email: 'root@example.com' } } }),
      admin: {
        getUserById: async () => ({ data: { user: { user_metadata: { full_name: 'Editor' } } } }),
        updateUserById: async (id, value) => { metadata = { id, value }; return { error: null }; }
      }
    },
    from: () => ({
      select: async () => ({ data: rows, error: null }),
      update: value => ({ eq: async (_, id) => { updated.push({ id, value }); return { error: null }; } }),
      insert: async value => { inserted.push(value); return { error: null }; },
      delete: () => ({ in: async (_, ids) => { removed = ids; return { error: null }; } })
    })
  };
  const res = response();
  await editAdminRole(request({ roleName: 'Super Manager' }), res);
  assert.equal(res.code, 200);
  assert.deepEqual(updated, [{ id: newsId, value: {
    role_name: 'Super Manager', permissions: ['news'], report_categories: [], transparency_categories: []
  } }]);
  assert.deepEqual(inserted[0].permissions, ['reports']);
  assert.deepEqual(inserted[0].report_categories, ['Public safety']);
  assert.deepEqual(removed, [reportsId]);
  assert.equal(metadata.id, targetId);
  assert.deepEqual(metadata.value.user_metadata.permissions, ['news', 'reports']);
  assert.deepEqual(metadata.value.user_metadata.report_categories, ['Public safety']);
  assert.equal(metadata.value.user_metadata.full_name, 'Editor');
  assert.equal(metadata.value.user_metadata.role, 'Admin');
  assert.equal(metadata.value.user_metadata.is_super_admin, false);
});

test('non-super admins cannot edit roles', async () => {
  service = {
    auth: { getUser: async () => ({ data: { user: { id: targetId, email: 'editor@example.com' } } }) },
    from: () => ({ select: async () => ({ data: [
      { id: newsId, assigned_email: 'editor@example.com', auth_user_id: targetId, is_super_admin: false }
    ], error: null }) })
  };
  const res = response();
  await editAdminRole(request(), res);
  assert.equal(res.code, 403);
});

test('transparency edits validate and persist selected categories', async () => {
  const updates = [];
  const rows = [
    { id: callerId, assigned_email: 'root@example.com', auth_user_id: callerId, is_super_admin: true },
    { id: newsId, assigned_email: 'editor@unassigned.local', feature: 'transparency' }
  ];
  service = {
    auth: { getUser: async () => ({ data: { user: { id: callerId, email: 'root@example.com' } } }) },
    from: () => ({ select: async () => ({ data: rows }),
      update: value => ({ eq: async () => { updates.push(value); return {}; } }) })
  };
  for (const categories of [[], ['invalid']]) {
    const res = response();
    await editAdminRole(request({ features: ['transparency'], transparencyCategories: categories }), res);
    assert.equal(res.code, 400);
  }
  assert.equal(updates.length, 0);
  const res = response();
  await editAdminRole(request({ features: ['transparency'], transparencyCategories: ['bids_projects', 'financial_reports'] }), res);
  assert.equal(res.code, 200);
  assert.deepEqual(updates[0].transparency_categories, ['bids_projects', 'financial_reports']);
  assert.deepEqual(updates[0].report_categories, []);
});
