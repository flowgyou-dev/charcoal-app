import React, { useEffect, useState } from 'react';
import { ref, onValue, set } from 'firebase/database';
import { db } from '../firebase';
import { Package, TrendingUp, Truck, CheckCircle2, AlertTriangle, ArrowUpRight } from 'lucide-react';

export default function Dashboard({ setActiveTab }) {
  const [stock, setStock] = useState({ currentStock: 100, pricePerUnit: 250, lowStockLimit: 20 });
  const [orders, setOrders] = useState([]);
  const [drivers, setDrivers] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // 1. Listen to inventory
    const invRef = ref(db, 'inventory');
    const unsubInv = onValue(invRef, (snap) => {
      if (snap.exists()) {
        setStock(snap.val());
      } else {
        // Auto-seed default charcoal inventory if empty
        const initialInv = {
          itemName: 'Standard Charcoal Sack (Uling)',
          pricePerUnit: 250,
          currentStock: 120,
          lowStockLimit: 20,
          unit: 'sack',
          lastUpdated: new Date().toISOString()
        };
        set(invRef, initialInv);
        setStock(initialInv);
      }
    });

    // 2. Listen to orders
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
      setLoading(false);
    });

    // 3. Listen to drivers
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
      unsubInv();
      unsubOrders();
      unsubDrivers();
    };
  }, []);

  // Compute metrics
  const totalSales = orders.reduce((sum, ord) => sum + (Number(ord.totalAmount) || 0), 0);
  const totalSacksSold = orders.reduce((sum, ord) => sum + (Number(ord.sacksOrdered) || 0), 0);
  const activeDeliveries = orders.filter(o => o.status === 'Out for Delivery' || o.status === 'Confirmed').length;
  const isLowStock = (stock.currentStock || 0) <= (stock.lowStockLimit || 20);

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
        <div>
          <h1 className="text-2xl font-bold text-charcoal-ink tracking-tight">Executive Dashboard</h1>
          <p className="text-sm text-charcoal-muted">Real-time status ng Charcoal Sales, Inventory, at Deliveries.</p>
        </div>
        <div className="flex items-center gap-2">
          <span className="flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-semibold bg-[#E8F3EC] text-charcoal-eco border border-[#B7DFC7]">
            <span className="w-2 h-2 rounded-full bg-charcoal-eco animate-ping"></span>
            Realtime DB Connected
          </span>
        </div>
      </div>

      {/* Low Stock Warning Banner */}
      {isLowStock && (
        <div className="bg-amber-50 border border-amber-300 rounded-xl p-4 flex items-center justify-between text-amber-900 shadow-sm">
          <div className="flex items-center gap-3">
            <AlertTriangle className="w-5 h-5 text-amber-600" />
            <div>
              <p className="font-bold text-sm">Low Stock Alert!</p>
              <p className="text-xs text-amber-800">
                May {stock.currentStock} sako na lang ng uling na natitira. Mag-restock na bago maubusan.
              </p>
            </div>
          </div>
          <button 
            onClick={() => setActiveTab('inventory')}
            className="px-3.5 py-1.5 bg-charcoal-header hover:bg-charcoal-dark text-white rounded-lg text-xs font-semibold shadow-sm transition-all"
          >
            Go to Restock →
          </button>
        </div>
      )}

      {/* 4 Metric Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        
        {/* Card 1: Total Revenue */}
        <div className="bg-white border border-charcoal-border rounded-2xl p-5 shadow-sm">
          <div className="flex justify-between items-start">
            <div>
              <p className="text-xs font-medium text-charcoal-muted uppercase tracking-wider">Total Sales</p>
              <h3 className="text-2xl font-black text-charcoal-eco mt-1 font-mono">
                ₱ {totalSales.toLocaleString('en-US', { minimumFractionDigits: 2 })}
              </h3>
            </div>
            <div className="p-3 bg-[#E8F3EC] rounded-xl text-charcoal-eco">
              <TrendingUp className="w-5 h-5" />
            </div>
          </div>
          <div className="mt-3 flex items-center gap-1.5 text-xs text-charcoal-eco font-semibold">
            <ArrowUpRight className="w-3.5 h-3.5" />
            <span>{orders.length} orders recorded</span>
          </div>
        </div>

        {/* Card 2: Sacks Sold */}
        <div className="bg-white border border-charcoal-border rounded-2xl p-5 shadow-sm">
          <div className="flex justify-between items-start">
            <div>
              <p className="text-xs font-medium text-charcoal-muted uppercase tracking-wider">Sacks Sold</p>
              <h3 className="text-2xl font-black text-charcoal-header mt-1">
                {totalSacksSold} <span className="text-sm font-semibold text-charcoal-muted">sacks</span>
              </h3>
            </div>
            <div className="p-3 bg-charcoal-canvas border border-charcoal-border rounded-xl text-charcoal-header text-xl">
              🪵
            </div>
          </div>
          <p className="mt-3 text-xs text-charcoal-muted">
            Standard 25kg sacks
          </p>
        </div>

        {/* Card 3: Current Stock */}
        <div className="bg-white border border-charcoal-border rounded-2xl p-5 shadow-sm">
          <div className="flex justify-between items-start">
            <div>
              <p className="text-xs font-medium text-charcoal-muted uppercase tracking-wider">Available Stock</p>
              <h3 className={`text-2xl font-black mt-1 ${isLowStock ? 'text-rose-600' : 'text-charcoal-header'}`}>
                {stock.currentStock || 0} <span className="text-sm font-semibold text-charcoal-muted">left</span>
              </h3>
            </div>
            <div className="p-3 bg-charcoal-canvas border border-charcoal-border rounded-xl text-charcoal-header">
              <Package className="w-5 h-5" />
            </div>
          </div>
          <p className="mt-3 text-xs text-charcoal-muted">
            Price: ₱{stock.pricePerUnit || 250}/sack
          </p>
        </div>

        {/* Card 4: Active Deliveries */}
        <div className="bg-white border border-charcoal-border rounded-2xl p-5 shadow-sm">
          <div className="flex justify-between items-start">
            <div>
              <p className="text-xs font-medium text-charcoal-muted uppercase tracking-wider">Active Deliveries</p>
              <h3 className="text-2xl font-black text-teal-700 mt-1">
                {activeDeliveries} <span className="text-sm font-semibold text-charcoal-muted">ongoing</span>
              </h3>
            </div>
            <div className="p-3 bg-teal-50 rounded-xl text-teal-700">
              <Truck className="w-5 h-5" />
            </div>
          </div>
          <p className="mt-3 text-xs text-charcoal-muted">
            {drivers.length} registered drivers
          </p>
        </div>

      </div>

      {/* Recent Orders Preview */}
      <div className="bg-white border border-charcoal-border rounded-2xl shadow-sm overflow-hidden">
        <div className="bg-charcoal-header px-5 py-3.5 flex justify-between items-center">
          <h3 className="font-bold text-xs uppercase tracking-wider text-white">Recent Orders Stream</h3>
          <button 
            onClick={() => setActiveTab('orders')}
            className="text-xs text-[#B7DFC7] hover:text-white font-semibold"
          >
            View All ({orders.length}) →
          </button>
        </div>

        {orders.length === 0 ? (
          <div className="py-12 text-center text-charcoal-muted text-sm">
            Wala pang orders sa database. Maglagay ng order sa Mobile app para makita ito rito live!
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs">
              <thead>
                <tr className="bg-[#F8FAFA] border-b border-charcoal-border text-charcoal-muted font-semibold">
                  <th className="py-3 px-5">Order ID</th>
                  <th className="py-3 px-5">Customer</th>
                  <th className="py-3 px-5">Address</th>
                  <th className="py-3 px-5">Quantity</th>
                  <th className="py-3 px-5">Total Amount</th>
                  <th className="py-3 px-5">Status</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-charcoal-border">
                {orders.slice(0, 5).map(order => (
                  <tr key={order.id} className="hover:bg-[#F8FAFA] transition-colors">
                    <td className="py-3.5 px-5 font-mono font-bold text-charcoal-header">{order.id}</td>
                    <td className="py-3.5 px-5 font-semibold text-charcoal-ink">{order.customerName || 'Customer'}</td>
                    <td className="py-3.5 px-5 text-charcoal-muted max-w-[200px] truncate">{order.deliveryAddress || 'Address'}</td>
                    <td className="py-3.5 px-5 font-medium text-charcoal-ink">{order.sacksOrdered || 1} sacks</td>
                    <td className="py-3.5 px-5 font-mono font-bold text-charcoal-eco">₱ {(order.totalAmount || 0).toLocaleString()}</td>
                    <td className="py-3.5 px-5">
                      <span className={`px-2.5 py-0.5 rounded-full text-[11px] font-bold ${
                        order.status === 'Delivered' 
                          ? 'bg-emerald-100 text-emerald-800 border border-emerald-200'
                          : order.status === 'Out for Delivery'
                          ? 'bg-teal-100 text-teal-800 border border-teal-200'
                          : 'bg-amber-100 text-amber-800 border border-amber-200'
                      }`}>
                        {order.status || 'Pending'}
                      </span>
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
