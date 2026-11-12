import React, { useEffect, useRef, useState } from 'react';
import { onAuthStateChanged, signOut } from 'firebase/auth';
import { ref, get, onValue } from 'firebase/database';
import { auth, db } from './firebase';
import Login from './pages/Login';
import Dashboard from './pages/Dashboard';
import Inventory from './pages/Inventory';
import Orders from './pages/Orders';
import Drivers from './pages/Drivers';
import Customers from './pages/Customers';
import LiveTracking from './pages/LiveTracking';
import Analytics from './pages/Analytics';
import Settings from './pages/Settings';
import {
  LayoutDashboard,
  Package,
  ShoppingCart,
  Users,
  UserCheck,
  MapPin,
  BarChart3,
  Settings as SettingsIcon,
  Bell,
  Menu,
  X,
  Flame,
  LogOut,
  Wifi,
  WifiOff,
  AlertTriangle,
  Receipt,
} from 'lucide-react';

export default function App() {
  const [activeTab, setActiveTab] = useState('dashboard');
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const [adminUser, setAdminUser] = useState(null);
  const [authChecking, setAuthChecking] = useState(true);
  const [authError, setAuthError] = useState('');
  const [isDbConnected, setIsDbConnected] = useState(true);
  const [alerts, setAlerts] = useState([]);
  const [showAlerts, setShowAlerts] = useState(false);
  const isSettingUpRef = useRef(false);

  useEffect(() => {
    const unsub = onAuthStateChanged(auth, async (user) => {
      if (isSettingUpRef.current) return;
      if (!user) {
        setAdminUser(null);
        setAuthChecking(false);
        return;
      }

      try {
        const snap = await get(ref(db, `users/${user.uid}`));
        if (isSettingUpRef.current) return;
        const userData = snap.exists() ? snap.val() : null;
        if (userData && userData.role === 'admin' && userData.isActive !== false) {
          setAdminUser({
            uid: user.uid,
            email: user.email || userData.email,
            name: userData.name || 'Business Owner',
          });
          setAuthError('');
        } else {
          await signOut(auth);
          setAdminUser(null);
          setAuthError('Access denied. Only active verified Admin accounts can access this portal.');
        }
      } catch {
        if (isSettingUpRef.current) return;
        await signOut(auth);
        setAdminUser(null);
        setAuthError('Unable to verify Admin permissions. Please sign in again.');
      } finally {
        setAuthChecking(false);
      }
    });

    return () => unsub();
  }, []);

  // Real RTDB connection listener + live operational alerts when logged in
  useEffect(() => {
    const connRef = ref(db, '.info/connected');
    const unsubConn = onValue(connRef, (snap) => {
      setIsDbConnected(snap.val() === true);
    });

    if (!adminUser) {
      return () => unsubConn();
    }

    let invData = null;
    let ordersData = [];

    const recomputeAlerts = () => {
      const items = [];
      if (invData && Number(invData.currentStock) <= Number(invData.lowStockLimit || 20)) {
        items.push({
          id: 'low-stock',
          tab: 'inventory',
          type: 'warning',
          title: 'Low Stock Alert',
          detail: `${invData.currentStock} ${invData.unit || 'sacks'} remaining (limit: ${invData.lowStockLimit || 20})`,
        });
      }
      const unverifiedOnline = ordersData.filter(
        (o) => o.paymentMethod === 'ONLINE_QR' && o.paymentStatus === 'Pending Verification' && o.status !== 'Cancelled'
      );
      if (unverifiedOnline.length > 0) {
        items.push({
          id: 'verify-receipts',
          tab: 'orders',
          type: 'receipt',
          title: `${unverifiedOnline.length} Online Receipt(s) to Verify`,
          detail: 'Check OCR reference number and uploaded proof image.',
        });
      }
      const pendingOrders = ordersData.filter((o) => (o.status || 'Pending') === 'Pending');
      if (pendingOrders.length > 0) {
        items.push({
          id: 'pending-orders',
          tab: 'orders',
          type: 'order',
          title: `${pendingOrders.length} Pending Order(s)`,
          detail: 'Ready for driver assignment and confirmation.',
        });
      }
      setAlerts(items);
    };

    const unsubInv = onValue(ref(db, 'inventory'), (snap) => {
      invData = snap.exists() ? snap.val() : null;
      recomputeAlerts();
    });

    const unsubOrders = onValue(ref(db, 'orders'), (snap) => {
      if (snap.exists()) {
        const val = snap.val();
        ordersData = Object.keys(val).map((k) => ({ id: k, ...val[k] }));
      } else {
        ordersData = [];
      }
      recomputeAlerts();
    });

    return () => {
      unsubConn();
      unsubInv();
      unsubOrders();
    };
  }, [adminUser]);

  const handleLogout = async () => {
    await signOut(auth);
  };

  if (authChecking) {
    return (
      <div className="min-h-screen bg-charcoal-canvas flex items-center justify-center text-charcoal-muted text-sm font-medium">
        Checking Admin session...
      </div>
    );
  }

  if (!adminUser) {
    return (
      <Login
        externalError={authError}
        isSettingUpRef={isSettingUpRef}
        onAdminInitialized={(userObj) => {
          setAuthError('');
          setAdminUser(userObj);
        }}
      />
    );
  }

  const navigation = [
    { id: 'dashboard', name: 'Dashboard', icon: LayoutDashboard },
    { id: 'inventory', name: 'Charcoal Inventory', icon: Package },
    { id: 'orders', name: 'Orders & Dispatch', icon: ShoppingCart },
    { id: 'customers', name: 'Manage Customers', icon: UserCheck },
    { id: 'drivers', name: 'Manage Drivers', icon: Users },
    { id: 'map', name: 'Live Delivery Map', icon: MapPin },
    { id: 'analytics', name: 'Sales Analytics', icon: BarChart3 },
    { id: 'settings', name: 'Shop & QR Settings', icon: SettingsIcon },
  ];

  const renderContent = () => {
    switch (activeTab) {
      case 'dashboard':
        return <Dashboard setActiveTab={setActiveTab} />;
      case 'inventory':
        return <Inventory />;
      case 'orders':
        return <Orders />;
      case 'customers':
        return <Customers />;
      case 'drivers':
        return <Drivers />;
      case 'map':
        return <LiveTracking />;
      case 'analytics':
        return <Analytics />;
      case 'settings':
        return <Settings />;
      default:
        return <Dashboard setActiveTab={setActiveTab} />;
    }
  };

  return (
    <div className="flex min-h-screen bg-charcoal-canvas text-charcoal-ink font-sans">
      {mobileMenuOpen && (
        <div
          onClick={() => setMobileMenuOpen(false)}
          className="fixed inset-0 z-40 bg-black/50 backdrop-blur-sm lg:hidden"
        />
      )}

      {/* Sidebar Navigation */}
      <aside
        className={`
        fixed lg:static top-0 bottom-0 left-0 z-50 w-64 bg-charcoal-sidebar border-r border-charcoal-hover p-4 flex flex-col justify-between transition-transform duration-200 ease-in-out text-white
        ${mobileMenuOpen ? 'translate-x-0' : '-translate-x-full lg:translate-x-0'}
      `}
      >
        <div>
          <div className="flex items-center justify-between px-3 py-3 mb-6 border-b border-charcoal-hover">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-2xl bg-charcoal-eco flex items-center justify-center text-white shadow-md">
                <Flame className="w-6 h-6" />
              </div>
              <div>
                <h2 className="font-extrabold text-base tracking-tight text-white">CharCoal Hub</h2>
                <span
                  className={`text-[11px] font-semibold flex items-center gap-1 ${
                    isDbConnected ? 'text-[#B7DFC7]' : 'text-amber-300'
                  }`}
                >
                  <span
                    className={`w-1.5 h-1.5 rounded-full ${
                      isDbConnected ? 'bg-[#4ADE80] animate-pulse' : 'bg-amber-400'
                    }`}
                  ></span>
                  {isDbConnected ? 'Live Sync' : 'Reconnecting...'}
                </span>
              </div>
            </div>
            <button
              onClick={() => setMobileMenuOpen(false)}
              className="lg:hidden p-1 text-[#CBD5D4] hover:text-white"
            >
              <X className="w-5 h-5" />
            </button>
          </div>

          <nav className="space-y-1.5">
            {navigation.map((item) => {
              const Icon = item.icon;
              const isActive = activeTab === item.id;
              return (
                <button
                  key={item.id}
                  onClick={() => {
                    setActiveTab(item.id);
                    setMobileMenuOpen(false);
                  }}
                  className={`
                    w-full flex items-center gap-3 px-3.5 py-2.5 rounded-xl text-xs font-semibold transition-all text-left
                    ${
                      isActive
                        ? 'bg-charcoal-hover text-white shadow-sm'
                        : 'text-[#CBD5D4] hover:bg-charcoal-hover/70 hover:text-white'
                    }
                  `}
                >
                  <Icon className={`w-4 h-4 ${isActive ? 'text-white' : 'text-[#CBD5D4]'}`} />
                  {item.name}
                </button>
              );
            })}
          </nav>
        </div>

        <div className="pt-4 border-t border-charcoal-hover space-y-3">
          <div className="flex items-center gap-3 px-2 py-1">
            <div className="w-9 h-9 rounded-xl bg-charcoal-hover border border-[#496968] text-white font-bold text-xs flex items-center justify-center shrink-0">
              {adminUser.name.slice(0, 2).toUpperCase()}
            </div>
            <div className="text-xs min-w-0">
              <p className="font-bold text-white truncate">{adminUser.name}</p>
              <p className="text-[11px] text-[#CBD5D4] truncate">{adminUser.email}</p>
            </div>
          </div>
          <button
            onClick={handleLogout}
            className="w-full flex items-center justify-center gap-2 px-3 py-2 rounded-xl bg-charcoal-dark hover:bg-rose-600/80 text-[#CBD5D4] hover:text-white text-xs font-semibold transition-colors"
          >
            <LogOut className="w-3.5 h-3.5" />
            Sign Out
          </button>
        </div>
      </aside>

      {/* Main Content Pane */}
      <div className="flex-1 flex flex-col min-w-0 overflow-hidden">
        <header className="h-16 border-b border-charcoal-hover bg-charcoal-header text-white px-4 sm:px-8 flex items-center justify-between">
          <button
            onClick={() => setMobileMenuOpen(true)}
            className="lg:hidden p-2 text-[#CBD5D4] hover:text-white rounded-lg hover:bg-charcoal-hover"
          >
            <Menu className="w-5 h-5" />
          </button>

          <div className="flex items-center gap-2">
            <span className="text-xs font-medium text-[#CBD5D4]">CharCoal System /</span>
            <span className="text-xs font-bold text-white capitalize">{activeTab}</span>
          </div>

          <div className="flex items-center gap-3 relative">
            <span
              className={`hidden sm:flex items-center gap-1.5 text-[11px] px-2.5 py-1 rounded-full font-semibold ${
                isDbConnected
                  ? 'bg-charcoal-hover text-[#B7DFC7]'
                  : 'bg-amber-900/50 text-amber-200'
              }`}
            >
              {isDbConnected ? <Wifi className="w-3 h-3" /> : <WifiOff className="w-3 h-3" />}
              {isDbConnected ? 'Realtime DB' : 'Offline'}
            </span>

            {/* Notification Bell */}
            <div className="relative">
              <button
                type="button"
                onClick={() => setShowAlerts(!showAlerts)}
                className="relative p-2 rounded-xl bg-charcoal-hover hover:bg-[#3e5c5b] text-white transition-colors"
                title="Live Notifications"
              >
                <Bell className="w-4 h-4" />
                {alerts.length > 0 && (
                  <span className="absolute -top-1 -right-1 w-4 h-4 rounded-full bg-rose-500 text-white text-[10px] font-bold flex items-center justify-center">
                    {alerts.length}
                  </span>
                )}
              </button>

              {showAlerts && (
                <div className="absolute right-0 mt-2 w-80 bg-white border border-charcoal-border rounded-2xl shadow-xl z-50 text-charcoal-ink overflow-hidden">
                  <div className="px-4 py-3 bg-charcoal-canvas border-b border-charcoal-border flex items-center justify-between">
                    <span className="font-bold text-xs">Operational Alerts</span>
                    <button
                      onClick={() => setShowAlerts(false)}
                      className="text-charcoal-muted hover:text-charcoal-ink text-xs"
                    >
                      Close
                    </button>
                  </div>
                  {alerts.length === 0 ? (
                    <div className="p-5 text-center text-xs text-charcoal-muted">
                      All clear! No pending receipts, low stock, or unhandled orders.
                    </div>
                  ) : (
                    <div className="divide-y divide-charcoal-border">
                      {alerts.map((alert) => (
                        <button
                          key={alert.id}
                          onClick={() => {
                            setActiveTab(alert.tab);
                            setShowAlerts(false);
                          }}
                          className="w-full text-left p-3.5 hover:bg-charcoal-canvas flex items-start gap-2.5 transition-colors"
                        >
                          {alert.type === 'warning' ? (
                            <AlertTriangle className="w-4 h-4 text-amber-600 shrink-0 mt-0.5" />
                          ) : alert.type === 'receipt' ? (
                            <Receipt className="w-4 h-4 text-charcoal-eco shrink-0 mt-0.5" />
                          ) : (
                            <ShoppingCart className="w-4 h-4 text-charcoal-header shrink-0 mt-0.5" />
                          )}
                          <div>
                            <p className="font-bold text-xs text-charcoal-ink">{alert.title}</p>
                            <p className="text-[11px] text-charcoal-muted mt-0.5">{alert.detail}</p>
                          </div>
                        </button>
                      ))}
                    </div>
                  )}
                </div>
              )}
            </div>
          </div>
        </header>

        <main className="flex-1 p-4 sm:p-8 overflow-y-auto relative">
          {renderContent()}
        </main>
      </div>
    </div>
  );
}
