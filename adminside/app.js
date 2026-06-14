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

function initSupabase() {
  if (typeof window.supabase !== 'undefined' && typeof window.supabase.createClient === 'function') {
    supabaseClient = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
    console.log('Supabase client initialized');
    checkAuthentication();
  } else {
    console.warn('Supabase JS library not loaded');
  }
}

async function checkAuthentication() {
  if (!supabaseClient) return;

  try {
    const { data, error } = await supabaseClient.auth.getSession();
    if (!data?.session) {
      window.location.href = './login.html';
    } else {
      updateUserProfile(data.session.user);
    }
  } catch (error) {
    console.error('Auth check error:', error);
    window.location.href = './login.html';
  }
}

function updateUserProfile(user) {
  const userNameElement = document.querySelector('.user-name-sidebar');
  if (userNameElement && user?.email) {
    const name = user.user_metadata?.full_name || user.email.split('@')[0];
    userNameElement.textContent = name;
  }

  // Update sidebar role
  const userRoleElement = document.querySelector('.user-role-sidebar');
  if (userRoleElement && user?.user_metadata?.role) {
    userRoleElement.textContent = user.user_metadata.role;
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

  if (headerUserRole && user?.user_metadata?.role) {
    headerUserRole.textContent = user.user_metadata.role;
  } else if (headerUserRole) {
    headerUserRole.textContent = 'Administrator';
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
}

async function handleLogout() {
  if (!supabaseClient) return;

  try {
    await supabaseClient.auth.signOut();
    localStorage.removeItem('rememberEmail');
    window.location.href = './login.html';
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
    document.getElementById('profileRole').value = user.user_metadata?.role || 'Administrator';
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
        role: session.user.user_metadata?.role || 'Administrator'
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

    // Update password
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
  users: { current: 1, total: 0 }
};

// Notifications array
let notifications = [];

// ============================================================
// SETTINGS
// ============================================================

// ---------- INIT ----------
document.addEventListener('DOMContentLoaded', () => {
  initDarkMode();
  initSupabase();
  setupNavigation();
  setupMobileMenu();
  setupSidebarCollapse();
  setupSearchListeners();
  setupNotifications();
  setupNewsImagePreview();
  setupNewsSchedule();
  setupLogoutButton();
  setupRealtimeListeners();

  // Restore the last visited page
  const lastPage = localStorage.getItem('lastVisitedPage') || 'dashboard';
  navigateTo(lastPage);
});

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
  currentPage = page;

  // Save current page to localStorage for persistence on refresh
  localStorage.setItem('lastVisitedPage', page);

  document.querySelectorAll('.nav-item').forEach(item => {
    item.classList.toggle('active', item.dataset.page === page);
  });

  document.querySelectorAll('.page').forEach(p => p.classList.remove('active'));
  const targetPage = document.getElementById(page + 'Page');
  if (targetPage) {
    targetPage.classList.add('active');
  }

  if (page === 'dashboard') {
    loadDashboardStats();
    loadDashboardReport();
    loadDashboardService();
  } else if (page === 'barangay') {
    loadBarangayTable();
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
  } else if (page === 'hotline') {
    loadHotline();
  } else if (page === 'users') {
    loadUsers();
  }

  document.getElementById('sidebar').classList.remove('open');
}

function setupMobileMenu() {
  const menuToggle = document.getElementById('menuToggle');
  const sidebar = document.getElementById('sidebar');

  menuToggle.addEventListener('click', () => {
    sidebar.classList.toggle('open');
  });

  document.addEventListener('click', (e) => {
    if (window.innerWidth <= 768) {
      const isInsideSidebar = sidebar.contains(e.target);
      const isMenuToggle = menuToggle.contains(e.target);
      if (!isInsideSidebar && !isMenuToggle && sidebar.classList.contains('open')) {
        sidebar.classList.remove('open');
      }
    }
  });
}

function setupSidebarCollapse() {
  const collapseBtn = document.getElementById('sidebarCollapseBtn');
  const brandLogo = document.querySelector('.brand-logo');
  const sidebar = document.getElementById('sidebar');
  const body = document.body;

  // Load collapsed state from localStorage
  const isCollapsed = localStorage.getItem('sidebarCollapsed') === 'true';
  if (isCollapsed) {
    sidebar.classList.add('collapsed');
    body.classList.add('sidebar-collapsed');
  }

  const toggleSidebar = () => {
    sidebar.classList.toggle('collapsed');
    body.classList.toggle('sidebar-collapsed');
    const collapsed = sidebar.classList.contains('collapsed');
    localStorage.setItem('sidebarCollapsed', collapsed);
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

    const { count: reportsCount } = await supabaseClient
      .from('reports')
      .select('*', { count: 'exact', head: true });
    document.getElementById('totalReports').textContent = reportsCount || 0;

    // Fetch real user count from Firebase backend API
    try {
      const response = await fetch('/api/user-count');
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
    const { count: pendingReports } = await supabaseClient
      .from('reports')
      .select('*', { count: 'exact', head: true })
      .eq('status', 'pending');
    document.getElementById('pendingReports').textContent = pendingReports || 0;

    const serviceTables = [
      'birth_certificate_appointments',
      'cenodeath_appointments',
      'cenomar_appointments',
      'death_certificate_appointments',
      'facility_borrow_requests',
      'marriage_certificate_appointments'
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
    const { data } = await supabaseClient
      .from('reports')
      .select('status');

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
      'facility_borrow_requests',
      'marriage_certificate_appointments'
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
    const { data } = await supabaseClient
      .from('reports')
      .select('category');

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
      { name: 'facility_borrow_requests', type: 'Facility Borrow' },
      { name: 'marriage_certificate_appointments', type: 'Marriage Certificate' }
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

function escapeHtml(text) {
  const div = document.createElement('div');
  div.textContent = text;
  return div.innerHTML;
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
    const months = 6;
    const now = new Date();

    // Initialize data structure for last 6 months
    const monthLabels = [];
    const monthData = {};

    for (let i = months - 1; i >= 0; i--) {
      const date = new Date(now.getFullYear(), now.getMonth() - i, 1);
      const monthKey = date.toLocaleString('default', { month: 'short' });
      monthLabels.push(monthKey);
      monthData[monthKey] = {
        reports: 0,
        news: 0,
        requests: 0,
        reviews: 0
      };
    }

    // Fetch reports
    try {
      const { data: reportsData } = await supabaseClient
        .from('reports')
        .select('created_at');

      (reportsData || []).forEach(r => {
        const date = new Date(r.created_at);
        const monthKey = date.toLocaleString('default', { month: 'short' });
        if (monthData[monthKey]) {
          monthData[monthKey].reports++;
        }
      });
    } catch (e) {
      console.warn('Could not fetch reports:', e);
    }

    // Fetch news
    try {
      const { data: newsData } = await supabaseClient
        .from('news')
        .select('created_at');

      (newsData || []).forEach(n => {
        const date = new Date(n.created_at);
        const monthKey = date.toLocaleString('default', { month: 'short' });
        if (monthData[monthKey]) {
          monthData[monthKey].news++;
        }
      });
    } catch (e) {
      console.warn('Could not fetch news:', e);
    }

    // Fetch service requests from all service tables
    const serviceTables = [
      'birth_certificate_appointments',
      'cenodeath_appointments',
      'cenomar_appointments',
      'death_certificate_appointments',
      'facility_borrow_requests',
      'marriage_certificate_appointments'
    ];

    for (const table of serviceTables) {
      try {
        const { data: serviceData } = await supabaseClient
          .from(table)
          .select('created_at');

        (serviceData || []).forEach(s => {
          const date = new Date(s.created_at);
          const monthKey = date.toLocaleString('default', { month: 'short' });
          if (monthData[monthKey]) {
            monthData[monthKey].requests++;
          }
        });
      } catch (e) {
        // Table might not exist
      }
    }

    // Fetch place reviews
    try {
      const { data: placesData } = await supabaseClient
        .from('places')
        .select('created_at');

      (placesData || []).forEach(p => {
        const date = new Date(p.created_at);
        const monthKey = date.toLocaleString('default', { month: 'short' });
        if (monthData[monthKey]) {
          monthData[monthKey].reviews++;
        }
      });
    } catch (e) {
      console.warn('Could not fetch places:', e);
    }

    // Prepare data for chart
    const reportsCounts = monthLabels.map(m => monthData[m].reports);
    const newsCounts = monthLabels.map(m => monthData[m].news);
    const requestsCounts = monthLabels.map(m => monthData[m].requests);
    const reviewsCounts = monthLabels.map(m => monthData[m].reviews);

    console.log('Chart data:', { monthLabels, reportsCounts, newsCounts, requestsCounts, reviewsCounts });

    // Wait for Chart.js to be available
    if (typeof Chart === 'undefined') {
      console.error('Chart.js is not loaded');
      return;
    }

    const ctx = document.getElementById('performanceTrendChart');
    if (!ctx) {
      console.error('Canvas element not found');
      return;
    }

    // Destroy existing chart if it exists
    if (window.performanceTrendChart instanceof Chart) {
      window.performanceTrendChart.destroy();
    }

    // Create chart
    window.performanceTrendChart = new Chart(ctx, {
      type: 'line',
      data: {
        labels: monthLabels,
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
            pointRadius: 5,
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
            pointRadius: 5,
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
            pointRadius: 5,
            pointHoverRadius: 7
          },
          {
            label: 'Users',
            data: newsCounts,
            borderColor: '#2196F3',
            backgroundColor: 'rgba(33, 150, 243, 0.05)',
            borderWidth: 2.5,
            fill: true,
            tension: 0.4,
            pointBackgroundColor: '#2196F3',
            pointBorderColor: '#fff',
            pointBorderWidth: 2,
            pointRadius: 5,
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
              font: {
                size: 12,
                weight: '500'
              },
              padding: 15,
              usePointStyle: true,
              color: '#6b7280'
            }
          }
        },
        scales: {
          y: {
            beginAtZero: true,
            grid: {
              drawBorder: false,
              color: 'rgba(0, 0, 0, 0.05)'
            },
            ticks: {
              font: {
                size: 12
              },
              color: '#6b7280'
            }
          },
          x: {
            grid: {
              display: false,
              drawBorder: false
            },
            ticks: {
              font: {
                size: 12
              },
              color: '#6b7280'
            }
          }
        },
        interaction: {
          intersect: false,
          mode: 'index'
        }
      }
    });

    console.log('Chart created successfully');
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
    const { data, error } = await supabaseClient
      .from('reports')
      .select('*')
      .order('created_at', { ascending: false })
      .limit(5);

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
          reporter_name: userMap[r.user_id] || r.user_id.substring(0, 12) || 'Anonymous'
        }));
      }
    }

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
      statusBadge.textContent = (report.status || 'pending').charAt(0).toUpperCase() + (report.status || 'pending').slice(1);
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
      { name: 'facility_borrow_requests', label: 'Facility Borrow' },
      { name: 'marriage_certificate_appointments', label: 'Marriage Certificate' }
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
        display_name: item.user_id ? userDisplayNames[item.user_id] : null
      }))
      .sort((a, b) => new Date(b.created_at) - new Date(a.created_at))
      .slice(0, 5);

    const colSpan = tbody.closest('table').querySelectorAll('th').length;
    if (combinedData.length === 0) {
      tbody.innerHTML = `<tr><td colspan="${colSpan}" class="empty-state">No service requests found</td></tr>`;
      return;
    }

    tbody.innerHTML = '';
    combinedData.forEach(service => {
      const tr = document.createElement('tr');

      const tdRequestedBy = document.createElement('td');
      tdRequestedBy.textContent = service.display_name || service.requested_by || 'N/A';

      const tdType = document.createElement('td');
      tdType.textContent = service._label || 'Service';

      const tdStatus = document.createElement('td');
      const statusBadge = document.createElement('span');
      statusBadge.className = `status-badge ${getStatusClass(service.status)}`;
      statusBadge.textContent = (service.status || 'pending').charAt(0).toUpperCase() + (service.status || 'pending').slice(1);
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
  const barangays = barangayData !== null ? barangayData : await fetchBarangays();

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

  // Clear officials
  document.getElementById('punongBarangay').value = '';
  document.getElementById('skChairman').value = '';
  document.getElementById('barangaySecretary').value = '';
  document.getElementById('barangayTreasurer').value = '';
  for (let i = 1; i <= 7; i++) {
    document.getElementById(`kagawad${i}`).value = '';
  }

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

async function saveBarangay() {
  const editId = document.getElementById('barangayEditId').value;
  const name = document.getElementById('barangayName').value.trim();
  const description = document.getElementById('barangayDescription').value.trim();
  const geographicData = document.getElementById('barangayLocation').value.trim();
  const latitude = document.getElementById('barangayLatitude').value.trim();
  const longitude = document.getElementById('barangayLongitude').value.trim();
  const logoBase64 = document.getElementById('barangayLogoBase64').value;
  const coverImageBase64 = document.getElementById('barangayCoverImageBase64').value;

  // Collect officials
  const officials = collectOfficials();

  // Validate required fields
  if (!name || !description || !geographicData || !latitude || !longitude) {
    showToast('Please fill all required fields (basic info and coordinates)', 'error');
    return;
  }

  // Validate officials
  const requiredOfficials = [
    'punong_barangay', 'sk_chairman', 'barangay_secretary', 'barangay_treasurer'
  ];
  for (const official of requiredOfficials) {
    if (!officials[official] || officials[official].trim() === '') {
      showToast(`Please fill in all required officials`, 'error');
      return;
    }
  }

  // Validate kagawad
  if (!officials.kagawad || officials.kagawad.length < 7) {
    showToast('Please fill in all 7 Kagawad names', 'error');
    return;
  }
  for (const kagawad of officials.kagawad) {
    if (!kagawad || kagawad.trim() === '') {
      showToast('Please fill in all 7 Kagawad names', 'error');
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

    const payload = {
      name,
      description,
      geographic_data: geographicData,
      latitude,
      longitude,
      officials: JSON.stringify(officials)
    };

    if (logoBase64) {
      payload.logo_url = logoBase64;
    }

    if (coverImageBase64) {
      payload.barangay_img = coverImageBase64;
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
    showToast('Failed to save barangay: ' + error.message, 'error');
  } finally {
    saveBtn.innerHTML = '<i class="fa-solid fa-floppy-disk"></i> Save';
    saveBtn.disabled = false;
  }
}

// ---------- Helper Functions for Officials ----------
function collectOfficials() {
  const kagawad = [];
  for (let i = 1; i <= 7; i++) {
    const kagawadValue = document.getElementById(`kagawad${i}`).value.trim();
    kagawad.push(kagawadValue);
  }

  return {
    punong_barangay: document.getElementById('punongBarangay').value.trim(),
    sk_chairman: document.getElementById('skChairman').value.trim(),
    barangay_secretary: document.getElementById('barangaySecretary').value.trim(),
    barangay_treasurer: document.getElementById('barangayTreasurer').value.trim(),
    kagawad: kagawad
  };
}

function populateOfficials(officialsJson) {
  if (!officialsJson) {
    document.getElementById('punongBarangay').value = '';
    document.getElementById('skChairman').value = '';
    document.getElementById('barangaySecretary').value = '';
    document.getElementById('barangayTreasurer').value = '';
    for (let i = 1; i <= 7; i++) {
      document.getElementById(`kagawad${i}`).value = '';
    }
    return;
  }

  try {
    const officials = typeof officialsJson === 'string' ? JSON.parse(officialsJson) : officialsJson;

    document.getElementById('punongBarangay').value = officials.punong_barangay || '';
    document.getElementById('skChairman').value = officials.sk_chairman || '';
    document.getElementById('barangaySecretary').value = officials.barangay_secretary || '';
    document.getElementById('barangayTreasurer').value = officials.barangay_treasurer || '';

    if (officials.kagawad && Array.isArray(officials.kagawad)) {
      for (let i = 1; i <= 7; i++) {
        document.getElementById(`kagawad${i}`).value = officials.kagawad[i - 1] || '';
      }
    } else {
      for (let i = 1; i <= 7; i++) {
        document.getElementById(`kagawad${i}`).value = '';
      }
    }
  } catch (error) {
    console.error('Error parsing officials JSON:', error);
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
    } else if (deleteType === 'report') {
      if (!supabaseClient) {
        showToast('Database connection unavailable', 'error');
        deleteBtn.innerHTML = '<i class="fa-solid fa-trash"></i> Delete';
        deleteBtn.disabled = false;
        return;
      }
      const { error } = await supabaseClient.from('reports').delete().eq('id', deleteTarget);
      if (error) throw error;
      showToast('Report deleted successfully!', 'success');
      addNotification('Report Deleted', 'A report has been removed', 'warning');
      loadReports();
    } else if (deleteType === 'transparency') {
      if (!supabaseClient) {
        showToast('Database connection unavailable', 'error');
        deleteBtn.innerHTML = '<i class="fa-solid fa-trash"></i> Delete';
        deleteBtn.disabled = false;
        return;
      }

      // Find the record to get its type
      const record = allTransparency.find(t => t.id === deleteTarget);
      if (record) {
        const tableName = `transparency_${record.type}`;
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
    } else if (deleteType === 'service') {
      if (!supabaseClient) {
        showToast('Database connection unavailable', 'error');
        deleteBtn.innerHTML = '<i class="fa-solid fa-trash"></i> Delete';
        deleteBtn.disabled = false;
        return;
      }

      // Find which table this record belongs to
      const recordToDelete = allServices.find(s => s.id === deleteTarget);
      if (recordToDelete && recordToDelete.table_name) {
        const { error } = await supabaseClient
          .from(recordToDelete.table_name)
          .delete()
          .eq('id', deleteTarget);

        if (error) throw error;
        showToast('Service deleted successfully!', 'success');
        addNotification('Service Deleted', 'A service request has been removed', 'warning');
        console.log(`Deleted from table: ${recordToDelete.table_name}`);
        loadServices();
      } else {
        throw new Error('Could not determine which table contains this record');
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
    } else if (deleteType === 'user') {
      if (!supabaseClient) {
        showToast('Database connection unavailable', 'error');
        deleteBtn.innerHTML = '<i class="fa-solid fa-trash"></i> Delete';
        deleteBtn.disabled = false;
        return;
      }
      const { error } = await supabaseClient.from('users').delete().eq('id', deleteTarget);
      if (error) throw error;
      showToast('User deleted successfully!', 'success');
      addNotification('User Deleted', 'A user has been removed', 'warning');
      loadUsers();
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
    e.target.classList.remove('active');
    deleteTarget = null;
    deleteType = null;
  }
});

// Close modals on Escape key
document.addEventListener('keydown', (e) => {
  if (e.key === 'Escape') {
    document.querySelectorAll('.modal-overlay.active').forEach(m => m.classList.remove('active'));
    deleteTarget = null;
    deleteType = null;
  }
});

// ============================================================
// NEWS CRUD
// ============================================================
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
  document.getElementById('newsImageUrl').value = '';
  document.getElementById('newsImagePreview').innerHTML = '<i class="fa-solid fa-image"></i><span>No image selected</span>';
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
      document.getElementById('newsImageUrl').value = data.image_url || '';
      document.getElementById('newsImage').value = '';

      if (data.image_url) {
        const previewDiv = document.getElementById('newsImagePreview');
        previewDiv.innerHTML = `<img src="${data.image_url}" alt="News image" style="max-width: 100%; max-height: 200px; border-radius: 8px;" />`;
      } else {
        document.getElementById('newsImagePreview').innerHTML = '<i class="fa-solid fa-image"></i><span>No image selected</span>';
      }

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

function removeNewsImage() {
  document.getElementById('newsImage').value = '';
  document.getElementById('newsImageUrl').value = '';
  document.getElementById('newsImagePreview').innerHTML = '<i class="fa-solid fa-image"></i><span>No image selected</span>';
}

function setupNewsImagePreview() {
  const fileInput = document.getElementById('newsImage');
  if (!fileInput) return;

  fileInput.addEventListener('change', function(e) {
    const file = e.target.files[0];
    if (file) {
      const reader = new FileReader();
      reader.onload = function(event) {
        const previewDiv = document.getElementById('newsImagePreview');
        previewDiv.innerHTML = `
          <div class="preview-image-wrapper">
            <img src="${event.target.result}" alt="Preview" style="max-width: 100%; max-height: 200px; border-radius: 8px;" />
            <button type="button" class="remove-image-btn" title="Remove image">
              <i class="fa-solid fa-xmark"></i>
            </button>
          </div>
        `;
        previewDiv.querySelector('.remove-image-btn').addEventListener('click', (e) => {
          e.preventDefault();
          fileInput.value = '';
          previewDiv.innerHTML = '';
        });
      };
      reader.readAsDataURL(file);
    }
  });
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
  const fileInput = document.getElementById('newsImage');
  const existingImageUrl = document.getElementById('newsImageUrl').value;

  if (!title || !content) {
    showToast('Please fill all required fields', 'error');
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

    let imageUrl = existingImageUrl;

    // Upload new image if selected
    if (fileInput.files.length > 0) {
      const file = fileInput.files[0];

      // Validate file upload
      const validation = validateFileUpload(file, ['image/jpeg', 'image/png', 'image/webp', 'image/gif'], 5 * 1024 * 1024);
      if (!validation.valid) {
        showToast('File upload error: ' + validation.errors.join(', '), 'error');
        return;
      }

      const fileName = `news_${Date.now()}_${sanitizeText(file.name)}`;
      const { data, error: uploadError } = await supabaseClient.storage
        .from('NEWS')
        .upload(fileName, file);

      if (uploadError) throw uploadError;

      const { data: urlData } = supabaseClient.storage
        .from('NEWS')
        .getPublicUrl(data.path);

      imageUrl = urlData.publicUrl;
    }

    const payload = { title, description: content, image_url: imageUrl };

    // Add category if selected
    const category = document.getElementById('newsCategory').value;
    if (category && category.trim() !== '') {
      payload.category = category;
    } else {
      payload.category = 'Announcement'; // Default category
    }

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
    const { data, error } = await supabaseClient
      .from('reports')
      .select('id, user_id, message, image_urls, status, rejection_reason, resolution_notes, accomplishment_message, accomplishment_files, created_at, updated_at')
      .order('created_at', { ascending: false });

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
          reporter_name: userMap[r.user_id] || r.user_id.substring(0, 12) || 'Anonymous',
          reporter_email: emailMap[r.user_id] || ''
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

    const tdStatus = document.createElement('td');
    const statusBadge = document.createElement('span');
    statusBadge.className = `status-badge ${getStatusClass(r.status)}`;
    statusBadge.textContent = (r.status || 'pending').charAt(0).toUpperCase() + (r.status || 'pending').slice(1);
    tdStatus.appendChild(statusBadge);

    const tdAttachments = document.createElement('td');
    const imageUrls = r.image_urls || [];
    tdAttachments.textContent = `${imageUrls.length} image${imageUrls.length !== 1 ? 's' : ''}`;
    tdAttachments.style.fontSize = '13px';

    const tdDate = document.createElement('td');
    tdDate.textContent = formatDate(r.created_at);
    tdDate.style.fontSize = '13px';

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

    const deleteBtn = document.createElement('button');
    deleteBtn.className = 'btn btn-sm btn-delete btn-icon';
    deleteBtn.title = 'Delete';
    deleteBtn.innerHTML = '<i class="fa-solid fa-trash"></i>';
    deleteBtn.addEventListener('click', () => openDeleteReport(r.id, r.reporter_name || 'Report'));

    actionsDiv.appendChild(viewBtn);
    actionsDiv.appendChild(editBtn);
    actionsDiv.appendChild(deleteBtn);
    tdActions.appendChild(actionsDiv);

    tr.appendChild(tdReporter);
    tr.appendChild(tdMessage);
    tr.appendChild(tdStatus);
    tr.appendChild(tdAttachments);
    tr.appendChild(tdDate);
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
      const reportData = allReports.find(r => r.id === id);
      const reporterName = reportData?.reporter_name || data.reporter_name || 'Anonymous';
      const reporterEmail = reportData?.reporter_email || data.reporter_email || '';

      document.getElementById('reportViewId').value = id;
      document.getElementById('reportViewReporterName').value = reporterName;
      document.getElementById('reportViewReporterEmail').value = reporterEmail;
      document.getElementById('reportViewMessage').value = data.message || '';
      document.getElementById('reportViewSubmittedDate').value = formatDate(data.created_at);

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
        document.getElementById('reportViewAccomplishmentMessage').value = data.accomplishment_message || '';

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

      document.getElementById('reportModal').classList.add('active');
    }
  } catch (error) {
    console.error('Error loading report:', error);
    showToast('Failed to load report details', 'error');
  }
}

function closeReportModal() {
  document.getElementById('reportModal').classList.remove('active');
}

async function openEditReportModal(id) {
  document.getElementById('reportEditId').value = id;
  document.getElementById('reportEditReason').value = '';
  document.getElementById('accomplishmentMessage').value = '';
  document.getElementById('accomplishmentFiles').value = '';
  document.getElementById('accomplishmentFilesList').innerHTML = '';
  updateAccomplishmentFilesList();

  try {
    const record = allReports.find(r => r.id === id);

    if (record) {
      document.getElementById('reportEditStatus').value = record.status || 'pending';

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
  const accomplishmentSection = document.getElementById('accomplishmentSection');

  if (status === 'rejected') {
    reasonGroup.style.display = 'block';
    reasonLabel.textContent = 'Rejection Reason *';
    accomplishmentSection.style.display = 'none';
  } else if (status === 'resolved') {
    reasonGroup.style.display = 'none';
    accomplishmentSection.style.display = 'block';
  } else {
    reasonGroup.style.display = 'none';
    accomplishmentSection.style.display = 'none';
  }

  if (reasonGroup.style.display === 'none') {
    document.getElementById('reportEditReason').value = '';
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
  const accomplishmentMessage = document.getElementById('accomplishmentMessage')?.value || '';
  const accomplishmentFiles = document.getElementById('accomplishmentFiles')?.files || [];

  if (!reportId) {
    showToast('Report ID not found', 'error');
    return;
  }

  if (status === 'rejected' && !reason.trim()) {
    showToast('Please provide a rejection reason', 'error');
    return;
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
    if (status === 'rejected') {
      updateData.rejection_reason = reason.trim();
      updateData.resolution_notes = null;
      updateData.accomplishment_message = null;
      updateData.accomplishment_files = null;
    } else if (status === 'resolved') {
      updateData.rejection_reason = null;
      updateData.resolution_notes = null;
      updateData.accomplishment_message = accomplishmentMessage.trim();
      updateData.accomplishment_files = accomplishmentFileUrls;
    } else {
      updateData.rejection_reason = null;
      updateData.resolution_notes = null;
      updateData.accomplishment_message = null;
      updateData.accomplishment_files = null;
    }

    const { error } = await supabaseClient
      .from('reports')
      .update(updateData)
      .eq('id', reportId);

    if (error) throw error;
    showToast('Report status updated successfully!', 'success');
    addNotification('Report Status Changed', `Report status changed to ${status}`, 'info');
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
      const file = files[i];
      const timestamp = Date.now();
      const sanitizedName = file.name.replace(/[^a-zA-Z0-9._-]/g, '_');
      const path = `accomplishment/${reportId}/${timestamp}-${i}-${sanitizedName}`;

      const { data, error } = await supabaseClient.storage
        .from('report-images')
        .upload(path, file, {
          cacheControl: '3600',
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
        name: file.name,
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

function openDeleteReport(id, title) {
  deleteTarget = id;
  deleteType = 'report';
  document.getElementById('deleteMessage').textContent = `Are you sure you want to delete "${title}"? This action cannot be undone.`;
  document.getElementById('deleteModal').classList.add('active');
}

// ============================================================
// TRANSPARENCY
// ============================================================
let allTransparency = [];

async function loadTransparency() {
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
          type: item.type || 'general'
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
          let type = tableName.replace('transparency_', '').replace('_projects', '');
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

    allTransparency = allRecords;
    renderTransparencyTable(allTransparency);
  } catch (error) {
    console.error('Error loading transparency records:', error);
    showToast('Failed to load transparency records from database', 'error');
  }
}

function renderTransparencyTable(transparencyData) {
  const tbody = document.getElementById('transparencyTableBody');
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

function openTransparencyModal() {
  const typeFilter = document.getElementById('transparencyTypeFilter');
  const selectedType = typeFilter ? typeFilter.value : '';

  const typeLabels = {
    'annual_budget': 'Annual Budget',
    'bids_projects': 'Bids',
    'executive_orders': 'Executive Orders',
    'financial_reports': 'Financial Reports',
    'legislative_ordinances': 'Legislative Ordinances',
    'programs_projects': 'Programs'
  };

  const typeLabel = typeLabels[selectedType] || 'Transparency';
  document.getElementById('transparencyModalTitle').textContent = `Add ${typeLabel} Record`;
  document.getElementById('transparencyCurrentType').value = selectedType;
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
  const editId = document.getElementById('transparencyEditId').value;
  const currentType = document.getElementById('transparencyCurrentType').value;
  const title = document.getElementById('transparencyTitle').value.trim();
  const description = document.getElementById('transparencyDescription').value.trim();
  const displayOrder = document.getElementById('transparencyDisplayOrder').value;
  const isPublished = document.getElementById('transparencyIsPublished').checked;
  const pdfFile = document.getElementById('transparencyPdfUrl').files[0];

  if (!title || !description) {
    showToast('Please fill all required fields', 'error');
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

  const tableName = tableMap[currentType] || 'transparency_annual_budget';

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
      description,
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
    showToast('Failed to save record: ' + error.message, 'error');
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
      const reviewsContainer = document.createElement('div');
      reviewsContainer.style.cssText = `
        display: contents;
      `;

      reviewsContainer.addEventListener('mouseenter', function() {
        if (this.querySelector('div')) {
          this.querySelector('div').style.boxShadow = '0 4px 12px rgba(251, 191, 36, 0.2)';
          this.querySelector('div').style.transform = 'scale(1.02)';
        }
      });

      reviewsContainer.addEventListener('mouseleave', function() {
        if (this.querySelector('div')) {
          this.querySelector('div').style.boxShadow = 'none';
          this.querySelector('div').style.transform = 'scale(1)';
        }
      });

      reviewsContainer.addEventListener('click', () => {
        openPlaceReviewsModal(t.id, t.name);
      });

      const starsDiv = document.createElement('div');
      starsDiv.style.cssText = `
        display: flex;
        align-items: center;
        gap: 10px;
        background: linear-gradient(135deg, #fffbeb 0%, #fef3c7 100%);
        padding: 10px 14px;
        border-radius: 10px;
        border: 1px solid #fcd34d;
        cursor: pointer;
        transition: all 0.3s ease;
      `;

      const starsContainer = document.createElement('div');
      starsContainer.style.cssText = `
        display: flex;
        gap: 2px;
        font-size: 16px;
      `;

      const fullStars = Math.floor(avgRating);
      const hasHalfStar = avgRating % 1 >= 0.5;
      const emptyStars = 5 - fullStars - (hasHalfStar ? 1 : 0);

      starsContainer.innerHTML =
        '★'.repeat(fullStars) +
        (hasHalfStar ? '⭐' : '') +
        '☆'.repeat(emptyStars);
      starsContainer.style.cssText += `
        color: #fbbf24;
        text-shadow: 0 1px 2px rgba(0, 0, 0, 0.1);
        letter-spacing: 1px;
      `;

      const ratingText = document.createElement('span');
      ratingText.textContent = `${avgRating} (${placeReviews.length})`;
      ratingText.style.cssText = `
        font-weight: 700;
        color: #d97706;
        font-size: 13px;
        white-space: nowrap;
      `;

      starsDiv.appendChild(starsContainer);
      starsDiv.appendChild(ratingText);

      const viewIcon = document.createElement('i');
      viewIcon.className = 'fa-solid fa-arrow-up-right';
      viewIcon.style.cssText = 'color: #2196F3; font-size: 12px;';

      reviewsContainer.appendChild(starsDiv);
      reviewsContainer.appendChild(viewIcon);
      tdReviews.appendChild(reviewsContainer);
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
  document.getElementById('touristImageBase64').value = '';
  document.getElementById('touristImagePreview').innerHTML = '<i class="fa-solid fa-image"></i><span>No image selected</span>';
  document.getElementById('touristSaveBtn').innerHTML = '<i class="fa-solid fa-floppy-disk"></i> Save';
  setupTouristImageUpload();
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

      if (record.image_url) {
        document.getElementById('touristImagePreview').innerHTML = '<i class="fa-solid fa-image"></i><span>' + record.image_url.split('/').pop() + '</span>';
      }

      setupTouristImageUpload();
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
  const imageBase64 = document.getElementById('touristImageBase64').value;

  if (!name || !shortLocation || !category || !description) {
    showToast('Please fill all required fields: Name, Location, Category, Description', 'error');
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

    let imageUrl = null;

    if (imageBase64) {
      const fileName = `tourist_${Date.now()}.jpg`;
      const { data, error } = await supabaseClient.storage
        .from('places-images')
        .upload(`destination/touristguide/${fileName}`, decodeBase64(imageBase64), {
          contentType: 'image/jpeg',
          upsert: false
        });

      if (error) {
        console.error('Image upload error:', error);
      } else if (data) {
        const { data: urlData } = supabaseClient.storage
          .from('places-images')
          .getPublicUrl(`destination/touristguide/${fileName}`);
        imageUrl = urlData.publicUrl;
      }
    }

    const payload = {
      name,
      short_location: shortLocation,
      full_address: fullAddress || null,
      category,
      description,
      phone: contactNumber || null,
      latitude: latNum,
      longitude: lonNum,
      distance_label: distanceLabel || null,
      is_featured: isFeatured,
      is_published: isPublished
    };

    if (imageUrl) {
      payload.image_url = imageUrl;
    }

    const { data, error } = editId
      ? await supabaseClient.from('places').update(payload).eq('id', editId)
      : await supabaseClient.from('places').insert([payload]);

    if (error) {
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
    showToast('Failed to save destination: ' + error.message, 'error');
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
      { name: 'facility_borrow_requests', type: 'Facility Borrow' },
      { name: 'marriage_certificate_appointments', type: 'Marriage Certificate' }
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
            created_at: item.created_at || item.date || item.appointment_date || item.created_date || new Date().toISOString(),
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
      display_name: item.user_id ? userDisplayNames[item.user_id] : null
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
      { name: 'facility_borrow_requests', type: 'Facility Borrow' },
      { name: 'marriage_certificate_appointments', type: 'Marriage Certificate' }
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
            created_at: item.created_at || item.date || item.appointment_date || item.created_date || new Date().toISOString(),
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
      display_name: item.user_id ? userDisplayNames[item.user_id] : null
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
    tdRequestedBy.textContent = s.display_name || s.requested_by || s.requester || 'N/A';
    tdRequestedBy.style.fontSize = '13px';
    tdRequestedBy.style.fontWeight = '500';

    const tdType = document.createElement('td');
    tdType.textContent = s.type || s.service_type || 'N/A';
    tdType.style.fontSize = '13px';
    tdType.style.textTransform = 'capitalize';

    const tdStatus = document.createElement('td');
    const statusBadge = document.createElement('span');
    statusBadge.className = `status-badge ${getStatusClass(s.status)}`;
    statusBadge.textContent = (s.status || 'pending').charAt(0).toUpperCase() + (s.status || 'pending').slice(1);
    tdStatus.appendChild(statusBadge);

    const tdDate = document.createElement('td');
    tdDate.textContent = formatDate(s.created_at || s.date);
    tdDate.style.fontSize = '13px';

    const tdCreated = document.createElement('td');
    tdCreated.textContent = formatDate(s.created_at);
    tdCreated.style.fontSize = '13px';

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

    const deleteBtn = document.createElement('button');
    deleteBtn.className = 'btn btn-sm btn-delete btn-icon';
    deleteBtn.title = 'Delete';
    deleteBtn.innerHTML = '<i class="fa-solid fa-trash"></i>';
    deleteBtn.addEventListener('click', () => openDeleteService(s.id, s.name || 'Service'));

    actionsDiv.appendChild(viewBtn);
    actionsDiv.appendChild(editBtn);
    actionsDiv.appendChild(deleteBtn);
    tdActions.appendChild(actionsDiv);

    tr.appendChild(tdRequestedBy);
    tr.appendChild(tdType);
    tr.appendChild(tdStatus);
    tr.appendChild(tdDate);
    tr.appendChild(tdCreated);
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
  document.getElementById('reasonFieldGroup').style.display = 'none';
  document.getElementById('serviceSaveBtn').innerHTML = '<i class="fa-solid fa-floppy-disk"></i> Save';
  document.getElementById('serviceModal').classList.add('active');
}

async function openEditServiceModal(id) {
  document.getElementById('serviceModalTitle').textContent = 'Update Service Request Status';
  document.getElementById('serviceEditId').value = id;
  document.getElementById('serviceReason').value = '';
  document.getElementById('serviceSaveBtn').innerHTML = '<i class="fa-solid fa-floppy-disk"></i> Update Status';

  try {
    const record = allServices.find(s => s.id === id);

    if (record) {
      document.getElementById('serviceStatus').value = record.status || 'pending';
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

    let requestedByValue = 'N/A';
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

    const fields = [
      { label: 'Service Name', value: record.name || 'N/A' },
      { label: 'Service Type', value: record.type || record.service_type || 'N/A' },
      { label: 'Requested By', value: record.requested_by || requestedByValue || 'N/A' },
      { label: 'Status', value: (record.status || 'N/A').charAt(0).toUpperCase() + (record.status || 'N/A').slice(1) },
      { label: 'Contact Number', value: record.contact_number || record.phone || 'N/A' },
      { label: 'Date Requested', value: formatDate(record.created_at || record.date) },
      { label: 'Description', value: record.description || record.notes || 'N/A', fullWidth: true },
    ];

    const commonFields = ['id', 'name', 'type', 'requested_by', 'status', 'contact_number', 'date', 'created_at', 'description', 'table_name', 'user_id'];
    Object.keys(record).forEach(key => {
      if (!commonFields.includes(key) && record[key] && typeof record[key] === 'string') {
        fields.push({ label: key.replace(/_/g, ' ').charAt(0).toUpperCase() + key.replace(/_/g, ' ').slice(1), value: record[key] });
      }
    });

    fields.forEach(field => {
      const fieldDiv = document.createElement('div');
      if (field.fullWidth) {
        fieldDiv.style.gridColumn = '1 / -1';
      }

      const label = document.createElement('label');
      label.style.cssText = 'display: block; font-size: 12px; font-weight: 600; color: #666; margin-bottom: 4px; text-transform: uppercase;';
      label.textContent = field.label;

      const value = document.createElement('p');
      value.style.cssText = 'margin: 0; color: #333; font-size: 14px; word-break: break-word;';
      value.textContent = field.value;

      fieldDiv.appendChild(label);
      fieldDiv.appendChild(value);
      detailsContent.appendChild(fieldDiv);
    });

    document.getElementById('serviceDetailsModal').classList.add('active');
  } catch (error) {
    console.error('Error loading service details:', error);
    showToast('Failed to load service details', 'error');
  }
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
  const reasonFieldGroup = document.getElementById('reasonFieldGroup');

  // Check if reason is required but empty
  if (reasonFieldGroup.style.display !== 'none' && !reason) {
    showToast('Please provide a reason for this status change', 'error');
    return;
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

      // Add reason to notes/remarks based on status
      if (reason) {
        if (status === 'rejected') {
          updatePayload.rejection_reason = reason;
          updatePayload.remarks = `Rejected: ${reason}`;
        } else if (status === 'completed') {
          updatePayload.approval_reason = reason;
          updatePayload.remarks = `Approved: ${reason}`;
        } else {
          updatePayload.notes = reason;
          updatePayload.remarks = reason;
        }
      }

      const { error } = await supabaseClient
        .from(originalRecord.table_name)
        .update(updatePayload)
        .eq('id', editId);

      if (error) throw error;
      showToast('Service status updated successfully!', 'success');
      addNotification('Service Updated', `Service request status has been updated to ${status}`, 'success');
      closeServiceModal();
      loadServices();
    } catch (error) {
      console.error('Error updating service:', error);
      showToast('Error updating service status', 'error');
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

  if (status === 'rejected') {
    reasonFieldGroup.style.display = 'block';
    reasonLabel.textContent = 'Rejection Reason *';
  } else if (status === 'completed') {
    reasonFieldGroup.style.display = 'block';
    reasonLabel.textContent = 'Approval Notes *';
  } else {
    reasonFieldGroup.style.display = 'none';
  }

  // Clear reason when hiding
  if (reasonFieldGroup.style.display === 'none') {
    document.getElementById('serviceReason').value = '';
  }
}

function openDeleteService(id, name) {
  deleteTarget = id;
  deleteType = 'service';
  document.getElementById('deleteMessage').textContent = `Are you sure you want to delete "${name}"? This action cannot be undone.`;
  document.getElementById('deleteModal').classList.add('active');
}

function getStatusClass(status) {
  const s = (status || '').toLowerCase();
  if (s === 'resolved' || s === 'done' || s === 'completed' || s === 'approved') return 'status-approved';
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

    if (logoBase64) {
      payload.logo_url = logoBase64;
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
    showToast('Failed to save hotline: ' + error.message, 'error');
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
      filterUsers();
    }, 300));
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
  const dateFrom = document.getElementById('reportDateFrom').value;
  const dateTo = document.getElementById('reportDateTo').value;

  const filtered = allReports.filter(r => {
    const matchSearch = !searchTerm ||
      (r.reporter_name && r.reporter_name.toLowerCase().includes(searchTerm)) ||
      (r.message && r.message.toLowerCase().includes(searchTerm));

    const matchStatus = !statusFilter || r.status === statusFilter;

    let matchDate = true;
    if (dateFrom || dateTo) {
      const createdDate = new Date(r.created_at).toISOString().split('T')[0];
      if (dateFrom && createdDate < dateFrom) matchDate = false;
      if (dateTo && createdDate > dateTo) matchDate = false;
    }

    return matchSearch && matchStatus && matchDate;
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

function setupTouristImageUpload() {
  const imageInput = document.getElementById('touristImage');
  const imagePreview = document.getElementById('touristImagePreview');

  if (!imageInput || !imagePreview) return;

  imageInput.addEventListener('change', (e) => {
    const file = e.target.files[0];
    if (!file) return;

    if (!file.type.startsWith('image/')) {
      showToast('Please select a valid image file', 'error');
      imageInput.value = '';
      return;
    }

    const reader = new FileReader();
    reader.onload = (event) => {
      const base64 = event.target.result;
      document.getElementById('touristImageBase64').value = base64;
      imagePreview.innerHTML = `
        <div class="preview-image-wrapper">
          <img src="${base64}" alt="image preview" style="max-width: 100%; max-height: 200px; border-radius: 8px;">
          <button type="button" class="remove-image-btn" title="Remove image">
            <i class="fa-solid fa-xmark"></i>
          </button>
        </div>
      `;
      imagePreview.querySelector('.remove-image-btn').addEventListener('click', (e) => {
        e.preventDefault();
        imageInput.value = '';
        document.getElementById('touristImageBase64').value = '';
        imagePreview.innerHTML = '<i class="fa-solid fa-image"></i><span>No image selected</span>';
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
function decodeBase64(base64String) {
  const base64 = base64String.replace(/^data:image\/[^;]+;base64,/, '');
  const binary = atob(base64);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) {
    bytes[i] = binary.charCodeAt(i);
  }
  return bytes;
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

async function loadUsers() {
  const tbody = document.getElementById('usersTableBody');
  if (!tbody) return;

  if (!supabaseClient) {
    const colSpan = tbody.closest('table').querySelectorAll('th').length;
    tbody.innerHTML = `<tr><td colspan="${colSpan}" class="empty-state">Database connection unavailable</td></tr>`;
    return;
  }

  try {
    const { data, error } = await supabaseClient
      .from('users')
      .select('*')
      .order('created_at', { ascending: false });

    if (error) throw error;
    allUsers = data || [];
    renderUsersTable(allUsers);
  } catch (error) {
    console.error('Error loading users:', error);
    showToast('Failed to load users from database: ' + error.message, 'error');
  }
}

function renderUsersTable(usersData) {
  const tbody = document.getElementById('usersTableBody');
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

    const tdStatus = document.createElement('td');
    const statusBadge = document.createElement('span');
    statusBadge.className = 'status-badge ' + (u.user_metadata?.status === 'suspended' ? 'status-rejected' : 'status-resolved');
    statusBadge.textContent = (u.user_metadata?.status || 'active').charAt(0).toUpperCase() + (u.user_metadata?.status || 'active').slice(1);
    tdStatus.appendChild(statusBadge);

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

    const deleteBtn = document.createElement('button');
    deleteBtn.className = 'btn btn-sm btn-delete btn-icon';
    deleteBtn.title = 'Delete';
    deleteBtn.innerHTML = '<i class="fa-solid fa-trash"></i>';
    deleteBtn.addEventListener('click', () => openDeleteUser(u.id, u.email || 'User'));

    actionsDiv.appendChild(editBtn);
    actionsDiv.appendChild(deleteBtn);
    tdActions.appendChild(actionsDiv);

    tr.appendChild(tdEmail);
    tr.appendChild(tdFullName);
    tr.appendChild(tdPhone);
    tr.appendChild(tdAddress);
    tr.appendChild(tdStatus);
    tr.appendChild(tdCreated);
    tr.appendChild(tdActions);

    tbody.appendChild(tr);
  });

  renderUsersPagination(totalItems);
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
  document.getElementById('userFullName').value = userData.display_name || userData.user_metadata?.full_name || '';
  document.getElementById('userPhone').value = userData.phone || userData.user_metadata?.phone || '';
  document.getElementById('userAddress').value = userData.address || userData.user_metadata?.address || '';
  document.getElementById('userStatus').value = userData.user_metadata?.status || 'active';

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
  const status = document.getElementById('userStatus').value;

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
        address: address,
        user_metadata: {
          phone: phone,
          address: address,
          status: status
        }
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

function openDeleteUser(userId, userEmail) {
  deleteTarget = userId;
  deleteType = 'user';
  document.getElementById('deleteMessage').textContent = `Are you sure you want to delete this user (${userEmail})? This action cannot be undone.`;
  document.getElementById('deleteModal').classList.add('active');
}

async function deleteUser() {
  try {
    const { error } = await supabaseClient
      .from('users')
      .delete()
      .eq('id', deleteTarget);

    if (error) throw error;
    showToast('User deleted successfully!', 'success');
    addNotification('User Deleted', 'A user has been removed', 'warning');
    loadUsers();
  } catch (error) {
    console.error('Error deleting user:', error);
    showToast('Failed to delete user: ' + error.message, 'error');
  }
}

function filterUsers() {
  const searchTerm = (document.getElementById('usersSearch').value || '').toLowerCase();

  const filtered = allUsers.filter(u => {
    const email = (u.email || '').toLowerCase();
    const fullName = (u.display_name || u.user_metadata?.full_name || '').toLowerCase();
    const phone = (u.phone || u.user_metadata?.phone || '').toLowerCase();
    const address = (u.address || u.user_metadata?.address || '').toLowerCase();

    return email.includes(searchTerm) ||
           fullName.includes(searchTerm) ||
           phone.includes(searchTerm) ||
           address.includes(searchTerm);
  });

  renderUsersTable(filtered);
}

// ============================================================
// PLACE REVIEWS
// ============================================================
// Reviews are now displayed inline in the Tourist Guide table
// Click the "View" button next to reviews to see all reviews for that place
