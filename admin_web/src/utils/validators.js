import recognizedDomains from '../data/recognized-email-domains.json';

const EMAIL_REGEX = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;
const PH_PHONE_REGEX =
  /^(?:(?:0|\+?63)9\d{9}|(?:0|\+?63)2\d{7,8}|(?:0|\+?63)[3-8]\d{8}|[78]\d{7})$/;
const NAME_CHAR_REGEX = /^[A-Za-zÀ-ÖØ-öø-ÿÑñ\s.'-]+$/;
const SPECIAL_CHAR_REGEX = /[!@#$%^&*(),.?":{}|<>_\-+=~`]/;

const GENERIC_CATCHALL_SUFFIXES = new Set([
  '.com',
  '.net',
  '.org',
  '.biz',
  '.io',
  '.co',
  '.tech',
  '.company',
]);

const EXACT_PROVIDERS = new Set([
  'charcoal.com',
  ...(recognizedDomains.public_email_providers || []).map((d) => d.toLowerCase()),
  ...(recognizedDomains.regional_and_isp_providers || []).map((d) => d.toLowerCase()),
]);

const ORG_SUFFIXES = Object.values(recognizedDomains.organization_domain_patterns || {})
  .flat()
  .map((pattern) => pattern.replace(/^\*/, '').toLowerCase())
  .filter((suffix) => !GENERIC_CATCHALL_SUFFIXES.has(suffix))
  .sort((a, b) => b.length - a.length);

const BLOCKED_DOMAINS = new Set([
  'mailinator.com',
  'tempmail.com',
  'temp-mail.org',
  'guerrillamail.com',
  '10minutemail.com',
  'yopmail.com',
  'trashmail.com',
  'sharklasers.com',
  'getnada.com',
  'dispostable.com',
  'fakeinbox.com',
  'maildrop.cc',
  'throwawaymail.com',
  'gmai.com',
  'gmil.com',
  'gmaill.com',
  'gmial.com',
  'gnail.com',
  'yaho.com',
  'yahooo.com',
  'hotmal.com',
  'outlok.com',
  'example.com',
  'example.org',
  'example.net',
]);

const BLOCKED_SUFFIXES = ['.con', '.cmo', '.invalid', '.local', '.localhost', '.test'];

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
  if (!NAME_CHAR_REGEX.test(clean)) {
    return `${label} may only contain letters, spaces, periods, hyphens, and apostrophes.`;
  }
  return null;
}

export function validateEmail(value) {
  const clean = String(value || '').trim();
  if (!clean) return 'Email address is required.';
  if (clean.length > 100) return 'Email address is too long (max 100 characters).';
  if (!EMAIL_REGEX.test(clean)) return 'Please enter a valid email address.';

  const domain = clean.split('@').pop().toLowerCase();
  if (!domain || domain.includes('*') || domain.includes('..')) {
    return 'Invalid email domain format.';
  }
  if (BLOCKED_SUFFIXES.some((s) => domain.endsWith(s)) || BLOCKED_DOMAINS.has(domain)) {
    return `Unrecognized or disposable email domain ("${domain}").`;
  }
  if (EXACT_PROVIDERS.has(domain)) return null;
  for (const suffix of ORG_SUFFIXES) {
    if (domain.endsWith(suffix) && domain.length > suffix.length) {
      return null;
    }
  }
  return `Email domain "${domain}" is not a recognized provider or organization domain.`;
}

export function validatePhPhone(value) {
  const clean = String(value || '').replace(/\D/g, '');
  if (!clean) return 'Mobile or telephone number is required.';
  if (!PH_PHONE_REGEX.test(clean)) {
    return 'Use a valid PH mobile (e.g. 09171234567) or telephone number (e.g. 0281234567).';
  }
  return null;
}

export function checkPasswordRequirements(value, confirmValue = null) {
  const pass = String(value || '');
  return {
    hasMinLength: pass.length >= 8 && pass.length <= 64,
    hasUppercase: /[A-Z]/.test(pass),
    hasNumber: /[0-9]/.test(pass),
    hasSpecialChar: SPECIAL_CHAR_REGEX.test(pass),
    passwordsMatch: confirmValue !== null && pass.length > 0 && pass === String(confirmValue),
  };
}

export function validateStrongPassword(value) {
  const pass = String(value || '');
  if (!pass) return 'Password is required.';
  if (pass.length < 8) return 'Password must be at least 8 characters.';
  if (pass.length > 64) return 'Password must be at most 64 characters.';
  if (!/[A-Z]/.test(pass)) return 'Password must contain at least 1 uppercase letter.';
  if (!/[0-9]/.test(pass)) return 'Password must contain at least 1 number.';
  if (!SPECIAL_CHAR_REGEX.test(pass)) {
    return 'Password must contain at least 1 special character (e.g. @, #, $, !).';
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

/**
 * Strips all non-digit characters and caps length (used for phone numbers & integer inputs).
 */
export function formatDigitsOnly(value = '', maxLen = 12) {
  return String(value).replace(/\D/g, '').slice(0, maxLen);
}

/**
 * Filters numeric input to digits and at most one decimal point with bounded decimal places.
 */
export function formatDecimalInput(value = '', maxDecimals = 2, maxLen = 10) {
  const cleaned = String(value).replace(/[^0-9.]/g, '');
  const parts = cleaned.split('.');
  const intPart = parts[0] || '';
  if (parts.length === 1) {
    return intPart.slice(0, maxLen);
  }
  const decPart = parts.slice(1).join('').slice(0, maxDecimals);
  return `${intPart}.${decPart}`.slice(0, maxLen);
}

/**
 * Auto-formats Philippine LTO plate numbers:
 * uppercase alphanumeric only, automatically inserting '-' at the first letter<->digit boundary
 * (e.g., abc1234 -> ABC-1234, 7821ab -> 7821-AB, ab12345 -> AB-12345).
 */
export function formatPlateNumber(value = '') {
  const raw = String(value)
    .toUpperCase()
    .replace(/[^A-Z0-9]/g, '')
    .slice(0, 8);
  if (raw.length < 2) return raw;
  const isFirstAlpha = /^[A-Z]/.test(raw);
  const boundary = isFirstAlpha ? raw.search(/[0-9]/) : raw.search(/[A-Z]/);
  if (boundary > 0) {
    return `${raw.slice(0, boundary)}-${raw.slice(boundary)}`;
  }
  return raw;
}

/**
 * Validates optional Philippine plate number when provided.
 */
export function validatePlateNumber(value = '') {
  const raw = String(value || '')
    .toUpperCase()
    .replace(/[^A-Z0-9]/g, '');
  if (!raw) return null; // Optional
  if (raw.length < 5 || raw.length > 8) {
    return 'Plate number must be 5–8 letters/numbers (e.g. ABC-1234 or 7821-AB).';
  }
  if (!/[A-Z]/.test(raw) || !/[0-9]/.test(raw)) {
    return 'Plate number must contain both letters and numbers (e.g. ABC-1234).';
  }
  return null;
}
