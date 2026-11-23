const test = require('node:test');
const assert = require('node:assert/strict');

let service;
const initPath = require.resolve('../api/_lib/init.js');
require.cache[initPath] = {
  id: initPath,
  filename: initPath,
  loaded: true,
  exports: { initServiceSupabase: () => service }
};
const removeAdminRole = require('../api/admin-roles/remove.js');

const callerId = '11111111-1111-4111-8111-111111111111';
const targetId = '22222222-2222-4222-8222-222222222222';
const secondTargetId = '33333333-3333-4333-8333-333333333333';

function response() {
  return {
    code: 200,
    body: null,
    status(code) { this.code = code; return this; },
    json(body) { this.body = body; return this; }
  };
}

function request(roleId = targetId) {
  return {
    method: 'POST',
    headers: { authorization: 'Bearer test-token' },
    body: { roleId }
  };
}

test('non-super admins cannot remove roles', async () => {
  service = {
    auth: { getUser: async () => ({ data: { user: { id: callerId, email: 'officer@example.com', app_metadata: {} } } }) },
    from: () => ({ select: async () => ({ data: [
      { id: targetId, assigned_email: 'target@example.com', auth_user_id: null, is_super_admin: false }
    ] }) })
  };
  const res = response();
  await removeAdminRole(request(), res);
  assert.equal(res.code, 403);
});

test('super admin cannot remove their own account', async () => {
  service = {
    auth: { getUser: async () => ({ data: { user: { id: callerId, email: 'root@example.com', app_metadata: {} } } }) },
    from: () => ({ select: async () => ({ data: [
      { id: callerId, assigned_email: 'root@example.com', auth_user_id: callerId, is_super_admin: true }
    ], error: null }) })
  };
  const res = response();
  await removeAdminRole(request(callerId), res);
  assert.equal(res.code, 400);
});

test('removes all roles and clears admin metadata, preserving the user', async () => {
  const roleRows = [
    { id: callerId, assigned_email: 'root@example.com', auth_user_id: callerId, is_super_admin: true },
    { id: targetId, assigned_email: 'target@example.com', auth_user_id: targetId, is_super_admin: false },
    { id: secondTargetId, assigned_email: 'target@example.com', auth_user_id: targetId, is_super_admin: false }
  ];
  let updatedUser = null;
  let deletedIds = null;
  service = {
    auth: {
      getUser: async () => ({ data: { user: { id: callerId, email: 'root@example.com', app_metadata: {} } } }),
      admin: {
        getUserById: async () => ({ data: { user: {
          id: targetId,
          email: 'target@example.com',
          user_metadata: { full_name: 'Target', role: 'Admin', is_super_admin: true },
          app_metadata: { provider: 'email', role: 'admin' }
        } } }),
        updateUserById: async (id, metadata) => {
          updatedUser = { id, metadata };
          return { error: null };
        }
      }
    },
    from: () => ({
      select: async () => ({ data: roleRows, error: null }),
      delete: () => ({
        in: (column, ids) => {
          deletedIds = ids;
          return { select: async () => ({ data: ids.map(id => ({ id })), error: null }) };
        }
      })
    })
  };
  const res = response();
  await removeAdminRole(request(), res);
  assert.equal(res.code, 200);
  assert.deepEqual(new Set(deletedIds), new Set([targetId, secondTargetId]));
  assert.equal(updatedUser.id, targetId);
  assert.equal(updatedUser.metadata.user_metadata.full_name, 'Target');
  assert.equal(updatedUser.metadata.user_metadata.is_super_admin, false);
  assert.equal(updatedUser.metadata.app_metadata.role, 'authenticated');
});
