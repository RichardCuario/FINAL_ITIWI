const fs = require('node:fs');
const path = require('node:path');

const documentPath = path.join(__dirname, '..', 'docs', 'DATA_DICTIONARY_APPENDIX.md');
const outputDirectory = path.join(__dirname, '..', 'docs', 'data_dictionary_images');
const source = fs.readFileSync(documentPath, 'utf8');
const lines = source.split(/\r?\n/);
const tables = [];
let section = 'Data Dictionary';

for (let index = 0; index < lines.length; index += 1) {
  const heading = lines[index].match(/^#{2,3}\s+(.+)$/);
  if (heading) section = heading[1].replaceAll('`', '');

  if (!lines[index].startsWith('| Field Name | Data Type | Description |')) continue;

  const rows = [];
  index += 2;
  while (index < lines.length && lines[index].startsWith('|')) {
    rows.push(lines[index].slice(1, -1).split('|').map((cell) => cell.trim()));
    index += 1;
  }
  index -= 1;

  const sectionNumber = section.match(/A\.\d+(?:\.\d+)?/)?.[0] ?? 'A';
  const slug = section
    .replace(/^A\.\d+(?:\.\d+)?\s*/, '')
    .replace(/`/g, '')
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '_')
    .replace(/^_|_$/g, '');
  tables.push({
    title: section,
    fileName: `${sectionNumber.replaceAll('.', '_')}_${slug || 'table'}.svg`,
    rows,
  });
}

const physicalTables = [];
const appointmentSpecificFields = [
  {
    tableName: 'public.birth_certificate_appointments',
    serviceName: 'Birth Certificate',
    fields: [['full_name', 'text', 'Full name of the applicant or record owner.']],
  },
  {
    tableName: 'public.marriage_certificate_appointments',
    serviceName: 'Marriage Certificate',
    fields: [
      ['husband_name', 'text', "Husband's full name."],
      ['wife_name', 'text', "Wife's full name."],
    ],
  },
  {
    tableName: 'public.death_certificate_appointments',
    serviceName: 'Death Certificate',
    fields: [
      ['deceased_full_name', 'text', 'Full name of the deceased person.'],
      ['date_of_death', 'text', 'Date of death as entered in the request.'],
      ['place_of_death', 'text', 'Place where the death occurred.'],
      ['requestor_full_name', 'text', 'Full name of the person submitting the request.'],
    ],
  },
  {
    tableName: 'public.cenodeath_appointments',
    serviceName: 'CENODEATH (Certificate of No Death)',
    fields: [['full_name', 'text', 'Full name of the person for whom the certificate is requested.']],
  },
];

const transparencyTables = [
  'public.transparency_annual_budget',
  'public.transparency_bids_projects',
  'public.transparency_executive_orders',
  'public.transparency_financial_reports',
  'public.transparency_legislative_ordinances',
  'public.transparency_programs_projects',
];

const sharedAppointmentTable = tables.find((table) => table.title.includes('Shared appointment fields'));
const serviceSpecificTable = tables.find((table) => table.title.includes('Service-specific fields'));
const sharedTransparencyTable = tables.find((table) => table.title.includes('Shared transparency record fields'));
const placesTable = tables.find((table) => table.title.includes('Tourist Destinations'));
const reviewsTable = tables.find((table) => table.title.includes('Destination Reviews'));

for (const table of tables) {
  if (
    table === sharedAppointmentTable ||
    table === serviceSpecificTable ||
    table === sharedTransparencyTable ||
    table === placesTable ||
    table === reviewsTable
  ) continue;

  physicalTables.push(table);
}

if (sharedAppointmentTable && serviceSpecificTable) {
  const rows = sharedAppointmentTable.rows.map((row) => [...row]);
  const serviceRow = rows.find((row) => row[0] === '`service_name`');
  if (serviceRow) {
    serviceRow[2] += ` Values: ${appointmentSpecificFields.map((appointment) => appointment.serviceName).join('; ')}.`;
  }
  rows.push(...serviceSpecificTable.rows);
  physicalTables.push({
    title: 'Online Services: Certificate Appointments',
    fileName: 'online_service_appointments.svg',
    rows,
  });
}

if (sharedTransparencyTable) {
  physicalTables.push({
    title: 'Transparency Records: Shared Schema',
    fileName: 'transparency_records.svg',
    rows: sharedTransparencyTable.rows,
  });
}

if (placesTable && reviewsTable) {
  const namespaceFields = (table, namespace) => table.rows.map((row) => [
    `\`${namespace}.${row[0].replaceAll('`', '')}\``,
    row[1],
    row[2],
  ]);
  physicalTables.push({
    title: 'Tourist Features: Destinations and Reviews',
    fileName: 'tourist_features.svg',
    rows: [
      ...namespaceFields(placesTable, 'places'),
      ...namespaceFields(reviewsTable, 'place_reviews'),
    ],
  });
}

function escapeXml(value) {
  return String(value)
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');
}

function wrapText(value, maxCharacters) {
  const words = String(value).split(/\s+/);
  const lines = [];
  let current = '';

  for (const word of words) {
    const next = current ? `${current} ${word}` : word;
    if (next.length > maxCharacters && current) {
      lines.push(current);
      current = word;
    } else {
      current = next;
    }
  }
  if (current) lines.push(current);
  return lines.length ? lines : [''];
}

function renderTable({ title, rows }) {
  const width = 1320;
  const margins = 20;
  const columns = [250, 210, 820];
  const lineHeight = 20;
  const headerHeight = 38;
  const titleHeight = 52;
  const rowData = rows.map((row) => [
    wrapText(row[0], 28),
    wrapText(row[1], 23),
    wrapText(row[2], 98),
  ]);
  const rowHeights = rowData.map((cells) => Math.max(42, ...cells.map((cell) => cell.length * lineHeight + 16)));
  const height = titleHeight + headerHeight + rowHeights.reduce((sum, value) => sum + value, 0) + margins * 2;
  const parts = [
    `<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${height}" viewBox="0 0 ${width} ${height}">`,
    '<rect width="100%" height="100%" fill="#ffffff"/>',
    `<text x="${width / 2}" y="38" text-anchor="middle" font-family="Arial, sans-serif" font-size="23" font-weight="700" fill="#111111">${escapeXml(title)}</text>`,
  ];

  let y = titleHeight;
  const headers = ['Field Name', 'Data Type', 'Description'];
  let x = margins;
  headers.forEach((header, index) => {
    parts.push(`<rect x="${x}" y="${y}" width="${columns[index]}" height="${headerHeight}" fill="#a6a6a6" stroke="#b8b8b8"/>`);
    parts.push(`<text x="${x + 8}" y="${y + 25}" font-family="Arial, sans-serif" font-size="16" font-weight="700" fill="#111111">${header}</text>`);
    x += columns[index];
  });
  y += headerHeight;

  rowData.forEach((cells, rowIndex) => {
    const rowHeight = rowHeights[rowIndex];
    const fill = rowIndex % 2 === 0 ? '#f2f2f2' : '#ffffff';
    x = margins;
    cells.forEach((cellLines, columnIndex) => {
      parts.push(`<rect x="${x}" y="${y}" width="${columns[columnIndex]}" height="${rowHeight}" fill="${fill}" stroke="#c8c8c8"/>`);
      cellLines.forEach((line, lineIndex) => {
        parts.push(`<text x="${x + 8}" y="${y + 22 + lineIndex * lineHeight}" font-family="Arial, sans-serif" font-size="15" fill="#111111">${escapeXml(line)}</text>`);
      });
      x += columns[columnIndex];
    });
    y += rowHeight;
  });

  parts.push('</svg>');
  return parts.join('\n');
}

fs.mkdirSync(outputDirectory, { recursive: true });
for (const file of fs.readdirSync(outputDirectory).filter((name) => name.endsWith('.svg'))) {
  fs.unlinkSync(path.join(outputDirectory, file));
}
for (const table of physicalTables) {
  fs.writeFileSync(path.join(outputDirectory, table.fileName), renderTable(table), 'utf8');
}

const index = [
  '# Data Dictionary Table Images',
  '',
  'SVG renderings use the editable three-column tables in [DATA_DICTIONARY_APPENDIX.md](DATA_DICTIONARY_APPENDIX.md) as their source.',
  '',
];
for (const table of physicalTables) {
  const imagePath = `data_dictionary_images/${table.fileName}`;
  index.push(`## ${table.title}`, '', `![${table.title}](${imagePath})`, '');
}
fs.writeFileSync(path.join(__dirname, '..', 'docs', 'DATA_DICTIONARY_IMAGES.md'), `${index.join('\n')}\n`, 'utf8');
console.log(`Rendered ${physicalTables.length} table images to docs/data_dictionary_images/.`);