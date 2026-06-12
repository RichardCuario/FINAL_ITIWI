const admin = require('firebase-admin');
const { createClient } = require('@supabase/supabase-js');

// Initialize Firebase Admin
function initFirebase() {
  if (admin.apps.length > 0) return admin;
  
  const serviceAccount = {
    type: "service_account",
    project_id: "itiwi-c7340",
    private_key_id: "a49b6065f4a4cb7fbbc7eea49d4310413798d52a",
    private_key: process.env.FIREBASE_PRIVATE_KEY 
      ? process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n')
      : "-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDc7zwl9SSN+LX8\nQoulqhmGacXbDbP9SG1Xz/ML7l4ZbOymDQo2TYaQXiEMxPMbdpRB+b6IhgpT6wLT\nPYBkWcvCY/h5+Rlh9jDvqPeRbSuqHitScdALgtCns6kltuwwZrzfsAhXzckcX1ND\nXvVS3Mm3avpTWBmFt+VGkpYEnfOPNd09OfJX1ClyntqPc7EONL4wtqejwoZlkjDg\np/5dc43FIFu0tyLIdixm+odUqr1LWElktTaOTx5E9phe7AD5XP3A3usU6YxNx7T6\nm44ADBTjO0I4RUglQo6HFQb2SrVpWAmB3z1+atdOfw1K7UgPIu7Oxrh63O+llcG/\nhcRh9h0dAgMBAAECggEAOC72Ysi2ZQwsa1wY2yYom4/matBPR0fV1pDhQ9V4RIr4\nmzmRsUGByNDHItIq6H79MNHr7Bf6JGENNN7c+agEMwjtNUdtdwX+Z9PWMTtL8VT+\nu1aKC4NWwG7lwtuDsMNPoKrJVFrWm8p6CBXr2Qigm24u/mbXBrQ/L/UzBTWNrIsT\nACQ+MyPGZgaNK2zW2xXndpv+ntn2Imldg1Jzl2iXA4e2XKs3jZhBxRkgKU+/h6XG\ngUbOuoD7RusjAN6K3fnUInr541XowqaI0ai9EWjbkMCNe0Bkh7M0tPtYyfQqq1On\n9eCOIdOTGL77l4hYk6+f+cQvEIK91pf4bkBDWUqfWQKBgQD5rYPLnXVm167RGEzA\nX0C0jS+ilU60VR96inMIfz1BuwWmBZlbQz2jtcpBxK+H0bKJL20bAMGoOtYAs98w\nt/N9bsvuR8hqPoQiGv6E2oDUyJa8sZzMtWWeyGQVwiBs06hn86fKfIPbH4YNccUY\n0HwzSR8LajColU5mcL5WbfGB+wKBgQDih2XPXcbZzYVawRE3SC3YuQKH6ngLgdkL\nuzAnZI2hiOkQ29pXxlpObINKt4VZbaVpGOfjf01pI1+x70nz6jbusn21F9i4vRhz\nAznjHIs0Z8BKPK7v3naoxqWryNdbfG2fQjRQxzLSVhRd6KQ0WA3946jUp3Sqs+cn\nG+Td2MTJxwKBgEvApXglsfUeA2BVaxQC0nL1UzqU6mg0W3SmhPhTApbq02/nyvux\njwYYpeEGd+tRaEXPKd9Df343O67C5Di31xx7fUwyY1A434Ypgod0dBobMgDWMqi5\ncLeYPSWM3KGoJjRD7Oi2lprpGZcCqbY5qzU0PkMMWO8NPdg+5MD8YoX5AoGBALd8\nLH8W2ma5DfdAww0gLeKJmP82cB4CAyh5aru9uurI1t+M9QJ769HyGzZ+CEkzgvPp\n9IpVJwKuYGjkBebII86cTS5OLoEUyaT/S/gluqusDhkTpi8s5rg2jyLh/25fDvwc\nx/tWHlg42S5nrfmoCU1JBguZx+os5mLLOUpotp0pAoGBAOTLHfFQ6T+pfFkwP6Dw\nvk1kagy5ZGogoEzwoabQwvL76ozo1H9Wwb7gjTwPfrwe6b+yFWsXI0V0q/QfRGnq\nzp2JtuveQEd1gJF4jIM/HeZLEoVDCvF1b5BEXale1o48nTtBtR5CqkfbxgdD3nO7\nVpZh6nwwDZrmuR0+D88SUZZu\n-----END PRIVATE KEY-----\n",
    client_email: "firebase-adminsdk-fbsvc@itiwi-c7340.iam.gserviceaccount.com",
    client_id: "113314869250418353546",
    auth_uri: "https://accounts.google.com/o/oauth2/auth",
    token_uri: "https://oauth2.googleapis.com/token",
    auth_provider_x509_cert_url: "https://www.googleapis.com/oauth2/v1/certs",
    client_x509_cert_url: "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-fbsvc%40itiwi-c7340.iam.gserviceaccount.com",
    universe_domain: "googleapis.com"
  };

  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    projectId: 'itiwi-c7340'
  });

  return admin;
}

// Initialize Supabase
function initSupabase() {
  const supabaseUrl = process.env.SUPABASE_URL || 'https://jbhlbukxankrtcwhqoll.supabase.co';
  const supabaseKey = process.env.SUPABASE_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpiaGxidWt4YW5rcnRjd2hxb2xsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ0NzAxODgsImV4cCI6MjA5MDA0NjE4OH0.DebtVdw7bF5nRaXQg8Ta2SsO2Qv42QnGSzoS8hT2vJc';
  return createClient(supabaseUrl, supabaseKey);
}

module.exports = { initFirebase, initSupabase };
