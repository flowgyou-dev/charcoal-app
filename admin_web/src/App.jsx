import React, { useEffect, useState } from 'react';
import { onAuthStateChanged, signOut } from 'firebase/auth';
import { ref, get } from 'firebase/database';
import { auth, db } from './firebase';
import Login from './pages/Login';
import Dashboard from './pages/Dashboard';
import Inventory from './pages/Inventory';
import Orders from './pages/Orders';
import Drivers from './pages/Drivers';
import LiveTracking from './pages/LiveTracking';
import Analytics from './pages/Analytics';
import { LayoutDashboard, Package, ShoppingCart, Users, MapPin, BarChart3, Menu, X, Flame, LogOut } from 'lucide-react';

export default function App() {
  const [activeTab, setActiveTab] = useState('dashboard');
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const [adminUser, setAdminUser] = useState(null);
  const [authChecking, setAuthChecking] = useState(true);
  const [authError, setAuthError] = useState('');

  useEffect(() => {
    const unsub = onAuthStateChanged(auth, async (user) => {
      if (!user) {
        setAdminUser(null);
        setAuthChecking(false);
        return;
      }

      try {
        const snap = await get(ref(db, `users/${user.uid}`));
        const userData = snap.exists() ? snap.val() : null;
        if (userData && userData.role === 'admin') {
          setAdminUser({
            uid: user.uid,
            email: user.email || userData.email,
            name: userData.name || 'Business Owner',
          });
          setAuthError('');
        } else {
          await signOut(auth);
          setAdminUser(null);
          setAuthError('Access denied. Only verified Admin accounts can access this portal.');
        }
      } catch {
        await signOut(auth);
        setAdminUser(null);
        setAuthError('Unable to verify Admin permissions. Please sign in again.');
      } finally {
        setAuthChecking(false);
      }
    });

    return () => unsub();
  }, []);

  const handleLogout = async () => {
    await signOut(auth);
  };

  if (authChecking) {
    return (
      <div className="min-h-screen bg-slate-950 flex items-center justify-center text-slate-300 text-sm">
        Checking Admin session...
      </div>
    );
  }

  if (!adminUser) {
    return <Login externalError={authError} />;
  }

  const navigation = [
    { id: 'dashboard', name: 'Dashboard', icon: LayoutDashboard },
    { id: 'inventory', name: 'Uling Inventory', icon: Package },
    { id: 'orders', name: 'Orders & Dispatch', icon: ShoppingCart },
    { id: 'drivers', name: 'Manage Drivers', icon: Users },
    { id: 'map', name: 'Live Delivery Map', icon: MapPin },
    { id: 'analytics', name: 'Sales Analytics', icon: BarChart3 },
  ];

  const renderContent = () => {
    switch (activeTab) {
      case 'dashboard':
        return <Dashboard setActiveTab={setActiveTab} />;
      case 'inventory':
        return <Inventory />;
      case 'orders':
        return <Orders />;
      case 'drivers':
        return <Drivers />;
      case 'map':
        return <LiveTracking />;
      case 'analytics':
        return <Analytics />;
      default:
        return <Dashboard setActiveTab={setActiveTab} />;
    }
  };

  return (
    <div className="flex min-h-screen bg-slate-950 text-slate-100 font-sans">
      
      {/* Mobile Drawer Backdrop */}
      {mobileMenuOpen && (
        <div 
          onClick={() => setMobileMenuOpen(false)}
          className="fixed inset-0 z-40 bg-black/60 backdrop-blur-sm lg:hidden"
        />
      )}

      {/* Sidebar Navigation */}
      <aside className={`
        fixed lg:static top-0 bottom-0 left-0 z-50 w-64 bg-slate-900 border-r border-slate-800 p-4 flex flex-col justify-between transition-transform duration-200 ease-in-out
        ${mobileMenuOpen ? 'translate-x-0' : '-translate-x-full lg:translate-x-0'}
      `}>
        <div>
          {/* Logo Brand */}
          <div className="flex items-center justify-between px-3 py-3 mb-6 border-b border-slate-800">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-2xl bg-gradient-to-tr from-amber-600 to-amber-500 flex items-center justify-center text-white shadow-lg shadow-amber-600/30">
                <Flame className="w-6 h-6" />
              </div>
              <div>
                <h2 className="font-extrabold text-base tracking-tight text-white">CharCoal Hub</h2>
                <span className="text-[10px] font-semibold text-emerald-400 flex items-center gap-1">
                  <span className="w-1.5 h-1.5 rounded-full bg-emerald-400 animate-pulse"></span>
                  Vercel Live
                </span>
              </div>
            </div>
            <button 
              onClick={() => setMobileMenuOpen(false)}
              className="lg:hidden p-1 text-slate-400 hover:text-white"
            >
              <X className="w-5 h-5" />
            </button>
          </div>

          {/* Navigation Links */}
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
                    ${isActive 
                      ? 'bg-amber-600 text-white shadow-lg shadow-amber-600/20' 
                      : 'text-slate-400 hover:bg-slate-800 hover:text-white'
                    }
                  `}
                >
                  <Icon className={`w-4 h-4 ${isActive ? 'text-white' : 'text-slate-400'}`} />
                  {item.name}
                </button>
              );
            })}
          </nav>
        </div>

        {/* Footer Admin Info */}
        <div className="pt-4 border-t border-slate-800 space-y-3">
          <div className="flex items-center gap-3 px-2 py-1">
            <div className="w-9 h-9 rounded-xl bg-amber-600/20 border border-amber-600/40 text-amber-400 font-bold text-xs flex items-center justify-center shrink-0">
              {adminUser.name.slice(0, 2).toUpperCase()}
            </div>
            <div className="text-xs min-w-0">
              <p className="font-bold text-white truncate">{adminUser.name}</p>
              <p className="text-[11px] text-slate-400 truncate">{adminUser.email}</p>
            </div>
          </div>
          <button
            onClick={handleLogout}
            className="w-full flex items-center justify-center gap-2 px-3 py-2 rounded-xl bg-slate-800 hover:bg-rose-600/20 hover:text-rose-300 text-slate-300 text-xs font-semibold transition-colors"
          >
            <LogOut className="w-3.5 h-3.5" />
            Sign Out
          </button>
        </div>
      </aside>

      {/* Main Content Pane */}
      <div className="flex-1 flex flex-col min-w-0 overflow-hidden">
        
        {/* Top Navbar */}
        <header className="h-16 border-b border-slate-800 bg-slate-900/50 backdrop-blur-md px-4 sm:px-8 flex items-center justify-between">
          <button
            onClick={() => setMobileMenuOpen(true)}
            className="lg:hidden p-2 text-slate-400 hover:text-white rounded-lg hover:bg-slate-800"
          >
            <Menu className="w-5 h-5" />
          </button>

          <div className="flex items-center gap-2">
            <span className="text-xs font-medium text-slate-400">Admin Portal /</span>
            <span className="text-xs font-bold text-amber-400 capitalize">{activeTab}</span>
          </div>

          <div className="flex items-center gap-3">
            <span className="text-xs text-slate-400 hidden sm:inline">Firebase: <strong className="text-emerald-400">charcoal-2fe4b</strong></span>
          </div>
        </header>

        {/* Dynamic Page Content */}
        <main className="flex-1 p-4 sm:p-8 overflow-y-auto">
          {renderContent()}
        </main>
      </div>

    </div>
  );
}
