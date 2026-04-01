// Shared Sidebar Component
async function createSidebar() {
  const sidebarHTML = `
  <div class="sidebar">
    <div class="logo">
      <h2>ITIWI</h2>
    </div>

    <div class="menu">
      <a class="menu-item" href="dashboard.html" style="text-decoration: none; color: inherit;">
        <span>&#8962;</span>
        <p>Dashboard</p>
      </a>

      <a class="menu-item" href="index.html" style="text-decoration: none; color: inherit;">
        <span>&#9888;</span>
        <p>Emergency Hotline</p>
      </a>

      <a class="menu-item" href="news.html" style="text-decoration: none; color: inherit;">
        <span>&#128240;</span>
        <p>News</p>
      </a>

      <a class="menu-item" href="reports.html" style="text-decoration: none; color: inherit;">
        <span>&#128221;</span>
        <p>Reports</p>
      </a>

      <a class="menu-item" href="barangay.html" style="text-decoration: none; color: inherit;">
        <span>&#127970;</span>
        <p>Barangay</p>
      </a>
    </div>

    <div class="menu" style="margin-top: auto; padding-top: 16px; border-top: 1px solid rgba(255,255,255,0.08);">
      <div id="adminSessionMeta" style="padding: 0 18px 12px; color: rgba(255,255,255,0.72); font-size: 12px; line-height: 1.6;">Signed in</div>
      <button id="logoutButton" class="menu-item" type="button" style="width: 100%; background: transparent; border: 0; text-align: left; color: inherit; cursor: pointer;">
        <span>&#10162;</span>
        <p>Logout</p>
      </button>
    </div>
  </div>
  `;

  const currentPage = window.location.pathname.split('/').pop() || 'index.html';

  const tempDiv = document.createElement('div');
  tempDiv.innerHTML = sidebarHTML;
  const sidebarElement = tempDiv.firstElementChild;
  document.body.insertBefore(sidebarElement, document.body.firstChild);

  const menuItems = document.querySelectorAll('.sidebar .menu-item');
  menuItems.forEach(item => {
    const href = item.getAttribute('href');
    if (href === currentPage ||
        (currentPage === '' && href === 'dashboard.html') ||
        (href === 'index.html' && currentPage === 'index.html') ||
        (href === 'news.html' && (currentPage === 'news.html' || currentPage === 'add_news.html' || currentPage === 'news_new.html' || currentPage === 'edit_news.html')) ||
        (href === 'reports.html' && currentPage === 'reports.html') ||
        (href === 'index.html' && (currentPage === 'add.html' || currentPage === 'edit.html')) ||
        (href === 'barangay.html' && (currentPage === 'barangay.html' || currentPage === 'add_barangay.html' || currentPage === 'edit_barangay.html'))) {
      item.classList.add('active');
    }
  });

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
