# Firebase Cloud Functions - Deployment Guide

This directory contains the Cloud Function that syncs Firebase users to Supabase.

## Quick Deploy (Windows)

```bash
cd firebase_functions
deploy.bat
```

The script will automatically:
1. Install dependencies
2. Configure Supabase credentials
3. Deploy the functions

---

## Manual Deployment Steps

If the script doesn't work, follow these steps:

### Prerequisites
- Node.js 18+ installed
- Firebase CLI installed (`npm install -g firebase-tools`)
- Logged in to Firebase (`firebase login`)

### Step 1: Install Dependencies

```bash
cd firebase_functions
npm install
```

### Step 2: Configure Supabase Credentials

Run these commands (paste exactly):

```bash
firebase functions:config:set supabase.url="https://jbhlbukxankrtcwhqoll.supabase.co"

firebase functions:config:set supabase.key="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpiaGxidWt4YW5rcnRjd2hxb2xsIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3NDQ3MDE4OCwiZXhwIjoyMDkwMDQ2MTg4fQ.IzVTOEgPim0sNNZMzLtvLjJlf5HHZxVXYg9OCRnuEyI"
```

You should see output like:
```
✔  Functions config updated.
```

### Step 3: Deploy

```bash
firebase deploy --only functions
```

Wait for completion. You'll see:
```
✔  Deploy complete!
```

---

## Verify Deployment

1. Go to **Firebase Console** → **Functions**
2. You should see two functions:
   - `syncUserOnSignUp` (Trigger: Cloud Pub/Sub)
   - `updateUserLoginTime` (Trigger: HTTPS)

3. Test by creating a new user in Firebase Auth
4. Check **Supabase** → **Table Editor** → **users** table
5. New user should appear automatically

---

## Troubleshooting

### "Cannot find module 'firebase-admin'"
```bash
npm install
```

### "No project active"
```bash
firebase use your-project-id
# or
firebase init
```

### Functions not triggering
- Check Firebase Functions logs: `firebase functions:log`
- Verify Supabase Service Role Key is correct
- Ensure `users` table exists in Supabase

### Permission denied error
- Supabase Service Role Key might be wrong
- Check that the key starts with `eyJhbGciOi...`
