const test = require('node:test');
const assert = require('node:assert/strict');

const {
  ADMIN_FEATURES,
  DEFAULT_SUPER_ADMIN_SESSION,
  buildPermissionSet,
  canAccessFeature,
  createRoleRecord,
  buildAdminAccountCreationPayload,
} = require('../adminside/admin_roles_logic.js');

test('Admin feature map includes all target modules', () => {
  assert.deepEqual(ADMIN_FEATURES.map(item => item.value).sort(), [
    'barangay',
    'news',
    'reports',
    'services',
    'tourist',
    'transparency'
  ]);
});

test('Single-feature role grants access only to its module', () => {
  const rolePermissions = buildPermissionSet('news');

  assert.deepEqual(rolePermissions, ['news']);
  assert.equal(canAccessFeature('news', { isSuperAdmin: false, permissions: rolePermissions }), true);
  assert.equal(canAccessFeature('reports', { isSuperAdmin: false, permissions: rolePermissions }), false);
  assert.equal(canAccessFeature('barangay', { isSuperAdmin: false, permissions: rolePermissions }), false);
});

test('Super admin session keeps all features unlocked', () => {
  assert.deepEqual(DEFAULT_SUPER_ADMIN_SESSION.permissions.sort(), ADMIN_FEATURES.map(item => item.value).sort());
  assert.equal(canAccessFeature('news', DEFAULT_SUPER_ADMIN_SESSION), true);
  assert.equal(canAccessFeature('services', DEFAULT_SUPER_ADMIN_SESSION), true);
  assert.equal(canAccessFeature('tourist', DEFAULT_SUPER_ADMIN_SESSION), true);
});

test('Role records are normalized to one feature permission', () => {
  const role = createRoleRecord('News Manager', 'news');

  assert.equal(role.roleName, 'News Manager');
  assert.deepEqual(role.permissions, ['news']);
  assert.equal(role.feature, 'news');
  assert.ok(role.id);
  assert.ok(role.createdAt);
});

test('Admin account payload includes credentials and metadata for the assigned role', () => {
  const payload = buildAdminAccountCreationPayload({
    email: 'news.manager@tiwi.gov.ph',
    password: 'Tiwi@2026Sec!ure',
    roleName: 'News Manager',
    feature: 'news',
    isSuperAdmin: false
  });

  assert.equal(payload.email, 'news.manager@tiwi.gov.ph');
  assert.equal(payload.password, 'Tiwi@2026Sec!ure');
  assert.equal(payload.options.data.role_name, 'News Manager');
  assert.equal(payload.options.data.role, 'News Manager');
  assert.equal(payload.options.data.admin_access, 'news');
  assert.equal(payload.options.data.is_super_admin, false);
});
