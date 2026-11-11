const EMAIL_REGEX = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;
const PH_PHONE_REGEX = /^(09\d{9}|\+639\d{9})$/;

/**
 * Strips leading/trailing whitespace and removes angle brackets, quotes, and control chars
 * to prevent stored XSS and malformed data.
 */
export function sanitizeText(value = '') {
  return String(value)
    .trim()
    .replace(/[<>"']|[\x00-\x1F\x7F]/g, '');
}

export function validateName(value, label = 'Name', minLen = 2, maxLen = 60) {
  const clean = sanitizeText(value);
  if (!clean) return `${label} is required.`;
  if (clean.length < minLen) return `${label} must be at least ${minLen} characters.`;
  if (clean.length > maxLen) return `${label} must be at most ${maxLen} characters.`;
  return null;
}

export function validateEmail(value) {
  const clean = String(value || '').trim();
  if (!clean) return 'Email address is required.';
  if (clean.length > 100) return 'Email address is too long (max 100 characters).';
  if (!EMAIL_REGEX.test(clean)) return 'Please enter a valid email address.';
  return null;
}

export function validatePhPhone(value) {
  const clean = String(value || '').replace(/[\s\-()]/g, '').trim();
  if (!clean) return 'Mobile number is required.';
  if (!PH_PHONE_REGEX.test(clean)) {
    return 'Use a valid PH mobile number (e.g. 09171234567 or +639171234567).';
  }
  return null;
}

export function validateStrongPassword(value) {
  const pass = String(value || '');
  if (!pass) return 'Password is required.';
  if (pass.length < 8) return 'Password must be at least 8 characters.';
  if (pass.length > 64) return 'Password must be at most 64 characters.';
  if (!/[A-Z]/.test(pass)) return 'Password must contain at least 1 uppercase letter.';
  if (!/[0-9]/.test(pass)) return 'Password must contain at least 1 number.';
  if (!/[!@#$%^&*(),.?":{}|<>_\-+=~`]/.test(pass)) {
    return 'Password must contain at least 1 symbol (e.g. @, #, $, !).';
  }
  return null;
}

export function validatePositiveInt(value, min = 1, max = 10000, label = 'Quantity') {
  const num = Number(value);
  if (!Number.isInteger(num) || num < min || num > max) {
    return `${label} must be a whole number between ${min} and ${max}.`;
  }
  return null;
}

export function validatePositivePrice(value, min = 1, max = 50000, label = 'Price') {
  const num = Number(value);
  if (Number.isNaN(num) || num < min || num > max) {
    return `${label} must be between ${min} and ${max}.`;
  }
  return null;
}
