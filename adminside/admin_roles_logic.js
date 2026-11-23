const ADMIN_FEATURES = [
  { label: 'Manage About Us', value: 'about-us' },
  { label: 'Manage Barangay', value: 'barangay' },
  { label: 'Manage News', value: 'news' },
  { label: 'Reports', value: 'reports' },
  { label: 'Transparency', value: 'transparency' },
  { label: 'Tourist Guide', value: 'tourist' },
  { label: 'Online Services', value: 'services' },
  { label: 'Manage Hotline', value: 'hotline' }
];

// Keep these values aligned with the categories used by the citizen app.
const REPORT_CATEGORIES = [
  'Infrastructure and roads',
  'Public safety',
  'Sanitation and waste',
  'Environment',
  'Health and social services',
  'Utilities',
  'Other'
];

const TRANSPARENCY_CATEGORIES = [
  { value: 'annual_budget', label: 'Annual Budget' },
  { value: 'bids_projects', label: 'Bids & Projects' },
  { value: 'executive_orders', label: 'Executive Orders' },
  { value: 'financial_reports', label: 'Financial Reports' },
  { value: 'legislative_ordinances', label: 'Legislative Ordinances' },
  { value: 'programs_projects', label: 'Programs & Projects' }
];

function normalizeTransparencyCategories(categories) {
  return [...new Set(Array.isArray(categories) ? categories : [])]
    .filter(value => TRANSPARENCY_CATEGORIES.some(category => category.value === value));
}

const DEFAULT_SUPER_ADMIN_SESSION = {
  isSuperAdmin: true,
  permissions: ADMIN_FEATURES.map(item => item.value),
  reportCategories: REPORT_CATEGORIES,
  transparencyCategories: TRANSPARENCY_CATEGORIES.map(item => item.value)
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

function normalizeReportCategories(categories) {
  const selected = Array.isArray(categories) ? categories : [];
  return [...new Set(selected.map(value => String(value || '').trim()))]
    .filter(value => REPORT_CATEGORIES.includes(value));
}

function createRoleRecord(roleName, feature, reportCategories = []) {
  return {
    id: `role_${Date.now()}_${Math.random().toString(36).slice(2, 9)}`,
    roleName: String(roleName || '').trim(),
    feature: String(feature || '').trim(),
    permissions: buildPermissionSet(feature),
    reportCategories: normalizeReportCategories(reportCategories),
    createdAt: new Date().toISOString()
  };
}

function buildAdminAccountCreationPayload({
  email,
  password,
  roleName,
  feature,
  features,
  reportCategories = [],
  transparencyCategories = []
}) {
  const cleanEmail = String(email || '').trim();
  const cleanPassword = String(password || '');
  const cleanRoleName = String(roleName || '').trim();
  const cleanFeature = String(feature || '').trim();
  const cleanFeatures = [...new Set(Array.isArray(features) ? features : [cleanFeature])]
    .filter(value => ADMIN_FEATURES.some(item => item.value === value));
  const cleanReportCategories = normalizeReportCategories(reportCategories);
  const permissions = cleanFeatures;

  return {
    email: cleanEmail,
    password: cleanPassword,
    options: {
      data: {
        role: cleanRoleName || 'Admin',
        role_name: cleanRoleName || 'Admin',
        admin_access: permissions.join(','),
        permissions,
        report_categories: cleanReportCategories,
        transparency_categories: cleanFeatures.includes('transparency') ? normalizeTransparencyCategories(transparencyCategories) : [],
        is_super_admin: false,
        created_via_admin_console: true
      }
    }
  };
}

if (typeof module !== 'undefined') {
  module.exports = {
    ADMIN_FEATURES,
    REPORT_CATEGORIES,
    TRANSPARENCY_CATEGORIES,
    normalizeTransparencyCategories,
    DEFAULT_SUPER_ADMIN_SESSION,
    buildPermissionSet,
    canAccessFeature,
    normalizeReportCategories,
    createRoleRecord,
    buildAdminAccountCreationPayload
  };
}
