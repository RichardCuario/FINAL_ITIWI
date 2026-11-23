const test = require('node:test');
const assert = require('node:assert/strict');
const { buildAdminAccountCreationPayload } = require('../admin_roles_logic.js');

test('new admin sign-up carries every selected feature and report category', () => {
  const payload = buildAdminAccountCreationPayload({
    email: 'admin@example.com',
    password: 'secure-password',
    roleName: 'Multi-feature Admin',
    features: ['news', 'reports', 'news'],
    reportCategories: ['Infrastructure and roads'],
    isSuperAdmin: false
  });

  assert.deepEqual(payload.options.data.permissions, ['news', 'reports']);
  assert.equal(payload.options.data.admin_access, 'news,reports');
  assert.deepEqual(payload.options.data.report_categories, ['Infrastructure and roads']);
});
