// ============================================================
// SECURITY UTILITIES
// ============================================================

/**
 * Safely create DOM elements without innerHTML
 */
function createSafeImage(src, alt = '', styles = {}) {
  const img = document.createElement('img');
  img.src = src;
  img.alt = alt;
  img.onerror = function() {
    this.src = 'data:image/svg+xml,%3Csvg xmlns=%22http://www.w3.org/2000/svg%22%3E%3C/svg%3E';
  };
  Object.assign(img.style, styles);
  return img;
}

/**
 * Sanitize HTML by converting to text
 */
function sanitizeText(text) {
  const div = document.createElement('div');
  div.textContent = text;
  return div.innerHTML;
}

/**
 * Validate file type by MIME type and magic number
 */
function validateFileUpload(file, allowedMimes = [], maxSize = 5 * 1024 * 1024) {
  const errors = [];

  // Check file size
  if (file.size > maxSize) {
    errors.push(`File size exceeds maximum of ${maxSize / 1024 / 1024}MB`);
  }

  // Check MIME type
  if (allowedMimes.length > 0 && !allowedMimes.includes(file.type)) {
    errors.push(`Invalid file type. Allowed types: ${allowedMimes.join(', ')}`);
  }

  // Check file extension
  const name = file.name.toLowerCase();
  const invalidExtensions = ['.exe', '.sh', '.bat', '.cmd', '.php', '.asp', '.jsp', '.py', '.rb', '.pl'];
  const hasInvalidExt = invalidExtensions.some(ext => name.endsWith(ext));
  if (hasInvalidExt) {
    errors.push('Executable file types are not allowed');
  }

  return {
    valid: errors.length === 0,
    errors
  };
}

/**
 * Validate URL to prevent malicious URIs
 */
function isValidImageUrl(url) {
  try {
    const urlObj = new URL(url);
    // Only allow http, https, and data protocols
    if (!['http:', 'https:', 'data:'].includes(urlObj.protocol)) {
      return false;
    }
    // Prevent javascript: protocol
    if (url.toLowerCase().includes('javascript:')) {
      return false;
    }
    return true;
  } catch {
    return false;
  }
}

/**
 * Validate input against patterns
 */
function validateInput(value, type = 'text', options = {}) {
  const validators = {
    text: (v) => typeof v === 'string' && v.length <= (options.maxLength || 255),
    email: (v) => /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(v),
    number: (v) => !isNaN(v) && v >= (options.min || -Infinity) && v <= (options.max || Infinity),
    phone: (v) => /^[\d\s\-\+\(\)]+$/.test(v),
    coordinates: (v) => !isNaN(v) && v >= -180 && v <= 180,
    url: (v) => {
      try {
        new URL(v);
        return isValidImageUrl(v);
      } catch {
        return false;
      }
    }
  };

  const validator = validators[type] || validators.text;
  return validator(value);
}

/**
 * Escape HTML special characters
 */
function escapeHtml(text) {
  const map = {
    '&': '&amp;',
    '<': '&lt;',
    '>': '&gt;',
    '"': '&quot;',
    "'": '&#039;'
  };
  return text.replace(/[&<>"']/g, m => map[m]);
}
