const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const source = fs.readFileSync(path.join(__dirname, '../app.js'), 'utf8');
const helperSource = source.slice(source.indexOf('function normalizeRecordName('), source.indexOf('async function saveBarangay('));

function context(rows, error = null) {
  const calls = [];
  const supabaseClient = { from(table) {
    const query = {
      select(columns) { calls.push({ table, columns }); return query; },
      order() { return query; },
      async range(start, end) { return { data: rows.slice(start, end + 1), error }; }
    };
    return query;
  } };
  const ctx = vm.createContext({ supabaseClient });
  vm.runInContext(helperSource, ctx);
  return { ctx, calls };
}

test('duplicates ignore case and surrounding/repeated whitespace', async () => {
  const { ctx } = context([{ id: '1', name: '  Tiwi\t Rescue  ' }]);
  await assert.rejects(ctx.ensureUniqueRecordName('hotlines', 'name', 'tiwi rescue', '', 'A hotline with this name'), /already exists/);
  await ctx.ensureUniqueRecordName('hotlines', 'name', 'Tiwi Police', '', 'A hotline with this name');
});

test('an edit may retain its own name but cannot take another name', async () => {
  const { ctx } = context([{ id: 1, name: 'Tiwi' }, { id: 2, name: 'Other' }]);
  await ctx.ensureUniqueRecordName('barangays', 'name', 'TIWI', '1', 'A barangay with this name');
  await assert.rejects(ctx.ensureUniqueRecordName('barangays', 'name', 'Other', '1', 'A barangay with this name'), /already exists/);
});

test('checks later pages and fails closed on database errors', async () => {
  const rows = Array.from({ length: 501 }, (_, id) => ({ id, name: `Place ${id}` }));
  const { ctx, calls } = context(rows);
  await assert.rejects(ctx.ensureUniqueRecordName('places', 'name', 'place 500', '', 'A tourist spot with this name'), /already exists/);
  assert.equal(calls.length, 2);
  const failed = context([], { message: 'Permission denied' }).ctx;
  await assert.rejects(failed.ensureUniqueRecordName('places', 'name', 'New', '', 'A tourist spot'), /Unable to check/);
});

test('transparency compares titles in the requested category only', async () => {
  const { ctx, calls } = context([{ id: 'a', title: 'Annual  Report' }]);
  await assert.rejects(ctx.ensureUniqueRecordName('transparency_financial_reports', 'title', 'annual report', '', 'A document with this title in this category'), /already exists/);
  assert.deepEqual(calls, [{ table: 'transparency_financial_reports', columns: 'id,title' }]);
});

test('all four save flows reject a duplicate before uploading or writing', async () => {
  for (const name of ['saveBarangay', 'saveTransparency', 'saveTourist', 'saveHotline']) {
    const start = source.indexOf(`async function ${name}(`);
    const end = source.indexOf('\nfunction ', start);
    const values = { barangayName: 'Existing', transparencyTitle: 'Existing', transparencyCurrentType: 'annual_budget', touristName: 'Existing', touristLocation: 'Tiwi', touristCategory: 'Nature', touristLatitude: '13', touristLongitude: '123', hotlineName: 'Existing', hotlineCategory: 'Emergency', hotlineNumber: '911' };
    const elements = new Map();
    const messages = [];
    const ctx = vm.createContext({
      document: { getElementById(id) {
        if (!elements.has(id)) elements.set(id, { value: values[id] || '', dataset: {}, files: [{}], disabled: false });
        return elements.get(id);
      } },
      collectOfficials: () => [], canAccessTransparency: () => true,
      supabaseClient: {},
      ensureUniqueRecordName: async () => { throw new Error('Name already exists'); },
      recordSaveError: error => error.message,
      showToast: message => messages.push(message), console: { error() {} }
    });
    vm.runInContext(source.slice(start, end), ctx);
    await ctx[name]();
    assert.ok(messages.some(message => message.includes('already exists')), name);
    assert.equal(messages.length, 1, name);
    assert.equal([...elements.values()].some(element => element.disabled), false, name);
  }
});
