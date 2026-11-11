import React, { useEffect, useState } from 'react';
import { MapContainer, TileLayer, Marker, Popup, Polyline } from 'react-leaflet';
import L from 'leaflet';
import { ref, onValue, set } from 'firebase/database';
import { db } from '../firebase';
import { Navigation, Compass, AlertCircle, Play } from 'lucide-react';

// Custom Map Markers
const hubIcon = L.divIcon({
  className: 'custom-hub-icon',
  html: `<div style="background-color: #059669; color: white; width: 34px; height: 34px; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-size: 16px; border: 3px solid white; box-shadow: 0 4px 6px -1px rgba(0,0,0,0.4);">🏭</div>`,
  iconSize: [34, 34],
  iconAnchor: [17, 17],
});

const customerIcon = L.divIcon({
  className: 'custom-customer-icon',
  html: `<div style="background-color: #2563eb; color: white; width: 34px; height: 34px; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-size: 16px; border: 3px solid white; box-shadow: 0 4px 6px -1px rgba(0,0,0,0.4);">🏠</div>`,
  iconSize: [34, 34],
  iconAnchor: [17, 17],
});

const driverIcon = L.divIcon({
  className: 'custom-driver-icon',
  html: `<div style="background-color: #d97706; color: white; width: 38px; height: 38px; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-size: 18px; border: 3px solid white; box-shadow: 0 10px 15px -3px rgba(0,0,0,0.5);">🛵</div>`,
  iconSize: [38, 38],
  iconAnchor: [19, 19],
});

export default function LiveTracking() {
  const [driverLocations, setDriverLocations] = useState([]);
  const [activeOrders, setActiveOrders] = useState([]);
  const defaultCenter = [14.6042, 120.9822]; // Manila coordinates

  useEffect(() => {
    // 1. Listen to live driver locations
    const locRef = ref(db, 'driver_locations');
    const unsubLoc = onValue(locRef, (snap) => {
      if (snap.exists()) {
        const val = snap.val();
        setDriverLocations(Object.keys(val).map(k => ({ id: k, ...val[k] })));
      } else {
        setDriverLocations([]);
      }
    });

    // 2. Listen to active orders with destination pins
    const ordersRef = ref(db, 'orders');
    const unsubOrders = onValue(ordersRef, (snap) => {
      if (snap.exists()) {
        const val = snap.val();
        const list = Object.keys(val)
          .map(k => ({ id: k, ...val[k] }))
          .filter(o => o.deliveryLat && (o.status === 'Out for Delivery' || o.status === 'Confirmed'));
        setActiveOrders(list);
      } else {
        setActiveOrders([]);
      }
    });

    return () => {
      unsubLoc();
      unsubOrders();
    };
  }, []);

  // Quick simulator for testing live GPS movement
  const handleSimulateGPS = async () => {
    const lat = 14.6042 + (Math.random() - 0.5) * 0.01;
    const lng = 120.9822 + (Math.random() - 0.5) * 0.01;
    await set(ref(db, 'driver_locations/demo_driver_1'), {
      driverName: 'Kuya Cardo (Simulated)',
      latitude: lat,
      longitude: lng,
      isOnline: true,
      lastUpdated: new Date().toISOString()
    });
  };

  return (
    <div className="space-y-4">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
        <div>
          <h1 className="text-2xl font-bold text-charcoal-ink tracking-tight">Live Delivery &amp; Fleet Tracking</h1>
          <p className="text-sm text-charcoal-muted">
            Real-time GPS tracking ng mga delivery riders gamit ang Leaflet at OpenStreetMap (Libre).
          </p>
        </div>
        <div className="flex items-center gap-2">
          <button
            onClick={handleSimulateGPS}
            className="px-3.5 py-2 bg-charcoal-header hover:bg-charcoal-dark text-white rounded-xl text-xs font-bold shadow-sm transition-all flex items-center gap-1.5"
          >
            <Play className="w-3.5 h-3.5" />
            Simulate Driver GPS Move
          </button>
        </div>
      </div>

      {/* Map Container */}
      <div className="h-[600px] w-full bg-white border border-charcoal-border rounded-2xl overflow-hidden shadow-sm relative">
        <MapContainer
          center={defaultCenter}
          zoom={14}
          scrollWheelZoom={true}
          className="h-full w-full"
        >
          <TileLayer
            attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
            url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
          />

          {/* Charcoal Hub Warehouse Marker */}
          <Marker position={[14.6000, 120.9750]} icon={hubIcon}>
            <Popup>
              <div className="text-slate-900 font-sans p-1">
                <p className="font-bold text-sm text-emerald-700">🏭 Charcoal Central Warehouse</p>
                <p className="text-xs text-slate-600 mt-0.5">Main stocking and dispatch hub.</p>
              </div>
            </Popup>
          </Marker>

          {/* Active Orders Pins */}
          {activeOrders.map(order => (
            <Marker
              key={order.id}
              position={[Number(order.deliveryLat), Number(order.deliveryLng)]}
              icon={customerIcon}
            >
              <Popup>
                <div className="text-slate-900 font-sans p-1">
                  <p className="font-bold text-sm text-blue-700">🏠 {order.customerName}</p>
                  <p className="text-xs text-slate-600 font-semibold">{order.deliveryAddress}</p>
                  <p className="text-xs text-amber-700 mt-1 font-bold">
                    Order: {order.sacksOrdered} Sacks • ₱{order.totalAmount} (COD)
                  </p>
                  <p className="text-[11px] text-purple-700 font-medium">Status: {order.status}</p>
                </div>
              </Popup>
            </Marker>
          ))}

          {/* Active Drivers Live GPS Markers */}
          {driverLocations.map(driver => (
            <Marker
              key={driver.id}
              position={[Number(driver.latitude || 14.6042), Number(driver.longitude || 120.9822)]}
              icon={driverIcon}
            >
              <Popup>
                <div className="text-slate-900 font-sans p-1">
                  <p className="font-bold text-sm text-amber-600">🛵 {driver.driverName || 'Delivery Driver'}</p>
                  <p className="text-xs text-slate-500 font-mono mt-0.5">
                    Lat: {Number(driver.latitude).toFixed(4)}, Lng: {Number(driver.longitude).toFixed(4)}
                  </p>
                  <p className="text-[10px] text-emerald-600 font-bold mt-1">
                    Live GPS Stream Active
                  </p>
                </div>
              </Popup>
            </Marker>
          ))}
        </MapContainer>

        {/* Legend Overlay */}
        <div className="absolute bottom-5 left-5 z-[1000] bg-white/95 backdrop-blur-md border border-charcoal-border p-3 rounded-xl shadow-lg text-xs text-charcoal-ink space-y-1.5 pointer-events-auto">
          <p className="font-bold text-charcoal-header text-[11px] uppercase tracking-wider mb-2">Map Legend</p>
          <div className="flex items-center gap-2">
            <span className="w-3 h-3 rounded-full bg-charcoal-eco"></span>
            <span>Charcoal Central Hub</span>
          </div>
          <div className="flex items-center gap-2">
            <span className="w-3 h-3 rounded-full bg-amber-600"></span>
            <span>Driver Real-Time GPS ({driverLocations.length} active)</span>
          </div>
          <div className="flex items-center gap-2">
            <span className="w-3 h-3 rounded-full bg-blue-600"></span>
            <span>Customer Delivery Destination</span>
          </div>
        </div>
      </div>
    </div>
  );
}
