const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');

function loadPage(file, auth = {}, url = 'https://admin.example.com/login.html') {
  const elements = new Map();
  function element(id) {
    if (!elements.has(id)) elements.set(id, {
      value: '', textContent: 'Forgot Password?', disabled: file === 'reset-password.html',
      handlers: {}, classList: { add() {}, remove() {} },
      parentElement: { classList: { add() {}, remove() {} } },
      addEventListener(event, callback) { this.handlers[event] = callback; },
      setAttribute() {}, removeAttribute() {}, focus() {}, reportValidity() {},
      checkValidity() { return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(this.value); }
    });
    return elements.get(id);
  }
  const events = {};
  const timers = [];
  const context = vm.createContext({
    URL, URLSearchParams, console,
    document: { getElementById: element },
    window: { location: { href: url, hash: new URL(url).hash, search: new URL(url).search }, supabase: { createClient: () => ({ auth }) },
      addEventListener: (name, callback) => { events[name] = callback; } },
    setTimeout: callback => timers.push(callback),
    localStorage: { getItem: () => null }
  });
  const html = fs.readFileSync(path.join(__dirname, '..', file), 'utf8');
  const script = [...html.matchAll(/<script>([\s\S]*?)<\/script>/g)].at(-1)[1];
  vm.runInContext(script, context);
  return { element, events, timers, context,
    fire: (id, event) => element(id).handlers[event]({ preventDefault() {} }) };
}

test('admin login does not offer password reset', () => {
  const html = fs.readFileSync(path.join(__dirname, '..', 'login.html'), 'utf8');
  assert.doesNotMatch(html, /forgotPasswordLink|resetPasswordForEmail|forgot password\?/i);
});

for (const expired of [false, true]) {
  test(`${expired ? 'expired' : 'missing'} recovery session cannot update password`, async () => {
    let updates = 0;
    const page = loadPage('reset-password.html', {
      getSession: async () => ({ data: { session: null } }),
      updateUser: async () => { updates++; }
    }, `https://admin.example.com/reset-password.html${expired ? '#error=access_denied&error_code=otp_expired' : ''}`);
    await page.events.load();
    await page.fire('resetForm', 'submit');
    assert.equal(page.element('submitBtn').disabled, true);
    assert.equal(updates, 0);
  });
}

test('verified session updates password, signs out, and returns to login', async () => {
  const calls = [];
  const page = loadPage('reset-password.html', {
    getSession: async () => ({ data: { session: { user: { id: '1' } } } }),
    getUser: async () => ({ data: { user: { id: '1' } } }),
    updateUser: async ({ password }) => { calls.push(password); return {}; },
    signOut: async ({ scope }) => { calls.push(scope); return {}; }
  });
  await page.events.load();
  assert.equal(page.element('submitBtn').disabled, false);
  page.element('password').value = 'New-password-123';
  page.element('confirmPassword').value = 'different';
  await page.fire('resetForm', 'submit');
  assert.deepEqual(calls, []);
  page.element('confirmPassword').value = 'New-password-123';
  await page.fire('resetForm', 'submit');
  assert.deepEqual(calls, ['New-password-123', 'local']);
  assert.equal(page.element('submitBtn').disabled, true);
  page.timers.at(-1)();
  assert.match(page.context.window.location.href, /\/login.html$/);
});
