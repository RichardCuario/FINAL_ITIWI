const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const source = fs.readFileSync(path.join(__dirname, '../app.js'), 'utf8');
const context = vm.createContext({
  formatDate: value => `date:${value}`,
  formatSubmittedAt: value => value || 'Not recorded',
  formatSubmissionAge: () => '1d',
  formatAdminStatus: value => value,
  formatServiceStatus: value => value,
});
vm.runInContext(source.slice(source.indexOf('function buildServiceDetailsFields('), source.indexOf('function closeServiceDetailsModal(')), context);
const details = record => context.buildServiceDetailsFields(record, 'Account Owner');

test('birth details show owner birthday separately from requester without duplicates', () => {
  const rows = details({table_name:'birth_certificate_appointments', full_name:'Certificate Owner',
    date_of_birth:'2001-02-03', place_of_birth:'Tiwi, Albay',
    mother_full_name:'Maria Santos', father_full_name:'Pedro Santos',
    appointment_date:'2026-10-22', relationship_to_owner:'Parent',
    authorization_letter_path:'private/letter.jpg', owner_valid_id_path:'private/id.jpg'});
  assert.equal(rows.find(row => row.label === 'Birthday').value, 'date:2001-02-03');
  assert.equal(rows.find(row => row.label === 'Certificate Owner').value, 'Certificate Owner');
  assert.equal(rows.find(row => row.label === 'Place of Birth').value, 'Tiwi, Albay');
  assert.equal(rows.find(row => row.label === 'Mother’s Full Name').value, 'Maria Santos');
  assert.equal(rows.find(row => row.label === 'Father’s Full Name').value, 'Pedro Santos');
  assert.equal(rows.find(row => row.label === 'Requested By').value, 'Account Owner');
  assert.equal(rows.filter(row => row.label === 'Appointment').length, 1);
  assert.equal(rows.some(row => String(row.value).includes('private/')), false);
});

test('marriage and death show service-specific dates and names', () => {
  const marriage = details({table_name:'marriage_certificate_appointments', husband_name:'A', wife_name:'B', marriage_date:'2020-01-01', place_of_marriage:'Tiwi, Albay'});
  assert.equal(marriage.find(row => row.label === 'Date of Marriage').value, 'date:2020-01-01');
  assert.equal(marriage.find(row => row.label === 'Wife').value, 'B');
  assert.equal(marriage.find(row => row.label === 'Place of Marriage').value, 'Tiwi, Albay');
  const death = details({table_name:'death_certificate_appointments', deceased_full_name:'C', date_of_death:'2025-01-01',
    place_of_death:'Tiwi', requestor_full_name:'Relative', relationship_to_owner:'Child'});
  assert.equal(death.find(row => row.label === 'Date of Death').value, 'date:2025-01-01');
  assert.equal(death.find(row => row.label === 'Deceased Person').value, 'C');
  assert.equal(death.find(row => row.label === 'Place of Death').value, 'Tiwi');
  assert.equal(death.find(row => row.label === 'Requested By').value, 'Relative');
  assert.equal(death.find(row => row.label === 'Relationship to Deceased').value, 'Child');
});

test('older records omit missing dates and empty notes', () => {
  for (const [table, label] of [['birth_certificate_appointments', 'Certificate Owner Birthday'], ['marriage_certificate_appointments', 'Date of Marriage'], ['death_certificate_appointments', 'Date of Death']]) {
    assert.equal(details({table_name:table}).some(row => row.label === label), false);
  }
  const self = details({table_name:'birth_certificate_appointments', relationship_to_owner:'Self'});
  assert.equal(self.some(row => row.label === 'Notes'), false);
  assert.equal(self.find(row => row.label === 'Relationship to Certificate Owner').value, 'Self');
});

test('CENOMAR and facility requests show their entered details and decision notes', () => {
  const cenomar = details({table_name:'cenomar_appointments', full_name:'Applicant',
    relationship_to_owner:'Sibling', purpose:'Employment'});
  assert.equal(cenomar.find(row => row.label === 'Name on Request').value, 'Applicant');
  assert.equal(cenomar.find(row => row.label === 'Purpose').value, 'Employment');

  const facility = details({table_name:'facility_borrow_requests', facility_name:'Tiwi Gymnasium',
    full_name:'Requester', event_date:'2026-11-15', start_time:'9:00 AM', end_time:'1:00 PM',
    expected_participants:80, additional_information:'Need chairs', status:'completed', approval_reason:'Approved'});
  assert.equal(facility.find(row => row.label === 'Requested By').value, 'Requester');
  assert.equal(facility.find(row => row.label === 'Facility').value, 'Tiwi Gymnasium');
  assert.equal(facility.find(row => row.label === 'Event Date').value, 'date:2026-11-15');
  assert.equal(facility.find(row => row.label === 'Time').value, '9:00 AM to 1:00 PM');
  assert.equal(facility.find(row => row.label === 'Participants').value, '80');
  assert.equal(facility.find(row => row.label === 'Additional Information').value, 'Need chairs');
  assert.equal(facility.find(row => row.label === 'Approval Notes').value, 'Approved');
});

test('appointment date and time are combined, with relevant contact details', () => {
  const rows = details({table_name:'birth_certificate_appointments', appointment_date:'2026-11-12',
    appointment_time:'11:00 AM', contact_number:'09123456789', email:'person@example.com',
    created_at:'2026-10-21T03:18:57Z', updated_at:'2026-10-21T03:18:57Z'});
  assert.equal(rows.find(row => row.label === 'Appointment').value, 'date:2026-11-12 at 11:00 AM');
  assert.equal(rows.find(row => row.label === 'Phone').value, '09123456789');
  assert.equal(rows.some(row => row.label === 'Last Updated (PHT)' || row.label === 'Time Since Submission'), false);
});
