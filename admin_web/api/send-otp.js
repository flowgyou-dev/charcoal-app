import crypto from 'node:crypto';
import nodemailer from 'nodemailer';
import { createOtpToken, setCorsHeaders, validateEmailDomain } from './_otpHelper.js';

async function sendViaResend(toEmail, code, customerName) {
  const apiKey = process.env.RESEND_API_KEY;
  const fromAddress = process.env.EMAIL_FROM || 'CharCoal Express <onboarding@resend.dev>';
  const resp = await fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${apiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      from: fromAddress,
      to: [toEmail],
      subject: `${code} is your CharCoal Express verification code`,
      html: buildEmailHtml(code, customerName),
    }),
  });
  if (!resp.ok) {
    const errBody = await resp.text();
    throw new Error(`Resend API error (${resp.status}): ${errBody}`);
  }
}

async function sendViaSmtp(toEmail, code, customerName) {
  const transporter = nodemailer.createTransport({
    service: process.env.SMTP_SERVICE || 'gmail',
    host: process.env.SMTP_HOST || undefined,
    port: process.env.SMTP_PORT ? Number(process.env.SMTP_PORT) : undefined,
    secure: process.env.SMTP_SECURE === 'true',
    auth: {
      user: process.env.SMTP_USER,
      pass: process.env.SMTP_PASS,
    },
  });

  await transporter.sendMail({
    from: process.env.EMAIL_FROM || `"CharCoal Express" <${process.env.SMTP_USER}>`,
    to: toEmail,
    subject: `${code} is your CharCoal Express verification code`,
    html: buildEmailHtml(code, customerName),
  });
}

function buildEmailHtml(code, customerName) {
  const safeName = String(customerName || 'Customer').replace(/[<>&"]/g, '');
  return `
    <div style="font-family: Arial, sans-serif; max-width: 480px; margin: 0 auto; padding: 24px; background: #F3F5F4; border-radius: 16px;">
      <div style="background: #243D3C; color: #FFFFFF; padding: 20px; border-radius: 12px 12px 0 0; text-align: center;">
        <h2 style="margin: 0; font-size: 20px;">CharCoal Express</h2>
        <p style="margin: 4px 0 0; font-size: 12px; opacity: 0.85;">Email Verification Code</p>
      </div>
      <div style="background: #FFFFFF; padding: 24px; border-radius: 0 0 12px 12px; border: 1px solid #DCE2E0;">
        <p style="color: #1E2929; font-size: 14px;">Hi ${safeName},</p>
        <p style="color: #617070; font-size: 13px; line-height: 1.5;">
          Use the 6-digit verification code below to complete your Customer account registration:
        </p>
        <div style="margin: 20px 0; padding: 16px; background: #F3F5F4; border: 1px dashed #3E7C59; border-radius: 10px; text-align: center;">
          <span style="font-family: monospace; font-size: 32px; font-weight: bold; letter-spacing: 8px; color: #243D3C;">${code}</span>
        </div>
        <p style="color: #617070; font-size: 12px;">
          This code expires in <strong>10 minutes</strong>. If you did not request this, you can safely ignore this email.
        </p>
      </div>
    </div>
  `;
}

export default async function handler(req, res) {
  setCorsHeaders(res);
  if (req.method === 'OPTIONS') return res.status(204).end();
  if (req.method !== 'POST') return res.status(405).json({ error: 'Method not allowed' });

  const { email, name } = req.body || {};
  const domainErr = validateEmailDomain(email);
  if (domainErr) {
    return res.status(400).json({ error: domainErr });
  }

  const hasResend = Boolean(process.env.RESEND_API_KEY);
  const hasSmtp = Boolean(process.env.SMTP_USER && process.env.SMTP_PASS);
  if (!process.env.OTP_SECRET || (!hasResend && !hasSmtp)) {
    return res.status(503).json({
      error:
        'Email verification service is not configured yet. Please set OTP_SECRET and either RESEND_API_KEY or SMTP_USER/SMTP_PASS in Vercel Environment Variables.',
    });
  }

  const code = String(crypto.randomInt(100000, 1000000));
  try {
    if (hasResend) {
      await sendViaResend(email, code, name);
    } else {
      await sendViaSmtp(email, code, name);
    }
    const token = createOtpToken(email, code);
    return res.status(200).json({ ok: true, token, expiresInSeconds: 600 });
  } catch (err) {
    console.error('OTP send failure:', err);
    return res.status(500).json({ error: 'Failed to deliver verification email. Please try again.' });
  }
}
