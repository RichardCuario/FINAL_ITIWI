const test = require('node:test');
const assert = require('node:assert/strict');
const { formatSubmittedAt, formatSubmittedDate, formatSubmissionAge } = require('../submission_time.js');

test('submission time includes Philippine date, hours, minutes and seconds', () => {
  assert.match(formatSubmittedAt('2026-10-07T01:02:03Z'), /Oct 07, 2026.*09:02:03 PHT/);
});

test('reports table shows only the Philippine submission date', () => {
  assert.equal(formatSubmittedDate('2026-10-07T17:02:03Z'), 'Oct 08, 2026');
  assert.equal(formatSubmittedDate('2026-10-07'), 'Not recorded');
});

test('aging is elapsed time since submission', () => {
  assert.equal(formatSubmissionAge('2026-10-07T01:02:03Z', Date.parse('2026-10-08T03:05:07Z')),
    '1d 02h 03m 04s');
});

test('missing or date-only values are not presented as exact submission times', () => {
  assert.equal(formatSubmittedAt('2026-10-07'), 'Not recorded');
  assert.equal(formatSubmissionAge(null), 'Not recorded');
});
