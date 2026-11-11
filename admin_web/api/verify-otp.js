import { setCorsHeaders, verifyOtpToken } from './_otpHelper.js';

export default async function handler(req, res) {
  setCorsHeaders(res);
  if (req.method === 'OPTIONS') return res.status(204).end();
  if (req.method !== 'POST') return res.status(405).json({ error: 'Method not allowed' });

  const { email, code, token } = req.body || {};
  if (!email || !code || !token) {
    return res.status(400).json({ error: 'Email, 6-digit code, and verification token are required.' });
  }
  if (!/^\d{6}$/.test(String(code).trim())) {
    return res.status(400).json({ error: 'Please enter a valid 6-digit numeric code.' });
  }

  const result = verifyOtpToken(token, email, String(code).trim());
  if (!result.valid) {
    return res.status(400).json({ error: result.error });
  }
  return res.status(200).json({ ok: true, verified: true });
}
