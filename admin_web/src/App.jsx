import React, { useEffect, useRef, useState } from 'react';
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
    <div className="flex min-h-screen bg-charcoal-canvas text-charcoal-ink font-sans">
      
      {/* Mobile Drawer Backdrop */}
      {mobileMenuOpen && (
        <div 
          onClick={() => setMobileMenuOpen(false)}
          className="fixed inset-0 z-40 bg-black/50 backdrop-blur-sm lg:hidden"
        />
      )}

      {/* Sidebar Navigation (#293E3E) */}
      <aside className={`
        fixed lg:static top-0 bottom-0 left-0 z-50 w-64 bg-charcoal-sidebar border-r border-charcoal-hover p-4 flex flex-col justify-between transition-transform duration-200 ease-in-out text-white
        ${mobileMenuOpen ? 'translate-x-0' : '-translate-x-full lg:translate-x-0'}
      `}>
        <div>
          {/* Logo Brand */}
          <div className="flex items-center justify-between px-3 py-3 mb-6 border-b border-charcoal-hover">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-2xl bg-charcoal-eco flex items-center justify-center text-white shadow-md">
                <Flame className="w-6 h-6" />
              </div>
              <div>
                <h2 className="font-extrabold text-base tracking-tight text-white">CharCoal Hub</h2>
                <span className="text-[11px] font-semibold text-[#B7DFC7] flex items-center gap-1">
                  <span className="w-1.5 h-1.5 rounded-full bg-[#4ADE80] animate-pulse"></span>
                  Live Sync
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

        {/* Footer Admin Info */}
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
        
        {/* Top Navbar (#243D3C matching Charcoal System top bar) */}
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

          <div className="flex items-center gap-3">
            <span className="text-xs text-[#CBD5D4] hidden sm:inline">Firebase: <strong className="text-[#B7DFC7]">charcoal-2fe4b</strong></span>
          </div>
        </header>

        {/* Dynamic Page Content (#F3F5F4) */}
        <main className="flex-1 p-4 sm:p-8 overflow-y-auto relative">
          {renderContent()}
        </main>
      </div>

    </div>
  );
}
