const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const source = fs.readFileSync(path.join(__dirname, '../app.js'), 'utf8');

function form(raw) {
  const rows = [];
  const list = { dataset: {}, replaceChildren() { rows.length = 0; } };
  const context = vm.createContext({
    document: { getElementById: () => list },
    console: { error() {} }, showToast() {},
    addOfficialRow(official, listId = 'barangayOfficialsList') {
      assert.equal(listId, 'barangayOfficialsList');
      rows.push(official);
    }
  });
  vm.runInContext(source.slice(source.indexOf('function populateOfficials('), source.indexOf('function addOfficialRow(')), context);
  context.populateOfficials(raw);
  return { rows, list };
}

test('empty form has all eleven default positions', () => {
  const { rows } = form(null);
  assert.equal(rows.length, 11);
  assert.equal(rows.filter(row => row.position === 'Barangay Kagawad').length, 7);
  for (const position of ['Punong Barangay', 'SK Chairman', 'Barangay Secretary', 'Barangay Treasurer']) {
    assert.equal(rows.filter(row => row.position === position).length, 1);
  }
});

test('JSON arrays load without passing an array index as the target container', () => {
  const officials = [{ name: 'Ana', position: 'Punong Barangay', image_url: 'https://example.com/photo.jpg' },
    { name: 'Ben', position: 'Barangay Kagawad' }];
  for (const raw of [officials, JSON.stringify(officials), JSON.stringify(JSON.stringify(officials))]) {
    const { rows, list } = form(raw);
    assert.equal(list.dataset.loadError, 'false');
    assert.equal(rows.length, 11);
    assert.deepEqual(JSON.parse(JSON.stringify(rows[0])), officials[0]);
    assert.equal(rows[1].name, 'Ben');
    const reopened = form(JSON.stringify(rows.filter(row => row.name)));
    assert.equal(JSON.stringify(reopened.rows), JSON.stringify(rows));
  }
});

test('legacy roles and additional officials are preserved', () => {
  assert.equal(form({ punong_barangay: 'Ana', kagawad: ['Ben'] }).rows[1].name, 'Ben');
  const { rows } = form('Ana, Ben');
  assert.equal(rows.length, 13);
  assert.equal(rows[11].name, 'Ana');
});

test('an intentionally blank official position stays blank when reopened', () => {
  const { rows, list } = form([{ name: 'Ana', position: '' }]);
  assert.equal(list.dataset.loadError, 'false');
  assert.equal(rows.find(row => row.name === 'Ana').position, '');
});

test('malformed JSON and previously corrupted names are not split into officials', () => {
  for (const raw of ['[{"name":"Ana"', [{ name: '[{"name":"Ana"', position: 'Barangay Official' }], { unexpected: 'data' }]) {
    const { rows, list } = form(raw);
    assert.equal(rows.length, 0);
    assert.equal(list.dataset.loadError, 'true');
  }
});

test('collection skips vacant slots but retains incomplete rows with photos for validation', () => {
  const official = (name, photo = '') => ({ dataset: { imageUrl: photo }, querySelector(selector) {
    return selector === '.official-name' ? { value: name } : selector === '.official-position'
      ? { value: 'Barangay Kagawad' } : { files: [] };
  } });
  const context = vm.createContext({ document: { querySelectorAll: () => [official(''), official(' Ana '), official('', 'photo.jpg')] } });
  vm.runInContext(source.slice(source.indexOf('function collectOfficials('), source.indexOf('function populateOfficials(')), context);
  const rows = context.collectOfficials();
  assert.equal(rows.length, 2);
  assert.equal(rows[0].name, 'Ana');
  assert.equal(rows[1].image_url, 'photo.jpg');
});

test('barangay saves without description, official names, or coordinates and rejects half a coordinate pair', async () => {
  const values = {
    barangayEditId: '', barangayName: 'Biyong', barangayDescription: '',
    barangayLocation: '', barangayLatitude: '', barangayLongitude: '',
    barangayLogoBase64: '', barangayCoverImageBase64: '',
    barangayLogo: '', barangayCoverImage: ''
  };
  const nodes = Object.fromEntries(Object.entries(values).map(([id, value]) =>
    [id, { value, files: [], dataset: {}, innerHTML: '', disabled: false }]));
  nodes.barangayOfficialsList = { dataset: { loadError: 'false' } };
  nodes.barangaySaveBtn = { innerHTML: '', disabled: false };
  const saved = [];
  const notices = [];
  let selectedOfficials = [];
  const context = vm.createContext({
    document: { getElementById: id => nodes[id] },
    collectOfficials: () => selectedOfficials,
    // Duplicate validation has its own behavioral tests in duplicate_names.test.js.
    ensureUniqueRecordName: async () => {},
    recordSaveError: error => error.message,
    supabaseClient: { from: () => ({ insert: async payload => { saved.push(payload); return { error: null }; } }) },
    showToast: message => notices.push(message),
    closeBarangayModal() {}, loadDashboardStats() {}, loadDashboardBarangay() {},
    loadBarangayTable() {}, addNotification() {}, console
  });
  vm.runInContext(source.slice(source.indexOf('async function saveBarangay()'),
    source.indexOf('// ---------- Helper Functions for Officials ----------')), context);
  await context.saveBarangay();
  assert.equal(saved.length, 1);
  assert.equal(saved[0].description, null);
  assert.equal(saved[0].geographic_data, null);
  assert.equal(saved[0].latitude, null);
  assert.equal(saved[0].longitude, null);
  assert.equal(saved[0].officials, '[]');

  nodes.barangayLatitude.value = '13.45';
  await context.saveBarangay();
  assert.equal(saved.length, 1);
  assert.match(notices.at(-1), /both valid latitude and longitude/);

  nodes.barangayLatitude.value = '';
  selectedOfficials = [{ name: 'Ana', position: '', image_url: null, file: null }];
  await context.saveBarangay();
  assert.equal(saved.length, 2);
  assert.equal(JSON.parse(saved[1].officials)[0].position, '');
});
