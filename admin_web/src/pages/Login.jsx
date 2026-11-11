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

export default function Login({ externalError }) {
  const [isSetupMode, setIsSetupMode] = useState(false);
  const [canInitializeAdmin, setCanInitializeAdmin] = useState(false);
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
        if (!snap.exists()) {
          setCanInitializeAdmin(true);
        }
      } catch {
        // Ignore if database rules block unauthenticated read on admins_initialized
        setCanInitializeAdmin(false);
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
      const cleanEmail = email.trim();
      if (isSetupMode) {
        const initSnap = await get(ref(db, 'admins_initialized'));
        if (initSnap.exists()) {
          setError('An admin account already exists. Please sign in.');
          setIsSetupMode(false);
          setCanInitializeAdmin(false);
          return;
        }

        const cred = await createUserWithEmailAndPassword(auth, cleanEmail, password);
        const uid = cred.user.uid;

        await set(ref(db, `users/${uid}`), {
          uid,
          email: cleanEmail,
          name: sanitizeText(name),
          phone: '',
          role: 'admin',
          createdAt: new Date().toISOString(),
        });
        await set(ref(db, 'admins_initialized'), true);
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
      setIsSubmitting(false);
    }
  };

  return (
    <div className="min-h-screen bg-slate-950 flex items-center justify-center p-4 text-slate-100">
      <div className="w-full max-w-md bg-slate-900 border border-slate-800 rounded-3xl p-7 shadow-2xl">
        <div className="flex flex-col items-center text-center mb-6">
          <div className="w-14 h-14 rounded-2xl bg-gradient-to-tr from-amber-600 to-amber-500 flex items-center justify-center text-white shadow-lg shadow-amber-600/30 mb-4">
            <Flame className="w-8 h-8" />
          </div>
          <h1 className="text-xl font-extrabold text-white tracking-tight">CharCoal Hub Admin</h1>
          <p className="text-xs text-slate-400 mt-1">
            {isSetupMode
              ? 'Create the first Business Owner / Admin account'
              : 'Sign in with your verified Admin credentials'}
          </p>
        </div>

        {error && (
          <div className="mb-5 p-3 rounded-xl bg-rose-500/15 border border-rose-500/30 flex items-start gap-2.5 text-xs text-rose-300">
            <AlertCircle className="w-4 h-4 text-rose-400 shrink-0 mt-0.5" />
            <span>{error}</span>
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-4 text-xs">
          {isSetupMode && (
            <div>
              <label className="block text-slate-300 font-semibold mb-1.5">Admin Full Name</label>
              <div className="relative">
                <User className="w-4 h-4 text-slate-500 absolute left-3.5 top-3" />
                <input
                  type="text"
                  maxLength={60}
                  required
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  placeholder="Business Owner"
                  className="w-full bg-slate-950 border border-slate-700 rounded-xl pl-10 pr-3.5 py-2.5 text-white focus:outline-none focus:border-amber-500"
                />
              </div>
            </div>
          )}

          <div>
            <label className="block text-slate-300 font-semibold mb-1.5">Admin Email</label>
            <div className="relative">
              <Mail className="w-4 h-4 text-slate-500 absolute left-3.5 top-3" />
              <input
                type="email"
                maxLength={100}
                required
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="admin@charcoal.ph"
                className="w-full bg-slate-950 border border-slate-700 rounded-xl pl-10 pr-3.5 py-2.5 text-white focus:outline-none focus:border-amber-500"
              />
            </div>
          </div>

          <div>
            <label className="block text-slate-300 font-semibold mb-1.5">Password</label>
            <div className="relative">
              <Lock className="w-4 h-4 text-slate-500 absolute left-3.5 top-3" />
              <input
                type="password"
                maxLength={64}
                required
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder={isSetupMode ? 'Min 8 chars, uppercase, number, symbol' : 'Enter password'}
                className="w-full bg-slate-950 border border-slate-700 rounded-xl pl-10 pr-3.5 py-2.5 text-white focus:outline-none focus:border-amber-500"
              />
            </div>
          </div>

          <button
            type="submit"
            disabled={isSubmitting}
            className="w-full py-3 rounded-xl bg-amber-600 hover:bg-amber-700 disabled:opacity-60 text-white font-bold shadow-lg shadow-amber-600/20 transition-all flex items-center justify-center gap-2"
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
          <div className="mt-5 pt-4 border-t border-slate-800 text-center">
            <button
              type="button"
              onClick={() => {
                setError('');
                setIsSetupMode(!isSetupMode);
              }}
              className="text-xs text-amber-400 hover:text-amber-300 font-semibold"
            >
              {isSetupMode ? 'Back to Admin Sign In' : 'First time here? Initialize First Admin Account'}
            </button>
          </div>
        )}
      </div>
    </div>
  );
}
