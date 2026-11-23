// ============================================================
// iTIWI Admin Dashboard - Main Application Script
// ============================================================

// ---------- DARK MODE MANAGEMENT ----------
function initDarkMode() {
  const savedTheme = localStorage.getItem('theme') || 'light';
  setTheme(savedTheme);

  const themeToggleBtn = document.getElementById('themeToggleBtn');
  if (themeToggleBtn) {
    themeToggleBtn.addEventListener('click', toggleTheme);
  }
}

function setTheme(theme) {
  if (theme === 'dark') {
    document.documentElement.setAttribute('data-theme', 'dark');
    document.body.style.backgroundImage = 'none';
    document.body.style.backgroundColor = '#0f1419';
    const themeToggleBtn = document.getElementById('themeToggleBtn');
    if (themeToggleBtn) {
      themeToggleBtn.innerHTML = '<i class="fa-solid fa-sun"></i>';
    }
  } else {
    document.documentElement.removeAttribute('data-theme');
    const themeToggleBtn = document.getElementById('themeToggleBtn');
    if (themeToggleBtn) {
      themeToggleBtn.innerHTML = '<i class="fa-solid fa-moon"></i>';
    }
  }
  localStorage.setItem('theme', theme);
}

function toggleTheme() {
  const currentTheme = localStorage.getItem('theme') || 'light';
  const newTheme = currentTheme === 'light' ? 'dark' : 'light';
  setTheme(newTheme);
}

// ---------- SUPABASE CLIENT ----------
const SUPABASE_URL = 'https://jbhlbukxankrtcwhqoll.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpiaGxidWt4YW5rcnRjd2hxb2xsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ0NzAxODgsImV4cCI6MjA5MDA0NjE4OH0.DebtVdw7bF5nRaXQg8Ta2SsO2Qv42QnGSzoS8hT2vJc';

let supabaseClient = null;
let adminAuthReady = false;
let adminAuthCheckRunning = false;
let verifiedAdminSession = null;

function initSupabase() {
  if (typeof window.supabase !== 'undefined' && typeof window.supabase.createClient === 'function') {
    supabaseClient = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
    console.log('Supabase client initialized');
    checkAuthentication();
    window.addEventListener('focus', checkAuthentication);
    setInterval(() => {
      if (!document.hidden) checkAuthentication();
    }, 60000);
  } else {
    console.warn('Supabase JS library not loaded');
  }
}

async function checkAuthentication() {
  if (!supabaseClient || adminAuthCheckRunning) return;
  adminAuthCheckRunning = true;

  try {
    const { data, error } = await supabaseClient.auth.getUser();
    if (error || !data?.user || !(await updateUserProfile(data.user))) {
      adminAuthReady = false;
      verifiedAdminSession = null;
      localStorage.removeItem(ADMIN_SESSION_STORAGE_KEY);
      await supabaseClient.auth.signOut();
      window.location.href = '/login';
      return;
    }
    if (!document.querySelector('.page.active')) {
      navigateTo(localStorage.getItem('lastVisitedPage') || 'dashboard');
    }
  } catch (error) {
    console.error('Auth check error:', error);
    adminAuthReady = false;
    verifiedAdminSession = null;
    localStorage.removeItem(ADMIN_SESSION_STORAGE_KEY);
    window.location.href = '/login';
  } finally {
    adminAuthCheckRunning = false;
  }
}

async function updateUserProfile(user) {
  await loadAdminRolesFromDatabase(user);
  const accessSession = resolveAdminSession(user);
  if (!accessSession) return false;
  verifiedAdminSession = accessSession;
  adminAuthReady = true;
  localStorage.setItem(ADMIN_SESSION_STORAGE_KEY, JSON.stringify(accessSession));
  applyAdminNavigationPermissions(user);

  const userNameElement = document.querySelector('.user-name-sidebar');
  if (userNameElement && user?.email) {
    const name = user.user_metadata?.full_name || user.email.split('@')[0];
    userNameElement.textContent = name;
  }

  // Update sidebar role
  const userRoleElement = document.querySelector('.user-role-sidebar');
  if (userRoleElement) {
    userRoleElement.textContent = accessSession.roleName || 'Administrator';
  }

  // Update sidebar avatar with initials
  const sidebarAvatar = document.querySelector('.user-avatar-sidebar');
  if (sidebarAvatar && user?.email) {
    const fullName = user.user_metadata?.full_name || user.email.split('@')[0];
    const initials = fullName
      .split(' ')
      .map(name => name[0])
      .join('')
      .toUpperCase()
      .slice(0, 2);

    // Clear the icon and add initials
    sidebarAvatar.innerHTML = '';
    sidebarAvatar.textContent = initials;
    sidebarAvatar.title = fullName;
  }

  // Update header user profile
  const headerUserName = document.querySelector('.header-user-name');
  const headerUserRole = document.querySelector('.header-user-role');
  const headerAvatar = document.querySelector('.header-avatar');

  if (headerUserName && user?.email) {
    const fullName = user.user_metadata?.full_name || user.email.split('@')[0];
    headerUserName.textContent = fullName;
  }

  if (headerUserRole) {
    headerUserRole.textContent = accessSession.roleName || 'Administrator';
  }

  // Update avatar with initials
  if (headerAvatar && user?.email) {
    const fullName = user.user_metadata?.full_name || user.email.split('@')[0];
    const initials = fullName
      .split(' ')
      .map(name => name[0])
      .join('')
      .toUpperCase()
      .slice(0, 2);

    headerAvatar.textContent = initials;
    headerAvatar.title = fullName;
  }
  return true;
}

async function handleLogout() {
  if (!supabaseClient) return;

  try {
    await supabaseClient.auth.signOut();
    localStorage.removeItem('rememberEmail');
    window.location.href = '/login';
  } catch (error) {
    console.error('Logout error:', error);
    alert('Error logging out. Please try again.');
  }
}

// ============================================================
// PROFILE MANAGEMENT
// ============================================================
async function openProfileModal() {
  const profileModal = document.getElementById('profileModal');
  const { data: { session } } = await supabaseClient.auth.getSession();

  if (session?.user) {
    const user = session.user;
    document.getElementById('profileUserId').value = user.id;
    document.getElementById('profileEmail').value = user.email || '';
    document.getElementById('profileFullName').value = user.user_metadata?.full_name || '';
    document.getElementById('profileRole').value = getCurrentAdminSession().isSuperAdmin
      ? 'Admin' : user.user_metadata?.role || 'Administrator';
    document.getElementById('profilePhone').value = user.user_metadata?.phone || '';
    document.getElementById('profileAddress').value = user.user_metadata?.address || '';
    document.getElementById('profileBio').value = user.user_metadata?.bio || '';

    // Update avatar initials
    const fullName = user.user_metadata?.full_name || user.email.split('@')[0];
    const initials = fullName
      .split(' ')
      .map(name => name[0])
      .join('')
      .toUpperCase()
      .slice(0, 2);
    document.getElementById('profileInitials').textContent = initials;
  }

  profileModal.classList.add('active');
}

function closeProfileModal() {
  const profileModal = document.getElementById('profileModal');
  profileModal.classList.remove('active');
}

async function saveProfile() {
  if (!supabaseClient) return;

  try {
    const { data: { session } } = await supabaseClient.auth.getSession();
    if (!session?.user) return;

    const fullName = document.getElementById('profileFullName').value;
    const phone = document.getElementById('profilePhone').value;
    const address = document.getElementById('profileAddress').value;
    const bio = document.getElementById('profileBio').value;

    if (!fullName) {
      showToast('Full name is required', 'error');
      return;
    }

    // Update user metadata
    const { error: updateError } = await supabaseClient.auth.updateUser({
      data: {
        full_name: fullName,
        phone: phone,
        address: address,
        bio: bio,
        role: getCurrentAdminSession().isSuperAdmin ? 'Admin'
          : session.user.user_metadata?.role || 'Administrator'
      }
    });

    if (updateError) {
      showToast('Error updating profile: ' + updateError.message, 'error');
      return;
    }

    // Update UI
    updateUserProfile(session.user);
    showToast('Profile updated successfully!', 'success');
    closeProfileModal();
  } catch (error) {
    console.error('Profile update error:', error);
    showToast('Error updating profile', 'error');
  }
}

async function changePassword() {
  if (!supabaseClient) return;

  try {
    const currentPassword = document.getElementById('currentPassword').value;
    const newPassword = document.getElementById('newPassword').value;
    const confirmPassword = document.getElementById('confirmPassword').value;

    // Validation
    if (!currentPassword || !newPassword || !confirmPassword) {
      showToast('All password fields are required', 'error');
      return;
    }

    if (newPassword.length < 8) {
      showToast('New password must be at least 8 characters long', 'error');
      return;
    }

    if (newPassword !== confirmPassword) {
      showToast('Passwords do not match', 'error');
      return;
    }

    if (currentPassword === newPassword) {
      showToast('New password must be different from current password', 'error');
      return;
    }

    // Require the existing password before changing it. An active Supabase
    // session alone is not proof that the person at the keyboard knows it.
    const { data: sessionData, error: sessionError } = await supabaseClient.auth.getSession();
    const email = sessionData?.session?.user?.email;
    if (sessionError || !email) {
      showToast('Your session has expired. Please sign in again.', 'error');
      return;
    }

    const { error: reauthError } = await supabaseClient.auth.signInWithPassword({
      email,
      password: currentPassword
    });

    if (reauthError) {
      showToast('Current password is incorrect.', 'error');
      return;
    }

    // Update the password only after successful re-authentication.
    const { error: updateError } = await supabaseClient.auth.updateUser({
      password: newPassword
    });

    if (updateError) {
      showToast('Error changing password: ' + updateError.message, 'error');
      return;
    }

    // Clear password fields
    document.getElementById('currentPassword').value = '';
    document.getElementById('newPassword').value = '';
    document.getElementById('confirmPassword').value = '';

    showToast('Password changed successfully!', 'success');
  } catch (error) {
    console.error('Password change error:', error);
    showToast('Error changing password', 'error');
  }
}



// ============================================================
// NOTIFICATIONS
// ============================================================
function setupNotifications() {
  const notificationBtn = document.getElementById('notificationBtn');
  const notificationPanel = document.getElementById('notificationPanel');
  const clearNotificationsBtn = document.getElementById('clearNotificationsBtn');

  // Initialize badge on page load
  updateNotificationUI();

  // Toggle notification panel
  notificationBtn.addEventListener('click', (e) => {
    e.stopPropagation();
    const isOpening = !notificationPanel.classList.contains('active');

    notificationPanel.classList.toggle('active');

    // Mark all notifications as read when opening the panel
    if (isOpening && notifications.length > 0) {
      notifications.forEach(n => n.read = true);
      updateNotificationUI();
    }
  });

  // Close panel when clicking outside
  document.addEventListener('click', (e) => {
    if (!notificationBtn.contains(e.target) && !notificationPanel.contains(e.target)) {
      notificationPanel.classList.remove('active');
    }
  });

  // Clear all notifications
  clearNotificationsBtn.addEventListener('click', () => {
    notifications = [];
    updateNotificationUI();
  });
}

function setupLogoutButton() {
  const logoutBtn = document.getElementById('logoutBtn');
  if (logoutBtn) {
    logoutBtn.addEventListener('click', async (e) => {
      e.preventDefault();
      openLogoutModal();
    });
  }
}

function openLogoutModal() {
  const modal = document.getElementById('logoutModal');
  if (modal) {
    modal.classList.add('active');
  }
}

function closeLogoutModal() {
  const modal = document.getElementById('logoutModal');
  if (modal) {
    modal.classList.remove('active');
  }
}

async function confirmLogout() {
  closeLogoutModal();
  await handleLogout();
}

function setupRealtimeListeners() {
  if (!supabaseClient) return;

  // Service tables to listen to
  const serviceTables = [
    'birth_certificate_appointments',
    'cenodeath_appointments',
    'cenomar_appointments',
    'death_certificate_appointments',
    'marriage_certificate_appointments',
    'facility_borrow_requests'
  ];

  // Listen to each service table
  serviceTables.forEach(table => {
    supabaseClient
      .channel(`public:${table}`)
      .on(
        'postgres_changes',
        {
          event: 'INSERT',
          schema: 'public',
          table: table
        },
        (payload) => {
          const data = payload.new;
          const serviceName = data.name || data.appointment_type || 'Service Request';
          const requesterName = data.requested_by || data.applicant_name || 'User';
          addNotification(
            'New Service Request',
            `${requesterName} requested ${serviceName}`,
            'warning'
          );
          // Reload services if on services page
          if (document.querySelector('.services-page.active')) {
            loadServices();
          }
        }
      )
      .subscribe();
  });

  // Listen to reports table
  supabaseClient
    .channel('public:reports')
    .on(
      'postgres_changes',
      {
        event: 'INSERT',
        schema: 'public',
        table: 'reports'
      },
      (payload) => {
        const data = payload.new;
        if (!canAccessReport(data)) return;
        const reporterName = data.reporter_name || 'User';
        const message = data.message || 'No message';
        addNotification(
          'New Report Submitted',
          `${reporterName} submitted a report: "${message.substring(0, 50)}${message.length > 50 ? '...' : ''}"`,
          'danger'
        );
        // Reload reports if on reports page
        if (document.querySelector('.reports-page.active')) {
          loadReports();
        }
      }
    )
    .subscribe();
}

function addNotification(title, message, type = 'info') {
  const notification = {
    id: Date.now(),
    title,
    message,
    type,
    timestamp: new Date(),
    read: false
  };

  notifications.unshift(notification);

  // Keep only last 50 notifications
  if (notifications.length > 50) {
    notifications = notifications.slice(0, 50);
  }

  updateNotificationUI();

  // Auto-remove notification after 5 seconds if it's a simple info
  if (type === 'info') {
    setTimeout(() => {
      notifications = notifications.filter(n => n.id !== notification.id);
      updateNotificationUI();
    }, 5000);
  }
}

function removeNotification(id) {
  notifications = notifications.filter(n => n.id !== id);
  updateNotificationUI();
}

function updateNotificationUI() {
  const notificationList = document.getElementById('notificationList');
  const notificationBadge = document.getElementById('notificationBadge');
  const unreadCount = notifications.filter(n => !n.read).length;

  // Update badge
  notificationBadge.textContent = unreadCount;
  notificationBadge.style.display = unreadCount > 0 ? 'flex' : 'none';

  // Update list
  if (notifications.length === 0) {
    notificationList.innerHTML = '<p class="notification-empty">No notifications yet</p>';
    return;
  }

  notificationList.innerHTML = notifications.map(n => `
    <div class="notification-item">
      <div class="notification-icon ${n.type}">
        ${getNotificationIcon(n.type)}
      </div>
      <div class="notification-content">
        <p class="notification-title">${escapeHtml(n.title)}</p>
        <p class="notification-message">${escapeHtml(n.message)}</p>
        <p class="notification-time">${formatTime(n.timestamp)}</p>
      </div>
      <button class="notification-close" onclick="removeNotification(${n.id})" title="Dismiss">
        <i class="fa-solid fa-xmark"></i>
      </button>
    </div>
  `).join('');

  // Mark as read
  notifications.forEach(n => n.read = true);
}

function getNotificationIcon(type) {
  const icons = {
    success: '<i class="fa-solid fa-circle-check"></i>',
    info: '<i class="fa-solid fa-circle-info"></i>',
    warning: '<i class="fa-solid fa-triangle-exclamation"></i>',
    error: '<i class="fa-solid fa-circle-xmark"></i>'
  };
  return icons[type] || icons.info;
}

function formatTime(date) {
  const now = new Date();
  const diff = now - date;
  const minutes = Math.floor(diff / 60000);
  const hours = Math.floor(diff / 3600000);
  const days = Math.floor(diff / 86400000);

  if (minutes < 1) return 'Just now';
  if (minutes < 60) return `${minutes}m ago`;
  if (hours < 24) return `${hours}h ago`;
  if (days < 7) return `${days}d ago`;

  return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
}

// ---------- STATE ----------
let currentPage = 'dashboard';
let deleteTarget = null;
let deleteType = null;

const ITEMS_PER_PAGE = 10;
const ADMIN_ROLES_PER_PAGE = 5;
const FEATURE_TO_PAGE_MAP = {
  'about-us': 'about-us',
  barangay: 'barangay',
  news: 'news',
  reports: 'reports',
  transparency: 'transparency',
  tourist: 'tourist',
  services: 'services',
  hotline: 'hotline'
};
const ALL_ADMIN_PAGES = ['dashboard', ...Object.values(FEATURE_TO_PAGE_MAP), 'users', 'manage-admin'];
const ADMIN_SESSION_STORAGE_KEY = 'itiwi_admin_session';
let databaseAdminRoles = null;

function resolvePageId(page) {
  if (!page) return null;
  const directId = `${page}Page`;
  if (document.getElementById(directId)) return directId;
  const camel = page.replace(/-([a-z])/g, (_, ch) => ch.toUpperCase());
  const camelId = `${camel}Page`;
  return document.getElementById(camelId) ? camelId : directId;
}

function getAdminRoles() {
  return databaseAdminRoles ?? [];
}

function mapDatabaseAdminRole(role) {
  return {
    id: role.id,
    roleName: role.role_name,
    feature: role.feature,
    permissions: Array.isArray(role.permissions) ? role.permissions : [],
    reportCategories: normalizeReportCategories(role.report_categories),
    transparencyCategories: normalizeTransparencyCategories(role.transparency_categories),
    isSuperAdmin: Boolean(role.is_super_admin),
    assignedEmail: role.assigned_email,
    authUserId: role.auth_user_id,
    createdAt: role.created_at
  };
}

async function loadAdminRolesFromDatabase(user) {
  if (!supabaseClient || !user?.email) throw new Error('Admin role check unavailable.');

  const { data, error } = await supabaseClient
    .from('admin_roles')
    .select('id, role_name, feature, permissions, report_categories, transparency_categories, is_super_admin, assigned_email, auth_user_id, created_at')
    .order('created_at', { ascending: true });

  if (error) {
    throw error;
  }

  databaseAdminRoles = (data || []).map(mapDatabaseAdminRole);

  if (document.querySelector('.manage-admin-page.active')) {
    renderAdminRoles();
  }
}

async function saveAdminRolesToDatabase(roles) {
  const { data, error } = await supabaseClient
    .from('admin_roles')
    .insert(roles.map(role => ({
      role_name: role.roleName,
      feature: role.feature,
      permissions: role.permissions,
      report_categories: role.reportCategories,
      transparency_categories: role.transparencyCategories || [],
      is_super_admin: false,
      assigned_email: role.assignedEmail,
      auth_user_id: role.authUserId
    })))
    .select('id, role_name, feature, permissions, report_categories, transparency_categories, is_super_admin, assigned_email, auth_user_id, created_at');

  if (error) throw error;
  return (data || []).map(mapDatabaseAdminRole);
}

function canAccessUserDirectory() {
  return adminAuthReady && verifiedAdminSession?.isSuperAdmin === true;
}

function getCurrentAdminSession() {
  return verifiedAdminSession || {
    isSuperAdmin: false,
    permissions: [],
    reportCategories: [],
    roleName: 'Administrator'
  };
}

function getReportCategoriesForSession(session = getCurrentAdminSession()) {
  if (session?.isSuperAdmin) return REPORT_CATEGORIES;
  return normalizeReportCategories(session?.reportCategories);
}

function canAccessReport(report, session = getCurrentAdminSession()) {
  if (session?.isSuperAdmin) return true;
  if (!canAccessFeature('reports', session)) return false;
  const assignedEmail = String(report?.assigned_admin_email || '').toLowerCase();
  if (assignedEmail && assignedEmail === String(session?.email || '').toLowerCase()) {
    return true;
  }
  const category = String(report?.category || 'Other').trim() || 'Other';
  return getReportCategoriesForSession(session).includes(category);
}

function syncReportCategoryFilter() {
  const select = document.getElementById('reportCategoryFilter');
  if (!select) return;

  const session = getCurrentAdminSession();
  const allowedCategories = session.isSuperAdmin
    ? REPORT_CATEGORIES
    : getReportCategoriesForSession(session);
  const previousValue = select.value;

  select.innerHTML = '';
  if (allowedCategories.length === 0) {
    select.append(new Option('No assigned categories', ''));
    select.disabled = true;
    return;
  }

  // A single-category report admin should always start on that category.
  if (allowedCategories.length === 1) {
    select.append(new Option(allowedCategories[0], allowedCategories[0]));
    select.value = allowedCategories[0];
    select.disabled = true;
    return;
  }

  select.append(new Option('All Categories', ''));
  allowedCategories.forEach(category => select.append(new Option(category, category)));
  select.value = allowedCategories.includes(previousValue) ? previousValue : '';
  select.disabled = false;
}

function resolveAdminSession(user) {
  const email = String(user?.email || '').toLowerCase();
  const assignedRoles = getAdminRoles();
  const matchingRoles = assignedRoles.filter(role =>
    role.authUserId ? role.authUserId === user?.id : Boolean(email) && (role.assignedEmail || '').toLowerCase() === email
  );
  const superRole = matchingRoles.find(role => role.isSuperAdmin);

  if (superRole || user?.app_metadata?.is_super_admin === true) {
    return {
      isSuperAdmin: true,
      permissions: ADMIN_FEATURES.map(feature => feature.value),
      reportCategories: REPORT_CATEGORIES,
      transparencyCategories: TRANSPARENCY_CATEGORIES.map(item => item.value),
      email,
      roleName: 'Admin'
    };
  }

  if (matchingRoles.length) {
    return {
      isSuperAdmin: false,
      permissions: [...new Set(matchingRoles.flatMap(role =>
        Array.isArray(role.permissions) && role.permissions.length
          ? role.permissions
          : buildPermissionSet(role.feature || role.permission)
      ))],
      reportCategories: normalizeReportCategories(matchingRoles.flatMap(role => role.reportCategories || [])),
      transparencyCategories: normalizeTransparencyCategories(matchingRoles.flatMap(role => role.transparencyCategories || [])),
      email,
      roleName: matchingRoles[0].roleName || 'Admin'
    };
  }

  return null;
}

function getAllowedPagesForSession(session) {
  const allowed = new Set();
  if (!session || !session.permissions) return allowed;

  if (session.isSuperAdmin) {
    allowed.add('dashboard');
    ALL_ADMIN_PAGES.forEach(page => allowed.add(page));
    return allowed;
  }

  Object.entries(FEATURE_TO_PAGE_MAP).forEach(([feature, page]) => {
    if (session.permissions.includes(feature)) {
      allowed.add(page);
    }
  });

  return allowed;
}

function canAccessPage(page) {
  if (!adminAuthReady) return false;
  const session = getCurrentAdminSession();
  if (page === 'dashboard') return Boolean(session.isSuperAdmin);
  if (page === 'users') return canAccessUserDirectory();
  if (page === 'manage-admin') return Boolean(session.isSuperAdmin);

  const allowedPages = getAllowedPagesForSession(session);
  return allowedPages.has(page);
}

function applyAdminNavigationPermissions(user = null) {
  const session = user ? resolveAdminSession(user) : getCurrentAdminSession();
  localStorage.setItem(ADMIN_SESSION_STORAGE_KEY, JSON.stringify(session));

  const allowedPages = getAllowedPagesForSession(session);
  document.querySelectorAll('.nav-item').forEach(item => {
    const page = item.dataset.page;
    const isVisible = allowedPages.has(page);
    item.style.display = isVisible ? '' : 'none';
  });

  if (currentPage && !allowedPages.has(currentPage)) {
    const fallbackPage = allowedPages.values().next().value;
    if (fallbackPage) {
      navigateTo(fallbackPage);
    }
  }
}

// Pagination state for each page
const paginationState = {
  barangay: { current: 1, total: 0 },
  news: { current: 1, total: 0 },
  reports: { current: 1, total: 0 },
  transparency: { current: 1, total: 0 },
  tourist: { current: 1, total: 0 },
  placeReviews: { current: 1, total: 0 },
  services: { current: 1, total: 0 },
  hotline: { current: 1, total: 0 },
  users: { current: 1, total: 0 },
  adminRoles: { current: 1, total: 0 }
};

// Keep the complete displayed datasets so PDF exports include all filtered pages.
const tableExportRows = {};

function setupTableDownloads() {
  const tables = {
    barangayTableBody: 'barangays',
    newsTableBody: 'news',
    reportsTableBody: 'reports',
    transparencyTableBody: 'transparency',
    touristTableBody: 'tourist-destinations',
    serviceTableBody: 'service-requests',
    hotlineTableBody: 'hotlines',
    usersTableBody: 'users'
  };

  for (const [bodyId, name] of Object.entries(tables)) {
    const body = document.getElementById(bodyId);
    const header = body?.closest('.card')?.querySelector('.card-header');
    if (!header) continue;
    const actions = header.querySelector('.card-header-actions') || header;
    const button = document.createElement('button');
    button.type = 'button';
    button.className = 'btn btn-secondary pdf-download-btn';
    button.innerHTML = '<i class="fa-solid fa-file-pdf" aria-hidden="true"></i><span>Download PDF</span>';
    button.title = 'Downloads a styled PDF file';
    button.setAttribute('aria-label', `Download ${name.replace(/-/g, ' ')} as a styled PDF`);
    button.addEventListener('click', () => downloadTablePdf(bodyId, name, header.querySelector('h2')?.textContent || name));
    actions.appendChild(button);
  }
}

function exportColumnsForTable(bodyId) {
  const status = row => formatAdminStatus(row.status);
  const serviceStatus = row => formatServiceStatus(row.status);
  const date = value => value ? formatDate(value) : '';
  const attachmentCount = row => Array.isArray(row.image_urls) ? row.image_urls.length : 0;
  return {
    dashboardReportTableBody: [
      ['Reporter Name', row => row.reporter_name || 'Anonymous'],
      ['Message', row => row.message], ['Status', status],
      ['Attachments', attachmentCount], ['Date Submitted', row => date(row.created_at)]
    ],
    dashboardServiceTableBody: [
      ['Requested By', row => getServiceRequesterName(row)],
      ['Type', row => row._label], ['Status', serviceStatus],
      ['Date Requested', row => date(row.created_at)]
    ],
    barangayTableBody: [
      ['Barangay Name', row => row.name], ['Description', row => row.description],
      ['Geographic Data', row => row.geographic_data]
    ],
    newsTableBody: [
      ['Title', row => row.title], ['Description', row => row.description],
      ['Category', row => row.category || 'General'],
      ['Image URL', row => row.image_url && !row.image_url.startsWith('data:') ? row.image_url : ''],
      ['Published', row => row.is_published ? 'Yes' : 'No'],
      ['Created', row => date(row.created_at)]
    ],
    reportsTableBody: [
      ['Reporter Name', row => row.reporter_name || 'Anonymous'],
      ['Message', row => row.message], ['Category', row => row.category || 'Other'],
      ['Status', status], ['Attachments', attachmentCount],
      ['Submitted (PHT)', row => formatSubmittedAt(row.created_at)],
      ['Time Since Submission', row => formatSubmissionAge(row.created_at)],
      ['Last Updated', row => date(row.updated_at)]
    ],
    transparencyTableBody: [
      ['Title', row => row.title], ['Type', row => (row.type || '').replace(/_/g, ' ')],
      ['Description', row => row.description], ['PDF URL', row => row.pdf_url],
      ['Created', row => date(row.created_at)], ['Last Updated', row => date(row.updated_at)]
    ],
    touristTableBody: [
      ['Name', row => row.name], ['Location', row => row.location || row.short_location],
      ['Category', row => row.category], ['Description', row => row.description],
      ['Reviews', row => allPlaceReviews.filter(review => review.place_id === row.id).length],
      ['Created', row => date(row.created_at)], ['Last Updated', row => date(row.updated_at)]
    ],
    serviceTableBody: [
      ['Requested By', row => getServiceRequesterName(row)],
      ['Type', row => row.type || row.service_type], ['Status', serviceStatus],
      ['Appointment Date', row => date(row.appointment_date || row.date)],
      ['Submitted (PHT)', row => formatSubmittedAt(row.created_at)],
      ['Time Since Submission', row => formatSubmissionAge(row.created_at)]
    ],
    hotlineTableBody: [
      ['Name', row => row.name || row.department], ['Category', row => row.category || 'General'],
      ['Hotline Number', row => Array.isArray(row.phone_numbers) ? row.phone_numbers.join(', ') : row.phone_numbers || row.hotline_number]
    ],
    usersTableBody: [
      ['Email', row => row.email],
      ['Full Name', row => row.display_name || row.user_metadata?.full_name],
      ['Phone', row => row.phone || row.user_metadata?.phone],
      ['Address', row => row.address || row.user_metadata?.address],
      ['Verification', row => getVerificationBadgeText(row.verification_status)],
      ['Created', row => date(row.created_at)]
    ]
  }[bodyId] || [];
}

function pdfExportText(value) {
  // Convert decorative mathematical letters to ordinary text supported by Helvetica.
  return String(value ?? '').normalize('NFKC')
    .replace(/\r\n?/g, '\n')
    .replace(/[\p{Extended_Pictographic}\uFE0F\u200D]/gu, '')
    .trim();
}

function pdfColumnStyles(columns, availableWidth) {
  const weights = columns.map(([label]) => {
    if (/description|message|geographic|address/i.test(label)) return 3.5;
    if (/url$/i.test(label)) return 1.2;
    if (/title|name|requested by|email|location|hotline number/i.test(label)) return 2.4;
    if (/date|created|updated|submitted|time since/i.test(label)) return 1.8;
    return 1.4;
  });
  const total = weights.reduce((sum, weight) => sum + weight, 0);
  return Object.fromEntries(weights.map((weight, index) =>
    [index, { cellWidth: availableWidth * weight / total }]));
}

function downloadTablePdf(bodyId, name, title) {
  const rows = tableExportRows[bodyId] || [];
  if (!rows.length) {
    showToast('There are no records to export in this table.', 'error');
    return;
  }
  if (!window.jspdf?.jsPDF) {
    showToast('PDF download is unavailable. Please reload the page and try again.', 'error');
    return;
  }

  try {
    const columns = exportColumnsForTable(bodyId);
    const doc = new window.jspdf.jsPDF({
      orientation: columns.length > 5 ? 'landscape' : 'portrait',
      unit: 'mm',
      format: 'a4'
    });
    if (typeof doc.autoTable !== 'function') throw new Error('PDF table library did not load.');
    const pageWidth = doc.internal.pageSize.getWidth();
    const pageHeight = doc.internal.pageSize.getHeight();
    const exportedAt = new Date().toLocaleString('en-PH', { dateStyle: 'medium', timeStyle: 'short' });
    const statusColumn = columns.findIndex(column => column[0] === 'Status' || column[0] === 'Verification');
    const links = new Map();
    const body = rows.map((row, rowIndex) => columns.map((column, columnIndex) => {
      const value = column[1](row);
      if (/url$/i.test(column[0])) {
        const url = String(value || '').trim();
        if (!/^https?:\/\//i.test(url)) return '';
        links.set(`${rowIndex}:${columnIndex}`, url);
        return /pdf/i.test(column[0]) ? 'Open PDF' : 'View image';
      }
      return pdfExportText(value);
    }));

    doc.autoTable({
      head: [columns.map(column => column[0])],
      body,
      tableWidth: pageWidth - 24,
      columnStyles: pdfColumnStyles(columns, pageWidth - 24),
      rowPageBreak: 'avoid',
      startY: 43,
      margin: { top: 43, right: 12, bottom: 18, left: 12 },
      theme: 'grid',
      styles: {
        font: 'helvetica', fontSize: 8.5, cellPadding: 2.8,
        textColor: [30, 41, 59], lineColor: [226, 232, 240],
        lineWidth: 0.15, overflow: 'linebreak', valign: 'top'
      },
      headStyles: { fillColor: [30, 41, 59], textColor: [255, 255, 255], fontStyle: 'bold' },
      alternateRowStyles: { fillColor: [248, 250, 252] },
      didParseCell: data => {
        if (data.section === 'body' && /description|message|geographic|address/i.test(columns[data.column.index][0])) {
          data.cell.styles.halign = 'justify';
        }
        if (data.section === 'body' && links.has(`${data.row.index}:${data.column.index}`)) {
          data.cell.styles.textColor = [25, 118, 210];
        }
        if (data.section !== 'body' || data.column.index !== statusColumn) return;
        const value = String(data.cell.raw).toLowerCase();
        data.cell.styles.fontStyle = 'bold';
        data.cell.styles.fillColor = value.includes('pending') ? [255, 237, 213]
          : value.includes('returned') ? [254, 226, 226]
          : value.includes('completed') || value.includes('resolved') || value.includes('verified') ? [220, 252, 231]
          : [219, 234, 254];
      },
      didDrawCell: data => {
        if (data.section !== 'body') return;
        const url = links.get(`${data.row.index}:${data.column.index}`);
        if (url) doc.link(data.cell.x, data.cell.y, data.cell.width, data.cell.height, { url });
      },
      didDrawPage: data => {
        doc.setFillColor(25, 118, 210);
        doc.rect(0, 0, pageWidth, 5, 'F');
        doc.setFont('helvetica', 'bold');
        doc.setFontSize(9);
        doc.setTextColor(25, 118, 210);
        doc.text('iTIWI ADMIN DASHBOARD', 12, 15);
        doc.setFontSize(16);
        doc.setTextColor(15, 23, 42);
        doc.text(title, 12, 25);
        doc.setFont('helvetica', 'normal');
        doc.setFontSize(8);
        doc.setTextColor(100, 116, 139);
        doc.text(`${rows.length} records  |  Exported ${exportedAt}`, 12, 33);
        doc.setDrawColor(226, 232, 240);
        doc.line(12, 37, pageWidth - 12, 37);
        doc.text(`Page ${data.pageNumber}`, pageWidth - 12, pageHeight - 8, { align: 'right' });
      }
    });

    doc.save(`${name}-${new Date().toISOString().slice(0, 10)}.pdf`);
    showToast(`Downloaded ${rows.length} ${rows.length === 1 ? 'record' : 'records'} as PDF.`, 'success');
  } catch (error) {
    console.error('PDF export failed:', error);
    showToast('Could not create PDF: ' + error.message, 'error');
  }
}

// Notifications array
let notifications = [];

// ============================================================
// SETTINGS
// ============================================================

// ---------- ANTI-AUTOFILL FOR SEARCH INPUTS ----------
function preventSearchAutofill() {
  // Select all search inputs that should never autofill
  const searchIds = [
    'barangaySearch',
    'newsSearch',
    'reportsSearch',
    'transparencySearch',
    'touristSearch',
    'serviceSearch',
    'hotlineSearch',
    'usersSearch'
  ];

  searchIds.forEach(function(id) {
    var input = document.getElementById(id);
    if (!input) return;

    // Set readonly initially — browsers won't autofill readonly fields
    input.setAttribute('readonly', 'readonly');

    // Remove readonly on focus so user can type
    input.addEventListener('focus', function onFocus() {
      input.removeAttribute('readonly');
      input.removeEventListener('focus', onFocus);
    });

    // Also clear any value the browser may have injected
    input.addEventListener('mousedown', function clearAutofill() {
      // Delay to run after browser's autofill
      var valueOnMousedown = input.value;
      setTimeout(function() {
        if (input.value !== valueOnMousedown) {
          input.value = '';
        }
      }, 10);
    });
  });
}

// ---------- INIT ----------
document.addEventListener('DOMContentLoaded', () => {
  initDarkMode();
  initSupabase();
  preventSearchAutofill();
  setupNavigation();
  setupMobileMenu();
  setupSidebarCollapse();
  setupSearchListeners();
  setupNotifications();
  setupNewsSchedule();
  setupTableDownloads();
  setupLogoutButton();
  setupRealtimeListeners();
  setupFileDropZones();

});

// Let every admin upload use the same change handler for picked and dropped files.
function fileMatchesAccept(file, accept) {
  if (!accept) return true;
  return accept.split(',').some(rule => {
    const value = rule.trim().toLowerCase();
    const type = (file.type || '').toLowerCase();
    const name = file.name.toLowerCase();
    if (value.startsWith('.')) return name.endsWith(value);
    if (value.endsWith('/*')) return type.startsWith(value.slice(0, -1));
    return type === value;
  });
}

function hasDraggedFiles(event) {
  return Array.from(event.dataTransfer?.types || []).includes('Files');
}

function bindFileDropZone(input, zone) {
  if (!input || !zone || zone.dataset.dropBound) return;
  zone.dataset.dropBound = 'true';
  zone.classList.add('file-drop-zone');
  zone.dataset.dropHint = input.multiple ? 'Drop files here' : 'Drop a file here';

  zone.addEventListener('dragenter', event => {
    if (!hasDraggedFiles(event)) return;
    event.preventDefault();
    zone.classList.add('is-drag-over');
  });
  zone.addEventListener('dragover', event => {
    if (!hasDraggedFiles(event)) return;
    event.preventDefault();
    event.dataTransfer.dropEffect = 'copy';
    zone.classList.add('is-drag-over');
  });
  zone.addEventListener('dragleave', event => {
    if (!zone.contains(event.relatedTarget)) zone.classList.remove('is-drag-over');
  });
  zone.addEventListener('drop', event => {
    event.preventDefault();
    zone.classList.remove('is-drag-over');
    const dropped = Array.from(event.dataTransfer?.files || []);
    if (!dropped.length) return;
    if (!input.multiple && dropped.length > 1) {
      showToast('Drop one file in this upload area.', 'error');
      return;
    }
    const invalid = dropped.find(file => !fileMatchesAccept(file, input.accept));
    if (invalid) {
      showToast(`Unsupported file type: ${invalid.name}`, 'error');
      return;
    }
    const transfer = new DataTransfer();
    // These inputs keep their files until Save; gallery and Charter handlers keep
    // their own pending lists and clear the input after each selection.
    if (input.multiple && !['newsImage', 'touristImage', 'aboutCharterUpload'].includes(input.id)) {
      Array.from(input.files || []).forEach(file => transfer.items.add(file));
    }
    dropped.forEach(file => transfer.items.add(file));
    input.files = transfer.files;
    input.dispatchEvent(new Event('change', { bubbles: true }));
  });
}

function setupFileDropZones() {
  document.querySelectorAll('input[type="file"]').forEach(input => {
    if (input.classList.contains('official-photo-input')) return;
    let zone = input.closest('.logo-upload-wrapper') ||
      (input.previousElementSibling?.matches('.charter-upload-panel') ? input.previousElementSibling : null);
    if (!zone) {
      // Native file inputs need a visible drop target of their own.
      zone = document.createElement('div');
      input.parentNode.insertBefore(zone, input);
      zone.appendChild(input);
    }
    bindFileDropZone(input, zone);
  });
  document.addEventListener('dragover', event => {
    if (hasDraggedFiles(event)) event.preventDefault();
  });
  document.addEventListener('drop', event => {
    if (hasDraggedFiles(event)) event.preventDefault();
  });
}

// ============================================================
// NAVIGATION
// ============================================================
function setupNavigation() {
  document.querySelectorAll('.nav-item').forEach(item => {
    item.addEventListener('click', (e) => {
      e.preventDefault();
      const page = item.dataset.page;
      navigateTo(page);
    });
  });
}

function navigateTo(page) {
  if (!page) return;
  closeSidebar();
  const session = getCurrentAdminSession();
  if (!canAccessPage(page)) {
    showToast('You do not have access to this section.', 'error');
    const fallbackPage = canAccessPage('dashboard') ? 'dashboard' : ALL_ADMIN_PAGES.find(item => canAccessPage(item)) || 'dashboard';
    if (fallbackPage && fallbackPage !== page) {
      page = fallbackPage;
    } else {
      return;
    }
  }

  currentPage = page;

  // Save current page to localStorage for persistence on refresh
  localStorage.setItem('lastVisitedPage', page);

  document.querySelectorAll('.nav-item').forEach(item => {
    item.classList.toggle('active', item.dataset.page === page);
  });

  document.querySelectorAll('.page').forEach(p => p.classList.remove('active'));
  const targetPageId = resolvePageId(page);
  const targetPage = targetPageId ? document.getElementById(targetPageId) : null;
  if (targetPage) {
    targetPage.classList.add('active');
  }

  if (page === 'dashboard') {
    loadDashboardStats();
    loadDashboardReport();
    loadDashboardService();
  } else if (page === 'barangay') {
    loadBarangayTable();
  } else if (page === 'about-us') {
    loadAboutUs();
  } else if (page === 'news') {
    loadNews();
  } else if (page === 'reports') {
    loadReports();
  } else if (page === 'transparency') {
    loadTransparency();
  } else if (page === 'tourist') {
    loadTourist();
  } else if (page === 'services') {
    loadServices();
    loadAppointmentUnavailableDates();
  } else if (page === 'hotline') {
    loadHotline();
  } else if (page === 'users') {
    loadUsers();
  } else if (page === 'manage-admin') {
    loadManageAdmin();
  }

}

function closeSidebar() {
  document.getElementById('sidebar')?.classList.remove('open');
  document.getElementById('sidebarOverlay')?.classList.remove('active');
  document.body.style.overflow = '';
}

function setupMobileMenu() {
  const menuToggle = document.getElementById('menuToggle');
  const sidebar = document.getElementById('sidebar');
  const overlay = document.getElementById('sidebarOverlay') || createOverlay();

  function createOverlay() {
    const el = document.createElement('div');
    el.className = 'sidebar-overlay';
    el.id = 'sidebarOverlay';
    document.body.insertBefore(el, sidebar);
    return el;
  }

  function openSidebar() {
    sidebar.classList.add('open');
    if (window.innerWidth <= 768) {
      overlay.classList.add('active');
      document.body.style.overflow = 'hidden';
    }
  }

  menuToggle.addEventListener('click', (e) => {
    e.stopPropagation();
    if (sidebar.classList.contains('open')) {
      closeSidebar();
    } else {
      openSidebar();
    }
  });

  // Close sidebar when tapping overlay
  overlay.addEventListener('click', closeSidebar);

  // Close sidebar on Escape key
  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape' && sidebar.classList.contains('open') && window.innerWidth <= 768) {
      closeSidebar();
    }
  });

  // Re-evaluate on resize — close sidebar if window grows past mobile breakpoint
  let resizeTimer;
  window.addEventListener('resize', () => {
    clearTimeout(resizeTimer);
    resizeTimer = setTimeout(() => {
      if (window.innerWidth > 768) {
        closeSidebar();
      }
    }, 200);
  });
}

function setupSidebarCollapse() {
  const collapseBtn = document.getElementById('sidebarCollapseBtn');
  const brandLogo = document.getElementById('sidebarLogoBtn');
  const sidebar = document.getElementById('sidebar');
  const body = document.body;

  const updateToggleLabels = () => {
    const label = sidebar.classList.contains('collapsed') ? 'Expand Sidebar' : 'Collapse Sidebar';
    for (const button of [collapseBtn, brandLogo]) {
      button.setAttribute('aria-label', label);
      button.setAttribute('title', label);
      button.setAttribute('aria-expanded', String(!sidebar.classList.contains('collapsed')));
    }
  };

  // Load collapsed state from localStorage
  const isCollapsed = localStorage.getItem('sidebarCollapsed') === 'true';
  if (isCollapsed) {
    sidebar.classList.add('collapsed');
    body.classList.add('sidebar-collapsed');
  }
  updateToggleLabels();

  const toggleSidebar = () => {
    if (window.innerWidth <= 768) {
      closeSidebar();
      return;
    }

    sidebar.classList.toggle('collapsed');
    body.classList.toggle('sidebar-collapsed');
    const collapsed = sidebar.classList.contains('collapsed');
    localStorage.setItem('sidebarCollapsed', collapsed);
    updateToggleLabels();
  };

  collapseBtn.addEventListener('click', toggleSidebar);
  brandLogo.addEventListener('click', toggleSidebar);
}

// ============================================================
// TOAST NOTIFICATIONS
// ============================================================
function showToast(message, type = 'success') {
  const container = document.getElementById('toastContainer');
  const icons = {
    success: 'fa-circle-check',
    error: 'fa-circle-xmark'
  };

  const toast = document.createElement('div');
  toast.className = `toast toast-${type}`;
  toast.innerHTML = `
    <i class="fa-solid ${icons[type] || icons.success}"></i>
    <span class="toast-message"></span>
    <button class="toast-close" onclick="this.parentElement.remove()">
      <i class="fa-solid fa-xmark"></i>
    </button>
  `;
  toast.querySelector('.toast-message').textContent = message;

  container.appendChild(toast);

  setTimeout(() => {
    if (toast.parentElement) {
      toast.style.animation = 'toastIn 0.3s ease reverse';
      setTimeout(() => toast.remove(), 300);
    }
  }, 4000);
}

// ============================================================
// DASHBOARD STATS
// ============================================================
async function loadDashboardStats() {
  if (!supabaseClient) {
    document.getElementById('totalBarangay').textContent = '0';
    document.getElementById('totalNews').textContent = '0';
    document.getElementById('totalReports').textContent = '0';
    document.getElementById('activeUsers').textContent = '0';
    return;
  }

  try {
    const { count: barangayCount } = await supabaseClient
      .from('barangays')
      .select('*', { count: 'exact', head: true });
    document.getElementById('totalBarangay').textContent = barangayCount || 0;

    const { count: newsCount } = await supabaseClient
      .from('news')
      .select('*', { count: 'exact', head: true });
    document.getElementById('totalNews').textContent = newsCount || 0;

    const session = getCurrentAdminSession();
    const allowedCategories = getReportCategoriesForSession(session);
    let reportsCountQuery = supabaseClient
      .from('reports')
      .select('*', { count: 'exact', head: true });
    if (!session.isSuperAdmin) {
      reportsCountQuery = allowedCategories.length
        ? reportsCountQuery.in('category', allowedCategories)
        : null;
    }
    const { count: reportsCount } = reportsCountQuery
      ? await reportsCountQuery
      : { count: 0 };
    document.getElementById('totalReports').textContent = reportsCount || 0;

    // Fetch real user count from Firebase backend API
    try {
      const { data: authData } = await supabaseClient.auth.getSession();
      const response = await fetch('/api/user-count', {
        headers: { Authorization: 'Bearer ' + (authData?.session?.access_token || '') }
      });
      const data = await response.json();

      if (data.success) {
        document.getElementById('activeUsers').textContent = data.userCount;
        console.log('✅ Active users from Firebase:', data.userCount);
      } else {
        throw new Error(data.error);
      }
    } catch (error) {
      console.error('Error fetching user count from backend:', error);
      document.getElementById('activeUsers').textContent = '0';
    }
  } catch (error) {
    console.error('Error loading stats:', error);
    document.getElementById('totalBarangay').textContent = '0';
    document.getElementById('totalNews').textContent = '0';
    document.getElementById('totalReports').textContent = '0';
    document.getElementById('activeUsers').textContent = '0';
  }

  // Load additional analytics
  loadAnalytics();
  loadPerformanceTrend();
}

// ============================================================
// ANALYTICS FUNCTIONS
// ============================================================
async function loadAnalytics() {
  if (!supabaseClient) return;

  try {
    await Promise.all([
      loadPendingStats(),
      loadTransparencyCount(),
      loadReportStatusBreakdown(),
      loadServiceStatusBreakdown(),
      loadNewsByCategory(),
      loadReportsByCategory(),
      loadServicesByType()
    ]);
  } catch (error) {
    console.error('Error loading analytics:', error);
  }
}

async function loadPendingStats() {
  try {
    const session = getCurrentAdminSession();
    const allowedCategories = getReportCategoriesForSession(session);
    let pendingReportsQuery = supabaseClient
      .from('reports')
      .select('*', { count: 'exact', head: true })
      .eq('status', 'pending');
    if (!session.isSuperAdmin) {
      pendingReportsQuery = allowedCategories.length
        ? pendingReportsQuery.in('category', allowedCategories)
        : null;
    }
    const { count: pendingReports } = pendingReportsQuery
      ? await pendingReportsQuery
      : { count: 0 };
    document.getElementById('pendingReports').textContent = pendingReports || 0;

    const serviceTables = [
      'birth_certificate_appointments',
      'cenodeath_appointments',
      'cenomar_appointments',
      'death_certificate_appointments',
      'marriage_certificate_appointments',
      'facility_borrow_requests'
    ];

    let totalPendingServices = 0;
    for (const table of serviceTables) {
      try {
        const { count } = await supabaseClient
          .from(table)
          .select('*', { count: 'exact', head: true })
          .eq('status', 'pending');
        totalPendingServices += count || 0;
      } catch (e) {
        // Table might not exist
      }
    }
    document.getElementById('pendingServices').textContent = totalPendingServices;
  } catch (error) {
    console.error('Error loading pending stats:', error);
  }
}

async function loadTransparencyCount() {
  try {
    const { count } = await supabaseClient
      .from('transparency')
      .select('*', { count: 'exact', head: true });
    document.getElementById('transparencyDocCount').textContent = count || 0;
  } catch (error) {
    console.error('Error loading transparency count:', error);
    document.getElementById('transparencyDocCount').textContent = '0';
  }
}

async function loadReportStatusBreakdown() {
  try {
    const session = getCurrentAdminSession();
    const allowedCategories = getReportCategoriesForSession(session);
    let reportStatusQuery = supabaseClient
      .from('reports')
      .select('status');
    if (!session.isSuperAdmin) {
      reportStatusQuery = allowedCategories.length
        ? reportStatusQuery.in('category', allowedCategories)
        : null;
    }
    const { data } = reportStatusQuery ? await reportStatusQuery : { data: [] };

    const statusCounts = { pending: 0, reviewing: 0, resolved: 0 };
    (data || []).forEach(r => {
      const status = r.status || 'pending';
      if (statusCounts.hasOwnProperty(status)) {
        statusCounts[status]++;
      }
    });

    const total = Object.values(statusCounts).reduce((a, b) => a + b, 0) || 1;

    Object.entries(statusCounts).forEach(([status, count]) => {
      const percentage = total > 0 ? (count / total) * 100 : 0;
      document.getElementById(`report${capitalize(status)}Count`).textContent = count;
      document.getElementById(`report${capitalize(status)}Bar`).style.width = percentage + '%';
    });
  } catch (error) {
    console.error('Error loading report status breakdown:', error);
  }
}

async function loadServiceStatusBreakdown() {
  try {
    const serviceTables = [
      'birth_certificate_appointments',
      'cenodeath_appointments',
      'cenomar_appointments',
      'death_certificate_appointments',
      'marriage_certificate_appointments',
      'facility_borrow_requests'
    ];

    const statusCounts = { pending: 0, processing: 0, completed: 0, rejected: 0 };

    for (const table of serviceTables) {
      try {
        const { data } = await supabaseClient.from(table).select('status');
        (data || []).forEach(item => {
          const status = item.status || 'pending';
          if (statusCounts.hasOwnProperty(status)) {
            statusCounts[status]++;
          } else if (status === 'appointment_status') {
            statusCounts.pending++;
          }
        });
      } catch (e) {
        // Table might not exist
      }
    }

    const total = Object.values(statusCounts).reduce((a, b) => a + b, 0) || 1;

    ['Pending', 'Processing', 'Completed', 'Rejected'].forEach(status => {
      const key = status.toLowerCase();
      const count = statusCounts[key] || 0;
      const percentage = total > 0 ? (count / total) * 100 : 0;
      const el = document.getElementById(`service${status}Count`);
      const bar = document.getElementById(`service${status}Bar`);
      if (el) el.textContent = count;
      if (bar) bar.style.width = percentage + '%';
    });
  } catch (error) {
    console.error('Error loading service status breakdown:', error);
  }
}

async function loadNewsByCategory() {
  try {
    const { data } = await supabaseClient
      .from('news')
      .select('category');

    const categoryCounts = {};
    (data || []).forEach(item => {
      const cat = item.category || 'General';
      categoryCounts[cat] = (categoryCounts[cat] || 0) + 1;
    });

    renderCategoryList('newsByCategoryList', categoryCounts);
  } catch (error) {
    console.error('Error loading news by category:', error);
  }
}

async function loadReportsByCategory() {
  try {
    const session = getCurrentAdminSession();
    const allowedCategories = getReportCategoriesForSession(session);
    let reportCategoryQuery = supabaseClient
      .from('reports')
      .select('category');
    if (!session.isSuperAdmin) {
      reportCategoryQuery = allowedCategories.length
        ? reportCategoryQuery.in('category', allowedCategories)
        : null;
    }
    const { data } = reportCategoryQuery ? await reportCategoryQuery : { data: [] };

    const categoryCounts = {};
    (data || []).forEach(item => {
      const cat = item.category || 'General';
      categoryCounts[cat] = (categoryCounts[cat] || 0) + 1;
    });

    renderCategoryList('reportsByCategoryList', categoryCounts);
  } catch (error) {
    console.error('Error loading reports by category:', error);
  }
}

async function loadServicesByType() {
  try {
    const serviceTables = [
      { name: 'birth_certificate_appointments', type: 'Birth Certificate' },
      { name: 'cenodeath_appointments', type: 'Cenodeath Appointments' },
      { name: 'cenomar_appointments', type: 'Cenomar Appointments' },
      { name: 'death_certificate_appointments', type: 'Death Certificate' },
      { name: 'marriage_certificate_appointments', type: 'Marriage Certificate' },
      { name: 'facility_borrow_requests', type: 'Facility Borrowing' }
    ];

    const typeCounts = {};

    for (const serviceTable of serviceTables) {
      try {
        const { count } = await supabaseClient
          .from(serviceTable.name)
          .select('*', { count: 'exact', head: true });
        if (count > 0) {
          typeCounts[serviceTable.type] = count;
        }
      } catch (e) {
        // Table might not exist
      }
    }

    renderCategoryList('servicesByTypeList', typeCounts);
  } catch (error) {
    console.error('Error loading services by type:', error);
  }
}

function renderCategoryList(elementId, categoryCounts) {
  const el = document.getElementById(elementId);
  if (!el) return;

  if (Object.keys(categoryCounts).length === 0) {
    el.innerHTML = '<p class="loading-text">No data available</p>';
    return;
  }

  el.innerHTML = Object.entries(categoryCounts)
    .sort((a, b) => b[1] - a[1])
    .map(([category, count]) => `
      <div class="category-item">
        <span class="category-item-label">${escapeHtml(category)}</span>
        <span class="category-item-count">${count}</span>
      </div>
    `)
    .join('');
}

function capitalize(str) {
  return str.charAt(0).toUpperCase() + str.slice(1);
}

function formatAdminStatus(status, fallback = 'Pending') {
  const normalized = (status || '').toLowerCase();
  if (!normalized) return fallback;
  if (normalized === 'rejected') return 'Returned';
  return normalized.charAt(0).toUpperCase() + normalized.slice(1);
}

function formatServiceStatus(status, fallback = 'Pending') {
  return String(status || '').trim().toLowerCase() === 'processing'
    ? 'Ready for Release'
    : formatAdminStatus(status, fallback);
}

function escapeHtml(text) {
  const div = document.createElement('div');
  div.textContent = text;
  return div.innerHTML;
}

// -------- MOBILE DATA-LABELS --------
// Sets data-label on every <td> from the corresponding <th> text,
// so CSS can show labels inside cards on mobile.
function applyTableDataLabels(table) {
  if (!table) return;
  const theadThs = table.querySelectorAll('thead tr th');
  if (!theadThs.length) return;
  const labels = [];
  theadThs.forEach(th => {
    labels.push(th.textContent.trim());
  });
  table.querySelectorAll('tbody tr').forEach(tr => {
    const tds = tr.querySelectorAll('td');
    tds.forEach((td, idx) => {
      if (idx < labels.length && labels[idx]) {
        td.setAttribute('data-label', labels[idx]);
      }
    });
  });
}

// Convenience: apply to every <table class="data-table"> in the DOM
function applyAllTableDataLabels() {
  document.querySelectorAll('.data-table').forEach(applyTableDataLabels);
}

function getCategoryColor(category) {
  const colors = {
    'Emergency': '#dc2626',
    'Health': '#2563eb',
    'Public Safety': '#7c3aed',
    'Social Services': '#0891b2',
    'Infrastructure': '#f59e0b',
    'Administrative': '#6366f1',
    'Support': '#10b981',
    'General': '#8b5cf6'
  };
  return colors[category] || '#6b7280';
}

async function loadPerformanceTrend() {
  if (!supabaseClient) return;

  try {
    const filterValue = document.getElementById('performanceTrendFilter')?.value || 'weekly';
    const now = new Date();

    // Build labels and data accumulator based on filter
    const labels = [];
    const dataBuckets = {};

    let getDateKey;

    if (filterValue === 'daily') {
      // Last 7 days (today + past 6 days)
      for (let i = 6; i >= 0; i--) {
        const d = new Date(now);
        d.setDate(d.getDate() - i);
        const key = d.toLocaleDateString('en-US', { weekday: 'short', month: 'short', day: 'numeric' });
        labels.push(key);
        dataBuckets[key] = { reports: 0, news: 0, requests: 0, reviews: 0 };
      }
      getDateKey = (dateStr) => {
        const d = new Date(dateStr);
        return d.toLocaleDateString('en-US', { weekday: 'short', month: 'short', day: 'numeric' });
      };
    } else if (filterValue === 'weekly') {
      // Last 6 weeks — each bucket is a week range (Mon–Sun)
      for (let i = 5; i >= 0; i--) {
        // Monday of week i weeks ago
        const monday = new Date(now);
        monday.setDate(monday.getDate() - ((now.getDay() || 7) - 1) - 7 * i);
        monday.setHours(0, 0, 0, 0);
        const sunday = new Date(monday);
        sunday.setDate(sunday.getDate() + 6);
        sunday.setHours(23, 59, 59, 999);

        const startStr = monday.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
        const endStr = sunday.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
        const key = `${startStr}–${endStr}`;
        labels.push(key);
        dataBuckets[key] = {
          reports: 0, news: 0, requests: 0, reviews: 0,
          _start: monday.getTime(), _end: sunday.getTime()
        };
      }
      getDateKey = (dateStr) => {
        const t = new Date(dateStr).getTime();
        for (const key of labels) {
          const b = dataBuckets[key];
          if (t >= b._start && t <= b._end) return key;
        }
        return null;
      };
    } else { // yearly
      // Last 12 months
      for (let i = 11; i >= 0; i--) {
        const d = new Date(now.getFullYear(), now.getMonth() - i, 1);
        const key = d.toLocaleString('default', { month: 'short', year: 'numeric' });
        labels.push(key);
        dataBuckets[key] = { reports: 0, news: 0, requests: 0, reviews: 0 };
      }
      getDateKey = (dateStr) => {
        const d = new Date(dateStr);
        return d.toLocaleString('default', { month: 'short', year: 'numeric' });
      };
    }

    // Assign a record to the correct bucket
    const bucketize = (records, field) => {
      (records || []).forEach(item => {
        if (!item.created_at) return;
        const key = getDateKey(item.created_at);
        if (key && dataBuckets[key]) {
          dataBuckets[key][field]++;
        }
      });
    };

    // Fetch & bucketize: reports
    try {
      const { data } = await supabaseClient.from('reports').select('created_at');
      bucketize(data, 'reports');
    } catch (e) { console.warn('Could not fetch reports:', e); }

    // Fetch & bucketize: news
    try {
      const { data } = await supabaseClient.from('news').select('created_at');
      bucketize(data, 'news');
    } catch (e) { console.warn('Could not fetch news:', e); }

    // Fetch & bucketize: service requests
    const serviceTables = [
      'birth_certificate_appointments', 'cenodeath_appointments',
      'cenomar_appointments', 'death_certificate_appointments',
      'marriage_certificate_appointments', 'facility_borrow_requests'
    ];
    for (const table of serviceTables) {
      try {
        const { data } = await supabaseClient.from(table).select('created_at');
        bucketize(data, 'requests');
      } catch (e) { /* skip */ }
    }

    // Fetch & bucketize: places (as a proxy for reviews activity)
    try {
      const { data } = await supabaseClient.from('places').select('created_at');
      bucketize(data, 'reviews');
    } catch (e) { console.warn('Could not fetch places:', e); }

    // Prepare chart data arrays
    const reportsCounts = labels.map(l => dataBuckets[l]?.reports || 0);
    const newsCounts     = labels.map(l => dataBuckets[l]?.news || 0);
    const requestsCounts = labels.map(l => dataBuckets[l]?.requests || 0);
    const reviewsCounts  = labels.map(l => dataBuckets[l]?.reviews || 0);

    console.log('Performance Trend —', filterValue, { labels, reportsCounts, newsCounts, requestsCounts, reviewsCounts });

    if (typeof Chart === 'undefined') {
      console.error('Chart.js is not loaded');
      return;
    }

    const ctx = document.getElementById('performanceTrendChart');
    if (!ctx) { console.error('Canvas element not found'); return; }

    // Destroy previous chart
    if (window.performanceTrendChart instanceof Chart) {
      window.performanceTrendChart.destroy();
    }

    // Detect dark mode for axis colours
    const isDark = document.documentElement.getAttribute('data-theme') === 'dark';
    const axisColor = isDark ? '#9ca3af' : '#6b7280';
    const gridColor = isDark ? 'rgba(255,255,255,0.06)' : 'rgba(0,0,0,0.05)';

    window.performanceTrendChart = new Chart(ctx, {
      type: 'line',
      data: {
        labels: labels,
        datasets: [
          {
            label: 'Place Review',
            data: reviewsCounts,
            borderColor: '#9C27B0',
            backgroundColor: 'rgba(156, 39, 176, 0.05)',
            borderWidth: 2.5,
            fill: true,
            tension: 0.4,
            pointBackgroundColor: '#9C27B0',
            pointBorderColor: '#fff',
            pointBorderWidth: 2,
            pointRadius: 4,
            pointHoverRadius: 7
          },
          {
            label: 'Request',
            data: requestsCounts,
            borderColor: '#4CAF50',
            backgroundColor: 'rgba(76, 175, 80, 0.05)',
            borderWidth: 2.5,
            fill: true,
            tension: 0.4,
            pointBackgroundColor: '#4CAF50',
            pointBorderColor: '#fff',
            pointBorderWidth: 2,
            pointRadius: 4,
            pointHoverRadius: 7
          },
          {
            label: 'Reports',
            data: reportsCounts,
            borderColor: '#FF9800',
            backgroundColor: 'rgba(255, 152, 0, 0.05)',
            borderWidth: 2.5,
            fill: true,
            tension: 0.4,
            pointBackgroundColor: '#FF9800',
            pointBorderColor: '#fff',
            pointBorderWidth: 2,
            pointRadius: 4,
            pointHoverRadius: 7
          },
          {
            label: 'News',
            data: newsCounts,
            borderColor: '#2196F3',
            backgroundColor: 'rgba(33, 150, 243, 0.05)',
            borderWidth: 2.5,
            fill: true,
            tension: 0.4,
            pointBackgroundColor: '#2196F3',
            pointBorderColor: '#fff',
            pointBorderWidth: 2,
            pointRadius: 4,
            pointHoverRadius: 7
          }
        ]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: {
            display: true,
            position: 'top',
            labels: {
              font: { size: 12, weight: '500' },
              padding: 15,
              usePointStyle: true,
              color: axisColor
            }
          }
        },
        scales: {
          y: {
            beginAtZero: true,
            grid: { drawBorder: false, color: gridColor },
            ticks: { font: { size: 12 }, color: axisColor, stepSize: 1 }
          },
          x: {
            grid: { display: false, drawBorder: false },
            ticks: { font: { size: 10 }, color: axisColor, maxRotation: filterValue === 'weekly' ? 45 : 30 }
          }
        },
        interaction: { intersect: false, mode: 'index' }
      }
    });

    console.log('Performance trend chart updated (' + filterValue + ')');
  } catch (error) {
    console.error('Error loading performance trend:', error);
  }
}

// ============================================================
// BARANGAY CRUD — Real Supabase Data
// ============================================================
async function loadDashboardBarangay() {
  const tbody = document.getElementById('dashboardBarangayTableBody');
  if (!tbody) return;
  await renderBarangayTable(tbody, 5);
}

async function loadDashboardReport() {
  const tbody = document.getElementById('dashboardReportTableBody');
  if (!tbody) return;
  await renderDashboardReportTable(tbody);
}

async function loadDashboardService() {
  const tbody = document.getElementById('dashboardServiceTableBody');
  if (!tbody) return;
  await renderDashboardServiceTable(tbody);
}

async function renderDashboardReportTable(tbody) {
  if (!supabaseClient) {
    const colSpan = tbody.closest('table').querySelectorAll('th').length;
    tbody.innerHTML = `<tr><td colspan="${colSpan}" class="empty-state">No reports found</td></tr>`;
    return;
  }

  try {
    const session = getCurrentAdminSession();
    const allowedCategories = getReportCategoriesForSession(session);
    if (!session.isSuperAdmin && allowedCategories.length === 0) {
      const colSpan = tbody.closest('table').querySelectorAll('th').length;
      tbody.innerHTML = `<tr><td colspan="${colSpan}" class="empty-state">No reports assigned to your account</td></tr>`;
      return;
    }

    let dashboardReportQuery = supabaseClient
      .from('reports')
      .select('*')
      .order('created_at', { ascending: false })
      .limit(5);
    if (!session.isSuperAdmin) {
      dashboardReportQuery = dashboardReportQuery.in('category', allowedCategories);
    }
    const { data, error } = await dashboardReportQuery;

    if (error) throw error;

    let reports = data || [];

    // Fetch user display names for enrichment
    if (reports.length > 0) {
      const userIds = [...new Set(reports.map(r => r.user_id).filter(Boolean))];

      if (userIds.length > 0) {
        const { data: users } = await supabaseClient
          .from('users')
          .select('id, display_name, email')
          .in('id', userIds);

        const userMap = {};
        (users || []).forEach(u => {
          const name = (u.display_name && u.display_name.trim())
            ? u.display_name
            : (u.email && u.email.trim()
              ? u.email
              : u.id.substring(0, 12));
          userMap[u.id] = name;
        });

        reports = reports.map(r => ({
          ...r,
          reporter_name: r.reporter_name || userMap[r.user_id] || r.user_id?.substring(0, 12) || 'Anonymous'
        }));
      }
    }

    tableExportRows.dashboardReportTableBody = reports;
    const colSpan = tbody.closest('table').querySelectorAll('th').length;
    if (!reports || reports.length === 0) {
      tbody.innerHTML = `<tr><td colspan="${colSpan}" class="empty-state">No reports found</td></tr>`;
      return;
    }

    tbody.innerHTML = '';
    reports.forEach(report => {
      const tr = document.createElement('tr');

      const tdReporterName = document.createElement('td');
      tdReporterName.textContent = report.reporter_name || 'Anonymous';

      const tdMessage = document.createElement('td');
      tdMessage.textContent = report.message || '';
      tdMessage.style.maxWidth = '250px';
      tdMessage.style.overflow = 'hidden';
      tdMessage.style.textOverflow = 'ellipsis';
      tdMessage.style.whiteSpace = 'nowrap';

      const tdStatus = document.createElement('td');
      const statusBadge = document.createElement('span');
      statusBadge.className = `status-badge ${getStatusClass(report.status)}`;
      statusBadge.textContent = formatAdminStatus(report.status);
      tdStatus.appendChild(statusBadge);

      const tdAttachment = document.createElement('td');
      if (report.image_urls && Array.isArray(report.image_urls)) {
        const count = report.image_urls.length;
        tdAttachment.textContent = `${count} image${count !== 1 ? 's' : ''}`;
      } else {
        tdAttachment.textContent = '0 images';
      }

      const tdDate = document.createElement('td');
      const date = new Date(report.created_at);
      tdDate.textContent = date.toLocaleDateString('en-US', { year: 'numeric', month: 'short', day: 'numeric' });

      const tdAction = document.createElement('td');
      const actionBtn = document.createElement('button');
      actionBtn.className = 'btn btn-sm btn-info btn-icon';
      actionBtn.title = 'View';
      actionBtn.innerHTML = '<i class="fa-solid fa-eye"></i>';
      actionBtn.addEventListener('click', () => openReportModal(report.id));
      tdAction.appendChild(actionBtn);

      tr.appendChild(tdReporterName);
      tr.appendChild(tdMessage);
      tr.appendChild(tdStatus);
      tr.appendChild(tdAttachment);
      tr.appendChild(tdDate);
      tr.appendChild(tdAction);

      tbody.appendChild(tr);
    });
  } catch (error) {
    console.error('Error loading dashboard reports:', error);
    const colSpan = tbody.closest('table').querySelectorAll('th').length;
    tbody.innerHTML = `<tr><td colspan="${colSpan}" class="empty-state">Error loading reports</td></tr>`;
  }
}

async function renderDashboardServiceTable(tbody) {
  if (!supabaseClient) {
    const colSpan = tbody.closest('table').querySelectorAll('th').length;
    tbody.innerHTML = `<tr><td colspan="${colSpan}" class="empty-state">No requests found</td></tr>`;
    return;
  }

  try {
    let combinedData = [];

    const serviceTables = [
      { name: 'birth_certificate_appointments', label: 'Birth Certificate' },
      { name: 'cenodeath_appointments', label: 'Cenodeath Appointments' },
      { name: 'cenomar_appointments', label: 'Cenomar Appointments' },
      { name: 'death_certificate_appointments', label: 'Death Certificate' },
      { name: 'marriage_certificate_appointments', label: 'Marriage Certificate' },
      { name: 'facility_borrow_requests', label: 'Facility Borrowing' }
    ];

    for (const table of serviceTables) {
      try {
        const { data } = await supabaseClient
          .from(table.name)
          .select('*')
          .order('created_at', { ascending: false });

        if (data) {
          const mappedData = data.map(item => ({
            id: item.id,
            requested_by: item.requested_by || item.applicant_name || item.customer_name || item.client_name || item.submitted_by || item.first_name || 'N/A',
            status: item.status || item.appointment_status || 'pending',
            created_at: item.created_at || new Date().toISOString(),
            _table: table.name,
            _label: table.label,
            user_id: item.user_id,
            ...item
          }));
          combinedData = [...combinedData, ...mappedData];
        }
      } catch (e) {
        // Table might not exist
      }
    }

    // Fetch display names for unique user IDs
    const userIds = [...new Set(combinedData.map(item => item.user_id).filter(id => id))];
    const userDisplayNames = {};

    if (userIds.length > 0) {
      try {
        const { data: users } = await supabaseClient
          .from('users')
          .select('id, display_name')
          .in('id', userIds);

        if (users) {
          users.forEach(user => {
            userDisplayNames[user.id] = user.display_name;
          });
        }
      } catch (e) {
        // Could not fetch user names
      }
    }

    // Add display_name and sort
    combinedData = combinedData
      .map(item => ({
        ...item,
        display_name: userDisplayNames[item.user_id] || item.display_name || item.requester_name || item.full_name || item.name || null
      }))
      .sort((a, b) => new Date(b.created_at) - new Date(a.created_at))
      .slice(0, 5);

    tableExportRows.dashboardServiceTableBody = combinedData;

    const colSpan = tbody.closest('table').querySelectorAll('th').length;
    if (combinedData.length === 0) {
      tbody.innerHTML = `<tr><td colspan="${colSpan}" class="empty-state">No service requests found</td></tr>`;
      return;
    }

    tbody.innerHTML = '';
    combinedData.forEach(service => {
      const tr = document.createElement('tr');

      const tdRequestedBy = document.createElement('td');
      tdRequestedBy.textContent = getServiceRequesterName(service);

      const tdType = document.createElement('td');
      tdType.textContent = service._label || 'Service';

      const tdStatus = document.createElement('td');
      const statusBadge = document.createElement('span');
      statusBadge.className = `status-badge ${getStatusClass(service.status)}`;
      statusBadge.textContent = formatServiceStatus(service.status);
      tdStatus.appendChild(statusBadge);

      const tdDate = document.createElement('td');
      const date = new Date(service.created_at);
      tdDate.textContent = date.toLocaleDateString('en-US', { year: 'numeric', month: 'short', day: 'numeric' });

      const tdAction = document.createElement('td');
      const actionBtn = document.createElement('button');
      actionBtn.className = 'btn btn-sm btn-info btn-icon';
      actionBtn.title = 'View';
      actionBtn.innerHTML = '<i class="fa-solid fa-eye"></i>';
      actionBtn.addEventListener('click', () => {
        openServiceDetailsModal(service.id);
      });
      tdAction.appendChild(actionBtn);

      tr.appendChild(tdRequestedBy);
      tr.appendChild(tdType);
      tr.appendChild(tdStatus);
      tr.appendChild(tdDate);
      tr.appendChild(tdAction);

      tbody.appendChild(tr);
    });
  } catch (error) {
    console.error('Error loading dashboard services:', error);
    const colSpan = tbody.closest('table').querySelectorAll('th').length;
    tbody.innerHTML = `<tr><td colspan="${colSpan}" class="empty-state">Error loading service requests</td></tr>`;
  }
}

async function loadBarangayTable() {
  const tbody = document.getElementById('barangayTableBody');
  if (!tbody) return;
  await renderBarangayTable(tbody, null, true);
}

async function fetchBarangays() {
  if (!supabaseClient) {
    console.warn('Supabase client not initialized — cannot fetch barangays');
    return [];
  }

  try {
    const { data, error } = await supabaseClient
      .from('barangays')
      .select('*')
      .order('id', { ascending: true });

    if (error) {
      console.error('Supabase error fetching barangays:', error.message, error.details);
      showToast('Failed to load barangays from database: ' + error.message, 'error');
      return [];
    }
    return data || [];
  } catch (error) {
    console.error('Error fetching barangays:', error);
    showToast('Failed to connect to database. Check your connection.', 'error');
    return [];
  }
}

async function renderBarangayTable(tbody, limit = null, showPagination = false, barangayData = null) {
  const barangays = [...(barangayData !== null ? barangayData : await fetchBarangays())]
    .sort((a, b) => String(a.name || '').localeCompare(String(b.name || ''), undefined, { sensitivity: 'base' }));
  if (showPagination) tableExportRows.barangayTableBody = barangays;

  if (!showPagination) {
    const data = limit ? barangays.slice(0, limit) : barangays;
    if (data.length === 0) {
      const colSpan = tbody.closest('table').querySelectorAll('th').length;
      tbody.innerHTML = `<tr><td colspan="${colSpan}" class="empty-state">No barangay records found</td></tr>`;
      return;
    }

    tbody.innerHTML = '';
    data.forEach(b => renderBarangayRow(tbody, b));
    return;
  }

  // With pagination
  const totalItems = barangays.length;
  const totalPages = Math.ceil(totalItems / ITEMS_PER_PAGE);
  const currentPage = paginationState.barangay.current;

  // Reset to page 1 if out of bounds
  if (currentPage > totalPages && totalPages > 0) {
    paginationState.barangay.current = 1;
    renderBarangayTable(tbody, limit, showPagination);
    return;
  }

  const startIdx = (currentPage - 1) * ITEMS_PER_PAGE;
  const endIdx = startIdx + ITEMS_PER_PAGE;
  const data = barangays.slice(startIdx, endIdx);

  const colSpan = tbody.closest('table').querySelectorAll('th').length;
  if (data.length === 0) {
    tbody.innerHTML = `<tr><td colspan="${colSpan}" class="empty-state">No barangay records found</td></tr>`;
    renderPagination(totalItems);
    return;
  }

  tbody.innerHTML = '';
  data.forEach(b => renderBarangayRow(tbody, b));
  renderPagination(totalItems);
}

function renderBarangayRow(tbody, b) {
  const tr = document.createElement('tr');

  const tdLogo = document.createElement('td');
  const logoImg = document.createElement('img');
  if (b.logo_url) {
    logoImg.src = b.logo_url;
    logoImg.alt = b.name;
    logoImg.className = 'barangay-logo-thumb';
  } else {
    logoImg.className = 'barangay-logo-thumb-placeholder';
    logoImg.style.background = '#f0f2f5';
    logoImg.innerHTML = '<i class="fa-solid fa-image" style="font-size: 16px; color: #999;"></i>';
  }
  tdLogo.appendChild(logoImg);

  const tdName = document.createElement('td');
  tdName.textContent = b.name || 'N/A';

  const tdDesc = document.createElement('td');
  tdDesc.textContent = b.description || 'N/A';

  const tdLocation = document.createElement('td');
  tdLocation.textContent = b.geographic_data || 'N/A';

  const tdActions = document.createElement('td');
  const actionsDiv = document.createElement('div');
  actionsDiv.className = 'action-btns';

  const editBtn = document.createElement('button');
  editBtn.className = 'btn btn-sm btn-edit btn-icon';
  editBtn.title = 'Edit';
  editBtn.innerHTML = '<i class="fa-solid fa-pen-to-square"></i>';
  editBtn.addEventListener('click', () => openEditModal(b.id));

  const deleteBtn = document.createElement('button');
  deleteBtn.className = 'btn btn-sm btn-delete btn-icon';
  deleteBtn.title = 'Delete';
  deleteBtn.innerHTML = '<i class="fa-solid fa-trash"></i>';
  deleteBtn.addEventListener('click', () => openDeleteBarangay(b.id, b.name));

  actionsDiv.appendChild(editBtn);
  actionsDiv.appendChild(deleteBtn);
  tdActions.appendChild(actionsDiv);

  tr.appendChild(tdLogo);
  tr.appendChild(tdName);
  tr.appendChild(tdDesc);
  tr.appendChild(tdLocation);
  tr.appendChild(tdActions);

  tbody.appendChild(tr);
}

function renderPagination(totalItems) {
  const paginationEl = document.getElementById('barangayPagination');
  const showingEl = document.getElementById('barangayShowing');
  if (!paginationEl || !showingEl) return;

  const totalPages = Math.ceil(totalItems / ITEMS_PER_PAGE);
  const currentPage = paginationState.barangay.current;
  paginationState.barangay.total = totalPages;
  showingEl.textContent = `Showing ${Math.min(currentPage * ITEMS_PER_PAGE, totalItems)} of ${totalItems} entries`;

  if (totalPages <= 1) {
    paginationEl.innerHTML = '';
    return;
  }

  let html = `<button class="page-btn prev-btn" data-page="${currentPage - 1}" ${currentPage === 1 ? 'disabled' : ''}><i class="fa-solid fa-chevron-left"></i></button>`;

  const maxButtons = 5;
  let startPage = Math.max(1, currentPage - Math.floor(maxButtons / 2));
  let endPage = Math.min(totalPages, startPage + maxButtons - 1);
  if (endPage - startPage + 1 < maxButtons) {
    startPage = Math.max(1, endPage - maxButtons + 1);
  }

  if (startPage > 1) {
    html += `<button class="page-btn" data-page="1">1</button>`;
    if (startPage > 2) html += `<span class="page-ellipsis">...</span>`;
  }

  for (let i = startPage; i <= endPage; i++) {
    html += `<button class="page-btn ${i === currentPage ? 'active' : ''}" data-page="${i}">${i}</button>`;
  }

  if (endPage < totalPages) {
    if (endPage < totalPages - 1) html += `<span class="page-ellipsis">...</span>`;
    html += `<button class="page-btn" data-page="${totalPages}">${totalPages}</button>`;
  }

  html += `<button class="page-btn next-btn" data-page="${currentPage + 1}" ${currentPage === totalPages ? 'disabled' : ''}><i class="fa-solid fa-chevron-right"></i></button>`;
  paginationEl.innerHTML = html;

  // Add click handlers
  paginationEl.querySelectorAll('.page-btn').forEach(btn => {
    btn.addEventListener('click', (e) => {
      e.preventDefault();
      const page = parseInt(btn.dataset.page);
      if (page >= 1 && page <= totalPages) {
        paginationState.barangay.current = page;
        loadBarangayTable();
        window.scrollTo(0, 0);
      }
    });
  });
}

// ---------- Barangay Modal ----------
function openAddModal() {
  document.getElementById('barangayModalTitle').textContent = 'Add Barangay';
  document.getElementById('barangayEditId').value = '';
  document.getElementById('barangayName').value = '';
  document.getElementById('barangayDescription').value = '';
  document.getElementById('barangayLocation').value = '';
  document.getElementById('barangayLogoBase64').value = '';
  document.getElementById('barangayCoverImageBase64').value = '';
  document.getElementById('logoPreview').innerHTML = '<i class="fa-solid fa-image"></i><span>No image selected</span>';
  document.getElementById('coverImagePreview').innerHTML = '<i class="fa-solid fa-image"></i><span>No image selected</span>';

  populateOfficials(null);

  // Clear coordinates
  document.getElementById('barangayLatitude').value = '';
  document.getElementById('barangayLongitude').value = '';

  document.getElementById('barangaySaveBtn').innerHTML = '<i class="fa-solid fa-floppy-disk"></i> Save';
  document.getElementById('barangayModal').classList.add('active');
  setupLogoUpload();
  setupCoverImageUpload();
}

async function openEditModal(id) {
  document.getElementById('barangayModalTitle').textContent = 'Edit Barangay';
  document.getElementById('barangayEditId').value = id;
  document.getElementById('barangaySaveBtn').innerHTML = '<i class="fa-solid fa-floppy-disk"></i> Update';
  setupLogoUpload();
  setupCoverImageUpload();
  document.getElementById('barangayOfficialsList').replaceChildren();

  if (!supabaseClient) {
    showToast('Database connection unavailable', 'error');
    document.getElementById('barangayModal').classList.add('active');
    return;
  }

  try {
    const { data, error } = await supabaseClient
      .from('barangays')
      .select('*')
      .eq('id', id)
      .single();

    if (error) throw error;
    if (data) {
      // Basic info
      document.getElementById('barangayName').value = data.name || '';
      document.getElementById('barangayDescription').value = data.description || '';
      document.getElementById('barangayLocation').value = data.geographic_data || '';

      // Coordinates
      document.getElementById('barangayLatitude').value = data.latitude || '';
      document.getElementById('barangayLongitude').value = data.longitude || '';

      // Logo
      if (data.logo_url) {
        const preview = document.getElementById('logoPreview');
        preview.innerHTML = `<img src="${data.logo_url}" alt="logo" style="max-width: 100%; max-height: 100%; border-radius: 8px;">`;
      }

      // Cover image
      if (data.barangay_img) {
        const coverPreview = document.getElementById('coverImagePreview');
        coverPreview.innerHTML = `<img src="${data.barangay_img}" alt="cover" style="max-width: 100%; max-height: 100%; border-radius: 8px;">`;
      }

      // Officials
      populateOfficials(data.officials);
    }
  } catch (error) {
    console.error('Error fetching barangay for edit:', error);
    showToast('Failed to load barangay data from database', 'error');
  }

  document.getElementById('barangayModal').classList.add('active');
}

function closeBarangayModal() {
  document.getElementById('barangayModal').classList.remove('active');
  // Reset file inputs
  const logoInput = document.getElementById('barangayLogo');
  const coverInput = document.getElementById('barangayCoverImage');
  if (logoInput) logoInput.value = '';
  if (coverInput) coverInput.value = '';
}

// Check every page rather than relying on the currently filtered dashboard rows.
function normalizeRecordName(value) {
  return String(value || '').replace(/\s+/g, ' ').trim().toLowerCase();
}

async function ensureUniqueRecordName(table, column, value, editId, label) {
  const normalized = normalizeRecordName(value);
  const pageSize = 500;
  for (let offset = 0; ; offset += pageSize) {
    const { data, error } = await supabaseClient.from(table)
      .select(`id,${column}`).order('id', { ascending: true })
      .range(offset, offset + pageSize - 1);
    if (error) throw new Error('Unable to check for duplicate names. Please try again.');
    if (!Array.isArray(data)) throw new Error('Unable to check for duplicate names. Please try again.');
    if (data.some(record => String(record.id) !== String(editId || '') &&
        normalizeRecordName(record[column]) === normalized)) {
      throw new Error(`${label} already exists. Please use a different ${column === 'title' ? 'title' : 'name'}.`);
    }
    if (data.length < pageSize) return;
  }
}

function recordSaveError(error, label) {
  if (error?.code === '23505') {
    return `${label} already exists. Please use a different name or title.`;
  }
  return error.message || 'Please try again.';
}

async function saveBarangay() {
  if (document.getElementById('barangaySaveBtn').disabled) return;
  const editId = document.getElementById('barangayEditId').value;
  const name = document.getElementById('barangayName').value.trim();
  const description = document.getElementById('barangayDescription').value.trim();
  const geographicData = document.getElementById('barangayLocation').value.trim();
  const latitude = document.getElementById('barangayLatitude').value.trim();
  const longitude = document.getElementById('barangayLongitude').value.trim();
  const logoBase64 = document.getElementById('barangayLogoBase64').value;
  const coverImageBase64 = document.getElementById('barangayCoverImageBase64').value;

  if (document.getElementById('barangayOfficialsList').dataset.loadError === 'true') {
    showToast('Officials data could not be loaded. Repair the saved data before updating.', 'error');
    return;
  }
  const officials = collectOfficials();

  // Validate required fields
  if (!name) {
    showToast('Please enter the barangay name.', 'error');
    return;
  }

  if ((latitude || longitude) &&
      (!latitude || !longitude || !Number.isFinite(Number(latitude)) || !Number.isFinite(Number(longitude)) ||
       Number(latitude) < -90 || Number(latitude) > 90 || Number(longitude) < -180 || Number(longitude) > 180)) {
    showToast('Enter both valid latitude and longitude coordinates, or leave both blank.', 'error');
    return;
  }
  for (const official of officials) {
    if (official.file && !official.file.type.startsWith('image/')) {
      showToast('Official photos must be images.', 'error');
      return;
    }
  }

  const saveBtn = document.getElementById('barangaySaveBtn');
  saveBtn.innerHTML = '<span class="loading-spinner"></span> Saving...';
  saveBtn.disabled = true;

  try {
    if (!supabaseClient) {
      showToast('Database connection unavailable — cannot save', 'error');
      saveBtn.innerHTML = '<i class="fa-solid fa-floppy-disk"></i> Save';
      saveBtn.disabled = false;
      return;
    }

    await ensureUniqueRecordName('barangays', 'name', name, editId, 'A barangay with this name');

    const savedOfficials = [];
    for (const official of officials) {
      savedOfficials.push({
        name: official.name,
        position: official.position,
        image_url: official.file
          ? await uploadOfficialPhoto(official.file)
          : official.image_url
      });
    }

    const payload = {
      name,
      description: description || null,
      geographic_data: geographicData || null,
      latitude: latitude ? Number(latitude) : null,
      longitude: longitude ? Number(longitude) : null,
      officials: JSON.stringify(savedOfficials)
    };

    if (logoBase64 || document.getElementById('barangayLogo').files[0]) {
      payload.logo_url = await compressedImageDataUrl(document.getElementById('barangayLogo').files[0], logoBase64);
    }

    if (coverImageBase64 || document.getElementById('barangayCoverImage').files[0]) {
      payload.barangay_img = await compressedImageDataUrl(document.getElementById('barangayCoverImage').files[0], coverImageBase64);
    }

    if (editId) {
      const { error } = await supabaseClient.from('barangays').update(payload).eq('id', editId);
      if (error) throw error;
      showToast('Barangay updated successfully!', 'success');
      addNotification('Barangay Updated', `"${name}" has been updated`, 'success');
    } else {
      const { error } = await supabaseClient.from('barangays').insert(payload);
      if (error) throw error;
      showToast('Barangay added successfully!', 'success');
      addNotification('Barangay Added', `"${name}" has been created`, 'success');
    }

    closeBarangayModal();
    loadDashboardStats();
    loadDashboardBarangay();
    loadBarangayTable();
  } catch (error) {
    console.error('Error saving barangay:', error);
    showToast('Failed to save barangay: ' + recordSaveError(error, 'A barangay with this name'), 'error');
  } finally {
    saveBtn.innerHTML = '<i class="fa-solid fa-floppy-disk"></i> Save';
    saveBtn.disabled = false;
  }
}

// ---------- Helper Functions for Officials ----------
function collectOfficials() {
  return Array.from(document.querySelectorAll('#barangayOfficialsList .barangay-official-row')).map(row => ({
    name: row.querySelector('.official-name').value.trim(),
    position: row.querySelector('.official-position').value.trim(),
    image_url: row.dataset.imageUrl || null,
    file: row.querySelector('.official-photo-input').files[0] || null
  })).filter(official => official.name || official.image_url || official.file);
}

function populateOfficials(officialsJson) {
  const list = document.getElementById('barangayOfficialsList');
  list.replaceChildren();
  list.dataset.loadError = 'false';
  try {
    let officials = officialsJson;
    for (let depth = 0; typeof officials === 'string' && depth < 10; depth++) {
      const text = officials.trim();
      if (!text) { officials = []; break; }
      if (/^[\[{\"]/.test(text)) {
        officials = JSON.parse(text);
      } else {
        officials = text.split(/\r?\n|,/).map(name => name.trim()).filter(Boolean)
          .map(name => ({ name, position: 'Barangay Official' }));
      }
    }
    const rows = [];
    if (Array.isArray(officials)) {
      officials.forEach(official => {
        if (typeof official === 'string') official = { name: official, position: 'Barangay Official' };
        if (!official || typeof official.name !== 'string' || /^[\[{\"]/.test(official.name.trim())) {
          throw new Error('Invalid saved official');
        }
        rows.push({ ...official, position: typeof official.position === 'string'
          ? official.position : 'Barangay Official' });
      });
    } else if (officials && typeof officials === 'object') {
      const legacyRoles = [
        ['punong_barangay', 'Punong Barangay'],
        ['sk_chairman', 'SK Chairman'],
        ['barangay_secretary', 'Barangay Secretary'],
        ['barangay_treasurer', 'Barangay Treasurer']
      ];
      if (!legacyRoles.some(([key]) => key in officials) && !('kagawad' in officials)) {
        throw new Error('Unrecognized saved officials');
      }
      for (const [key, position] of legacyRoles) {
        if (officials[key]) rows.push({ name: officials[key], position });
      }
      (Array.isArray(officials.kagawad) ? officials.kagawad : []).forEach(name => {
        if (name) rows.push({ name, position: 'Barangay Kagawad' });
      });
    } else if (officials != null) {
      throw new Error('Invalid saved officials');
    }
    const positions = ['Punong Barangay', ...Array(7).fill('Barangay Kagawad'),
      'SK Chairman', 'Barangay Secretary', 'Barangay Treasurer'];
    for (const position of positions) {
      const index = rows.findIndex(official => official.position.trim().toLowerCase() === position.toLowerCase());
      addOfficialRow(index >= 0 ? rows.splice(index, 1)[0] : { name: '', position });
    }
    rows.forEach(official => addOfficialRow(official));
  } catch (error) {
    console.error('Error parsing officials JSON:', error);
    list.replaceChildren();
    list.dataset.loadError = 'true';
    list.textContent = 'Saved officials data is malformed and needs repair before updating.';
    showToast('Could not load officials safely. Saved data needs repair.', 'error');
  }
}

function addOfficialRow(official = {}, listId = 'barangayOfficialsList') {
  const row = document.createElement('div');
  row.className = 'barangay-official-row';
  row.dataset.imageUrl = official.image_url || '';
  row.innerHTML = `
    <div class="official-photo-controls">
      <div class="official-photo-preview"><i class="fa-solid fa-user"></i></div>
      <input type="file" class="official-photo-input" accept="image/*" hidden>
      <button type="button" class="btn btn-secondary btn-sm official-photo-button">Choose Photo</button>
      ${listId === 'barangayOfficialsList' ? '<button type="button" class="btn btn-secondary btn-sm official-photo-remove-button" hidden>Remove Photo</button>' : ''}
    </div>
    <div class="official-fields">
      <div class="form-group"><label>Name</label><input class="official-name" type="text" placeholder="Official's full name"></div>
      <div class="form-group"><label>Position</label><input class="official-position" type="text" placeholder="e.g. Punong Barangay"></div>
    </div>
    <button type="button" class="btn btn-sm btn-delete official-remove-button" title="Remove official" aria-label="Remove official"><i class="fa-solid fa-trash"></i></button>
  `;
  row.querySelector('.official-name').value = official.name || '';
  row.querySelector('.official-position').value = official.position || '';
  row.querySelector('.official-name').setAttribute('aria-label', 'Official name');
  row.querySelector('.official-position').setAttribute('aria-label', 'Official position');
  row.querySelector('.official-photo-button').setAttribute('aria-label', `Choose photo for ${official.name || 'official'}`);
  const fileInput = row.querySelector('.official-photo-input');
  const preview = row.querySelector('.official-photo-preview');
  const removePhotoButton = row.querySelector('.official-photo-remove-button');
  const updateRemovePhotoButton = () => {
    if (removePhotoButton) removePhotoButton.hidden = !row.dataset.imageUrl && !fileInput.files.length;
  };
  if (official.image_url) {
    const image = document.createElement('img');
    image.src = official.image_url;
    image.alt = `${official.name || 'Official'} photo`;
    preview.replaceChildren(image);
  }
  row.querySelector('.official-photo-button').addEventListener('click', () => fileInput.click());
  if (removePhotoButton) {
    removePhotoButton.setAttribute('aria-label', `Remove photo for ${official.name || 'official'}`);
    removePhotoButton.addEventListener('click', () => {
      row.dataset.imageUrl = '';
      fileInput.value = '';
      const placeholder = document.createElement('i');
      placeholder.className = 'fa-solid fa-user';
      preview.replaceChildren(placeholder);
      updateRemovePhotoButton();
    });
  }
  updateRemovePhotoButton();
  bindFileDropZone(fileInput, row.querySelector('.official-photo-controls'));
  fileInput.addEventListener('change', () => {
    const file = fileInput.files[0];
    if (!file) return;
    updateRemovePhotoButton();
    const reader = new FileReader();
    reader.onload = () => {
      if (fileInput.files[0] !== file) return;
      const image = document.createElement('img');
      image.src = reader.result;
      image.alt = 'Selected official photo';
      preview.replaceChildren(image);
    };
    reader.readAsDataURL(file);
  });
  row.querySelector('.official-remove-button').addEventListener('click', () => row.remove());
  document.getElementById(listId).appendChild(row);
}

async function uploadOfficialPhoto(file, bucket = 'barangay-officials') {
  file = await compressImageForUpload(file, 5 * 1024 * 1024);
  if (file.size > 5 * 1024 * 1024) throw new Error('Official photo is still over 5 MB after compression. Please choose a smaller image.');
  const safeName = file.name.replace(/[^a-zA-Z0-9._-]/g, '_');
  const path = `officials/${Date.now()}-${Math.random().toString(36).slice(2, 10)}-${safeName}`;
  const { error } = await supabaseClient.storage.from(bucket).upload(path, file, {
    contentType: file.type,
    upsert: false
  });
  if (error) throw error;
  const { data } = supabaseClient.storage.from(bucket).getPublicUrl(path);
  return data.publicUrl;
}

const ABOUT_FIELDS = {
  vision: 'aboutVision',
  mission: 'aboutMission',
  history: 'aboutHistory',
  geography: 'aboutGeography'
};
const ABOUT_IMAGE_FIELDS = { history: 'history_image_path', geography: 'geography_image_path' };
const aboutImagePaths = { history: '', geography: '' };
const aboutPendingImages = { history: null, geography: null };
let charterFiles = [];
let pendingCharterFiles = [];
const CHARTER_FILE_EXTENSIONS = /\.(pdf|doc|docx|xls|xlsx|png|jpe?g|webp)$/i;
const CHARTER_CONTENT_TYPES = {
  pdf: 'application/pdf',
  doc: 'application/msword',
  docx: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  xls: 'application/vnd.ms-excel',
  xlsx: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  png: 'image/png',
  jpg: 'image/jpeg',
  jpeg: 'image/jpeg',
  webp: 'image/webp'
};

function renderAboutImage(section) {
  const prefix = section === 'history' ? 'aboutHistoryImage' : 'aboutGeographyImage';
  const preview = document.getElementById(`${prefix}Preview`);
  const remove = document.getElementById(`${prefix}Remove`);
  const status = document.getElementById(`${prefix}Status`);
  preview.replaceChildren();
  const file = aboutPendingImages[section];
  const path = aboutImagePaths[section];
  preview.hidden = !file && !path;
  remove.hidden = !file && !path;
  status.textContent = file
    ? `${file.name} — ready to save`
    : path ? 'Current image is shown below.' : 'JPG, PNG, or WebP. Large images are compressed when saved.';
  if (!file && !path) {
    return;
  }
  const image = document.createElement('img');
  image.alt = `${section} preview`;
  preview.appendChild(image);
  if (file) {
    const reader = new FileReader();
    reader.onload = () => {
      if (aboutPendingImages[section] === file) image.src = reader.result;
    };
    reader.readAsDataURL(file);
  } else {
    image.src = supabaseClient.storage.from('municipal-profile-images').getPublicUrl(path).data.publicUrl;
  }
}

function selectAboutImage(section, file) {
  if (!file || !Object.hasOwn(ABOUT_IMAGE_FIELDS, section)) return;
  if (!['image/jpeg', 'image/png', 'image/webp'].includes(file.type) || !file.size) {
    showToast('Choose a JPG, PNG, or WebP image.', 'error');
    document.getElementById(section === 'history' ? 'aboutHistoryImage' : 'aboutGeographyImage').value = '';
    return;
  }
  aboutPendingImages[section] = file;
  document.getElementById(section === 'history' ? 'aboutHistoryImage' : 'aboutGeographyImage').value = '';
  renderAboutImage(section);
}

function clearAboutImage(section) {
  if (!Object.hasOwn(ABOUT_IMAGE_FIELDS, section)) return;
  aboutPendingImages[section] = null;
  aboutImagePaths[section] = '';
  renderAboutImage(section);
}

async function uploadAboutImage(section, originalFile) {
  const file = await compressImageForUpload(originalFile, 5 * 1024 * 1024);
  if (file.size > 5 * 1024 * 1024) throw new Error('Image is still over 5 MB after compression.');
  const safeName = file.name.replace(/[^a-zA-Z0-9._-]/g, '_');
  const path = `${section}/${Date.now()}-${Math.random().toString(36).slice(2, 10)}-${safeName}`;
  const { error } = await supabaseClient.storage.from('municipal-profile-images').upload(path, file, {
    contentType: file.type, upsert: false
  });
  if (error) throw error;
  return path;
}

function addCharterFiles(fileList) {
  for (const file of Array.from(fileList || [])) {
    if (!CHARTER_FILE_EXTENSIONS.test(file.name) || file.size === 0) {
      showToast(`Choose a nonempty PDF, Word, Excel, or image file: ${file.name}`, 'error');
      continue;
    }
    pendingCharterFiles.push(file);
  }
  document.getElementById('aboutCharterUpload').value = '';
  renderCharterFiles();
}

function renderCharterFiles() {
  const list = document.getElementById('aboutCharterFiles');
  list.replaceChildren();
  const entries = [
    ...charterFiles.map((file, index) => ({ file, index, pending: false })),
    ...pendingCharterFiles.map((file, index) => ({ file, index, pending: true }))
  ];
  if (!entries.length) {
    const empty = document.createElement('p');
    empty.className = 'form-help-text';
    empty.textContent = 'No Charter files uploaded yet.';
    list.appendChild(empty);
    return;
  }
  for (const { file, index, pending } of entries) {
    const row = document.createElement('div');
    row.className = 'charter-file-row';
    const fileIcon = document.createElement('span');
    fileIcon.className = 'charter-file-icon';
    fileIcon.setAttribute('aria-hidden', 'true');
    const icon = document.createElement('i');
    const extension = file.name.split('.').pop().toLowerCase();
    icon.className = ['jpg', 'jpeg', 'png', 'webp'].includes(extension)
      ? 'fa-solid fa-file-image'
      : extension === 'pdf' ? 'fa-solid fa-file-pdf' : 'fa-solid fa-file-lines';
    fileIcon.appendChild(icon);
    row.appendChild(fileIcon);
    const details = document.createElement('div');
    details.className = 'charter-file-details';
    const name = document.createElement('span');
    name.className = 'charter-file-name';
    name.textContent = file.name;
    name.title = file.name;
    details.appendChild(name);
    const status = document.createElement('small');
    if (pending) {
      status.textContent = file.type.startsWith('image/') && file.size > 10 * 1024 * 1024
        ? 'Will compress when saved'
        : 'Ready to upload';
    } else {
      status.textContent = 'Uploaded';
    }
    details.appendChild(status);
    row.appendChild(details);
    const actions = document.createElement('div');
    actions.className = 'charter-file-actions';
    if (!pending && file.path) {
      const link = document.createElement('a');
      const publicUrl = supabaseClient.storage.from('municipal-charter').getPublicUrl(file.path).data.publicUrl;
      link.href = publicUrl;
      link.target = '_blank';
      link.rel = 'noopener noreferrer';
      link.className = 'charter-view-button';
      link.setAttribute('aria-label', `View ${file.name}`);
      link.innerHTML = '<i class="fa-solid fa-arrow-up-right-from-square" aria-hidden="true"></i><span>View file</span>';
      actions.appendChild(link);
    }
    const remove = document.createElement('button');
    remove.type = 'button';
    remove.className = 'btn btn-sm btn-delete';
    remove.textContent = 'Remove';
    remove.addEventListener('click', () => {
      if (pending) pendingCharterFiles.splice(index, 1);
      else charterFiles.splice(index, 1);
      renderCharterFiles();
    });
    actions.appendChild(remove);
    row.appendChild(actions);
    list.appendChild(row);
  }
}

async function uploadCharterFile(file) {
  const originalExtension = file.name.split('.').pop().toLowerCase();
  if (['jpg', 'jpeg', 'png', 'webp'].includes(originalExtension)) {
    if (!file.type.startsWith('image/')) {
      file = new File([file], file.name, { type: CHARTER_CONTENT_TYPES[originalExtension], lastModified: file.lastModified });
    }
    file = await compressImageForUpload(file, 10 * 1024 * 1024);
    if (file.size > 10 * 1024 * 1024) {
      throw new Error(`Charter image is still over 10 MB after compression: ${file.name}`);
    }
  }
  const safeName = file.name.replace(/[^a-zA-Z0-9._-]/g, '_');
  const extension = file.name.split('.').pop().toLowerCase();
  const path = `charter/${Date.now()}-${Math.random().toString(36).slice(2, 10)}-${safeName}`;
  const { error } = await supabaseClient.storage.from('municipal-charter').upload(path, file, {
    contentType: CHARTER_CONTENT_TYPES[extension], upsert: false
  });
  if (error) throw error;
  return { name: file.name, path };
}

function selectAboutSection(sectionId) {
  const buttons = document.querySelectorAll('#aboutUsPage [data-about-section]');
  if (!Array.from(buttons).some(button => button.dataset.aboutSection === sectionId)) return;
  buttons.forEach(button => button.setAttribute('aria-pressed', String(button.dataset.aboutSection === sectionId)));
  document.querySelectorAll('#aboutUsPage .about-category-panel').forEach(panel => {
    panel.hidden = panel.id !== sectionId;
  });
}

async function loadAboutUs() {
  if (!supabaseClient) return;
  try {
    const { data, error } = await supabaseClient.from('municipal_profile').select('*').eq('id', 1).maybeSingle();
    if (error) throw error;
    for (const [column, id] of Object.entries(ABOUT_FIELDS)) {
      document.getElementById(id).value = column === 'vision'
        ? (data?.vision || data?.vision_mission || '')
        : (data?.[column] || '');
    }
    for (const [section, column] of Object.entries(ABOUT_IMAGE_FIELDS)) {
      aboutImagePaths[section] = data?.[column] || '';
      aboutPendingImages[section] = null;
      renderAboutImage(section);
    }
    charterFiles = Array.isArray(data?.citizens_charter_files) ? data.citizens_charter_files : [];
    pendingCharterFiles = [];
    renderCharterFiles();
    const list = document.getElementById('municipalOfficialsList');
    list.replaceChildren();
    for (const official of sortMunicipalOfficials(Array.isArray(data?.officials) ? data.officials : [])) {
      addMunicipalOfficialRow(official);
    }
  } catch (error) {
    console.error('Error loading About Us:', error);
    showToast('Failed to load About Us: ' + error.message, 'error');
  }
}

function addMunicipalOfficialRow(official = {}) {
  addOfficialRow(official, 'municipalOfficialsList');
  document.querySelector('#municipalOfficialsList .barangay-official-row:last-child .official-position').placeholder = 'e.g. Municipal Mayor';
}

function sortMunicipalOfficials(officials) {
  const isMayor = official => /\bmayor\b/i.test(official.position || '') && !/\bvice\b/i.test(official.position || '');
  return [...officials.filter(isMayor), ...officials.filter(official => !isMayor(official))];
}

async function saveAboutUs() {
  if (!supabaseClient) {
    showToast('Database connection unavailable', 'error');
    return;
  }
  const officials = Array.from(document.querySelectorAll('#municipalOfficialsList .barangay-official-row')).map(row => ({
    name: row.querySelector('.official-name').value.trim(),
    position: row.querySelector('.official-position').value.trim(),
    image_url: row.dataset.imageUrl || null,
    file: row.querySelector('.official-photo-input').files[0] || null
  }));
  if (officials.some(item => !item.name || !item.position)) {
    selectAboutSection('aboutOfficialsSection');
    const missingField = Array.from(document.querySelectorAll('#municipalOfficialsList .official-name, #municipalOfficialsList .official-position')).find(input => !input.value.trim());
    missingField?.focus();
    showToast('Fill in the name and position for each official.', 'error');
    return;
  }
  if (officials.some(item => item.file && !['image/jpeg', 'image/png', 'image/webp', 'image/gif'].includes(item.file.type))) {
    selectAboutSection('aboutOfficialsSection');
    showToast('Official photos must be JPG, PNG, WebP, or GIF images.', 'error');
    return;
  }
  const button = document.getElementById('aboutSaveBtn');
  if (button.disabled) return;
  const saveStatus = document.getElementById('aboutSaveStatus');
  saveStatus.textContent = 'Saving your changes. Please keep this page open.';
  document.querySelectorAll('#aboutUsPage .form-section').forEach(section => { section.inert = true; });
  button.disabled = true;
  button.innerHTML = '<span class="loading-spinner"></span> Saving...';
  try {
    const payload = { id: 1 };
    for (const [column, id] of Object.entries(ABOUT_FIELDS)) payload[column] = document.getElementById(id).value.trim();
    for (const [section, column] of Object.entries(ABOUT_IMAGE_FIELDS)) {
      payload[column] = aboutPendingImages[section]
        ? await uploadAboutImage(section, aboutPendingImages[section])
        : aboutImagePaths[section];
    }
    payload.vision_mission = '';
    payload.citizens_charter_files = [...charterFiles];
    for (const file of pendingCharterFiles) {
      payload.citizens_charter_files.push(await uploadCharterFile(file));
    }
    payload.officials = [];
    for (const official of sortMunicipalOfficials(officials)) {
      payload.officials.push({
        name: official.name,
        position: official.position,
        image_url: official.file ? await uploadOfficialPhoto(official.file, 'municipal-officials') : official.image_url
      });
    }
    const { error } = await supabaseClient.from('municipal_profile').upsert(payload, { onConflict: 'id' });
    if (error) throw error;
    showToast('About Us updated successfully!', 'success');
    await loadAboutUs();
    saveStatus.textContent = 'Changes saved. About Us is up to date.';
  } catch (error) {
    console.error('Error saving About Us:', error);
    saveStatus.textContent = 'Changes could not be saved. Please try again.';
    showToast('Failed to save About Us: ' + error.message, 'error');
  } finally {
    button.disabled = false;
    document.querySelectorAll('#aboutUsPage .form-section').forEach(section => { section.inert = false; });
    button.innerHTML = '<i class="fa-solid fa-floppy-disk" aria-hidden="true"></i> Save changes';
  }
}

// ---------- Delete Barangay ----------
function openDeleteBarangay(id, name) {
  deleteTarget = id;
  deleteType = 'barangay';
  document.getElementById('deleteMessage').textContent = `Are you sure you want to delete "${name}"? This action cannot be undone.`;
  document.getElementById('deleteModal').classList.add('active');
}

function closeDeleteModal() {
  document.getElementById('deleteModal').classList.remove('active');
  deleteTarget = null;
  deleteType = null;
}

async function confirmDelete() {
  if (!deleteTarget || !deleteType) return;

  const deleteBtn = document.getElementById('deleteConfirmBtn');
  deleteBtn.innerHTML = '<span class="loading-spinner"></span> Deleting...';
  deleteBtn.disabled = true;

  try {
    if (deleteType === 'barangay') {
      if (!supabaseClient) {
        showToast('Database connection unavailable', 'error');
        deleteBtn.innerHTML = '<i class="fa-solid fa-trash"></i> Delete';
        deleteBtn.disabled = false;
        return;
      }
      const { error } = await supabaseClient.from('barangays').delete().eq('id', deleteTarget);
      if (error) throw error;
      showToast('Barangay deleted successfully!', 'success');
      addNotification('Barangay Deleted', 'A barangay record has been deleted', 'warning');
      loadDashboardStats();
      loadDashboardBarangay();
      loadBarangayTable();
    } else if (deleteType === 'news') {
      if (!supabaseClient) {
        showToast('Database connection unavailable', 'error');
        deleteBtn.innerHTML = '<i class="fa-solid fa-trash"></i> Delete';
        deleteBtn.disabled = false;
        return;
      }
      const { error } = await supabaseClient.from('news').delete().eq('id', deleteTarget);
      if (error) throw error;
      showToast('News article deleted successfully!', 'success');
      addNotification('News Deleted', 'A news article has been removed', 'warning');
      loadDashboardStats();
      loadNews();
    } else if (deleteType === 'transparency') {
      if (!supabaseClient) {
        showToast('Database connection unavailable', 'error');
        deleteBtn.innerHTML = '<i class="fa-solid fa-trash"></i> Delete';
        deleteBtn.disabled = false;
        return;
      }

      // Find the record to get its type
      const record = allTransparency.find(t => t.id === deleteTarget);
      if (!record || !canAccessTransparency(record.type)) throw new Error('You cannot manage this transparency category.');
      if (record) {
        const tableName = `transparency_${canonicalTransparencyType(record.type)}`;
        const { error } = await supabaseClient.from(tableName).delete().eq('id', deleteTarget);
        if (error) throw error;
      }

      showToast('Transparency record deleted successfully!', 'success');
      addNotification('Transparency Deleted', 'A transparency record has been removed', 'warning');
      loadTransparency();
    } else if (deleteType === 'tourist') {
      if (!supabaseClient) {
        showToast('Database connection unavailable', 'error');
        deleteBtn.innerHTML = '<i class="fa-solid fa-trash"></i> Delete';
        deleteBtn.disabled = false;
        return;
      }

      // Try different table names
      const tableNames = [
        'tourist_guides',
        'tourist_guide',
        'tourist_destinations',
        'tourist_spots',
        'places',
        'tourist_places'
      ];

      let deleted = false;
      for (const tableName of tableNames) {
      if (!canAccessTransparency(tableName.replace('transparency_', ''))) continue;
        try {
          const { error } = await supabaseClient.from(tableName).delete().eq('id', deleteTarget);
          if (!error) {
            deleted = true;
            break;
          }
        } catch (e) {
          continue;
        }
      }

      if (deleted) {
        showToast('Tourist destination deleted successfully!', 'success');
        addNotification('Tourist Deleted', 'A destination has been removed', 'warning');
        loadTourist();
      } else {
        throw new Error('Could not delete from any table');
      }
    } else if (deleteType === 'place-review') {
      if (!supabaseClient) {
        showToast('Database connection unavailable', 'error');
        deleteBtn.innerHTML = '<i class="fa-solid fa-trash"></i> Delete';
        deleteBtn.disabled = false;
        return;
      }

      try {
        const { error } = await supabaseClient.from('place_reviews').delete().eq('id', deleteTarget);
        if (error) {
          throw error;
        }
        showToast('Review deleted successfully!', 'success');
        addNotification('Review Deleted', 'A place review has been removed', 'warning');
        loadPlaceReviews();
      } catch (error) {
        console.error('Error deleting review:', error);
        throw error;
      }
    } else if (deleteType === 'hotline') {
      if (!supabaseClient) {
        showToast('Database connection unavailable', 'error');
        deleteBtn.innerHTML = '<i class="fa-solid fa-trash"></i> Delete';
        deleteBtn.disabled = false;
        return;
      }
      const { error } = await supabaseClient.from('hotlines').delete().eq('id', deleteTarget);
      if (error) throw error;
      showToast('Hotline deleted successfully!', 'success');
      addNotification('Hotline Deleted', 'A hotline record has been removed', 'warning');
      loadHotline();
    }
  } catch (error) {
    console.error('Error deleting:', error);
    showToast('Failed to delete: ' + error.message, 'error');
  } finally {
    deleteBtn.innerHTML = '<i class="fa-solid fa-trash"></i> Delete';
    deleteBtn.disabled = false;
    closeDeleteModal();
  }
}

// Close modals on overlay click
document.addEventListener('click', (e) => {
  if (e.target.classList.contains('modal-overlay') && e.target.classList.contains('active')) {
    if (e.target.id === 'appointmentAvailabilityModal') {
      closeAppointmentAvailabilityModal();
      return;
    }
    e.target.classList.remove('active');
    deleteTarget = null;
    deleteType = null;
  }
});

// Close modals on Escape key
document.addEventListener('keydown', (e) => {
  if (e.key === 'Escape') {
    if (document.getElementById('imageLightbox')?.classList.contains('active')) return;
    if (document.getElementById('appointmentAvailabilityModal')?.classList.contains('active')) {
      closeAppointmentAvailabilityModal();
    }
    document.querySelectorAll('.modal-overlay.active').forEach(m => m.classList.remove('active'));
    deleteTarget = null;
    deleteType = null;
  }
});

// ============================================================
// NEWS CRUD
// ============================================================
const galleryImages = { news: [], tourist: [] };

function setGalleryImages(kind, record = {}) {
  const urls = Array.isArray(record.image_urls) && record.image_urls.length
    ? record.image_urls
    : (record.image_url ? [record.image_url] : []);
  galleryImages[kind] = urls.filter(url => typeof url === 'string' && url.trim()).slice(0, 5).map(url => ({ url }));
  renderGalleryImages(kind);
}

function addGalleryImages(kind, files) {
  const input = document.getElementById(kind === 'news' ? 'newsImage' : 'touristImage');
  const selected = Array.from(files || []);
  input.value = '';
  if (galleryImages[kind].length + selected.length > 5) {
    showToast('You can upload up to 5 images.', 'error');
    return;
  }
  for (const file of selected) {
    const validation = validateFileUpload(file, ['image/jpeg', 'image/png', 'image/webp', 'image/gif']);
    if (!validation.valid || !file.size) {
      showToast('Image upload error: ' + (validation.valid ? 'The image is empty.' : validation.error), 'error');
      return;
    }
  }
  galleryImages[kind].push(...selected.map(file => ({ file })));
  renderGalleryImages(kind);
}

function renderGalleryImages(kind) {
  const preview = document.getElementById(kind === 'news' ? 'newsImagePreview' : 'touristImagePreview');
  preview.replaceChildren();
  if (!galleryImages[kind].length) {
    preview.textContent = 'No images selected';
    return;
  }
  galleryImages[kind].forEach((item, index) => {
    const tile = document.createElement('div');
    tile.className = 'image-gallery-tile';
    const image = document.createElement('img');
    image.alt = `Image ${index + 1}`;
    tile.appendChild(image);
    if (item.url) image.src = item.url;
    else {
      const reader = new FileReader();
      reader.onload = () => { if (tile.isConnected) image.src = reader.result; };
      reader.readAsDataURL(item.file);
    }
    const label = document.createElement('span');
    label.textContent = index === 0 ? 'Cover' : `${index + 1}`;
    tile.appendChild(label);
    const remove = document.createElement('button');
    remove.type = 'button';
    remove.className = 'remove-image-btn';
    remove.title = 'Remove image';
    remove.setAttribute('aria-label', `Remove image ${index + 1}`);
    remove.innerHTML = '<i class="fa-solid fa-xmark"></i>';
    remove.addEventListener('click', () => {
      galleryImages[kind].splice(index, 1);
      renderGalleryImages(kind);
    });
    tile.appendChild(remove);
    preview.appendChild(tile);
  });
}

async function uploadGalleryImages(kind) {
  const bucket = kind === 'news' ? 'NEWS' : 'places-images';
  const urls = [];
  for (const item of galleryImages[kind]) {
    if (item.url) {
      urls.push(item.url);
      continue;
    }
    const file = await compressImageForUpload(item.file, 5 * 1024 * 1024);
    const validation = validateFileUpload(file, ['image/jpeg', 'image/png', 'image/webp', 'image/gif'], 5 * 1024 * 1024);
    if (!validation.valid) throw new Error(validation.error);
    const safeName = file.name.replace(/[^a-zA-Z0-9._-]/g, '_');
    const path = `${kind === 'news' ? 'news' : 'destination/touristguide'}/${Date.now()}-${Math.random().toString(36).slice(2, 10)}-${safeName}`;
    const { error } = await supabaseClient.storage.from(bucket).upload(path, file, {
      contentType: file.type, upsert: false
    });
    if (error) throw error;
    urls.push(supabaseClient.storage.from(bucket).getPublicUrl(path).data.publicUrl);
  }
  return urls;
}

async function loadNews() {
  const tbody = document.getElementById('newsTableBody');
  if (!tbody) return;

  let news = [];

  if (!supabaseClient) {
    const colSpan = tbody.closest('table').querySelectorAll('th').length;
    tbody.innerHTML = `<tr><td colspan="${colSpan}" class="empty-state">Database connection unavailable</td></tr>`;
    return;
  }

  try {
    const { data, error } = await supabaseClient
      .from('news')
      .select('*')
      .order('created_at', { ascending: false });

    if (error) throw error;
    news = data || [];
  } catch (error) {
    console.error('Error loading news:', error);
    showToast('Failed to load news from database', 'error');
  }

  renderNewsTable(news);
}

async function renderNewsTable(newsData) {
  const tbody = document.getElementById('newsTableBody');
  tableExportRows.newsTableBody = newsData;
  const colSpan = tbody.closest('table').querySelectorAll('th').length;

  const totalItems = newsData.length;
  const totalPages = Math.ceil(totalItems / ITEMS_PER_PAGE);
  const currentPage = paginationState.news.current;

  if (currentPage > totalPages && totalPages > 0) {
    paginationState.news.current = 1;
    renderNewsTable(newsData);
    return;
  }

  if (newsData.length === 0) {
    tbody.innerHTML = `<tr><td colspan="${colSpan}" class="empty-state">No news articles found</td></tr>`;
    renderNewsPagination(0);
    return;
  }

  const startIdx = (currentPage - 1) * ITEMS_PER_PAGE;
  const endIdx = startIdx + ITEMS_PER_PAGE;
  const pageData = newsData.slice(startIdx, endIdx);

  tbody.innerHTML = '';
  pageData.forEach(n => {
    const tr = document.createElement('tr');

    const tdTitle = document.createElement('td');
    tdTitle.style.fontWeight = '600';

    // Show scheduled indicator if post is scheduled
    if (n.scheduled_at && !n.is_published) {
      const scheduledDate = new Date(n.scheduled_at);
      const now = new Date();
      if (scheduledDate > now) {
        const badge = document.createElement('span');
        badge.style.cssText = 'display: inline-block; background: #3b82f6; color: white; padding: 2px 8px; border-radius: 4px; font-size: 11px; margin-right: 8px; font-weight: 600;';
        badge.textContent = '📅 SCHEDULED';
        tdTitle.appendChild(badge);
      }
    }

    const titleSpan = document.createElement('span');
    titleSpan.textContent = n.title || 'N/A';
    tdTitle.appendChild(titleSpan);

    const tdDescription = document.createElement('td');
    const desc = (n.description || 'No description').substring(0, 50) + '...';
    tdDescription.textContent = desc;
    tdDescription.style.color = '#6b7280';
    tdDescription.style.fontSize = '13px';

    const tdImage = document.createElement('td');
    if (n.image_url) {
      const img = document.createElement('img');
      img.src = n.image_url;
      img.style.width = '50px';
      img.style.height = '50px';
      img.style.objectFit = 'cover';
      img.style.borderRadius = '4px';
      tdImage.appendChild(img);
    } else {
      const placeholder = document.createElement('div');
      placeholder.style.width = '50px';
      placeholder.style.height = '50px';
      placeholder.style.backgroundColor = '#e5e7eb';
      placeholder.style.borderRadius = '4px';
      placeholder.style.display = 'flex';
      placeholder.style.alignItems = 'center';
      placeholder.style.justifyContent = 'center';
      placeholder.innerHTML = '<i class="fa-solid fa-image" style="color: #9ca3af;"></i>';
      tdImage.appendChild(placeholder);
    }

    const tdPublished = document.createElement('td');
    tdPublished.textContent = formatDate(n.created_at);

    const tdCreated = document.createElement('td');
    tdCreated.textContent = formatDate(n.created_at);
    tdCreated.style.fontSize = '13px';

    const tdActions = document.createElement('td');
    const actionsDiv = document.createElement('div');
    actionsDiv.className = 'action-btns';

    const editBtn = document.createElement('button');
    editBtn.className = 'btn btn-sm btn-edit btn-icon';
    editBtn.title = 'Edit';
    editBtn.innerHTML = '<i class="fa-solid fa-pen-to-square"></i>';
    editBtn.addEventListener('click', () => openEditNewsModal(n.id));

    const deleteBtn = document.createElement('button');
    deleteBtn.className = 'btn btn-sm btn-delete btn-icon';
    deleteBtn.title = 'Delete';
    deleteBtn.innerHTML = '<i class="fa-solid fa-trash"></i>';
    deleteBtn.addEventListener('click', () => openDeleteNews(n.id, n.title || 'News Article'));

    actionsDiv.appendChild(editBtn);
    actionsDiv.appendChild(deleteBtn);
    tdActions.appendChild(actionsDiv);

    tr.appendChild(tdTitle);
    tr.appendChild(tdDescription);
    tr.appendChild(tdImage);
    tr.appendChild(tdPublished);
    tr.appendChild(tdCreated);
    tr.appendChild(tdActions);

    tbody.appendChild(tr);
  });

  if (document.getElementById('totalNews')) {
    document.getElementById('totalNews').textContent = newsData.length;
  }

  renderNewsPagination(totalItems);
}

function renderNewsPagination(totalItems) {
  const paginationEl = document.getElementById('newsPagination');
  const showingEl = document.getElementById('newsShowing');
  if (!paginationEl || !showingEl) return;

  const totalPages = Math.ceil(totalItems / ITEMS_PER_PAGE);
  const currentPage = paginationState.news.current;
  paginationState.news.total = totalPages;
  showingEl.textContent = `Showing ${Math.min(currentPage * ITEMS_PER_PAGE, totalItems)} of ${totalItems} entries`;

  if (totalPages <= 1) {
    paginationEl.innerHTML = '';
    return;
  }

  let html = `<button class="page-btn prev-btn" data-page="${currentPage - 1}" ${currentPage === 1 ? 'disabled' : ''}><i class="fa-solid fa-chevron-left"></i></button>`;

  const maxButtons = 5;
  let startPage = Math.max(1, currentPage - Math.floor(maxButtons / 2));
  let endPage = Math.min(totalPages, startPage + maxButtons - 1);
  if (endPage - startPage + 1 < maxButtons) {
    startPage = Math.max(1, endPage - maxButtons + 1);
  }

  if (startPage > 1) {
    html += `<button class="page-btn" data-page="1">1</button>`;
    if (startPage > 2) html += `<span class="page-ellipsis">...</span>`;
  }

  for (let i = startPage; i <= endPage; i++) {
    html += `<button class="page-btn ${i === currentPage ? 'active' : ''}" data-page="${i}">${i}</button>`;
  }

  if (endPage < totalPages) {
    if (endPage < totalPages - 1) html += `<span class="page-ellipsis">...</span>`;
    html += `<button class="page-btn" data-page="${totalPages}">${totalPages}</button>`;
  }

  html += `<button class="page-btn next-btn" data-page="${currentPage + 1}" ${currentPage === totalPages ? 'disabled' : ''}><i class="fa-solid fa-chevron-right"></i></button>`;
  paginationEl.innerHTML = html;

  paginationEl.querySelectorAll('.page-btn').forEach(btn => {
    btn.addEventListener('click', (e) => {
      e.preventDefault();
      const page = parseInt(btn.dataset.page);
      if (page >= 1 && page <= totalPages) {
        paginationState.news.current = page;
        loadNews();
        window.scrollTo(0, 0);
      }
    });
  });
}

function openNewsModal() {
  document.getElementById('newsModalTitle').textContent = 'Add News';
  document.getElementById('newsEditId').value = '';
  document.getElementById('newsTitle').value = '';
  document.getElementById('newsContent').value = '';
  document.getElementById('newsCategory').value = '';
  document.getElementById('newsImage').value = '';
  setGalleryImages('news');
  document.getElementById('newsScheduleCheckbox').checked = false;
  document.getElementById('newsScheduleDate').value = '';
  document.getElementById('newsScheduleTime').value = '';
  document.getElementById('newsScheduledAt').value = '';
  document.getElementById('newsScheduleSection').style.display = 'none';
  document.getElementById('newsScheduleCheckbox').checked = false;
  document.getElementById('newsScheduleSection').style.display = 'none';
  document.getElementById('newsScheduleDate').value = '';
  document.getElementById('newsScheduleTime').value = '';
  document.getElementById('newsScheduledAt').value = '';
  document.getElementById('schedulePreview').textContent = '';
  document.getElementById('newsSaveBtn').innerHTML = '<i class="fa-solid fa-floppy-disk"></i> Save';
  document.getElementById('newsSaveBtn').disabled = false;
  document.getElementById('newsModal').classList.add('active');
}

async function openEditNewsModal(id) {
  document.getElementById('newsModalTitle').textContent = 'Edit News';
  document.getElementById('newsEditId').value = id;
  document.getElementById('newsSaveBtn').innerHTML = '<i class="fa-solid fa-floppy-disk"></i> Update';
  document.getElementById('newsSaveBtn').disabled = false;

  if (!supabaseClient) {
    showToast('Database connection unavailable', 'error');
    document.getElementById('newsModal').classList.add('active');
    return;
  }

  try {
    const { data, error } = await supabaseClient.from('news').select('*').eq('id', id).single();
    if (error) throw error;
    if (data) {
      document.getElementById('newsTitle').value = data.title || '';
      document.getElementById('newsContent').value = data.description || '';
      document.getElementById('newsCategory').value = data.category || '';
      document.getElementById('newsImage').value = '';
      setGalleryImages('news', data);

      // Load scheduling data
      if (data.scheduled_at) {
        const scheduledDate = new Date(data.scheduled_at);
        const dateStr = scheduledDate.toISOString().split('T')[0];
        const timeStr = scheduledDate.toTimeString().slice(0, 5);
        document.getElementById('newsScheduleCheckbox').checked = true;
        document.getElementById('newsScheduleDate').value = dateStr;
        document.getElementById('newsScheduleTime').value = timeStr;
        document.getElementById('newsScheduledAt').value = data.scheduled_at;
        document.getElementById('newsScheduleSection').style.display = 'block';
        updateSchedulePreview();
      } else {
        document.getElementById('newsScheduleCheckbox').checked = false;
        document.getElementById('newsScheduleDate').value = '';
        document.getElementById('newsScheduleTime').value = '';
        document.getElementById('newsScheduledAt').value = '';
        document.getElementById('newsScheduleSection').style.display = 'none';
      }
    }
  } catch (error) {
    console.error('Error loading news:', error);
    showToast('Failed to load news data', 'error');
  }

  document.getElementById('newsModal').classList.add('active');
}

function closeNewsModal() {
  document.getElementById('newsModal').classList.remove('active');
  document.getElementById('newsScheduleCheckbox').checked = false;
  document.getElementById('newsScheduleSection').style.display = 'none';
}

function toggleNewsSchedule() {
  const checkbox = document.getElementById('newsScheduleCheckbox');
  const scheduleSection = document.getElementById('newsScheduleSection');
  scheduleSection.style.display = checkbox.checked ? 'block' : 'none';

  if (!checkbox.checked) {
    document.getElementById('newsScheduleDate').value = '';
    document.getElementById('newsScheduleTime').value = '';
    document.getElementById('newsScheduledAt').value = '';
  }
}

function updateSchedulePreview() {
  const dateInput = document.getElementById('newsScheduleDate').value;
  const timeInput = document.getElementById('newsScheduleTime').value;
  const previewEl = document.getElementById('schedulePreview');

  if (dateInput && timeInput) {
    const date = new Date(dateInput + 'T' + timeInput);
    const previewText = 'Will be published on ' + date.toLocaleString();
    if (previewEl.textContent !== previewText) {
      previewEl.textContent = previewText;
    }
    const isoString = date.toISOString();
    const hiddenField = document.getElementById('newsScheduledAt');
    if (hiddenField.value !== isoString) {
      hiddenField.value = isoString;
    }
  } else {
    if (previewEl.textContent !== '') {
      previewEl.textContent = '';
    }
    const hiddenField = document.getElementById('newsScheduledAt');
    if (hiddenField.value !== '') {
      hiddenField.value = '';
    }
  }
}

function setupNewsSchedule() {
  const dateInput = document.getElementById('newsScheduleDate');
  const timeInput = document.getElementById('newsScheduleTime');

  if (!dateInput || !timeInput) return;

  let scheduleTimeout;
  const debouncedUpdate = () => {
    clearTimeout(scheduleTimeout);
    scheduleTimeout = setTimeout(updateSchedulePreview, 100);
  };

  dateInput.addEventListener('input', debouncedUpdate);
  timeInput.addEventListener('input', debouncedUpdate);
}

async function saveNews() {
  // Ensure schedule preview is updated before saving (populates the hidden field)
  updateSchedulePreview();

  const editId = document.getElementById('newsEditId').value;
  const title = document.getElementById('newsTitle').value.trim();
  const content = document.getElementById('newsContent').value.trim();
  const category = document.getElementById('newsCategory').value.trim();

  if (!title || !category) {
    showToast('Please enter a title and category.', 'error');
    return;
  }

  const saveBtn = document.getElementById('newsSaveBtn');
  saveBtn.innerHTML = '<span class="loading-spinner"></span> Saving...';
  saveBtn.disabled = true;

  try {
    if (!supabaseClient) {
      showToast('Database connection unavailable', 'error');
      saveBtn.innerHTML = '<i class="fa-solid fa-floppy-disk"></i> Save';
      saveBtn.disabled = false;
      return;
    }

    const imageUrls = await uploadGalleryImages('news');
    const imageUrl = imageUrls[0] || null;
    const payload = { title, description: content, category, image_url: imageUrl, image_urls: imageUrls };

    // Add scheduled_at if scheduling is enabled
    const scheduledAtValue = document.getElementById('newsScheduledAt').value;
    if (scheduledAtValue) {
      payload.scheduled_at = scheduledAtValue;
      // Mark as unpublished if scheduled for future
      const scheduledDate = new Date(scheduledAtValue);
      const now = new Date();
      if (scheduledDate > now) {
        payload.is_published = false; // Will be published later
      } else {
        payload.is_published = true; // Scheduled time has passed, publish now
      }
    } else {
      payload.is_published = true; // No schedule, publish immediately
    }

    if (editId && editId.trim() !== '') {
      console.log('Updating news with ID:', editId, 'Payload:', payload);

      // First verify the record exists
      const { data: checkData, error: checkError } = await supabaseClient.from('news').select('id').eq('id', editId).single();
      console.log('Record exists check:', { exists: !!checkData, data: checkData, error: checkError });

      if (!checkData) {
        showToast('Error: Record not found in database. The ID may be invalid.', 'error');
        console.error('Record with ID ' + editId + ' not found in database');
        throw new Error('Record not found');
      }

      // Try direct update without select first
      const updateResult = await supabaseClient
        .from('news')
        .update(payload)
        .eq('id', editId);

      console.log('Update result:', updateResult);

      if (updateResult.error) {
        console.error('Update error:', updateResult.error);
        throw updateResult.error;
      }

      // Verify the update actually saved
      await new Promise(resolve => setTimeout(resolve, 800));
      const { data: verifyData, error: verifyError } = await supabaseClient
        .from('news')
        .select('id, title, description, image_url')
        .eq('id', editId)
        .single();

      console.log('Verify update - Data:', verifyData, 'Error:', verifyError);

      if (verifyData?.title !== title) {
        console.warn('WARNING: Title did not update! Database still has:', verifyData?.title, 'Expected:', title);
        showToast('Update failed: Database rejected the changes (RLS or validation issue)', 'error');
        throw new Error('Update was not applied to database');
      }

      showToast('News updated successfully!', 'success');
      const isScheduled = payload.scheduled_at && payload.is_published === false;
      const message = isScheduled
        ? `Article "${title}" scheduled for ${new Date(payload.scheduled_at).toLocaleString()}`
        : `Article "${title}" has been updated`;
      addNotification('News Updated', message, 'success');
      if (!isScheduled) {
        sendNewsPushNotification({
          title,
          description: content,
          image_url: imageUrl,
          topic: 'news_updates',
          type: 'news',
        });
      }
    } else {
      console.log('Creating new news with payload:', payload, 'editId was:', editId);
      const { error } = await supabaseClient.from('news').insert(payload);
      if (error) throw error;

      const isScheduled = payload.scheduled_at && payload.is_published === false;
      if (isScheduled) {
        showToast('News scheduled successfully! It will be published at ' + new Date(payload.scheduled_at).toLocaleString(), 'success');
        addNotification('News Scheduled', `Article "${title}" scheduled for ${new Date(payload.scheduled_at).toLocaleString()}`, 'success');
      } else {
        showToast('News added successfully!', 'success');
        addNotification('News Created', `Article "${title}" has been published`, 'success');
        sendNewsPushNotification({
          title,
          description: content,
          image_url: imageUrl,
          topic: 'news_updates',
          type: 'news',
        });
      }
    }

    closeNewsModal();
    loadDashboardStats();
    loadNews();
  } catch (error) {
    console.error('Error saving news:', error);
    showToast('Failed to save news: ' + error.message, 'error');
  } finally {
    saveBtn.innerHTML = '<i class="fa-solid fa-floppy-disk"></i> Save';
    saveBtn.disabled = false;
  }
}

async function sendNewsPushNotification(payload) {
  try {
    const response = await fetch('/api/send-notification', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(payload),
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error('Failed to send news push:', response.status, errorText);
      return;
    }

    const result = await response.json();
    console.log('News push notification sent:', result);
  } catch (error) {
    console.error('Error sending news push notification:', error);
  }
}

async function sendVerificationStatusPushNotification({ userId, status, rejectionReason = '' }) {
  if (!userId) return;

  try {
    const normalizedStatus = String(status || '').toLowerCase();
    const topic = `identity_verification_user_${userId}`;
    const payload = {
      topic,
      type: 'identity_verification_status',
      status: normalizedStatus,
      userId,
      rejectionReason,
      title: normalizedStatus === 'verified'
        ? 'Your identity verification was approved'
        : 'Your identity verification was rejected',
      description: normalizedStatus === 'verified'
        ? 'Your identity verification has been approved. You can now access all verification-based features.'
        : (rejectionReason
          ? `Your identity verification was rejected. Reason: ${rejectionReason}`
          : 'Your identity verification was rejected. Please review the requirements and resubmit.'),
    };

    const response = await fetch('/api/send-notification', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(payload),
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error('Failed to send verification status push:', response.status, errorText);
      return;
    }

    const result = await response.json();
    console.log('Verification status push notification sent:', result);
  } catch (error) {
    console.error('Error sending verification status push notification:', error);
  }
}

async function sendReportStatusPushNotification({ reportId, userId, status, reviewMessage = '', rejectionReason = '', accomplishmentMessage = '' }) {
  const normalizedUserId = String(userId || '').trim();
  if (!reportId || !normalizedUserId) {
    console.warn('Report status push skipped: report has no user_id', reportId);
    return false;
  }

  const title = status === 'reviewing' ? 'Your report is under review'
    : status === 'resolved' ? 'Your report was resolved'
    : status === 'rejected' ? 'Your report was returned'
    : 'Your report status was updated';
  const description = status === 'reviewing'
    ? (reviewMessage || 'The admin is reviewing your report.')
    : status === 'resolved'
      ? (accomplishmentMessage || 'The admin marked your report as resolved.')
      : status === 'rejected'
        ? `Your report was returned. Reason: ${rejectionReason}`
        : 'Your report is pending review.';

  try {
    const response = await fetch('/api/send-notification', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        topic: `report_user_${normalizedUserId.replace(/[^a-zA-Z0-9\-_.~%]/g, '_')}`,
        type: 'report_status',
        reportId,
        status,
        rejectionReason,
        title,
        description,
      }),
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error('Failed to send report status push:', response.status, errorText);
      return false;
    }

    console.log('Report status push notification sent:', await response.json());
    return true;
  } catch (error) {
    console.error('Error sending report status push notification:', error);
    return false;
  }
}

async function sendOnlineServiceStatusPushNotification(record, status, reason = '') {
  const userId = String(record.user_id || '').trim();
  if (!userId) {
    console.warn('Service status push skipped: request has no user_id', record.id);
    return false;
  }

  const serviceLabel = record.type || 'Online service';
  const statusText = status === 'processing' ? 'ready for release'
    : status === 'completed' ? 'completed'
    : status === 'rejected' ? 'returned'
    : 'pending';
  const description = `Your ${serviceLabel} request is ${statusText}.` +
    (reason ? ` ${status === 'rejected' ? 'Reason' : 'Note'}: ${reason}` : '');
  try {
    const response = await fetch('/api/send-notification', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        topic: `online_service_user_${userId.replace(/[^a-zA-Z0-9\-_.~%]/g, '_')}`,
        type: 'online_service_status',
        requestId: String(record.id),
        status,
        serviceLabel,
        applicantName: record.display_name || '',
        table: record.table_name,
        title: `${serviceLabel} request ${statusText}`,
        description,
      }),
    });
    if (!response.ok) {
      console.error('Failed to send service status push:', response.status, await response.text());
      return false;
    }
    console.log('Service status push notification sent:', await response.json());
    return true;
  } catch (error) {
    console.error('Error sending service status push notification:', error);
    return false;
  }
}

function openDeleteNews(id, title) {
  deleteTarget = id;
  deleteType = 'news';
  document.getElementById('deleteMessage').textContent = `Are you sure you want to delete "${title}"? This action cannot be undone.`;
  document.getElementById('deleteModal').classList.add('active');
}

// ============================================================
// REPORTS
// ============================================================
let allReports = [];

async function loadReports() {
  const tbody = document.getElementById('reportsTableBody');
  if (!tbody) return;

  if (!supabaseClient) {
    const colSpan = tbody.closest('table').querySelectorAll('th').length;
    tbody.innerHTML = `<tr><td colspan="${colSpan}" class="empty-state">Database connection unavailable</td></tr>`;
    return;
  }

  try {
    const session = getCurrentAdminSession();
    const allowedCategories = getReportCategoriesForSession(session);
    syncReportCategoryFilter();
    const assignedEmail = String(session.email || '').trim();
    if (!session.isSuperAdmin && allowedCategories.length === 0 && !assignedEmail) {
      allReports = [];
      renderReportsTable(allReports);
      return;
    }

    let query = supabaseClient
      .from('reports')
      .select('*')
      .order('created_at', { ascending: false });

    if (!session.isSuperAdmin) {
      if (allowedCategories.length && assignedEmail) {
        const categories = allowedCategories
          .map(category => `"${category.replace(/"/g, '\\"')}"`)
          .join(',');
        query = query.or(`category.in.(${categories}),assigned_admin_email.eq."${assignedEmail.replace(/"/g, '\\"')}"`);
      } else if (allowedCategories.length) {
        query = query.in('category', allowedCategories);
      } else {
        query = query.eq('assigned_admin_email', assignedEmail);
      }
    }

    const { data, error } = await query;

    if (error) throw error;

    allReports = data || [];
    console.log('Reports fetched:', allReports.length);

    // Fetch user display names for all reports
    if (allReports.length > 0) {
      const userIds = [...new Set(allReports.map(r => r.user_id).filter(Boolean))];
      console.log('User IDs to fetch:', userIds.length);

      if (userIds.length > 0) {
        const { data: users, error: usersError } = await supabaseClient
          .from('users')
          .select('id, display_name, email')
          .in('id', userIds);

        console.log('Users fetched:', users);
        console.log('Users error:', usersError);

        const userMap = {};
        const emailMap = {};
        (users || []).forEach(u => {
          // Priority: display_name -> email -> user_id (first 12 chars)
          const name = (u.display_name && u.display_name.trim())
            ? u.display_name
            : (u.email && u.email.trim()
              ? u.email
              : u.id.substring(0, 12));
          userMap[u.id] = name;
          emailMap[u.id] = u.email || '';
          console.log(`Mapped ${u.id.substring(0, 8)}... to ${name}`);
        });

        allReports = allReports.map(r => ({
          ...r,
          reporter_name: r.reporter_name || userMap[r.user_id] || r.user_id.substring(0, 12) || 'Anonymous',
          reporter_email: r.reporter_email || emailMap[r.user_id] || ''
        }));
      }
    }

    console.log('Reports with names:', allReports);
    renderReportsTable(allReports);
  } catch (error) {
    console.error('Error loading reports:', error);
    showToast('Failed to load reports from database: ' + error.message, 'error');
  }
}

function renderReportsTable(reportsData) {
  const tbody = document.getElementById('reportsTableBody');
  tableExportRows.reportsTableBody = reportsData;
  const colSpan = tbody.closest('table').querySelectorAll('th').length;

  const totalItems = reportsData.length;
  const totalPages = Math.ceil(totalItems / ITEMS_PER_PAGE);
  const currentPage = paginationState.reports.current;

  if (currentPage > totalPages && totalPages > 0) {
    paginationState.reports.current = 1;
    renderReportsTable(reportsData);
    return;
  }

  if (reportsData.length === 0) {
    tbody.innerHTML = `<tr><td colspan="${colSpan}" class="empty-state">No reports found</td></tr>`;
    renderReportsPagination(0);
    return;
  }

  const startIdx = (currentPage - 1) * ITEMS_PER_PAGE;
  const endIdx = startIdx + ITEMS_PER_PAGE;
  const pageData = reportsData.slice(startIdx, endIdx);

  tbody.innerHTML = '';
  pageData.forEach(r => {
    const tr = document.createElement('tr');

    const tdReporter = document.createElement('td');
    tdReporter.textContent = r.reporter_name || 'Anonymous';
    tdReporter.style.fontWeight = '600';

    const tdMessage = document.createElement('td');
    const messageText = (r.message || '').substring(0, 50);
    tdMessage.textContent = messageText.length < (r.message || '').length ? messageText + '...' : messageText;
    tdMessage.style.fontSize = '13px';
    tdMessage.title = r.message || '';

    const tdCategory = document.createElement('td');
    tdCategory.textContent = r.category || 'Other';
    tdCategory.style.fontSize = '13px';

    const tdStatus = document.createElement('td');
    const statusBadge = document.createElement('span');
    statusBadge.className = `status-badge ${getStatusClass(r.status)}`;
    statusBadge.textContent = formatAdminStatus(r.status);
    tdStatus.appendChild(statusBadge);
    if (r.assigned_admin_email) {
      const forwardedTo = document.createElement('div');
      forwardedTo.textContent = `Forwarded to: ${r.assigned_admin_email}`;
      forwardedTo.style.cssText = 'margin-top: 6px; font-size: 11px; color: #64748b;';
      tdStatus.appendChild(forwardedTo);

      if (r.forwarded_by_email) {
        const forwardedBy = document.createElement('div');
        forwardedBy.textContent = `Forwarded by: ${r.forwarded_by_email}`;
        forwardedBy.style.cssText = 'margin-top: 3px; font-size: 11px; color: #64748b;';
        tdStatus.appendChild(forwardedBy);
      }
    }

    const tdAttachments = document.createElement('td');
    const imageUrls = r.image_urls || [];
    tdAttachments.textContent = `${imageUrls.length} image${imageUrls.length !== 1 ? 's' : ''}`;
    tdAttachments.style.fontSize = '13px';

    const tdDate = document.createElement('td');
    tdDate.textContent = formatSubmittedDate(r.created_at);
    tdDate.title = formatSubmittedAt(r.created_at);
    tdDate.className = 'submission-time-cell';

    const tdAge = createSubmissionAgeCell(r.created_at);

    const tdUpdated = document.createElement('td');
    tdUpdated.textContent = formatDate(r.updated_at);
    tdUpdated.style.fontSize = '13px';

    const tdActions = document.createElement('td');
    const actionsDiv = document.createElement('div');
    actionsDiv.className = 'action-btns';

    const viewBtn = document.createElement('button');
    viewBtn.className = 'btn btn-sm btn-edit btn-icon';
    viewBtn.title = 'View Details';
    viewBtn.innerHTML = '<i class="fa-solid fa-eye"></i>';
    viewBtn.addEventListener('click', () => openReportModal(r.id));

    const editBtn = document.createElement('button');
    editBtn.className = 'btn btn-sm btn-edit btn-icon';
    editBtn.title = 'Edit Report';
    editBtn.innerHTML = '<i class="fa-solid fa-pencil"></i>';
    editBtn.addEventListener('click', () => openEditReportModal(r.id));

    actionsDiv.appendChild(viewBtn);
    actionsDiv.appendChild(editBtn);
    tdActions.appendChild(actionsDiv);

    tr.appendChild(tdReporter);
    tr.appendChild(tdMessage);
    tr.appendChild(tdCategory);
    tr.appendChild(tdStatus);
    tr.appendChild(tdAttachments);
    tr.appendChild(tdDate);
    tr.appendChild(tdAge);
    tr.appendChild(tdUpdated);
    tr.appendChild(tdActions);

    tbody.appendChild(tr);
  });

  if (document.getElementById('totalReports')) {
    document.getElementById('totalReports').textContent = reportsData.length;
  }

  renderReportsPagination(totalItems);
}

function renderReportsPagination(totalItems) {
  const paginationEl = document.getElementById('reportsPagination');
  const showingEl = document.getElementById('reportsShowing');
  if (!paginationEl || !showingEl) return;

  const totalPages = Math.ceil(totalItems / ITEMS_PER_PAGE);
  const currentPage = paginationState.reports.current;
  paginationState.reports.total = totalPages;
  showingEl.textContent = `Showing ${Math.min(currentPage * ITEMS_PER_PAGE, totalItems)} of ${totalItems} entries`;

  if (totalPages <= 1) {
    paginationEl.innerHTML = '';
    return;
  }

  let html = `<button class="page-btn prev-btn" data-page="${currentPage - 1}" ${currentPage === 1 ? 'disabled' : ''}><i class="fa-solid fa-chevron-left"></i></button>`;

  const maxButtons = 5;
  let startPage = Math.max(1, currentPage - Math.floor(maxButtons / 2));
  let endPage = Math.min(totalPages, startPage + maxButtons - 1);
  if (endPage - startPage + 1 < maxButtons) {
    startPage = Math.max(1, endPage - maxButtons + 1);
  }

  if (startPage > 1) {
    html += `<button class="page-btn" data-page="1">1</button>`;
    if (startPage > 2) html += `<span class="page-ellipsis">...</span>`;
  }

  for (let i = startPage; i <= endPage; i++) {
    html += `<button class="page-btn ${i === currentPage ? 'active' : ''}" data-page="${i}">${i}</button>`;
  }

  if (endPage < totalPages) {
    if (endPage < totalPages - 1) html += `<span class="page-ellipsis">...</span>`;
    html += `<button class="page-btn" data-page="${totalPages}">${totalPages}</button>`;
  }

  html += `<button class="page-btn next-btn" data-page="${currentPage + 1}" ${currentPage === totalPages ? 'disabled' : ''}><i class="fa-solid fa-chevron-right"></i></button>`;
  paginationEl.innerHTML = html;

  paginationEl.querySelectorAll('.page-btn').forEach(btn => {
    btn.addEventListener('click', (e) => {
      e.preventDefault();
      const page = parseInt(btn.dataset.page);
      if (page >= 1 && page <= totalPages) {
        paginationState.reports.current = page;
        loadReports();
        window.scrollTo(0, 0);
      }
    });
  });
}

async function openReportModal(id) {
  if (!supabaseClient) {
    showToast('Database connection unavailable', 'error');
    return;
  }

  try {
    const { data, error } = await supabaseClient
      .from('reports')
      .select('*')
      .eq('id', id)
      .single();

    if (error) throw error;
    if (data) {
      if (!canAccessReport(data)) {
        showToast('You do not have access to this report category.', 'error');
        return;
      }
      const reportData = allReports.find(r => r.id === id);
      const reporterName = reportData?.reporter_name || data.reporter_name || 'Anonymous';
      const reporterEmail = reportData?.reporter_email || data.reporter_email || '';

      document.getElementById('reportViewId').value = id;
      document.getElementById('reportViewReporterName').textContent = reporterName;
      document.getElementById('reportViewReporterEmail').textContent = reporterEmail || 'No email provided';
      document.getElementById('reportViewCategory').textContent = data.category || 'Other';
      const reportStatus = document.getElementById('reportViewStatus');
      reportStatus.textContent = formatAdminStatus(data.status);
      reportStatus.className = `status-badge ${getStatusClass(data.status)}`;
      const forwardingGroup = document.getElementById('reportViewForwardingGroup');
      const forwardingField = document.getElementById('reportViewForwarding');
      if (data.assigned_admin_email) {
        const sender = data.forwarded_by_email || 'Unknown admin';
        forwardingField.textContent = `Forwarded by ${sender} to ${data.assigned_admin_email}`;
        forwardingGroup.style.display = 'block';
      } else {
        forwardingField.textContent = '';
        forwardingGroup.style.display = 'none';
      }
      document.getElementById('reportViewMessage').textContent = data.message || 'No message provided.';
      document.getElementById('reportViewSubmittedDate').textContent = formatSubmittedAt(data.created_at);
      const reportAge = document.getElementById('reportViewAge');
      reportAge.textContent = formatSubmissionAge(data.created_at);
      reportAge.dataset.submittedAt = parseSubmissionTime(data.created_at)?.toISOString() || '';

      // Display attachments
      const imageUrls = data.image_urls || [];
      const attachmentsContainer = document.getElementById('reportViewAttachmentsContainer');
      attachmentsContainer.innerHTML = '';

      if (imageUrls.length === 0) {
        attachmentsContainer.innerHTML = '<p style="color: #999; font-size: 13px;">No attachments</p>';
      } else {
        imageUrls.forEach(url => {
          const imgWrapper = document.createElement('div');
          imgWrapper.style.cssText = 'position: relative; width: 100px; height: 100px; border-radius: 8px; overflow: hidden; box-shadow: 0 2px 8px rgba(0,0,0,0.1); cursor: pointer;';

          const img = document.createElement('img');
          img.src = url;
          img.style.cssText = 'width: 100%; height: 100%; object-fit: cover;';
          img.title = 'Click to view full image';

          imgWrapper.appendChild(img);
          imgWrapper.addEventListener('click', () => {
            const modal = document.createElement('div');
            modal.style.cssText = 'position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: rgba(0,0,0,0.8); display: flex; align-items: center; justify-content: center; z-index: 10000;';

            const img2 = document.createElement('img');
            img2.src = url;
            img2.style.cssText = 'max-width: 90%; max-height: 90%; border-radius: 8px;';

            modal.appendChild(img2);
            modal.addEventListener('click', () => modal.remove());
            document.body.appendChild(modal);
          });

          attachmentsContainer.appendChild(imgWrapper);
        });
      }

      // Display accomplishment report if status is resolved
      const accomplishmentSection = document.getElementById('reportViewAccomplishmentSection');
      if (data.status === 'resolved' && data.accomplishment_message) {
        accomplishmentSection.style.display = 'block';
        document.getElementById('reportViewAccomplishmentMessage').textContent = data.accomplishment_message || '';

        // Display accomplishment files
        const accomplishmentFilesContainer = document.getElementById('reportViewAccomplishmentFiles');
        accomplishmentFilesContainer.innerHTML = '';

        const accomplishmentFiles = data.accomplishment_files || [];
        if (accomplishmentFiles.length === 0) {
          accomplishmentFilesContainer.innerHTML = '<p style="color: #999; font-size: 13px;">No files attached</p>';
        } else {
          accomplishmentFiles.forEach(file => {
            const fileLink = document.createElement('a');
            fileLink.href = file.url;
            fileLink.target = '_blank';
            fileLink.style.cssText = 'display: flex; align-items: center; gap: 8px; padding: 8px 12px; background: #f3f4f6; border-radius: 8px; text-decoration: none; color: #1f2937; font-size: 13px; word-break: break-word;';
            fileLink.innerHTML = `<i class="fa-solid fa-file"></i><span>${file.name}</span>`;
            fileLink.title = 'Click to download/view';

            accomplishmentFilesContainer.appendChild(fileLink);
          });
        }
      } else {
        accomplishmentSection.style.display = 'none';
      }

      const previousReturnFiles = document.getElementById('reportViewReturnFiles');
      previousReturnFiles?.remove();
      if (data.status === 'rejected' && Array.isArray(data.return_files) && data.return_files.length) {
        const section = document.createElement('div');
        section.id = 'reportViewReturnFiles';
        section.className = 'form-group';
        const heading = document.createElement('strong');
        heading.textContent = 'Return attachments';
        section.appendChild(heading);
        appendReturnFileLinks(section, data.return_files);
        attachmentsContainer.parentElement.appendChild(section);
      }

      document.getElementById('reportModal').classList.add('active');
      document.querySelector('#reportModal .modal-body').scrollTop = 0;
    }
  } catch (error) {
    console.error('Error loading report:', error);
    showToast('Failed to load report details', 'error');
  }
}

function closeReportModal() {
  document.getElementById('reportModal').classList.remove('active');
}

function populateReportForwardingOptions(report) {
  const select = document.getElementById('reportForwardTo');
  if (!select) return;

  const category = String(report.category || 'Other').trim() || 'Other';
  const recipients = getAdminRoles()
    .filter(role => {
      const permissions = Array.isArray(role.permissions) && role.permissions.length
        ? role.permissions
        : buildPermissionSet(role.feature);
      return role.isSuperAdmin || permissions.includes('reports');
    })
    .filter((role, index, roles) =>
      roles.findIndex(item => item.assignedEmail === role.assignedEmail) === index
    );

  select.innerHTML = '<option value="">Unassigned</option>';
  recipients.forEach(role => {
    const option = new Option(
      `${role.roleName || 'Report Admin'} (${role.assignedEmail || 'No email'})`,
      role.id
    );
    option.selected = role.id === report.assigned_admin_role_id ||
      role.assignedEmail === report.assigned_admin_email;
    select.append(option);
  });
}

async function openEditReportModal(id) {
  document.getElementById('reportEditId').value = id;
  document.getElementById('reportEditReason').value = '';
  document.getElementById('reportReturnTemplate').value = '';
  document.getElementById('reportReturnFiles').value = '';
  document.getElementById('reportReviewMessage').value = '';
  document.getElementById('accomplishmentMessage').value = '';
  document.getElementById('accomplishmentFiles').value = '';
  document.getElementById('accomplishmentFilesList').innerHTML = '';
  updateAccomplishmentFilesList();

  try {
    const record = allReports.find(r => r.id === id);

    if (record) {
      if (!canAccessReport(record)) {
        showToast('You do not have access to this report category.', 'error');
        return;
      }
      populateReportForwardingOptions(record);
      document.getElementById('reportEditStatus').value = record.status || 'pending';
      if (record.status === 'rejected') {
        document.getElementById('reportEditReason').value = record.rejection_reason || '';
      }

      if (record.status === 'reviewing' && record.review_message) {
        document.getElementById('reportReviewMessage').value = record.review_message;
      }

      // Populate existing accomplishment data if report is already resolved
      if (record.status === 'resolved') {
        if (record.accomplishment_message) {
          document.getElementById('accomplishmentMessage').value = record.accomplishment_message;
        }
      }

      toggleReportReasonField();
    } else {
      throw new Error('Record not found');
    }
  } catch (error) {
    console.error('Error loading report:', error);
    showToast('Failed to load report data', 'error');
    return;
  }

  document.getElementById('editReportModal').classList.add('active');
}

function closeEditReportModal() {
  document.getElementById('editReportModal').classList.remove('active');
}

function setupReportStatusChangeListener() {
  // No longer needed - functionality moved to toggleReportReasonField
}

function toggleReportReasonField() {
  const status = document.getElementById('reportEditStatus').value;
  const reasonGroup = document.getElementById('reportEditReasonGroup');
  const reasonLabel = document.getElementById('reportEditReasonLabel');
  const reviewMessageGroup = document.getElementById('reportReviewMessageGroup');
  const accomplishmentSection = document.getElementById('accomplishmentSection');

  if (status === 'rejected') {
    reasonGroup.style.display = 'block';
    reasonLabel.textContent = 'Return Reason *';
    reviewMessageGroup.style.display = 'none';
    accomplishmentSection.style.display = 'none';
  } else if (status === 'resolved') {
    reasonGroup.style.display = 'none';
    reviewMessageGroup.style.display = 'none';
    accomplishmentSection.style.display = 'block';
  } else if (status === 'reviewing') {
    reasonGroup.style.display = 'none';
    reviewMessageGroup.style.display = 'block';
    accomplishmentSection.style.display = 'none';
  } else {
    reasonGroup.style.display = 'none';
    reviewMessageGroup.style.display = 'none';
    accomplishmentSection.style.display = 'none';
  }

  if (reasonGroup.style.display === 'none') {
    document.getElementById('reportEditReason').value = '';
    document.getElementById('reportReturnTemplate').value = '';
    document.getElementById('reportReturnFiles').value = '';
  }
  if (reviewMessageGroup.style.display === 'none') {
    document.getElementById('reportReviewMessage').value = '';
  }
}

function applyReturnReasonTemplate(selectId, reasonId) {
  const selected = document.getElementById(selectId).value;
  if (selected && selected !== 'custom') {
    document.getElementById(reasonId).value = selected;
  } else if (selected === 'custom') {
    document.getElementById(reasonId).value = '';
    document.getElementById(reasonId).focus();
  }
}

function validateReturnFiles(files) {
  const allowedExtensions = /\.(pdf|doc|docx)$/i;
  for (const file of files) {
    if (!(file.type.startsWith('image/') || allowedExtensions.test(file.name))) {
      throw new Error(`Unsupported file type: ${file.name}`);
    }
    if (!file.type.startsWith('image/') && file.size > 10 * 1024 * 1024) {
      throw new Error(`${file.name} exceeds the 10 MB limit.`);
    }
  }
}

async function uploadReturnFiles(kind, recordId, files) {
  validateReturnFiles(files);
  const uploaded = [];
  for (const [index, originalFile] of Array.from(files).entries()) {
    const file = await compressAdminImage(originalFile);
    if (file.size > 10 * 1024 * 1024) throw new Error(`${originalFile.name} is still over 10 MB after compression.`);
    const safeName = file.name.replace(/[^a-zA-Z0-9._-]/g, '_');
    const path = `returns/${kind}/${recordId}/${Date.now()}-${index}-${safeName}`;
    const { error } = await supabaseClient.storage.from('report-images').upload(path, file, {
      cacheControl: '3600',
      contentType: file.type || undefined,
      upsert: false
    });
    if (error) throw error;
    const { data } = supabaseClient.storage.from('report-images').getPublicUrl(path);
    uploaded.push({ name: originalFile.name, url: data.publicUrl, uploadedAt: new Date().toISOString() });
  }
  return uploaded;
}

function appendReturnFileLinks(container, files) {
  for (const file of files) {
    if (!file?.url || !/^https:\/\//i.test(file.url)) continue;
    const link = document.createElement('a');
    link.href = file.url;
    link.target = '_blank';
    link.rel = 'noopener noreferrer';
    link.textContent = file.name || 'View attachment';
    link.style.cssText = 'display: block; margin-top: 8px; word-break: break-word;';
    container.appendChild(link);
  }
}

// Handle accomplishment file selection
document.addEventListener('DOMContentLoaded', function() {
  const fileInput = document.getElementById('accomplishmentFiles');
  if (fileInput) {
    fileInput.addEventListener('change', function(e) {
      updateAccomplishmentFilesList();
    });
  }
});

function updateAccomplishmentFilesList() {
  const fileInput = document.getElementById('accomplishmentFiles');
  const filesList = document.getElementById('accomplishmentFilesList');
  const preview = document.getElementById('accomplishmentFilesPreview');

  if (!fileInput.files || fileInput.files.length === 0) {
    preview.innerHTML = '<i class="fa-solid fa-paperclip"></i><span>No files selected</span>';
    filesList.innerHTML = '';
    return;
  }

  preview.innerHTML = `<i class="fa-solid fa-check-circle"></i><span>${fileInput.files.length} file(s) selected</span>`;

  filesList.innerHTML = '';
  Array.from(fileInput.files).forEach((file, index) => {
    const fileItem = document.createElement('div');
    fileItem.style.cssText = 'display: flex; align-items: center; justify-content: space-between; padding: 8px 12px; background: #f3f4f6; border-radius: 8px; margin-bottom: 8px; font-size: 13px;';

    const nameSpan = document.createElement('span');
    nameSpan.textContent = file.name;
    nameSpan.style.cssText = 'flex: 1; overflow: hidden; text-overflow: ellipsis; white-space: nowrap;';

    const sizeSpan = document.createElement('span');
    sizeSpan.textContent = (file.size / 1024 / 1024).toFixed(2) + ' MB';
    sizeSpan.style.cssText = 'color: #999; margin-left: 10px; white-space: nowrap;';

    const removeBtn = document.createElement('button');
    removeBtn.type = 'button';
    removeBtn.className = 'btn btn-sm btn-delete btn-icon';
    removeBtn.style.cssText = 'margin-left: 10px; padding: 4px 8px;';
    removeBtn.innerHTML = '<i class="fa-solid fa-trash"></i>';
    removeBtn.title = 'Remove file';
    removeBtn.addEventListener('click', () => {
      const dt = new DataTransfer();
      Array.from(fileInput.files).forEach((file, i) => {
        if (i !== index) dt.items.add(file);
      });
      fileInput.files = dt.files;
      updateAccomplishmentFilesList();
    });

    fileItem.appendChild(nameSpan);
    fileItem.appendChild(sizeSpan);
    fileItem.appendChild(removeBtn);
    filesList.appendChild(fileItem);
  });
}

async function updateReportStatus() {
  const reportId = document.getElementById('reportEditId').value;
  const status = document.getElementById('reportEditStatus').value;
  const reason = document.getElementById('reportEditReason').value;
  const reviewMessage = document.getElementById('reportReviewMessage')?.value || '';
  const accomplishmentMessage = document.getElementById('accomplishmentMessage')?.value || '';
  const accomplishmentFiles = document.getElementById('accomplishmentFiles')?.files || [];
  const returnFiles = document.getElementById('reportReturnFiles').files;
  const forwardRoleId = document.getElementById('reportForwardTo')?.value || '';

  if (!reportId) {
    showToast('Report ID not found', 'error');
    return;
  }

  const report = allReports.find(item => item.id === reportId);
  if (!report || !canAccessReport(report)) {
    showToast('You do not have access to update this report.', 'error');
    closeEditReportModal();
    return;
  }

  const forwardRecipient = forwardRoleId
    ? getAdminRoles().find(role => role.id === forwardRoleId)
    : null;
  if (forwardRoleId && !forwardRecipient) {
    showToast('The selected forwarding admin is no longer available.', 'error');
    return;
  }

  if (status === 'rejected' && !reason.trim()) {
    showToast('Please provide a return reason', 'error');
    return;
  }
  if (status === 'rejected') {
    try {
      validateReturnFiles(returnFiles);
    } catch (error) {
      showToast(error.message, 'error');
      return;
    }
  }

  if (status === 'resolved' && !accomplishmentMessage.trim()) {
    showToast('Please provide a message in the accomplishment report', 'error');
    return;
  }

  const saveBtn = document.getElementById('reportEditSaveBtn');
  saveBtn.innerHTML = '<span class="loading-spinner"></span> Updating...';
  saveBtn.disabled = true;

  try {
    if (!supabaseClient) {
      showToast('Database connection unavailable', 'error');
      saveBtn.innerHTML = '<i class="fa-solid fa-floppy-disk"></i> Update Status';
      saveBtn.disabled = false;
      return;
    }

    let accomplishmentFileUrls = [];

    // Upload accomplishment files if status is resolved
    if (status === 'resolved' && accomplishmentFiles.length > 0) {
      accomplishmentFileUrls = await uploadAccomplishmentFiles(reportId, accomplishmentFiles);
    }

    const updateData = { status };
    const forwardingChanged =
      (forwardRecipient?.id || null) !== (report.assigned_admin_role_id || null);
    if (forwardRecipient) {
      updateData.assigned_admin_role_id = forwardRecipient.id;
      updateData.assigned_admin_email = forwardRecipient.assignedEmail;
      if (forwardingChanged) {
        const { data: userData } = await supabaseClient.auth.getUser();
        updateData.forwarded_by_email = userData?.user?.email || null;
        updateData.forwarded_at = new Date().toISOString();
      }
    } else {
      updateData.assigned_admin_role_id = null;
      updateData.assigned_admin_email = null;
      updateData.forwarded_by_email = null;
      updateData.forwarded_at = null;
    }
    if (status === 'rejected') {
      updateData.rejection_reason = reason.trim();
      if (!('return_files' in report) && returnFiles.length) {
        throw new Error('Return attachments are not available yet. Run supabase/add_return_files.sql first.');
      }
      if ('return_files' in report) {
        updateData.return_files = returnFiles.length
          ? [...(Array.isArray(report.return_files) ? report.return_files : []), ...await uploadReturnFiles('report', reportId, returnFiles)]
          : (report.return_files || null);
      }
      updateData.review_message = null;
      updateData.resolution_notes = null;
      updateData.accomplishment_message = null;
      updateData.accomplishment_files = null;
    } else if (status === 'resolved') {
      updateData.rejection_reason = null;
      if ('return_files' in report) updateData.return_files = null;
      updateData.review_message = null;
      updateData.resolution_notes = null;
      updateData.accomplishment_message = accomplishmentMessage.trim();
      updateData.accomplishment_files = accomplishmentFileUrls;
    } else {
      updateData.rejection_reason = null;
      if ('return_files' in report) updateData.return_files = null;
      updateData.review_message = status === 'reviewing' && reviewMessage.trim()
        ? reviewMessage.trim()
        : null;
      updateData.resolution_notes = null;
      updateData.accomplishment_message = null;
      updateData.accomplishment_files = null;
    }

    const { data: savedReport, error } = await supabaseClient
      .from('reports')
      .update(updateData)
      .eq('id', reportId)
      .select('id, status')
      .single();

    if (error) throw error;
    if (!savedReport || savedReport.status !== status) {
      throw new Error('The report status change was not saved.');
    }
    const pushSent = report.status !== status
      ? await sendReportStatusPushNotification({
        reportId,
        userId: report.user_id,
        status,
        reviewMessage: reviewMessage.trim(),
        rejectionReason: status === 'rejected' ? reason.trim() : '',
        accomplishmentMessage: status === 'resolved' ? accomplishmentMessage.trim() : '',
      })
      : true;
    showToast(pushSent
      ? 'Report status updated successfully!'
      : 'Report status saved, but the user push notification could not be sent.',
      pushSent ? 'success' : 'error');
    addNotification('Report Status Changed', `Report status changed to ${formatAdminStatus(status)}`, 'info');
    closeEditReportModal();
    loadReports();
  } catch (error) {
    console.error('Error updating report:', error);
    showToast('Failed to update report: ' + error.message, 'error');
  } finally {
    saveBtn.innerHTML = '<i class="fa-solid fa-floppy-disk"></i> Update Status';
    saveBtn.disabled = false;
  }
}

async function uploadAccomplishmentFiles(reportId, files) {
  const fileUrls = [];

  try {
    for (let i = 0; i < files.length; i++) {
      const originalFile = files[i];
      const file = await compressAdminImage(originalFile);
      const timestamp = Date.now();
      const sanitizedName = file.name.replace(/[^a-zA-Z0-9._-]/g, '_');
      const path = `accomplishment/${reportId}/${timestamp}-${i}-${sanitizedName}`;

      const { data, error } = await supabaseClient.storage
        .from('report-images')
        .upload(path, file, {
          cacheControl: '3600',
          contentType: file.type || undefined,
          upsert: false
        });

      if (error) {
        console.error(`Error uploading file ${file.name}:`, error);
        throw error;
      }

      const { data: publicUrlData } = supabaseClient.storage
        .from('report-images')
        .getPublicUrl(path);

      fileUrls.push({
        name: originalFile.name,
        url: publicUrlData.publicUrl,
        uploadedAt: new Date().toISOString()
      });
    }
  } catch (error) {
    console.error('Error uploading accomplishment files:', error);
    throw new Error(`Failed to upload files: ${error.message || 'Unknown error'}`);
  }

  return fileUrls;
}

// ============================================================
// TRANSPARENCY
// ============================================================
function canonicalTransparencyType(type) {
  return type === 'bids' ? 'bids_projects' : type === 'programs' ? 'programs_projects' : type;
}

function canAccessTransparency(type, session = getCurrentAdminSession()) {
  if (session?.isSuperAdmin) return true;
  return canAccessFeature('transparency', session) &&
    normalizeTransparencyCategories(session?.transparencyCategories).includes(canonicalTransparencyType(type));
}

function syncTransparencyCategoryFilter() {
  const select = document.getElementById('transparencyTypeFilter');
  const previous = canonicalTransparencyType(select.value);
  const allowed = TRANSPARENCY_CATEGORIES.filter(category => canAccessTransparency(category.value));
  select.replaceChildren();
  if (allowed.length !== 1) select.append(new Option(allowed.length ? 'All Types' : 'No assigned categories', ''));
  allowed.forEach(category => select.append(new Option(category.label, category.value)));
  select.value = allowed.length === 1 ? allowed[0].value : allowed.some(category => category.value === previous) ? previous : '';
  select.disabled = allowed.length <= 1;
}

let allTransparency = [];

async function loadTransparency() {
  syncTransparencyCategoryFilter();
  const tbody = document.getElementById('transparencyTableBody');
  if (!tbody) return;

  if (!supabaseClient) {
    const colSpan = tbody.closest('table').querySelectorAll('th').length;
    tbody.innerHTML = `<tr><td colspan="${colSpan}" class="empty-state">Database connection unavailable</td></tr>`;
    return;
  }

  try {
    // Try to fetch from 'transparency' table first
    let allRecords = [];

    try {
      const { data: transparencyData, error: transparencyError } = await supabaseClient
        .from('transparency')
        .select('*')
        .order('created_at', { ascending: false });

      if (!transparencyError && transparencyData) {
        allRecords = allRecords.concat(transparencyData.map(item => ({
          ...item,
          type: canonicalTransparencyType(item.type || 'general')
        })));
      }
    } catch (e) {
      console.log('transparency table not found, trying alternative tables');
    }

    // Try individual transparency tables
    const tableNames = [
      'transparency_annual_budget',
      'transparency_bids_projects',
      'transparency_executive_orders',
      'transparency_financial_reports',
      'transparency_legislative_ordinances',
      'transparency_programs_projects'
    ];

    for (const tableName of tableNames) {
      try {
        const { data, error } = await supabaseClient
          .from(tableName)
          .select('*');

        if (!error && data) {
          let type = tableName.replace('transparency_', '');
          allRecords = allRecords.concat(data.map(item => ({
            ...item,
            type: type
          })));
        }
      } catch (e) {
        console.log(`Table ${tableName} not available`);
      }
    }

    // Sort by created_at or date field
    allRecords.sort((a, b) => {
      const dateA = new Date(a.created_at || a.date || 0);
      const dateB = new Date(b.created_at || b.date || 0);
      return dateB - dateA;
    });

    allTransparency = allRecords.filter(record => canAccessTransparency(record.type));
    filterTransparency();
  } catch (error) {
    console.error('Error loading transparency records:', error);
    showToast('Failed to load transparency records from database', 'error');
  }
}

function renderTransparencyTable(transparencyData) {
  const tbody = document.getElementById('transparencyTableBody');
  tableExportRows.transparencyTableBody = transparencyData;
  const colSpan = tbody.closest('table').querySelectorAll('th').length;

  const totalItems = transparencyData.length;
  const totalPages = Math.ceil(totalItems / ITEMS_PER_PAGE);
  const currentPage = paginationState.transparency.current;

  if (currentPage > totalPages && totalPages > 0) {
    paginationState.transparency.current = 1;
    renderTransparencyTable(transparencyData);
    return;
  }

  if (transparencyData.length === 0) {
    tbody.innerHTML = `<tr><td colspan="${colSpan}" class="empty-state">No transparency records found</td></tr>`;
    renderTransparencyPagination(0);
    return;
  }

  const startIdx = (currentPage - 1) * ITEMS_PER_PAGE;
  const endIdx = startIdx + ITEMS_PER_PAGE;
  const pageData = transparencyData.slice(startIdx, endIdx);

  tbody.innerHTML = '';
  pageData.forEach(t => {
    const tr = document.createElement('tr');

    const tdTitle = document.createElement('td');
    tdTitle.textContent = t.title || 'N/A';
    tdTitle.style.fontWeight = '600';

    const tdType = document.createElement('td');
    const typeText = (t.type || '').replace(/_/g, ' ').toUpperCase();
    tdType.textContent = typeText;
    tdType.style.fontSize = '13px';
    tdType.style.textTransform = 'capitalize';

    const tdDate = document.createElement('td');
    tdDate.textContent = formatDate(t.created_at);
    tdDate.style.fontSize = '13px';

    const tdUpdated = document.createElement('td');
    tdUpdated.textContent = formatDate(t.updated_at);
    tdUpdated.style.fontSize = '13px';

    const tdActions = document.createElement('td');
    const actionsDiv = document.createElement('div');
    actionsDiv.className = 'action-btns';

    const viewBtn = document.createElement('button');
    viewBtn.className = 'btn btn-sm btn-edit btn-icon';
    viewBtn.title = 'View/Edit';
    viewBtn.innerHTML = '<i class="fa-solid fa-pen-to-square"></i>';
    viewBtn.addEventListener('click', () => openEditTransparencyModal(t.id));

    const deleteBtn = document.createElement('button');
    deleteBtn.className = 'btn btn-sm btn-delete btn-icon';
    deleteBtn.title = 'Delete';
    deleteBtn.innerHTML = '<i class="fa-solid fa-trash"></i>';
    deleteBtn.addEventListener('click', () => openDeleteTransparency(t.id, t.title || 'Record'));

    actionsDiv.appendChild(viewBtn);
    actionsDiv.appendChild(deleteBtn);
    tdActions.appendChild(actionsDiv);

    tr.appendChild(tdTitle);
    tr.appendChild(tdType);
    tr.appendChild(tdDate);
    tr.appendChild(tdUpdated);
    tr.appendChild(tdActions);

    tbody.appendChild(tr);
  });

  renderTransparencyPagination(totalItems);
}

function renderTransparencyPagination(totalItems) {
  const paginationEl = document.getElementById('transparencyPagination');
  const showingEl = document.getElementById('transparencyShowing');
  if (!paginationEl || !showingEl) return;

  const totalPages = Math.ceil(totalItems / ITEMS_PER_PAGE);
  const currentPage = paginationState.transparency.current;
  paginationState.transparency.total = totalPages;
  showingEl.textContent = `Showing ${Math.min(currentPage * ITEMS_PER_PAGE, totalItems)} of ${totalItems} entries`;

  if (totalPages <= 1) {
    paginationEl.innerHTML = '';
    return;
  }

  let html = `<button class="page-btn prev-btn" data-page="${currentPage - 1}" ${currentPage === 1 ? 'disabled' : ''}><i class="fa-solid fa-chevron-left"></i></button>`;

  const maxButtons = 5;
  let startPage = Math.max(1, currentPage - Math.floor(maxButtons / 2));
  let endPage = Math.min(totalPages, startPage + maxButtons - 1);
  if (endPage - startPage + 1 < maxButtons) {
    startPage = Math.max(1, endPage - maxButtons + 1);
  }

  if (startPage > 1) {
    html += `<button class="page-btn" data-page="1">1</button>`;
    if (startPage > 2) html += `<span class="page-ellipsis">...</span>`;
  }

  for (let i = startPage; i <= endPage; i++) {
    html += `<button class="page-btn ${i === currentPage ? 'active' : ''}" data-page="${i}">${i}</button>`;
  }

  if (endPage < totalPages) {
    if (endPage < totalPages - 1) html += `<span class="page-ellipsis">...</span>`;
    html += `<button class="page-btn" data-page="${totalPages}">${totalPages}</button>`;
  }

  html += `<button class="page-btn next-btn" data-page="${currentPage + 1}" ${currentPage === totalPages ? 'disabled' : ''}><i class="fa-solid fa-chevron-right"></i></button>`;
  paginationEl.innerHTML = html;

  paginationEl.querySelectorAll('.page-btn').forEach(btn => {
    btn.addEventListener('click', (e) => {
      e.preventDefault();
      const page = parseInt(btn.dataset.page);
      if (page >= 1 && page <= totalPages) {
        paginationState.transparency.current = page;
        filterTransparency();
        window.scrollTo(0, 0);
      }
    });
  });
}

function setTransparencyRecordType(type) {
  const category = TRANSPARENCY_CATEGORIES.find(item => item.value === canonicalTransparencyType(type));
  document.getElementById('transparencyCurrentType').value = category?.value || '';
  document.getElementById('transparencyModalTitle').textContent = category
    ? `Add ${category.label} Record` : 'Add Transparency Record';
}

function openTransparencyModal() {
  const typeFilter = document.getElementById('transparencyTypeFilter');
  const selectedType = canonicalTransparencyType(typeFilter ? typeFilter.value : '');
  const chooseCategory = getCurrentAdminSession().isSuperAdmin && !selectedType;
  if ((!selectedType && !chooseCategory) || (selectedType && !canAccessTransparency(selectedType))) {
    showToast('Select an assigned transparency category first.', 'error');
    return;
  }

  const categoryGroup = document.getElementById('transparencyRecordCategoryGroup');
  const categorySelect = document.getElementById('transparencyRecordCategory');
  categoryGroup.hidden = !chooseCategory;
  if (chooseCategory) {
    categorySelect.replaceChildren(new Option('Select category', ''));
    TRANSPARENCY_CATEGORIES.forEach(category =>
      categorySelect.append(new Option(category.label, category.value)));
    categorySelect.value = '';
  }
  setTransparencyRecordType(chooseCategory ? '' : selectedType);
  document.getElementById('transparencyEditId').value = '';
  document.getElementById('transparencyTitle').value = '';
  document.getElementById('transparencyDescription').value = '';
  document.getElementById('transparencyDisplayOrder').value = '';
  document.getElementById('transparencyIsPublished').checked = false;
  document.getElementById('transparencyPdfUrl').value = '';
  document.getElementById('transparencyPdfBase64').value = '';
  document.getElementById('transparencyPdfPreview').innerHTML = '<i class="fa-solid fa-file-pdf"></i><span>No PDF selected</span>';
  document.getElementById('transparencySaveBtn').innerHTML = '<i class="fa-solid fa-floppy-disk"></i> Save';
  setupTransparencyPdfUpload();
  document.getElementById('transparencyModal').classList.add('active');
  updateTransparencyTable();
}

async function openEditTransparencyModal(id) {
  if (!supabaseClient) {
    showToast('Database connection unavailable', 'error');
    return;
  }

  const tables = {
    'annual_budget': 'transparency_annual_budget',
    'bids_projects': 'transparency_bids_projects',
    'executive_orders': 'transparency_executive_orders',
    'financial_reports': 'transparency_financial_reports',
    'legislative_ordinances': 'transparency_legislative_ordinances',
    'programs_projects': 'transparency_programs_projects'
  };

  const typeLabels = {
    'annual_budget': 'Annual Budget',
    'bids_projects': 'Bids',
    'executive_orders': 'Executive Orders',
    'financial_reports': 'Financial Reports',
    'legislative_ordinances': 'Legislative Ordinances',
    'programs_projects': 'Programs'
  };

  try {
    let foundData = null;
    let foundType = null;

    // Search through all transparency tables to find the record
    for (const [typeKey, tableName] of Object.entries(tables)) {
      if (!canAccessTransparency(typeKey)) continue;
      const { data, error } = await supabaseClient
        .from(tableName)
        .select('*')
        .eq('id', id)
        .single();

      if (!error && data) {
        foundData = data;
        foundType = typeKey;
        break;
      }
    }

    if (!foundData) {
      showToast('Record not found', 'error');
      return;
    }

    const typeLabel = typeLabels[foundType] || 'Transparency';
    document.getElementById('transparencyModalTitle').textContent = `Edit ${typeLabel} Record`;
    document.getElementById('transparencyRecordCategoryGroup').hidden = true;
    document.getElementById('transparencyEditId').value = id;
    document.getElementById('transparencyCurrentType').value = foundType;
    document.getElementById('transparencySaveBtn').innerHTML = '<i class="fa-solid fa-floppy-disk"></i> Update';
    document.getElementById('transparencyTitle').value = foundData.title || '';
    document.getElementById('transparencyDescription').value = foundData.description || '';
    document.getElementById('transparencyDisplayOrder').value = foundData.display_order || '';
    document.getElementById('transparencyIsPublished').checked = foundData.is_published || false;

    if (foundData.pdf_url) {
      document.getElementById('transparencyPdfPreview').innerHTML = '<i class="fa-solid fa-file-pdf"></i><span>' + foundData.pdf_url.split('/').pop() + '</span>';
    }

    document.getElementById('transparencyModal').classList.add('active');
  } catch (error) {
    console.error('Error loading transparency record:', error);
    showToast('Failed to load record data', 'error');
  }
}

function closeTransparencyModal() {
  document.getElementById('transparencyModal').classList.remove('active');
}

async function saveTransparency() {
  if (document.getElementById('transparencySaveBtn').disabled) return;
  const editId = document.getElementById('transparencyEditId').value;
  const currentType = document.getElementById('transparencyCurrentType').value;
  const title = document.getElementById('transparencyTitle').value.trim();
  const description = document.getElementById('transparencyDescription').value.trim();
  const displayOrder = document.getElementById('transparencyDisplayOrder').value;
  const isPublished = document.getElementById('transparencyIsPublished').checked;
  const pdfFile = document.getElementById('transparencyPdfUrl').files[0];

  if (!title) {
    showToast('Please enter a title.', 'error');
    return;
  }

  if (!currentType) {
    showToast('Please select a transparency type', 'error');
    return;
  }

  if (!editId && !pdfFile) {
    showToast('Please upload a PDF for new records', 'error');
    return;
  }

  const tableMap = {
    'annual_budget': 'transparency_annual_budget',
    'bids_projects': 'transparency_bids_projects',
    'executive_orders': 'transparency_executive_orders',
    'financial_reports': 'transparency_financial_reports',
    'legislative_ordinances': 'transparency_legislative_ordinances',
    'programs_projects': 'transparency_programs_projects'
  };

  const tableName = tableMap[currentType];
  if (!tableName || !canAccessTransparency(currentType)) {
    showToast('You cannot manage this transparency category.', 'error');
    return;
  }

  const typeLabels = {
    'annual_budget': 'Annual Budget',
    'bids_projects': 'Bids',
    'executive_orders': 'Executive Orders',
    'financial_reports': 'Financial Reports',
    'legislative_ordinances': 'Legislative Ordinances',
    'programs_projects': 'Programs'
  };
  const typeLabel = typeLabels[currentType] || 'Transparency';

  const saveBtn = document.getElementById('transparencySaveBtn');
  saveBtn.innerHTML = '<span class="loading-spinner"></span> Saving...';
  saveBtn.disabled = true;

  try {
    if (!supabaseClient) {
      showToast('Database connection unavailable', 'error');
      saveBtn.innerHTML = '<i class="fa-solid fa-floppy-disk"></i> Save';
      saveBtn.disabled = false;
      return;
    }

    await ensureUniqueRecordName(tableName, 'title', title, editId, 'A document with this title in this category');

    let pdfUrl = null;

    // Handle PDF upload if new file selected
    if (pdfFile) {
      const bucket = 'transparency-pdfs';
      const fileName = `${currentType}_${Date.now()}_${pdfFile.name}`;

      const { data, error: uploadError } = await supabaseClient.storage
        .from(bucket)
        .upload(fileName, pdfFile);

      if (uploadError) throw uploadError;

      const { data: { publicUrl } } = supabaseClient.storage
        .from(bucket)
        .getPublicUrl(fileName);

      pdfUrl = publicUrl;
    }

    const payload = {
      title,
      description: description || null,
      display_order: parseInt(displayOrder) || 0,
      is_published: isPublished
    };

    if (pdfUrl) {
      payload.pdf_url = pdfUrl;
    }

    if (editId) {
      // Update existing record
      const { error } = await supabaseClient
        .from(tableName)
        .update(payload)
        .eq('id', editId);

      if (error) throw error;
      showToast('Record updated successfully!', 'success');
      addNotification('Transparency Updated', `${typeLabel} record "${title}" has been updated`, 'success');
    } else {
      // Insert new record
      const { error } = await supabaseClient
        .from(tableName)
        .insert([payload]);

      if (error) throw error;
      showToast('Record added successfully!', 'success');
      addNotification('Transparency Added', `${typeLabel} record "${title}" created`, 'success');
    }

    closeTransparencyModal();
    loadTransparency();
  } catch (error) {
    console.error('Error saving transparency record:', error);
    showToast('Failed to save record: ' + recordSaveError(error, 'A document with this title in this category'), 'error');
  } finally {
    saveBtn.innerHTML = '<i class="fa-solid fa-floppy-disk"></i> Save';
    saveBtn.disabled = false;
  }
}

function openDeleteTransparency(id, title) {
  deleteTarget = id;
  deleteType = 'transparency';
  document.getElementById('deleteMessage').textContent = `Are you sure you want to delete "${title}"? This action cannot be undone.`;
  document.getElementById('deleteModal').classList.add('active');
}

// ============================================================
// TOURIST GUIDE
// ============================================================
let allTourist = [];
let allPlaceReviews = [];

async function loadTourist() {
  const tbody = document.getElementById('touristTableBody');
  if (!tbody) return;

  if (!supabaseClient) {
    const colSpan = tbody.closest('table').querySelectorAll('th').length;
    tbody.innerHTML = `<tr><td colspan="${colSpan}" class="empty-state">Database connection unavailable</td></tr>`;
    return;
  }

  try {
    let data = null;
    let error = null;

    // Try primary table name first
    const tableNames = [
      'places',
      'tourist_guides',
      'tourist_guide',
      'tourist_destinations',
      'tourist_spots',
      'tourist_places'
    ];

    for (const tableName of tableNames) {
      try {
        const result = await supabaseClient
          .from(tableName)
          .select('*')
          .order('created_at', { ascending: false });

        if (!result.error) {
          data = result.data;
          error = null;
          console.log(`Successfully fetched from table: ${tableName}`);
          break;
        }
      } catch (e) {
        console.log(`Table ${tableName} not found, trying next...`);
        continue;
      }
    }

    // Load reviews data
    try {
      const reviewsResult = await supabaseClient
        .from('place_reviews')
        .select('*')
        .eq('status', 'approved');
      allPlaceReviews = reviewsResult.data || [];

      // Fetch user display names for reviews
      if (allPlaceReviews.length > 0) {
        const userIds = [...new Set(allPlaceReviews.map(r => r.user_id).filter(Boolean))];

        if (userIds.length > 0) {
          try {
            const { data: users } = await supabaseClient
              .from('users')
              .select('id, display_name, email')
              .in('id', userIds);

            const userMap = {};
            (users || []).forEach(u => {
              const name = (u.display_name && u.display_name.trim())
                ? u.display_name
                : (u.email && u.email.trim()
                  ? u.email
                  : u.id.substring(0, 12));
              userMap[u.id] = name;
            });

            allPlaceReviews = allPlaceReviews.map(r => ({
              ...r,
              display_name: userMap[r.user_id] || r.reviewer_name || 'Anonymous'
            }));
          } catch (userError) {
            console.warn('Error fetching user display names:', userError);
            // Use any available name fields
            allPlaceReviews = allPlaceReviews.map(r => ({
              ...r,
              display_name: r.reviewer_name || 'Anonymous'
            }));
          }
        } else {
          // No user IDs, use reviewer_name field if available
          allPlaceReviews = allPlaceReviews.map(r => ({
            ...r,
            display_name: r.reviewer_name || 'Anonymous'
          }));
        }
      }
    } catch (e) {
      console.log('Could not load reviews');
      allPlaceReviews = [];
    }

    if (error) throw error;
    if (!data) {
      console.warn('No tourist data found in any table');
      const colSpan = tbody.closest('table').querySelectorAll('th').length;
      tbody.innerHTML = `<tr><td colspan="${colSpan}" class="empty-state">No tourist destinations found</td></tr>`;
      return;
    }

    allTourist = data || [];
    populateTouristCategoryFilter();
    renderTouristTable(allTourist);
  } catch (error) {
    console.error('Error loading tourist guides:', error);
    showToast('Failed to load tourist destinations from database: ' + error.message, 'error');
  }
}

function renderTouristTable(touristData) {
  const tbody = document.getElementById('touristTableBody');
  tableExportRows.touristTableBody = touristData;
  const colSpan = tbody.closest('table').querySelectorAll('th').length;

  const totalItems = touristData.length;
  const totalPages = Math.ceil(totalItems / ITEMS_PER_PAGE);
  const currentPage = paginationState.tourist.current;

  if (currentPage > totalPages && totalPages > 0) {
    paginationState.tourist.current = 1;
    renderTouristTable(touristData);
    return;
  }

  if (touristData.length === 0) {
    tbody.innerHTML = `<tr><td colspan="${colSpan}" class="empty-state">No tourist destinations found</td></tr>`;
    renderTouristPagination(0);
    return;
  }

  const startIdx = (currentPage - 1) * ITEMS_PER_PAGE;
  const endIdx = startIdx + ITEMS_PER_PAGE;
  const pageData = touristData.slice(startIdx, endIdx);

  tbody.innerHTML = '';
  pageData.forEach(t => {
    const tr = document.createElement('tr');

    const tdName = document.createElement('td');
    tdName.textContent = t.name || 'N/A';
    tdName.style.fontWeight = '600';

    const tdLocation = document.createElement('td');
    tdLocation.textContent = t.location || 'N/A';
    tdLocation.style.fontSize = '13px';

    const tdCategory = document.createElement('td');
    const categoryBadge = document.createElement('span');
    categoryBadge.className = 'status-badge status-reviewing';
    categoryBadge.textContent = t.category || 'General';
    tdCategory.appendChild(categoryBadge);

    const tdDescription = document.createElement('td');
    const preview = (t.description || 'No description').substring(0, 40) + '...';
    tdDescription.textContent = preview;
    tdDescription.style.fontSize = '13px';
    tdDescription.style.color = '#6b7280';

    const tdReviews = document.createElement('td');
    const placeReviews = allPlaceReviews.filter(r => r.place_id === t.id);
    const avgRating = placeReviews.length > 0
      ? (placeReviews.reduce((sum, r) => sum + r.rating, 0) / placeReviews.length).toFixed(1)
      : 0;

    if (placeReviews.length > 0) {
      const reviewsButton = document.createElement('button');
      reviewsButton.type = 'button';
      reviewsButton.className = 'tourist-review-summary';
      reviewsButton.setAttribute('aria-label', `${avgRating} out of 5 from ${placeReviews.length} review${placeReviews.length === 1 ? '' : 's'}. View reviews for ${t.name || 'destination'}`);
      reviewsButton.title = 'View reviews';
      reviewsButton.addEventListener('click', () => {
        openPlaceReviewsModal(t.id, t.name);
      });
      const star = document.createElement('span');
      star.className = 'tourist-review-star';
      star.setAttribute('aria-hidden', 'true');
      star.textContent = '★';
      const ratingText = document.createElement('span');
      ratingText.textContent = `${avgRating} (${placeReviews.length})`;
      reviewsButton.append(star, ratingText);
      tdReviews.appendChild(reviewsButton);
    } else {
      const noReviewsSpan = document.createElement('span');
      noReviewsSpan.textContent = 'No reviews yet';
      noReviewsSpan.style.cssText = 'color: #9ca3af; font-size: 13px; font-weight: 500;';
      tdReviews.appendChild(noReviewsSpan);
    }

    const tdDate = document.createElement('td');
    tdDate.textContent = formatDate(t.created_at);
    tdDate.style.fontSize = '13px';

    const tdUpdated = document.createElement('td');
    tdUpdated.textContent = formatDate(t.updated_at);
    tdUpdated.style.fontSize = '13px';

    const tdActions = document.createElement('td');
    const actionsDiv = document.createElement('div');
    actionsDiv.className = 'action-btns';

    const editBtn = document.createElement('button');
    editBtn.className = 'btn btn-sm btn-edit btn-icon';
    editBtn.title = 'Edit';
    editBtn.innerHTML = '<i class="fa-solid fa-pen-to-square"></i>';
    editBtn.addEventListener('click', () => openEditTouristModal(t.id));

    const deleteBtn = document.createElement('button');
    deleteBtn.className = 'btn btn-sm btn-delete btn-icon';
    deleteBtn.title = 'Delete';
    deleteBtn.innerHTML = '<i class="fa-solid fa-trash"></i>';
    deleteBtn.addEventListener('click', () => openDeleteTourist(t.id, t.name || 'Destination'));

    actionsDiv.appendChild(editBtn);
    actionsDiv.appendChild(deleteBtn);
    tdActions.appendChild(actionsDiv);

    tr.appendChild(tdName);
    tr.appendChild(tdLocation);
    tr.appendChild(tdCategory);
    tr.appendChild(tdDescription);
    tr.appendChild(tdReviews);
    tr.appendChild(tdDate);
    tr.appendChild(tdUpdated);
    tr.appendChild(tdActions);

    tbody.appendChild(tr);
  });

  renderTouristPagination(totalItems);
}

function renderTouristPagination(totalItems) {
  const paginationEl = document.getElementById('touristPagination');
  const showingEl = document.getElementById('touristShowing');
  if (!paginationEl || !showingEl) return;

  const totalPages = Math.ceil(totalItems / ITEMS_PER_PAGE);
  const currentPage = paginationState.tourist.current;
  paginationState.tourist.total = totalPages;
  showingEl.textContent = `Showing ${Math.min(currentPage * ITEMS_PER_PAGE, totalItems)} of ${totalItems} entries`;

  if (totalPages <= 1) {
    paginationEl.innerHTML = '';
    return;
  }

  let html = `<button class="page-btn prev-btn" data-page="${currentPage - 1}" ${currentPage === 1 ? 'disabled' : ''}><i class="fa-solid fa-chevron-left"></i></button>`;

  const maxButtons = 5;
  let startPage = Math.max(1, currentPage - Math.floor(maxButtons / 2));
  let endPage = Math.min(totalPages, startPage + maxButtons - 1);
  if (endPage - startPage + 1 < maxButtons) {
    startPage = Math.max(1, endPage - maxButtons + 1);
  }

  if (startPage > 1) {
    html += `<button class="page-btn" data-page="1">1</button>`;
    if (startPage > 2) html += `<span class="page-ellipsis">...</span>`;
  }

  for (let i = startPage; i <= endPage; i++) {
    html += `<button class="page-btn ${i === currentPage ? 'active' : ''}" data-page="${i}">${i}</button>`;
  }

  if (endPage < totalPages) {
    if (endPage < totalPages - 1) html += `<span class="page-ellipsis">...</span>`;
    html += `<button class="page-btn" data-page="${totalPages}">${totalPages}</button>`;
  }

  html += `<button class="page-btn next-btn" data-page="${currentPage + 1}" ${currentPage === totalPages ? 'disabled' : ''}><i class="fa-solid fa-chevron-right"></i></button>`;
  paginationEl.innerHTML = html;

  paginationEl.querySelectorAll('.page-btn').forEach(btn => {
    btn.addEventListener('click', (e) => {
      e.preventDefault();
      const page = parseInt(btn.dataset.page);
      if (page >= 1 && page <= totalPages) {
        paginationState.tourist.current = page;
        filterTourist();
        window.scrollTo(0, 0);
      }
    });
  });
}

function populateTouristCategoryFilter() {
  const categoryFilter = document.getElementById('touristCategoryFilter');
  if (!categoryFilter) return;

  const categories = [...new Set(allTourist.map(t => t.category ? t.category.trim() : null).filter(Boolean))].sort();

  const currentValue = categoryFilter.value;
  categoryFilter.innerHTML = '<option value="">All Categories</option>';

  categories.forEach(cat => {
    const option = document.createElement('option');
    option.value = cat;
    option.textContent = cat;
    categoryFilter.appendChild(option);
  });

  categoryFilter.value = currentValue;
}

function openTouristModal() {
  document.getElementById('touristModalTitle').textContent = 'Add Tourist Destination';
  document.getElementById('touristEditId').value = '';
  document.getElementById('touristName').value = '';
  document.getElementById('touristLocation').value = '';
  document.getElementById('touristFullAddress').value = '';
  document.getElementById('touristCategory').value = '';
  document.getElementById('touristDescription').value = '';
  document.getElementById('touristContactNumber').value = '';
  document.getElementById('touristWebsiteUrl').value = '';
  document.getElementById('touristLatitude').value = '';
  document.getElementById('touristLongitude').value = '';
  document.getElementById('touristDistanceLabel').value = '';
  document.getElementById('touristIsFeatured').checked = false;
  document.getElementById('touristIsPublished').checked = false;
  document.getElementById('touristImage').value = '';
  setGalleryImages('tourist');
  document.getElementById('touristSaveBtn').innerHTML = '<i class="fa-solid fa-floppy-disk"></i> Save';
  document.getElementById('touristModal').classList.add('active');
}

async function openEditTouristModal(id) {
  document.getElementById('touristModalTitle').textContent = 'Edit Tourist Destination';
  document.getElementById('touristEditId').value = id;
  document.getElementById('touristSaveBtn').innerHTML = '<i class="fa-solid fa-floppy-disk"></i> Update';

  if (!supabaseClient) {
    showToast('Database connection unavailable', 'error');
    return;
  }

  try {
    // Find the record from the already loaded data
    const record = allTourist.find(t => t.id === id);

    if (record) {
      document.getElementById('touristName').value = record.name || '';
      document.getElementById('touristLocation').value = record.short_location || record.location || '';
      document.getElementById('touristFullAddress').value = record.full_address || '';
      document.getElementById('touristCategory').value = record.category || '';
      document.getElementById('touristDescription').value = record.description || '';
      document.getElementById('touristContactNumber').value = record.phone || '';
      document.getElementById('touristWebsiteUrl').value = record.website_url || '';
      document.getElementById('touristLatitude').value = record.latitude || '';
      document.getElementById('touristLongitude').value = record.longitude || '';
      document.getElementById('touristDistanceLabel').value = record.distance_label || '';
      document.getElementById('touristIsFeatured').checked = record.is_featured || false;
      document.getElementById('touristIsPublished').checked = record.is_published || false;

      document.getElementById('touristImage').value = '';
      setGalleryImages('tourist', record);
    } else {
      throw new Error('Record not found');
    }
  } catch (error) {
    console.error('Error loading tourist guide:', error);
    showToast('Failed to load destination data', 'error');
    return;
  }

  document.getElementById('touristModal').classList.add('active');
}

function closeTouristModal() {
  document.getElementById('touristModal').classList.remove('active');
}

async function saveTourist() {
  if (document.getElementById('touristSaveBtn').disabled) return;
  const editId = document.getElementById('touristEditId').value;
  const name = document.getElementById('touristName').value.trim();
  const shortLocation = document.getElementById('touristLocation').value.trim();
  const fullAddress = document.getElementById('touristFullAddress').value.trim();
  const category = document.getElementById('touristCategory').value;
  const description = document.getElementById('touristDescription').value.trim();
  const contactNumber = document.getElementById('touristContactNumber').value.trim();
  const latitude = document.getElementById('touristLatitude').value.trim();
  const longitude = document.getElementById('touristLongitude').value.trim();
  const distanceLabel = document.getElementById('touristDistanceLabel').value.trim();
  const isFeatured = document.getElementById('touristIsFeatured').checked;
  const isPublished = document.getElementById('touristIsPublished').checked;

  if (!name || !shortLocation || !category) {
    showToast('Please fill all required fields: Name, Location, Category', 'error');
    return;
  }

  const latNum = parseFloat(latitude);
  const lonNum = parseFloat(longitude);

  if (!latitude || !longitude || isNaN(latNum) || isNaN(lonNum)) {
    showToast('Please enter valid latitude and longitude numbers', 'error');
    return;
  }

  const saveBtn = document.getElementById('touristSaveBtn');
  saveBtn.innerHTML = '<span class="loading-spinner"></span> Saving...';
  saveBtn.disabled = true;

  try {
    if (!supabaseClient) {
      showToast('Database connection unavailable', 'error');
      saveBtn.innerHTML = '<i class="fa-solid fa-floppy-disk"></i> Save';
      saveBtn.disabled = false;
      return;
    }

    await ensureUniqueRecordName('places', 'name', name, editId, 'A tourist spot with this name');

    const imageUrls = await uploadGalleryImages('tourist');

    const payload = {
      name,
      short_location: shortLocation,
      full_address: fullAddress || null,
      category,
      description: description || null,
      phone: contactNumber || null,
      latitude: latNum,
      longitude: lonNum,
      distance_label: distanceLabel || null,
      is_featured: isFeatured,
      is_published: isPublished,
      image_url: imageUrls[0] || null,
      image_urls: imageUrls
    };

    const { data, error } = editId
      ? await supabaseClient.from('places').update(payload).eq('id', editId)
      : await supabaseClient.from('places').insert([payload]);

    if (error) {
      if (error.code === '23505') throw error;
      console.error('Database error:', error);
      if (error.message && error.message.includes('row-level security')) {
        throw new Error('Access denied: The RLS policy for the places table does not allow this operation. Please contact your admin.');
      }
      throw new Error(error.message || 'Failed to save destination');
    }

    showToast('Destination ' + (editId ? 'updated' : 'added') + ' successfully!', 'success');
    addNotification('Tourist ' + (editId ? 'Updated' : 'Added'), `Destination "${name}" has been ${editId ? 'updated' : 'created'}`, 'success');
    closeTouristModal();
    loadTourist();
  } catch (error) {
    console.error('Error saving tourist guide:', error);
    showToast('Failed to save destination: ' + recordSaveError(error, 'A tourist spot with this name'), 'error');
  } finally {
    saveBtn.innerHTML = '<i class="fa-solid fa-floppy-disk"></i> Save';
    saveBtn.disabled = false;
  }
}

function openDeleteTourist(id, name) {
  deleteTarget = id;
  deleteType = 'tourist';
  document.getElementById('deleteMessage').textContent = `Are you sure you want to delete "${name}"? This action cannot be undone.`;
  document.getElementById('deleteModal').classList.add('active');
}

// ============================================================
// ONLINE SERVICES
// ============================================================
function openAppointmentAvailabilityModal() {
  const modal = document.getElementById('appointmentAvailabilityModal');
  if (!modal) return;
  modal.classList.add('active');
  document.getElementById('appointmentAvailabilityTrigger')?.setAttribute('aria-expanded', 'true');
  modal.querySelector('.modal-close')?.focus();
  loadAppointmentUnavailableDates();
}

function closeAppointmentAvailabilityModal() {
  document.getElementById('appointmentAvailabilityModal')?.classList.remove('active');
  const trigger = document.getElementById('appointmentAvailabilityTrigger');
  trigger?.setAttribute('aria-expanded', 'false');
  trigger?.focus();
}

async function loadAppointmentUnavailableDates() {
  const container = document.getElementById('appointmentUnavailableDates');
  if (!container) return;
  if (!supabaseClient) {
    container.textContent = 'Database connection unavailable.';
    return;
  }
  container.textContent = 'Loading unavailable dates...';

  const { data, error } = await supabaseClient
    .from('appointment_unavailable_dates')
    .select('date, reason')
    .order('date', { ascending: true });

  if (error) {
    container.textContent = 'Date management is unavailable. Run supabase/appointment_unavailable_dates_setup.sql in Supabase.';
    return;
  }

  container.replaceChildren();
  if (!data?.length) {
    container.textContent = 'No additional dates have been disabled.';
    return;
  }

  for (const entry of data) {
    const row = document.createElement('div');
    row.className = 'appointment-closure-row';
    const details = document.createElement('div');
    const date = document.createElement('strong');
    date.textContent = new Date(`${entry.date}T12:00:00`).toLocaleDateString('en-PH', {
      year: 'numeric', month: 'long', day: 'numeric'
    });
    const reason = document.createElement('span');
    reason.textContent = entry.reason || 'Unavailable for appointments';
    details.append(date, reason);

    const removeButton = document.createElement('button');
    removeButton.type = 'button';
    removeButton.className = 'btn btn-secondary btn-sm';
    removeButton.textContent = 'Enable Date';
    removeButton.addEventListener('click', () => removeAppointmentUnavailableDate(entry.date));
    row.append(details, removeButton);
    container.appendChild(row);
  }
}

async function addAppointmentUnavailableDate() {
  if (!supabaseClient) {
    showToast('Database connection unavailable.', 'error');
    return;
  }
  const dateInput = document.getElementById('appointmentClosedDate');
  const reasonInput = document.getElementById('appointmentClosedReason');
  const date = dateInput.value;
  if (!date) {
    showToast('Choose a date to disable.', 'error');
    return;
  }

  const { error } = await supabaseClient.from('appointment_unavailable_dates').insert({
    date,
    reason: reasonInput.value.trim() || 'Unavailable for appointments'
  });
  if (error) {
    showToast(error.code === '23505' ? 'This date is already disabled.' : `Could not disable date: ${error.message}`, 'error');
    return;
  }
  dateInput.value = '';
  reasonInput.value = '';
  showToast('Appointment date disabled.', 'success');
  loadAppointmentUnavailableDates();
}

async function removeAppointmentUnavailableDate(date) {
  if (!supabaseClient) {
    showToast('Database connection unavailable.', 'error');
    return;
  }
  const { error } = await supabaseClient
    .from('appointment_unavailable_dates')
    .delete()
    .eq('date', date);
  if (error) {
    showToast(`Could not enable date: ${error.message}`, 'error');
    return;
  }
  showToast('Date enabled for appointments, unless it is a holiday or closed weekday.', 'success');
  loadAppointmentUnavailableDates();
}

let allServices = [];
let serviceTableName = null;

async function loadServicesData() {
  if (!supabaseClient) {
    console.warn('Supabase client not available');
    return;
  }

  try {
    let combinedData = [];

    const serviceTables = [
      { name: 'birth_certificate_appointments', type: 'Birth Certificate' },
      { name: 'cenodeath_appointments', type: 'Cenodeath Appointments' },
      { name: 'cenomar_appointments', type: 'Cenomar Appointments' },
      { name: 'death_certificate_appointments', type: 'Death Certificate' },
      { name: 'marriage_certificate_appointments', type: 'Marriage Certificate' },
      { name: 'facility_borrow_requests', type: 'Facility Borrowing' }
    ];

    for (const serviceTable of serviceTables) {
      try {
        const { data, error } = await supabaseClient
          .from(serviceTable.name)
          .select('*')
          .order('created_at', { ascending: false });

        if (!error && data && data.length > 0) {
          const mappedData = data.map(item => ({
            id: String(item.id),
            name: item.name || item.appointment_type || item.service_name || item.title || serviceTable.type,
            type: serviceTable.type,
            requested_by: item.requested_by || item.applicant_name || item.customer_name || item.client_name || item.submitted_by || item.first_name || 'N/A',
            status: item.status || item.appointment_status || 'pending',
            contact_number: item.contact_number || item.phone || item.phone_number || item.mobile || '',
            description: item.description || item.notes || item.details || item.purpose || '',
            created_at: item.created_at || item.created_date || null,
            date: item.date || item.appointment_date || item.created_at || item.created_date || new Date().toISOString(),
            table_name: serviceTable.name,
            ...item
          }));

          combinedData = combinedData.concat(mappedData);
        }
      } catch (e) {
        console.log(`Could not fetch from ${serviceTable.name}`);
      }
    }

    if (combinedData.length === 0) {
      console.warn('No service data found');
      return;
    }

    const userIds = [...new Set(combinedData.map(item => item.user_id).filter(id => id))];
    const userDisplayNames = {};

    if (userIds.length > 0 && supabaseClient) {
      try {
        const { data: users } = await supabaseClient
          .from('users')
          .select('id, display_name')
          .in('id', userIds);

        if (users) {
          users.forEach(user => {
            userDisplayNames[user.id] = user.display_name;
          });
        }
      } catch (e) {
        console.log('Could not fetch user display names');
      }
    }

    combinedData = combinedData.map(item => ({
      ...item,
      display_name: userDisplayNames[item.user_id] || item.display_name || item.requester_name || item.full_name || item.name || null
    }));

    combinedData.sort((a, b) => {
      const dateA = new Date(a.created_at);
      const dateB = new Date(b.created_at);
      return dateB - dateA;
    });

    allServices = combinedData;
    console.log(`✓ Loaded ${allServices.length} services into memory`);
  } catch (error) {
    console.error('Error loading services data:', error);
  }
}

async function loadServices() {
  const tbody = document.getElementById('serviceTableBody');
  if (!tbody) return;

  if (!supabaseClient) {
    const colSpan = tbody.closest('table').querySelectorAll('th').length;
    tbody.innerHTML = `<tr><td colspan="${colSpan}" class="empty-state">Database connection unavailable</td></tr>`;
    return;
  }

  try {
    let combinedData = [];

    // Specific service tables from your Supabase
    const serviceTables = [
      { name: 'birth_certificate_appointments', type: 'Birth Certificate' },
      { name: 'cenodeath_appointments', type: 'Cenodeath Appointments' },
      { name: 'cenomar_appointments', type: 'Cenomar Appointments' },
      { name: 'death_certificate_appointments', type: 'Death Certificate' },
      { name: 'marriage_certificate_appointments', type: 'Marriage Certificate' },
      { name: 'facility_borrow_requests', type: 'Facility Borrowing' }
    ];

    console.log('Loading services from all tables...');

    // Fetch from each service table
    for (const serviceTable of serviceTables) {
      try {
        console.log(`Fetching from ${serviceTable.name}...`);

        const { data, error } = await supabaseClient
          .from(serviceTable.name)
          .select('*')
          .order('created_at', { ascending: false });

        if (!error && data && data.length > 0) {
          console.log(`✓ Got ${data.length} records from ${serviceTable.name}`);

          // Map each record to include the service type - ensure ID is always a string
          const mappedData = data.map(item => ({
            id: String(item.id), // Convert to string for consistent comparison
            name: item.name || item.appointment_type || item.service_name || item.title || serviceTable.type,
            type: serviceTable.type,
            requested_by: item.requested_by || item.applicant_name || item.customer_name || item.client_name || item.submitted_by || item.first_name || 'N/A',
            status: item.status || item.appointment_status || 'pending',
            contact_number: item.contact_number || item.phone || item.phone_number || item.mobile || '',
            description: item.description || item.notes || item.details || item.purpose || '',
            created_at: item.created_at || item.created_date || null,
            date: item.date || item.appointment_date || item.created_at || item.created_date || new Date().toISOString(),
            table_name: serviceTable.name,
            ...item // Keep all original fields
          }));

          combinedData = combinedData.concat(mappedData);
        } else if (error) {
          console.log(`Table ${serviceTable.name} not found or empty: ${error.message}`);
        } else {
          console.log(`No data in ${serviceTable.name}`);
        }
      } catch (e) {
        console.error(`Error fetching from ${serviceTable.name}:`, e.message);
        continue;
      }
    }

    if (combinedData.length === 0) {
      console.warn('No service data found in any table');
      showToast('No service requests found in any table', 'info');
      const colSpan = tbody.closest('table').querySelectorAll('th').length;
      tbody.innerHTML = `<tr><td colspan="${colSpan}" class="empty-state">No service requests found</td></tr>`;
      return;
    }

    // Fetch display names for all unique user IDs
    const userIds = [...new Set(combinedData.map(item => item.user_id).filter(id => id))];
    const userDisplayNames = {};

    if (userIds.length > 0 && supabaseClient) {
      try {
        const { data: users, error: userError } = await supabaseClient
          .from('users')
          .select('id, display_name')
          .in('id', userIds);

        if (!userError && users) {
          users.forEach(user => {
            userDisplayNames[user.id] = user.display_name;
          });
        }
      } catch (e) {
        console.log('Could not fetch user display names:', e.message);
      }
    }

    // Add display_name to each service record
    combinedData = combinedData.map(item => ({
      ...item,
      display_name: userDisplayNames[item.user_id] || item.display_name || item.requester_name || item.full_name || item.name || null
    }));

    // Sort by date descending
    combinedData.sort((a, b) => {
      const dateA = new Date(a.created_at);
      const dateB = new Date(b.created_at);
      return dateB - dateA;
    });

    allServices = combinedData;
    console.log(`✓ Successfully loaded ${allServices.length} total services`);
    populateServiceCategoryFilter();
    renderServiceTable(allServices);
  } catch (error) {
    console.error('Error loading services:', error);
    showToast('Error loading services: ' + error.message, 'error');
  }
}

function renderServiceTable(servicesData) {
  const tbody = document.getElementById('serviceTableBody');
  tableExportRows.serviceTableBody = servicesData;
  const colSpan = tbody.closest('table').querySelectorAll('th').length;

  const totalItems = servicesData.length;
  const totalPages = Math.ceil(totalItems / ITEMS_PER_PAGE);
  const currentPage = paginationState.services.current;

  if (currentPage > totalPages && totalPages > 0) {
    paginationState.services.current = 1;
    renderServiceTable(servicesData);
    return;
  }

  if (servicesData.length === 0) {
    tbody.innerHTML = `<tr><td colspan="${colSpan}" class="empty-state">No service requests found</td></tr>`;
    renderServicePagination(0);
    return;
  }

  const startIdx = (currentPage - 1) * ITEMS_PER_PAGE;
  const endIdx = startIdx + ITEMS_PER_PAGE;
  const pageData = servicesData.slice(startIdx, endIdx);

  tbody.innerHTML = '';
  pageData.forEach(s => {
    const tr = document.createElement('tr');

    const tdRequestedBy = document.createElement('td');
    tdRequestedBy.textContent = getServiceRequesterName(s);
    tdRequestedBy.style.fontSize = '13px';
    tdRequestedBy.style.fontWeight = '500';

    const tdType = document.createElement('td');
    tdType.textContent = s.type || s.service_type || 'N/A';
    tdType.style.fontSize = '13px';
    tdType.style.textTransform = 'capitalize';

    const tdStatus = document.createElement('td');
    const statusBadge = document.createElement('span');
    statusBadge.className = `status-badge ${getStatusClass(s.status)}`;
    statusBadge.textContent = formatServiceStatus(s.status);
    tdStatus.appendChild(statusBadge);

    const tdDate = document.createElement('td');
    tdDate.textContent = formatDate(s.appointment_date || s.date);
    tdDate.style.fontSize = '13px';

    const tdCreated = document.createElement('td');
    tdCreated.textContent = formatSubmittedAt(s.created_at);
    tdCreated.className = 'submission-time-cell';

    const tdAge = createSubmissionAgeCell(s.created_at);

    const tdActions = document.createElement('td');
    const actionsDiv = document.createElement('div');
    actionsDiv.className = 'action-btns';

    const viewBtn = document.createElement('button');
    viewBtn.className = 'btn btn-sm btn-info btn-icon';
    viewBtn.title = 'View Details';
    viewBtn.innerHTML = '<i class="fa-solid fa-eye"></i>';
    viewBtn.addEventListener('click', () => openServiceDetailsModal(String(s.id)));

    const editBtn = document.createElement('button');
    editBtn.className = 'btn btn-sm btn-edit btn-icon';
    editBtn.title = 'Edit';
    editBtn.innerHTML = '<i class="fa-solid fa-pen-to-square"></i>';
    editBtn.addEventListener('click', () => openEditServiceModal(String(s.id)));

    actionsDiv.appendChild(viewBtn);
    actionsDiv.appendChild(editBtn);
    tdActions.appendChild(actionsDiv);

    tr.appendChild(tdRequestedBy);
    tr.appendChild(tdType);
    tr.appendChild(tdStatus);
    tr.appendChild(tdDate);
    tr.appendChild(tdCreated);
    tr.appendChild(tdAge);
    tr.appendChild(tdActions);

    // Add click handler to view details
    tr.style.cursor = 'pointer';
    tr.addEventListener('click', (e) => {
      if (!e.target.closest('.action-btns')) {
        openServiceDetailsModal(s.id);
      }
    });

    tbody.appendChild(tr);
  });

  renderServicePagination(totalItems);
}

function renderServicePagination(totalItems) {
  const paginationEl = document.getElementById('servicePagination');
  const showingEl = document.getElementById('serviceShowing');
  if (!paginationEl || !showingEl) return;

  const totalPages = Math.ceil(totalItems / ITEMS_PER_PAGE);
  const currentPage = paginationState.services.current;
  paginationState.services.total = totalPages;
  showingEl.textContent = `Showing ${Math.min(currentPage * ITEMS_PER_PAGE, totalItems)} of ${totalItems} entries`;

  if (totalPages <= 1) {
    paginationEl.innerHTML = '';
    return;
  }

  let html = `<button class="page-btn prev-btn" data-page="${currentPage - 1}" ${currentPage === 1 ? 'disabled' : ''}><i class="fa-solid fa-chevron-left"></i></button>`;

  const maxButtons = 5;
  let startPage = Math.max(1, currentPage - Math.floor(maxButtons / 2));
  let endPage = Math.min(totalPages, startPage + maxButtons - 1);
  if (endPage - startPage + 1 < maxButtons) {
    startPage = Math.max(1, endPage - maxButtons + 1);
  }

  if (startPage > 1) {
    html += `<button class="page-btn" data-page="1">1</button>`;
    if (startPage > 2) html += `<span class="page-ellipsis">...</span>`;
  }

  for (let i = startPage; i <= endPage; i++) {
    html += `<button class="page-btn ${i === currentPage ? 'active' : ''}" data-page="${i}">${i}</button>`;
  }

  if (endPage < totalPages) {
    if (endPage < totalPages - 1) html += `<span class="page-ellipsis">...</span>`;
    html += `<button class="page-btn" data-page="${totalPages}">${totalPages}</button>`;
  }

  html += `<button class="page-btn next-btn" data-page="${currentPage + 1}" ${currentPage === totalPages ? 'disabled' : ''}><i class="fa-solid fa-chevron-right"></i></button>`;
  paginationEl.innerHTML = html;

  paginationEl.querySelectorAll('.page-btn').forEach(btn => {
    btn.addEventListener('click', (e) => {
      e.preventDefault();
      const page = parseInt(btn.dataset.page);
      if (page >= 1 && page <= totalPages) {
        paginationState.services.current = page;
        filterService();
        window.scrollTo(0, 0);
      }
    });
  });
}

function populateServiceCategoryFilter() {
  const categoryFilter = document.getElementById('serviceCategoryFilter');
  if (!categoryFilter) return;

  const categories = [...new Set(allServices.map(s => s.type ? s.type.trim() : null).filter(Boolean))].sort();

  const currentValue = categoryFilter.value;
  categoryFilter.innerHTML = '<option value="">All Categories</option>';

  categories.forEach(cat => {
    const option = document.createElement('option');
    option.value = cat;
    option.textContent = cat;
    categoryFilter.appendChild(option);
  });

  categoryFilter.value = currentValue;
}

function openServiceModal() {
  document.getElementById('serviceModalTitle').textContent = 'Add Service Request';
  document.getElementById('serviceEditId').value = '';
  document.getElementById('serviceStatus').value = 'pending';
  document.getElementById('serviceReason').value = '';
  document.getElementById('serviceReturnTemplate').value = '';
  document.getElementById('serviceReturnFiles').value = '';
  document.getElementById('reasonFieldGroup').style.display = 'none';
  document.getElementById('serviceSaveBtn').innerHTML = '<i class="fa-solid fa-floppy-disk"></i> Save';
  document.getElementById('serviceModal').classList.add('active');
}

async function openEditServiceModal(id) {
  document.getElementById('serviceModalTitle').textContent = 'Update Service Request Status';
  document.getElementById('serviceEditId').value = id;
  document.getElementById('serviceReason').value = '';
  document.getElementById('serviceReturnTemplate').value = '';
  document.getElementById('serviceReturnFiles').value = '';
  document.getElementById('serviceSaveBtn').innerHTML = '<i class="fa-solid fa-floppy-disk"></i> Update Status';

  try {
    const record = allServices.find(s => s.id === id);

    if (record) {
      document.getElementById('serviceStatus').value = record.status || 'pending';
      if (record.status === 'rejected') {
        document.getElementById('serviceReason').value = record.rejection_reason || '';
      }
      toggleReasonField();
    } else {
      throw new Error('Record not found');
    }
  } catch (error) {
    console.error('Error loading service:', error);
    showToast('Failed to load service data', 'error');
    return;
  }

  document.getElementById('serviceModal').classList.add('active');
}

function closeServiceModal() {
  document.getElementById('serviceModal').classList.remove('active');
}

async function openServiceDetailsModal(id) {
  try {
    // Ensure ID is a string for consistent comparison
    const stringId = String(id).trim();

    // Load services if not already loaded (e.g., when called from dashboard)
    if (allServices.length === 0) {
      console.log('📂 Services not loaded, fetching...');
      await loadServicesData();
    }

    // Debug: Log the search
    console.log('🔍 Searching for service ID:', stringId);
    console.log('📊 Total services loaded:', allServices.length);
    console.log('🔎 Service IDs available:', allServices.map(s => String(s.id)));

    // Find with flexible ID matching
    let record = allServices.find(s => String(s.id) === stringId);

    if (!record) {
      console.warn('⚠️ Service not found with ID:', stringId);
      console.log('Available service objects:', allServices.slice(0, 3)); // Log first 3 for debugging

      showToast('Service not found. Please refresh and try again.', 'error');
      return;
    }

    console.log('✅ Service found:', record);

    document.getElementById('serviceDetailsId').value = stringId;
    document.getElementById('serviceDetailsTitle').textContent = `Service Request: ${record.name || 'Service'}`;

    const detailsContent = document.getElementById('serviceDetailsContent');
    detailsContent.innerHTML = '';

    let requestedByValue = '';
    if (record.user_id) {
      try {
        const { data: user } = await supabaseClient
          .from('users')
          .select('display_name')
          .eq('id', record.user_id)
          .single();
        if (user && user.display_name) {
          requestedByValue = user.display_name;
        }
      } catch (err) {
        console.log('Could not fetch user display name');
      }
    }

    const fields = buildServiceDetailsFields(record, requestedByValue);

    fields.forEach(field => {
      const fieldDiv = document.createElement('div');
      if (field.fullWidth) {
        fieldDiv.style.gridColumn = '1 / -1';
      }

      const label = document.createElement('label');
      label.className = 'service-detail-label';
      label.textContent = field.label;

      const value = document.createElement('p');
      value.className = 'service-detail-value';
      value.textContent = field.value;
      if (field.submittedAt && parseSubmissionTime(field.submittedAt)) {
        value.dataset.submittedAt = parseSubmissionTime(field.submittedAt).toISOString();
      }

      fieldDiv.appendChild(label);
      fieldDiv.appendChild(value);
      detailsContent.appendChild(fieldDiv);
    });

    const relationship = String(record.relationship_to_owner || '').trim().toLowerCase();
    const needsAuthorization = relationship && relationship !== 'self';
    for (const [key, title] of [['authorization_letter_path', 'Authorization Letter'], ['owner_valid_id_path', 'Certificate Owner Valid ID']]) {
      const serviceType = String(record.table_name || record.type || record.service_name || '').toLowerCase();
      if (key === 'owner_valid_id_path' && !serviceType.includes('birth') && !record[key]) continue;
      if (!record[key] && !needsAuthorization) continue;
      const section = document.createElement('div');
      const label = document.createElement('strong');
      label.textContent = title;
      section.appendChild(label);
      if (!record[key]) {
        const message = document.createElement('p');
        message.textContent = 'Not uploaded';
        section.appendChild(message);
        detailsContent.appendChild(section);
        continue;
      }
      let data, error;
      try {
        ({ data, error } = await supabaseClient.storage.from('birth-certificate-documents').createSignedUrl(record[key], 300));
      } catch (failure) { error = failure; }
      if (error || !data?.signedUrl) {
        const message = document.createElement('p');
        message.textContent = 'Unable to load document. Please reopen this request or check your service access.';
        section.appendChild(message);
      } else {
        const link = document.createElement('button');
        link.type = 'button';
        link.className = 'service-document-preview';
        link.setAttribute('aria-label', `View ${title}`);
        link.setAttribute('aria-haspopup', 'dialog');
        link.addEventListener('click', () => openImageLightbox(data.signedUrl, title));
        link.title = `View ${title}`;
        const preview = document.createElement('img');
        preview.src = data.signedUrl;
        preview.alt = title;
        preview.style.cssText = 'display:block;max-width:100%;height:160px;object-fit:contain;margin:10px 0;border-radius:8px';
        preview.addEventListener('error', () => preview.remove());
        link.appendChild(preview);
        section.appendChild(link);
      }
      detailsContent.appendChild(section);
    }

    if (record.status === 'rejected' && Array.isArray(record.return_files) && record.return_files.length) {
      const section = document.createElement('div');
      section.style.gridColumn = '1 / -1';
      const heading = document.createElement('strong');
      heading.textContent = 'Return attachments';
      section.appendChild(heading);
      appendReturnFileLinks(section, record.return_files);
      detailsContent.appendChild(section);
    }

    document.getElementById('serviceDetailsModal').classList.add('active');
  } catch (error) {
    console.error('Error loading service details:', error);
    showToast('Failed to load service details', 'error');
  }
}

function buildServiceDetailsFields(record, profileName = '') {
  const type = String(record.table_name || record.type || record.service_name || record.name || '').toLowerCase();
  const fields = [];
  const add = (label, value) => {
    if (value != null && String(value).trim() && !/^(n\/?a|null|undefined)$/i.test(String(value).trim())) {
      fields.push({ label, value: String(value).trim() });
    }
  };
  const date = value => value ? formatDate(value) : '';
  add('Status', formatServiceStatus(record.status, 'Pending'));
  add('Requested By', getServiceRequesterName(record, profileName));
  if (type.includes('marriage')) {
    add('Husband', record.husband_name);
    add('Wife', record.wife_name);
    add('Date of Marriage', date(record.marriage_date));
    add('Place of Marriage', record.place_of_marriage);
  } else if (type.includes('death_certificate')) {
    add('Deceased Person', record.deceased_full_name);
    add('Date of Death', date(record.date_of_death));
    add('Place of Death', record.place_of_death);
  } else if (type.includes('facility')) {
    add('Facility', record.facility_name);
    add('Event Date', date(record.event_date));
    add('Time', [record.start_time, record.end_time].filter(Boolean).join(' to '));
    add('Participants', record.expected_participants);
  } else {
    add(type.includes('birth') ? 'Certificate Owner' : 'Name on Request', record.full_name);
    if (type.includes('birth')) {
      add('Birthday', date(record.date_of_birth));
      add('Place of Birth', record.place_of_birth);
      add('Mother’s Full Name', record.mother_full_name);
      add('Father’s Full Name', record.father_full_name);
    }
  }
  const relationship = String(record.relationship_to_owner || '').trim();
  if (relationship) {
    const relationshipLabel = type.includes('death_certificate') ? 'Relationship to Deceased'
      : type.includes('marriage') ? 'Relationship to Either Spouse'
      : type.includes('facility') ? 'Requesting for'
      : 'Relationship to Certificate Owner';
    add(relationshipLabel, relationship);
  }
  add('Purpose', record.purpose);
  if (record.appointment_date || record.appointment_time) {
    add('Appointment', [date(record.appointment_date), record.appointment_time].filter(Boolean).join(' at '));
  }
  add('Phone', record.contact_number || record.phone);
  add('Email', record.email);
  add('Submitted', formatSubmittedAt(record.created_at));
  add('Notes', record.notes || (record.description !== record.purpose ? record.description : ''));
  add('Additional Information', record.additional_information);
  if (record.status === 'rejected') {
    add('Reason for Return', record.rejection_reason || record.remarks);
  } else if (record.status === 'completed') {
    add('Approval Notes', record.approval_reason || record.remarks);
  } else if (record.remarks && record.remarks !== record.notes) {
    add('Admin Remarks', record.remarks);
  }
  return fields;
}

function getServiceRequesterName(record, profileName = '') {
  const type = String(record.table_name || record.type || record.service_name || record.name || '').toLowerCase();
  // Certificate full_name can be the owner, but Death and facility forms collect the requester explicitly.
  const explicitRequester = type.includes('death_certificate') ? record.requestor_full_name
    : type.includes('facility') ? record.full_name : null;
  const candidates = [explicitRequester, record.display_name, profileName, record.requested_by,
    record.requester, record.applicant_name, record.customer_name,
    record.client_name, record.submitted_by, record.first_name,
    ...(type.includes('cenomar') || type.includes('cenodeath') ? [record.full_name] : [])];
  return candidates.find(value => typeof value === 'string' &&
    value.trim() && !/^(n\/?a|null|undefined)$/i.test(value.trim()))?.trim() || 'N/A';
}

function closeServiceDetailsModal() {
  document.getElementById('serviceDetailsModal').classList.remove('active');
}

function openServiceDetailsEditModal() {
  const id = document.getElementById('serviceDetailsId').value;
  closeServiceDetailsModal();
  openEditServiceModal(id);
}

async function saveService() {
  const editId = document.getElementById('serviceEditId').value;
  const status = document.getElementById('serviceStatus').value;
  const reason = document.getElementById('serviceReason').value.trim();
  const returnFiles = document.getElementById('serviceReturnFiles').files;
  const reasonFieldGroup = document.getElementById('reasonFieldGroup');

  // Check if reason is required but empty
  if (reasonFieldGroup.style.display !== 'none' && !reason) {
    showToast('Please provide a reason for this status change', 'error');
    return;
  }
  if (status === 'rejected') {
    try {
      validateReturnFiles(returnFiles);
    } catch (error) {
      showToast(error.message, 'error');
      return;
    }
  }

  // If editing, only allow status update
  if (editId) {
    const saveBtn = document.getElementById('serviceSaveBtn');
    saveBtn.innerHTML = '<span class="loading-spinner"></span> Updating...';
    saveBtn.disabled = true;

    try {
      if (!supabaseClient) {
        showToast('Database connection unavailable', 'error');
        saveBtn.innerHTML = '<i class="fa-solid fa-floppy-disk"></i> Update Status';
        saveBtn.disabled = false;
        return;
      }

      // Find the original table for this record
      const originalRecord = allServices.find(s => s.id === editId);
      if (!originalRecord || !originalRecord.table_name) {
        showToast('Could not find service record', 'error');
        saveBtn.innerHTML = '<i class="fa-solid fa-floppy-disk"></i> Update Status';
        saveBtn.disabled = false;
        return;
      }

      const updatePayload = { status };
      if (status === 'rejected') {
        if (!('return_files' in originalRecord) && returnFiles.length) {
          throw new Error('Return attachments are not available yet. Run supabase/add_return_files.sql first.');
        }
        if ('return_files' in originalRecord) {
          updatePayload.return_files = returnFiles.length
            ? [...(Array.isArray(originalRecord.return_files) ? originalRecord.return_files : []), ...await uploadReturnFiles('service', editId, returnFiles)]
            : (originalRecord.return_files || null);
        }
      } else if ('return_files' in originalRecord) {
        updatePayload.return_files = null;
      }

      // Add reason to notes/remarks based on status
      if (reason) {
        if (status === 'rejected') {
          updatePayload.rejection_reason = reason;
          updatePayload.remarks = `Returned: ${reason}`;
        } else if (status === 'completed') {
          updatePayload.approval_reason = reason;
          updatePayload.remarks = `Approved: ${reason}`;
        } else {
          updatePayload.notes = reason;
          updatePayload.remarks = reason;
        }
      }

      const { data: savedRecord, error } = await supabaseClient
        .from(originalRecord.table_name)
        .update(updatePayload)
        .eq('id', editId)
        .select('id, status')
        .single();

      if (error) throw error;
      if (!savedRecord || savedRecord.status !== status) {
        throw new Error('The service status change was not saved.');
      }
      const statusChanged = originalRecord.status !== status;
      const pushSent = statusChanged
        ? await sendOnlineServiceStatusPushNotification(originalRecord, status, reason)
        : true;
      showToast(pushSent
        ? 'Service status updated successfully!'
        : 'Service status saved, but the user push notification could not be sent.',
        pushSent ? 'success' : 'error');
      addNotification('Service Updated', `Service request status has been updated to ${formatServiceStatus(status)}`, 'success');
      closeServiceModal();
      loadServices();
    } catch (error) {
      console.error('Error updating service:', error);
      showToast('Error updating service status: ' + error.message, 'error');
      const saveBtn = document.getElementById('serviceSaveBtn');
      saveBtn.innerHTML = '<i class="fa-solid fa-floppy-disk"></i> Update Status';
      saveBtn.disabled = false;
    }
    return;
  }

  // If creating new service (this should not be used since "Add Service" button was removed)
  showToast('Service requests can only be created by app users', 'info');
}

function toggleReasonField() {
  const status = document.getElementById('serviceStatus').value;
  const reasonFieldGroup = document.getElementById('reasonFieldGroup');
  const reasonLabel = document.getElementById('reasonLabel');
  document.getElementById('serviceReturnTemplate').style.display = status === 'rejected' ? 'block' : 'none';
  document.getElementById('serviceReturnFilesGroup').style.display = status === 'rejected' ? 'block' : 'none';

  if (status === 'rejected') {
    reasonFieldGroup.style.display = 'block';
    reasonLabel.textContent = 'Return Reason *';
  } else if (status === 'completed') {
    reasonFieldGroup.style.display = 'block';
    reasonLabel.textContent = 'Approval Notes *';
  } else {
    reasonFieldGroup.style.display = 'none';
  }

  // Clear reason when hiding
  if (reasonFieldGroup.style.display === 'none') {
    document.getElementById('serviceReason').value = '';
    document.getElementById('serviceReturnTemplate').value = '';
    document.getElementById('serviceReturnFiles').value = '';
  }
}

function getStatusClass(status) {
  const s = (status || '').toLowerCase();
  if (s === 'resolved' || s === 'done' || s === 'completed' || s === 'approved') return 'status-approved';
  if (s === 'processing') return 'status-processing';
  if (s === 'reviewing' || s === 'under review' || s === 'in progress') return 'status-reviewing';
  if (s === 'rejected') return 'status-rejected';
  return 'status-pending';
}

// ============================================================
// HOTLINE MANAGEMENT
// ============================================================
let allHotlines = [];

async function loadHotline() {
  const tbody = document.getElementById('hotlineTableBody');
  if (!tbody) return;

  if (!supabaseClient) {
    const colSpan = tbody.closest('table').querySelectorAll('th').length;
    tbody.innerHTML = `<tr><td colspan="${colSpan}" class="empty-state">Database connection unavailable</td></tr>`;
    return;
  }

  try {
    const { data, error } = await supabaseClient
      .from('hotlines')
      .select('*')
      .order('created_at', { ascending: false });

    if (error) throw error;
    allHotlines = data || [];
    populateHotlineCategoryFilter();
    renderHotlineTable(allHotlines);
  } catch (error) {
    console.error('Error loading hotlines:', error);
    showToast('Failed to load hotlines from database: ' + error.message, 'error');
  }
}

function renderHotlineTable(hotlineData) {
  const tbody = document.getElementById('hotlineTableBody');
  tableExportRows.hotlineTableBody = hotlineData;
  const colSpan = tbody.closest('table').querySelectorAll('th').length;

  const totalItems = hotlineData.length;
  const totalPages = Math.ceil(totalItems / ITEMS_PER_PAGE);
  const currentPage = paginationState.hotline.current;

  if (currentPage > totalPages && totalPages > 0) {
    paginationState.hotline.current = 1;
    renderHotlineTable(hotlineData);
    return;
  }

  if (hotlineData.length === 0) {
    tbody.innerHTML = `<tr><td colspan="${colSpan}" class="empty-state">No hotline records found</td></tr>`;
    renderHotlinePagination(0);
    return;
  }

  const startIdx = (currentPage - 1) * ITEMS_PER_PAGE;
  const endIdx = startIdx + ITEMS_PER_PAGE;
  const pageData = hotlineData.slice(startIdx, endIdx);

  tbody.innerHTML = '';
  pageData.forEach(h => {
    const tr = document.createElement('tr');

    const tdLogo = document.createElement('td');
    if (h.logo_url) {
      const img = document.createElement('img');
      img.src = h.logo_url;
      img.style.maxWidth = '40px';
      img.style.maxHeight = '40px';
      img.style.borderRadius = '4px';
      tdLogo.appendChild(img);
    } else {
      tdLogo.innerHTML = '<i class="fa-solid fa-image" style="color: #d1d5db;"></i>';
    }

    const tdName = document.createElement('td');
    const displayName = h.name || h.department || 'N/A';
    tdName.textContent = displayName;
    tdName.style.fontWeight = '600';

    const tdCategory = document.createElement('td');
    const displayCategory = h.category || 'General';
    const categoryBadge = document.createElement('span');
    categoryBadge.className = 'badge';
    categoryBadge.style.backgroundColor = getCategoryColor(displayCategory);
    categoryBadge.style.color = 'white';
    categoryBadge.style.padding = '4px 8px';
    categoryBadge.style.borderRadius = '4px';
    categoryBadge.style.fontSize = '12px';
    categoryBadge.textContent = displayCategory;
    tdCategory.textContent = '';
    tdCategory.appendChild(categoryBadge);

    const tdNumber = document.createElement('td');
    let numberDisplay = 'N/A';
    if (h.phone_numbers) {
      if (Array.isArray(h.phone_numbers)) {
        numberDisplay = h.phone_numbers.join(', ');
      } else {
        numberDisplay = h.phone_numbers;
      }
    } else if (h.hotline_number) {
      numberDisplay = h.hotline_number;
    }
    tdNumber.textContent = numberDisplay;
    tdNumber.style.fontSize = '13px';

    const tdActions = document.createElement('td');
    const actionsDiv = document.createElement('div');
    actionsDiv.className = 'action-btns';

    const editBtn = document.createElement('button');
    editBtn.className = 'btn btn-sm btn-edit btn-icon';
    editBtn.title = 'Edit';
    editBtn.innerHTML = '<i class="fa-solid fa-pen-to-square"></i>';
    editBtn.addEventListener('click', () => openEditHotlineModal(h.id));

    const deleteBtn = document.createElement('button');
    deleteBtn.className = 'btn btn-sm btn-delete btn-icon';
    deleteBtn.title = 'Delete';
    deleteBtn.innerHTML = '<i class="fa-solid fa-trash"></i>';
    deleteBtn.addEventListener('click', () => openDeleteHotline(h.id, displayName));

    actionsDiv.appendChild(editBtn);
    actionsDiv.appendChild(deleteBtn);
    tdActions.appendChild(actionsDiv);

    tr.appendChild(tdLogo);
    tr.appendChild(tdName);
    tr.appendChild(tdCategory);
    tr.appendChild(tdNumber);
    tr.appendChild(tdActions);

    tbody.appendChild(tr);
  });

  renderHotlinePagination(totalItems);
}

function renderHotlinePagination(totalItems) {
  const paginationEl = document.getElementById('hotlinePagination');
  const showingEl = document.getElementById('hotlineShowing');
  if (!paginationEl || !showingEl) return;

  const totalPages = Math.ceil(totalItems / ITEMS_PER_PAGE);
  const currentPage = paginationState.hotline.current;
  paginationState.hotline.total = totalPages;
  showingEl.textContent = `Showing ${Math.min(currentPage * ITEMS_PER_PAGE, totalItems)} of ${totalItems} entries`;

  if (totalPages <= 1) {
    paginationEl.innerHTML = '';
    return;
  }

  let html = `<button class="page-btn prev-btn" data-page="${currentPage - 1}" ${currentPage === 1 ? 'disabled' : ''}><i class="fa-solid fa-chevron-left"></i></button>`;

  const maxButtons = 5;
  let startPage = Math.max(1, currentPage - Math.floor(maxButtons / 2));
  let endPage = Math.min(totalPages, startPage + maxButtons - 1);
  if (endPage - startPage + 1 < maxButtons) {
    startPage = Math.max(1, endPage - maxButtons + 1);
  }

  if (startPage > 1) {
    html += `<button class="page-btn" data-page="1">1</button>`;
    if (startPage > 2) html += `<span class="page-ellipsis">...</span>`;
  }

  for (let i = startPage; i <= endPage; i++) {
    html += `<button class="page-btn ${i === currentPage ? 'active' : ''}" data-page="${i}">${i}</button>`;
  }

  if (endPage < totalPages) {
    if (endPage < totalPages - 1) html += `<span class="page-ellipsis">...</span>`;
    html += `<button class="page-btn" data-page="${totalPages}">${totalPages}</button>`;
  }

  html += `<button class="page-btn next-btn" data-page="${currentPage + 1}" ${currentPage === totalPages ? 'disabled' : ''}><i class="fa-solid fa-chevron-right"></i></button>`;
  paginationEl.innerHTML = html;

  paginationEl.querySelectorAll('.page-btn').forEach(btn => {
    btn.addEventListener('click', (e) => {
      e.preventDefault();
      const page = parseInt(btn.dataset.page);
      if (page >= 1 && page <= totalPages) {
        paginationState.hotline.current = page;
        filterHotline();
        window.scrollTo(0, 0);
      }
    });
  });
}

function populateHotlineCategoryFilter() {
  const categoryFilter = document.getElementById('hotlineCategoryFilter');
  if (!categoryFilter) return;

  const categories = [...new Set(allHotlines.map(h => h.category ? h.category.trim() : null).filter(Boolean))].sort();

  const currentValue = categoryFilter.value;
  categoryFilter.innerHTML = '<option value="">All Categories</option>';

  categories.forEach(cat => {
    const option = document.createElement('option');
    option.value = cat;
    option.textContent = cat;
    categoryFilter.appendChild(option);
  });

  categoryFilter.value = currentValue;
}

function openHotlineModal() {
  document.getElementById('hotlineModalTitle').textContent = 'Add Hotline';
  document.getElementById('hotlineEditId').value = '';
  document.getElementById('hotlineName').value = '';
  document.getElementById('hotlineCategory').value = '';
  document.getElementById('hotlineNumber').value = '';
  document.getElementById('hotlineDescription').value = '';
  document.getElementById('hotlineLogoBase64').value = '';
  document.getElementById('hotlineLogoPreview').innerHTML = '<i class="fa-solid fa-image"></i><span>No image selected</span>';
  document.getElementById('hotlineSaveBtn').innerHTML = '<i class="fa-solid fa-floppy-disk"></i> Save';
  document.getElementById('hotlineModal').classList.add('active');
  setupHotlineLogoUpload();
}

async function openEditHotlineModal(id) {
  document.getElementById('hotlineModalTitle').textContent = 'Edit Hotline';
  document.getElementById('hotlineEditId').value = id;
  document.getElementById('hotlineSaveBtn').innerHTML = '<i class="fa-solid fa-floppy-disk"></i> Update';

  try {
    const record = allHotlines.find(h => h.id === id);

    if (record) {
      document.getElementById('hotlineName').value = record.name || '';
      document.getElementById('hotlineCategory').value = record.category || '';

      let numberValue = '';
      if (record.phone_numbers) {
        if (Array.isArray(record.phone_numbers)) {
          numberValue = record.phone_numbers.join(', ');
        } else {
          numberValue = record.phone_numbers;
        }
      } else if (record.hotline_number) {
        numberValue = record.hotline_number;
      }
      document.getElementById('hotlineNumber').value = numberValue;

      document.getElementById('hotlineDescription').value = record.description || '';
      document.getElementById('hotlineLogoBase64').value = '';

      const logoPreview = document.getElementById('hotlineLogoPreview');
      if (record.logo_url) {
        logoPreview.innerHTML = `<img src="${record.logo_url}" alt="logo preview" style="max-width: 100%; max-height: 100%; border-radius: 8px;">`;
      } else {
        logoPreview.innerHTML = '<i class="fa-solid fa-image"></i><span>No image selected</span>';
      }
    } else {
      throw new Error('Record not found');
    }
  } catch (error) {
    console.error('Error loading hotline:', error);
    showToast('Failed to load hotline data', 'error');
    return;
  }

  document.getElementById('hotlineModal').classList.add('active');
  setupHotlineLogoUpload();
}

function closeHotlineModal() {
  document.getElementById('hotlineModal').classList.remove('active');
}

async function saveHotline() {
  if (document.getElementById('hotlineSaveBtn').disabled) return;
  const editId = document.getElementById('hotlineEditId').value;
  const name = document.getElementById('hotlineName').value.trim();
  const category = document.getElementById('hotlineCategory').value.trim();
  const hotlineNumberInput = document.getElementById('hotlineNumber').value.trim();
  const description = document.getElementById('hotlineDescription').value.trim();
  const logoBase64 = document.getElementById('hotlineLogoBase64').value;

  if (!name || !category || !hotlineNumberInput) {
    showToast('Please fill all required fields', 'error');
    return;
  }

  const saveBtn = document.getElementById('hotlineSaveBtn');
  saveBtn.innerHTML = '<span class="loading-spinner"></span> Saving...';
  saveBtn.disabled = true;

  try {
    if (!supabaseClient) {
      showToast('Database connection unavailable', 'error');
      saveBtn.innerHTML = '<i class="fa-solid fa-floppy-disk"></i> Save';
      saveBtn.disabled = false;
      return;
    }

    await ensureUniqueRecordName('hotlines', 'name', name, editId, 'A hotline with this name');

    const phoneNumbers = hotlineNumberInput
      .split(',')
      .map(num => num.trim())
      .filter(num => num.length > 0);

    const payload = {
      name,
      category,
      phone_numbers: phoneNumbers,
      description
    };

    if (logoBase64 || document.getElementById('hotlineLogo').files[0]) {
      payload.logo_url = await compressedImageDataUrl(document.getElementById('hotlineLogo').files[0], logoBase64);
    }

    if (editId) {
      const { error } = await supabaseClient
        .from('hotlines')
        .update(payload)
        .eq('id', editId);
      if (error) throw error;
      showToast('Hotline updated successfully!', 'success');
      addNotification('Hotline Updated', `${name} hotline has been updated`, 'success');
    } else {
      const { error } = await supabaseClient
        .from('hotlines')
        .insert([{
          ...payload,
          created_at: new Date().toISOString()
        }]);
      if (error) throw error;
      showToast('Hotline added successfully!', 'success');
      addNotification('Hotline Added', `${name} hotline has been created`, 'success');
    }

    closeHotlineModal();
    loadHotline();
  } catch (error) {
    console.error('Error saving hotline:', error);
    showToast('Failed to save hotline: ' + recordSaveError(error, 'A hotline with this name'), 'error');
  } finally {
    saveBtn.innerHTML = '<i class="fa-solid fa-floppy-disk"></i> Save';
    saveBtn.disabled = false;
  }
}

function openDeleteHotline(id, name) {
  deleteTarget = id;
  deleteType = 'hotline';
  document.getElementById('deleteMessage').textContent = `Are you sure you want to delete "${name}"? This action cannot be undone.`;
  document.getElementById('deleteModal').classList.add('active');
}

// ============================================================
// SEARCH LISTENERS
// ============================================================
function setupSearchListeners() {
  const barangaySearch = document.getElementById('barangaySearch');
  if (barangaySearch) {
    barangaySearch.addEventListener('input', debounce(async () => {
      const searchTerm = barangaySearch.value.toLowerCase();
      if (!supabaseClient) return;

      try {
        const { data, error } = await supabaseClient
          .from('barangays')
          .select('*')
          .order('id', { ascending: true });

        if (error) throw error;

        const filtered = data.filter(b =>
          (b.name && b.name.toLowerCase().includes(searchTerm)) ||
          (b.description && b.description.toLowerCase().includes(searchTerm)) ||
          (b.geographic_data && b.geographic_data.toLowerCase().includes(searchTerm))
        );

        const tbody = document.getElementById('barangayTableBody');
        if (tbody) {
          paginationState.barangay.current = 1;
          await renderBarangayTable(tbody, null, true, filtered);
        }
      } catch (error) {
        console.error('Error searching barangays:', error);
      }
    }, 300));
  }

  const newsSearch = document.getElementById('newsSearch');
  if (newsSearch) {
    newsSearch.addEventListener('input', debounce(async () => {
      const searchTerm = newsSearch.value.toLowerCase();
      if (!supabaseClient) return;

      try {
        const { data, error } = await supabaseClient
          .from('news')
          .select('*')
          .order('created_at', { ascending: false });

        if (error) throw error;

        const filtered = data.filter(n =>
          (n.title && n.title.toLowerCase().includes(searchTerm)) ||
          (n.description && n.description.toLowerCase().includes(searchTerm)) ||
          (n.category && n.category.toLowerCase().includes(searchTerm))
        );

        renderNewsTable(filtered);
      } catch (error) {
        console.error('Error searching news:', error);
      }
    }, 300));
  }

  const reportsSearch = document.getElementById('reportsSearch');
  if (reportsSearch) {
    reportsSearch.addEventListener('input', debounce(() => {
      filterReports();
    }, 300));
  }

  const statusFilter = document.getElementById('reportStatusFilter');
  if (statusFilter) {
    statusFilter.addEventListener('change', () => {
      filterReports();
    });
  }

  const reportCategoryFilter = document.getElementById('reportCategoryFilter');
  if (reportCategoryFilter) {
    reportCategoryFilter.addEventListener('change', () => {
      paginationState.reports.current = 1;
      filterReports();
    });
  }

  const reportDateFrom = document.getElementById('reportDateFrom');
  if (reportDateFrom) {
    reportDateFrom.addEventListener('change', () => {
      filterReports();
    });
  }

  const reportDateTo = document.getElementById('reportDateTo');
  if (reportDateTo) {
    reportDateTo.addEventListener('change', () => {
      filterReports();
    });
  }

  const transparencyTypeFilter = document.getElementById('transparencyTypeFilter');
  if (transparencyTypeFilter) {
    transparencyTypeFilter.addEventListener('change', () => {
      filterTransparency();
      updateTransparencyTable();
    });
  }

  const transparencySearch = document.getElementById('transparencySearch');
  if (transparencySearch) {
    transparencySearch.addEventListener('input', debounce(() => {
      filterTransparency();
    }, 300));
  }

  const transparencyDateFrom = document.getElementById('transparencyDateFrom');
  if (transparencyDateFrom) {
    transparencyDateFrom.addEventListener('change', () => {
      filterTransparency();
    });
  }

  const transparencyDateTo = document.getElementById('transparencyDateTo');
  if (transparencyDateTo) {
    transparencyDateTo.addEventListener('change', () => {
      filterTransparency();
    });
  }

  const touristSearch = document.getElementById('touristSearch');
  if (touristSearch) {
    touristSearch.addEventListener('input', debounce(() => {
      filterTourist();
    }, 300));
  }

  const touristCategoryFilter = document.getElementById('touristCategoryFilter');
  if (touristCategoryFilter) {
    touristCategoryFilter.addEventListener('change', () => {
      paginationState.tourist.current = 1;
      filterTourist();
    });
  }

  const serviceSearch = document.getElementById('serviceSearch');
  if (serviceSearch) {
    serviceSearch.addEventListener('input', debounce(() => {
      filterService();
    }, 300));
  }

  const serviceStatusFilter = document.getElementById('serviceStatusFilter');
  if (serviceStatusFilter) {
    serviceStatusFilter.addEventListener('change', () => {
      filterService();
    });
  }

  const serviceCategoryFilter = document.getElementById('serviceCategoryFilter');
  if (serviceCategoryFilter) {
    serviceCategoryFilter.addEventListener('change', () => {
      filterService();
    });
  }

  const serviceDateFrom = document.getElementById('serviceDateFrom');
  if (serviceDateFrom) {
    serviceDateFrom.addEventListener('change', () => {
      filterService();
    });
  }

  const serviceDateTo = document.getElementById('serviceDateTo');
  if (serviceDateTo) {
    serviceDateTo.addEventListener('change', () => {
      filterService();
    });
  }

  const hotlineSearch = document.getElementById('hotlineSearch');
  if (hotlineSearch) {
    hotlineSearch.addEventListener('input', debounce(() => {
      filterHotline();
    }, 300));
  }

  const hotlineCategoryFilter = document.getElementById('hotlineCategoryFilter');
  if (hotlineCategoryFilter) {
    hotlineCategoryFilter.addEventListener('change', () => {
      paginationState.hotline.current = 1;
      filterHotline();
    });
  }

  const usersSearch = document.getElementById('usersSearch');
  if (usersSearch) {
    usersSearch.addEventListener('input', debounce(() => {
      paginationState.users.current = 1;
      filterUsers();
    }, 300));
  }

  const usersVerificationFilter = document.getElementById('usersVerificationFilter');
  if (usersVerificationFilter) {
    usersVerificationFilter.addEventListener('change', () => {
      paginationState.users.current = 1;
      filterUsers();
    });
  }
}

function filterTransparency() {
  const searchTerm = (document.getElementById('transparencySearch').value || '').toLowerCase();
  const typeFilter = document.getElementById('transparencyTypeFilter').value || '';
  const dateFrom = document.getElementById('transparencyDateFrom').value;
  const dateTo = document.getElementById('transparencyDateTo').value;

  const filtered = allTransparency.filter(t => {
    const matchSearch = !searchTerm ||
      (t.title && t.title.toLowerCase().includes(searchTerm)) ||
      (t.description && t.description.toLowerCase().includes(searchTerm));

    const matchType = !typeFilter || t.type === typeFilter;

    let matchDate = true;
    if (dateFrom || dateTo) {
      const createdDate = new Date(t.created_at).toISOString().split('T')[0];
      if (dateFrom && createdDate < dateFrom) matchDate = false;
      if (dateTo && createdDate > dateTo) matchDate = false;
    }

    return matchSearch && matchType && matchDate;
  });

  renderTransparencyTable(filtered);
}

function updateTransparencyTable() {
  const typeFilter = document.getElementById('transparencyTypeFilter').value || '';
  filterTransparency();
}

function filterTourist() {
  const searchTerm = (document.getElementById('touristSearch').value || '').toLowerCase();
  const categoryFilter = (document.getElementById('touristCategoryFilter').value || '').toLowerCase().trim();

  const filtered = allTourist.filter(t => {
    const matchSearch = !searchTerm ||
      (t.name && t.name.toLowerCase().includes(searchTerm)) ||
      (t.location && t.location.toLowerCase().includes(searchTerm)) ||
      (t.category && t.category.toLowerCase().includes(searchTerm)) ||
      (t.description && t.description.toLowerCase().includes(searchTerm));

    const matchCategory = !categoryFilter || (t.category || '').toLowerCase().trim() === categoryFilter;

    return matchSearch && matchCategory;
  });

  renderTouristTable(filtered);
}

function filterService() {
  const searchTerm = (document.getElementById('serviceSearch').value || '').toLowerCase();
  const statusFilter = document.getElementById('serviceStatusFilter').value || '';
  const categoryFilter = document.getElementById('serviceCategoryFilter').value || '';
  const dateFrom = document.getElementById('serviceDateFrom').value;
  const dateTo = document.getElementById('serviceDateTo').value;

  const filtered = allServices.filter(s => {
    const matchSearch = !searchTerm ||
      (s.name && s.name.toLowerCase().includes(searchTerm)) ||
      (s.requested_by && s.requested_by.toLowerCase().includes(searchTerm)) ||
      ((s.type || s.service_type) && (s.type || s.service_type).toLowerCase().includes(searchTerm));

    const matchStatus = !statusFilter || s.status === statusFilter;
    const matchCategory = !categoryFilter || s.type === categoryFilter;

    let matchDate = true;
    if (dateFrom || dateTo) {
      const createdDate = new Date(s.created_at).toISOString().split('T')[0];
      if (dateFrom && createdDate < dateFrom) matchDate = false;
      if (dateTo && createdDate > dateTo) matchDate = false;
    }

    return matchSearch && matchStatus && matchCategory && matchDate;
  });

  renderServiceTable(filtered);
}

function filterHotline() {
  const searchTerm = (document.getElementById('hotlineSearch').value || '').toLowerCase();
  const categoryFilter = (document.getElementById('hotlineCategoryFilter').value || '').toLowerCase().trim();

  const filtered = allHotlines.filter(h => {
    const name = (h.name || h.department || '').toLowerCase();
    const category = (h.category || '').toLowerCase();
    const number = String(h.phone_numbers || h.hotline_number || '').toLowerCase();
    const desc = (h.description || '').toLowerCase();

    const matchSearch = name.includes(searchTerm) ||
           category.includes(searchTerm) ||
           number.includes(searchTerm) ||
           desc.includes(searchTerm);

    const matchCategory = !categoryFilter || category === categoryFilter;

    return matchSearch && matchCategory;
  });

  renderHotlineTable(filtered);
}

function filterReports() {
  const searchTerm = (document.getElementById('reportsSearch').value || '').toLowerCase();
  const statusFilter = document.getElementById('reportStatusFilter').value || '';
  const categoryFilter = document.getElementById('reportCategoryFilter')?.value || '';
  const dateFrom = document.getElementById('reportDateFrom').value;
  const dateTo = document.getElementById('reportDateTo').value;

  const filtered = allReports.filter(r => {
    const matchSearch = !searchTerm ||
      (r.reporter_name && r.reporter_name.toLowerCase().includes(searchTerm)) ||
      (r.message && r.message.toLowerCase().includes(searchTerm));

    const matchStatus = !statusFilter || r.status === statusFilter;
    const matchCategory = !categoryFilter || (r.category || 'Other') === categoryFilter;

    let matchDate = true;
    if (dateFrom || dateTo) {
      const createdDate = new Date(r.created_at).toISOString().split('T')[0];
      if (dateFrom && createdDate < dateFrom) matchDate = false;
      if (dateTo && createdDate > dateTo) matchDate = false;
    }

    return matchSearch && matchStatus && matchCategory && matchDate;
  });

  renderReportsTable(filtered);
}

// ============================================================
// LOGO UPLOAD HANDLER
// ============================================================
function setupLogoUpload() {
  const logoInput = document.getElementById('barangayLogo');
  const logoPreview = document.getElementById('logoPreview');

  logoInput.addEventListener('change', (e) => {
    const file = e.target.files[0];
    if (!file) return;

    const reader = new FileReader();
    reader.onload = (event) => {
      const base64 = event.target.result;
      document.getElementById('barangayLogoBase64').value = base64;
      logoPreview.innerHTML = `
        <div class="preview-image-wrapper">
          <img src="${base64}" alt="logo preview" style="max-width: 100%; max-height: 100%; border-radius: 8px;">
          <button type="button" class="remove-image-btn" title="Remove image">
            <i class="fa-solid fa-xmark"></i>
          </button>
        </div>
      `;
      logoPreview.querySelector('.remove-image-btn').addEventListener('click', (e) => {
        e.preventDefault();
        logoInput.value = '';
        document.getElementById('barangayLogoBase64').value = '';
        logoPreview.innerHTML = '<i class="fa-solid fa-image"></i><span>No image selected</span>';
      });
    };
    reader.readAsDataURL(file);
  });
}

function setupCoverImageUpload() {
  const coverInput = document.getElementById('barangayCoverImage');
  const coverPreview = document.getElementById('coverImagePreview');

  coverInput.addEventListener('change', (e) => {
    const file = e.target.files[0];
    if (!file) return;

    const reader = new FileReader();
    reader.onload = (event) => {
      const base64 = event.target.result;
      document.getElementById('barangayCoverImageBase64').value = base64;
      coverPreview.innerHTML = `
        <div class="preview-image-wrapper">
          <img src="${base64}" alt="cover preview" style="max-width: 100%; max-height: 100%; border-radius: 8px;">
          <button type="button" class="remove-image-btn" title="Remove image">
            <i class="fa-solid fa-xmark"></i>
          </button>
        </div>
      `;
      coverPreview.querySelector('.remove-image-btn').addEventListener('click', (e) => {
        e.preventDefault();
        coverInput.value = '';
        document.getElementById('barangayCoverImageBase64').value = '';
        coverPreview.innerHTML = '<i class="fa-solid fa-image"></i><span>No image selected</span>';
      });
    };
    reader.readAsDataURL(file);
  });
}

function setupHotlineLogoUpload() {
  const logoInput = document.getElementById('hotlineLogo');
  const logoPreview = document.getElementById('hotlineLogoPreview');

  if (!logoInput || !logoPreview) return;

  logoInput.addEventListener('change', (e) => {
    const file = e.target.files[0];
    if (!file) return;

    const reader = new FileReader();
    reader.onload = (event) => {
      const base64 = event.target.result;
      document.getElementById('hotlineLogoBase64').value = base64;
      logoPreview.innerHTML = `
        <div class="preview-image-wrapper">
          <img src="${base64}" alt="logo preview" style="max-width: 100%; max-height: 100%; border-radius: 8px;">
          <button type="button" class="remove-image-btn" title="Remove image">
            <i class="fa-solid fa-xmark"></i>
          </button>
        </div>
      `;
      logoPreview.querySelector('.remove-image-btn').addEventListener('click', (e) => {
        e.preventDefault();
        logoInput.value = '';
        document.getElementById('hotlineLogoBase64').value = '';
        logoPreview.innerHTML = '<i class="fa-solid fa-image"></i><span>No image selected</span>';
      });
    };
    reader.readAsDataURL(file);
  });
}


function setupTransparencyPdfUpload() {
  const pdfInput = document.getElementById('transparencyPdfUrl');
  const pdfPreview = document.getElementById('transparencyPdfPreview');

  if (!pdfInput || !pdfPreview) return;

  pdfInput.addEventListener('change', (e) => {
    const file = e.target.files[0];
    if (!file) return;

    if (!file.type.includes('pdf')) {
      showToast('Please select a valid PDF file', 'error');
      pdfInput.value = '';
      return;
    }

    pdfPreview.innerHTML = `
      <div class="preview-file-wrapper">
        <i class="fa-solid fa-file-pdf"></i>
        <span>${file.name}</span>
        <button type="button" class="remove-image-btn" title="Remove file">
          <i class="fa-solid fa-xmark"></i>
        </button>
      </div>
    `;
    pdfPreview.querySelector('.remove-image-btn').addEventListener('click', (e) => {
      e.preventDefault();
      pdfInput.value = '';
      pdfPreview.innerHTML = '';
    });
  });
}

// ============================================================
// UTILITIES
// ============================================================
// Compress large admin photos before they reach Supabase (including base64 columns).
async function compressAdminImage(file) {
  if (!file || !file.type.startsWith('image/') || file.size <= 1024 * 1024 || file.type === 'image/gif') return file;

  const image = new Image();
  const objectUrl = URL.createObjectURL(file);
  try {
    await new Promise((resolve, reject) => {
      image.onload = resolve;
      image.onerror = () => reject(new Error(`Could not read image: ${file.name}`));
      image.src = objectUrl;
    });

    const canvas = document.createElement('canvas');
    const context = canvas.getContext('2d');
    if (!context) throw new Error('Image compression is not supported by this browser.');
    const outputType = file.type === 'image/png' || file.type === 'image/webp' ? 'image/webp' : 'image/jpeg';
    const extension = outputType === 'image/webp' ? 'webp' : 'jpg';
    let best = null;

    for (const maxDimension of [1920, 1440, 1080]) {
      const scale = Math.min(1, maxDimension / Math.max(image.naturalWidth, image.naturalHeight));
      canvas.width = Math.max(1, Math.round(image.naturalWidth * scale));
      canvas.height = Math.max(1, Math.round(image.naturalHeight * scale));
      context.drawImage(image, 0, 0, canvas.width, canvas.height);

      for (const quality of [0.85, 0.7, 0.55]) {
        const blob = await new Promise(resolve => canvas.toBlob(resolve, outputType, quality));
        if (!blob || blob.type !== outputType) throw new Error('This browser could not compress the selected image.');
        if (!best || blob.size < best.size) best = blob;
        if (blob.size <= 1024 * 1024) break;
      }
      if (best && best.size <= 1024 * 1024) break;
    }

    if (!best || best.size >= file.size) return file;
    const baseName = file.name.replace(/\.[^.]+$/, '');
    return new File([best], `${baseName}.${extension}`, { type: outputType, lastModified: file.lastModified });
  } finally {
    URL.revokeObjectURL(objectUrl);
  }
}

// Retry at smaller dimensions if the general photo compressor cannot get an
// unusually large image below the upload limit.
async function compressImageForUpload(originalFile, maxBytes) {
  const prepared = await compressAdminImage(originalFile);
  if (prepared.size <= maxBytes || !prepared.type.startsWith('image/')) return prepared;

  const image = new Image();
  const objectUrl = URL.createObjectURL(prepared);
  try {
    await new Promise((resolve, reject) => {
      image.onload = resolve;
      image.onerror = () => reject(new Error(`Could not read image: ${prepared.name}`));
      image.src = objectUrl;
    });

    const canvas = document.createElement('canvas');
    const context = canvas.getContext('2d');
    if (!context) throw new Error('Image compression is not supported by this browser.');
    const outputType = prepared.type === 'image/png' || prepared.type === 'image/webp' ? 'image/webp' : 'image/jpeg';
    const extension = outputType === 'image/webp' ? 'webp' : 'jpg';
    let smallest = null;
    for (const maxDimension of [1600, 1200, 900, 700, 500, 320]) {
      const scale = Math.min(1, maxDimension / Math.max(image.naturalWidth, image.naturalHeight));
      canvas.width = Math.max(1, Math.round(image.naturalWidth * scale));
      canvas.height = Math.max(1, Math.round(image.naturalHeight * scale));
      context.drawImage(image, 0, 0, canvas.width, canvas.height);
      for (const quality of [0.7, 0.5, 0.35, 0.2]) {
        const blob = await new Promise(resolve => canvas.toBlob(resolve, outputType, quality));
        if (!blob || blob.type !== outputType) throw new Error('This browser could not compress the selected image.');
        if (!smallest || blob.size < smallest.size) smallest = blob;
        if (blob.size <= maxBytes) {
          const baseName = prepared.name.replace(/\.[^.]+$/, '');
          return new File([blob], `${baseName}.${extension}`, { type: outputType, lastModified: prepared.lastModified });
        }
      }
    }
    if (!smallest || smallest.size >= prepared.size) return prepared;
    const baseName = prepared.name.replace(/\.[^.]+$/, '');
    return new File([smallest], `${baseName}.${extension}`, { type: outputType, lastModified: prepared.lastModified });
  } finally {
    URL.revokeObjectURL(objectUrl);
  }
}

async function compressedImageDataUrl(file, fallback) {
  if (!file) return fallback;
  const prepared = await compressAdminImage(file);
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = () => resolve(reader.result);
    reader.onerror = () => reject(new Error(`Could not read image: ${file.name}`));
    reader.readAsDataURL(prepared);
  });
}

function decodeBase64(base64String) {
  const base64 = base64String.replace(/^data:image\/[^;]+;base64,/, '');
  const binary = atob(base64);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) {
    bytes[i] = binary.charCodeAt(i);
  }
  return bytes;
}

let submissionAgeTimer = null;

function updateSubmissionAges() {
  document.querySelectorAll('[data-submitted-at]').forEach(element => {
    const age = formatSubmissionAge(element.dataset.submittedAt);
    if (element instanceof HTMLInputElement) element.value = age;
    else element.textContent = age;
  });
}

function createSubmissionAgeCell(submittedAt) {
  const cell = document.createElement('td');
  cell.className = 'submission-age-cell';
  const timestamp = parseSubmissionTime(submittedAt);
  cell.textContent = formatSubmissionAge(submittedAt);
  if (timestamp) cell.dataset.submittedAt = timestamp.toISOString();
  if (!submissionAgeTimer) submissionAgeTimer = setInterval(updateSubmissionAges, 1000);
  return cell;
}

function formatDate(dateStr) {
  if (!dateStr) return 'N/A';
  try {
    const date = new Date(dateStr);
    return date.toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric'
    });
  } catch {
    return dateStr;
  }
}

function debounce(func, wait) {
  let timeout;
  return function executedFunction(...args) {
    const later = () => {
      clearTimeout(timeout);
      func(...args);
    };
    clearTimeout(timeout);
    timeout = setTimeout(later, wait);
  };
}

// ============================================================
// PLACE REVIEWS MODAL
// ============================================================
async function openPlaceReviewsModal(placeId, placeName) {
  const modal = document.getElementById('placeReviewsModal');
  const modalTitle = document.getElementById('placeReviewsModalTitle');
  const reviewsList = document.getElementById('reviewsList');
  const selectedPlaceId = document.getElementById('selectedPlaceId');

  modalTitle.textContent = `Reviews for ${placeName}`;
  selectedPlaceId.value = placeId;
  reviewsList.innerHTML = '<p style="text-align: center; color: #999; padding: 20px;">Loading reviews...</p>';
  modal.classList.add('active');

  try {
    const placeReviews = allPlaceReviews.filter(r => r.place_id === placeId);

    if (placeReviews.length === 0) {
      reviewsList.innerHTML = '<p style="text-align: center; color: #999; padding: 20px;">No reviews yet</p>';
      return;
    }

    reviewsList.innerHTML = '';
    placeReviews.forEach(review => {
      const reviewCard = document.createElement('div');
      reviewCard.style.cssText = `
        background: linear-gradient(135deg, #ffffff 0%, #fafbfc 100%);
        border: 1px solid #e5e7eb;
        border-radius: 12px;
        padding: 20px;
        margin-bottom: 16px;
        transition: all 0.3s ease;
      `;

      reviewCard.addEventListener('mouseenter', function() {
        this.style.boxShadow = '0 4px 20px rgba(0, 0, 0, 0.1)';
        this.style.transform = 'translateY(-2px)';
      });

      reviewCard.addEventListener('mouseleave', function() {
        this.style.boxShadow = 'none';
        this.style.transform = 'translateY(0)';
      });

      const headerDiv = document.createElement('div');
      headerDiv.style.cssText = 'display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 14px; gap: 12px;';

      const authorInfoDiv = document.createElement('div');
      authorInfoDiv.style.cssText = 'display: flex; gap: 12px; align-items: flex-start; flex: 1;';

      const avatarDiv = document.createElement('div');
      const displayName = review.display_name || 'Anonymous';
      const initials = displayName
        .split(' ')
        .slice(0, 2)
        .map(n => n[0])
        .join('')
        .toUpperCase();

      avatarDiv.style.cssText = `
        width: 40px;
        height: 40px;
        border-radius: 50%;
        background: linear-gradient(135deg, #2196F3, #1976D2);
        display: flex;
        align-items: center;
        justify-content: center;
        color: white;
        font-weight: 700;
        font-size: 14px;
        flex-shrink: 0;
      `;
      avatarDiv.textContent = initials;

      const nameTimeDiv = document.createElement('div');
      nameTimeDiv.style.cssText = 'flex: 1;';

      const authorName = document.createElement('p');
      authorName.textContent = displayName;
      authorName.style.cssText = 'margin: 0 0 4px 0; font-weight: 700; color: #0f1a2e; font-size: 15px; letter-spacing: -0.3px;';

      const dateSpan = document.createElement('span');
      dateSpan.textContent = `${formatDate(review.created_at)}`;
      dateSpan.style.cssText = 'font-size: 12px; color: #9ca3af; display: block;';

      nameTimeDiv.appendChild(authorName);
      nameTimeDiv.appendChild(dateSpan);

      authorInfoDiv.appendChild(avatarDiv);
      authorInfoDiv.appendChild(nameTimeDiv);

      const ratingDiv = document.createElement('div');
      ratingDiv.style.cssText = 'display: flex; align-items: center; gap: 8px; white-space: nowrap;';

      const starsSpan = document.createElement('span');
      starsSpan.innerHTML = '★'.repeat(review.rating) + '☆'.repeat(5 - review.rating);
      starsSpan.style.cssText = 'font-size: 16px; color: #fbbf24; letter-spacing: 1px;';

      const ratingValue = document.createElement('span');
      ratingValue.textContent = `${review.rating}/5`;
      ratingValue.style.cssText = 'font-weight: 700; color: #2196F3; font-size: 13px;';

      ratingDiv.appendChild(starsSpan);
      ratingDiv.appendChild(ratingValue);

      headerDiv.appendChild(authorInfoDiv);
      headerDiv.appendChild(ratingDiv);

      const reviewText = document.createElement('p');
      reviewText.textContent = review.review_text || '';
      reviewText.style.cssText = 'margin: 0; color: #4b5563; font-size: 14px; line-height: 1.6; font-weight: 500;';

      reviewCard.appendChild(headerDiv);
      reviewCard.appendChild(reviewText);

      reviewsList.appendChild(reviewCard);
    });
  } catch (error) {
    console.error('Error loading reviews:', error);
    reviewsList.innerHTML = '<p style="text-align: center; color: #ef4444;">Error loading reviews</p>';
  }
}

function closePlaceReviewsModal() {
  const modal = document.getElementById('placeReviewsModal');
  modal.classList.remove('active');
}

// ============================================================
// USERS MANAGEMENT
// ============================================================
let allUsers = [];

async function syncUsersFromFirebase() {
  if (!canAccessUserDirectory()) throw new Error('Admin access required.');
  const syncEndpoint = window.location.protocol === 'file:'
    ? 'http://localhost:5000/api/sync-users'
    : '/api/sync-users';
  const { data: sessionData } = await supabaseClient.auth.getSession();
  const accessToken = sessionData?.session?.access_token;
  if (!accessToken) {
    throw new Error('Admin session is not available for user synchronization.');
  }

  const response = await fetch(syncEndpoint, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${accessToken}`
    }
  });

  let result = null;
  try {
    result = await response.json();
  } catch {
    result = null;
  }

  if (!response.ok || !result?.success) {
    throw new Error(result?.error || `Sync failed with status ${response.status}`);
  }

  return result;
}

async function loadUsers() {
  if (!canAccessUserDirectory()) {
    allUsers = [];
    tableExportRows.usersTableBody = [];
    document.getElementById('usersTableBody')?.replaceChildren();
    return;
  }
  const tbody = document.getElementById('usersTableBody');
  if (!tbody) return;

  if (!supabaseClient) {
    const colSpan = tbody.closest('table').querySelectorAll('th').length;
    tbody.innerHTML = `<tr><td colspan="${colSpan}" class="empty-state">Database connection unavailable</td></tr>`;
    return;
  }

  try {
    try {
      const syncResult = await syncUsersFromFirebase();
      console.log(`Synced ${syncResult.usersSynced || 0} Firebase users before loading Manage Citizen.`);
    } catch (syncError) {
      console.warn('Firebase user sync unavailable; loading existing Supabase users:', syncError);
      showToast(
        'Firebase sync failed. Start the backend or open the deployed admin dashboard to load all users.',
        'warning'
      );
    }

    const { data, error } = await supabaseClient
      .from('users')
      .select('*')
      .order('created_at', { ascending: false })
      .range(0, 9999);

    if (error) throw error;

    const userIds = (data || []).map(user => user.id).filter(Boolean);
    let verificationMap = {};

    if (userIds.length > 0) {
      const { data: verificationData, error: verificationError } = await supabaseClient
        .from('identity_verification')
        .select('user_id, verification_status')
        .in('user_id', userIds);

      if (verificationError) throw verificationError;

      (verificationData || []).forEach(item => {
        verificationMap[item.user_id] = item.verification_status || 'pending';
      });
    }

    allUsers = (data || []).map(user => ({
      ...user,
      verification_status: verificationMap[user.id] || 'not_submitted'
    }));

    renderUsersTable(allUsers);
    updateAdminRolePasswordHint();
  } catch (error) {
    console.error('Error loading users:', error);
    showToast('Failed to load users from database: ' + error.message, 'error');
  }
}

function getVerificationBadgeClass(status) {
  if (status === 'verified') return 'status-verified';
  if (status === 'pending') return 'status-pending';
  if (status === 'rejected') return 'status-rejected';
  return 'status-not-submitted';
}

function getVerificationBadgeText(status) {
  if (status === 'verified') return 'Verified';
  if (status === 'pending') return 'Pending';
  if (status === 'rejected') return 'Returned';
  return 'Not Submitted';
}

function isRlsPolicyError(error) {
  const message = String(error?.message || '').toLowerCase();
  return Boolean(
    error && (
      error.code === '42501' ||
      message.includes('row level security') ||
      message.includes('policy') ||
      message.includes('permission denied')
    )
  );
}

function populateAdminRoleFeatureOptions() {
  const container = document.getElementById('adminRoleFeatureOptions');
  if (!container) return;

  container.innerHTML = ADMIN_FEATURES.map(feature => `
    <label class="checkbox-label">
      <input type="checkbox" name="adminRoleFeatures" value="${escapeHtml(feature.value)}" />
      <span>${escapeHtml(feature.label)}</span>
    </label>
  `).join('');
  container.querySelectorAll('input').forEach(input => {
    input.addEventListener('change', updateReportCategoryAccessVisibility);
  });
}

function selectedAdminFeatures() {
  return Array.from(document.querySelectorAll('input[name="adminRoleFeatures"]:checked'))
    .map(input => input.value);
}

function populateAdminReportCategoryOptions() {
  const container = document.getElementById('adminReportCategoryOptions');
  if (!container) return;

  container.innerHTML = REPORT_CATEGORIES.map(category => `
    <label class="checkbox-label">
      <input type="checkbox" name="adminReportCategories" value="${escapeHtml(category)}" />
      <span>${escapeHtml(category)}</span>
    </label>
  `).join('');
}

function populateAdminTransparencyCategoryOptions() {
  document.getElementById('adminTransparencyCategoryOptions').innerHTML = TRANSPARENCY_CATEGORIES.map(category => `
    <label class="checkbox-label">
      <input type="checkbox" name="adminTransparencyCategories" value="${category.value}" />
      <span>${escapeHtml(category.label)}</span>
    </label>
  `).join('');
}

function updateReportCategoryAccessVisibility() {
  const group = document.getElementById('reportCategoryAccessGroup');
  if (!group) return;

  group.style.display = selectedAdminFeatures().includes('reports') ? 'block' : 'none';
  document.getElementById('transparencyCategoryAccessGroup').style.display = selectedAdminFeatures().includes('transparency') ? 'block' : 'none';
}

function selectedAdminReportCategories() {
  return Array.from(
    document.querySelectorAll('input[name="adminReportCategories"]:checked')
  ).map(input => input.value);
}

function toggleAdminRolePassword() {
  const input = document.getElementById('adminRolePassword');
  const button = document.getElementById('adminPasswordToggle');
  const visible = input.type === 'password';
  input.type = visible ? 'text' : 'password';
  button.setAttribute('aria-pressed', String(visible));
  button.setAttribute('aria-label', visible ? 'Hide password' : 'Show password');
  button.innerHTML = `<i class="fa-regular ${visible ? 'fa-eye-slash' : 'fa-eye'}" aria-hidden="true"></i>`;
}

function updateAdminRolePasswordHint() {
  const selectedEmail = String(document.getElementById('adminRoleEmail')?.value || '').trim().toLowerCase();
  const existingAdmin = getAdminRoles().some(role =>
    String(role.assignedEmail || '').trim().toLowerCase() === selectedEmail
  );
  const requiredMark = document.getElementById('adminRolePasswordRequired');
  const hint = document.getElementById('adminRolePasswordHint');
  if (requiredMark) requiredMark.style.display = existingAdmin ? 'none' : '';
  if (hint) hint.textContent = existingAdmin
    ? 'This admin already has an account. Leave the password blank to keep it.'
    : 'Required for a new admin account. Existing admins keep their password.';
}

function loadManageAdmin() {
  populateAdminRoleFeatureOptions();
  populateAdminReportCategoryOptions();
  populateAdminTransparencyCategoryOptions();
  const emailInput = document.getElementById('adminRoleEmail');
  if (emailInput) emailInput.oninput = updateAdminRolePasswordHint;
  updateReportCategoryAccessVisibility();
  updateAdminRolePasswordHint();
  renderAdminRoles();
}

function renderAdminRoles() {
  const list = document.getElementById('adminRoleList');
  if (!list) return;

  const roles = getAdminRoles();
  if (!roles.length) {
    list.innerHTML = '<p class="empty-state">No admin roles created yet.</p>';
    renderAdminRolesPagination(0);
    return;
  }

  const totalPages = Math.ceil(roles.length / ADMIN_ROLES_PER_PAGE);
  if (paginationState.adminRoles.current > totalPages) {
    paginationState.adminRoles.current = totalPages;
  }
  const startIndex = (paginationState.adminRoles.current - 1) * ADMIN_ROLES_PER_PAGE;
  const visibleRoles = roles.slice(startIndex, startIndex + ADMIN_ROLES_PER_PAGE);

  list.innerHTML = visibleRoles.map(role => {
    const permissions = Array.isArray(role.permissions) && role.permissions.length > 0
      ? role.permissions
      : buildPermissionSet(role.feature || role.permission || '');
    const accessLabels = permissions.length
      ? permissions.map(value => ADMIN_FEATURES.find(feature => feature.value === value)?.label || value).join(', ')
      : 'No feature access';
    const transparencyCategoryLabels = TRANSPARENCY_CATEGORIES.filter(category => (role.transparencyCategories || []).includes(category.value)).map(category => category.label).join(', ');
    const reportCategoryLabels = normalizeReportCategories(role.reportCategories).join(', ');

    return `
      <div class="admin-role-item">
        <div class="admin-role-header">
          <div>
            <h3>${escapeHtml(role.isSuperAdmin ? 'Admin' : role.roleName || 'Unnamed Role')}</h3>
            <div class="admin-role-meta">
              <span class="admin-role-tag ${role.isSuperAdmin ? 'super' : ''}">${role.isSuperAdmin ? 'Admin' : 'Feature Access'}</span>
              ${role.assignedEmail ? `<span class="admin-role-email">${escapeHtml(role.assignedEmail)}</span>` : '<span class="admin-role-email">Unassigned</span>'}
            </div>
          </div>
          <div class="admin-role-actions">
            <button type="button" class="btn btn-sm btn-secondary" onclick="editAdminRole('${role.id}')">
              <i class="fa-solid fa-pen"></i> Edit
            </button>
            <button type="button" class="btn btn-sm btn-delete" onclick="deleteAdminRole('${role.id}')">
              <i class="fa-solid fa-trash"></i> Remove
            </button>
          </div>
        </div>
        ${permissions.includes('transparency') && !role.isSuperAdmin ? `<p class="admin-role-access"><strong>Transparency categories:</strong> ${escapeHtml(transparencyCategoryLabels || 'None assigned')}</p>` : ''}
        <p class="admin-role-access"><strong>Access:</strong> ${escapeHtml(accessLabels)}</p>
        ${permissions.includes('reports') && !role.isSuperAdmin ? `<p class="admin-role-access"><strong>Report categories:</strong> ${escapeHtml(reportCategoryLabels || 'None assigned')}</p>` : ''}
      </div>
    `;
  }).join('');

  renderAdminRolesPagination(roles.length);
}

let editingAdminRoleId = null;
let adminRoleEditBusy = false;

function updateEditAdminReportVisibility() {
  const hasReports = document.querySelector('#editAdminRoleFeatures input[value="reports"]')?.checked;
  document.getElementById('editAdminReportGroup').hidden = !hasReports;
  document.getElementById('editAdminTransparencyGroup').hidden = !document.querySelector('#editAdminRoleFeatures input[value="transparency"]')?.checked;
}

function editAdminRole(roleId) {
  if (adminRoleEditBusy) return;
  if (!getCurrentAdminSession().isSuperAdmin || databaseAdminRoles === null) {
    showToast('Only the Admin can edit staff access.', 'error');
    return;
  }
  const role = getAdminRoles().find(item => item.id === roleId);
  if (!role) return;
  const accountRoles = getAdminRoles().filter(item =>
    String(item.assignedEmail || '').toLowerCase() === String(role.assignedEmail || '').toLowerCase()
  );
  const isSuperAdmin = accountRoles.some(item => item.isSuperAdmin);
  const features = new Set(accountRoles.flatMap(item => item.permissions?.length
    ? item.permissions : buildPermissionSet(item.feature)));
  const categories = new Set(normalizeReportCategories(accountRoles.flatMap(item => item.reportCategories || [])));
  editingAdminRoleId = roleId;
  document.getElementById('editAdminRoleEmail').textContent = role.assignedEmail || 'Unassigned';
  document.getElementById('editAdminRoleName').value = isSuperAdmin ? 'Admin' : role.roleName || '';
  document.getElementById('editAdminRoleError').textContent = '';
  document.getElementById('editAdminFeatureGroup').hidden = isSuperAdmin;
  document.getElementById('editAdminRoleFeatures').innerHTML = ADMIN_FEATURES.map(feature => `
    <label class="checkbox-label">
      <input type="checkbox" value="${escapeHtml(feature.value)}" ${features.has(feature.value) ? 'checked' : ''} />
      <span>${escapeHtml(feature.label)}</span>
    </label>
  `).join('');
  document.getElementById('editAdminReportCategories').innerHTML = REPORT_CATEGORIES.map(category => `
    <label class="checkbox-label">
      <input type="checkbox" value="${escapeHtml(category)}" ${categories.has(category) ? 'checked' : ''} />
      <span>${escapeHtml(category)}</span>
    </label>
  `).join('');
  const transparencyCategories = new Set(accountRoles.flatMap(item => item.transparencyCategories || []));
  document.getElementById('editAdminTransparencyCategories').innerHTML = TRANSPARENCY_CATEGORIES.map(category => `
    <label class="checkbox-label">
      <input type="checkbox" value="${category.value}" ${transparencyCategories.has(category.value) ? 'checked' : ''} />
      <span>${escapeHtml(category.label)}</span>
    </label>
  `).join('');
  document.querySelectorAll('#editAdminRoleFeatures input').forEach(input =>
    input.addEventListener('change', updateEditAdminReportVisibility));
  updateEditAdminReportVisibility();
  document.getElementById('editAdminRoleModal').showModal();
}

function closeEditAdminRole() {
  if (adminRoleEditBusy) return;
  document.getElementById('editAdminRoleModal').close();
  editingAdminRoleId = null;
}

async function saveEditedAdminRole() {
  if (!editingAdminRoleId || adminRoleEditBusy) return;
  const role = getAdminRoles().find(item => item.id === editingAdminRoleId);
  if (!role) return;
  const name = document.getElementById('editAdminRoleName').value.trim();
  const features = Array.from(document.querySelectorAll('#editAdminRoleFeatures input:checked'), input => input.value);
  const reportCategories = Array.from(document.querySelectorAll('#editAdminReportCategories input:checked'), input => input.value);
  const transparencyCategories = Array.from(document.querySelectorAll('#editAdminTransparencyCategories input:checked'), input => input.value);
  const errorMessage = document.getElementById('editAdminRoleError');
  if (!name) { errorMessage.textContent = 'Enter a role name.'; return; }
  const accountIsSuperAdmin = getAdminRoles().some(item => item.isSuperAdmin &&
    String(item.assignedEmail || '').toLowerCase() === String(role.assignedEmail || '').toLowerCase());
  if (!accountIsSuperAdmin && !features.length) { errorMessage.textContent = 'Select at least one feature.'; return; }
  if (!accountIsSuperAdmin && features.includes('reports') && !reportCategories.length) {
    errorMessage.textContent = 'Select at least one report category.';
    return;
  }
  if (!accountIsSuperAdmin && features.includes('transparency') && !transparencyCategories.length) {
    errorMessage.textContent = 'Select at least one transparency category.';
    return;
  }
  const modal = document.getElementById('editAdminRoleModal');
  const saveButton = document.getElementById('editAdminRoleSave');
  adminRoleEditBusy = true;
  modal.setAttribute('aria-busy', 'true');
  modal.querySelectorAll('button').forEach(button => { button.disabled = true; });
  saveButton.textContent = 'Saving...';
  errorMessage.textContent = '';
  try {
    if (!getCurrentAdminSession().isSuperAdmin || databaseAdminRoles === null) {
      throw new Error('Only the Admin can edit staff access.');
    }
    const { data: sessionData } = await supabaseClient.auth.getSession();
    const token = sessionData?.session?.access_token;
    if (!token) throw new Error('Your admin session has expired. Please sign in again.');
    const response = await fetch('/api/admin-roles/edit', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
      body: JSON.stringify({ roleId: editingAdminRoleId, roleName: name, features, reportCategories, transparencyCategories })
    });
    if (!response.headers.get('content-type')?.includes('application/json')) {
      throw new Error('Admin edit API is unavailable. Deploy the API with SUPABASE_SERVICE_ROLE_KEY.');
    }
    const result = await response.json();
    if (!response.ok) throw new Error(result.error || 'Failed to edit admin access.');
    await loadAdminRolesFromDatabase({ email: getCurrentAdminSession().email });
    modal.close();
    editingAdminRoleId = null;
    showToast('Admin access updated.', 'success');
  } catch (error) {
    console.error('Edit admin role error:', error);
    errorMessage.textContent = error?.message || 'Failed to edit admin access.';
    try { await loadAdminRolesFromDatabase({ email: getCurrentAdminSession().email }); }
    catch (refreshError) { console.warn('Could not refresh admin roles:', refreshError); }
  } finally {
    adminRoleEditBusy = false;
    modal.removeAttribute('aria-busy');
    modal.querySelectorAll('button').forEach(button => { button.disabled = false; });
    saveButton.textContent = 'Save Changes';
  }
}

function renderAdminRolesPagination(totalItems) {
  const paginationEl = document.getElementById('adminRolesPagination');
  const showingEl = document.getElementById('adminRolesShowing');
  if (!paginationEl || !showingEl) return;

  const totalPages = Math.ceil(totalItems / ADMIN_ROLES_PER_PAGE);
  const currentPage = paginationState.adminRoles.current;
  paginationState.adminRoles.total = totalPages;
  showingEl.textContent = totalItems
    ? `Showing ${Math.min(currentPage * ADMIN_ROLES_PER_PAGE, totalItems)} of ${totalItems} roles`
    : 'Showing 0 of 0 roles';

  if (totalPages <= 1) {
    paginationEl.innerHTML = '';
    return;
  }

  let html = `<button class="page-btn prev-btn" data-page="${currentPage - 1}" ${currentPage === 1 ? 'disabled' : ''}><i class="fa-solid fa-chevron-left"></i></button>`;
  const maxButtons = 5;
  let startPage = Math.max(1, currentPage - Math.floor(maxButtons / 2));
  let endPage = Math.min(totalPages, startPage + maxButtons - 1);
  if (endPage - startPage + 1 < maxButtons) {
    startPage = Math.max(1, endPage - maxButtons + 1);
  }
  if (startPage > 1) {
    html += '<button class="page-btn" data-page="1">1</button>';
    if (startPage > 2) html += '<span class="page-ellipsis">...</span>';
  }
  for (let page = startPage; page <= endPage; page++) {
    html += `<button class="page-btn ${page === currentPage ? 'active' : ''}" data-page="${page}">${page}</button>`;
  }
  if (endPage < totalPages) {
    if (endPage < totalPages - 1) html += '<span class="page-ellipsis">...</span>';
    html += `<button class="page-btn" data-page="${totalPages}">${totalPages}</button>`;
  }
  html += `<button class="page-btn next-btn" data-page="${currentPage + 1}" ${currentPage === totalPages ? 'disabled' : ''}><i class="fa-solid fa-chevron-right"></i></button>`;
  paginationEl.innerHTML = html;

  paginationEl.querySelectorAll('.page-btn').forEach(button => {
    button.addEventListener('click', () => {
      const page = Number(button.dataset.page);
      if (page >= 1 && page <= totalPages) {
        paginationState.adminRoles.current = page;
        renderAdminRoles();
      }
    });
  });
}

async function createAdminRole() {
  const email = String(document.getElementById('adminRoleEmail')?.value || '').trim().toLowerCase();
  const password = document.getElementById('adminRolePassword')?.value || '';
  const roleName = document.getElementById('adminRoleName')?.value.trim();
  const selectedFeatures = selectedAdminFeatures();
  const reportCategories = selectedAdminReportCategories();
  const transparencyCategories = Array.from(document.querySelectorAll('input[name="adminTransparencyCategories"]:checked'), input => input.value);
  if (selectedFeatures.includes('transparency') && !transparencyCategories.length) {
    showToast('Select at least one transparency category for this admin.', 'error');
    return;
  }

  if (!email) {
    showToast('Please enter an admin email.', 'error');
    return;
  }

  if (!roleName) {
    showToast('Please enter a role name.', 'error');
    return;
  }

  if (selectedFeatures.length === 0) {
    showToast('Please select at least one feature for this admin.', 'error');
    return;
  }

  if (selectedFeatures.includes('reports') && reportCategories.length === 0) {
    showToast('Select at least one report category for this admin.', 'error');
    return;
  }

  if (!supabaseClient) {
    showToast('Supabase is not available. Please refresh the page.', 'error');
    return;
  }
  if (!getCurrentAdminSession().isSuperAdmin || databaseAdminRoles === null) {
    showToast('Only the Admin can add staff access.', 'error');
    return;
  }

  try {
    const roles = getAdminRoles();
    const existingAdminRoles = roles.filter(role =>
      String(role.assignedEmail || '').trim().toLowerCase() === email
    );
    const existingAdmin = existingAdminRoles.length > 0;
    if (!existingAdmin && (!password || password.length < 8)) {
      showToast('Password must be at least 8 characters long for a new admin account.', 'error');
      return;
    }
    const roleTemplate = {
      roleName,
      assignedEmail: email,
      authUserId: existingAdminRoles.find(role => role.authUserId)?.authUserId || null
    };
    const featuresToAdd = selectedFeatures
      .filter(feature => !existingAdminRoles.some(role => role.feature === feature));
    if (!featuresToAdd.length) {
      showToast(`${email} already has all selected feature access.`, 'error');
      return;
    }
    const newRoles = featuresToAdd.map(feature => ({
      ...roleTemplate,
      feature,
      permissions: feature === 'all' ? ADMIN_FEATURES.map(item => item.value) : buildPermissionSet(feature),
      reportCategories: feature === 'all' ? REPORT_CATEGORIES
        : feature === 'reports' ? normalizeReportCategories(reportCategories) : [],
      transparencyCategories: feature === 'all' ? TRANSPARENCY_CATEGORIES.map(item => item.value)
        : feature === 'transparency' ? normalizeTransparencyCategories(transparencyCategories) : []
    }));

    // Insert the selected feature roles together; existing admins keep their login.
    const savedRoles = await saveAdminRolesToDatabase(newRoles);
    let authUserId = roleTemplate.authUserId;
    if (!existingAdmin) {
      const { data: currentSessionData } = await supabaseClient.auth.getSession();
      const currentSession = currentSessionData?.session;
      const payload = buildAdminAccountCreationPayload({
        email, password, roleName, features: selectedFeatures, reportCategories, transparencyCategories
      });
      const { data, error } = await supabaseClient.auth.signUp(payload);
      if (error) {
        await supabaseClient.from('admin_roles').delete().in('id', savedRoles.map(role => role.id));
        throw error;
      }

      // With email confirmation disabled, signUp can switch the browser to
      // the new account. Restore the super-admin session before updating.
      if (currentSession && data?.session?.user?.id !== currentSession.user.id) {
        await supabaseClient.auth.setSession({
          access_token: currentSession.access_token,
          refresh_token: currentSession.refresh_token
        });
      }
      authUserId = data?.user?.id || null;
      if (authUserId) {
        const { error: linkError } = await supabaseClient.from('admin_roles')
          .update({ auth_user_id: authUserId })
          .in('id', savedRoles.map(role => role.id));
        if (linkError) console.warn('Could not link admin role to auth user:', linkError.message);
      }
    }

    databaseAdminRoles = [...(databaseAdminRoles || []),
      ...savedRoles.map(role => ({ ...role, authUserId }))];

    document.getElementById('adminRoleEmail').value = '';
    document.getElementById('adminRolePassword').value = '';
    document.getElementById('adminRoleName').value = '';
    document.querySelectorAll('input[name="adminRoleFeatures"]').forEach(input => {
      input.checked = false;
    });
    document.querySelectorAll('input[name="adminTransparencyCategories"]').forEach(input => { input.checked = false; });
    document.querySelectorAll('input[name="adminReportCategories"]').forEach(input => {
      input.checked = false;
    });
    updateReportCategoryAccessVisibility();
    updateAdminRolePasswordHint();
    renderAdminRoles();
    showToast(existingAdmin
      ? `${savedRoles.length} feature${savedRoles.length === 1 ? '' : 's'} added to the existing admin.`
      : 'Admin account created with selected features. Email confirmation may be required.', 'success');
  } catch (error) {
    console.error('Create admin role error:', error);
    showToast(error?.message || 'Failed to create admin account.', 'error');
  }
}

let pendingAdminRemoval = null;
let adminRemovalBusy = false;

function closeAdminAccessModal() {
  if (adminRemovalBusy) return;
  document.getElementById('adminAccessModal').close();
  pendingAdminRemoval = null;
}

function deleteAdminRole(roleId) {
  if (adminRemovalBusy) return;
  const roles = getAdminRoles();
  const role = roles.find(item => item.id === roleId);
  if (!role) return;

  if (!getCurrentAdminSession().isSuperAdmin || databaseAdminRoles === null) {
    showToast('Only the Admin can remove staff access.', 'error');
    return;
  }
  const email = role.assignedEmail || 'this account';
  pendingAdminRemoval = { roleId, email };
  document.getElementById('adminAccessEmail').textContent = email;
  document.getElementById('adminAccessError').textContent = '';
  document.getElementById('adminAccessModal').showModal();
}

async function confirmAdminAccessRemoval() {
  if (!pendingAdminRemoval || adminRemovalBusy) return;
  const { roleId, email } = pendingAdminRemoval;
  const modal = document.getElementById('adminAccessModal');
  const confirmButton = document.getElementById('adminAccessConfirm');
  const errorMessage = document.getElementById('adminAccessError');
  adminRemovalBusy = true;
  modal.setAttribute('aria-busy', 'true');
  modal.querySelectorAll('button').forEach(button => { button.disabled = true; });
  confirmButton.textContent = 'Removing access...';
  errorMessage.textContent = '';

  try {
    if (!getCurrentAdminSession().isSuperAdmin || databaseAdminRoles === null) {
      throw new Error('Only the Admin can remove staff access.');
    }
    const { data: sessionData } = await supabaseClient.auth.getSession();
    const token = sessionData?.session?.access_token;
    if (!token) throw new Error('Your admin session has expired. Please sign in again.');
    const response = await fetch('/api/admin-roles/remove', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`
      },
      body: JSON.stringify({ roleId })
    });
    if (!response.headers.get('content-type')?.includes('application/json')) {
      throw new Error('Admin removal API is unavailable. Deploy the API with SUPABASE_SERVICE_ROLE_KEY.');
    }
    const result = await response.json();
    if (!response.ok) throw new Error(result.error || 'Failed to remove admin access.');
    const removedIds = new Set(result.removedIds || []);
    databaseAdminRoles = databaseAdminRoles.filter(item => !removedIds.has(item.id));
    renderAdminRoles();
    modal.close();
    pendingAdminRemoval = null;
    showToast(`Admin access removed for ${email}.`, 'success');
  } catch (error) {
    console.error('Delete admin role error:', error);
    errorMessage.textContent = error?.message || 'Failed to remove admin access. Please try again.';
  } finally {
    adminRemovalBusy = false;
    modal.removeAttribute('aria-busy');
    modal.querySelectorAll('button').forEach(button => { button.disabled = false; });
    confirmButton.textContent = 'Remove Access';
  }
}

function renderUsersTable(usersData) {
  const tbody = document.getElementById('usersTableBody');
  tableExportRows.usersTableBody = usersData;
  const colSpan = tbody.closest('table').querySelectorAll('th').length;

  const totalItems = usersData.length;
  const totalPages = Math.ceil(totalItems / ITEMS_PER_PAGE);
  const currentPage = paginationState.users.current;

  if (currentPage > totalPages && totalPages > 0) {
    paginationState.users.current = 1;
    renderUsersTable(usersData);
    return;
  }

  if (usersData.length === 0) {
    tbody.innerHTML = `<tr><td colspan="${colSpan}" class="empty-state">No users found</td></tr>`;
    renderUsersPagination(0);
    return;
  }

  const startIdx = (currentPage - 1) * ITEMS_PER_PAGE;
  const endIdx = startIdx + ITEMS_PER_PAGE;
  const pageData = usersData.slice(startIdx, endIdx);

  tbody.innerHTML = '';
  pageData.forEach(u => {
    const tr = document.createElement('tr');

    const tdEmail = document.createElement('td');
    tdEmail.textContent = u.email || 'N/A';
    tdEmail.style.fontWeight = '500';

    const tdFullName = document.createElement('td');
    tdFullName.textContent = u.display_name || u.user_metadata?.full_name || 'N/A';

    const tdPhone = document.createElement('td');
    tdPhone.textContent = u.phone || u.user_metadata?.phone || 'N/A';
    tdPhone.style.fontSize = '13px';

    const tdAddress = document.createElement('td');
    tdAddress.textContent = u.address || u.user_metadata?.address || 'N/A';
    tdAddress.style.fontSize = '13px';

    const tdVerification = document.createElement('td');
    const statusBadge = document.createElement('span');
    statusBadge.className = `status-badge ${getVerificationBadgeClass(u.verification_status)}`;
    statusBadge.textContent = getVerificationBadgeText(u.verification_status);
    tdVerification.appendChild(statusBadge);

    const tdCreated = document.createElement('td');
    tdCreated.textContent = formatDate(u.created_at);
    tdCreated.style.fontSize = '13px';

    const tdActions = document.createElement('td');
    const actionsDiv = document.createElement('div');
    actionsDiv.className = 'action-btns';

    const editBtn = document.createElement('button');
    editBtn.className = 'btn btn-sm btn-edit btn-icon';
    editBtn.title = 'Edit';
    editBtn.innerHTML = '<i class="fa-solid fa-pen-to-square"></i>';
    editBtn.addEventListener('click', () => openEditUserModal(u.id, u));

    const blockBtn = document.createElement('button');
    blockBtn.className = `btn btn-sm btn-icon ${u.is_active === false ? 'btn-info' : 'btn-delete'}`;
    blockBtn.title = u.is_active === false ? 'Unblock user' : 'Block user';
    blockBtn.innerHTML = u.is_active === false
      ? '<i class="fa-solid fa-unlock"></i>'
      : '<i class="fa-solid fa-user-slash"></i>';
    blockBtn.addEventListener('click', () => toggleUserActiveState(u));

    actionsDiv.appendChild(editBtn);
    actionsDiv.appendChild(blockBtn);
    tdActions.appendChild(actionsDiv);

    tr.appendChild(tdEmail);
    tr.appendChild(tdFullName);
    tr.appendChild(tdPhone);
    tr.appendChild(tdAddress);
    tr.appendChild(tdVerification);
    tr.appendChild(tdCreated);
    tr.appendChild(tdActions);

    tbody.appendChild(tr);
  });

  renderUsersPagination(totalItems);
}

async function toggleUserActiveState(user) {
  const isBlocked = user.is_active === false;
  const action = isBlocked ? 'unblock' : 'block';
  const modal = document.getElementById('userAccessModal');
  const title = document.getElementById('userAccessModalTitle');
  const message = document.getElementById('userAccessMessage');
  const email = document.getElementById('userAccessEmail');
  const icon = document.getElementById('userAccessConfirmIcon');
  const button = document.getElementById('userAccessConfirmBtn');

  if (!modal || !title || !message || !email || !icon || !button) return;

  window.pendingUserAccessChange = { user, isBlocked };
  title.textContent = isBlocked ? 'Unblock User' : 'Block User';
  message.textContent = isBlocked
    ? 'This user will regain access to the application.'
    : 'This user will no longer be able to access the application.';
  email.textContent = user.email || 'Selected user';
  icon.classList.toggle('is-unblocking', isBlocked);
  icon.innerHTML = isBlocked
    ? '<i class="fa-solid fa-user-check"></i>'
    : '<i class="fa-solid fa-user-slash"></i>';
  button.className = `btn ${isBlocked ? 'btn-primary' : 'btn-danger'}`;
  button.innerHTML = isBlocked
    ? '<i class="fa-solid fa-user-check"></i> Unblock User'
    : '<i class="fa-solid fa-user-slash"></i> Block User';
  modal.classList.add('active');
}

function closeUserAccessModal() {
  document.getElementById('userAccessModal')?.classList.remove('active');
  window.pendingUserAccessChange = null;
}

async function confirmUserAccessChange() {
  const pending = window.pendingUserAccessChange;
  if (!pending) return;

  const { user, isBlocked } = pending;
  const action = isBlocked ? 'unblock' : 'block';
  const button = document.getElementById('userAccessConfirmBtn');
  if (button) {
    button.disabled = true;
    button.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> Saving...';
  }

  try {
    const { error } = await supabaseClient
      .from('users')
      .update({ is_active: isBlocked })
      .eq('id', user.id);

    if (error) throw error;

    showToast(`User ${isBlocked ? 'unblocked' : 'blocked'} successfully.`, 'success');
    closeUserAccessModal();
    await loadUsers();
  } catch (error) {
    console.error(`Error trying to ${action} user:`, error);
    showToast(`Failed to ${action} user: ${error.message}`, 'error');
    if (button) {
      button.disabled = false;
      button.innerHTML = isBlocked
        ? '<i class="fa-solid fa-user-check"></i> Unblock User'
        : '<i class="fa-solid fa-user-slash"></i> Block User';
    }
  }
}

async function openReviewUserModal(userId, userData) {
  const reviewModal = document.getElementById('reviewUserModal');
  const reviewUserName = document.getElementById('reviewUserName');
  const reviewUserEmail = document.getElementById('reviewUserEmail');
  const reviewUserStatus = document.getElementById('reviewUserStatus');
  const reviewSubmittedAt = document.getElementById('reviewSubmittedAt');
  const reviewFullName = document.getElementById('reviewFullName');
  const reviewIdType = document.getElementById('reviewIdType');
  const reviewIdNumber = document.getElementById('reviewIdNumber');
  const reviewDob = document.getElementById('reviewDob');
  const reviewVerificationReason = document.getElementById('reviewVerificationReason');

  if (!reviewModal || !reviewUserName || !reviewUserEmail || !reviewUserStatus) return;

  const record = userData || allUsers.find(u => u.id === userId) || {};
  const userName = record.display_name || record.user_metadata?.full_name || 'Unknown User';
  const userEmail = record.email || 'N/A';

  document.getElementById('reviewUserId').value = userId;
  reviewUserName.textContent = userName;
  reviewUserEmail.textContent = userEmail;
  reviewUserStatus.textContent = 'Pending';
  reviewUserStatus.className = 'status-badge status-pending';
  reviewSubmittedAt.textContent = '—';
  reviewFullName.textContent = '—';
  reviewIdType.textContent = '—';
  reviewIdNumber.textContent = '—';
  reviewDob.textContent = '—';
  reviewVerificationReason.value = '';

  const frontPreview = document.getElementById('reviewIdFrontPreview');
  const backPreview = document.getElementById('reviewIdBackPreview');
  const selfiePreview = document.getElementById('reviewSelfiePreview');
  frontPreview.innerHTML = '<div class="verification-preview-empty">No image</div>';
  backPreview.innerHTML = '<div class="verification-preview-empty">No image</div>';
  selfiePreview.innerHTML = '<div class="verification-preview-empty">No image</div>';

  try {
    const { data, error } = await supabaseClient
      .from('identity_verification')
      .select('*')
      .eq('user_id', userId)
      .maybeSingle();

    if (error) throw error;

    if (!data) {
      reviewUserStatus.textContent = 'Not Submitted';
      reviewUserStatus.className = 'status-badge status-not-submitted';
      showToast('No identity verification record found for this user.', 'warning');
      reviewModal.classList.add('active');
      return;
    }

    const status = data.verification_status || 'pending';
    reviewUserStatus.textContent = getVerificationBadgeText(status);
    reviewUserStatus.className = `status-badge ${getVerificationBadgeClass(status)}`;
    reviewSubmittedAt.textContent = data.submitted_at ? formatDate(data.submitted_at) : '—';
    reviewFullName.textContent = data.full_name || '—';
    reviewIdType.textContent = data.id_type || '—';
    reviewIdNumber.textContent = data.id_number || '—';
    reviewDob.textContent = data.date_of_birth ? formatDate(data.date_of_birth) : '—';
    reviewVerificationReason.value = data.rejection_reason || '';

    const setPreview = (container, imageUrl, label) => {
      if (!imageUrl) {
        container.innerHTML = '<div class="verification-preview-empty">No image</div>';
        return;
      }

      const img = document.createElement('img');
      img.src = imageUrl;
      img.alt = label;
      img.classList.add('verification-preview-image');
      img.tabIndex = 0;
      img.title = 'Click to view full size';
      const openImage = () => openImageLightbox(imageUrl, label);
      img.addEventListener('click', openImage);
      img.addEventListener('keydown', (event) => {
        if (event.key === 'Enter' || event.key === ' ') {
          event.preventDefault();
          openImage();
        }
      });
      img.onerror = () => {
        container.innerHTML = '<div class="verification-preview-empty">Image unavailable</div>';
      };
      container.innerHTML = '';
      container.appendChild(img);
    };

    const storageFallback = await getUserIdentityStorageUrls(userId);
    const frontUrl = data.id_front_photo_url || storageFallback.front;
    const backUrl = data.id_back_photo_url || storageFallback.back;
    const selfieUrl = data.selfie_photo_url || storageFallback.selfie;

    setPreview(frontPreview, frontUrl, 'Front ID');
    setPreview(backPreview, backUrl, 'Back ID');
    setPreview(selfiePreview, selfieUrl, 'Selfie');
  } catch (error) {
    console.error('Error loading identity verification:', error);
    showToast('Failed to load verification record: ' + error.message, 'error');
  }

  reviewModal.classList.add('active');
}

let imageLightboxTrigger = null;

function openImageLightbox(imageUrl, label = 'Verification image') {
  const lightbox = document.getElementById('imageLightbox');
  const lightboxImage = document.getElementById('imageLightboxImage');
  if (!lightbox || !lightboxImage || !imageUrl) return;

  imageLightboxTrigger = document.activeElement;
  lightboxImage.src = imageUrl;
  lightboxImage.alt = label;
  lightbox.classList.add('active');
  lightbox.setAttribute('aria-label', label);
  lightbox.setAttribute('aria-hidden', 'false');
  document.body.classList.add('image-lightbox-open');
  lightbox.querySelector('.image-lightbox-close')?.focus();
}

function closeImageLightbox() {
  const lightbox = document.getElementById('imageLightbox');
  const lightboxImage = document.getElementById('imageLightboxImage');
  if (!lightbox || !lightboxImage || !lightbox.classList.contains('active')) return;

  lightbox.classList.remove('active');
  lightbox.setAttribute('aria-hidden', 'true');
  lightboxImage.removeAttribute('src');
  document.body.classList.remove('image-lightbox-open');
  imageLightboxTrigger?.focus();
  imageLightboxTrigger = null;
}

document.getElementById('imageLightbox')?.addEventListener('click', (event) => {
  if (event.target.id === 'imageLightbox') closeImageLightbox();
});

document.addEventListener('keydown', (event) => {
  if (event.key === 'Escape') closeImageLightbox();
  if (event.key === 'Tab' && document.getElementById('imageLightbox')?.classList.contains('active')) {
    event.preventDefault();
    document.querySelector('#imageLightbox .image-lightbox-close')?.focus();
  }
});

async function getUserIdentityStorageUrls(userId) {
  if (!supabaseClient || !userId) return { front: null, back: null, selfie: null };

  try {
    const { data: files, error } = await supabaseClient
      .storage
      .from('identity-uploads')
      .list(userId, { limit: 50, offset: 0 });

    if (error || !files || !Array.isArray(files)) {
      return { front: null, back: null, selfie: null };
    }

    const item = (name) => {
      const match = files.find(file => file.name && file.name.toLowerCase().includes(name));
      return match ? `${userId}/${match.name}` : null;
    };

    const frontPath = item('id_front');
    const backPath = item('id_back');
    const selfiePath = item('selfie');

    const toSignedUrl = async (storagePath) => {
      if (!storagePath) return null;
      const { data, error: signedError } = await supabaseClient.storage
        .from('identity-uploads')
        .createSignedUrl(storagePath, 60 * 60 * 24);

      if (signedError || !data?.signedUrl) return null;
      return data.signedUrl;
    };

    return {
      front: await toSignedUrl(frontPath),
      back: await toSignedUrl(backPath),
      selfie: await toSignedUrl(selfiePath)
    };
  } catch (error) {
    console.warn('Could not load identity image URLs from storage:', error);
    return { front: null, back: null, selfie: null };
  }
}

function closeReviewUserModal() {
  const reviewModal = document.getElementById('reviewUserModal');
  if (reviewModal) {
    reviewModal.classList.remove('active');
  }
}

async function approveUserVerification() {
  // Didit is the sole source of verification decisions. Manual approvals are disabled.
  showToast('Manual identity approval is disabled. Verification is decided by Didit.', 'warning');
  return;

  const userId = document.getElementById('reviewUserId').value;
  if (!userId) {
    showToast('No user selected', 'error');
    return;
  }

  try {
    const timestamp = new Date().toISOString();
    const { error: verificationError } = await supabaseClient
      .from('identity_verification')
      .update({
        verification_status: 'verified',
        rejection_reason: null,
        verified_at: timestamp,
        updated_at: timestamp
      })
      .eq('user_id', userId);

    if (verificationError) throw verificationError;

    const { error: userError } = await supabaseClient
      .from('users')
      .update({
        is_verified: true,
        verification_completed_at: timestamp
      })
      .eq('id', userId);

    if (userError) throw userError;

    await sendVerificationStatusPushNotification({
      userId,
      status: 'verified',
      rejectionReason: ''
    });

    showToast('User identity approved successfully!', 'success');
    addNotification('Identity Approved', 'User verification has been approved and unlocked features are now available.', 'success');
    closeReviewUserModal();
    loadUsers();
  } catch (error) {
    console.error('Error approving user verification:', error);
    if (isRlsPolicyError(error)) {
      showToast('Approval blocked by Supabase RLS. Run the SQL fix in supabase/fix_identity_verification_rls.sql, then retry.', 'error');
    } else {
      showToast('Failed to approve user: ' + error.message, 'error');
    }
  }
}

async function rejectUserVerification() {
  // Didit is the sole source of verification decisions. Manual rejections are disabled.
  showToast('Manual identity returns are disabled. Verification is decided by Didit.', 'warning');
  return;

  const userId = document.getElementById('reviewUserId').value;
  const rejectionReason = document.getElementById('reviewVerificationReason').value.trim();

  if (!userId) {
    showToast('No user selected', 'error');
    return;
  }

  if (!rejectionReason) {
    showToast('Please provide a return reason before returning this ID.', 'error');
    return;
  }

  try {
    const timestamp = new Date().toISOString();
    const { error: verificationError } = await supabaseClient
      .from('identity_verification')
      .update({
        verification_status: 'rejected',
        rejection_reason: rejectionReason,
        updated_at: timestamp
      })
      .eq('user_id', userId);

    if (verificationError) throw verificationError;

    const { error: userError } = await supabaseClient
      .from('users')
      .update({
        is_verified: false,
        verification_completed_at: null
      })
      .eq('id', userId);

    if (userError) throw userError;

    await sendVerificationStatusPushNotification({
      userId,
      status: 'rejected',
      rejectionReason
    });

    showToast('User verification returned.', 'warning');
    addNotification('Identity Returned', `User verification was returned: ${rejectionReason}`, 'warning');
    closeReviewUserModal();
    loadUsers();
  } catch (error) {
    console.error('Error rejecting user verification:', error);
    if (isRlsPolicyError(error)) {
      showToast('Return blocked by Supabase RLS. Run the SQL fix in supabase/fix_identity_verification_rls.sql, then retry.', 'error');
    } else {
      showToast('Failed to return user verification: ' + error.message, 'error');
    }
  }
}

function renderUsersPagination(totalItems) {
  const paginationEl = document.getElementById('usersPagination');
  const showingEl = document.getElementById('usersShowing');
  if (!paginationEl || !showingEl) return;

  const totalPages = Math.ceil(totalItems / ITEMS_PER_PAGE);
  const currentPage = paginationState.users.current;
  paginationState.users.total = totalPages;
  showingEl.textContent = `Showing ${Math.min(currentPage * ITEMS_PER_PAGE, totalItems)} of ${totalItems} entries`;

  if (totalPages <= 1) {
    paginationEl.innerHTML = '';
    return;
  }

  let html = `<button class="page-btn prev-btn" data-page="${currentPage - 1}" ${currentPage === 1 ? 'disabled' : ''}><i class="fa-solid fa-chevron-left"></i></button>`;

  const maxButtons = 5;
  let startPage = Math.max(1, currentPage - Math.floor(maxButtons / 2));
  let endPage = Math.min(totalPages, startPage + maxButtons - 1);
  if (endPage - startPage + 1 < maxButtons) {
    startPage = Math.max(1, endPage - maxButtons + 1);
  }

  if (startPage > 1) {
    html += `<button class="page-btn" data-page="1">1</button>`;
    if (startPage > 2) html += `<span class="page-ellipsis">...</span>`;
  }

  for (let i = startPage; i <= endPage; i++) {
    html += `<button class="page-btn ${i === currentPage ? 'active' : ''}" data-page="${i}">${i}</button>`;
  }

  if (endPage < totalPages) {
    if (endPage < totalPages - 1) html += `<span class="page-ellipsis">...</span>`;
    html += `<button class="page-btn" data-page="${totalPages}">${totalPages}</button>`;
  }

  html += `<button class="page-btn next-btn" data-page="${currentPage + 1}" ${currentPage === totalPages ? 'disabled' : ''}><i class="fa-solid fa-chevron-right"></i></button>`;
  paginationEl.innerHTML = html;

  paginationEl.querySelectorAll('.page-btn').forEach(btn => {
    btn.addEventListener('click', (e) => {
      e.preventDefault();
      const page = parseInt(btn.dataset.page);
      if (page >= 1 && page <= totalPages) {
        paginationState.users.current = page;
        filterUsers();
        window.scrollTo(0, 0);
      }
    });
  });
}

function openEditUserModal(userId, userData) {
  document.getElementById('userModalTitle').textContent = 'Edit User';
  document.getElementById('userEditId').value = userId;
  document.getElementById('userEmail').value = userData.email || '';
  document.getElementById('userFullName').value = userData.display_name || '';
  document.getElementById('userPhone').value = userData.phone || '';
  document.getElementById('userAddress').value = userData.address || '';

  document.getElementById('userModal').classList.add('active');
}

function closeUserModal() {
  document.getElementById('userModal').classList.remove('active');
}

async function saveUser() {
  const userId = document.getElementById('userEditId').value;
  const fullName = document.getElementById('userFullName').value.trim();
  const phone = document.getElementById('userPhone').value.trim();
  const address = document.getElementById('userAddress').value.trim();

  if (!fullName) {
    showToast('Please enter full name', 'error');
    return;
  }

  try {
    const { error } = await supabaseClient
      .from('users')
      .update({
        display_name: fullName,
        phone: phone,
        address: address
      })
      .eq('id', userId);

    if (error) throw error;

    showToast('User updated successfully!', 'success');
    addNotification('User Updated', `${fullName} has been updated`, 'success');
    closeUserModal();
    loadUsers();
  } catch (error) {
    console.error('Error updating user:', error);
    showToast('Failed to update user: ' + error.message, 'error');
  }
}

function filterUsers() {
  const searchTerm = (document.getElementById('usersSearch').value || '').toLowerCase();
  const verificationFilter = document.getElementById('usersVerificationFilter')?.value || '';

  const filtered = allUsers.filter(u => {
    const email = (u.email || '').toLowerCase();
    const fullName = (u.display_name || '').toLowerCase();
    const phone = (u.phone || '').toLowerCase();
    const address = (u.address || '').toLowerCase();

    const matchesSearch = email.includes(searchTerm) ||
           fullName.includes(searchTerm) ||
           phone.includes(searchTerm) ||
           address.includes(searchTerm);

    return matchesSearch &&
      (!verificationFilter || u.verification_status === verificationFilter);
  });

  renderUsersTable(filtered);
}

// -------- AUTO DATA-LABEL OBSERVER --------
// Whenever a table's tbody changes, re-apply data-labels from thead.
(function observeTableMutations() {
  var pageContent = document.getElementById('pageContent');
  if (!pageContent) return;
  var observer = new MutationObserver(function(mutations) {
    var shouldApply = false;
    for (var i = 0; i < mutations.length; i++) {
      var m = mutations[i];
      if (m.type === 'childList' && m.target.closest) {
        // Only care about mutations inside .data-table or when rows are added
        if (m.target.closest('.data-table') || m.addedNodes.length > 0) {
          shouldApply = true;
          break;
        }
      }
    }
    if (shouldApply) {
      // Small delay to let DOM settle
      clearTimeout(window._dataLabelTimer);
      window._dataLabelTimer = setTimeout(applyAllTableDataLabels, 50);
    }
  });
  observer.observe(pageContent, { childList: true, subtree: true });
  // Initial pass
  setTimeout(applyAllTableDataLabels, 300);
})();

// ============================================================
// PLACE REVIEWS
// ============================================================
// Reviews are now displayed inline in the Tourist Guide table
// Click the "View" button next to reviews to see all reviews for that place

/**
 * Loads reviews for a specific place and displays them in the reviews modal.
 */
async function loadPlaceReviews(placeId) {
  if (!supabaseClient || !placeId) {
    console.warn('Cannot load place reviews: missing supabase client or place ID');
    return;
  }

  const reviewsList = document.getElementById('reviewsList');
  if (!reviewsList) return;
  reviewsList.innerHTML = '<p style="text-align: center; color: #999;">Loading reviews...</p>';

  try {
    const { data: place } = await supabaseClient
      .from('places')
      .select('name, place_reviews')
      .eq('id', placeId)
      .single();

    const placeName = place ? (place.name || 'Unknown Place') : 'Unknown Place';
    const titleEl = document.getElementById('placeReviewsModalTitle');
    if (titleEl) {
      titleEl.textContent = 'Reviews - ' + escapeHtml(placeName);
    }

    const reviews = place ? (place.place_reviews || []) : [];

    if (!reviews || reviews.length === 0) {
      reviewsList.innerHTML = '<p style="text-align: center; color: #999; padding: 40px 0;">No reviews yet for this place.</p>';
      return;
    }

    reviewsList.innerHTML = reviews.map(function(review) {
      var stars = '';
      for (var i = 0; i < 5; i++) {
        stars += i < (review.rating || 0) ? '\u2605' : '\u2606';
      }
      var dateStr = review.created_at
        ? new Date(review.created_at).toLocaleDateString('en-US', { year: 'numeric', month: 'short', day: 'numeric' })
        : '';
      var reviewerName = review.user_name || review.name || 'Anonymous';
      var commentHtml = review.comment
        ? '<p style="font-size: 13px; color: #4b5563; margin: 8px 0 0 0; line-height: 1.5;">' + escapeHtml(review.comment) + '</p>'
        : '';
      var dateBlock = dateStr ? '<span style="font-size: 12px; color: #9ca3af;">' + dateStr + '</span>' : '';

      return '<div class="review-card" style="background: #ffffff; border: 1px solid #e5e7eb; border-radius: 8px; padding: 16px; margin-bottom: 10px;">' +
        '<div style="display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 8px;">' +
        '<div><strong style="font-size: 14px; color: #111827;">' + escapeHtml(reviewerName) + '</strong>' +
        '<span style="color: #f59e0b; font-size: 14px; margin-left: 8px;">' + stars + '</span></div>' +
        dateBlock + '</div>' + commentHtml + '</div>';
    }).join('');
  } catch (error) {
    console.error('Error loading place reviews:', error);
    reviewsList.innerHTML = '<p style="text-align: center; color: #ef4444;">Error loading reviews.</p>';
  }
}

/**
 * Validates a file upload against allowed types and max size.
 */
function validateFileUpload(file, allowedTypes, maxSizeBytes) {
  if (!file) {
    return { valid: false, error: 'No file selected' };
  }

  if (allowedTypes && allowedTypes.length > 0) {
    var isAllowed = allowedTypes.some(function(type) {
      if (type.endsWith('/*')) {
        var baseType = type.replace('/*', '');
        return file.type.startsWith(baseType + '/');
      }
      return file.type === type;
    });
    if (!isAllowed) {
      return { valid: false, error: 'File type not allowed. Accepted types: ' + allowedTypes.join(', ') };
    }
  }

  if (maxSizeBytes && file.size > maxSizeBytes) {
    var maxSizeMB = (maxSizeBytes / (1024 * 1024)).toFixed(1);
    var fileSizeMB = (file.size / (1024 * 1024)).toFixed(1);
    return { valid: false, error: 'File too large. ' + fileSizeMB + 'MB exceeds the maximum size of ' + maxSizeMB + 'MB' };
  }

  return { valid: true };
}


function sanitizeText(name) {
  if (!name) return '';
  return name
    .replace(/[^a-zA-Z0-9._-]/g, '_')
    .replace(/_+/g, '_')
    .replace(/^_|_$/g, '')
    .toLowerCase();
}
