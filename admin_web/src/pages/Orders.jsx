import React, { useEffect, useState } from 'react';
import { ref, onValue, update } from 'firebase/database';
import { db } from '../firebase';
import { Filter, CheckCircle, Truck, XCircle, Clock, MapPin, Phone } from 'lucide-react';

export default function Orders() {
  const [orders, setOrders] = useState([]);
  const [drivers, setDrivers] = useState([]);
  const [filter, setFilter] = useState('ALL');
  const [updatingOrderId, setUpdatingOrderId] = useState(null);
  const [actionError, setActionError] = useState('');

  const ALLOWED_STATUSES = ['Pending', 'Confirmed', 'Out for Delivery', 'Delivered', 'Cancelled'];

  useEffect(() => {
    // 1. Listen to orders
    const ordersRef = ref(db, 'orders');
    const unsubOrders = onValue(ordersRef, (snap) => {
      if (snap.exists()) {
        const val = snap.val();
        const list = Object.keys(val).map(key => ({ id: key, ...val[key] }));
        list.sort((a, b) => new Date(b.createdAt || 0) - new Date(a.createdAt || 0));
        setOrders(list);
      } else {
        setOrders([]);
      }
    });

    // 2. Listen to drivers
    const driversRef = ref(db, 'drivers');
    const unsubDrivers = onValue(driversRef, (snap) => {
      if (snap.exists()) {
        const val = snap.val();
        setDrivers(Object.keys(val).map(k => ({ id: k, ...val[k] })));
      } else {
        setDrivers([]);
      }
    });

    return () => {
      unsubOrders();
      unsubDrivers();
    };
  }, []);

  const handleUpdateStatus = async (orderId, newStatus) => {
    if (updatingOrderId === orderId) return;
    if (!ALLOWED_STATUSES.includes(newStatus)) return;
    setActionError('');
    if (newStatus === 'Out for Delivery') {
      const target = orders.find(o => o.id === orderId);
      if (target && !target.driverId) {
        setActionError('Please assign a delivery driver before dispatching.');
        return;
      }
    }
    setUpdatingOrderId(orderId);
    try {
      await update(ref(db, `orders/${orderId}`), {
        status: newStatus,
        updatedAt: new Date().toISOString()
      });
    } catch (err) {
      setActionError(err.message || 'Failed to update order status.');
    } finally {
      setUpdatingOrderId(null);
    }
  };

  const handleAssignDriver = async (orderId, driverId) => {
    if (updatingOrderId === orderId) return;
    setActionError('');
    if (!driverId) return;
    const selectedDriver = drivers.find(d => d.id === driverId);
    if (!selectedDriver) {
      setActionError('Selected driver does not exist.');
      return;
    }
    setUpdatingOrderId(orderId);
    try {
      await update(ref(db, `orders/${orderId}`), {
        driverId: driverId,
        driverName: selectedDriver.name,
        status: 'Confirmed',
        updatedAt: new Date().toISOString()
      });
    } catch (err) {
      setActionError(err.message || 'Failed to assign driver.');
    } finally {
      setUpdatingOrderId(null);
    }
  };

  const filteredOrders = orders.filter(ord => {
    if (filter === 'ALL') return true;
    return (ord.status || 'Pending').toUpperCase() === filter;
  });

  return (
    <div className="space-y-6">
      {actionError && (
        <div className="p-3 rounded-xl bg-rose-500/15 border border-rose-500/30 text-xs text-rose-300">
          {actionError}
        </div>
      )}
      {/* Header & Filter Pills */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
        <div>
          <h1 className="text-2xl font-bold text-white tracking-tight">Customer Orders & Dispatch</h1>
          <p className="text-sm text-slate-400">Pagtanggap ng orders, pag-assign ng delivery driver, at tracking.</p>
        </div>

        {/* Filter Buttons */}
        <div className="flex flex-wrap gap-1.5 bg-slate-800 p-1.5 rounded-xl border border-slate-700">
          {['ALL', 'PENDING', 'CONFIRMED', 'OUT FOR DELIVERY', 'DELIVERED'].map(f => (
            <button
              key={f}
              onClick={() => setFilter(f)}
              className={`px-3 py-1 rounded-lg text-xs font-semibold transition-all ${
                filter === f
                  ? 'bg-amber-600 text-white shadow-sm'
                  : 'text-slate-400 hover:text-white'
              }`}
            >
              {f === 'ALL' ? 'All Orders' : f}
            </button>
          ))}
        </div>
      </div>

      {/* Orders List */}
      <div className="bg-slate-800/80 border border-slate-700/80 rounded-2xl shadow-xl overflow-hidden">
        {filteredOrders.length === 0 ? (
          <div className="py-16 text-center text-slate-400 text-sm">
            Walang orders sa filter na ito.
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs min-w-[800px]">
              <thead className="bg-slate-900/60 border-b border-slate-700 text-slate-400 font-semibold">
                <tr>
                  <th className="p-4">Order ID & Date</th>
                  <th className="p-4">Customer Details</th>
                  <th className="p-4">Delivery Pin</th>
                  <th className="p-4">Sacks & Total</th>
                  <th className="p-4">Assigned Driver</th>
                  <th className="p-4">Status</th>
                  <th className="p-4 text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-700/50">
                {filteredOrders.map(order => (
                  <tr key={order.id} className="hover:bg-slate-750 transition-colors">
                    
                    {/* ID & Date */}
                    <td className="p-4">
                      <span className="font-mono font-bold text-amber-400 text-sm">{order.id}</span>
                      <p className="text-[11px] text-slate-400 mt-0.5 font-mono">
                        {order.createdAt ? new Date(order.createdAt).toLocaleDateString() : 'Today'}
                      </p>
                    </td>

                    {/* Customer */}
                    <td className="p-4">
                      <p className="font-bold text-white text-sm">{order.customerName || 'Anonymous Customer'}</p>
                      <p className="text-[11px] text-slate-400 flex items-center gap-1 mt-0.5">
                        <Phone className="w-3 h-3 text-slate-500" />
                        {order.customerPhone || 'No Phone'}
                      </p>
                    </td>

                    {/* Address & GPS Pin */}
                    <td className="p-4 max-w-[220px]">
                      <p className="text-slate-300 font-medium truncate">{order.deliveryAddress || 'Address'}</p>
                      {order.deliveryLat && (
                        <p className="text-[10px] text-blue-400 flex items-center gap-1 mt-0.5 font-mono">
                          <MapPin className="w-3 h-3" />
                          {Number(order.deliveryLat).toFixed(4)}, {Number(order.deliveryLng).toFixed(4)}
                        </p>
                      )}
                    </td>

                    {/* Sacks & Amount */}
                    <td className="p-4">
                      <p className="font-bold text-white text-sm">{order.sacksOrdered || 1} Sacks</p>
                      <p className="text-emerald-400 font-mono font-bold text-xs mt-0.5">
                        ₱ {(order.totalAmount || 0).toLocaleString()} (COD)
                      </p>
                    </td>

                    {/* Driver Selector */}
                    <td className="p-4">
                      <select
                        disabled={updatingOrderId === order.id || order.status === 'Delivered' || order.status === 'Cancelled'}
                        value={order.driverId || ''}
                        onChange={e => handleAssignDriver(order.id, e.target.value)}
                        className="bg-slate-900 border border-slate-700 rounded-lg px-2.5 py-1.5 text-xs text-white focus:outline-amber-500 disabled:opacity-50"
                      >
                        <option value="">-- Assign Driver --</option>
                        {drivers.map(d => (
                          <option key={d.id} value={d.id}>
                            {d.name} ({d.vehicle || 'Motorcycle'})
                          </option>
                        ))}
                      </select>
                    </td>

                    {/* Status Badge */}
                    <td className="p-4">
                      <span className={`px-2.5 py-1 rounded-full text-[10px] font-bold ${
                        order.status === 'Delivered'
                          ? 'bg-emerald-500/15 text-emerald-400 border border-emerald-500/30'
                          : order.status === 'Out for Delivery'
                          ? 'bg-purple-500/15 text-purple-400 border border-purple-500/30'
                          : order.status === 'Confirmed'
                          ? 'bg-blue-500/15 text-blue-400 border border-blue-500/30'
                          : order.status === 'Cancelled'
                          ? 'bg-rose-500/15 text-rose-400 border border-rose-500/30'
                          : 'bg-amber-500/15 text-amber-400 border border-amber-500/30'
                      }`}>
                        {order.status || 'Pending'}
                      </span>
                    </td>

                    {/* Action Dropdown / Buttons */}
                    <td className="p-4 text-right space-x-1.5">
                      {order.status !== 'Out for Delivery' && order.status !== 'Delivered' && order.status !== 'Cancelled' && (
                        <button
                          disabled={updatingOrderId === order.id}
                          onClick={() => handleUpdateStatus(order.id, 'Out for Delivery')}
                          className="px-2.5 py-1 bg-purple-600 hover:bg-purple-700 disabled:opacity-50 text-white rounded-lg text-xs font-semibold shadow-sm"
                        >
                          Dispatch
                        </button>
                      )}
                      {order.status === 'Out for Delivery' && (
                        <button
                          disabled={updatingOrderId === order.id}
                          onClick={() => handleUpdateStatus(order.id, 'Delivered')}
                          className="px-2.5 py-1 bg-emerald-600 hover:bg-emerald-700 disabled:opacity-50 text-white rounded-lg text-xs font-semibold shadow-sm"
                        >
                          Complete
                        </button>
                      )}
                      {order.status !== 'Cancelled' && order.status !== 'Delivered' && (
                        <button
                          disabled={updatingOrderId === order.id}
                          onClick={() => handleUpdateStatus(order.id, 'Cancelled')}
                          className="px-2.5 py-1 bg-slate-700 hover:bg-rose-600 disabled:opacity-50 text-slate-300 hover:text-white rounded-lg text-xs font-medium"
                        >
                          Cancel
                        </button>
                      )}
                    </td>

                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  );
}
