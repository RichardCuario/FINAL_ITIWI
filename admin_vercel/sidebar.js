// Shared Sidebar Component
async function createSidebar() {
  const sidebarHTML = `
  <aside class="sidebar">
    <div class="sidebar-brand">
      <div class="sidebar-brand-mark">I</div>
      <div class="sidebar-brand-copy">
        <h2>ITIWI</h2>
        <p>Municipal admin</p>
      </div>
    </div>

    <nav class="menu menu-primary" aria-label="Primary">
      <a class="menu-item" href="dashboard.html">
        <span class="menu-icon">⌂</span>
        <span class="menu-label">Dashboard</span>
      </a>

      <a class="menu-item" href="index.html">
        <span class="menu-icon">✦</span>
        <span class="menu-label">Emergency Hotline</span>
      </a>

      <a class="menu-item" href="news.html">
        <span class="menu-icon">▤</span>
        <span class="menu-label">News</span>
      </a>

      <a class="menu-item" href="reports.html">
        <span class="menu-icon">▣</span>
        <span class="menu-label">Report</span>
      </a>

      <div class="menu-group online-services-group">
        <button
          class="menu-item menu-group-toggle"
          type="button"
          id="onlineServicesToggle"
          aria-expanded="false"
          aria-controls="onlineServicesSubmenu"
        >
          <span class="menu-icon">◎</span>
          <span class="menu-label">Online Service</span>
          <span class="menu-caret">▾</span>
        </button>

        <div class="menu-submenu" id="onlineServicesSubmenu">
          <a class="menu-item menu-subitem" href="online_services.html">
            <span class="menu-icon">◈</span>
            <span class="menu-label">All Requests</span>
          </a>

          <a class="menu-item menu-subitem" href="online_services.html?category=Birth%20Certificate">
            <span class="menu-icon">◇</span>
            <span class="menu-label">Birth Certificate</span>
          </a>

          <a class="menu-item menu-subitem" href="online_services.html?category=CENODEATH">
            <span class="menu-icon">◉</span>
            <span class="menu-label">CENODEATH</span>
          </a>

          <a class="menu-item menu-subitem" href="online_services.html?category=Death%20Certificate">
            <span class="menu-icon">◌</span>
            <span class="menu-label">Death Certificate</span>
          </a>

          <a class="menu-item menu-subitem" href="online_services.html?category=CENOMAR">
            <span class="menu-icon">◍</span>
            <span class="menu-label">CENOMAR</span>
          </a>

          <a class="menu-item menu-subitem" href="online_services.html?category=Libjo%20Facilities">
            <span class="menu-icon">◎</span>
            <span class="menu-label">Libjo Facilities</span>
          </a>

          <a class="menu-item menu-subitem" href="online_services.html?category=Tiwi%20Gymnasium">
            <span class="menu-icon">◐</span>
            <span class="menu-label">Tiwi Gymnasium</span>
          </a>
        </div>
      </div>

      <a class="menu-item" href="barangay.html">
        <span class="menu-icon">◫</span>
        <span class="menu-label">Barangay</span>
      </a>

      <a class="menu-item" href="tourist_guide.html">
        <span class="menu-icon">◭</span>
        <span class="menu-label">Tourist Guide</span>
      </a>

      <div class="menu-group transparency-group">
        <button
          class="menu-item menu-group-toggle"
          type="button"
          id="transparencyToggle"
          aria-expanded="false"
          aria-controls="transparencySubmenu"
        >
          <span class="menu-icon">◐</span>
          <span class="menu-label">Transparency</span>
          <span class="menu-caret">▾</span>
        </button>

        <div class="menu-submenu" id="transparencySubmenu">
          <a class="menu-item menu-subitem" href="transparency_programs.html">
            <span class="menu-icon">◈</span>
            <span class="menu-label">Programs</span>
          </a>

          <a class="menu-item menu-subitem" href="transparency_bids.html">
            <span class="menu-icon">◇</span>
            <span class="menu-label">Bids</span>
          </a>

          <a class="menu-item menu-subitem" href="transparency_financial_reports.html">
            <span class="menu-icon">◉</span>
            <span class="menu-label">Financial Reports</span>
          </a>

          <a class="menu-item menu-subitem" href="transparency_annual_budget.html">
            <span class="menu-icon">◌</span>
            <span class="menu-label">Annual Budget</span>
          </a>

          <a class="menu-item menu-subitem" href="transparency_legislative_ordinances.html">
            <span class="menu-icon">◍</span>
            <span class="menu-label">Legislative Ordinances</span>
          </a>

          <a class="menu-item menu-subitem" href="transparency_executive_orders.html">
            <span class="menu-icon">◎</span>
            <span class="menu-label">Executive Orders</span>
          </a>
        </div>
      </div>
    </nav>

    <div class="sidebar-footer-group">
      <div class="sidebar-footer-meta">
        <div class="sidebar-section-heading">
          <span>Account</span>
        </div>
        <div id="adminSessionMeta" class="sidebar-session-meta">Signed in</div>
      </div>

      <button id="logoutButton" class="menu-item sidebar-logout" type="button">
        <span class="menu-icon">↪</span>
        <span class="menu-label">Logout</span>
      </button>
    </div>
  </aside>
  `;

  const normalizePage = (value) => {
    const cleanValue = (value || '').split('?')[0].split('#')[0].trim();

    if (!cleanValue) {
      return 'index';
    }

    return cleanValue.replace(/\.html$/i, '');
  };

  const currentPage = normalizePage(window.location.pathname.split('/').pop());
  const currentQuery = new URLSearchParams(window.location.search);
  const currentOnlineServiceCategory = currentQuery.get('category') || '';

  const tempDiv = document.createElement('div');
  tempDiv.innerHTML = sidebarHTML;
  const sidebarElement = tempDiv.firstElementChild;
  document.body.insertBefore(sidebarElement, document.body.firstChild);

  const menuItems = document.querySelectorAll('.sidebar .menu-item[href]');
  const pageGroups = {
    dashboard: 'dashboard',
    index: 'hotline',
    add: 'hotline',
    edit: 'hotline',
    news: 'news',
    add_news: 'news',
    news_new: 'news',
    edit_news: 'news',
    reports: 'reports',
    online_services: 'online-services',
    barangay: 'barangay',
    add_barangay: 'barangay',
    edit_barangay: 'barangay',
    tourist_guide: 'tourist-guide',
    places: 'tourist-guide',
    edit_place: 'tourist-guide',
    place_reviews: 'tourist-guide',
    transparency_programs: 'transparency',
    transparency_bids: 'transparency',
    transparency_financial_reports: 'transparency',
    transparency_annual_budget: 'transparency',
    transparency_legislative_ordinances: 'transparency',
    transparency_executive_orders: 'transparency'
  };

  const currentGroup = pageGroups[currentPage] || currentPage;
  let hasActiveTransparencyChild = false;
  let hasActiveOnlineServicesChild = false;

  menuItems.forEach((item) => {
    const href = item.getAttribute('href');
    const itemUrl = new URL(href, window.location.href);
    const normalizedHref = normalizePage(itemUrl.pathname.split('/').pop());
    const itemGroup = pageGroups[normalizedHref];
    const itemCategory = itemUrl.searchParams.get('category') || '';
    const isOnlineServicesSubitem = item.classList.contains('menu-subitem') && itemGroup === 'online-services';
    const isOnlineServicesSubitemActive = isOnlineServicesSubitem
      && normalizedHref === currentPage
      && (
        (itemCategory && itemCategory === currentOnlineServiceCategory)
        || (!itemCategory && !currentOnlineServiceCategory)
      );
    const isExactPage = isOnlineServicesSubitem
      ? false
      : normalizedHref === currentPage && (!itemCategory || itemCategory === currentOnlineServiceCategory);
    const isGroupedPage = itemGroup === currentGroup && !item.classList.contains('menu-subitem');
    const isActive = isOnlineServicesSubitemActive || isExactPage || isGroupedPage;

    item.classList.toggle('active', isActive);
    item.setAttribute('aria-current', isActive ? 'page' : 'false');

    if (isActive && item.classList.contains('menu-subitem')) {
      if (itemGroup === 'transparency') {
        hasActiveTransparencyChild = true;
      }

      if (itemGroup === 'online-services') {
        hasActiveOnlineServicesChild = true;
      }
    }
  });

  const onlineServicesToggle = document.getElementById('onlineServicesToggle');
  const onlineServicesSubmenu = document.getElementById('onlineServicesSubmenu');

  if (onlineServicesToggle && onlineServicesSubmenu) {
    const setOnlineServicesExpanded = (expanded) => {
      onlineServicesToggle.setAttribute('aria-expanded', expanded ? 'true' : 'false');
      onlineServicesSubmenu.hidden = !expanded;
      onlineServicesToggle.classList.toggle('active', expanded || hasActiveOnlineServicesChild);
      onlineServicesSubmenu.classList.toggle('expanded', expanded);
    };

    setOnlineServicesExpanded(currentGroup === 'online-services');

    onlineServicesToggle.addEventListener('click', () => {
      const isExpanded = onlineServicesToggle.getAttribute('aria-expanded') === 'true';
      setOnlineServicesExpanded(!isExpanded);
    });
  }

  const transparencyToggle = document.getElementById('transparencyToggle');
  const transparencySubmenu = document.getElementById('transparencySubmenu');

  if (transparencyToggle && transparencySubmenu) {
    const setTransparencyExpanded = (expanded) => {
      transparencyToggle.setAttribute('aria-expanded', expanded ? 'true' : 'false');
      transparencySubmenu.hidden = !expanded;
      transparencyToggle.classList.toggle('active', expanded || hasActiveTransparencyChild);
      transparencySubmenu.classList.toggle('expanded', expanded);
    };

    setTransparencyExpanded(hasActiveTransparencyChild);

    transparencyToggle.addEventListener('click', () => {
      const isExpanded = transparencyToggle.getAttribute('aria-expanded') === 'true';
      setTransparencyExpanded(!isExpanded);
    });
  }

  const adminSessionMeta = document.getElementById('adminSessionMeta');
  const logoutButton = document.getElementById('logoutButton');

  if (window.adminAuth) {
    try {
      const email = await window.adminAuth.getAdminUserEmail();
      adminSessionMeta.textContent = email ? `Signed in as ${email}` : 'Signed in';
    } catch (error) {
      adminSessionMeta.textContent = 'Signed in';
    }

    logoutButton.addEventListener('click', async () => {
      logoutButton.disabled = true;

      try {
        await window.adminAuth.signOutAdmin();
      } catch (error) {
        console.error('Logout failed:', error);
      }

      window.location.href = 'login.html';
    });
  }
}

document.addEventListener('DOMContentLoaded', createSidebar);
