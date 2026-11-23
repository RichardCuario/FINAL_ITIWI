const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');

test('mobile page selection clears the sidebar, backdrop, and scroll lock on every visit', () => {
  const source = fs.readFileSync(path.join(__dirname, '../app.js'), 'utf8');
  const navigation = source.slice(source.indexOf('function navigateTo(page)'), source.indexOf('function setupMobileMenu()'));
  const nodes = {};
  for (const id of ['sidebar', 'sidebarOverlay', 'reportsPage', 'touristPage']) {
    const classes = new Set();
    nodes[id] = { classes, classList: {
      add: value => classes.add(value), remove: value => classes.delete(value)
    } };
  }
  const body = { style: { overflow: '' } };
  const loaded = [];
  const context = vm.createContext({
    document: {
      body,
      getElementById: id => nodes[id],
      querySelectorAll: selector => selector === '.page' ? [nodes.reportsPage, nodes.touristPage] : []
    },
    localStorage: { setItem() {} },
    getCurrentAdminSession: () => ({}),
    canAccessPage: () => true,
    resolvePageId: page => `${page}Page`,
    loadReports: () => loaded.push('reports'),
    loadTourist: () => loaded.push('tourist')
  });
  vm.runInContext(navigation, context);
  for (const page of ['reports', 'tourist', 'reports']) {
    nodes.sidebar.classes.add('open');
    nodes.sidebarOverlay.classes.add('active');
    body.style.overflow = 'hidden';
    context.navigateTo(page);
    assert.equal(nodes.sidebar.classes.has('open'), false);
    assert.equal(nodes.sidebarOverlay.classes.has('active'), false);
    assert.equal(body.style.overflow, '');
    assert.equal(nodes[`${page}Page`].classes.has('active'), true);
  }
  assert.deepEqual(loaded, ['reports', 'tourist', 'reports']);
});
