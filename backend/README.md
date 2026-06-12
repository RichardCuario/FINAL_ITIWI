# Quick Start Guide - Backend API

## Setup (5 minutes)

### 1️⃣ Get Firebase Service Account Key

1. Go to Firebase Console: https://console.firebase.google.com
2. Select project **itiwi-c7340**
3. Click ⚙️ (Settings) → **Service Accounts**
4. Click **Generate New Private Key**
5. Save the JSON file as `serviceAccountKey.json` in this folder (`backend/`)

**⚠️ IMPORTANT: Keep this file secret! Add to .gitignore (already done)**

### 2️⃣ Install Dependencies

```bash
cd backend
npm install
```

### 3️⃣ Run the Server

```bash
npm start
```

You should see:
```
✅ Server running on http://localhost:5000
📊 Get user count: http://localhost:5000/api/user-count
👥 Get all users: http://localhost:5000/api/users
```

### 4️⃣ Test It

Open in your browser:
- **Health check:** http://localhost:5000/api/health
- **User count:** http://localhost:5000/api/user-count
- **All users:** http://localhost:5000/api/users

---

## File Structure

```
backend/
├── server.js                 # Main backend code
├── package.json             # Dependencies
├── .env                     # Environment variables
├── .gitignore              # Git ignore rules
└── serviceAccountKey.json  # Firebase credentials (KEEP SECRET!)
```

---

## API Endpoints

### GET /api/user-count
Returns count of all Firebase Auth users

**Response:**
```json
{
  "success": true,
  "userCount": 15,
  "timestamp": "2024-06-07T10:30:00.000Z"
}
```

### GET /api/users
Returns detailed list of all users (for debugging)

**Response:**
```json
{
  "success": true,
  "total": 15,
  "users": [
    {
      "uid": "firebase-uid-123",
      "email": "user@example.com",
      "displayName": "John Doe",
      "creationTime": "2024-06-01T10:00:00Z",
      "lastSignInTime": "2024-06-07T09:30:00Z"
    }
  ]
}
```

### GET /api/health
Health check

**Response:**
```json
{
  "status": "Backend is running"
}
```

---

## Troubleshooting

### ❌ "Cannot find module 'firebase-admin'"
```bash
npm install
```

### ❌ "serviceAccountKey.json not found"
Download it from Firebase Console → Project Settings → Service Accounts

### ❌ Port 5000 already in use
Change PORT in .env file or kill the process using port 5000

### ❌ Still getting 0 users on dashboard?
1. Make sure backend is running: `npm start`
2. Check the URL in adminside/app.js matches your backend URL
3. Open http://localhost:5000/api/user-count in browser to test

---

## Keep Running in Background

**Windows:**
- Use a terminal multiplexer or keep cmd window open

**Mac/Linux:**
```bash
nohup npm start &
```

---

## Next Steps

✅ Backend running locally  
✅ Admin dashboard calling backend  
✅ User count displaying in real-time  

When ready to deploy, follow the guide in `BACKEND_USER_COUNT_API.md` Step 9.
