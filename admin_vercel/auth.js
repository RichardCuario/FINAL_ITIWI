const SUPABASE_URL = 'https://jbhlbukxankrtcwhqoll.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpiaGxidWt4YW5rcnRjd2hxb2xsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ0NzAxODgsImV4cCI6MjA5MDA0NjE4OH0.DebtVdw7bF5nRaXQg8Ta2SsO2Qv42QnGSzoS8hT2vJc';
const LOGIN_PAGE = 'login.html';
const TEMP_ADMIN_EMAIL = 'admin@itiwi.local';
const TEMP_ADMIN_PASSWORD = 'Admin1234';
const TEMP_ADMIN_STORAGE_KEY = 'itiwi_temp_admin_session';

function getCurrentAdminPage() {
  return window.location.pathname.split('/').pop() || 'index.html';
}

function isPublicAdminPage() {
  const currentPage = getCurrentAdminPage();
  return currentPage === LOGIN_PAGE;
}

function getSupabaseClient() {
  if (!window.supabase || typeof window.supabase.createClient !== 'function') {
    throw new Error('Supabase client failed to load.');
  }

  if (!window.__adminSupabaseClient) {
    window.__adminSupabaseClient = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
  }

  return window.__adminSupabaseClient;
}

async function requireAdminAuth() {
  if (isPublicAdminPage()) {
    return null;
  }

  const tempAdminSession = window.localStorage.getItem(TEMP_ADMIN_STORAGE_KEY);

  if (tempAdminSession === 'true') {
    return {
      user: {
        email: TEMP_ADMIN_EMAIL
      },
      isTemporaryAdmin: true
    };
  }

  const client = getSupabaseClient();
  const { data, error } = await client.auth.getSession();

  if (error || !data?.session) {
    window.location.replace(LOGIN_PAGE);
    return null;
  }

  return data.session;
}

async function initializeAdminPage() {
  const session = await requireAdminAuth();

  if (!session) {
    return null;
  }

  const isTemporaryAdmin = Boolean(session?.isTemporaryAdmin);

  if (!isTemporaryAdmin) {
    const client = getSupabaseClient();

    client.auth.onAuthStateChange((event, nextSession) => {
      if (event === 'SIGNED_OUT' || !nextSession) {
        window.location.replace(LOGIN_PAGE);
      }
    });

    return {
      session,
      client
    };
  }

  return {
    session,
    client: getSupabaseClient()
  };
}

async function redirectIfAuthenticated() {
  if (!isPublicAdminPage()) {
    return null;
  }

  const tempAdminSession = window.localStorage.getItem(TEMP_ADMIN_STORAGE_KEY);

  if (tempAdminSession === 'true') {
    window.location.replace('dashboard.html');
    return {
      user: {
        email: TEMP_ADMIN_EMAIL
      },
      isTemporaryAdmin: true
    };
  }

  const client = getSupabaseClient();
  const { data, error } = await client.auth.getSession();

  if (!error && data?.session) {
    window.location.replace('dashboard.html');
    return data.session;
  }

  return null;
}

async function getAdminUserEmail() {
  const tempAdminSession = window.localStorage.getItem(TEMP_ADMIN_STORAGE_KEY);

  if (tempAdminSession === 'true') {
    return TEMP_ADMIN_EMAIL;
  }

  const client = getSupabaseClient();
  const { data } = await client.auth.getUser();
  return data?.user?.email || '';
}

async function signInAdmin(email, password) {
  if (email === TEMP_ADMIN_EMAIL && password === TEMP_ADMIN_PASSWORD) {
    window.localStorage.setItem(TEMP_ADMIN_STORAGE_KEY, 'true');
    return {
      data: {
        session: {
          user: {
            email: TEMP_ADMIN_EMAIL
          },
          isTemporaryAdmin: true
        }
      },
      error: null
    };
  }

  const client = getSupabaseClient();
  return client.auth.signInWithPassword({ email, password });
}

async function signOutAdmin() {
  window.localStorage.removeItem(TEMP_ADMIN_STORAGE_KEY);

  const client = getSupabaseClient();
  return client.auth.signOut();
}

window.adminAuth = {
  LOGIN_PAGE,
  SUPABASE_URL,
  SUPABASE_ANON_KEY,
  TEMP_ADMIN_EMAIL,
  TEMP_ADMIN_PASSWORD,
  getSupabaseClient,
  requireAdminAuth,
  initializeAdminPage,
  redirectIfAuthenticated,
  getAdminUserEmail,
  signInAdmin,
  signOutAdmin,
  getCurrentAdminPage
};
