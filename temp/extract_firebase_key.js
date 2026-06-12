const fs = require('fs');

const sourcePath = '..\\Downloads\\itiwi-c7340-firebase-adminsdk-fbsvc-8ced05dc57.json';
const outputPath = 'temp\\firebase_private_key_correct.txt';

const data = JSON.parse(fs.readFileSync(sourcePath, 'utf8'));
fs.writeFileSync(outputPath, data.private_key, 'utf8');
console.log('wrote', outputPath);
