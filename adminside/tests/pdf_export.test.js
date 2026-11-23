const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const source = fs.readFileSync(path.join(__dirname, '../app.js'), 'utf8');
const exportSource = source.slice(source.indexOf('function exportColumnsForTable('), source.indexOf('// Notifications array'));

function exportTable(bodyId, rows) {
  let options;
  const links = [];
  const messages = [];
  class Pdf {
    constructor() { this.internal = { pageSize: { getWidth: () => 297, getHeight: () => 210 } }; }
    autoTable(config) { options = config; }
    save() {}
    link(...args) { links.push(args); }
  }
  const context = vm.createContext({
    window: { jspdf: { jsPDF: Pdf } }, tableExportRows: { [bodyId]: rows },
    allPlaceReviews: [], formatDate: value => value,
    formatAdminStatus: value => value, formatServiceStatus: value => value,
    formatSubmittedAt: value => value, formatSubmissionAge: () => '1 day',
    getServiceRequesterName: row => row.name, getVerificationBadgeText: value => value,
    showToast: (...args) => messages.push(args), console
  });
  vm.runInContext(exportSource, context);
  context.downloadTablePdf(bodyId, 'sample', 'Sample');
  assert.equal(messages.at(-1)[1], 'success');
  return { options, links, context };
}

test('news reserves space for descriptions and uses clickable image labels', () => {
  const url = 'https://example.com/' + 'long-image-name'.repeat(50) + '.jpg';
  const { options, links } = exportTable('newsTableBody', [{ title: '𝗧𝗶𝘄𝗶 News', description: 'Full description '.repeat(100), image_url: url }]);
  assert.equal(options.body[0][0], 'Tiwi News');
  assert.equal(options.body[0][1], 'Full description '.repeat(100).trim());
  assert.equal(options.body[0][3], 'View image');
  assert.ok(options.columnStyles[1].cellWidth > 65);
  assert.ok(options.columnStyles[3].cellWidth < 30);
  assert.equal(options.rowPageBreak, 'avoid');
  options.didDrawCell({ section: 'body', row: { index: 0 }, column: { index: 3 }, cell: { x: 1, y: 2, width: 20, height: 10 } });
  assert.equal(links[0][4].url, url);
});

test('every export has fixed columns that fit the printable page', () => {
  for (const id of ['barangayTableBody', 'newsTableBody', 'reportsTableBody', 'transparencyTableBody', 'touristTableBody', 'serviceTableBody', 'hotlineTableBody', 'usersTableBody']) {
    const { options } = exportTable(id, [{ created_at: 'Nov 23, 2026' }]);
    const widths = Object.values(options.columnStyles).map(column => column.cellWidth);
    assert.equal(widths.length, options.head[0].length, id);
    assert.ok(Math.abs(widths.reduce((a, b) => a + b, 0) - 273) < 0.001, id);
    assert.ok(widths.every(width => width > 15), id);
  }
});

test('PDF URLs retain the actual link and unsafe URLs are omitted', () => {
  const { options, links } = exportTable('transparencyTableBody', [{ title: 'Budget', pdf_url: 'https://example.com/budget.pdf' }, { title: 'Other', pdf_url: 'javascript:alert(1)' }]);
  assert.equal(options.body[0][3], 'Open PDF');
  assert.equal(options.body[1][3], '');
  options.didDrawCell({ section: 'body', row: { index: 0 }, column: { index: 3 }, cell: { x: 0, y: 0, width: 20, height: 10 } });
  assert.equal(links[0][4].url, 'https://example.com/budget.pdf');
});
