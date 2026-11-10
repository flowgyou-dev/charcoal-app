import React, { useEffect, useState } from 'react';
import { ref, onValue } from 'firebase/database';
import { db } from '../firebase';
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  BarElement,
  LineElement,
  PointElement,
  Title,
  Tooltip,
  Legend,
} from 'chart.js';
import { Bar, Line } from 'react-chartjs-2';
import Papa from 'papaparse';
import { Download, TrendingUp, Calendar, DollarSign } from 'lucide-react';

ChartJS.register(
  CategoryScale,
  LinearScale,
  BarElement,
  LineElement,
  PointElement,
  Title,
  Tooltip,
  Legend
);

export default function Analytics() {
  const [orders, setOrders] = useState([]);

  useEffect(() => {
    const ordersRef = ref(db, 'orders');
    const unsub = onValue(ordersRef, (snap) => {
      if (snap.exists()) {
        const val = snap.val();
        setOrders(Object.keys(val).map(k => ({ id: k, ...val[k] })));
      } else {
        setOrders([]);
      }
    });

    return () => unsub();
  }, []);

  // Compute Daily Sales over the last 7 days
  const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  const dailyRevenue = [0, 0, 0, 0, 0, 0, 0];
  const dailySacks = [0, 0, 0, 0, 0, 0, 0];

  orders.forEach(order => {
    const date = order.createdAt ? new Date(order.createdAt) : new Date();
    const dayIdx = date.getDay();
    dailyRevenue[dayIdx] += Number(order.totalAmount) || 0;
    dailySacks[dayIdx] += Number(order.sacksOrdered) || 0;
  });

  const revenueChartData = {
    labels: days,
    datasets: [
      {
        label: 'Gross Sales (₱)',
        data: dailyRevenue,
        backgroundColor: 'rgba(16, 185, 129, 0.8)',
        borderColor: '#10b981',
        borderWidth: 2,
        borderRadius: 8,
      },
    ],
  };

  const sacksChartData = {
    labels: days,
    datasets: [
      {
        label: 'Sacks of Uling Sold',
        data: dailySacks,
        backgroundColor: 'rgba(245, 158, 11, 0.8)',
        borderColor: '#f59e0b',
        borderWidth: 2,
        borderRadius: 8,
      },
    ],
  };

  const chartOptions = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      legend: {
        labels: {
          color: '#cbd5e1',
          font: { size: 12 },
        },
      },
    },
    scales: {
      x: {
        ticks: { color: '#94a3b8' },
        grid: { color: 'rgba(51, 65, 85, 0.4)' },
      },
      y: {
        ticks: { color: '#94a3b8' },
        grid: { color: 'rgba(51, 65, 85, 0.4)' },
      },
    },
  };

  // Export to CSV Function
  const handleExportCSV = () => {
    if (orders.length === 0) {
      alert('Walang orders data para i-export.');
      return;
    }

    const csvData = orders.map(o => ({
      'Order ID': o.id,
      'Customer Name': o.customerName || '',
      'Customer Phone': o.customerPhone || '',
      'Delivery Address': o.deliveryAddress || '',
      'Sacks Ordered': o.sacksOrdered || 1,
      'Total Amount (PHP)': o.totalAmount || 0,
      'Payment Method': o.paymentMethod || 'COD',
      'Assigned Driver': o.driverName || 'Unassigned',
      'Status': o.status || 'Pending',
      'Date Created': o.createdAt || ''
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
  };

  const totalRevenue = orders.reduce((sum, o) => sum + (Number(o.totalAmount) || 0), 0);
  const totalSacks = orders.reduce((sum, o) => sum + (Number(o.sacksOrdered) || 0), 0);

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
        <div>
          <h1 className="text-2xl font-bold text-white tracking-tight">Sales Analytics & Reports</h1>
          <p className="text-sm text-slate-400">
            Detalyadong charts ng kita, bilang ng naibentang uling, at Excel CSV download.
          </p>
        </div>
        <button
          onClick={handleExportCSV}
          className="px-4 py-2.5 bg-emerald-600 hover:bg-emerald-700 text-white rounded-xl text-xs font-bold shadow-md transition-all flex items-center gap-2"
        >
          <Download className="w-4 h-4" />
          Export to CSV (Excel)
        </button>
      </div>

      {/* Summary KPI Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
        <div className="bg-slate-800/80 border border-slate-700/80 rounded-2xl p-5 shadow-lg">
          <p className="text-xs font-medium text-slate-400 uppercase tracking-wider">Total Gross Sales</p>
          <h3 className="text-3xl font-black text-emerald-400 mt-2 font-mono">
            ₱ {totalRevenue.toLocaleString('en-US', { minimumFractionDigits: 2 })}
          </h3>
          <p className="text-xs text-slate-400 mt-1">Lahat ng nakolektang benta</p>
        </div>

        <div className="bg-slate-800/80 border border-slate-700/80 rounded-2xl p-5 shadow-lg">
          <p className="text-xs font-medium text-slate-400 uppercase tracking-wider">Total Sacks Dispatched</p>
          <h3 className="text-3xl font-black text-amber-400 mt-2">
            {totalSacks} <span className="text-base font-semibold text-slate-400">sacks</span>
          </h3>
          <p className="text-xs text-slate-400 mt-1">Kabuuang uling na naihatid</p>
        </div>

        <div className="bg-slate-800/80 border border-slate-700/80 rounded-2xl p-5 shadow-lg">
          <p className="text-xs font-medium text-slate-400 uppercase tracking-wider">Average Order Value</p>
          <h3 className="text-3xl font-black text-blue-400 mt-2 font-mono">
            ₱ {orders.length > 0 ? (totalRevenue / orders.length).toFixed(2) : '0.00'}
          </h3>
          <p className="text-xs text-slate-400 mt-1">Benta bawat customer order</p>
        </div>
      </div>

      {/* Two Analytics Charts */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        
        {/* Revenue Trend */}
        <div className="bg-slate-800/80 border border-slate-700/80 rounded-2xl p-5 shadow-lg">
          <h3 className="font-bold text-base text-white mb-4">Revenue Breakdown by Day</h3>
          <div className="h-72 w-full">
            <Bar data={revenueChartData} options={chartOptions} />
          </div>
        </div>

        {/* Sacks Volume Trend */}
        <div className="bg-slate-800/80 border border-slate-700/80 rounded-2xl p-5 shadow-lg">
          <h3 className="font-bold text-base text-white mb-4">Sacks Sold Volume by Day</h3>
          <div className="h-72 w-full">
            <Bar data={sacksChartData} options={chartOptions} />
          </div>
        </div>

      </div>
    </div>
  );
}
