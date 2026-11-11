import recognizedDomains from '../data/recognized-email-domains.json';

const EMAIL_REGEX = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;
const PH_PHONE_REGEX =
  /^(09\d{9}|\+639\d{9}|02\d{7,8}|\+632\d{7,8}|0[3-8]\d{8}|\+63[3-8]\d{8}|[78]\d{7})$/;
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
  const clean = String(value || '').replace(/[\s\-()]/g, '').trim();
  if (!clean) return 'Mobile or telephone number is required.';
  if (!PH_PHONE_REGEX.test(clean)) {
    return 'Use a valid PH mobile (e.g. 09171234567) or telephone number (e.g. (02) 8123-4567).';
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
