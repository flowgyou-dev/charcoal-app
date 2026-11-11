import React, { useEffect, useState } from 'react';
import { initializeApp, deleteApp } from 'firebase/app';
import { getAuth, createUserWithEmailAndPassword, signOut } from 'firebase/auth';
import { ref, onValue, set, remove } from 'firebase/database';
import { db, firebaseConfig } from '../firebase';
import {
  sanitizeText,
  validateEmail,
  validateName,
  validatePhPhone,
  validateStrongPassword,
} from '../utils/validators';
import { UserPlus, Bike, Phone, Mail, ShieldAlert, Trash2, AlertCircle } from 'lucide-react';

export default function Drivers() {
  const [drivers, setDrivers] = useState([]);
  const [showModal, setShowModal] = useState(false);
  const [name, setName] = useState('');
  const [phone, setPhone] = useState('');
  const [vehicle, setVehicle] = useState('Motorcycle (Honda Wave 110)');
  const [plateNumber, setPlateNumber] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [formError, setFormError] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);

  useEffect(() => {
    const driversRef = ref(db, 'drivers');
    const unsub = onValue(driversRef, (snap) => {
      if (snap.exists()) {
        const val = snap.val();
        setDrivers(Object.keys(val).map(k => ({ id: k, ...val[k] })));
      } else {
        setDrivers([]);
      }
    });

    return () => unsub();
  }, []);

  const handleCreateDriver = async (e) => {
    e.preventDefault();
    if (isSubmitting) return;
    setFormError('');

    const nameErr = validateName(name, 'Driver Name');
    if (nameErr) return setFormError(nameErr);

    const phoneErr = validatePhPhone(phone);
    if (phoneErr) return setFormError(phoneErr);

    const cleanVehicle = sanitizeText(vehicle);
    if (!cleanVehicle || cleanVehicle.length < 2 || cleanVehicle.length > 60) {
      return setFormError('Vehicle type must be 2–60 characters.');
    }

    const cleanPlate = sanitizeText(plateNumber);
    if (cleanPlate.length > 20) {
      return setFormError('Plate number must be at most 20 characters.');
    }

    const emailErr = validateEmail(email);
    if (emailErr) return setFormError(emailErr);

    const passErr = validateStrongPassword(password);
    if (passErr) return setFormError(passErr);

    setIsSubmitting(true);
    let secondaryApp = null;
    try {
      const cleanName = sanitizeText(name);
      const cleanPhone = phone.replace(/[\s\-()]/g, '').trim();
      const cleanEmail = email.trim().toLowerCase();

      // Create real Firebase Auth user on a secondary app so Admin stays logged in
      secondaryApp = initializeApp(firebaseConfig, `DriverCreator-${Date.now()}`);
      const secondaryAuth = getAuth(secondaryApp);
      const cred = await createUserWithEmailAndPassword(secondaryAuth, cleanEmail, password);
      const driverUid = cred.user.uid;

      // Save safe profile metadata without password
      await set(ref(db, `drivers/${driverUid}`), {
        uid: driverUid,
        name: cleanName,
        phone: cleanPhone,
        vehicle: cleanVehicle,
        plateNumber: cleanPlate,
        email: cleanEmail,
        role: 'driver',
        isOnline: false,
        createdAt: new Date().toISOString(),
      });

      await set(ref(db, `users/${driverUid}`), {
        uid: driverUid,
        name: cleanName,
        phone: cleanPhone,
        email: cleanEmail,
        role: 'driver',
        createdAt: new Date().toISOString(),
      });

      await signOut(secondaryAuth);

      // Reset form
      setName('');
      setPhone('');
      setPlateNumber('');
      setEmail('');
      setPassword('');
      setFormError('');
      setShowModal(false);
    } catch (err) {
      if (err.code === 'auth/email-already-in-use') {
        setFormError('This driver email is already registered in Firebase Auth.');
      } else {
        setFormError(err.message || 'Failed to create driver account.');
      }
    } finally {
      if (secondaryApp) {
        try {
          await deleteApp(secondaryApp);
        } catch {
          // Ignore cleanup errors
        }
      }
      setIsSubmitting(false);
    }
  };

  const handleDeleteDriver = async (driverId) => {
    if (confirm('Sigurado ka bang gusto mong tanggalin ang driver na ito?')) {
      await remove(ref(db, `drivers/${driverId}`));
      await remove(ref(db, `driver_locations/${driverId}`));
    }
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
        <div>
          <h1 className="text-2xl font-bold text-charcoal-ink tracking-tight">Delivery Drivers Management</h1>
          <p className="text-sm text-charcoal-muted">
            Ikaw (Admin) lamang ang may kapangyarihang mag-create ng driver accounts.
          </p>
        </div>
        <button
          onClick={() => setShowModal(true)}
          className="px-4 py-2.5 bg-charcoal-header hover:bg-charcoal-dark text-white rounded-xl text-xs font-bold shadow-sm transition-all flex items-center gap-2 uppercase tracking-wide"
        >
          <UserPlus className="w-4 h-4" />
          + Create New Driver
        </button>
      </div>

      {/* Info Notice */}
      <div className="bg-white border border-charcoal-border border-l-4 border-l-charcoal-eco rounded-2xl p-4 flex items-start gap-3 shadow-sm">
        <ShieldAlert className="w-5 h-5 text-charcoal-eco shrink-0 mt-0.5" />
        <div className="text-xs text-charcoal-muted">
          <p className="font-bold text-charcoal-ink">Admin-Controlled Driver Registration</p>
          <p className="mt-0.5">
            Walang public registration ang mga driver sa mobile app para maiwasan ang mga pekeng rider. Ibigay ang Email at Password na nilikha mo rito sa iyong delivery driver para makapag-log in sila sa mobile app.
          </p>
        </div>
      </div>

      {/* Drivers List */}
      <div className="bg-white border border-charcoal-border rounded-2xl shadow-sm overflow-hidden">
        {drivers.length === 0 ? (
          <div className="py-16 text-center text-charcoal-muted text-sm">
            Wala pang driver accounts. Pindutin ang "+ Create New Driver" sa itaas para mag-assign ng driver.
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs min-w-[700px]">
              <thead className="bg-charcoal-header text-white font-semibold uppercase tracking-wider">
                <tr>
                  <th className="p-4">Driver Name</th>
                  <th className="p-4">Vehicle &amp; Plate #</th>
                  <th className="p-4">Login Credentials</th>
                  <th className="p-4">GPS Broadcast Status</th>
                  <th className="p-4 text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-charcoal-border">
                {drivers.map(driver => (
                  <tr key={driver.id} className="hover:bg-[#F8FAFA] transition-colors">
                    
                    {/* Driver Profile */}
                    <td className="p-4">
                      <div className="flex items-center gap-3">
                        <div className="w-10 h-10 rounded-xl bg-charcoal-canvas text-charcoal-header font-bold flex items-center justify-center text-sm border border-charcoal-border">
                          {driver.name ? driver.name.substring(0, 2).toUpperCase() : 'DR'}
                        </div>
                        <div>
                          <p className="font-bold text-charcoal-ink text-sm">{driver.name}</p>
                          <p className="text-[11px] text-charcoal-muted flex items-center gap-1 mt-0.5">
                            <Phone className="w-3 h-3 text-charcoal-muted" />
                            {driver.phone || 'No phone'}
                          </p>
                        </div>
                      </div>
                    </td>

                    {/* Vehicle */}
                    <td className="p-4">
                      <p className="font-semibold text-charcoal-ink">{driver.vehicle || 'Motorcycle'}</p>
                      <p className="text-[11px] text-charcoal-muted font-mono mt-0.5">
                        Plate: {driver.plateNumber || 'N/A'}
                      </p>
                    </td>

                    {/* Credentials */}
                    <td className="p-4 font-mono text-[11px]">
                      <p className="text-charcoal-header flex items-center gap-1 font-semibold">
                        <Mail className="w-3 h-3 text-charcoal-eco" />
                        {driver.email}
                      </p>
                      <p className="text-charcoal-muted mt-0.5">Managed by Firebase Auth</p>
                    </td>

                    {/* GPS Status */}
                    <td className="p-4">
                      <span className={`px-2.5 py-1 rounded-full text-[11px] font-bold ${
                        driver.isOnline
                          ? 'bg-emerald-100 text-emerald-800 border border-emerald-200'
                          : 'bg-charcoal-canvas text-charcoal-muted border border-charcoal-border'
                      }`}>
                        {driver.isOnline ? 'GPS Stream Active' : 'Standby / Offline'}
                      </span>
                    </td>

                    {/* Actions */}
                    <td className="p-4 text-right">
                      <button
                        onClick={() => handleDeleteDriver(driver.id)}
                        className="p-2 text-charcoal-muted hover:text-rose-600 hover:bg-rose-50 rounded-lg transition-colors"
                        title="Delete Driver"
                      >
                        <Trash2 className="w-4 h-4" />
                      </button>
                    </td>

                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* Create Driver Modal */}
      {showModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm p-4">
          <div className="bg-white border border-charcoal-border rounded-2xl p-6 w-full max-w-lg shadow-2xl text-charcoal-ink">
            <h3 className="font-bold text-lg text-charcoal-ink mb-1">Create New Delivery Driver Account</h3>
            <p className="text-xs text-charcoal-muted mb-4">
              I-fill out ang mga detalye ng driver para makapag-login sa mobile app.
            </p>
            
            <form onSubmit={handleCreateDriver} className="space-y-4 text-xs">
              {formError && (
                <div className="p-3 rounded-xl bg-rose-50 border border-rose-200 flex items-start gap-2 text-rose-700">
                  <AlertCircle className="w-4 h-4 text-rose-600 shrink-0 mt-0.5" />
                  <span>{formError}</span>
                </div>
              )}
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                <div>
                  <label className="block text-charcoal-ink font-semibold mb-1">Pangalan ng Driver</label>
                  <input
                    type="text"
                    required
                    maxLength={60}
                    value={name}
                    onChange={e => setName(e.target.value)}
                    placeholder="Hal. Cardo Dalisay"
                    className="w-full bg-charcoal-canvas border border-charcoal-border rounded-xl px-3.5 py-2.5 text-charcoal-ink text-xs focus:outline-none focus:border-charcoal-header"
                  />
                </div>
                <div>
                  <label className="block text-charcoal-ink font-semibold mb-1">Mobile Contact Number</label>
                  <input
                    type="text"
                    required
                    maxLength={15}
                    value={phone}
                    onChange={e => setPhone(e.target.value)}
                    placeholder="Hal. 09171234567"
                    className="w-full bg-charcoal-canvas border border-charcoal-border rounded-xl px-3.5 py-2.5 text-charcoal-ink text-xs focus:outline-none focus:border-charcoal-header"
                  />
                </div>
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                <div>
                  <label className="block text-charcoal-ink font-semibold mb-1">Uri ng Sasakyan</label>
                  <input
                    type="text"
                    required
                    maxLength={60}
                    value={vehicle}
                    onChange={e => setVehicle(e.target.value)}
                    placeholder="Hal. Honda Wave 110"
                    className="w-full bg-charcoal-canvas border border-charcoal-border rounded-xl px-3.5 py-2.5 text-charcoal-ink text-xs focus:outline-none focus:border-charcoal-header"
                  />
                </div>
                <div>
                  <label className="block text-charcoal-ink font-semibold mb-1">Plate Number</label>
                  <input
                    type="text"
                    maxLength={20}
                    value={plateNumber}
                    onChange={e => setPlateNumber(e.target.value)}
                    placeholder="Hal. 7821-AB"
                    className="w-full bg-charcoal-canvas border border-charcoal-border rounded-xl px-3.5 py-2.5 text-charcoal-ink text-xs font-mono focus:outline-none focus:border-charcoal-header"
                  />
                </div>
              </div>

              <div className="pt-2 border-t border-charcoal-border space-y-3">
                <div>
                  <label className="block text-charcoal-ink font-semibold mb-1">Driver Login Email</label>
                  <input
                    type="email"
                    required
                    maxLength={100}
                    value={email}
                    onChange={e => setEmail(e.target.value)}
                    placeholder="Hal. cardo@charcoal.ph"
                    className="w-full bg-charcoal-canvas border border-charcoal-border rounded-xl px-3.5 py-2.5 text-charcoal-ink text-xs font-mono focus:outline-none focus:border-charcoal-header"
                  />
                </div>
                <div>
                  <label className="block text-charcoal-ink font-semibold mb-1">Assigned Password</label>
                  <input
                    type="password"
                    required
                    maxLength={64}
                    value={password}
                    onChange={e => setPassword(e.target.value)}
                    placeholder="Min 8 chars, uppercase, number, symbol"
                    className="w-full bg-charcoal-canvas border border-charcoal-border rounded-xl px-3.5 py-2.5 text-charcoal-ink text-xs font-mono focus:outline-none focus:border-charcoal-header"
                  />
                </div>
              </div>

              <div className="flex justify-end gap-2 pt-2">
                <button
                  type="button"
                  disabled={isSubmitting}
                  onClick={() => {
                    setFormError('');
                    setShowModal(false);
                  }}
                  className="px-4 py-2 bg-charcoal-canvas hover:bg-charcoal-sage/40 border border-charcoal-border rounded-xl font-semibold text-charcoal-ink"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={isSubmitting}
                  className="px-5 py-2 bg-charcoal-header hover:bg-charcoal-dark disabled:opacity-60 text-white rounded-xl font-bold shadow-sm"
                >
                  {isSubmitting ? 'Creating...' : 'Create & Save Account'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
