import React, { useEffect, useState } from 'react';
import {
  signInWithEmailAndPassword,
  createUserWithEmailAndPassword,
  sendPasswordResetEmail,
  signOut,
} from 'firebase/auth';
import { ref, get, set } from 'firebase/database';
import { auth, db } from '../firebase';
import {
  validateEmail,
  validateName,
  validateStrongPassword,
  checkPasswordRequirements,
  sanitizeText,
} from '../utils/validators';
import { Flame, Lock, Mail, ShieldCheck, AlertCircle, User, CheckCircle2, KeyRound, Eye, EyeOff } from 'lucide-react';

export default function Login({ externalError, isSettingUpRef, onAdminInitialized }) {
  const [isSetupMode, setIsSetupMode] = useState(false);
  const [canInitializeAdmin, setCanInitializeAdmin] = useState(true);
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);
  const [error, setError] = useState(externalError || '');
  const [notice, setNotice] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);

  const [showResetModal, setShowResetModal] = useState(false);
  const [resetEmail, setResetEmail] = useState('');
  const [resetError, setResetError] = useState('');
  const [resetBusy, setResetBusy] = useState(false);

  useEffect(() => {
    if (externalError) setError(externalError);
  }, [externalError]);

  useEffect(() => {
    const checkInit = async () => {
      try {
        const snap = await get(ref(db, 'admins_initialized'));
        if (snap.exists() && snap.val() === true) {
          setCanInitializeAdmin(false);
        } else {
          setCanInitializeAdmin(true);
        }
      } catch {
        setCanInitializeAdmin(true);
      }
    };
    checkInit();
  }, []);

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (isSubmitting) return;
    setError('');
    setNotice('');

    const emailErr = validateEmail(email);
    if (emailErr) {
      setError(emailErr);
      return;
    }

    if (isSetupMode) {
      const nameErr = validateName(name, 'Admin Name');
      if (nameErr) {
        setError(nameErr);
        return;
      }
      const passErr = validateStrongPassword(password);
      if (passErr) {
        setError(passErr);
        return;
      }
      if (password !== confirmPassword) {
        setError('Passwords do not match.');
        return;
      }
    } else if (!password.trim()) {
      setError('Password is required.');
      return;
    }

    setIsSubmitting(true);
    try {
      const cleanEmail = email.trim().toLowerCase();
      if (isSetupMode) {
        if (isSettingUpRef) isSettingUpRef.current = true;

        const cred = await createUserWithEmailAndPassword(auth, cleanEmail, password);
        const uid = cred.user.uid;

        const initSnap = await get(ref(db, 'admins_initialized'));
        if (initSnap.exists() && initSnap.val() === true) {
          await signOut(auth);
          if (isSettingUpRef) isSettingUpRef.current = false;
          setError('An admin account already exists. Please sign in.');
          setIsSetupMode(false);
          setCanInitializeAdmin(false);
          return;
        }

        const cleanName = sanitizeText(name);
        await set(ref(db, `users/${uid}`), {
          uid,
          email: cleanEmail,
          name: cleanName,
          phone: '',
          role: 'admin',
          isActive: true,
          createdAt: new Date().toISOString(),
        });
        await set(ref(db, 'admins_initialized'), true);

        if (isSettingUpRef) isSettingUpRef.current = false;
        if (onAdminInitialized) {
          onAdminInitialized({ uid, email: cleanEmail, name: cleanName });
        }
      } else {
        const cred = await signInWithEmailAndPassword(auth, cleanEmail, password);
        const userSnap = await get(ref(db, `users/${cred.user.uid}`));
        const userData = userSnap.exists() ? userSnap.val() : null;

        if (!userData || userData.role !== 'admin') {
          await signOut(auth);
          setError('Access denied. Only authorized Admin accounts can open this dashboard.');
        } else if (userData.isActive === false) {
          await signOut(auth);
          setError('This Admin account has been deactivated.');
        }
      }
    } catch (err) {
      if (isSettingUpRef) isSettingUpRef.current = false;
      if (auth.currentUser && isSetupMode) {
        try {
          await signOut(auth);
        } catch {
          // Ignore signout error
        }
      }
      if (err.code === 'auth/invalid-credential' || err.code === 'auth/wrong-password' || err.code === 'auth/user-not-found') {
        setError('Invalid email or password.');
      } else if (err.code === 'auth/email-already-in-use') {
        setError('This email is already registered.');
      } else if (err.code === 'auth/too-many-requests') {
        setError('Too many failed attempts. Please wait a moment and try again.');
      } else {
        setError(err.message || 'Authentication failed.');
      }
    } finally {
      if (isSettingUpRef) isSettingUpRef.current = false;
      setIsSubmitting(false);
    }
  };

  const handlePasswordReset = async (e) => {
    e.preventDefault();
    if (resetBusy) return;
    setResetError('');
    setNotice('');

    const emailErr = validateEmail(resetEmail);
    if (emailErr) {
      setResetError(emailErr);
      return;
    }

    setResetBusy(true);
    try {
      await sendPasswordResetEmail(auth, resetEmail.trim().toLowerCase());
      setShowResetModal(false);
      setResetError('');
      setNotice(
        `If an account is registered for ${resetEmail.trim().toLowerCase()}, a password reset link has been sent. Please check your inbox or spam folder.`
      );
      setResetEmail('');
    } catch (err) {
      if (err?.code === 'auth/user-not-found') {
        setResetError('No registered account was found with that email address.');
      } else if (err?.code === 'auth/too-many-requests') {
        setResetError('Too many reset requests. Please wait a bit before trying again.');
      } else {
        setResetError(err.message || 'Failed to send password reset email.');
      }
    } finally {
      setResetBusy(false);
    }
  };

  return (
    <div className="min-h-screen bg-charcoal-canvas flex items-center justify-center p-4 text-charcoal-ink">
      <div className="w-full max-w-md bg-white border border-charcoal-border rounded-3xl p-7 shadow-lg">
        <div className="flex flex-col items-center text-center mb-6">
          <div className="w-14 h-14 rounded-2xl bg-charcoal-header flex items-center justify-center text-white shadow-md mb-4">
            <Flame className="w-8 h-8" />
          </div>
          <h1 className="text-xl font-extrabold text-charcoal-ink tracking-tight">CharCoal Hub Admin</h1>
          <p className="text-xs text-charcoal-muted mt-1">
            {isSetupMode
              ? 'Create the first Business Owner / Admin account'
              : 'Sign in with your verified Admin credentials'}
          </p>
        </div>

        {error && (
          <div className="mb-5 p-3 rounded-xl bg-rose-50 border border-rose-200 flex items-start gap-2.5 text-xs text-rose-700">
            <AlertCircle className="w-4 h-4 text-rose-600 shrink-0 mt-0.5" />
            <span>{error}</span>
          </div>
        )}

        {notice && (
          <div className="mb-5 p-3 rounded-xl bg-[#E8F3EC] border border-[#B7DFC7] flex items-start gap-2.5 text-xs text-charcoal-eco font-semibold">
            <CheckCircle2 className="w-4 h-4 shrink-0 mt-0.5" />
            <span>{notice}</span>
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-4 text-xs">
          {isSetupMode && (
            <div>
              <label className="block text-charcoal-ink font-semibold mb-1.5">Admin Full Name</label>
              <div className="relative">
                <User className="w-4 h-4 text-charcoal-muted absolute left-3.5 top-3" />
                <input
                  type="text"
                  maxLength={60}
                  required
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  placeholder="Business Owner"
                  className="w-full bg-charcoal-canvas border border-charcoal-border rounded-xl pl-10 pr-3.5 py-2.5 text-charcoal-ink focus:outline-none focus:border-charcoal-header"
                />
              </div>
            </div>
          )}

          <div>
            <label className="block text-charcoal-ink font-semibold mb-1.5">Admin Email</label>
            <div className="relative">
              <Mail className="w-4 h-4 text-charcoal-muted absolute left-3.5 top-3" />
              <input
                type="email"
                maxLength={100}
                required
                value={email}
                onChange={(e) => setEmail(e.target.value.replace(/\s+/g, ''))}
                placeholder="admin@charcoal.ph"
                className="w-full bg-charcoal-canvas border border-charcoal-border rounded-xl pl-10 pr-3.5 py-2.5 text-charcoal-ink focus:outline-none focus:border-charcoal-header"
              />
            </div>
          </div>

          <div>
            <div className="flex items-center justify-between mb-1.5">
              <label className="block text-charcoal-ink font-semibold">Password</label>
              {!isSetupMode && (
                <button
                  type="button"
                  onClick={() => {
                    setError('');
                    setResetError('');
                    setResetEmail(email);
                    setShowResetModal(true);
                  }}
                  className="text-[11px] font-semibold text-charcoal-eco hover:underline"
                >
                  Forgot Password?
                </button>
              )}
            </div>
            <div className="relative">
              <Lock className="w-4 h-4 text-charcoal-muted absolute left-3.5 top-3" />
              <input
                type={showPassword ? 'text' : 'password'}
                maxLength={64}
                required
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder={isSetupMode ? 'Min 8 chars, uppercase, number, symbol' : 'Enter password'}
                className="w-full bg-charcoal-canvas border border-charcoal-border rounded-xl pl-10 pr-10 py-2.5 text-charcoal-ink focus:outline-none focus:border-charcoal-header"
              />
              <button
                type="button"
                aria-label={showPassword ? 'Hide password' : 'Show password'}
                onClick={() => setShowPassword((prev) => !prev)}
                className="absolute right-3 top-2.5 text-charcoal-muted hover:text-charcoal-ink"
              >
                {showPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
              </button>
            </div>
          </div>

          {isSetupMode && (
            <>
              <div>
                <label className="block text-charcoal-ink font-semibold mb-1.5">Confirm Password</label>
                <div className="relative">
                  <Lock className="w-4 h-4 text-charcoal-muted absolute left-3.5 top-3" />
                  <input
                    type={showConfirmPassword ? 'text' : 'password'}
                    maxLength={64}
                    required
                    value={confirmPassword}
                    onChange={(e) => setConfirmPassword(e.target.value)}
                    placeholder="Re-enter password"
                    className="w-full bg-charcoal-canvas border border-charcoal-border rounded-xl pl-10 pr-10 py-2.5 text-charcoal-ink focus:outline-none focus:border-charcoal-header"
                  />
                  <button
                    type="button"
                    aria-label={showConfirmPassword ? 'Hide confirm password' : 'Show confirm password'}
                    onClick={() => setShowConfirmPassword((prev) => !prev)}
                    className="absolute right-3 top-2.5 text-charcoal-muted hover:text-charcoal-ink"
                  >
                    {showConfirmPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                  </button>
                </div>
              </div>

              {(() => {
                const req = checkPasswordRequirements(password, confirmPassword);
                const items = [
                  ['At least 8 characters', req.hasMinLength],
                  ['At least 1 uppercase letter (A-Z)', req.hasUppercase],
                  ['At least 1 number (0-9)', req.hasNumber],
                  ['At least 1 special character (@, #, $, !)', req.hasSpecialChar],
                  ['Passwords match', req.passwordsMatch],
                ];
                return (
                  <div className="p-3 rounded-xl bg-charcoal-canvas border border-charcoal-border space-y-1">
                    <div className="text-[11px] font-bold text-charcoal-ink mb-1">Password Requirements</div>
                    {items.map(([label, ok]) => (
                      <div key={label} className={`flex items-center gap-2 text-[11px] ${ok ? 'text-charcoal-eco font-semibold' : 'text-charcoal-muted'}`}>
                        <CheckCircle2 className={`w-3.5 h-3.5 ${ok ? 'text-charcoal-eco' : 'text-charcoal-border'}`} />
                        <span>{label}</span>
                      </div>
                    ))}
                  </div>
                );
              })()}
            </>
          )}

          <button
            type="submit"
            disabled={isSubmitting}
            className="w-full py-3 rounded-xl bg-charcoal-header hover:bg-charcoal-dark disabled:opacity-60 text-white font-bold shadow-sm transition-all flex items-center justify-center gap-2 uppercase tracking-wide"
          >
            <ShieldCheck className="w-4 h-4" />
            {isSubmitting
              ? 'Verifying...'
              : isSetupMode
              ? 'Create First Admin Account'
              : 'Sign In to Admin Portal'}
          </button>
        </form>

        {canInitializeAdmin && (
          <div className="mt-5 pt-4 border-t border-charcoal-border text-center">
            <button
              type="button"
              onClick={() => {
                setError('');
                setNotice('');
                setIsSetupMode(!isSetupMode);
              }}
              className="w-full py-2 px-3 rounded-xl bg-charcoal-canvas hover:bg-charcoal-sage/50 border border-charcoal-border text-xs text-charcoal-header font-semibold transition-colors"
            >
              {isSetupMode ? 'Back to Admin Sign In' : 'First time here? Create Super Admin Account'}
            </button>
          </div>
        )}
      </div>

      {/* Password Reset Modal */}
      {showResetModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm p-4">
          <div className="bg-white border border-charcoal-border rounded-2xl p-6 w-full max-w-sm shadow-2xl">
            <div className="flex items-center gap-2 mb-2">
              <KeyRound className="w-5 h-5 text-charcoal-header" />
              <h3 className="font-bold text-base text-charcoal-ink">Reset Admin Password</h3>
            </div>
            <p className="text-xs text-charcoal-muted mb-4">
              Enter your registered admin email address to receive a password reset link.
            </p>
            <form onSubmit={handlePasswordReset} className="space-y-4 text-xs">
              {resetError && (
                <div className="p-2.5 rounded-xl bg-rose-50 border border-rose-200 flex items-start gap-2 text-rose-700 text-xs">
                  <AlertCircle className="w-4 h-4 text-rose-600 shrink-0 mt-0.5" />
                  <span>{resetError}</span>
                </div>
              )}
              <input
                type="email"
                maxLength={100}
                required
                value={resetEmail}
                onChange={(e) => setResetEmail(e.target.value.replace(/\s+/g, ''))}
                placeholder="admin@charcoal.ph"
                className="w-full bg-charcoal-canvas border border-charcoal-border rounded-xl px-3.5 py-2.5 text-charcoal-ink focus:outline-none focus:border-charcoal-header"
              />
              <div className="flex justify-end gap-2">
                <button
                  type="button"
                  onClick={() => {
                    setResetError('');
                    setShowResetModal(false);
                  }}
                  className="px-4 py-2 bg-charcoal-canvas border border-charcoal-border rounded-xl font-semibold text-charcoal-ink"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={resetBusy}
                  className="px-4 py-2 bg-charcoal-header hover:bg-charcoal-dark disabled:opacity-60 text-white rounded-xl font-bold"
                >
                  {resetBusy ? 'Sending...' : 'Send Reset Link'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
