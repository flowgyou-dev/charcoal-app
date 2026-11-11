import React, { useEffect, useMemo, useState } from 'react';
import { ref, onValue } from 'firebase/database';
import { db } from '../firebase';
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  BarElement,
  Title,
  Tooltip,
  Legend,
} from 'chart.js';
import { Bar } from 'react-chartjs-2';
import Papa from 'papaparse';
import { Download } from 'lucide-react';

ChartJS.register(CategoryScale, LinearScale, BarElement, Title, Tooltip, Legend);

function toLocalDateKey(date) {
  const y = date.getFullYear();
  const m = String(date.getMonth() + 1).padStart(2, '0');
  const d = String(date.getDate()).padStart(2, '0');
  return `${y}-${m}-${d}`;
}

export default function Analytics() {
  const [orders, setOrders] = useState([]);
  const [rangePreset, setRangePreset] = useState('7d');
  const [customStart, setCustomStart] = useState('');
  const [customEnd, setCustomEnd] = useState('');
  const [notice, setNotice] = useState('');
  const [loadError, setLoadError] = useState('');

  useEffect(() => {
    const ordersRef = ref(db, 'orders');
    const unsub = onValue(
      ordersRef,
      (snap) => {
        if (snap.exists()) {
          const val = snap.val();
          setOrders(Object.keys(val).map((k) => ({ id: k, ...val[k] })));
        } else {
          setOrders([]);
        }
      },
      (err) => setLoadError(err.message || 'Unable to load analytics data.')
    );

    return () => unsub();
  }, []);

  const { filteredDelivered, allInRange, bucketLabels, revenueSeries, sacksSeries } = useMemo(() => {
    const now = new Date();
    const todayEnd = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 23, 59, 59, 999);

    let startDate = null;
    let endDate = todayEnd;

    if (rangePreset === '7d') {
      startDate = new Date(now.getFullYear(), now.getMonth(), now.getDate() - 6, 0, 0, 0, 0);
    } else if (rangePreset === '30d') {
      startDate = new Date(now.getFullYear(), now.getMonth(), now.getDate() - 29, 0, 0, 0, 0);
    } else if (rangePreset === 'custom') {
      startDate = customStart ? new Date(`${customStart}T00:00:00`) : null;
      endDate = customEnd ? new Date(`${customEnd}T23:59:59.999`) : todayEnd;
    }

    const inRange = orders.filter((o) => {
      if (!o.createdAt) return rangePreset === 'all';
      const d = new Date(o.createdAt);
      if (Number.isNaN(d.getTime())) return false;
      if (startDate && d < startDate) return false;
      if (endDate && d > endDate) return false;
      return true;
    });

    const delivered = inRange.filter((o) => o.status === 'Delivered');

    // Build chronological calendar buckets
    const buckets = new Map();
    if (rangePreset === '7d' || rangePreset === '30d') {
      const count = rangePreset === '7d' ? 7 : 30;
      for (let i = count - 1; i >= 0; i -= 1) {
        const d = new Date(now.getFullYear(), now.getMonth(), now.getDate() - i);
        const key = toLocalDateKey(d);
        const label = d.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
        buckets.set(key, { label, revenue: 0, sacks: 0 });
      }
    } else {
      const sorted = [...delivered].sort((a, b) => new Date(a.createdAt || 0) - new Date(b.createdAt || 0));
      sorted.forEach((o) => {
        const d = o.createdAt ? new Date(o.createdAt) : now;
        const key = toLocalDateKey(d);
        if (!buckets.has(key)) {
          buckets.set(key, {
            label: d.toLocaleDateString('en-US', { month: 'short', day: 'numeric' }),
            revenue: 0,
            sacks: 0,
          });
        }
      });
    }

    delivered.forEach((o) => {
      const d = o.createdAt ? new Date(o.createdAt) : now;
      const key = toLocalDateKey(d);
      if (buckets.has(key)) {
        const b = buckets.get(key);
        b.revenue += Number(o.totalAmount) || 0;
        b.sacks += Number(o.sacksOrdered) || 0;
      }
    });

    const values = Array.from(buckets.values());
    return {
      filteredDelivered: delivered,
      allInRange: inRange,
      bucketLabels: values.map((v) => v.label),
      revenueSeries: values.map((v) => v.revenue),
      sacksSeries: values.map((v) => v.sacks),
    };
  }, [orders, rangePreset, customStart, customEnd]);

  const revenueChartData = {
    labels: bucketLabels,
    datasets: [
      {
        label: 'Delivered Revenue (₱)',
        data: revenueSeries,
        backgroundColor: 'rgba(36, 61, 60, 0.85)',
        borderColor: '#243D3C',
        borderWidth: 2,
        borderRadius: 6,
      },
    ],
  };

  const sacksChartData = {
    labels: bucketLabels,
    datasets: [
      {
        label: 'Sacks Delivered',
        data: sacksSeries,
        backgroundColor: 'rgba(62, 124, 89, 0.85)',
        borderColor: '#3E7C59',
        borderWidth: 2,
        borderRadius: 6,
      },
    ],
  };

  const chartOptions = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      legend: {
        labels: { color: '#1E2929', font: { size: 12 } },
      },
    },
    scales: {
      x: { ticks: { color: '#617070' }, grid: { color: '#E5E9E8' } },
      y: { ticks: { color: '#617070' }, grid: { color: '#E5E9E8' } },
    },
  };

  const handleExportCSV = () => {
    setNotice('');
    if (allInRange.length === 0) {
      setNotice('Walang orders sa napiling date range para i-export.');
      return;
    }

    const csvData = allInRange.map((o) => ({
      'Order ID': o.id,
      'Customer Name': o.customerName || '',
      'Customer Phone': o.customerPhone || '',
      'Delivery Address': o.deliveryAddress || '',
      'Sacks Ordered': o.sacksOrdered || 1,
      'Subtotal (PHP)': o.subtotalAmount ?? o.totalAmount ?? 0,
      'Delivery Fee (PHP)': o.deliveryFee ?? 0,
      'Total Amount (PHP)': o.totalAmount || 0,
      'Payment Method': o.paymentMethod === 'ONLINE_QR' ? 'Online QR' : 'COD',
      'Payment Status': o.paymentStatus || '',
      'OCR Ref No': o.receiptRefNumber || '',
      'Assigned Driver': o.driverName || 'Unassigned',
      Status: o.status || 'Pending',
      'Date Created': o.createdAt || '',
    }));

    const csv = Papa.unparse(csvData);
    const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.setAttribute('download', `Charcoal_Sales_Report_${new Date().toISOString().split('T')[0]}.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    setTimeout(() => URL.revokeObjectURL(url), 1000);
    setNotice(`Exported ${allInRange.length} order record(s) to CSV.`);
  };

  const totalRevenue = filteredDelivered.reduce((sum, o) => sum + (Number(o.totalAmount) || 0), 0);
  const totalSacks = filteredDelivered.reduce((sum, o) => sum + (Number(o.sacksOrdered) || 0), 0);
  const onlineRevenue = filteredDelivered
    .filter((o) => o.paymentMethod === 'ONLINE_QR')
    .reduce((sum, o) => sum + (Number(o.totalAmount) || 0), 0);
  const codRevenue = totalRevenue - onlineRevenue;
  const cancelledCount = allInRange.filter((o) => o.status === 'Cancelled').length;

  return (
    <div className="space-y-6">
      {loadError && (
        <div className="p-3 rounded-xl bg-rose-50 border border-rose-200 text-xs text-rose-700">{loadError}</div>
      )}
      {notice && (
        <div className="p-3 rounded-xl bg-[#E8F3EC] border border-[#B7DFC7] text-xs text-charcoal-eco font-semibold flex justify-between">
          <span>{notice}</span>
          <button onClick={() => setNotice('')} className="font-bold">×</button>
        </div>
      )}

      <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-3">
        <div>
          <h1 className="text-2xl font-bold text-charcoal-ink tracking-tight">Sales Analytics &amp; Reports</h1>
          <p className="text-sm text-charcoal-muted">
            Kita at dami ng naideliver na uling base sa totoong calendar dates (excluded ang Cancelled/unpaid).
          </p>
        </div>
        <button
          onClick={handleExportCSV}
          className="px-4 py-2.5 bg-charcoal-eco hover:bg-[#2F6346] text-white rounded-xl text-xs font-bold shadow-sm transition-all flex items-center gap-2 self-start lg:self-auto"
        >
          <Download className="w-4 h-4" />
          Export Filtered CSV
        </button>
      </div>

      {/* Date Range Filters */}
      <div className="bg-white border border-charcoal-border rounded-2xl p-3 flex flex-wrap items-center gap-2 text-xs shadow-sm">
        {[
          { id: '7d', label: 'Last 7 Days' },
          { id: '30d', label: 'Last 30 Days' },
          { id: 'all', label: 'All Time' },
          { id: 'custom', label: 'Custom Range' },
        ].map((p) => (
          <button
            key={p.id}
            onClick={() => setRangePreset(p.id)}
            className={`px-3 py-1.5 rounded-lg font-semibold transition-colors ${
              rangePreset === p.id
                ? 'bg-charcoal-header text-white'
                : 'text-charcoal-muted hover:bg-charcoal-canvas'
            }`}
          >
            {p.label}
          </button>
        ))}
        {rangePreset === 'custom' && (
          <div className="flex items-center gap-2 ml-auto">
            <input
              type="date"
              value={customStart}
              onChange={(e) => setCustomStart(e.target.value)}
              className="bg-charcoal-canvas border border-charcoal-border rounded-lg px-2.5 py-1 text-xs"
            />
            <span className="text-charcoal-muted">to</span>
            <input
              type="date"
              value={customEnd}
              onChange={(e) => setCustomEnd(e.target.value)}
              className="bg-charcoal-canvas border border-charcoal-border rounded-lg px-2.5 py-1 text-xs"
            />
          </div>
        )}
      </div>

      {/* KPI Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <div className="bg-white border border-charcoal-border rounded-2xl p-5 shadow-sm">
          <p className="text-xs font-medium text-charcoal-muted uppercase tracking-wider">Delivered Revenue</p>
          <h3 className="text-2xl font-black text-charcoal-eco mt-2 font-mono">
            ₱ {totalRevenue.toLocaleString('en-US', { minimumFractionDigits: 2 })}
          </h3>
          <p className="text-xs text-charcoal-muted mt-1">{filteredDelivered.length} completed deliveries</p>
        </div>

        <div className="bg-white border border-charcoal-border rounded-2xl p-5 shadow-sm">
          <p className="text-xs font-medium text-charcoal-muted uppercase tracking-wider">Sacks Delivered</p>
          <h3 className="text-2xl font-black text-charcoal-header mt-2">
            {totalSacks} <span className="text-sm font-semibold text-charcoal-muted">sacks</span>
          </h3>
          <p className="text-xs text-charcoal-muted mt-1">{cancelledCount} cancelled in range</p>
        </div>

        <div className="bg-white border border-charcoal-border rounded-2xl p-5 shadow-sm">
          <p className="text-xs font-medium text-charcoal-muted uppercase tracking-wider">COD vs Online QR</p>
          <h3 className="text-lg font-black text-charcoal-ink mt-2 font-mono">
            ₱{codRevenue.toLocaleString()} / ₱{onlineRevenue.toLocaleString()}
          </h3>
          <p className="text-xs text-charcoal-muted mt-1">Cash on Delivery vs QR verified</p>
        </div>

        <div className="bg-white border border-charcoal-border rounded-2xl p-5 shadow-sm">
          <p className="text-xs font-medium text-charcoal-muted uppercase tracking-wider">Average Order Value</p>
          <h3 className="text-2xl font-black text-teal-700 mt-2 font-mono">
            ₱ {filteredDelivered.length > 0 ? (totalRevenue / filteredDelivered.length).toFixed(2) : '0.00'}
          </h3>
          <p className="text-xs text-charcoal-muted mt-1">Per delivered order</p>
        </div>
      </div>

      {/* Charts */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="bg-white border border-charcoal-border rounded-2xl p-5 shadow-sm">
          <h3 className="font-bold text-base text-charcoal-ink mb-4">Revenue Trend</h3>
          <div className="h-72 w-full">
            <Bar data={revenueChartData} options={chartOptions} />
          </div>
        </div>

        <div className="bg-white border border-charcoal-border rounded-2xl p-5 shadow-sm">
          <h3 className="font-bold text-base text-charcoal-ink mb-4">Delivered Sacks Volume</h3>
          <div className="h-72 w-full">
            <Bar data={sacksChartData} options={chartOptions} />
          </div>
        </div>
      </div>
    </div>
  );
}
