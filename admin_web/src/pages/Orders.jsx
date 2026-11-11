import React, { useEffect, useState } from 'react';
import { ref, onValue, update, get, push, remove, runTransaction } from 'firebase/database';
import { db } from '../firebase';
import {
  MapPin,
  Phone,
  Search,
  Receipt,
  CheckCircle2,
  XCircle,
  AlertCircle,
  X,
} from 'lucide-react';

export default function Orders() {
  const [orders, setOrders] = useState([]);
  const [drivers, setDrivers] = useState([]);
  const [filter, setFilter] = useState('ALL');
  const [searchQuery, setSearchQuery] = useState('');
  const [dateFilter, setDateFilter] = useState('');
  const [updatingOrderId, setUpdatingOrderId] = useState(null);
  const [actionError, setActionError] = useState('');

  // Online Payment Receipt Inspection Modal
  const [inspectOrder, setInspectOrder] = useState(null);
  const [receiptData, setReceiptData] = useState(null);
  const [receiptLoading, setReceiptLoading] = useState(false);

  // Cancel confirmation modal
  const [cancelTargetOrder, setCancelTargetOrder] = useState(null);
  const [cancelReason, setCancelReason] = useState('Cancelled by Admin');

  const ALLOWED_STATUSES = ['Pending', 'Confirmed', 'Out for Delivery', 'Delivered', 'Cancelled'];

  useEffect(() => {
    const ordersRef = ref(db, 'orders');
    const unsubOrders = onValue(
      ordersRef,
      (snap) => {
        if (snap.exists()) {
          const val = snap.val();
          const list = Object.keys(val).map((key) => ({ id: key, ...val[key] }));
          list.sort((a, b) => new Date(b.createdAt || 0) - new Date(a.createdAt || 0));
          setOrders(list);
        } else {
          setOrders([]);
        }
      },
      (err) => setActionError(err.message || 'Unable to listen to orders.')
    );

    const driversRef = ref(db, 'drivers');
    const unsubDrivers = onValue(
      driversRef,
      (snap) => {
        if (snap.exists()) {
          const val = snap.val();
          setDrivers(Object.keys(val).map((k) => ({ id: k, ...val[k] })));
        } else {
          setDrivers([]);
        }
      },
      (err) => setActionError(err.message || 'Unable to listen to drivers.')
    );

    return () => {
      unsubOrders();
      unsubDrivers();
    };
  }, []);

  const restoreStockAndReleaseRef = async (order, reasonText) => {
    const qty = Number(order.sacksOrdered || 0);
    if (qty > 0) {
      const invRef = ref(db, 'inventory');
      const txRes = await runTransaction(invRef, (current) => {
        if (!current) return current;
        return {
          ...current,
          currentStock: Number(current.currentStock || 0) + qty,
          lastUpdated: new Date().toISOString(),
        };
      });
      const newBal = txRes.snapshot.val()?.currentStock ?? qty;
      await push(ref(db, 'inventory_history'), {
        type: 'CANCELLATION_RESTORE',
        quantity: qty,
        reason: `Restored from cancelled order ${order.id}: ${reasonText}`,
        newBalance: newBal,
        timestamp: new Date().toISOString(),
      });
    }

    if (order.receiptRefNumber) {
      const refKey = String(order.receiptRefNumber).replace(/[^a-zA-Z0-9_-]/g, '');
      if (refKey) {
        await remove(ref(db, `used_receipt_refs/${refKey}`));
      }
    }
  };

  const handleUpdateStatus = async (order, newStatus, extraUpdates = {}) => {
    if (updatingOrderId === order.id) return;
    if (!ALLOWED_STATUSES.includes(newStatus)) return;
    setActionError('');

    if (newStatus === 'Out for Delivery' && !order.driverId) {
      setActionError('Please assign an active delivery driver before dispatching.');
      return;
    }

    setUpdatingOrderId(order.id);
    try {
      const updates = {
        status: newStatus,
        updatedAt: new Date().toISOString(),
        ...extraUpdates,
      };
      if (newStatus === 'Out for Delivery') {
        updates.outForDeliveryAt = new Date().toISOString();
      }
      if (newStatus === 'Delivered') {
        updates.deliveredAt = new Date().toISOString();
        updates.paymentStatus = 'Paid';
      }
      if (newStatus === 'Cancelled' && order.status !== 'Cancelled') {
        updates.cancelledAt = new Date().toISOString();
        await restoreStockAndReleaseRef(order, updates.cancelReason || 'Cancelled by Admin');
      }

      await update(ref(db, `orders/${order.id}`), updates);
    } catch (err) {
      setActionError(err.message || 'Failed to update order.');
    } finally {
      setUpdatingOrderId(null);
    }
  };

  const handleAssignDriver = async (order, driverId) => {
    if (updatingOrderId === order.id || !driverId) return;
    setActionError('');

    const selectedDriver = drivers.find((d) => d.id === driverId);
    if (!selectedDriver || selectedDriver.isActive === false) {
      setActionError('Selected driver is inactive or unavailable.');
      return;
    }

    setUpdatingOrderId(order.id);
    try {
      const nextStatus = order.status === 'Out for Delivery' ? 'Out for Delivery' : 'Confirmed';
      await update(ref(db, `orders/${order.id}`), {
        driverId,
        driverName: selectedDriver.name,
        driverPhone: selectedDriver.phone || '',
        status: nextStatus,
        updatedAt: new Date().toISOString(),
      });
    } catch (err) {
      setActionError(err.message || 'Failed to assign driver.');
    } finally {
      setUpdatingOrderId(null);
    }
  };

  const openReceiptInspector = async (order) => {
    setInspectOrder(order);
    setReceiptData(null);
    setReceiptLoading(true);
    try {
      const snap = await get(ref(db, `order_receipts/${order.id}`));
      setReceiptData(snap.exists() ? snap.val() : null);
    } catch (err) {
      setActionError(err.message || 'Could not load uploaded receipt.');
    } finally {
      setReceiptLoading(false);
    }
  };

  const activeDriverCountMap = orders.reduce((acc, ord) => {
    if (ord.driverId && (ord.status === 'Confirmed' || ord.status === 'Out for Delivery')) {
      acc[ord.driverId] = (acc[ord.driverId] || 0) + 1;
    }
    return acc;
  }, {});

  const availableDrivers = drivers.filter((d) => d.isActive !== false);

  const filteredOrders = orders.filter((ord) => {
    if (filter !== 'ALL' && (ord.status || 'Pending').toUpperCase() !== filter) return false;
    if (dateFilter && ord.createdAt) {
      if (!ord.createdAt.startsWith(dateFilter)) return false;
    } else if (dateFilter && !ord.createdAt) {
      return false;
    }
    if (searchQuery.trim()) {
      const q = searchQuery.trim().toLowerCase();
      const haystack = [
        ord.id,
        ord.customerName,
        ord.customerPhone,
        ord.deliveryAddress,
        ord.receiptRefNumber,
        ord.driverName,
      ]
        .filter(Boolean)
        .join(' ')
        .toLowerCase();
      if (!haystack.includes(q)) return false;
    }
    return true;
  });

  return (
    <div className="space-y-6">
      {actionError && (
        <div className="p-3 rounded-xl bg-rose-50 border border-rose-200 flex items-center justify-between text-xs text-rose-700">
          <span>{actionError}</span>
          <button onClick={() => setActionError('')} className="font-bold px-2">×</button>
        </div>
      )}

      {/* Header & Controls */}
      <div className="flex flex-col gap-3">
        <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-3">
          <div>
            <h1 className="text-2xl font-bold text-charcoal-ink tracking-tight">Customer Orders &amp; Dispatch</h1>
            <p className="text-sm text-charcoal-muted">Verify online QR payment receipts, assign online drivers, at track deliveries.</p>
          </div>

          <div className="flex flex-wrap gap-1.5 bg-white p-1.5 rounded-xl border border-charcoal-border shadow-sm">
            {['ALL', 'PENDING', 'CONFIRMED', 'OUT FOR DELIVERY', 'DELIVERED', 'CANCELLED'].map((f) => (
              <button
                key={f}
                onClick={() => setFilter(f)}
                className={`px-3 py-1.5 rounded-lg text-xs font-semibold transition-all ${
                  filter === f
                    ? 'bg-charcoal-header text-white shadow-sm'
                    : 'text-charcoal-muted hover:text-charcoal-ink hover:bg-charcoal-canvas'
                }`}
              >
                {f === 'ALL' ? 'All' : f}
              </button>
            ))}
          </div>
        </div>

        {/* Search & Date Filters */}
        <div className="flex flex-col sm:flex-row gap-3">
          <div className="relative flex-1">
            <Search className="w-4 h-4 text-charcoal-muted absolute left-3.5 top-2.5" />
            <input
              type="text"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              placeholder="Search order ID, customer, address, driver, or OCR Ref No..."
              className="w-full bg-white border border-charcoal-border rounded-xl pl-10 pr-4 py-2 text-xs text-charcoal-ink focus:outline-none focus:border-charcoal-header"
            />
          </div>
          <div className="flex items-center gap-2">
            <input
              type="date"
              value={dateFilter}
              onChange={(e) => setDateFilter(e.target.value)}
              className="bg-white border border-charcoal-border rounded-xl px-3 py-2 text-xs text-charcoal-ink focus:outline-none focus:border-charcoal-header"
            />
            {dateFilter && (
              <button
                onClick={() => setDateFilter('')}
                className="px-3 py-2 bg-white border border-charcoal-border rounded-xl text-xs font-semibold text-charcoal-muted hover:text-charcoal-ink"
              >
                Clear Date
              </button>
            )}
          </div>
        </div>
      </div>

      {/* Orders Table */}
      <div className="bg-white border border-charcoal-border rounded-2xl shadow-sm overflow-hidden">
        {filteredOrders.length === 0 ? (
          <div className="py-16 text-center text-charcoal-muted text-sm">
            Walang orders sa kasalukuyang filter.
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs min-w-[920px]">
              <thead className="bg-charcoal-header text-white font-semibold uppercase tracking-wider">
                <tr>
                  <th className="p-4">Order ID &amp; Date</th>
                  <th className="p-4">Customer Details</th>
                  <th className="p-4">Delivery Pin</th>
                  <th className="p-4">Total &amp; Payment</th>
                  <th className="p-4">Assigned Driver</th>
                  <th className="p-4">Status</th>
                  <th className="p-4 text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-charcoal-border">
                {filteredOrders.map((order) => {
                  const isOnline = order.paymentMethod === 'ONLINE_QR';
                  return (
                    <tr key={order.id} className="hover:bg-[#F8FAFA] transition-colors">
                      <td className="p-4">
                        <span className="font-mono font-bold text-charcoal-header text-sm">{order.id}</span>
                        <p className="text-[11px] text-charcoal-muted mt-0.5 font-mono">
                          {order.createdAt ? new Date(order.createdAt).toLocaleString() : '—'}
                        </p>
                      </td>

                      <td className="p-4">
                        <p className="font-bold text-charcoal-ink text-sm">{order.customerName || 'Customer'}</p>
                        <p className="text-[11px] text-charcoal-muted flex items-center gap-1 mt-0.5">
                          <Phone className="w-3 h-3" />
                          {order.customerPhone || 'No Phone'}
                        </p>
                      </td>

                      <td className="p-4 max-w-[210px]">
                        <p className="text-charcoal-ink font-medium truncate">{order.deliveryAddress}</p>
                        {order.deliveryLat && (
                          <p className="text-[11px] text-charcoal-eco flex items-center gap-1 mt-0.5 font-mono">
                            <MapPin className="w-3 h-3" />
                            {Number(order.deliveryLat).toFixed(4)}, {Number(order.deliveryLng).toFixed(4)}
                          </p>
                        )}
                      </td>

                      <td className="p-4">
                        <p className="font-bold text-charcoal-ink text-sm">{order.sacksOrdered || 1} Sacks</p>
                        <p className="text-charcoal-eco font-mono font-bold text-xs mt-0.5">
                          ₱ {(order.totalAmount || 0).toLocaleString()}
                          {Number(order.deliveryFee || 0) > 0 && (
                            <span className="text-[10px] text-charcoal-muted font-normal">
                              {' '}
                              (incl. ₱{order.deliveryFee} fee)
                            </span>
                          )}
                        </p>
                        <div className="mt-1 flex items-center gap-1.5 flex-wrap">
                          <span
                            className={`px-2 py-0.5 rounded text-[10px] font-bold ${
                              isOnline
                                ? 'bg-indigo-50 text-indigo-700 border border-indigo-200'
                                : 'bg-charcoal-canvas text-charcoal-ink border border-charcoal-border'
                            }`}
                          >
                            {isOnline ? 'ONLINE QR' : 'COD'}
                          </span>
                          {isOnline && (
                            <button
                              type="button"
                              onClick={() => openReceiptInspector(order)}
                              className="inline-flex items-center gap-1 px-2 py-0.5 rounded text-[10px] font-bold bg-[#E8F3EC] text-charcoal-eco border border-[#B7DFC7] hover:bg-charcoal-eco hover:text-white transition-colors"
                            >
                              <Receipt className="w-3 h-3" />
                              {order.paymentStatus === 'Verified' || order.paymentStatus === 'Paid'
                                ? 'Verified Receipt'
                                : 'Inspect OCR Receipt'}
                            </button>
                          )}
                        </div>
                        {isOnline && order.receiptRefNumber && (
                          <p className="text-[10px] font-mono text-charcoal-muted mt-0.5">
                            OCR Ref: {order.receiptRefNumber}
                          </p>
                        )}
                      </td>

                      <td className="p-4">
                        <select
                          disabled={updatingOrderId === order.id || order.status === 'Delivered' || order.status === 'Cancelled'}
                          value={order.driverId || ''}
                          onChange={(e) => handleAssignDriver(order, e.target.value)}
                          className="bg-charcoal-canvas border border-charcoal-border rounded-lg px-2.5 py-1.5 text-xs text-charcoal-ink font-medium focus:outline-none focus:border-charcoal-header disabled:opacity-50"
                        >
                          <option value="">-- Assign Driver --</option>
                          {availableDrivers.map((d) => {
                            const load = activeDriverCountMap[d.id] || 0;
                            return (
                              <option key={d.id} value={d.id}>
                                {d.isOnline ? '🟢 ' : '⚪ '}
                                {d.name} ({load} active)
                              </option>
                            );
                          })}
                        </select>
                      </td>

                      <td className="p-4">
                        <span
                          className={`px-2.5 py-1 rounded-full text-[11px] font-bold ${
                            order.status === 'Delivered'
                              ? 'bg-emerald-100 text-emerald-800 border border-emerald-200'
                              : order.status === 'Out for Delivery'
                              ? 'bg-teal-100 text-teal-800 border border-teal-200'
                              : order.status === 'Confirmed'
                              ? 'bg-blue-100 text-blue-800 border border-blue-200'
                              : order.status === 'Cancelled'
                              ? 'bg-rose-100 text-rose-800 border border-rose-200'
                              : 'bg-amber-100 text-amber-800 border border-amber-200'
                          }`}
                        >
                          {order.status || 'Pending'}
                        </span>
                      </td>

                      <td className="p-4 text-right space-x-1.5 whitespace-nowrap">
                        {order.status !== 'Out for Delivery' &&
                          order.status !== 'Delivered' &&
                          order.status !== 'Cancelled' && (
                            <button
                              disabled={updatingOrderId === order.id}
                              onClick={() => handleUpdateStatus(order, 'Out for Delivery')}
                              className="px-2.5 py-1 bg-charcoal-header hover:bg-charcoal-dark disabled:opacity-50 text-white rounded-lg text-xs font-semibold shadow-sm"
                            >
                              Dispatch
                            </button>
                          )}
                        {order.status === 'Out for Delivery' && (
                          <button
                            disabled={updatingOrderId === order.id}
                            onClick={() => handleUpdateStatus(order, 'Delivered')}
                            className="px-2.5 py-1 bg-charcoal-eco hover:bg-[#2F6346] disabled:opacity-50 text-white rounded-lg text-xs font-semibold shadow-sm"
                          >
                            Complete
                          </button>
                        )}
                        {order.status !== 'Cancelled' && order.status !== 'Delivered' && (
                          <button
                            disabled={updatingOrderId === order.id}
                            onClick={() => {
                              setCancelReason('Cancelled by Admin');
                              setCancelTargetOrder(order);
                            }}
                            className="px-2.5 py-1 bg-charcoal-canvas hover:bg-rose-600 disabled:opacity-50 border border-charcoal-border text-charcoal-ink hover:text-white rounded-lg text-xs font-medium"
                          >
                            Cancel
                          </button>
                        )}
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* Receipt Inspection Modal */}
      {inspectOrder && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-sm p-4">
          <div className="bg-white border border-charcoal-border rounded-2xl w-full max-w-lg shadow-2xl overflow-hidden text-charcoal-ink">
            <div className="px-5 py-4 bg-charcoal-header text-white flex items-center justify-between">
              <div>
                <h3 className="font-bold text-sm">Online Payment OCR &amp; Receipt Inspection</h3>
                <p className="text-[11px] text-[#CBD5D4] font-mono">Order {inspectOrder.id}</p>
              </div>
              <button onClick={() => setInspectOrder(null)} className="p-1 hover:bg-charcoal-hover rounded-lg">
                <X className="w-4 h-4" />
              </button>
            </div>

            <div className="p-5 space-y-4 text-xs">
              <div className="grid grid-cols-2 gap-3 bg-charcoal-canvas p-3.5 rounded-xl border border-charcoal-border">
                <div>
                  <span className="text-charcoal-muted block">OCR Reference No.</span>
                  <span className="font-mono font-bold text-sm text-charcoal-header">
                    {inspectOrder.receiptRefNumber || receiptData?.ocrRefNumber || 'N/A'}
                  </span>
                </div>
                <div>
                  <span className="text-charcoal-muted block">Order Total vs OCR Amount</span>
                  <span className="font-mono font-bold text-sm text-charcoal-eco">
                    ₱{Number(inspectOrder.totalAmount || 0).toLocaleString()}
                    {inspectOrder.ocrDetectedAmount != null && (
                      <span className="text-charcoal-ink font-normal">
                        {' '}
                        / OCR: ₱{Number(inspectOrder.ocrDetectedAmount).toLocaleString()}
                      </span>
                    )}
                  </span>
                </div>
              </div>

              {receiptLoading ? (
                <div className="py-12 text-center text-charcoal-muted">Loading uploaded receipt photo...</div>
              ) : receiptData?.imageBase64 ? (
                <div className="border border-charcoal-border rounded-xl overflow-hidden bg-charcoal-canvas flex justify-center max-h-80">
                  <img
                    src={receiptData.imageBase64}
                    alt="Customer Payment Receipt"
                    className="max-h-80 object-contain"
                  />
                </div>
              ) : (
                <div className="py-10 text-center text-rose-600 bg-rose-50 rounded-xl border border-rose-200 flex flex-col items-center gap-2">
                  <AlertCircle className="w-6 h-6" />
                  <span>No receipt image found for this order.</span>
                </div>
              )}

              {inspectOrder.status !== 'Cancelled' && inspectOrder.status !== 'Delivered' && (
                <div className="flex justify-end gap-2 pt-2 border-t border-charcoal-border">
                  <button
                    type="button"
                    onClick={() => {
                      const target = inspectOrder;
                      setInspectOrder(null);
                      setCancelReason('Invalid or unverified online payment receipt');
                      setCancelTargetOrder(target);
                    }}
                    className="px-4 py-2 bg-rose-50 hover:bg-rose-600 text-rose-700 hover:text-white border border-rose-200 rounded-xl font-bold flex items-center gap-1.5"
                  >
                    <XCircle className="w-4 h-4" />
                    Reject &amp; Cancel Order
                  </button>
                  <button
                    type="button"
                    onClick={async () => {
                      const target = inspectOrder;
                      await handleUpdateStatus(
                        target,
                        target.status === 'Pending' ? 'Confirmed' : target.status,
                        { paymentStatus: 'Verified' }
                      );
                      setInspectOrder(null);
                    }}
                    className="px-4 py-2 bg-charcoal-eco hover:bg-[#2F6346] text-white rounded-xl font-bold flex items-center gap-1.5 shadow-sm"
                  >
                    <CheckCircle2 className="w-4 h-4" />
                    Mark Payment Verified
                  </button>
                </div>
              )}
            </div>
          </div>
        </div>
      )}

      {/* Cancel Order Confirmation Modal */}
      {cancelTargetOrder && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm p-4">
          <div className="bg-white border border-charcoal-border rounded-2xl p-6 w-full max-w-md shadow-2xl text-charcoal-ink">
            <h3 className="font-bold text-base mb-1">Cancel Order {cancelTargetOrder.id}?</h3>
            <p className="text-xs text-charcoal-muted mb-4">
              Ibabalik nito ang {cancelTargetOrder.sacksOrdered} sako sa Inventory at ire-release ang receipt reference number kung online payment.
            </p>
            <div className="text-xs mb-4">
              <label className="block font-semibold mb-1">Reason for cancellation</label>
              <input
                type="text"
                maxLength={150}
                value={cancelReason}
                onChange={(e) => setCancelReason(e.target.value)}
                className="w-full bg-charcoal-canvas border border-charcoal-border rounded-xl px-3.5 py-2 text-charcoal-ink focus:outline-none focus:border-charcoal-header"
              />
            </div>
            <div className="flex justify-end gap-2 text-xs">
              <button
                type="button"
                onClick={() => setCancelTargetOrder(null)}
                className="px-4 py-2 bg-charcoal-canvas border border-charcoal-border rounded-xl font-semibold"
              >
                Keep Order
              </button>
              <button
                type="button"
                onClick={async () => {
                  const target = cancelTargetOrder;
                  setCancelTargetOrder(null);
                  await handleUpdateStatus(target, 'Cancelled', {
                    cancelReason: cancelReason.trim() || 'Cancelled by Admin',
                  });
                }}
                className="px-4 py-2 bg-rose-600 hover:bg-rose-700 text-white rounded-xl font-bold"
              >
                Confirm Cancel &amp; Restore Stock
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
