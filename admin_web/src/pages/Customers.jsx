import React, { useEffect, useState } from 'react';
import { sendPasswordResetEmail } from 'firebase/auth';
import { ref, onValue, update, remove } from 'firebase/database';
import { auth, db } from '../firebase';
import {
  formatDigitsOnly,
  sanitizeText,
  validateName,
  validatePhPhone,
} from '../utils/validators';
import {
  Users,
  Search,
  Phone,
  Mail,
  Edit3,
  KeyRound,
  Ban,
  CheckCircle2,
  Trash2,
  ShoppingBag,
  ShieldAlert,
} from 'lucide-react';

export default function Customers() {
  const [customers, setCustomers] = useState([]);
  const [orders, setOrders] = useState([]);
  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState('');
  const [statusFilter, setStatusFilter] = useState('ALL');
  const [pageNotice, setPageNotice] = useState('');
  const [pageError, setPageError] = useState('');

  const [editingCustomer, setEditingCustomer] = useState(null);
  const [editName, setEditName] = useState('');
  const [editPhone, setEditPhone] = useState('');
  const [formError, setFormError] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);

  const [toggleCustomerTarget, setToggleCustomerTarget] = useState(null);
  const [deleteCustomerTarget, setDeleteCustomerTarget] = useState(null);
  const [isDeleting, setIsDeleting] = useState(false);

  useEffect(() => {
    const unsubUsers = onValue(
      ref(db, 'users'),
      (snap) => {
        if (!snap.exists()) {
          setCustomers([]);
          setLoading(false);
          return;
        }
        const raw = snap.val();
        const list = Object.entries(raw)
          .map(([id, val]) => ({ id, ...val }))
          .filter((u) => u.role === 'customer');
        list.sort((a, b) => (b.createdAt || '').localeCompare(a.createdAt || ''));
        setCustomers(list);
        setLoading(false);
      },
      (err) => {
        setPageError(err.message || 'Unable to load customers.');
        setLoading(false);
      }
    );

    const unsubOrders = onValue(ref(db, 'orders'), (snap) => {
      if (!snap.exists()) return setOrders([]);
      const raw = snap.val();
      setOrders(Object.entries(raw).map(([id, val]) => ({ id, ...val })));
    });

    return () => {
      unsubUsers();
      unsubOrders();
    };
  }, []);

  const openEditModal = (customer) => {
    setFormError('');
    setEditingCustomer(customer);
    setEditName(customer.name || '');
    setEditPhone(formatDigitsOnly(customer.phone || '', 12));
  };

  const handleSaveEdit = async (e) => {
    e.preventDefault();
    if (!editingCustomer || isSubmitting) return;
    setFormError('');

    const nameErr = validateName(editName, 'Customer Name');
    if (nameErr) return setFormError(nameErr);
    const phoneErr = validatePhPhone(editPhone);
    if (phoneErr) return setFormError(phoneErr);

    const cleanName = sanitizeText(editName);
    const cleanPhone = formatDigitsOnly(editPhone, 12);

    setIsSubmitting(true);
    try {
      await update(ref(db, `users/${editingCustomer.id}`), {
        name: cleanName,
        phone: cleanPhone,
        updatedAt: new Date().toISOString(),
      });
      setEditingCustomer(null);
      setPageNotice(`Updated details for ${cleanName}.`);
    } catch (err) {
      setFormError(err.message || 'Failed to update customer.');
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleToggleActive = async (customer) => {
    setPageError('');
    setPageNotice('');
    const nextActive = customer.isActive === false;
    try {
      await update(ref(db, `users/${customer.id}`), {
        isActive: nextActive,
        updatedAt: new Date().toISOString(),
      });
      setPageNotice(
        `${customer.name || customer.email} has been ${
          nextActive ? 'reactivated' : 'deactivated (login blocked)'
        }.`
      );
    } catch (err) {
      setPageError(err.message || 'Failed to update customer status.');
    }
  };

  const handleSendPasswordReset = async (customerEmail) => {
    setPageError('');
    setPageNotice('');
    try {
      await sendPasswordResetEmail(auth, customerEmail);
      setPageNotice(`Password reset email sent to ${customerEmail}.`);
    } catch (err) {
      setPageError(err.message || 'Failed to send password reset email.');
    }
  };

  const handleDeleteCustomer = async (customer) => {
    if (!customer || isDeleting) return;
    setPageError('');
    setPageNotice('');

    const activeOrdersCount = orders.filter(
      (o) =>
        o.customerId === customer.id &&
        (o.status === 'Pending' || o.status === 'Confirmed' || o.status === 'Out for Delivery')
    ).length;

    if (activeOrdersCount > 0) {
      setPageError(
        `Cannot delete ${customer.name || customer.email} while they have ${activeOrdersCount} active order(s). Please complete or cancel them first.`
      );
      return;
    }

    setIsDeleting(true);
    try {
      await remove(ref(db, `users/${customer.id}`));
      setPageNotice(`Deleted customer account for ${customer.name || customer.email}.`);
    } catch (err) {
      setPageError(err.message || 'Failed to delete customer account.');
    } finally {
      setIsDeleting(false);
    }
  };

  const filteredCustomers = customers.filter((c) => {
    const isActive = c.isActive !== false;
    if (statusFilter === 'ACTIVE' && !isActive) return false;
    if (statusFilter === 'DEACTIVATED' && isActive) return false;

    const q = searchQuery.trim().toLowerCase();
    if (!q) return true;
    return (
      (c.name || '').toLowerCase().includes(q) ||
      (c.email || '').toLowerCase().includes(q) ||
      (c.phone || '').toLowerCase().includes(q)
    );
  });

  const activeTotal = customers.filter((c) => c.isActive !== false).length;
  const deactivatedTotal = customers.length - activeTotal;

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
        <div>
          <h1 className="text-2xl font-bold text-charcoal-ink tracking-tight">Customer Management</h1>
          <p className="text-sm text-charcoal-muted">
            View registered customers, order activity, update details, reset passwords, or manage account access.
          </p>
        </div>

        <div className="flex items-center gap-2 text-xs">
          {['ALL', 'ACTIVE', 'DEACTIVATED'].map((f) => (
            <button
              key={f}
              onClick={() => setStatusFilter(f)}
              className={`px-3 py-1.5 rounded-lg font-semibold border transition-colors ${
                statusFilter === f
                  ? 'bg-charcoal-header text-white border-charcoal-header'
                  : 'bg-white text-charcoal-muted border-charcoal-border hover:text-charcoal-ink'
              }`}
            >
              {f === 'ALL' ? `All (${customers.length})` : f === 'ACTIVE' ? `Active (${activeTotal})` : `Deactivated (${deactivatedTotal})`}
            </button>
          ))}
        </div>
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
          <p className="font-bold text-charcoal-ink">Customer Account Access</p>
          <p className="mt-0.5">
            Deactivating or deleting a customer immediately blocks their mobile app login and order placement via Realtime Database rules.
          </p>
        </div>
      </div>

      {/* Search */}
      <div className="relative">
        <Search className="w-4 h-4 text-charcoal-muted absolute left-3.5 top-2.5" />
        <input
          type="text"
          maxLength={100}
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
          placeholder="Search customer name, email, or phone number..."
          className="w-full bg-white border border-charcoal-border rounded-xl pl-10 pr-4 py-2 text-xs text-charcoal-ink focus:outline-none focus:border-charcoal-header"
        />
      </div>

      {/* Customers Table */}
      <div className="bg-white border border-charcoal-border rounded-2xl shadow-sm overflow-hidden">
        {loading ? (
          <div className="py-16 text-center text-charcoal-muted text-sm">Loading customers...</div>
        ) : filteredCustomers.length === 0 ? (
          <div className="py-16 text-center text-charcoal-muted text-sm flex flex-col items-center gap-2">
            <Users className="w-8 h-8 opacity-40" />
            <span>No matching customer accounts found.</span>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs min-w-[820px]">
              <thead className="bg-charcoal-header text-white font-semibold uppercase tracking-wider">
                <tr>
                  <th className="p-4">Customer</th>
                  <th className="p-4">Contact</th>
                  <th className="p-4">Orders &amp; Total Spent</th>
                  <th className="p-4">Joined</th>
                  <th className="p-4">Account Status</th>
                  <th className="p-4 text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-charcoal-border">
                {filteredCustomers.map((customer) => {
                  const isActive = customer.isActive !== false;
                  const custOrders = orders.filter((o) => o.customerId === customer.id);
                  const activeCount = custOrders.filter(
                    (o) =>
                      o.status === 'Pending' ||
                      o.status === 'Confirmed' ||
                      o.status === 'Out for Delivery'
                  ).length;
                  const deliveredOrders = custOrders.filter((o) => o.status === 'Delivered');
                  const totalSpent = deliveredOrders.reduce(
                    (sum, o) => sum + Number(o.totalAmount || 0),
                    0
                  );

                  return (
                    <tr key={customer.id} className="hover:bg-[#F8FAFA] transition-colors">
                      <td className="p-4">
                        <div className="flex items-center gap-3">
                          <div className="w-10 h-10 rounded-xl bg-charcoal-canvas text-charcoal-header font-bold flex items-center justify-center text-sm border border-charcoal-border">
                            {customer.name ? customer.name.substring(0, 2).toUpperCase() : 'CU'}
                          </div>
                          <div>
                            <p className="font-bold text-charcoal-ink text-sm">
                              {customer.name || 'Unnamed Customer'}
                            </p>
                            <p className="text-[11px] text-charcoal-muted font-mono">
                              ID: {customer.id.slice(0, 8)}...
                            </p>
                          </div>
                        </div>
                      </td>

                      <td className="p-4 space-y-1">
                        <p className="text-charcoal-header flex items-center gap-1.5 font-mono text-[11px] font-semibold">
                          <Mail className="w-3 h-3 text-charcoal-eco" />
                          {customer.email || 'No email'}
                        </p>
                        <p className="text-[11px] text-charcoal-muted flex items-center gap-1.5">
                          <Phone className="w-3 h-3" />
                          {customer.phone || 'No phone'}
                        </p>
                      </td>

                      <td className="p-4">
                        <p className="font-bold text-charcoal-ink flex items-center gap-1">
                          <ShoppingBag className="w-3.5 h-3.5 text-charcoal-eco" />
                          {custOrders.length} total ({deliveredOrders.length} delivered)
                        </p>
                        <p className="text-[11px] text-charcoal-muted mt-0.5 font-mono">
                          ₱ {totalSpent.toLocaleString('en-US', { minimumFractionDigits: 2 })}
                          {activeCount > 0 ? ` • ${activeCount} active` : ''}
                        </p>
                      </td>

                      <td className="p-4 text-[11px] text-charcoal-muted">
                        {customer.createdAt
                          ? new Date(customer.createdAt).toLocaleDateString()
                          : '—'}
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
                          onClick={() => openEditModal(customer)}
                          className="p-2 text-charcoal-muted hover:text-charcoal-header hover:bg-charcoal-canvas rounded-lg transition-colors"
                          title="Edit Customer Details"
                        >
                          <Edit3 className="w-4 h-4" />
                        </button>
                        {customer.email && (
                          <button
                            onClick={() => handleSendPasswordReset(customer.email)}
                            className="p-2 text-charcoal-muted hover:text-charcoal-eco hover:bg-[#E8F3EC] rounded-lg transition-colors"
                            title="Send Password Reset Email"
                          >
                            <KeyRound className="w-4 h-4" />
                          </button>
                        )}
                        <button
                          onClick={() => setToggleCustomerTarget(customer)}
                          className={`p-2 rounded-lg transition-colors ${
                            isActive
                              ? 'text-charcoal-muted hover:text-rose-600 hover:bg-rose-50'
                              : 'text-charcoal-eco hover:bg-[#E8F3EC]'
                          }`}
                          title={isActive ? 'Deactivate Customer' : 'Reactivate Customer'}
                        >
                          {isActive ? <Ban className="w-4 h-4" /> : <CheckCircle2 className="w-4 h-4" />}
                        </button>
                        <button
                          onClick={() => setDeleteCustomerTarget(customer)}
                          className="p-2 text-charcoal-muted hover:text-rose-600 hover:bg-rose-50 rounded-lg transition-colors"
                          title="Delete Customer Account"
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

      {/* Edit Customer Modal */}
      {editingCustomer && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm p-4">
          <div className="bg-white border border-charcoal-border rounded-2xl p-6 w-full max-w-md shadow-2xl text-charcoal-ink">
            <h3 className="font-bold text-lg mb-1">Edit Customer Details</h3>
            <p className="text-xs text-charcoal-muted mb-4">{editingCustomer.email}</p>
            <form onSubmit={handleSaveEdit} className="space-y-3 text-xs">
              {formError && (
                <div className="p-3 rounded-xl bg-rose-50 border border-rose-200 text-rose-700">
                  {formError}
                </div>
              )}
              <div>
                <label className="block font-semibold mb-1">Customer Name</label>
                <input
                  type="text"
                  required
                  maxLength={60}
                  value={editName}
                  onChange={(e) => setEditName(e.target.value)}
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
                  value={editPhone}
                  onChange={(e) => setEditPhone(formatDigitsOnly(e.target.value, 12))}
                  placeholder="09171234567 or 0281234567"
                  className="w-full bg-charcoal-canvas border border-charcoal-border rounded-xl px-3.5 py-2.5 focus:outline-none focus:border-charcoal-header"
                />
              </div>
              <div className="flex justify-end gap-2 pt-2">
                <button
                  type="button"
                  disabled={isSubmitting}
                  onClick={() => setEditingCustomer(null)}
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
      {toggleCustomerTarget && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm p-4">
          <div className="bg-white border border-charcoal-border rounded-2xl p-6 w-full max-w-sm shadow-2xl text-charcoal-ink">
            <h3 className="font-bold text-base mb-1">
              {toggleCustomerTarget.isActive === false ? 'Reactivate' : 'Deactivate'} Customer{' '}
              {toggleCustomerTarget.name || toggleCustomerTarget.email}?
            </h3>
            <p className="text-xs text-charcoal-muted mb-4">
              {toggleCustomerTarget.isActive === false
                ? 'This customer will be allowed to log in and place orders again.'
                : 'This customer will no longer be able to log in or place new orders.'}
            </p>
            <div className="flex justify-end gap-2 text-xs">
              <button
                type="button"
                onClick={() => setToggleCustomerTarget(null)}
                className="px-4 py-2 bg-charcoal-canvas border border-charcoal-border rounded-xl font-semibold"
              >
                Cancel
              </button>
              <button
                type="button"
                onClick={() => {
                  const target = toggleCustomerTarget;
                  setToggleCustomerTarget(null);
                  handleToggleActive(target);
                }}
                className={`px-4 py-2 text-white rounded-xl font-bold ${
                  toggleCustomerTarget.isActive === false
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

      {/* Delete Customer Confirmation Modal */}
      {deleteCustomerTarget && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm p-4">
          <div className="bg-white border border-charcoal-border rounded-2xl p-6 w-full max-w-sm shadow-2xl text-charcoal-ink">
            <h3 className="font-bold text-base text-rose-700 mb-1">
              Delete Customer {deleteCustomerTarget.name || deleteCustomerTarget.email}?
            </h3>
            <p className="text-xs text-charcoal-muted mb-4">
              This will permanently remove their customer profile ({deleteCustomerTarget.email}) and block all app login access. This action cannot be undone.
            </p>
            <div className="flex justify-end gap-2 text-xs">
              <button
                type="button"
                disabled={isDeleting}
                onClick={() => setDeleteCustomerTarget(null)}
                className="px-4 py-2 bg-charcoal-canvas border border-charcoal-border rounded-xl font-semibold"
              >
                Cancel
              </button>
              <button
                type="button"
                disabled={isDeleting}
                onClick={async () => {
                  const target = deleteCustomerTarget;
                  setDeleteCustomerTarget(null);
                  await handleDeleteCustomer(target);
                }}
                className="px-4 py-2 bg-rose-600 hover:bg-rose-700 disabled:opacity-60 text-white rounded-xl font-bold"
              >
                {isDeleting ? 'Deleting...' : 'Delete Customer'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
