const test = require('node:test');
const assert = require('node:assert/strict');
const { requireSuperAdmin } = require('../api/_lib/require-super-admin');
const user = { id: 'admin-id', email: 'admin@example.com' };
function response() { return { code: 200, setHeader() {}, status(code) { this.code = code; return this; }, json(body) { this.body = body; return this; } }; }
async function check(caller, roles, token = 'Bearer valid', error = null) {
  const client = { auth: { getUser: async () => ({ data: { user: caller }, error }) },
    from: () => ({ select: async () => ({ data: roles }) }) };
  const res = response();
  const result = await requireSuperAdmin({ headers: { authorization: token } }, res, () => client);
  return { res, result, client };
}
test('missing and invalid sessions are rejected', async () => {
  assert.equal((await check(user, [], '')).res.code, 401);
  assert.equal((await check(user, [], 'Bearer invalid', new Error('expired'))).res.code, 401);
});
test('regular admins, citizens and forged editable metadata cannot read users', async () => {
  assert.equal((await check({ ...user, user_metadata: { is_super_admin: true } }, [])).res.code, 403);
  assert.equal((await check(user, [])).res.code, 403);
  assert.equal((await check(user, [{ auth_user_id: user.id, is_super_admin: false }])).res.code, 403);
});
test('assigned superadmins and trusted app metadata are allowed', async () => {
  for (const [caller, roles] of [[user, [{ auth_user_id: user.id, is_super_admin: true }]],
    [{ ...user, app_metadata: { is_super_admin: true } }, []],
    [user, [{ assigned_email: 'ADMIN@example.com', is_super_admin: true }]]]) {
    const result = await check(caller, roles);
    assert.equal(result.result, result.client);
  }
});
test('email cannot override a role bound to another account', async () => {
  assert.equal((await check(user, [{ auth_user_id: 'other', assigned_email: user.email, is_super_admin: true }])).res.code, 403);
});

test('only superadmins see Users while assigned features stay available to admins', () => {
  const fs = require('node:fs');
  const vm = require('node:vm');
  const source = fs.readFileSync(require('node:path').join(__dirname, '../app.js'), 'utf8');
  const pick = (start, end) => source.slice(source.indexOf(start), source.indexOf(end));
  const context = vm.createContext({ adminAuthReady: true, verifiedAdminSession: { isSuperAdmin: false, permissions: ['tourist'] },
    FEATURE_TO_PAGE_MAP: { tourist: 'tourist' }, ALL_ADMIN_PAGES: ['users', 'manage-admin', 'tourist'] });
  vm.runInContext(pick('function canAccessUserDirectory()', 'function getReportCategoriesForSession(') +
    pick('function getAllowedPagesForSession(', 'function applyAdminNavigationPermissions('), context);
  assert.equal(context.canAccessPage('users'), false);
  assert.equal(context.getAllowedPagesForSession(context.verifiedAdminSession).has('users'), false);
  assert.equal(context.canAccessPage('manage-admin'), false);
  assert.equal(context.canAccessPage('tourist'), true);
  context.verifiedAdminSession = null;
  assert.equal(context.canAccessPage('users'), false);
  context.verifiedAdminSession = { isSuperAdmin: true, permissions: [] };
  assert.equal(context.canAccessPage('users'), true);
  assert.equal(context.getAllowedPagesForSession(context.verifiedAdminSession).has('users'), true);
  assert.equal(context.canAccessPage('manage-admin'), true);
});

test('the full-access account displays Admin without losing its permissions', () => {
  const fs = require('node:fs');
  const vm = require('node:vm');
  const source = fs.readFileSync(require('node:path').join(__dirname, '../app.js'), 'utf8');
  const context = vm.createContext({
    getAdminRoles: () => [{ authUserId: user.id, isSuperAdmin: true, roleName: 'Super Admin' }],
    ADMIN_FEATURES: [{ value: 'tourist' }], REPORT_CATEGORIES: ['Other'],
    TRANSPARENCY_CATEGORIES: [{ value: 'annual_budget' }]
  });
  vm.runInContext(source.slice(source.indexOf('function resolveAdminSession('),
    source.indexOf('function getAllowedPagesForSession(')), context);
  const session = context.resolveAdminSession(user);
  assert.equal(session.roleName, 'Admin');
  assert.equal(session.isSuperAdmin, true);
  assert.deepEqual(Array.from(session.permissions), ['tourist']);
});
