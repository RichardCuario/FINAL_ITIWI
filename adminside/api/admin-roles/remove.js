const { initServiceSupabase } = require('../_lib/init');

module.exports = async (req, res) => {
  if (req.method !== 'POST') {
    res.status(405).json({ error: 'Method not allowed' });
    return;
  }

  const token = String(req.headers.authorization || '').replace(/^Bearer\s+/i, '');
  const roleId = String(req.body?.roleId || '');
  if (!token || !/^[0-9a-f]{8}-[0-9a-f-]{27,}$/i.test(roleId)) {
    res.status(400).json({ error: 'A valid admin session and role are required.' });
    return;
  }

  try {
    const supabase = initServiceSupabase();
    const { data: callerData, error: authError } = await supabase.auth.getUser(token);
    const caller = callerData?.user;
    if (authError || !caller?.email) {
      res.status(401).json({ error: 'Your admin session has expired.' });
      return;
    }

    const { data: roles, error: rolesError } = await supabase
      .from('admin_roles')
      .select('id, assigned_email, auth_user_id, is_super_admin');
    if (rolesError) throw rolesError;

    const callerEmail = caller.email.toLowerCase();
    const isSuperAdmin = roles.some(role => role.is_super_admin && (
      role.auth_user_id === caller.id || role.assigned_email?.toLowerCase() === callerEmail
    )) || caller.app_metadata?.is_super_admin === true;
    if (!isSuperAdmin) {
      res.status(403).json({ error: 'Only the Admin can remove staff access.' });
      return;
    }

    const selectedRole = roles.find(role => role.id === roleId);
    if (!selectedRole) {
      res.status(404).json({ error: 'The admin role no longer exists.' });
      return;
    }

    const targetEmail = selectedRole.assigned_email?.toLowerCase();
    if (!targetEmail || targetEmail === callerEmail || selectedRole.auth_user_id === caller.id) {
      res.status(400).json({ error: 'You cannot remove your own admin access.' });
      return;
    }

    // Removing an admin removes every feature role assigned to that account.
    const targetRoles = roles.filter(role =>
      role.assigned_email?.toLowerCase() === targetEmail ||
      (selectedRole.auth_user_id && role.auth_user_id === selectedRole.auth_user_id)
    );

    let targetUser = null;
    const authUserId = selectedRole.auth_user_id || targetRoles.find(role => role.auth_user_id)?.auth_user_id;
    if (authUserId) {
      const { data, error } = await supabase.auth.admin.getUserById(authUserId);
      if (error && error.status !== 404) throw error;
      targetUser = data?.user || null;
    }
    if (!targetUser && !targetEmail.endsWith('@unassigned.local')) {
      // Older role rows were created before auth_user_id was saved.
      for (let page = 1; page <= 100; page++) {
        const { data, error } = await supabase.auth.admin.listUsers({ page, perPage: 1000 });
        if (error) throw error;
        targetUser = data.users.find(user => user.email?.toLowerCase() === targetEmail) || null;
        if (targetUser || data.users.length < 1000) break;
      }
    }

    if (targetUser) {
      const userMetadata = { ...targetUser.user_metadata };
      const appMetadata = { ...targetUser.app_metadata };
      if (/admin|super/i.test(String(userMetadata.role || ''))) userMetadata.role = 'User';
      userMetadata.role_name = null;
      userMetadata.admin_access = null;
      userMetadata.permissions = [];
      userMetadata.report_categories = [];
      userMetadata.transparency_categories = [];
      userMetadata.is_super_admin = false;
      userMetadata.isAdmin = false;
      userMetadata.created_via_admin_console = false;
      if (/admin/i.test(String(appMetadata.role || ''))) appMetadata.role = 'authenticated';
      appMetadata.is_super_admin = false;
      appMetadata.isAdmin = false;
      const { error } = await supabase.auth.admin.updateUserById(targetUser.id, {
        user_metadata: userMetadata,
        app_metadata: appMetadata
      });
      if (error) throw error;
    }

    const ids = targetRoles.map(role => role.id);
    const { data: removed, error: deleteError } = await supabase
      .from('admin_roles')
      .delete()
      .in('id', ids)
      .select('id');
    if (deleteError) throw deleteError;
    if ((removed || []).length !== ids.length) throw new Error('Not all admin roles were removed.');

    res.status(200).json({ removedIds: ids, email: targetEmail });
  } catch (error) {
    console.error('Remove admin access failed:', error);
    res.status(500).json({ error: 'Could not remove admin access. Please try again.' });
  }
};
