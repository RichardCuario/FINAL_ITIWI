# SECURITY IMPLEMENTATION GUIDE - iTIWI Admin Dashboard

**Date Created:** 2026-06-13  
**Status:** IN PROGRESS - Critical fixes applied

---

## ✅ COMPLETED SECURITY FIXES

### 1. **API Key Exposure - URGENT FIX NEEDED**
**Status:** ⚠️ MANUAL ACTION REQUIRED

**What was done:**
- Created `.env.example` file as template
- Added `.env.local` to `.gitignore` to prevent committing secrets

**What YOU NEED TO DO IMMEDIATELY:**

1. **Rotate the exposed Supabase key:**
   - Go to Supabase Dashboard → Settings → API Keys
   - Regenerate the `anon` key
   - The old key is now compromised!

2. **Set up environment variables on Vercel:**
   ```
   VITE_SUPABASE_URL=your_new_url
   VITE_SUPABASE_ANON_KEY=your_new_key
   ```

3. **For local development:**
   - Create `adminside/.env.local`:
   ```
   VITE_SUPABASE_URL=your_supabase_url
   VITE_SUPABASE_ANON_KEY=your_supabase_key
   ```
   - Add `.env.local` to `.gitignore` (✅ DONE)

4. **Update app.js:**
   - Replace hardcoded keys with environment variables
   - Use config loading instead of inline values

**Timeline:** MUST BE DONE TODAY

---

### 2. **File Upload Validation - ✅ PARTIALLY DONE**
**Status:** ⚠️ NEEDS COMPLETION

**Completed:**
- ✅ Created `security-utils.js` with `validateFileUpload()` function
- ✅ Added validation to news upload
- ✅ Checks for: file type, file size, dangerous extensions

**Still needs file validation:**
- Accomplishment files upload (app.js line 3238)
- Logo uploads (lines 2823-2861)
- Transparency PDF upload

**To complete:** Add similar validation to remaining upload functions:
```javascript
// Example from news upload (now secure):
const validation = validateFileUpload(file, ['image/jpeg', 'image/png', 'image/webp', 'image/gif'], 5 * 1024 * 1024);
if (!validation.valid) {
  showToast('File upload error: ' + validation.errors.join(', '), 'error');
  return;
}
```

---

### 3. **XSS Prevention - ✅ FRAMEWORK CREATED**
**Status:** ⚠️ NEEDS IMPLEMENTATION

**Completed:**
- ✅ Created `security-utils.js` with sanitization functions:
  - `createSafeImage()` - safely create image elements
  - `sanitizeText()` - convert to plain text
  - `escapeHtml()` - escape special characters
  - `isValidImageUrl()` - validate URLs
  - `validateInput()` - validate various input types

**Still needs XSS fixes at these locations:**
- Line 1549: Preview images - Use `createSafeImage()` instead of `innerHTML`
- Line 2149: News preview - Use `createSafeImage()` instead of `innerHTML`
- Line 2182: File preview - Use `createSafeImage()` instead of `innerHTML`
- Line 2599: Report files - Use `sanitizeText()` for names

**Example fix:**
```javascript
// ❌ UNSAFE (current):
preview.innerHTML = `<img src="${data.logo_url}" alt="logo">`;

// ✅ SAFE (use this):
preview.innerHTML = '';
preview.appendChild(createSafeImage(data.logo_url, 'logo', { maxWidth: '200px' }));
```

---

### 4. **Input Validation - ✅ UTILITIES CREATED**
**Status:** ⚠️ NEEDS IMPLEMENTATION

**Completed:**
- ✅ Created validation functions in `security-utils.js`:
  - Text validation (length limits)
  - Email validation
  - Phone validation
  - Coordinate validation (lat/long)
  - URL validation
  - Number validation (with min/max)

**Implementation needed at:**
- Barangay form: coordinates validation
- Tourist destinations: all fields
- News: title, description
- All text inputs: add max length checks

**Example usage:**
```javascript
// Validate before saving
const title = document.getElementById('barangayName').value.trim();
if (!validateInput(title, 'text', { maxLength: 100 })) {
  showToast('Invalid barangay name', 'error');
  return;
}
```

---

## 📋 REMAINING CRITICAL FIXES

### HIGH PRIORITY (This week)

#### 1. **Remove Hardcoded API Keys**
**File:** `app.js` lines 5-7

**Current:**
```javascript
const SUPABASE_URL = 'https://...'; // EXPOSED!
const SUPABASE_ANON_KEY = 'eyJh...'; // EXPOSED!
```

**Fix:**
```javascript
// Load from environment variables or config
const SUPABASE_URL = window.ENV?.SUPABASE_URL || localStorage.getItem('SUPABASE_URL');
const SUPABASE_ANON_KEY = window.ENV?.SUPABASE_ANON_KEY || localStorage.getItem('SUPABASE_ANON_KEY');

if (!SUPABASE_URL || !SUPABASE_ANON_KEY) {
  console.error('Supabase credentials not configured');
  window.location.href = './login.html';
}
```

---

#### 2. **Add Session Re-verification**
**File:** `app.js` lines 20-34

**Add periodic session check:**
```javascript
// Add this after initial auth check
function setupSessionValidation() {
  // Re-verify every 5 minutes
  setInterval(async () => {
    const { data, error } = await supabaseClient.auth.getSession();
    if (!data?.session || error) {
      console.warn('Session expired or invalid');
      window.location.href = './login.html';
    }
  }, 5 * 60 * 1000);
  
  // Add inactivity timeout (30 minutes)
  let inactivityTimer;
  function resetInactivityTimer() {
    clearTimeout(inactivityTimer);
    inactivityTimer = setTimeout(() => {
      handleLogout();
    }, 30 * 60 * 1000);
  }
  
  // Track user activity
  document.addEventListener('mousedown', resetInactivityTimer);
  document.addEventListener('keydown', resetInactivityTimer);
  resetInactivityTimer();
}

setupSessionValidation();
```

---

#### 3. **Add CSRF Protection**
**Recommendation:** Implement backend API endpoint that validates requests

**For now, add to all state-changing operations:**
```javascript
// Add CSRF token to all requests
const headers = {
  'Content-Type': 'application/json',
  'X-Requested-With': 'XMLHttpRequest'
};
```

---

### MEDIUM PRIORITY (Next 2 weeks)

#### 4. **Content Security Policy (CSP)**
**Add to `vercel.json`:**
```json
{
  "headers": [
    {
      "source": "/(.*)",
      "headers": [
        {
          "key": "Content-Security-Policy",
          "value": "default-src 'self'; script-src 'self' 'unsafe-inline' https://cdn.jsdelivr.net; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; font-src 'self' https://cdnjs.cloudflare.com; connect-src 'self' https://*.supabase.co"
        }
      ]
    }
  ]
}
```

---

#### 5. **Remove Console Logging**
**Affected lines:** 526, 2235, 2243, 2253, 2268, etc.

**Action:** Comment out or remove `console.log` statements in production

```javascript
// ❌ Remove or comment out:
// console.log('Updating news with ID:', editId);

// ✅ Use conditional logging:
if (process.env.NODE_ENV === 'development') {
  console.log('Debug info...');
}
```

---

#### 6. **Add Rate Limiting (Backend)**
Backend should implement rate limiting:
- 100 requests per minute per IP
- 10 failed login attempts = 15 min lockout
- Aggressive rate limiting on delete operations

---

## 🔐 SECURITY CHECKLIST

- [ ] Supabase keys rotated
- [ ] Environment variables set up on Vercel
- [ ] `.env.local` file created for development
- [ ] Hardcoded keys removed from app.js
- [ ] File upload validation added to all upload functions
- [ ] XSS prevention implemented (replace innerHTML with safe methods)
- [ ] Input validation added to all forms
- [ ] Session re-verification implemented
- [ ] CSRF protection headers added
- [ ] CSP headers configured
- [ ] Console logging removed/restricted
- [ ] Error messages sanitized (no internal details)
- [ ] File extensions whitelisted
- [ ] Rate limiting configured on backend

---

## 🚀 TESTING SECURITY FIXES

**After implementing fixes, test:**

1. **XSS Prevention:**
   - Try entering `<script>alert('XSS')</script>` in text fields
   - Try uploading SVG with embedded scripts
   - Verify no alerts/scripts execute

2. **File Upload:**
   - Try uploading `.exe`, `.sh`, `.php` files
   - Verify rejection with proper error message
   - Try large files > 5MB
   - Verify rejection

3. **Input Validation:**
   - Try entering invalid coordinates (> 180)
   - Try very long text (> 255 chars)
   - Try invalid email formats
   - Verify validation errors shown

4. **API Security:**
   - Check Network tab in DevTools
   - Verify no API keys visible
   - Verify all requests go through authenticated endpoints

---

## 📞 QUICK REFERENCE

**Security Utils Functions:**
```javascript
validateFileUpload(file, mimes, maxSize)  // Validate uploads
createSafeImage(src, alt, styles)         // Create safe images
sanitizeText(text)                        // Convert to plain text
validateInput(value, type, options)       // Validate inputs
escapeHtml(text)                          // Escape HTML chars
isValidImageUrl(url)                      // Validate URLs
```

---

## ⚠️ DO NOT COMMIT

- `.env.local` files (added to .gitignore ✅)
- API keys or secrets
- Database credentials
- Authentication tokens
- Private keys

---

**Last Updated:** 2026-06-13  
**Next Review:** After all critical fixes implemented
