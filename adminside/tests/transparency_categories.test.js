const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const logic = require('../admin_roles_logic');
const source = fs.readFileSync(path.join(__dirname, '../app.js'), 'utf8');

test('Transparency and Reports show only their selected category selectors', () => {
  const nodes = Object.fromEntries(['reportCategoryAccessGroup',
    'transparencyCategoryAccessGroup'].map(id => [id, { style: {} }]));
  let features = ['transparency'];
  const context = vm.createContext({ document: { getElementById: id => nodes[id] }, selectedAdminFeatures: () => features });
  vm.runInContext(source.slice(source.indexOf('function updateReportCategoryAccessVisibility('), source.indexOf('function selectedAdminReportCategories(')), context);
  context.updateReportCategoryAccessVisibility();
  assert.equal(nodes.transparencyCategoryAccessGroup.style.display, 'block');
  assert.equal(nodes.reportCategoryAccessGroup.style.display, 'none');
  features.push('reports');
  context.updateReportCategoryAccessVisibility();
  assert.equal(nodes.reportCategoryAccessGroup.style.display, 'block');
  features = [];
  context.updateReportCategoryAccessVisibility();
  assert.equal(nodes.transparencyCategoryAccessGroup.style.display, 'none');
  assert.equal(nodes.reportCategoryAccessGroup.style.display, 'none');
});

test('edit form toggles transparency categories independently', () => {
  const nodes = { editAdminReportGroup: {}, editAdminTransparencyGroup: {} };
  let transparency = true;
  const context = vm.createContext({ document: {
    getElementById: id => nodes[id],
    querySelector: selector => ({ checked: selector.includes('transparency') && transparency })
  } });
  vm.runInContext(source.slice(source.indexOf('function updateEditAdminReportVisibility('), source.indexOf('function editAdminRole(')), context);
  context.updateEditAdminReportVisibility();
  assert.equal(nodes.editAdminTransparencyGroup.hidden, false);
  assert.equal(nodes.editAdminReportGroup.hidden, true);
  transparency = false;
  context.updateEditAdminReportVisibility();
  assert.equal(nodes.editAdminTransparencyGroup.hidden, true);
});

test('account payload saves only valid selected transparency categories', () => {
  const payload = logic.buildAdminAccountCreationPayload({ features: ['transparency'],
    transparencyCategories: ['bids_projects', 'bids_projects', 'invalid'] });
  assert.deepEqual(payload.options.data.transparency_categories, ['bids_projects']);
  const attemptedSuperAdmin = logic.buildAdminAccountCreationPayload({
    features: ['tourist'], isSuperAdmin: true
  });
  assert.equal(attemptedSuperAdmin.options.data.is_super_admin, false);
  assert.deepEqual(attemptedSuperAdmin.options.data.permissions, ['tourist']);
});

test('category filter and access match assigned categories including legacy aliases', () => {
  let session = { permissions: ['transparency'], transparencyCategories: ['bids_projects'] };
  const select = { value: '', options: [], replaceChildren() { this.options = []; }, append(option) { this.options.push(option); } };
  const context = vm.createContext({ ...logic, getCurrentAdminSession: () => session,
    document: { getElementById: () => select }, Option: function(label, value) { this.label = label; this.value = value; } });
  vm.runInContext(source.slice(source.indexOf('function canonicalTransparencyType('), source.indexOf('let allTransparency =')), context);
  assert.equal(context.canAccessTransparency('bids'), true);
  assert.equal(context.canAccessTransparency('financial_reports'), false);
  context.syncTransparencyCategoryFilter();
  assert.equal(select.value, 'bids_projects');
  assert.equal(select.disabled, true);
  session = { isSuperAdmin: true };
  context.syncTransparencyCategoryFilter();
  assert.equal(select.options.length, 7);
  assert.equal(select.disabled, false);
});

test('Admin can choose a record category from All Types; staff remain scoped to their filter', () => {
  const nodes = Object.fromEntries([
    'transparencyTypeFilter', 'transparencyRecordCategoryGroup', 'transparencyCurrentType',
    'transparencyModalTitle', 'transparencyEditId', 'transparencyTitle',
    'transparencyDescription', 'transparencyDisplayOrder', 'transparencyIsPublished',
    'transparencyPdfUrl', 'transparencyPdfBase64', 'transparencyPdfPreview',
    'transparencySaveBtn'
  ].map(id => [id, { value: '', hidden: true, checked: false, textContent: '', innerHTML: '' }]));
  const options = [];
  nodes.transparencyRecordCategory = {
    value: '', replaceChildren(...items) { options.splice(0, options.length, ...items); },
    append(item) { options.push(item); }
  };
  nodes.transparencyModal = { classList: { add() {} } };
  let session = { isSuperAdmin: true };
  const notices = [];
  const context = vm.createContext({
    document: { getElementById: id => nodes[id] },
    getCurrentAdminSession: () => session,
    canAccessTransparency: type => session.isSuperAdmin || type === 'bids_projects',
    canonicalTransparencyType: type => type,
    TRANSPARENCY_CATEGORIES: logic.TRANSPARENCY_CATEGORIES,
    Option: function(label, value) { this.label = label; this.value = value; },
    setupTransparencyPdfUpload() {}, updateTransparencyTable() {},
    showToast: message => notices.push(message)
  });
  vm.runInContext(source.slice(source.indexOf('function setTransparencyRecordType('),
    source.indexOf('async function openEditTransparencyModal(')), context);

  context.openTransparencyModal();
  assert.equal(nodes.transparencyRecordCategoryGroup.hidden, false);
  assert.equal(options.length, logic.TRANSPARENCY_CATEGORIES.length + 1);
  assert.equal(nodes.transparencyCurrentType.value, '');
  context.setTransparencyRecordType('bids_projects');
  assert.equal(nodes.transparencyCurrentType.value, 'bids_projects');
  assert.equal(nodes.transparencyModalTitle.textContent, 'Add Bids & Projects Record');

  session = { isSuperAdmin: false };
  nodes.transparencyTypeFilter.value = '';
  context.openTransparencyModal();
  assert.equal(notices.length, 1);
  nodes.transparencyTypeFilter.value = 'bids_projects';
  context.openTransparencyModal();
  assert.equal(nodes.transparencyRecordCategoryGroup.hidden, true);
  assert.equal(nodes.transparencyCurrentType.value, 'bids_projects');
});
