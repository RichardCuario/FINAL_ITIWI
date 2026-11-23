// Authorization must never trust editable user_metadata.
async function requireUserAdmin(req, res, createClient) {
  res.setHeader('Cache-Control', 'no-store');
  const match = /^Bearer\s+(\S+)$/i.exec(req.headers.authorization || '');
  if (!match) {
    res.status(401).json({ success: false, error: 'Authentication required.' });
    return null;
  }
  const client = createClient(match[1]);
  const { data, error } = await client.auth.getUser(match[1]);
  const user = data?.user;
  if (error || !user?.id) {
    res.status(401).json({ success: false, error: 'Invalid or expired session.' });
    return null;
  }
  const { data: roles, error: rolesError } = await client.from('admin_roles')
    .select('auth_user_id, assigned_email, is_super_admin');
  if (rolesError) throw rolesError;
  const allowed = user.app_metadata?.is_super_admin === true || (roles || []).some(role =>
    (role.auth_user_id
      ? role.auth_user_id === user.id
      : Boolean(user.email) && role.assigned_email?.toLowerCase() === user.email.toLowerCase()));
  if (!allowed) {
    res.status(403).json({ success: false, error: 'Only authorized staff can access citizens.' });
    return null;
  }
  return client;
}
module.exports = { requireUserAdmin };
