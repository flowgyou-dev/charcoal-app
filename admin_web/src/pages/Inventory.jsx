import React, { useEffect, useState } from 'react';
import { ref, onValue, update, push, runTransaction } from 'firebase/database';
import { db } from '../firebase';
import { sanitizeText, validatePositiveInt, validatePositivePrice } from '../utils/validators';
import { PlusCircle, Edit3, History, AlertCircle } from 'lucide-react';

export default function Inventory() {
  const [inventory, setInventory] = useState(null);
  const [loading, setLoading] = useState(true);
  const [loadError, setLoadError] = useState('');
  const [history, setHistory] = useState([]);

  const [showRestockModal, setShowRestockModal] = useState(false);
  const [showEditProductModal, setShowEditProductModal] = useState(false);

  const [restockQty, setRestockQty] = useState(50);
  const [restockReason, setRestockReason] = useState('New supplier delivery');

  const [editItemName, setEditItemName] = useState('');
  const [editUnit, setEditUnit] = useState('sack');
  const [editPrice, setEditPrice] = useState(250);
  const [editLowStockLimit, setEditLowStockLimit] = useState(20);

  const [modalError, setModalError] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);

  useEffect(() => {
    const invRef = ref(db, 'inventory');
    const unsub = onValue(
      invRef,
      (snap) => {
        if (snap.exists()) {
          const val = snap.val();
          setInventory(val);
          setEditItemName(val.itemName || 'Standard Charcoal Sack (Uling)');
          setEditUnit(val.unit || 'sack');
          setEditPrice(val.pricePerUnit ?? 250);
          setEditLowStockLimit(val.lowStockLimit ?? 20);
        } else {
          setInventory({
            itemName: 'Standard Charcoal Sack (Uling)',
            unit: 'sack',
            currentStock: 0,
            pricePerUnit: 250,
            lowStockLimit: 20,
          });
        }
        setLoading(false);
      },
      (err) => {
        setLoadError(err.message || 'Unable to load inventory.');
        setLoading(false);
      }
    );

    const histRef = ref(db, 'inventory_history');
    const unsubHist = onValue(
      histRef,
      (snap) => {
        if (snap.exists()) {
          const val = snap.val();
          const list = Object.keys(val).map((k) => ({ id: k, ...val[k] }));
          list.sort((a, b) => new Date(b.timestamp || 0) - new Date(a.timestamp || 0));
          setHistory(list);
        } else {
          setHistory([]);
        }
      },
      (err) => {
        setLoadError(err.message || 'Unable to load inventory history.');
      }
    );

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
      const invRef = ref(db, 'inventory');
      const txResult = await runTransaction(invRef, (current) => {
        const base = current || {
          itemName: 'Standard Charcoal Sack (Uling)',
          unit: 'sack',
          pricePerUnit: 250,
          lowStockLimit: 20,
          currentStock: 0,
        };
        return {
          ...base,
          currentStock: Number(base.currentStock || 0) + qty,
          lastUpdated: new Date().toISOString(),
        };
      });

      if (!txResult.committed) {
        throw new Error('Stock transaction failed. Please try again.');
      }

      const newBalance = txResult.snapshot.val()?.currentStock ?? qty;
      await push(ref(db, 'inventory_history'), {
        type: 'RESTOCK',
        quantity: qty,
        reason: cleanReason || 'Restocked',
        newBalance,
        timestamp: new Date().toISOString(),
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

  const handleUpdateProduct = async (e) => {
    e.preventDefault();
    if (isSubmitting) return;
    setModalError('');

    const cleanName = sanitizeText(editItemName);
    if (cleanName.length < 2 || cleanName.length > 80) {
      return setModalError('Product name must be 2–80 characters.');
    }

    const cleanUnit = sanitizeText(editUnit).toLowerCase();
    if (cleanUnit.length < 1 || cleanUnit.length > 20) {
      return setModalError('Unit label must be 1–20 characters (e.g. sack, bag).');
    }

    const priceErr = validatePositivePrice(editPrice, 1, 50000, 'Price per unit');
    if (priceErr) return setModalError(priceErr);

    const limitErr = validatePositiveInt(editLowStockLimit, 1, 5000, 'Low stock threshold');
    if (limitErr) return setModalError(limitErr);

    setIsSubmitting(true);
    try {
      await update(ref(db, 'inventory'), {
        itemName: cleanName,
        unit: cleanUnit,
        pricePerUnit: Number(editPrice),
        lowStockLimit: Number(editLowStockLimit),
        lastUpdated: new Date().toISOString(),
      });

      setShowEditProductModal(false);
      setModalError('');
    } catch (err) {
      setModalError(err.message || 'Failed to update product settings.');
    } finally {
      setIsSubmitting(false);
    }
  };

  if (loading) {
    return <div className="py-16 text-center text-sm text-charcoal-muted">Loading charcoal inventory...</div>;
  }

  const currentStock = Number(inventory?.currentStock ?? 0);
  const lowLimit = Number(inventory?.lowStockLimit ?? 20);
  const unitLabel = inventory?.unit || 'sack';
  const pricePerUnit = Number(inventory?.pricePerUnit ?? 250);

  return (
    <div className="space-y-6">
      {loadError && (
        <div className="p-3 rounded-xl bg-rose-50 border border-rose-200 text-xs text-rose-700">
          {loadError}
        </div>
      )}

      {/* Title & Actions */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
        <div>
          <h1 className="text-2xl font-bold text-charcoal-ink tracking-tight">Charcoal (Uling) Inventory</h1>
          <p className="text-sm text-charcoal-muted">Pamahalaan ang stock balance, presyo, pangalan ng produkto, at low-stock alert limit.</p>
        </div>
        <div className="flex gap-2">
          <button
            onClick={() => {
              setModalError('');
              setShowRestockModal(true);
            }}
            className="px-4 py-2.5 bg-charcoal-header hover:bg-charcoal-dark text-white rounded-xl text-xs font-bold shadow-sm transition-all flex items-center gap-2 uppercase tracking-wide"
          >
            <PlusCircle className="w-4 h-4" />
            Restock
          </button>
          <button
            onClick={() => {
              setModalError('');
              setShowEditProductModal(true);
            }}
            className="px-4 py-2.5 bg-white hover:bg-charcoal-canvas border border-charcoal-border text-charcoal-ink rounded-xl text-xs font-semibold transition-all flex items-center gap-2 shadow-sm"
          >
            <Edit3 className="w-4 h-4 text-charcoal-eco" />
            Edit Product &amp; Price
          </button>
        </div>
      </div>

      {/* Main Product Card */}
      <div className="bg-white border border-charcoal-border rounded-2xl p-6 shadow-sm">
        <div className="flex flex-col md:flex-row md:items-center justify-between gap-6">
          <div className="flex items-center gap-5">
            <div className="w-20 h-20 rounded-2xl bg-charcoal-canvas border border-charcoal-border flex items-center justify-center text-4xl">
              🪵
            </div>
            <div>
              <div className="flex items-center gap-2">
                <h3 className="text-lg font-bold text-charcoal-ink">{inventory?.itemName}</h3>
                <span className="px-2.5 py-0.5 rounded-full text-[11px] font-bold bg-[#E8F3EC] text-charcoal-eco border border-[#B7DFC7]">
                  ACTIVE PRODUCT
                </span>
              </div>
              <p className="text-xs text-charcoal-muted mt-1 max-w-lg">
                Premium charcoal packed per {unitLabel}. Automatically deducted upon order placement and restored on cancellation.
              </p>
              <div className="flex flex-wrap items-center gap-4 mt-3 text-xs">
                <span className="font-semibold text-charcoal-header">Unit: {unitLabel}</span>
                <span className="text-charcoal-border">•</span>
                <span className="text-charcoal-ink font-semibold">
                  Unit Price:{' '}
                  <span className="text-charcoal-eco font-bold font-mono">
                    ₱ {pricePerUnit.toLocaleString('en-US', { minimumFractionDigits: 2 })}
                  </span>
                </span>
              </div>
            </div>
          </div>

          <div className="bg-charcoal-canvas border border-charcoal-border rounded-2xl p-6 text-center min-w-[220px]">
            <p className="text-xs font-semibold text-charcoal-muted uppercase tracking-wider">Remaining Stock</p>
            <div
              className={`text-5xl font-black my-2 font-mono ${
                currentStock <= lowLimit ? 'text-rose-600' : 'text-charcoal-header'
              }`}
            >
              {currentStock}
            </div>
            <p className="text-xs text-charcoal-muted">
              Low stock limit: <span className="font-bold text-amber-700">{lowLimit} {unitLabel}s</span>
            </p>
          </div>
        </div>
      </div>

      {/* Stock History Table */}
      <div className="bg-white border border-charcoal-border rounded-2xl shadow-sm overflow-hidden">
        <div className="bg-charcoal-header px-5 py-3.5 flex items-center gap-2 text-white">
          <History className="w-4 h-4 text-[#B7DFC7]" />
          <h3 className="font-bold text-xs uppercase tracking-wider">Stock Movement History</h3>
        </div>

        {history.length === 0 ? (
          <div className="py-12 text-center text-charcoal-muted text-sm">
            Wala pang stock adjustments.
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs">
              <thead>
                <tr className="bg-[#F8FAFA] border-b border-charcoal-border text-charcoal-muted font-semibold">
                  <th className="py-3 px-5">Timestamp</th>
                  <th className="py-3 px-5">Action Type</th>
                  <th className="py-3 px-5">Quantity</th>
                  <th className="py-3 px-5">Notes / Reason</th>
                  <th className="py-3 px-5">Ending Balance</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-charcoal-border">
                {history.map((item) => {
                  const isAddition = item.type === 'RESTOCK' || item.type === 'CANCELLATION_RESTORE';
                  return (
                    <tr key={item.id} className="hover:bg-[#F8FAFA] transition-colors">
                      <td className="py-3 px-5 text-charcoal-muted font-mono">
                        {item.timestamp ? new Date(item.timestamp).toLocaleString() : '—'}
                      </td>
                      <td className="py-3 px-5">
                        <span
                          className={`px-2 py-0.5 rounded-full text-[11px] font-bold ${
                            item.type === 'RESTOCK'
                              ? 'bg-emerald-100 text-emerald-800 border border-emerald-200'
                              : item.type === 'CANCELLATION_RESTORE'
                              ? 'bg-blue-100 text-blue-800 border border-blue-200'
                              : 'bg-rose-100 text-rose-800 border border-rose-200'
                          }`}
                        >
                          {item.type}
                        </span>
                      </td>
                      <td
                        className={`py-3 px-5 font-mono font-bold ${
                          isAddition ? 'text-charcoal-eco' : 'text-rose-600'
                        }`}
                      >
                        {isAddition ? `+${item.quantity}` : `-${item.quantity}`} {unitLabel}s
                      </td>
                      <td className="py-3 px-5 text-charcoal-ink">{item.reason}</td>
                      <td className="py-3 px-5 font-mono font-bold text-charcoal-header">
                        {item.newBalance} {unitLabel}s
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* Restock Modal */}
      {showRestockModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm p-4">
          <div className="bg-white border border-charcoal-border rounded-2xl p-6 w-full max-w-md shadow-2xl text-charcoal-ink">
            <h3 className="font-bold text-lg text-charcoal-ink mb-1">Restock Charcoal</h3>
            <p className="text-xs text-charcoal-muted mb-4">Atomic transaction restock ng imbentaryo.</p>
            <form onSubmit={handleRestock} className="space-y-4 text-xs">
              {modalError && (
                <div className="p-3 rounded-xl bg-rose-50 border border-rose-200 flex items-start gap-2 text-rose-700">
                  <AlertCircle className="w-4 h-4 text-rose-600 shrink-0 mt-0.5" />
                  <span>{modalError}</span>
                </div>
              )}
              <div>
                <label className="block text-charcoal-ink font-semibold mb-1">Quantity (+)</label>
                <input
                  type="number"
                  min="1"
                  max="10000"
                  step="1"
                  value={restockQty}
                  onChange={(e) => setRestockQty(e.target.value)}
                  className="w-full bg-charcoal-canvas border border-charcoal-border rounded-xl px-3.5 py-2.5 text-charcoal-ink font-mono text-sm focus:outline-none focus:border-charcoal-header"
                  required
                />
              </div>
              <div>
                <label className="block text-charcoal-ink font-semibold mb-1">Supplier Note</label>
                <input
                  type="text"
                  maxLength={200}
                  value={restockReason}
                  onChange={(e) => setRestockReason(e.target.value)}
                  className="w-full bg-charcoal-canvas border border-charcoal-border rounded-xl px-3.5 py-2.5 text-charcoal-ink text-xs focus:outline-none focus:border-charcoal-header"
                />
              </div>
              <div className="flex justify-end gap-2 pt-2">
                <button
                  type="button"
                  disabled={isSubmitting}
                  onClick={() => setShowRestockModal(false)}
                  className="px-4 py-2 bg-charcoal-canvas border border-charcoal-border rounded-xl font-semibold text-charcoal-ink"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={isSubmitting}
                  className="px-5 py-2 bg-charcoal-header hover:bg-charcoal-dark disabled:opacity-60 text-white rounded-xl font-bold shadow-sm"
                >
                  {isSubmitting ? 'Saving...' : 'Confirm Restock'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Edit Product & Price Modal */}
      {showEditProductModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm p-4">
          <div className="bg-white border border-charcoal-border rounded-2xl p-6 w-full max-w-md shadow-2xl text-charcoal-ink">
            <h3 className="font-bold text-lg text-charcoal-ink mb-1">Edit Product &amp; Pricing</h3>
            <p className="text-xs text-charcoal-muted mb-4">I-update ang pangalan ng uling, unit, presyo, at low-stock alert.</p>
            <form onSubmit={handleUpdateProduct} className="space-y-4 text-xs">
              {modalError && (
                <div className="p-3 rounded-xl bg-rose-50 border border-rose-200 flex items-start gap-2 text-rose-700">
                  <AlertCircle className="w-4 h-4 text-rose-600 shrink-0 mt-0.5" />
                  <span>{modalError}</span>
                </div>
              )}
              <div>
                <label className="block text-charcoal-ink font-semibold mb-1">Product Name</label>
                <input
                  type="text"
                  maxLength={80}
                  required
                  value={editItemName}
                  onChange={(e) => setEditItemName(e.target.value)}
                  className="w-full bg-charcoal-canvas border border-charcoal-border rounded-xl px-3.5 py-2.5 text-charcoal-ink focus:outline-none focus:border-charcoal-header"
                />
              </div>
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-charcoal-ink font-semibold mb-1">Unit (e.g. sack)</label>
                  <input
                    type="text"
                    maxLength={20}
                    required
                    value={editUnit}
                    onChange={(e) => setEditUnit(e.target.value)}
                    className="w-full bg-charcoal-canvas border border-charcoal-border rounded-xl px-3.5 py-2.5 text-charcoal-ink focus:outline-none focus:border-charcoal-header"
                  />
                </div>
                <div>
                  <label className="block text-charcoal-ink font-semibold mb-1">Low Stock Limit</label>
                  <input
                    type="number"
                    min="1"
                    max="5000"
                    step="1"
                    required
                    value={editLowStockLimit}
                    onChange={(e) => setEditLowStockLimit(e.target.value)}
                    className="w-full bg-charcoal-canvas border border-charcoal-border rounded-xl px-3.5 py-2.5 font-mono text-charcoal-ink focus:outline-none focus:border-charcoal-header"
                  />
                </div>
              </div>
              <div>
                <label className="block text-charcoal-ink font-semibold mb-1">Price per Unit (₱)</label>
                <input
                  type="number"
                  step="0.01"
                  min="1"
                  max="50000"
                  required
                  value={editPrice}
                  onChange={(e) => setEditPrice(e.target.value)}
                  className="w-full bg-charcoal-canvas border border-charcoal-border rounded-xl px-3.5 py-2.5 font-mono text-sm text-charcoal-ink focus:outline-none focus:border-charcoal-header"
                />
              </div>
              <div className="flex justify-end gap-2 pt-2">
                <button
                  type="button"
                  disabled={isSubmitting}
                  onClick={() => setShowEditProductModal(false)}
                  className="px-4 py-2 bg-charcoal-canvas border border-charcoal-border rounded-xl font-semibold text-charcoal-ink"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={isSubmitting}
                  className="px-5 py-2 bg-charcoal-eco hover:bg-[#2F6346] disabled:opacity-60 text-white rounded-xl font-bold shadow-sm"
                >
                  {isSubmitting ? 'Saving...' : 'Save Changes'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
