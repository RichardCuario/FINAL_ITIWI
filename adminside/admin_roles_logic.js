const ADMIN_FEATURES = [
  { label: 'Manage Barangay', value: 'barangay' },
  { label: 'Manage News', value: 'news' },
  { label: 'Reports', value: 'reports' },
  { label: 'Transparency', value: 'transparency' },
  { label: 'Tourist Guide', value: 'tourist' },
  { label: 'Online Services', value: 'services' },
  { label: 'Manage Hotline', value: 'hotline' }
];

const DEFAULT_SUPER_ADMIN_SESSION = {
  isSuperAdmin: true,
  permissions: ADMIN_FEATURES.map(item => item.value)
};

function buildPermissionSet(feature) {
  const selected = String(feature || '').trim();
  if (!selected) return [];
  return ADMIN_FEATURES.some(item => item.value === selected) ? [selected] : [];
}

function canAccessFeature(feature, session) {
  const selected = String(feature || '').trim();
  const permissions = Array.isArray(session?.permissions) ? session.permissions : [];
  if (session?.isSuperAdmin) return true;
  if (!selected) return false;
  return permissions.includes(selected);
}

function createRoleRecord(roleName, feature) {
  return {
    id: `role_${Date.now()}_${Math.random().toString(36).slice(2, 9)}`,
    roleName: String(roleName || '').trim(),
    feature: String(feature || '').trim(),
    permissions: buildPermissionSet(feature),
    createdAt: new Date().toISOString()
  };
}

function buildAdminAccountCreationPayload({ email, password, roleName, feature, isSuperAdmin }) {
  const cleanEmail = String(email || '').trim();
  const cleanPassword = String(password || '');
  const cleanRoleName = String(roleName || '').trim();
  const cleanFeature = String(feature || '').trim();
  const isAdminSuper = Boolean(isSuperAdmin);

  const permissions = isAdminSuper ? ADMIN_FEATURES.map(item => item.value) : buildPermissionSet(cleanFeature);

  return {
    email: cleanEmail,
    password: cleanPassword,
    options: {
      data: {
        role: cleanRoleName || 'Admin',
        role_name: cleanRoleName || 'Admin',
        admin_access: isAdminSuper ? 'all' : cleanFeature,
        permissions,
        is_super_admin: isAdminSuper,
        created_via_admin_console: true
      }
    }
  };
}

if (typeof module !== 'undefined') {
  module.exports = {
    ADMIN_FEATURES,
    DEFAULT_SUPER_ADMIN_SESSION,
    buildPermissionSet,
    canAccessFeature,
    createRoleRecord,
    buildAdminAccountCreationPayload
  };
}
