const fs = require('node:fs');
const path = require('node:path');

const outputPath = path.join(__dirname, '..', 'docs', 'ITIWI_HIPO_CHART.svg');
const width = 1100;
const height = 1240;
const functionWidth = 300;
const functionHeight = 82;
const functionY = 320;
const activityY = 500;
const activityWidth = 300;
const activityHeight = 118;
const activityGap = 16;
const columns = [
  {
    name: 'Authentication',
    activities: [
      { name: 'Citizen Sign-in', detail: 'Register and sign in with Firebase or Google.' },
      { name: 'Admin Access', detail: 'Sign in with Supabase Auth and check roles.' },
      { name: 'Identity Verification', detail: 'Start Didit verification and view its status.' },
    ],
  },
  {
    name: 'Manage Data',
    activities: [
      { name: 'User Accounts', detail: 'Maintain citizen profile and account status.' },
      { name: 'Citizen Reports', detail: 'Submit, review, forward, and update reports.' },
      { name: 'Online Services', detail: 'Process Birth, Marriage, Death, and CENODEATH requests.' },
      { name: 'Public Content', detail: 'Manage news, barangays, hotlines, and public records.' },
    ],
  },
  {
    name: 'Provide Information',
    activities: [
      { name: 'News and Municipal Information', detail: 'Display announcements, barangays, and municipal profile.' },
      { name: 'Emergency Hotlines', detail: 'Provide agency contact numbers and categories.' },
      { name: 'Tourist Features', detail: 'Show destinations, maps, and visitor reviews.' },
      { name: 'Transparency Records', detail: 'Provide published public documents.' },
      { name: 'Notifications', detail: 'Deliver news, report, appointment, and verification updates.' },
    ],
  },
];

const columnX = [35, 400, 765];
const columnCenter = columnX.map((x) => x + functionWidth / 2);

function escapeXml(value) {
  return String(value)
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');
}

function wrapText(value, limit) {
  const lines = [];
  let current = '';
  for (const word of value.split(/\s+/)) {
    const candidate = current ? `${current} ${word}` : word;
    if (candidate.length > limit && current) {
      lines.push(current);
      current = word;
    } else {
      current = candidate;
    }
  }
  if (current) lines.push(current);
  return lines;
}

function renderDetail(text, x, y) {
  const lines = wrapText(text, 38);
  return `<text class="detail" x="${x}" y="${y}" text-anchor="middle">${lines
    .map((line, index) => `<tspan x="${x}" dy="${index === 0 ? 0 : 17}">${escapeXml(line)}</tspan>`)
    .join('')}</text>`;
}

const parts = [
  `<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${height}" viewBox="0 0 ${width} ${height}" role="img" aria-labelledby="chart-title chart-desc">`,
  '<title id="chart-title">iTIWI HIPO Chart</title>',
  '<desc id="chart-desc">Simple HIPO hierarchy showing the iTIWI system, three main functions, and one activity for each function.</desc>',
  '<defs><style>',
  'text{font-family:Arial,Helvetica,sans-serif;fill:#182536}.page{fill:#fff}.title{font-size:25px;font-weight:700}.root,.node{fill:#dce9fa;stroke:#8daee0;stroke-width:2}.root-label{font-size:17px;font-weight:700}.root-name{font-size:19px;font-weight:700}.function-name{font-size:20px;font-weight:700}.activity-name{font-size:16px;font-weight:700}.detail{font-size:13px;fill:#43566c}.connector{fill:none;stroke:#566576;stroke-width:2}',
  '</style></defs>',
  `<rect class="page" width="${width}" height="${height}"/>`,
  `<text class="title" x="${width / 2}" y="50" text-anchor="middle">Appendix D</text>`,
  `<text class="title" x="${width / 2}" y="84" text-anchor="middle">HIPO Chart</text>`,
  '<rect class="root" x="350" y="140" width="400" height="100" rx="13"/>',
  '<text class="root-label" x="550" y="178" text-anchor="middle">THE SYSTEM</text>',
  '<text class="root-name" x="550" y="211" text-anchor="middle">iTIWI Digital Government System</text>',
  '<path class="connector" d="M550 240 V280 M185 280 H915 M185 280 V320 M550 280 V320 M915 280 V320"/>',
];

for (let index = 0; index < columns.length; index += 1) {
  const column = columns[index];
  const x = columnX[index];
  const center = columnCenter[index];
  const spineX = x - 14;
  const lastActivityCenter = activityY + (column.activities.length - 1) * (activityHeight + activityGap) + activityHeight / 2;

  parts.push(`<path class="connector" d="M${center} ${functionY + functionHeight} V465 H${spineX} V${lastActivityCenter}"/>`);
  parts.push(`<rect class="node" x="${x}" y="${functionY}" width="${functionWidth}" height="${functionHeight}" rx="12"/>`);
  parts.push(`<text class="function-name" x="${center}" y="${functionY + 49}" text-anchor="middle">${escapeXml(column.name)}</text>`);

  column.activities.forEach((activity, activityIndex) => {
    const y = activityY + activityIndex * (activityHeight + activityGap);
    const centerY = y + activityHeight / 2;
    parts.push(`<path class="connector" d="M${spineX} ${centerY} H${x}"/>`);
    parts.push(`<rect class="node" x="${x}" y="${y}" width="${activityWidth}" height="${activityHeight}" rx="12"/>`);
    parts.push(`<text class="activity-name" x="${center}" y="${y + 38}" text-anchor="middle">${escapeXml(activity.name)}</text>`);
    parts.push(renderDetail(activity.detail, center, y + 68));
  });
}

parts.push('</svg>');
fs.writeFileSync(outputPath, `${parts.join('\n')}\n`, 'utf8');
console.log(`Generated ${path.relative(path.join(__dirname, '..'), outputPath)}.`);