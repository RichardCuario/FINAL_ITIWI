// Shared Sidebar Component
async function createSidebar() {
  const sidebarStyles = `
    :root {
      --itiwi-sidebar-width: 272px;
      --itiwi-sidebar-bg: #1e4e96;
      --itiwi-sidebar-bg-alt: #1a4a8f;
      --itiwi-sidebar-text: #ffffff;
      --itiwi-sidebar-text-soft: rgba(255, 255, 255, 0.86);
      --itiwi-sidebar-text-muted: rgba(255, 255, 255, 0.7);
      --itiwi-sidebar-active-text: #1e4e96;
      --itiwi-sidebar-line: rgba(255, 255, 255, 0.14);
      --itiwi-sidebar-shadow: 0 22px 46px rgba(5, 20, 48, 0.18);
    }

    .itiwi-sidebar {
      position: fixed;
      inset: 0 auto 0 0;
      width: var(--itiwi-sidebar-width);
      height: 100vh;
      display: flex;
      flex-direction: column;
      overflow-y: auto;
      overflow-x: hidden;
      padding: 16px 16px 14px;
      background: linear-gradient(180deg, var(--itiwi-sidebar-bg) 0%, var(--itiwi-sidebar-bg-alt) 100%);
      color: var(--itiwi-sidebar-text);
      z-index: 30;
      box-shadow: var(--itiwi-sidebar-shadow);
    }

    .itiwi-sidebar *,
    .itiwi-sidebar *::before,
    .itiwi-sidebar *::after {
      box-sizing: border-box;
    }

    .itiwi-sidebar__brand {
      display: flex;
      flex-direction: column;
      gap: 10px;
      padding: 2px 4px 10px;
    }

    .itiwi-brand {
      display: flex;
      align-items: center;
      gap: 12px;
      min-width: 0;
    }

    .itiwi-brand__logo {
      width: 34px;
      height: 34px;
      display: inline-flex;
      align-items: center;
      justify-content: center;
      flex-shrink: 0;
    }

    .itiwi-brand__logo svg,
    .itiwi-nav__icon svg,
    .itiwi-logout__icon svg,
    .itiwi-avatar__icon svg {
      display: block;
      width: 100%;
      height: 100%;
    }

    .itiwi-brand__copy {
      min-width: 0;
      line-height: 1.1;
    }

    .itiwi-brand__copy h2 {
      margin: 0;
      color: #ffffff;
      font-size: 22px;
      font-weight: 800;
      letter-spacing: 0.04em;
      line-height: 1;
    }

    .itiwi-brand__copy p {
      margin: 4px 0 0;
      color: var(--itiwi-sidebar-text-soft);
      font-size: 9px;
      font-weight: 600;
      letter-spacing: 0.12em;
      line-height: 1.2;
      text-transform: uppercase;
    }

    .itiwi-sidebar__menu-title {
      padding: 6px 8px 8px;
      color: var(--itiwi-sidebar-text-muted);
      font-size: 11px;
      font-weight: 700;
      letter-spacing: 0.1em;
      text-transform: uppercase;
    }

    .itiwi-sidebar__nav {
      display: flex;
      flex: 1 1 auto;
      min-height: 0;
      flex-direction: column;
      gap: 4px;
      overflow: visible;
      padding-right: 2px;
      margin-bottom: 10px;
    }

    .itiwi-nav__item {
      position: relative;
      display: flex;
      align-items: center;
      gap: 12px;
      width: 100%;
      min-height: 46px;
      padding: 10px 12px;
      border-radius: 16px;
      color: var(--itiwi-sidebar-text);
      text-decoration: none !important;
      transition: background-color 180ms ease, color 180ms ease, transform 180ms ease, box-shadow 180ms ease;
      overflow: hidden;
    }

    .itiwi-nav__item:hover {
      background: rgba(255, 255, 255, 0.08);
      transform: translateX(2px);
    }

    .itiwi-nav__item--active {
      background: #ffffff;
      color: var(--itiwi-sidebar-active-text);
      box-shadow: 0 14px 24px rgba(5, 20, 48, 0.18);
      transform: none;
    }

    .itiwi-nav__item--active:hover {
      background: #ffffff;
      transform: none;
    }

    .itiwi-nav__icon {
      width: 24px;
      height: 24px;
      flex: 0 0 24px;
      color: currentColor;
      transition: color 180ms ease;
    }

    .itiwi-nav__icon svg {
      stroke: currentColor;
      fill: none;
      stroke-width: 2;
      stroke-linecap: round;
      stroke-linejoin: round;
    }

    .itiwi-nav__label {
      font-size: 15px;
      font-weight: 700;
      letter-spacing: 0;
      line-height: 1.2;
      color: inherit;
      white-space: nowrap;
    }

    .itiwi-sidebar__spacer {
      display: none;
    }

    .itiwi-sidebar__footer {
      position: sticky;
      bottom: 0;
      flex-shrink: 0;
      padding-top: 14px;
      padding-bottom: 2px;
      margin-top: auto;
      display: flex;
      flex-direction: column;
      align-items: center;
      background: linear-gradient(180deg, rgba(26, 74, 143, 0) 0%, rgba(26, 74, 143, 0.65) 22%, var(--itiwi-sidebar-bg-alt) 100%);
    }

    .itiwi-sidebar__divider {
      width: 100%;
      height: 1px;
      margin-bottom: 14px;
      background: var(--itiwi-sidebar-line);
    }

    .itiwi-avatar {
      display: flex;
      align-items: center;
      justify-content: center;
      margin: 0 auto 10px;
      width: 60px;
      height: 60px;
      border-radius: 50%;
      background: #ffffff;
      box-shadow: 0 12px 24px rgba(5, 20, 48, 0.16);
      color: var(--itiwi-sidebar-active-text);
    }

    .itiwi-avatar__icon {
      width: 30px;
      height: 30px;
    }

    .itiwi-sidebar__email {
      margin: 0 0 12px;
      padding: 0 8px;
      text-align: center;
      color: #ffffff;
      font-size: 11px;
      font-weight: 600;
      line-height: 1.35;
      word-break: break-word;
      opacity: 0.9;
    }

    .itiwi-logout {
      width: min(100%, 190px);
      display: inline-flex;
      align-items: center;
      justify-content: center;
      gap: 10px;
      min-height: 48px;
      padding: 12px 18px;
      margin: 0 auto;
      border: 0;
      border-radius: 14px;
      background: #ffffff;
      color: #1f2937;
      font: inherit;
      font-size: 15px;
      font-weight: 800;
      cursor: pointer;
      text-decoration: none;
      box-shadow: 0 12px 22px rgba(5, 20, 48, 0.18);
      transition: transform 180ms ease, box-shadow 180ms ease, opacity 180ms ease;
    }

    .itiwi-logout:hover {
      transform: translateY(-1px);
      box-shadow: 0 16px 28px rgba(5, 20, 48, 0.22);
    }

    .itiwi-logout:disabled {
      opacity: 0.7;
      cursor: wait;
      transform: none;
    }

    .itiwi-logout__icon {
      width: 18px;
      height: 18px;
      color: #ef4444;
      flex: 0 0 18px;
    }

    .itiwi-logout__icon svg {
      stroke: currentColor;
      fill: none;
      stroke-width: 2;
      stroke-linecap: round;
      stroke-linejoin: round;
    }

    .main {
      margin-left: calc(var(--itiwi-sidebar-width) + 32px) !important;
      width: calc(100% - var(--itiwi-sidebar-width) - 32px) !important;
    }

    @media (max-width: 980px) {
      .itiwi-sidebar {
        position: static;
        width: 100%;
        height: auto;
        min-height: 100vh;
        border-radius: 0 0 28px 28px;
        overflow: visible;
      }

      .itiwi-sidebar__nav {
        overflow: visible;
        padding-right: 0;
        margin-bottom: 0;
      }

      .main {
        margin-left: 0 !important;
        width: 100% !important;
      }
    }

    @media (max-width: 560px) {
      .itiwi-sidebar {
        padding: 14px 12px 12px;
      }

      .itiwi-nav__item {
        padding: 10px;
        min-height: 44px;
      }

      .itiwi-nav__label {
        font-size: 14px;
      }

      .itiwi-sidebar__email {
        font-size: 10px;
      }
    }
  `;

  const sidebarHTML = `
    <aside class="itiwi-sidebar" aria-label="Sidebar navigation">
      <div class="itiwi-sidebar__brand">
        <div class="itiwi-brand">
          <div class="itiwi-brand__logo" aria-hidden="true">
            <svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg" role="img" aria-hidden="true">
              <polygon points="50,6 78,22 78,56 50,72 22,56 22,22" fill="#ffffff"/>
            </svg>
          </div>

          <div class="itiwi-brand__copy">
            <h2>ITIWI</h2>
            <p>CORON'S CHARM, BICOL'S SOUL</p>
          </div>
        </div>

        <div class="itiwi-sidebar__menu-title">Menu</div>
      </div>

      <nav class="itiwi-sidebar__nav" aria-label="Primary navigation">
        <a class="itiwi-nav__item" href="dashboard.html" data-nav-page="dashboard">
          <span class="itiwi-nav__icon" aria-hidden="true">${iconDashboard()}</span>
          <span class="itiwi-nav__label">Dashboard</span>
        </a>

        <a class="itiwi-nav__item" href="barangay.html" data-nav-page="barangay">
          <span class="itiwi-nav__icon" aria-hidden="true">${iconBuilding()}</span>
          <span class="itiwi-nav__label">Baranggay</span>
        </a>

        <a class="itiwi-nav__item" href="tourist_guide.html" data-nav-page="tourist-guide">
          <span class="itiwi-nav__icon" aria-hidden="true">${iconPinInfo()}</span>
          <span class="itiwi-nav__label">Tourist Guide</span>
        </a>

        <a class="itiwi-nav__item" href="index.html" data-nav-page="hotline">
          <span class="itiwi-nav__icon" aria-hidden="true">${iconHotline()}</span>
          <span class="itiwi-nav__label">Emergency Hotline</span>
        </a>

        <a class="itiwi-nav__item" href="reports.html" data-nav-page="report">
          <span class="itiwi-nav__icon" aria-hidden="true">${iconBadgeAlert()}</span>
          <span class="itiwi-nav__label">Report</span>
        </a>

        <a class="itiwi-nav__item" href="news.html" data-nav-page="news">
          <span class="itiwi-nav__icon" aria-hidden="true">${iconNewspaper()}</span>
          <span class="itiwi-nav__label">News</span>
        </a>

        <a class="itiwi-nav__item" href="transparency_programs.html" data-nav-page="transparency">
          <span class="itiwi-nav__icon" aria-hidden="true">${iconDocument()}</span>
          <span class="itiwi-nav__label">Transparency</span>
        </a>
      </nav>

      <div class="itiwi-sidebar__footer">
        <div class="itiwi-sidebar__divider"></div>

        <div class="itiwi-avatar" aria-hidden="true">
          <div class="itiwi-avatar__icon">${iconUser()}</div>
        </div>

        <div class="itiwi-sidebar__email">adminitrator@gmail.com</div>

        <button id="logoutButton" class="itiwi-logout" type="button">
          <span class="itiwi-logout__icon" aria-hidden="true">${iconLogout()}</span>
          <span>Logout</span>
        </button>
      </div>
    </aside>
  `;

  function iconDashboard() {
    return `
      <svg viewBox="0 0 24 24" aria-hidden="true">
        <rect x="3" y="3" width="7" height="7" rx="1"></rect>
        <rect x="14" y="3" width="7" height="7" rx="1"></rect>
        <rect x="3" y="14" width="7" height="7" rx="1"></rect>
        <rect x="14" y="14" width="7" height="7" rx="1"></rect>
      </svg>
    `;
  }

  function iconBuilding() {
    return `
      <svg viewBox="0 0 24 24" aria-hidden="true">
        <path d="M4 21h16"></path>
        <path d="M5 21V8l7-4 7 4v13"></path>
        <path d="M8 21V12"></path>
        <path d="M12 21V12"></path>
        <path d="M16 21V12"></path>
        <path d="M6 12h12"></path>
      </svg>
    `;
  }

  function iconPinInfo() {
    return `
      <svg viewBox="0 0 24 24" aria-hidden="true">
        <path d="M12 21s5-5.1 5-9a5 5 0 0 0-10 0c0 3.9 5 9 5 9z"></path>
        <circle cx="12" cy="12" r="1"></circle>
        <path d="M12 9v2"></path>
      </svg>
    `;
  }

  function iconHotline() {
    return `
      <svg viewBox="0 0 24 24" aria-hidden="true">
        <path d="M12 3l9 16H3L12 3z"></path>
        <path d="M12 9v4"></path>
        <path d="M12 16h.01"></path>
      </svg>
    `;
  }

  function iconBadgeAlert() {
    return `
      <svg viewBox="0 0 24 24" aria-hidden="true">
        <path d="M12 3l2.2 2.2 3.1-.2 1.8 2.6 2.9 1-.3 3 1.8 2.5-1.8 2.5.3 3-2.9 1-1.8 2.6-3.1-.2L12 21l-2.2-2.2-3.1.2-1.8-2.6-2.9-1 .3-3L.5 12.9l1.8-2.5-.3-3 2.9-1 1.8-2.6 3.1.2L12 3z"></path>
        <path d="M12 8v5"></path>
        <path d="M12 16h.01"></path>
      </svg>
    `;
  }

  function iconNewspaper() {
    return `
      <svg viewBox="0 0 24 24" aria-hidden="true">
        <path d="M4 5h12v14H4z"></path>
        <path d="M16 8h4v11a1 1 0 0 1-1 1h-3"></path>
        <path d="M7 8h6"></path>
        <path d="M7 12h6"></path>
        <path d="M7 16h3"></path>
      </svg>
    `;
  }

  function iconDocument() {
    return `
      <svg viewBox="0 0 24 24" aria-hidden="true">
        <path d="M6 3h9l5 5v13H6z"></path>
        <path d="M15 3v5h5"></path>
        <path d="M8 12h8"></path>
        <path d="M8 16h8"></path>
      </svg>
    `;
  }

  function iconUser() {
    return `
      <svg viewBox="0 0 24 24" aria-hidden="true">
        <path d="M12 13a4 4 0 1 0-4-4 4 4 0 0 0 4 4z"></path>
        <path d="M4 21a8 8 0 0 1 16 0"></path>
      </svg>
    `;
  }

  function iconLogout() {
    return `
      <svg viewBox="0 0 24 24" aria-hidden="true">
        <path d="M10 17l5-5-5-5"></path>
        <path d="M15 12H3"></path>
        <path d="M15 3h6v18h-6"></path>
      </svg>
    `;
  }

  function normalizePage(value) {
    const cleanValue = (value || '').split('?')[0].split('#')[0].trim();

    if (!cleanValue) {
      return 'index';
    }

    return cleanValue.replace(/\.html$/i, '');
  }

  function getCurrentNavPage() {
    const currentPage = normalizePage(window.location.pathname.split('/').pop());
    const currentQuery = new URLSearchParams(window.location.search);

    if (['dashboard'].includes(currentPage)) {
      return 'dashboard';
    }

    if (['barangay', 'add_barangay', 'edit_barangay'].includes(currentPage)) {
      return 'barangay';
    }

    if (['tourist_guide', 'places', 'edit_place', 'place_reviews'].includes(currentPage)) {
      return 'tourist-guide';
    }

    if (['index', 'add', 'edit'].includes(currentPage)) {
      return 'hotline';
    }

    if (['reports'].includes(currentPage)) {
      return 'report';
    }

    if (['news', 'add_news', 'edit_news', 'news_new'].includes(currentPage)) {
      return 'news';
    }

    if (['transparency_programs', 'transparency_bids', 'transparency_financial_reports', 'transparency_annual_budget', 'transparency_legislative_ordinances', 'transparency_executive_orders'].includes(currentPage)) {
      return 'transparency';
    }

    if (currentQuery.get('category')) {
      return 'hotline';
    }

    return currentPage;
  }

  function injectStyles() {
    if (document.getElementById('itiwi-sidebar-styles')) {
      return;
    }

    const style = document.createElement('style');
    style.id = 'itiwi-sidebar-styles';
    style.textContent = sidebarStyles;
    document.head.appendChild(style);
  }

  injectStyles();

  const tempDiv = document.createElement('div');
  tempDiv.innerHTML = sidebarHTML;
  const sidebarElement = tempDiv.firstElementChild;
  document.body.insertBefore(sidebarElement, document.body.firstChild);

  const currentNavPage = getCurrentNavPage();
  const navItems = sidebarElement.querySelectorAll('.itiwi-nav__item[data-nav-page]');

  navItems.forEach((item) => {
    const navPage = item.getAttribute('data-nav-page');
    const isActive = navPage === currentNavPage;

    item.classList.toggle('itiwi-nav__item--active', isActive);
    item.setAttribute('aria-current', isActive ? 'page' : 'false');
  });

  const logoutButton = document.getElementById('logoutButton');

  if (logoutButton && window.adminAuth) {
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
