import React, { useEffect, useState } from 'react';
import {
  signInWithEmailAndPassword,
  createUserWithEmailAndPassword,
  signOut,
} from 'firebase/auth';
import { ref, get, set } from 'firebase/database';
import { auth, db } from '../firebase';
import { validateEmail, validateName, validateStrongPassword, sanitizeText } from '../utils/validators';
import { Flame, Lock, Mail, ShieldCheck, AlertCircle, User } from 'lucide-react';

export default function Login({ externalError, isSettingUpRef, onAdminInitialized }) {
  const [isSetupMode, setIsSetupMode] = useState(false);
  const [canInitializeAdmin, setCanInitializeAdmin] = useState(true);
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState(externalError || '');
  const [isSubmitting, setIsSubmitting] = useState(false);

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
        // Keep setup toggle available if unauthenticated read is blocked by rules
        setCanInitializeAdmin(true);
      }
    };
    checkInit();
  }, []);

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (isSubmitting) return;
    setError('');

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
          createdAt: new Date().toISOString(),
        });
        await set(ref(db, 'admins_initialized'), true);

        if (isSettingUpRef) isSettingUpRef.current = false;
        if (onAdminInitialized) {
          onAdminInitialized({ uid, email: cleanEmail, name: cleanName });
        }
      } else {
        const cred = await signInWithEmailAndPassword(auth, cleanEmail, password);
        const roleSnap = await get(ref(db, `users/${cred.user.uid}/role`));
        const role = roleSnap.exists() ? roleSnap.val() : null;

        if (role !== 'admin') {
          await signOut(auth);
          setError('Access denied. Only authorized Admin accounts can open this dashboard.');
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
                onChange={(e) => setEmail(e.target.value)}
                placeholder="admin@charcoal.ph"
                className="w-full bg-charcoal-canvas border border-charcoal-border rounded-xl pl-10 pr-3.5 py-2.5 text-charcoal-ink focus:outline-none focus:border-charcoal-header"
              />
            </div>
          </div>

          <div>
            <label className="block text-charcoal-ink font-semibold mb-1.5">Password</label>
            <div className="relative">
              <Lock className="w-4 h-4 text-charcoal-muted absolute left-3.5 top-3" />
              <input
                type="password"
                maxLength={64}
                required
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder={isSetupMode ? 'Min 8 chars, uppercase, number, symbol' : 'Enter password'}
                className="w-full bg-charcoal-canvas border border-charcoal-border rounded-xl pl-10 pr-3.5 py-2.5 text-charcoal-ink focus:outline-none focus:border-charcoal-header"
              />
            </div>
          </div>

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
                setIsSetupMode(!isSetupMode);
              }}
              className="w-full py-2 px-3 rounded-xl bg-charcoal-canvas hover:bg-charcoal-sage/50 border border-charcoal-border text-xs text-charcoal-header font-semibold transition-colors"
            >
              {isSetupMode ? 'Back to Admin Sign In' : 'First time here? Create Super Admin Account'}
            </button>
          </div>
        )}
      </div>
    </div>
  );
}
