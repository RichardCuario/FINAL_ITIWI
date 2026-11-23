const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const path = require('node:path');
const source = fs.readFileSync(path.join(__dirname, '../app.js'), 'utf8');
const context = vm.createContext({});
vm.runInContext(source.slice(source.indexOf('function getServiceRequesterName('), source.indexOf('function closeServiceDetailsModal(')), context);
const name = context.getServiceRequesterName;

test('placeholder requester does not hide the linked display name', () => {
  assert.equal(name({requested_by: 'N/A', display_name: 'Richard Cu ario'}), 'Richard Cu ario');
  assert.equal(name({requested_by: 'N/A'}, 'Richard'), 'Richard');
});
test('blank names and placeholder strings fall through to requester fields', () => {
  assert.equal(name({display_name: ' ', requested_by: ' n/a ', requester: ' Jane '}), 'Jane');
  assert.equal(name({requested_by: 'Alex'}), 'Alex');
});
test('certificate owner is not mistaken for the person who requested it', () => {
  assert.equal(name({full_name: 'Certificate Owner'}), 'N/A');
  assert.equal(name({full_name: 'Certificate Owner', display_name: 'Requester'}), 'Requester');
});

test('death and facility requests use the name entered by the requester', () => {
  assert.equal(name({table_name: 'death_certificate_appointments', requestor_full_name: 'Relative', display_name: 'Account Owner'}), 'Relative');
  assert.equal(name({table_name: 'facility_borrow_requests', full_name: 'Organizer', display_name: 'Account Owner'}), 'Organizer');
});
