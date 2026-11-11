import React, { useEffect, useState } from 'react';
import { ref, onValue, update, push } from 'firebase/database';
import { db } from '../firebase';
import { sanitizeText, validatePositiveInt, validatePositivePrice } from '../utils/validators';
import { Package, PlusCircle, Edit3, History, ArrowDownRight, ArrowUpRight, AlertCircle } from 'lucide-react';

export default function Inventory() {
  const [inventory, setInventory] = useState({
    itemName: 'Standard Hardwood Charcoal Sack (Uling)',
    currentStock: 120,
    pricePerUnit: 250,
    lowStockLimit: 20
  });
  const [history, setHistory] = useState([]);
  const [showRestockModal, setShowRestockModal] = useState(false);
  const [showPriceModal, setShowPriceModal] = useState(false);
  const [restockQty, setRestockQty] = useState(50);
  const [restockReason, setRestockReason] = useState('New supplier delivery');
  const [newPrice, setNewPrice] = useState(250);
  const [modalError, setModalError] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);

  useEffect(() => {
    const invRef = ref(db, 'inventory');
    const unsub = onValue(invRef, (snap) => {
      if (snap.exists()) {
        setInventory(snap.val());
        setNewPrice(snap.val().pricePerUnit || 250);
      }
    });

    const histRef = ref(db, 'inventory_history');
    const unsubHist = onValue(histRef, (snap) => {
      if (snap.exists()) {
        const val = snap.val();
        const list = Object.keys(val).map(k => ({ id: k, ...val[k] }));
        list.sort((a, b) => new Date(b.timestamp || 0) - new Date(a.timestamp || 0));
        setHistory(list);
      } else {
        setHistory([]);
      }
    });

    return () => {
      unsub();
      unsubHist();
    };
  }, []);

  const handleRestock = async (e) => {
    e.preventDefault();
    if (isSubmitting) return;
    setModalError('');

    const qtyErr = validatePositiveInt(restockQty, 1, 10000, 'Restock quantity');
    if (qtyErr) return setModalError(qtyErr);

    const cleanReason = sanitizeText(restockReason);
    if (cleanReason.length > 200) {
      return setModalError('Supplier note must be at most 200 characters.');
    }

    const qty = Number(restockQty);
    setIsSubmitting(true);
    try {
      const newStock = (inventory.currentStock || 0) + qty;
      await update(ref(db, 'inventory'), {
        currentStock: newStock,
        lastUpdated: new Date().toISOString()
      });

      // Log history
      await push(ref(db, 'inventory_history'), {
        type: 'RESTOCK',
        quantity: qty,
        reason: cleanReason || 'Restocked',
        newBalance: newStock,
        timestamp: new Date().toISOString()
      });

      setShowRestockModal(false);
      setRestockQty(50);
      setModalError('');
    } catch (err) {
      setModalError(err.message || 'Failed to restock inventory.');
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleUpdatePrice = async (e) => {
    e.preventDefault();
    if (isSubmitting) return;
    setModalError('');

    const priceErr = validatePositivePrice(newPrice, 1, 50000, 'Price per sack');
    if (priceErr) return setModalError(priceErr);

    const price = Number(newPrice);
    setIsSubmitting(true);
    try {
      await update(ref(db, 'inventory'), {
        pricePerUnit: price,
        lastUpdated: new Date().toISOString()
      });

      setShowPriceModal(false);
      setModalError('');
    } catch (err) {
      setModalError(err.message || 'Failed to update price.');
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="space-y-6">
      {/* Title & Actions */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
        <div>
          <h1 className="text-2xl font-bold text-white tracking-tight">Charcoal (Uling) Inventory</h1>
          <p className="text-sm text-slate-400">Pamahalaan ang bilang ng sako ng uling at presyo.</p>
        </div>
        <div className="flex gap-2">
          <button
            onClick={() => setShowRestockModal(true)}
            className="px-4 py-2.5 bg-amber-600 hover:bg-amber-700 text-white rounded-xl text-xs font-bold shadow-md transition-all flex items-center gap-2"
          >
            <PlusCircle className="w-4 h-4" />
            + Restock Sacks
          </button>
          <button
            onClick={() => setShowPriceModal(true)}
            className="px-4 py-2.5 bg-slate-800 hover:bg-slate-700 border border-slate-700 text-white rounded-xl text-xs font-semibold transition-all flex items-center gap-2"
          >
            <Edit3 className="w-4 h-4 text-amber-400" />
            Edit Price per Sack
          </button>
        </div>
      </div>

      {/* Main Product Card */}
      <div className="bg-slate-800/80 border border-slate-700/80 rounded-2xl p-6 shadow-xl">
        <div className="flex flex-col md:flex-row md:items-center justify-between gap-6">
          <div className="flex items-center gap-5">
            <div className="w-20 h-20 rounded-2xl bg-amber-500/10 border border-amber-500/30 flex items-center justify-center text-4xl shadow-inner">
              🪵
            </div>
            <div>
              <div className="flex items-center gap-2">
                <h3 className="text-lg font-bold text-white">{inventory.itemName || 'Standard Charcoal Sack'}</h3>
                <span className="px-2.5 py-0.5 rounded-full text-[10px] font-bold bg-emerald-500/15 text-emerald-400 border border-emerald-500/30">
                  ACTIVE PRODUCT
                </span>
              </div>
              <p className="text-xs text-slate-400 mt-1 max-w-lg">
                Premium grade hardwood and coconut shell uling packed in heavy-duty 25kg sacks for restaurants, lechon hubs, and barbecue vendors.
              </p>
              <div className="flex items-center gap-4 mt-3 text-xs">
                <span className="font-semibold text-amber-400">Packaging: Per Standard Sack (~25kg)</span>
                <span className="text-slate-600">•</span>
                <span className="text-slate-300 font-semibold">
                  Unit Price: <span className="text-emerald-400 font-bold font-mono">₱ {inventory.pricePerUnit || 250}.00</span>
                </span>
              </div>
            </div>
          </div>

          <div className="bg-slate-900/60 border border-slate-700/80 rounded-2xl p-6 text-center min-w-[220px]">
            <p className="text-xs font-semibold text-slate-400 uppercase tracking-wider">Remaining Sacks</p>
            <div className={`text-5xl font-black my-2 font-mono ${
              (inventory.currentStock || 0) <= (inventory.lowStockLimit || 20) ? 'text-rose-400' : 'text-blue-400'
            }`}>
              {inventory.currentStock || 0}
            </div>
            <p className="text-[11px] text-slate-400">
              Low stock limit: <span className="font-bold text-amber-400">{inventory.lowStockLimit || 20} sacks</span>
            </p>
          </div>
        </div>
      </div>

      {/* Stock History Table */}
      <div className="bg-slate-800/80 border border-slate-700/80 rounded-2xl p-5 shadow-lg">
        <div className="flex items-center gap-2 mb-4">
          <History className="w-4 h-4 text-amber-400" />
          <h3 className="font-bold text-base text-white">Stock Movement History</h3>
        </div>

        {history.length === 0 ? (
          <div className="py-12 text-center text-slate-400 text-sm">
            Wala pang stock adjustments. Mag-restock sa itaas para makita ang history logs.
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs">
              <thead>
                <tr className="border-b border-slate-700 text-slate-400 font-semibold">
                  <th className="pb-3">Timestamp</th>
                  <th className="pb-3">Action Type</th>
                  <th className="pb-3">Quantity</th>
                  <th className="pb-3">Notes / Reason</th>
                  <th className="pb-3">Ending Balance</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-700/50">
                {history.map(item => (
                  <tr key={item.id} className="hover:bg-slate-750 transition-colors">
                    <td className="py-3 text-slate-300 font-mono">
                      {new Date(item.timestamp).toLocaleString()}
                    </td>
                    <td className="py-3">
                      <span className={`px-2 py-0.5 rounded-full text-[10px] font-bold ${
                        item.type === 'RESTOCK' 
                          ? 'bg-emerald-500/15 text-emerald-400 border border-emerald-500/30'
                          : 'bg-rose-500/15 text-rose-400 border border-rose-500/30'
                      }`}>
                        {item.type}
                      </span>
                    </td>
                    <td className={`py-3 font-mono font-bold ${
                      item.type === 'RESTOCK' ? 'text-emerald-400' : 'text-rose-400'
                    }`}>
                      {item.type === 'RESTOCK' ? `+${item.quantity}` : `-${item.quantity}`} sacks
                    </td>
                    <td className="py-3 text-slate-300">{item.reason}</td>
                    <td className="py-3 font-mono font-bold text-white">{item.newBalance} sacks</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* Restock Modal */}
      {showRestockModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/70 backdrop-blur-sm p-4">
          <div className="bg-slate-800 border border-slate-700 rounded-2xl p-6 w-full max-w-md shadow-2xl">
            <h3 className="font-bold text-lg text-white mb-1">Restock Charcoal Sacks</h3>
            <p className="text-xs text-slate-400 mb-4">Magdagdag ng bagong dating na uling sa imbentaryo.</p>
            <form onSubmit={handleRestock} className="space-y-4 text-xs">
              {modalError && (
                <div className="p-3 rounded-xl bg-rose-500/15 border border-rose-500/30 flex items-start gap-2 text-rose-300">
                  <AlertCircle className="w-4 h-4 text-rose-400 shrink-0 mt-0.5" />
                  <span>{modalError}</span>
                </div>
              )}
              <div>
                <label className="block text-slate-300 font-semibold mb-1">Bilang ng Sako (+)</label>
                <input
                  type="number"
                  min="1"
                  max="10000"
                  step="1"
                  value={restockQty}
                  onChange={e => setRestockQty(e.target.value)}
                  className="w-full bg-slate-900 border border-slate-700 rounded-xl px-3.5 py-2.5 text-white font-mono text-sm focus:outline-amber-500"
                  required
                />
              </div>
              <div>
                <label className="block text-slate-300 font-semibold mb-1">Paliwanag / Supplier Note</label>
                <input
                  type="text"
                  maxLength={200}
                  value={restockReason}
                  onChange={e => setRestockReason(e.target.value)}
                  className="w-full bg-slate-900 border border-slate-700 rounded-xl px-3.5 py-2.5 text-white text-xs focus:outline-amber-500"
                  placeholder="Hal. Delivery from Quezon supplier"
                />
              </div>
              <div className="flex justify-end gap-2 pt-2">
                <button
                  type="button"
                  disabled={isSubmitting}
                  onClick={() => {
                    setModalError('');
                    setShowRestockModal(false);
                  }}
                  className="px-4 py-2 bg-slate-700 hover:bg-slate-600 rounded-xl font-semibold text-slate-300"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={isSubmitting}
                  className="px-5 py-2 bg-amber-600 hover:bg-amber-700 disabled:opacity-60 text-white rounded-xl font-bold shadow-md"
                >
                  {isSubmitting ? 'Saving...' : 'Confirm Restock'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Price Modal */}
      {showPriceModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/70 backdrop-blur-sm p-4">
          <div className="bg-slate-800 border border-slate-700 rounded-2xl p-6 w-full max-w-md shadow-2xl">
            <h3 className="font-bold text-lg text-white mb-1">Edit Price per Sack</h3>
            <p className="text-xs text-slate-400 mb-4">I-update ang presyo bawat sako ng uling sa mobile checkout.</p>
            <form onSubmit={handleUpdatePrice} className="space-y-4 text-xs">
              {modalError && (
                <div className="p-3 rounded-xl bg-rose-500/15 border border-rose-500/30 flex items-start gap-2 text-rose-300">
                  <AlertCircle className="w-4 h-4 text-rose-400 shrink-0 mt-0.5" />
                  <span>{modalError}</span>
                </div>
              )}
              <div>
                <label className="block text-slate-300 font-semibold mb-1">Presyo bawat Sako (₱)</label>
                <input
                  type="number"
                  step="0.01"
                  min="1"
                  max="50000"
                  value={newPrice}
                  onChange={e => setNewPrice(e.target.value)}
                  className="w-full bg-slate-900 border border-slate-700 rounded-xl px-3.5 py-2.5 text-white font-mono text-sm focus:outline-amber-500"
                  required
                />
              </div>
              <div className="flex justify-end gap-2 pt-2">
                <button
                  type="button"
                  disabled={isSubmitting}
                  onClick={() => {
                    setModalError('');
                    setShowPriceModal(false);
                  }}
                  className="px-4 py-2 bg-slate-700 hover:bg-slate-600 rounded-xl font-semibold text-slate-300"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={isSubmitting}
                  className="px-5 py-2 bg-emerald-600 hover:bg-emerald-700 disabled:opacity-60 text-white rounded-xl font-bold shadow-md"
                >
                  {isSubmitting ? 'Saving...' : 'Save New Price'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
