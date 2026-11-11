import crypto from 'node:crypto';
import fs from 'node:fs';
import path from 'node:path';

let cachedDomainData = null;

function loadDomainData() {
  if (cachedDomainData) return cachedDomainData;
  try {
    const filePath = path.resolve(process.cwd(), 'src/data/recognized-email-domains.json');
    cachedDomainData = JSON.parse(fs.readFileSync(filePath, 'utf8'));
  } catch {
    cachedDomainData = {
      public_email_providers: ['gmail.com', 'outlook.com', 'hotmail.com', 'yahoo.com', 'icloud.com'],
      regional_and_isp_providers: ['yahoo.com.ph'],
      organization_domain_patterns: {
        education: ['*.edu', '*.edu.ph'],
        government: ['*.gov.ph'],
        organizations_nonprofits: ['*.org', '*.org.ph'],
        business_custom_domains: ['*.com', '*.com.ph', '*.net'],
      },
    };
  }
  return cachedDomainData;
}

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
  'gmial.com',
  'gnail.com',
  'yaho.com',
  'yahooo.com',
  'hotmal.com',
  'outlok.com',
]);

const BLOCKED_SUFFIXES = ['.con', '.cmo', '.invalid', '.local', '.localhost', '.test'];

export function validateEmailDomain(email) {
  const clean = String(email || '').trim().toLowerCase();
  if (!/^[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}$/.test(clean)) {
    return 'Invalid email address format.';
  }
  const domain = clean.split('@').pop();
  if (!domain || domain.includes('*') || domain.includes('..')) {
    return 'Invalid email domain format.';
  }
  if (BLOCKED_SUFFIXES.some((s) => domain.endsWith(s)) || BLOCKED_DOMAINS.has(domain)) {
    return `Unrecognized or disposable email domain ("${domain}").`;
  }

  const data = loadDomainData();
  const exactSet = new Set([
    ...(data.public_email_providers || []).map((d) => d.toLowerCase()),
    ...(data.regional_and_isp_providers || []).map((d) => d.toLowerCase()),
  ]);
  if (exactSet.has(domain)) return null;

  const patterns = Object.values(data.organization_domain_patterns || {})
    .flat()
    .map((p) => p.replace(/^\*/, '').toLowerCase())
    .sort((a, b) => b.length - a.length);

  for (const suffix of patterns) {
    if (domain.endsWith(suffix) && domain.length > suffix.length) {
      return null;
    }
  }
  return `Email domain "${domain}" is not in the recognized provider or organization list.`;
}

function getOtpSecret() {
  return process.env.OTP_SECRET || '';
}

function hashOtp(email, code) {
  return crypto
    .createHmac('sha256', getOtpSecret())
    .update(`${email.toLowerCase().trim()}:${String(code).trim()}`)
    .digest('hex');
}

export function createOtpToken(email, code, ttlMs = 10 * 60 * 1000) {
  const secret = getOtpSecret();
  if (!secret) {
    throw new Error('OTP_SECRET environment variable is not configured.');
  }
  const payload = {
    email: email.toLowerCase().trim(),
    otpHash: hashOtp(email, code),
    exp: Date.now() + ttlMs,
  };
  const encoded = Buffer.from(JSON.stringify(payload), 'utf8').toString('base64url');
  const sig = crypto.createHmac('sha256', secret).update(encoded).digest('base64url');
  return `${encoded}.${sig}`;
}

export function verifyOtpToken(token, email, code) {
  const secret = getOtpSecret();
  if (!secret) {
    return { valid: false, error: 'OTP_SECRET environment variable is not configured.' };
  }
  if (!token || !String(token).includes('.')) {
    return { valid: false, error: 'Invalid verification session. Please request a new code.' };
  }
  const [encoded, sig] = String(token).split('.');
  const expectedSig = crypto.createHmac('sha256', secret).update(encoded).digest('base64url');
  const sigBuf = Buffer.from(sig);
  const expBuf = Buffer.from(expectedSig);
  if (sigBuf.length !== expBuf.length || !crypto.timingSafeEqual(sigBuf, expBuf)) {
    return { valid: false, error: 'Verification token signature mismatch.' };
  }

  let payload;
  try {
    payload = JSON.parse(Buffer.from(encoded, 'base64url').toString('utf8'));
  } catch {
    return { valid: false, error: 'Malformed verification token.' };
  }

  if (Date.now() > Number(payload.exp || 0)) {
    return { valid: false, error: 'Verification code has expired. Please request a new 6-digit code.' };
  }
  if (payload.email !== String(email || '').toLowerCase().trim()) {
    return { valid: false, error: 'Email address does not match the verification code.' };
  }

  const submittedHash = hashOtp(email, code);
  const a = Buffer.from(submittedHash);
  const b = Buffer.from(String(payload.otpHash || ''));
  if (a.length !== b.length || !crypto.timingSafeEqual(a, b)) {
    return { valid: false, error: 'Incorrect 6-digit verification code.' };
  }
  return { valid: true };
}

export function setCorsHeaders(res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
}
