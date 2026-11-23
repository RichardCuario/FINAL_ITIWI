function parseSubmissionTime(value) {
  if (typeof value !== 'string' || !/[T\s]\d{2}:\d{2}:\d{2}/.test(value)) return null;
  const date = new Date(value);
  return Number.isNaN(date.getTime()) ? null : date;
}

function formatSubmittedAt(value) {
  const date = parseSubmissionTime(value);
  if (!date) return 'Not recorded';
  return new Intl.DateTimeFormat('en-PH', {
    timeZone: 'Asia/Manila',
    year: 'numeric', month: 'short', day: '2-digit',
    hour: '2-digit', minute: '2-digit', second: '2-digit',
    hourCycle: 'h23'
  }).format(date) + ' PHT';
}

function formatSubmittedDate(value) {
  const date = parseSubmissionTime(value);
  if (!date) return 'Not recorded';
  return new Intl.DateTimeFormat('en-PH', {
    timeZone: 'Asia/Manila',
    year: 'numeric', month: 'short', day: '2-digit'
  }).format(date);
}

function formatSubmissionAge(value, now = Date.now()) {
  const date = parseSubmissionTime(value);
  if (!date) return 'Not recorded';
  let seconds = Math.max(0, Math.floor((now - date.getTime()) / 1000));
  const days = Math.floor(seconds / 86400);
  seconds %= 86400;
  const hours = Math.floor(seconds / 3600);
  seconds %= 3600;
  const minutes = Math.floor(seconds / 60);
  seconds %= 60;
  return `${days ? `${days}d ` : ''}${String(hours).padStart(2, '0')}h ` +
    `${String(minutes).padStart(2, '0')}m ${String(seconds).padStart(2, '0')}s`;
}

if (typeof module !== 'undefined') {
  module.exports = { parseSubmissionTime, formatSubmittedAt, formatSubmittedDate, formatSubmissionAge };
}
