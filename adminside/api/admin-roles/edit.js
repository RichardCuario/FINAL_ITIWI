const { initServiceSupabase } = require('../_lib/init');
const { ADMIN_FEATURES, REPORT_CATEGORIES, TRANSPARENCY_CATEGORIES } = require('../../admin_roles_logic');

const VALID_FEATURES = new Set(ADMIN_FEATURES.map(feature => feature.value));
const VALID_CATEGORIES = new Set(REPORT_CATEGORIES);
const ROLE_COLUMNS = 'id, role_name, feature, permissions, report_categories, transparency_categories, is_super_admin, assigned_email, auth_user_id, created_at';

module.exports = async (req, res) => {
  if (req.method !== 'POST') return res.status(405).json({ error: 'Method not allowed' });

  const token = String(req.headers.authorization || '').replace(/^Bearer\s+/i, '');
  const roleId = String(req.body?.roleId || '');
  const roleName = String(req.body?.roleName || '').trim();
  const features = req.body?.features;
  const categories = req.body?.reportCategories;
  const transparencyCategories = req.body?.transparencyCategories ?? [];
  if (!Array.isArray(transparencyCategories) || transparencyCategories.some(value => !TRANSPARENCY_CATEGORIES.some(category => category.value === value))) {
    return res.status(400).json({ error: 'Select valid transparency categories.' });
  }
  if (!token || !/^[0-9a-f]{8}-[0-9a-f-]{27,}$/i.test(roleId)) {
    return res.status(400).json({ error: 'A valid admin session and role are required.' });
  }
  if (!roleName || roleName.length > 120 || !Array.isArray(features) ||
      !Array.isArray(categories) || features.some(value => !VALID_FEATURES.has(value)) ||
      categories.some(value => !VALID_CATEGORIES.has(value))) {
    return res.status(400).json({ error: 'Enter a valid role name and permissions.' });
  }

  try {
    const supabase = initServiceSupabase();
    const { data: callerData, error: authError } = await supabase.auth.getUser(token);
    const caller = callerData?.user;
    if (authError || !caller?.email) return res.status(401).json({ error: 'Your admin session has expired.' });

    const { data: roles, error: rolesError } = await supabase.from('admin_roles').select(ROLE_COLUMNS);
    if (rolesError) throw rolesError;
    const callerEmail = caller.email.toLowerCase();
    const isSuperAdmin = (roles || []).some(role => role.is_super_admin && (
      role.auth_user_id === caller.id || role.assigned_email?.toLowerCase() === callerEmail
    )) || caller.app_metadata?.is_super_admin === true;
    if (!isSuperAdmin) return res.status(403).json({ error: 'Only the Admin can edit staff access.' });

    const selectedRole = roles.find(role => role.id === roleId);
    if (!selectedRole) return res.status(404).json({ error: 'The admin role no longer exists.' });
    const targetEmail = selectedRole.assigned_email?.toLowerCase();
    const targetRoles = roles.filter(role => role.assigned_email?.toLowerCase() === targetEmail);
    const targetIsSuperAdmin = targetRoles.some(role => role.is_super_admin);
    const desiredFeatures = [...new Set(features)];
    const desiredCategories = [...new Set(categories)];
    if (!targetIsSuperAdmin && (!desiredFeatures.length ||
      (desiredFeatures.includes('reports') && !desiredCategories.length))) {
      return res.status(400).json({ error: 'Select a feature and any required report categories.' });
    }

    if (!targetIsSuperAdmin && desiredFeatures.includes('transparency') && !transparencyCategories.length) {
      return res.status(400).json({ error: 'Select at least one transparency category.' });
    }

    // The full-access Admin permission stays intact; its display name may still be edited.
    if (targetIsSuperAdmin) {
      for (const role of targetRoles) {
        const { error } = await supabase.from('admin_roles').update({ role_name: roleName }).eq('id', role.id);
        if (error) throw error;
      }
    } else {
      const existingByFeature = new Map(targetRoles.map(role => [role.feature, role]));
      const userId = targetRoles.find(role => role.auth_user_id)?.auth_user_id || null;
      for (const feature of desiredFeatures) {
        const values = {
          role_name: roleName,
          permissions: [feature],
          report_categories: feature === 'reports' ? desiredCategories : [],
          transparency_categories: feature === 'transparency' ? [...new Set(transparencyCategories)] : []
        };
        const existing = existingByFeature.get(feature);
        const query = existing
          ? supabase.from('admin_roles').update(values).eq('id', existing.id)
          : supabase.from('admin_roles').insert({
            ...values, feature, assigned_email: selectedRole.assigned_email,
            auth_user_id: userId, is_super_admin: false
          });
        const { error } = await query;
        if (error) throw error;
      }
      const removedIds = targetRoles.filter(role => !desiredFeatures.includes(role.feature)).map(role => role.id);
      if (removedIds.length) {
        const { error } = await supabase.from('admin_roles').delete().in('id', removedIds);
        if (error) throw error;
      }
    }

    const authUserId = targetRoles.find(role => role.auth_user_id)?.auth_user_id;
    let targetUser = null;
    if (authUserId) {
      const { data, error } = await supabase.auth.admin.getUserById(authUserId);
      if (error) throw error;
      targetUser = data?.user || null;
    } else if (targetEmail && !targetEmail.endsWith('@unassigned.local')) {
      for (let page = 1; page <= 100; page++) {
        const { data, error } = await supabase.auth.admin.listUsers({ page, perPage: 1000 });
        if (error) throw error;
        targetUser = data.users.find(user => user.email?.toLowerCase() === targetEmail) || null;
        if (targetUser || data.users.length < 1000) break;
      }
    }
    if (targetUser) {
      const permissions = targetIsSuperAdmin ? [...VALID_FEATURES] : desiredFeatures;
      const reportCategories = targetIsSuperAdmin ? REPORT_CATEGORIES
        : desiredFeatures.includes('reports') ? desiredCategories : [];
      const { error } = await supabase.auth.admin.updateUserById(targetUser.id || authUserId, {
        user_metadata: {
          ...targetUser.user_metadata,
          role: 'Admin',
          role_name: roleName,
          admin_access: targetIsSuperAdmin ? 'all' : permissions.join(','),
          permissions,
          report_categories: reportCategories,
          transparency_categories: targetIsSuperAdmin ? TRANSPARENCY_CATEGORIES.map(item => item.value)
            : desiredFeatures.includes('transparency') ? [...new Set(transparencyCategories)] : [],
          is_super_admin: targetIsSuperAdmin
        }
      });
      if (error) throw error;
    }

    return res.status(200).json({ updated: true });
  } catch (error) {
    console.error('Edit admin access failed:', error);
    return res.status(500).json({ error: 'Could not update admin access. Refresh roles and try again.' });
  }
};
