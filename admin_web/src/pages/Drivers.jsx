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
  Copy,
} from 'lucide-react';
import Pagination from '../components/Pagination';

const VEHICLE_CATALOG = {
  Motorcycle: {
    Honda: {
      models: ['Wave 110', 'TMX 125 Alpha', 'Click 125i', 'Click 160', 'Beat 110', 'XRM 125'],
      ccs: ['110cc', '125cc', '150cc', '160cc'],
    },
    Yamaha: {
      models: ['Mio i 125', 'Sight 115', 'Sniper 155', 'NMAX 155', 'Aerox 155'],
      ccs: ['115cc', '125cc', '150cc', '155cc'],
    },
    Suzuki: {
      models: ['Smash 115', 'Raider J Crossover', 'Raider R150', 'Burgman Street 125'],
      ccs: ['115cc', '125cc', '150cc'],
    },
    Kawasaki: {
      models: ['Barako II 175', 'Bajaj CT100', 'Bajaj CT125', 'Rouser NS160'],
      ccs: ['100cc', '125cc', '160cc', '175cc'],
    },
    Rusi: {
      models: ['MP 110', 'Macho 125', 'TC 150', 'Classic 250'],
      ccs: ['110cc', '125cc', '150cc', '250cc'],
    },
  },
  'Elf Truck': {
    Isuzu: {
      models: ['NHR', 'NKR', 'NPR', 'NLR 77', 'NLR 85'],
      ccs: ['2771cc', '2999cc', '4570cc', '4751cc'],
    },
    'Mitsubishi Fuso': {
      models: ['Canter FE71', 'Canter FE73', 'Canter FE84', 'Canter FE85'],
      ccs: ['2998cc', '3908cc', '4899cc'],
    },
    Hino: {
      models: ['300 Series XZU600', '300 Series XZU710', 'Dutro 300'],
      ccs: ['4009cc', '4899cc'],
    },
  },
  L300: {
    Mitsubishi: {
      models: ['L300 FB Exceed', 'L300 Cab & Chassis', 'L300 Dropside'],
      ccs: ['2268cc (4N14)', '2477cc (4D56)'],
    },
  },
};

function generateDefaultDriverPassword(lname, plate) {
  const cleanLast = sanitizeText(lname).replace(/\s+/g, '');
  const cleanPlate = formatPlateNumber(plate).replace(/-/g, '').replace(/\s+/g, '');
  if (!cleanLast || !cleanPlate) return '';
  return `${cleanLast}${cleanPlate}`;
}

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

  const [firstName, setFirstName] = useState('');
  const [middleName, setMiddleName] = useState('');
  const [lastName, setLastName] = useState('');
  const [editName, setEditName] = useState('');
  const [editVehicle, setEditVehicle] = useState('');
  const [phone, setPhone] = useState('');
  const [vehicleType, setVehicleType] = useState('Motorcycle');
  const [vehicleBrand, setVehicleBrand] = useState('Honda');
  const [vehicleModel, setVehicleModel] = useState('Wave 110');
  const [vehicleCc, setVehicleCc] = useState('110cc');
  const [plateNumber, setPlateNumber] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [manualPasswordOverride, setManualPasswordOverride] = useState(false);
  const [copiedPass, setCopiedPass] = useState(false);
  const [showPassword, setShowPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);
  const [formError, setFormError] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [currentPage, setCurrentPage] = useState(1);
  const [pageSize, setPageSize] = useState(10);
  const passReqs = checkPasswordRequirements(password, confirmPassword);

  const handleVehicleTypeChange = (nextType) => {
    const brands = Object.keys(VEHICLE_CATALOG[nextType] || {});
    const nextBrand = brands[0] || '';
    const spec = VEHICLE_CATALOG[nextType]?.[nextBrand] || { models: [], ccs: [] };
    setVehicleType(nextType);
    setVehicleBrand(nextBrand);
    setVehicleModel(spec.models[0] || '');
    setVehicleCc(spec.ccs[0] || '');
  };

  const handleVehicleBrandChange = (nextBrand) => {
    const spec = VEHICLE_CATALOG[vehicleType]?.[nextBrand] || { models: [], ccs: [] };
    setVehicleBrand(nextBrand);
    setVehicleModel(spec.models[0] || '');
    setVehicleCc(spec.ccs[0] || '');
  };

  useEffect(() => {
    if (!manualPasswordOverride) {
      const autoPass = generateDefaultDriverPassword(lastName, plateNumber);
      setPassword(autoPass);
      setConfirmPassword(autoPass);
    }
  }, [lastName, plateNumber, manualPasswordOverride]);

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
        setOrders(
          Object.keys(val).map((k) => ({
            ...val[k],
            id: k,
            displayId: val[k]?.id || k,
          }))
        );
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

    const fnameErr = validateName(firstName, 'First Name', 2, 40);
    if (fnameErr) return setFormError(fnameErr);

    const cleanMiddle = sanitizeText(middleName);
    if (cleanMiddle) {
      const mnameErr = validateName(cleanMiddle, 'Middle Name', 1, 40);
      if (mnameErr) return setFormError(mnameErr);
    }

    const lnameErr = validateName(lastName, 'Last Name', 2, 40);
    if (lnameErr) return setFormError(lnameErr);

    const fullName = [sanitizeText(firstName), cleanMiddle, sanitizeText(lastName)]
      .filter(Boolean)
      .join(' ');

    const phoneErr = validatePhPhone(phone);
    if (phoneErr) return setFormError(phoneErr);

    const cleanVehicle = `${vehicleType} (${vehicleBrand} ${vehicleModel} ${vehicleCc})`.trim();

    const cleanPlate = formatPlateNumber(plateNumber);
    const plateErr = validatePlateNumber(cleanPlate);
    if (plateErr) return setFormError(plateErr);

    const emailErr = validateEmail(email);
    if (emailErr) return setFormError(emailErr);

    if (!password || password.length < 8 || password.length > 64) {
      return setFormError('Driver password must be 8–64 characters.');
    }
    if (!/[A-Za-z]/.test(password) || !/[0-9]/.test(password)) {
      return setFormError('Driver password must contain letters and numbers.');
    }

    if (password !== confirmPassword) {
      return setFormError('Passwords do not match.');
    }

    setIsSubmitting(true);
    let secondaryApp = null;
    let createdAuthUser = null;
    try {
      const cleanName = fullName;
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
        firstName: sanitizeText(firstName),
        middleName: cleanMiddle,
        lastName: sanitizeText(lastName),
        phone: cleanPhone,
        vehicle: cleanVehicle,
        vehicleType,
        vehicleBrand,
        vehicleModel,
        vehicleCc,
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
        firstName: sanitizeText(firstName),
        middleName: cleanMiddle,
        lastName: sanitizeText(lastName),
        phone: cleanPhone,
        email: cleanEmail,
        role: 'driver',
        isActive: true,
        createdAt: payload.createdAt,
      });

      await signOut(secondaryAuth);
      createdAuthUser = null;

      setFirstName('');
      setMiddleName('');
      setLastName('');
      setPhone('');
      handleVehicleTypeChange('Motorcycle');
      setPlateNumber('');
      setEmail('');
      setPassword('');
      setConfirmPassword('');
      setManualPasswordOverride(false);
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
    setEditName(driver.name || '');
    setPhone(formatDigitsOnly(driver.phone || '', 12));
    setEditVehicle(driver.vehicle || 'Motorcycle');
    setPlateNumber(formatPlateNumber(driver.plateNumber || ''));
  };

  const handleSaveEdit = async (e) => {
    e.preventDefault();
    if (!editingDriver || isSubmitting) return;
    setFormError('');

    const nameErr = validateName(editName, 'Driver Name');
    if (nameErr) return setFormError(nameErr);
    const phoneErr = validatePhPhone(phone);
    if (phoneErr) return setFormError(phoneErr);

    const cleanName = sanitizeText(editName);
    const cleanPhone = formatDigitsOnly(phone, 12);
    const cleanVehicle = sanitizeText(editVehicle);
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
            setFirstName('');
            setMiddleName('');
            setLastName('');
            setPhone('');
            handleVehicleTypeChange('Motorcycle');
            setPlateNumber('');
            setEmail('');
            setPassword('');
            setConfirmPassword('');
            setManualPasswordOverride(false);
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
          <>
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
                {drivers
                  .slice((currentPage - 1) * pageSize, currentPage * pageSize)
                  .map((driver) => {
                  const isActive = driver.isActive !== false;
                  const activeCount = orders.filter(
                    (o) => o.driverId === driver.id && (o.status === 'Confirmed' || o.status === 'Out for Delivery')
                  ).length;
                  const completedOrders = orders.filter(
                    (o) => o.driverId === driver.id && o.status === 'Delivered'
                  );
                  const completedCount = completedOrders.length;
                  const deliveredSacks = completedOrders.reduce(
                    (sum, o) => sum + (Number(o.sacksOrdered) || 0),
                    0
                  );
                  const todayStr = new Date().toDateString();
                  const todayCodRemit = completedOrders
                    .filter((o) => {
                      const d = o.deliveredAt || o.createdAt;
                      return d && new Date(d).toDateString() === todayStr && o.paymentMethod !== 'ONLINE_QR';
                    })
                    .reduce((sum, o) => sum + (Number(o.totalAmount) || 0), 0);

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
                          {activeCount} active • {completedCount} delivered ({deliveredSacks} sacks)
                        </p>
                        <p className="text-[11px] font-semibold text-charcoal-eco mt-0.5">
                          Today&apos;s COD Remit: ₱{todayCodRemit.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
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
          <Pagination
            totalItems={drivers.length}
            currentPage={currentPage}
            pageSize={pageSize}
            onPageChange={setCurrentPage}
            onPageSizeChange={setPageSize}
          />
          </>
        )}
      </div>

      {/* Create Driver Modal */}
      {showCreateModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm p-4 overflow-y-auto">
          <div className="bg-white border border-charcoal-border rounded-2xl p-6 w-full max-w-xl shadow-2xl text-charcoal-ink my-8">
            <h3 className="font-bold text-lg text-charcoal-ink mb-1">Create New Delivery Driver</h3>
            <p className="text-xs text-charcoal-muted mb-4">Fill out the driver details so they can log in to the Rider mobile app.</p>

            <form onSubmit={handleCreateDriver} className="space-y-4 text-xs">
              {formError && (
                <div className="p-3 rounded-xl bg-rose-50 border border-rose-200 flex items-start gap-2 text-rose-700">
                  <AlertCircle className="w-4 h-4 text-rose-600 shrink-0 mt-0.5" />
                  <span>{formError}</span>
                </div>
              )}

              {/* Driver Name: First / Middle / Last */}
              <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
                <div>
                  <label className="block font-semibold mb-1">First Name *</label>
                  <input
                    type="text"
                    required
                    maxLength={40}
                    value={firstName}
                    onChange={(e) => setFirstName(e.target.value)}
                    placeholder="Cardo"
                    className="w-full bg-charcoal-canvas border border-charcoal-border rounded-xl px-3.5 py-2.5 focus:outline-none focus:border-charcoal-header"
                  />
                </div>
                <div>
                  <label className="block font-semibold mb-1">Middle Name</label>
                  <input
                    type="text"
                    maxLength={40}
                    value={middleName}
                    onChange={(e) => setMiddleName(e.target.value)}
                    placeholder="Optional"
                    className="w-full bg-charcoal-canvas border border-charcoal-border rounded-xl px-3.5 py-2.5 focus:outline-none focus:border-charcoal-header"
                  />
                </div>
                <div>
                  <label className="block font-semibold mb-1">Last Name *</label>
                  <input
                    type="text"
                    required
                    maxLength={40}
                    value={lastName}
                    onChange={(e) => setLastName(e.target.value)}
                    placeholder="Dalisay"
                    className="w-full bg-charcoal-canvas border border-charcoal-border rounded-xl px-3.5 py-2.5 focus:outline-none focus:border-charcoal-header"
                  />
                </div>
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                <div>
                  <label className="block font-semibold mb-1">Mobile / Telephone Number *</label>
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
                <div>
                  <label className="block font-semibold mb-1">Plate Number *</label>
                  <input
                    type="text"
                    required
                    maxLength={9}
                    value={plateNumber}
                    onChange={(e) => setPlateNumber(formatPlateNumber(e.target.value))}
                    placeholder="ABC-1234 or 7821-AB"
                    className="w-full bg-charcoal-canvas border border-charcoal-border rounded-xl px-3.5 py-2.5 font-mono uppercase focus:outline-none focus:border-charcoal-header"
                  />
                </div>
              </div>

              {/* Vehicle Cascading Dropdowns */}
              <div className="p-3 rounded-xl bg-charcoal-canvas/70 border border-charcoal-border space-y-3">
                <p className="font-bold text-charcoal-ink">Vehicle Specification</p>
                <div className="grid grid-cols-2 sm:grid-cols-4 gap-2.5">
                  <div>
                    <label className="block font-semibold mb-1">Vehicle Type</label>
                    <select
                      value={vehicleType}
                      onChange={(e) => handleVehicleTypeChange(e.target.value)}
                      className="w-full bg-white border border-charcoal-border rounded-xl px-2.5 py-2 focus:outline-none focus:border-charcoal-header"
                    >
                      {Object.keys(VEHICLE_CATALOG).map((t) => (
                        <option key={t} value={t}>
                          {t}
                        </option>
                      ))}
                    </select>
                  </div>
                  <div>
                    <label className="block font-semibold mb-1">Brand</label>
                    <select
                      value={vehicleBrand}
                      onChange={(e) => handleVehicleBrandChange(e.target.value)}
                      className="w-full bg-white border border-charcoal-border rounded-xl px-2.5 py-2 focus:outline-none focus:border-charcoal-header"
                    >
                      {Object.keys(VEHICLE_CATALOG[vehicleType] || {}).map((b) => (
                        <option key={b} value={b}>
                          {b}
                        </option>
                      ))}
                    </select>
                  </div>
                  <div>
                    <label className="block font-semibold mb-1">Model</label>
                    <select
                      value={vehicleModel}
                      onChange={(e) => setVehicleModel(e.target.value)}
                      className="w-full bg-white border border-charcoal-border rounded-xl px-2.5 py-2 focus:outline-none focus:border-charcoal-header"
                    >
                      {(VEHICLE_CATALOG[vehicleType]?.[vehicleBrand]?.models || []).map((m) => (
                        <option key={m} value={m}>
                          {m}
                        </option>
                      ))}
                    </select>
                  </div>
                  <div>
                    <label className="block font-semibold mb-1">Engine CC</label>
                    <select
                      value={vehicleCc}
                      onChange={(e) => setVehicleCc(e.target.value)}
                      className="w-full bg-white border border-charcoal-border rounded-xl px-2.5 py-2 focus:outline-none focus:border-charcoal-header"
                    >
                      {(VEHICLE_CATALOG[vehicleType]?.[vehicleBrand]?.ccs || []).map((c) => (
                        <option key={c} value={c}>
                          {c}
                        </option>
                      ))}
                    </select>
                  </div>
                </div>
              </div>

              <div className="pt-2 border-t border-charcoal-border space-y-3">
                <div>
                  <label className="block font-semibold mb-1">Driver Login Email *</label>
                  <input
                    type="email"
                    name="new_driver_email"
                    autoComplete="off"
                    required
                    maxLength={100}
                    value={email}
                    onChange={(e) => setEmail(e.target.value.replace(/\s+/g, ''))}
                    placeholder="cardo@charcoal.ph"
                    className="w-full bg-charcoal-canvas border border-charcoal-border rounded-xl px-3.5 py-2.5 font-mono focus:outline-none focus:border-charcoal-header"
                  />
                </div>
                <div>
                  <div className="flex items-center justify-between mb-1">
                    <label className="block font-semibold">
                      Default Password{' '}
                      <span className="font-normal text-charcoal-muted">
                        (Last Name + Plate # without -)
                      </span>
                    </label>
                    <div className="flex items-center gap-2">
                      {password && (
                        <button
                          type="button"
                          onClick={() => {
                            navigator.clipboard?.writeText(password);
                            setCopiedPass(true);
                            setTimeout(() => setCopiedPass(false), 1500);
                          }}
                          className="inline-flex items-center gap-1 text-[11px] font-semibold text-charcoal-eco hover:underline"
                        >
                          <Copy className="w-3 h-3" />
                          {copiedPass ? 'Copied!' : 'Copy'}
                        </button>
                      )}
                      <button
                        type="button"
                        onClick={() => setManualPasswordOverride((prev) => !prev)}
                        className="text-[11px] font-semibold text-charcoal-header hover:underline"
                      >
                        {manualPasswordOverride ? 'Use Auto Default' : 'Customize'}
                      </button>
                    </div>
                  </div>
                  <div className="relative">
                    <input
                      type={showPassword || !manualPasswordOverride ? 'text' : 'password'}
                      name="new_driver_password"
                      autoComplete="new-password"
                      required
                      readOnly={!manualPasswordOverride}
                      maxLength={64}
                      value={password}
                      onChange={(e) => {
                        setPassword(e.target.value);
                        if (!manualPasswordOverride) setConfirmPassword(e.target.value);
                      }}
                      placeholder="Enter Last Name & Plate Number to auto-generate"
                      className={`w-full border border-charcoal-border rounded-xl pl-3.5 pr-10 py-2.5 font-mono focus:outline-none focus:border-charcoal-header ${
                        manualPasswordOverride ? 'bg-charcoal-canvas' : 'bg-[#E8F3EC]/60 text-charcoal-header font-bold'
                      }`}
                    />
                    {manualPasswordOverride && (
                      <button
                        type="button"
                        onClick={() => setShowPassword((prev) => !prev)}
                        aria-label={showPassword ? 'Hide password' : 'Show password'}
                        className="absolute right-3 top-1/2 -translate-y-1/2 text-charcoal-muted hover:text-charcoal-ink"
                      >
                        {showPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                      </button>
                    )}
                  </div>
                </div>
                {manualPasswordOverride && (
                  <div>
                    <label className="block font-semibold mb-1">Confirm Assigned Password</label>
                    <div className="relative">
                      <input
                        type={showConfirmPassword ? 'text' : 'password'}
                        name="new_driver_confirm_password"
                        autoComplete="new-password"
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
                  </div>
                )}
                <div className="p-2.5 rounded-xl bg-charcoal-canvas border border-charcoal-border grid grid-cols-3 gap-1.5 text-[11px]">
                  {[
                    { met: passReqs.hasMinLength, label: '8–64 chars' },
                    { met: /[A-Za-z]/.test(password) && passReqs.hasNumber, label: 'Letters & numbers' },
                    { met: passReqs.passwordsMatch, label: 'Confirmed' },
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
                  value={editName}
                  onChange={(e) => setEditName(e.target.value)}
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
                  value={editVehicle}
                  onChange={(e) => setEditVehicle(e.target.value)}
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
