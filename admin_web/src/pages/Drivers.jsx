import React, { useEffect, useState } from 'react';
import { ref, onValue, set, push, remove } from 'firebase/database';
import { db } from '../firebase';
import { UserPlus, Bike, Phone, Mail, ShieldAlert, Trash2 } from 'lucide-react';

export default function Drivers() {
  const [drivers, setDrivers] = useState([]);
  const [showModal, setShowModal] = useState(false);
  const [name, setName] = useState('');
  const [phone, setPhone] = useState('');
  const [vehicle, setVehicle] = useState('Motorcycle (Honda Wave 110)');
  const [plateNumber, setPlateNumber] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('charcoal123');

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
    if (!name || !email) return;

    const newDriverRef = push(ref(db, 'drivers'));
    const driverId = newDriverRef.key;

    await set(newDriverRef, {
      name,
      phone,
      vehicle,
      plateNumber,
      email,
      password,
      isOnline: false,
      createdAt: new Date().toISOString()
    });

    // Reset form
    setName('');
    setPhone('');
    setPlateNumber('');
    setEmail('');
    setPassword('charcoal123');
    setShowModal(false);
  };

  const handleDeleteDriver = async (driverId) => {
    if (confirm('Sigurado ka bang gusto mong tanggalin ang driver na ito?')) {
      await remove(ref(db, `drivers/${driverId}`));
    }
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
        <div>
          <h1 className="text-2xl font-bold text-white tracking-tight">Delivery Drivers Management</h1>
          <p className="text-sm text-slate-400">
            Ikaw (Admin) lamang ang may kapangyarihang mag-create ng driver accounts.
          </p>
        </div>
        <button
          onClick={() => setShowModal(true)}
          className="px-4 py-2.5 bg-amber-600 hover:bg-amber-700 text-white rounded-xl text-xs font-bold shadow-md transition-all flex items-center gap-2"
        >
          <UserPlus className="w-4 h-4" />
          + Create New Driver
        </button>
      </div>

      {/* Info Notice */}
      <div className="bg-slate-800/80 border border-slate-700/80 rounded-2xl p-4 flex items-start gap-3">
        <ShieldAlert className="w-5 h-5 text-amber-400 shrink-0 mt-0.5" />
        <div className="text-xs text-slate-300">
          <p className="font-bold text-white">Admin-Controlled Driver Registration</p>
          <p className="mt-0.5 text-slate-400">
            Walang public registration ang mga driver sa mobile app para maiwasan ang mga pekeng rider. Ibigay ang Email at Password na nilikha mo rito sa iyong delivery driver para makapag-log in sila sa mobile app.
          </p>
        </div>
      </div>

      {/* Drivers List */}
      <div className="bg-slate-800/80 border border-slate-700/80 rounded-2xl shadow-xl overflow-hidden">
        {drivers.length === 0 ? (
          <div className="py-16 text-center text-slate-400 text-sm">
            Wala pang driver accounts. Pindutin ang "+ Create New Driver" sa itaas para mag-assign ng driver.
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs min-w-[700px]">
              <thead className="bg-slate-900/60 border-b border-slate-700 text-slate-400 font-semibold">
                <tr>
                  <th className="p-4">Driver Name</th>
                  <th className="p-4">Vehicle & Plate #</th>
                  <th className="p-4">Login Credentials</th>
                  <th className="p-4">GPS Broadcast Status</th>
                  <th className="p-4 text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-700/50">
                {drivers.map(driver => (
                  <tr key={driver.id} className="hover:bg-slate-750 transition-colors">
                    
                    {/* Driver Profile */}
                    <td className="p-4">
                      <div className="flex items-center gap-3">
                        <div className="w-10 h-10 rounded-xl bg-amber-500/15 text-amber-400 font-bold flex items-center justify-center text-sm border border-amber-500/20">
                          {driver.name ? driver.name.substring(0, 2).toUpperCase() : 'DR'}
                        </div>
                        <div>
                          <p className="font-bold text-white text-sm">{driver.name}</p>
                          <p className="text-[11px] text-slate-400 flex items-center gap-1 mt-0.5">
                            <Phone className="w-3 h-3 text-slate-500" />
                            {driver.phone || 'No phone'}
                          </p>
                        </div>
                      </div>
                    </td>

                    {/* Vehicle */}
                    <td className="p-4">
                      <p className="font-semibold text-slate-200">{driver.vehicle || 'Motorcycle'}</p>
                      <p className="text-[11px] text-slate-400 font-mono mt-0.5">
                        Plate: {driver.plateNumber || 'N/A'}
                      </p>
                    </td>

                    {/* Credentials */}
                    <td className="p-4 font-mono text-[11px]">
                      <p className="text-blue-400 flex items-center gap-1">
                        <Mail className="w-3 h-3 text-blue-400" />
                        {driver.email}
                      </p>
                      <p className="text-slate-400 mt-0.5">Password: ••••••••</p>
                    </td>

                    {/* GPS Status */}
                    <td className="p-4">
                      <span className={`px-2.5 py-1 rounded-full text-[10px] font-bold ${
                        driver.isOnline
                          ? 'bg-emerald-500/15 text-emerald-400 border border-emerald-500/30'
                          : 'bg-slate-700 text-slate-400 border border-slate-600'
                      }`}>
                        {driver.isOnline ? '🟢 GPS Stream Active' : '⚪ Standby / Offline'}
                      </span>
                    </td>

                    {/* Actions */}
                    <td className="p-4 text-right">
                      <button
                        onClick={() => handleDeleteDriver(driver.id)}
                        className="p-2 text-slate-400 hover:text-rose-400 hover:bg-slate-700 rounded-lg transition-colors"
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
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/70 backdrop-blur-sm p-4">
          <div className="bg-slate-800 border border-slate-700 rounded-2xl p-6 w-full max-w-lg shadow-2xl">
            <h3 className="font-bold text-lg text-white mb-1">Create New Delivery Driver Account</h3>
            <p className="text-xs text-slate-400 mb-4">
              I-fill out ang mga detalye ng driver para makapag-login sa mobile app.
            </p>
            
            <form onSubmit={handleCreateDriver} className="space-y-4 text-xs">
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                <div>
                  <label className="block text-slate-300 font-semibold mb-1">Pangalan ng Driver</label>
                  <input
                    type="text"
                    required
                    value={name}
                    onChange={e => setName(e.target.value)}
                    placeholder="Hal. Cardo Dalisay"
                    className="w-full bg-slate-900 border border-slate-700 rounded-xl px-3.5 py-2.5 text-white text-xs focus:outline-amber-500"
                  />
                </div>
                <div>
                  <label className="block text-slate-300 font-semibold mb-1">Mobile Contact Number</label>
                  <input
                    type="text"
                    required
                    value={phone}
                    onChange={e => setPhone(e.target.value)}
                    placeholder="Hal. 0917-888-9900"
                    className="w-full bg-slate-900 border border-slate-700 rounded-xl px-3.5 py-2.5 text-white text-xs focus:outline-amber-500"
                  />
                </div>
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                <div>
                  <label className="block text-slate-300 font-semibold mb-1">Uri ng Sasakyan</label>
                  <input
                    type="text"
                    value={vehicle}
                    onChange={e => setVehicle(e.target.value)}
                    placeholder="Hal. Honda Wave 110"
                    className="w-full bg-slate-900 border border-slate-700 rounded-xl px-3.5 py-2.5 text-white text-xs focus:outline-amber-500"
                  />
                </div>
                <div>
                  <label className="block text-slate-300 font-semibold mb-1">Plate Number</label>
                  <input
                    type="text"
                    value={plateNumber}
                    onChange={e => setPlateNumber(e.target.value)}
                    placeholder="Hal. 7821-AB"
                    className="w-full bg-slate-900 border border-slate-700 rounded-xl px-3.5 py-2.5 text-white text-xs font-mono focus:outline-amber-500"
                  />
                </div>
              </div>

              <div className="pt-2 border-t border-slate-700 space-y-3">
                <div>
                  <label className="block text-slate-300 font-semibold mb-1">Driver Login Email</label>
                  <input
                    type="email"
                    required
                    value={email}
                    onChange={e => setEmail(e.target.value)}
                    placeholder="Hal. cardo@charcoal.ph"
                    className="w-full bg-slate-900 border border-slate-700 rounded-xl px-3.5 py-2.5 text-white text-xs font-mono focus:outline-amber-500"
                  />
                </div>
                <div>
                  <label className="block text-slate-300 font-semibold mb-1">Temporary Password</label>
                  <input
                    type="text"
                    required
                    value={password}
                    onChange={e => setPassword(e.target.value)}
                    className="w-full bg-slate-900 border border-slate-700 rounded-xl px-3.5 py-2.5 text-white text-xs font-mono focus:outline-amber-500"
                  />
                </div>
              </div>

              <div className="flex justify-end gap-2 pt-2">
                <button
                  type="button"
                  onClick={() => setShowModal(false)}
                  className="px-4 py-2 bg-slate-700 hover:bg-slate-600 rounded-xl font-semibold text-slate-300"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="px-5 py-2 bg-amber-600 hover:bg-amber-700 text-white rounded-xl font-bold shadow-md"
                >
                  Create & Save Account
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
