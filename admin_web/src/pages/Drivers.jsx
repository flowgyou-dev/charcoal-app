import React, { useEffect, useState } from 'react';
import { initializeApp, deleteApp } from 'firebase/app';
import { getAuth, createUserWithEmailAndPassword, sendPasswordResetEmail, signOut } from 'firebase/auth';
import { ref, onValue, set, update, remove } from 'firebase/database';
import { auth, db, firebaseConfig } from '../firebase';
import {
  checkPasswordRequirements,
  formatDigitsOnly,
  formatPlateNumber,
  sanitizeText,
  validateEmail,
  validateName,
  validatePhPhone,
  validatePlateNumber,
  validateStrongPassword,
} from '../utils/validators';
import {
  UserPlus,
  Phone,
  Mail,
  ShieldAlert,
  Edit3,
  KeyRound,
  Ban,
  CheckCircle2,
  AlertCircle,
  Eye,
  EyeOff,
  Trash2,
} from 'lucide-react';

export default function Drivers() {
  const [drivers, setDrivers] = useState([]);
  const [orders, setOrders] = useState([]);
  const [pageNotice, setPageNotice] = useState('');
  const [pageError, setPageError] = useState('');

  const [showCreateModal, setShowCreateModal] = useState(false);
  const [editingDriver, setEditingDriver] = useState(null);
  const [toggleDriverTarget, setToggleDriverTarget] = useState(null);
  const [deleteDriverTarget, setDeleteDriverTarget] = useState(null);
  const [isDeleting, setIsDeleting] = useState(false);

  const [name, setName] = useState('');
  const [phone, setPhone] = useState('');
  const [vehicle, setVehicle] = useState('Motorcycle (Honda Wave 110)');
  const [plateNumber, setPlateNumber] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);
  const [formError, setFormError] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const passReqs = checkPasswordRequirements(password, confirmPassword);

  useEffect(() => {
    const unsubDrivers = onValue(
      ref(db, 'drivers'),
      (snap) => {
        if (snap.exists()) {
          const val = snap.val();
          setDrivers(Object.keys(val).map((k) => ({ id: k, ...val[k] })));
        } else {
          setDrivers([]);
        }
      },
      (err) => setPageError(err.message || 'Unable to load drivers.')
    );

    const unsubOrders = onValue(ref(db, 'orders'), (snap) => {
      if (snap.exists()) {
        const val = snap.val();
        setOrders(Object.keys(val).map((k) => ({ id: k, ...val[k] })));
      } else {
        setOrders([]);
      }
    });

    return () => {
      unsubDrivers();
      unsubOrders();
    };
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

    const cleanPlate = formatPlateNumber(plateNumber);
    const plateErr = validatePlateNumber(cleanPlate);
    if (plateErr) return setFormError(plateErr);

    const emailErr = validateEmail(email);
    if (emailErr) return setFormError(emailErr);

    const passErr = validateStrongPassword(password);
    if (passErr) return setFormError(passErr);

    if (password !== confirmPassword) {
      return setFormError('Passwords do not match.');
    }

    setIsSubmitting(true);
    let secondaryApp = null;
    let createdAuthUser = null;
    try {
      const cleanName = sanitizeText(name);
      const cleanPhone = formatDigitsOnly(phone, 12);
      const cleanEmail = email.trim().toLowerCase();

      secondaryApp = initializeApp(firebaseConfig, `DriverCreator-${Date.now()}`);
      const secondaryAuth = getAuth(secondaryApp);
      const cred = await createUserWithEmailAndPassword(secondaryAuth, cleanEmail, password);
      createdAuthUser = cred.user;
      const driverUid = cred.user.uid;

      const payload = {
        uid: driverUid,
        name: cleanName,
        phone: cleanPhone,
        vehicle: cleanVehicle,
        plateNumber: cleanPlate,
        email: cleanEmail,
        role: 'driver',
        isOnline: false,
        isActive: true,
        createdAt: new Date().toISOString(),
      };

      await set(ref(db, `drivers/${driverUid}`), payload);
      await set(ref(db, `users/${driverUid}`), {
        uid: driverUid,
        name: cleanName,
        phone: cleanPhone,
        email: cleanEmail,
        role: 'driver',
        isActive: true,
        createdAt: payload.createdAt,
      });

      await signOut(secondaryAuth);
      createdAuthUser = null;

      setName('');
      setPhone('');
      setPlateNumber('');
      setEmail('');
      setPassword('');
      setConfirmPassword('');
      setShowPassword(false);
      setShowConfirmPassword(false);
      setShowCreateModal(false);
      setPageNotice(`Driver account created for ${cleanName} (${cleanEmail}).`);
    } catch (err) {
      if (createdAuthUser) {
        try {
          await createdAuthUser.delete();
        } catch {
          // Ignore rollback cleanup errors
        }
      }
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

  const openEditModal = (driver) => {
    setFormError('');
    setEditingDriver(driver);
    setName(driver.name || '');
    setPhone(formatDigitsOnly(driver.phone || '', 12));
    setVehicle(driver.vehicle || 'Motorcycle');
    setPlateNumber(formatPlateNumber(driver.plateNumber || ''));
  };

  const handleSaveEdit = async (e) => {
    e.preventDefault();
    if (!editingDriver || isSubmitting) return;
    setFormError('');

    const nameErr = validateName(name, 'Driver Name');
    if (nameErr) return setFormError(nameErr);
    const phoneErr = validatePhPhone(phone);
    if (phoneErr) return setFormError(phoneErr);

    const cleanName = sanitizeText(name);
    const cleanPhone = formatDigitsOnly(phone, 12);
    const cleanVehicle = sanitizeText(vehicle);
    if (cleanVehicle.length < 2 || cleanVehicle.length > 60) {
      return setFormError('Vehicle type must be 2–60 characters.');
    }
    const cleanPlate = formatPlateNumber(plateNumber);
    const plateErr = validatePlateNumber(cleanPlate);
    if (plateErr) return setFormError(plateErr);

    setIsSubmitting(true);
    try {
      await update(ref(db, `drivers/${editingDriver.id}`), {
        name: cleanName,
        phone: cleanPhone,
        vehicle: cleanVehicle,
        plateNumber: cleanPlate,
        updatedAt: new Date().toISOString(),
      });
      await update(ref(db, `users/${editingDriver.id}`), {
        name: cleanName,
        phone: cleanPhone,
      });
      setEditingDriver(null);
      setPageNotice(`Updated details for ${cleanName}.`);
    } catch (err) {
      setFormError(err.message || 'Failed to update driver.');
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleToggleActive = async (driver) => {
    setPageError('');
    const nextActive = driver.isActive === false;
    try {
      await update(ref(db, `drivers/${driver.id}`), {
        isActive: nextActive,
        isOnline: nextActive ? Boolean(driver.isOnline) : false,
      });
      await update(ref(db, `users/${driver.id}`), {
        isActive: nextActive,
      });
      if (!nextActive) {
        await update(ref(db, `driver_locations/${driver.id}`), { isOnline: false });
      }
      setPageNotice(
        `${driver.name} has been ${nextActive ? 'reactivated' : 'deactivated (login blocked)'}.`
      );
    } catch (err) {
      setPageError(err.message || 'Failed to update driver status.');
    }
  };

  const handleSendPasswordReset = async (driverEmail) => {
    setPageError('');
    setPageNotice('');
    try {
      await sendPasswordResetEmail(auth, driverEmail);
      setPageNotice(`Password reset email sent to ${driverEmail}.`);
    } catch (err) {
      setPageError(err.message || 'Failed to send password reset.');
    }
  };

  const handleDeleteDriver = async (driver) => {
    if (!driver || isDeleting) return;
    setPageError('');
    setPageNotice('');

    const activeCount = orders.filter(
      (o) =>
        o.driverId === driver.id &&
        (o.status === 'Confirmed' || o.status === 'Out for Delivery')
    ).length;
    if (activeCount > 0) {
      setPageError(
        `Cannot delete ${driver.name} while they have ${activeCount} active delivery order(s). Please reassign or complete them first.`
      );
      return;
    }

    setIsDeleting(true);
    try {
      await remove(ref(db, `drivers/${driver.id}`));
      await remove(ref(db, `users/${driver.id}`));
      await remove(ref(db, `driver_locations/${driver.id}`));
      setPageNotice(`Deleted driver account for ${driver.name}.`);
    } catch (err) {
      setPageError(err.message || 'Failed to delete driver account.');
    } finally {
      setIsDeleting(false);
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
        <div>
          <h1 className="text-2xl font-bold text-charcoal-ink tracking-tight">Delivery Drivers Management</h1>
          <p className="text-sm text-charcoal-muted">
            Create, edit, reset passwords, and manage the active status of delivery drivers.
          </p>
        </div>
        <button
          onClick={() => {
            setFormError('');
            setName('');
            setPhone('');
            setVehicle('Motorcycle (Honda Wave 110)');
            setPlateNumber('');
            setEmail('');
            setPassword('');
            setConfirmPassword('');
            setShowPassword(false);
            setShowConfirmPassword(false);
            setShowCreateModal(true);
          }}
          className="px-4 py-2.5 bg-charcoal-header hover:bg-charcoal-dark text-white rounded-xl text-xs font-bold shadow-sm transition-all flex items-center gap-2 uppercase tracking-wide"
        >
          <UserPlus className="w-4 h-4" />
          Create New Driver
        </button>
      </div>

      {pageError && (
        <div className="p-3 rounded-xl bg-rose-50 border border-rose-200 text-xs text-rose-700 flex justify-between">
          <span>{pageError}</span>
          <button onClick={() => setPageError('')} className="font-bold">×</button>
        </div>
      )}

      {pageNotice && (
        <div className="p-3 rounded-xl bg-[#E8F3EC] border border-[#B7DFC7] text-xs text-charcoal-eco font-semibold flex justify-between">
          <span>{pageNotice}</span>
          <button onClick={() => setPageNotice('')} className="font-bold">×</button>
        </div>
      )}

      <div className="bg-white border border-charcoal-border border-l-4 border-l-charcoal-eco rounded-2xl p-4 flex items-start gap-3 shadow-sm">
        <ShieldAlert className="w-5 h-5 text-charcoal-eco shrink-0 mt-0.5" />
        <div className="text-xs text-charcoal-muted">
          <p className="font-bold text-charcoal-ink">Admin-Controlled Driver Access</p>
          <p className="mt-0.5">
            Once a driver is deactivated, they are automatically blocked by Firebase login and Realtime Database rules even on the Free Spark Plan.
          </p>
        </div>
      </div>

      {/* Drivers Table */}
      <div className="bg-white border border-charcoal-border rounded-2xl shadow-sm overflow-hidden">
        {drivers.length === 0 ? (
          <div className="py-16 text-center text-charcoal-muted text-sm">
            No driver accounts yet.
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs min-w-[820px]">
              <thead className="bg-charcoal-header text-white font-semibold uppercase tracking-wider">
                <tr>
                  <th className="p-4">Driver Name</th>
                  <th className="p-4">Vehicle &amp; Plate #</th>
                  <th className="p-4">Login Email</th>
                  <th className="p-4">Workload &amp; GPS</th>
                  <th className="p-4">Account Status</th>
                  <th className="p-4 text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-charcoal-border">
                {drivers.map((driver) => {
                  const isActive = driver.isActive !== false;
                  const activeCount = orders.filter(
                    (o) => o.driverId === driver.id && (o.status === 'Confirmed' || o.status === 'Out for Delivery')
                  ).length;
                  const completedCount = orders.filter(
                    (o) => o.driverId === driver.id && o.status === 'Delivered'
                  ).length;

                  return (
                    <tr key={driver.id} className="hover:bg-[#F8FAFA] transition-colors">
                      <td className="p-4">
                        <div className="flex items-center gap-3">
                          <div className="w-10 h-10 rounded-xl bg-charcoal-canvas text-charcoal-header font-bold flex items-center justify-center text-sm border border-charcoal-border">
                            {driver.name ? driver.name.substring(0, 2).toUpperCase() : 'DR'}
                          </div>
                          <div>
                            <p className="font-bold text-charcoal-ink text-sm">{driver.name}</p>
                            <p className="text-[11px] text-charcoal-muted flex items-center gap-1 mt-0.5">
                              <Phone className="w-3 h-3" />
                              {driver.phone || 'No phone'}
                            </p>
                          </div>
                        </div>
                      </td>

                      <td className="p-4">
                        <p className="font-semibold text-charcoal-ink">{driver.vehicle || 'Motorcycle'}</p>
                        <p className="text-[11px] text-charcoal-muted font-mono mt-0.5">
                          Plate: {driver.plateNumber || 'N/A'}
                        </p>
                      </td>

                      <td className="p-4 font-mono text-[11px]">
                        <p className="text-charcoal-header flex items-center gap-1 font-semibold">
                          <Mail className="w-3 h-3 text-charcoal-eco" />
                          {driver.email}
                        </p>
                      </td>

                      <td className="p-4">
                        <span
                          className={`px-2.5 py-0.5 rounded-full text-[11px] font-bold ${
                            driver.isOnline && isActive
                              ? 'bg-emerald-100 text-emerald-800 border border-emerald-200'
                              : 'bg-charcoal-canvas text-charcoal-muted border border-charcoal-border'
                          }`}
                        >
                          {driver.isOnline && isActive ? 'GPS Active' : 'Offline'}
                        </span>
                        <p className="text-[11px] text-charcoal-muted mt-1">
                          {activeCount} active • {completedCount} delivered
                        </p>
                      </td>

                      <td className="p-4">
                        <span
                          className={`px-2.5 py-1 rounded-full text-[11px] font-bold ${
                            isActive
                              ? 'bg-[#E8F3EC] text-charcoal-eco border border-[#B7DFC7]'
                              : 'bg-rose-100 text-rose-700 border border-rose-200'
                          }`}
                        >
                          {isActive ? 'Active' : 'Deactivated'}
                        </span>
                      </td>

                      <td className="p-4 text-right space-x-1 whitespace-nowrap">
                        <button
                          onClick={() => openEditModal(driver)}
                          className="p-2 text-charcoal-muted hover:text-charcoal-header hover:bg-charcoal-canvas rounded-lg transition-colors"
                          title="Edit Driver Details"
                        >
                          <Edit3 className="w-4 h-4" />
                        </button>
                        <button
                          onClick={() => handleSendPasswordReset(driver.email)}
                          className="p-2 text-charcoal-muted hover:text-charcoal-eco hover:bg-[#E8F3EC] rounded-lg transition-colors"
                          title="Send Password Reset Email"
                        >
                          <KeyRound className="w-4 h-4" />
                        </button>
                        <button
                          onClick={() => setToggleDriverTarget(driver)}
                          className={`p-2 rounded-lg transition-colors ${
                            isActive
                              ? 'text-charcoal-muted hover:text-rose-600 hover:bg-rose-50'
                              : 'text-charcoal-eco hover:bg-[#E8F3EC]'
                          }`}
                          title={isActive ? 'Deactivate Driver' : 'Reactivate Driver'}
                        >
                          {isActive ? <Ban className="w-4 h-4" /> : <CheckCircle2 className="w-4 h-4" />}
                        </button>
                        <button
                          onClick={() => setDeleteDriverTarget(driver)}
                          className="p-2 text-charcoal-muted hover:text-rose-600 hover:bg-rose-50 rounded-lg transition-colors"
                          title="Delete Driver Account"
                        >
                          <Trash2 className="w-4 h-4" />
                        </button>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* Create Driver Modal */}
      {showCreateModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm p-4">
          <div className="bg-white border border-charcoal-border rounded-2xl p-6 w-full max-w-lg shadow-2xl text-charcoal-ink">
            <h3 className="font-bold text-lg text-charcoal-ink mb-1">Create New Delivery Driver</h3>
            <p className="text-xs text-charcoal-muted mb-4">Fill out the driver details so they can log in to the mobile app.</p>

            <form onSubmit={handleCreateDriver} className="space-y-4 text-xs">
              {formError && (
                <div className="p-3 rounded-xl bg-rose-50 border border-rose-200 flex items-start gap-2 text-rose-700">
                  <AlertCircle className="w-4 h-4 text-rose-600 shrink-0 mt-0.5" />
                  <span>{formError}</span>
                </div>
              )}
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                <div>
                  <label className="block font-semibold mb-1">Driver Name</label>
                  <input
                    type="text"
                    required
                    maxLength={60}
                    value={name}
                    onChange={(e) => setName(e.target.value)}
                    placeholder="Cardo Dalisay"
                    className="w-full bg-charcoal-canvas border border-charcoal-border rounded-xl px-3.5 py-2.5 focus:outline-none focus:border-charcoal-header"
                  />
                </div>
                <div>
                  <label className="block font-semibold mb-1">Mobile / Telephone Number</label>
                  <input
                    type="tel"
                    inputMode="numeric"
                    required
                    maxLength={12}
                    value={phone}
                    onChange={(e) => setPhone(formatDigitsOnly(e.target.value, 12))}
                    placeholder="09171234567 or 0281234567"
                    className="w-full bg-charcoal-canvas border border-charcoal-border rounded-xl px-3.5 py-2.5 focus:outline-none focus:border-charcoal-header"
                  />
                </div>
              </div>
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                <div>
                  <label className="block font-semibold mb-1">Vehicle</label>
                  <input
                    type="text"
                    required
                    maxLength={60}
                    value={vehicle}
                    onChange={(e) => setVehicle(e.target.value)}
                    className="w-full bg-charcoal-canvas border border-charcoal-border rounded-xl px-3.5 py-2.5 focus:outline-none focus:border-charcoal-header"
                  />
                </div>
                <div>
                  <label className="block font-semibold mb-1">Plate Number</label>
                  <input
                    type="text"
                    maxLength={9}
                    value={plateNumber}
                    onChange={(e) => setPlateNumber(formatPlateNumber(e.target.value))}
                    placeholder="ABC-1234 or 7821-AB"
                    className="w-full bg-charcoal-canvas border border-charcoal-border rounded-xl px-3.5 py-2.5 font-mono uppercase focus:outline-none focus:border-charcoal-header"
                  />
                </div>
              </div>
              <div className="pt-2 border-t border-charcoal-border space-y-3">
                <div>
                  <label className="block font-semibold mb-1">Driver Login Email</label>
                  <input
                    type="email"
                    required
                    maxLength={100}
                    value={email}
                    onChange={(e) => setEmail(e.target.value.replace(/\s+/g, ''))}
                    placeholder="cardo@charcoal.ph"
                    className="w-full bg-charcoal-canvas border border-charcoal-border rounded-xl px-3.5 py-2.5 font-mono focus:outline-none focus:border-charcoal-header"
                  />
                </div>
                <div>
                  <label className="block font-semibold mb-1">Assigned Password</label>
                  <div className="relative">
                    <input
                      type={showPassword ? 'text' : 'password'}
                      required
                      maxLength={64}
                      value={password}
                      onChange={(e) => setPassword(e.target.value)}
                      placeholder="Min 8 chars, uppercase, number, symbol"
                      className="w-full bg-charcoal-canvas border border-charcoal-border rounded-xl pl-3.5 pr-10 py-2.5 font-mono focus:outline-none focus:border-charcoal-header"
                    />
                    <button
                      type="button"
                      onClick={() => setShowPassword((prev) => !prev)}
                      aria-label={showPassword ? 'Hide password' : 'Show password'}
                      className="absolute right-3 top-1/2 -translate-y-1/2 text-charcoal-muted hover:text-charcoal-ink"
                    >
                      {showPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                    </button>
                  </div>
                </div>
                <div>
                  <label className="block font-semibold mb-1">Confirm Assigned Password</label>
                  <div className="relative">
                    <input
                      type={showConfirmPassword ? 'text' : 'password'}
                      required
                      maxLength={64}
                      value={confirmPassword}
                      onChange={(e) => setConfirmPassword(e.target.value)}
                      placeholder="Re-enter assigned password"
                      className="w-full bg-charcoal-canvas border border-charcoal-border rounded-xl pl-3.5 pr-10 py-2.5 font-mono focus:outline-none focus:border-charcoal-header"
                    />
                    <button
                      type="button"
                      onClick={() => setShowConfirmPassword((prev) => !prev)}
                      aria-label={showConfirmPassword ? 'Hide confirm password' : 'Show confirm password'}
                      className="absolute right-3 top-1/2 -translate-y-1/2 text-charcoal-muted hover:text-charcoal-ink"
                    >
                      {showConfirmPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                    </button>
                  </div>
                  <div className="mt-2 p-2.5 rounded-xl bg-charcoal-canvas border border-charcoal-border grid grid-cols-2 gap-1.5 text-[11px]">
                    {[
                      { met: passReqs.hasMinLength, label: '8–64 characters' },
                      { met: passReqs.hasUppercase, label: '1 uppercase letter' },
                      { met: passReqs.hasNumber, label: '1 number' },
                      { met: passReqs.hasSpecialChar, label: '1 special character' },
                      { met: passReqs.passwordsMatch, label: 'Passwords match' },
                    ].map((req) => (
                      <div
                        key={req.label}
                        className={`flex items-center gap-1.5 ${
                          req.met ? 'text-charcoal-eco font-semibold' : 'text-charcoal-muted'
                        }`}
                      >
                        <CheckCircle2 className={`w-3.5 h-3.5 shrink-0 ${req.met ? 'opacity-100' : 'opacity-35'}`} />
                        <span>{req.label}</span>
                      </div>
                    ))}
                  </div>
                </div>
              </div>
              <div className="flex justify-end gap-2 pt-2">
                <button
                  type="button"
                  disabled={isSubmitting}
                  onClick={() => setShowCreateModal(false)}
                  className="px-4 py-2 bg-charcoal-canvas border border-charcoal-border rounded-xl font-semibold"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={isSubmitting}
                  className="px-5 py-2 bg-charcoal-header hover:bg-charcoal-dark disabled:opacity-60 text-white rounded-xl font-bold"
                >
                  {isSubmitting ? 'Creating...' : 'Create Driver'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Edit Driver Modal */}
      {editingDriver && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm p-4">
          <div className="bg-white border border-charcoal-border rounded-2xl p-6 w-full max-w-md shadow-2xl text-charcoal-ink">
            <h3 className="font-bold text-lg mb-1">Edit Driver Details</h3>
            <p className="text-xs text-charcoal-muted mb-4">{editingDriver.email}</p>
            <form onSubmit={handleSaveEdit} className="space-y-3 text-xs">
              {formError && (
                <div className="p-3 rounded-xl bg-rose-50 border border-rose-200 text-rose-700">{formError}</div>
              )}
              <div>
                <label className="block font-semibold mb-1">Driver Name</label>
                <input
                  type="text"
                  required
                  maxLength={60}
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  className="w-full bg-charcoal-canvas border border-charcoal-border rounded-xl px-3.5 py-2.5"
                />
              </div>
              <div>
                <label className="block font-semibold mb-1">Mobile / Telephone Number</label>
                <input
                  type="tel"
                  inputMode="numeric"
                  required
                  maxLength={12}
                  value={phone}
                  onChange={(e) => setPhone(formatDigitsOnly(e.target.value, 12))}
                  placeholder="09171234567 or 0281234567"
                  className="w-full bg-charcoal-canvas border border-charcoal-border rounded-xl px-3.5 py-2.5"
                />
              </div>
              <div>
                <label className="block font-semibold mb-1">Vehicle</label>
                <input
                  type="text"
                  required
                  maxLength={60}
                  value={vehicle}
                  onChange={(e) => setVehicle(e.target.value)}
                  className="w-full bg-charcoal-canvas border border-charcoal-border rounded-xl px-3.5 py-2.5"
                />
              </div>
              <div>
                <label className="block font-semibold mb-1">Plate Number</label>
                <input
                  type="text"
                  maxLength={9}
                  value={plateNumber}
                  onChange={(e) => setPlateNumber(formatPlateNumber(e.target.value))}
                  placeholder="ABC-1234 or 7821-AB"
                  className="w-full bg-charcoal-canvas border border-charcoal-border rounded-xl px-3.5 py-2.5 font-mono uppercase"
                />
              </div>
              <div className="flex justify-end gap-2 pt-2">
                <button
                  type="button"
                  onClick={() => setEditingDriver(null)}
                  className="px-4 py-2 bg-charcoal-canvas border border-charcoal-border rounded-xl font-semibold"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={isSubmitting}
                  className="px-5 py-2 bg-charcoal-eco hover:bg-[#2F6346] text-white rounded-xl font-bold"
                >
                  {isSubmitting ? 'Saving...' : 'Save Changes'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Deactivate / Reactivate Confirmation Modal */}
      {toggleDriverTarget && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm p-4">
          <div className="bg-white border border-charcoal-border rounded-2xl p-6 w-full max-w-sm shadow-2xl text-charcoal-ink">
            <h3 className="font-bold text-base mb-1">
              {toggleDriverTarget.isActive === false ? 'Reactivate' : 'Deactivate'} Driver {toggleDriverTarget.name}?
            </h3>
            <p className="text-xs text-charcoal-muted mb-4">
              {toggleDriverTarget.isActive === false
                ? 'This driver will be allowed to log in and accept deliveries again.'
                : 'This driver will no longer be able to log in or update deliveries.'}
            </p>
            <div className="flex justify-end gap-2 text-xs">
              <button
                type="button"
                onClick={() => setToggleDriverTarget(null)}
                className="px-4 py-2 bg-charcoal-canvas border border-charcoal-border rounded-xl font-semibold"
              >
                Cancel
              </button>
              <button
                type="button"
                onClick={() => {
                  const target = toggleDriverTarget;
                  setToggleDriverTarget(null);
                  handleToggleActive(target);
                }}
                className={`px-4 py-2 text-white rounded-xl font-bold ${
                  toggleDriverTarget.isActive === false
                    ? 'bg-charcoal-eco hover:bg-[#2F6346]'
                    : 'bg-rose-600 hover:bg-rose-700'
                }`}
              >
                Confirm
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Delete Driver Confirmation Modal */}
      {deleteDriverTarget && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm p-4">
          <div className="bg-white border border-charcoal-border rounded-2xl p-6 w-full max-w-sm shadow-2xl text-charcoal-ink">
            <h3 className="font-bold text-base text-rose-700 mb-1">
              Delete Driver {deleteDriverTarget.name}?
            </h3>
            <p className="text-xs text-charcoal-muted mb-4">
              This will permanently remove their driver profile ({deleteDriverTarget.email}) and block all app login access. This action cannot be undone.
            </p>
            <div className="flex justify-end gap-2 text-xs">
              <button
                type="button"
                disabled={isDeleting}
                onClick={() => setDeleteDriverTarget(null)}
                className="px-4 py-2 bg-charcoal-canvas border border-charcoal-border rounded-xl font-semibold"
              >
                Cancel
              </button>
              <button
                type="button"
                disabled={isDeleting}
                onClick={async () => {
                  const target = deleteDriverTarget;
                  setDeleteDriverTarget(null);
                  await handleDeleteDriver(target);
                }}
                className="px-4 py-2 bg-rose-600 hover:bg-rose-700 disabled:opacity-60 text-white rounded-xl font-bold"
              >
                {isDeleting ? 'Deleting...' : 'Delete Driver'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
