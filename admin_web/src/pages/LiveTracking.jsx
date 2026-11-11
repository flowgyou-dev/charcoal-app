import React, { useEffect, useState } from 'react';
import { MapContainer, TileLayer, Marker, Popup, Polyline, useMap } from 'react-leaflet';
import L from 'leaflet';
import { ref, onValue } from 'firebase/database';
import { db } from '../firebase';
import { DEFAULT_HUB, fetchOsrmRoute } from '../utils/routing';
import { Navigation, Clock, Route } from 'lucide-react';

const hubIcon = L.divIcon({
  className: 'custom-hub-icon',
  html: `<div style="background-color: #243D3C; color: white; width: 34px; height: 34px; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-size: 16px; border: 3px solid white; box-shadow: 0 4px 6px -1px rgba(0,0,0,0.4);">🏭</div>`,
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
  html: `<div style="background-color: #3E7C59; color: white; width: 38px; height: 38px; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-size: 18px; border: 3px solid white; box-shadow: 0 10px 15px -3px rgba(0,0,0,0.5);">🛵</div>`,
  iconSize: [38, 38],
  iconAnchor: [19, 19],
});

function HubCenterUpdater({ center }) {
  const map = useMap();
  useEffect(() => {
    map.setView(center, map.getZoom());
  }, [center, map]);
  return null;
}

export default function LiveTracking() {
  const [hub, setHub] = useState(DEFAULT_HUB);
  const [driverLocations, setDriverLocations] = useState([]);
  const [activeOrders, setActiveOrders] = useState([]);
  const [routesMap, setRoutesMap] = useState({});
  const [mapError, setMapError] = useState('');

  useEffect(() => {
    const unsubSettings = onValue(
      ref(db, 'settings'),
      (snap) => {
        if (snap.exists()) {
          setHub({ ...DEFAULT_HUB, ...snap.val() });
        }
      },
      (err) => setMapError(err.message || 'Unable to load warehouse coordinates.')
    );

    const unsubLoc = onValue(
      ref(db, 'driver_locations'),
      (snap) => {
        if (snap.exists()) {
          const val = snap.val();
          setDriverLocations(
            Object.keys(val)
              .map((k) => ({ id: k, ...val[k] }))
              .filter((d) => d.isOnline !== false && Number.isFinite(Number(d.latitude)) && Number.isFinite(Number(d.longitude)))
          );
        } else {
          setDriverLocations([]);
        }
      },
      (err) => setMapError(err.message || 'Unable to listen to live driver locations.')
    );

    const unsubOrders = onValue(
      ref(db, 'orders'),
      (snap) => {
        if (snap.exists()) {
          const val = snap.val();
          const list = Object.keys(val)
            .map((k) => ({ id: k, ...val[k] }))
            .filter(
              (o) =>
                Number.isFinite(Number(o.deliveryLat)) &&
                Number.isFinite(Number(o.deliveryLng)) &&
                (o.status === 'Out for Delivery' || o.status === 'Confirmed')
            );
          setActiveOrders(list);
        } else {
          setActiveOrders([]);
        }
      },
      (err) => setMapError(err.message || 'Unable to load active orders.')
    );

    return () => {
      unsubSettings();
      unsubLoc();
      unsubOrders();
    };
  }, []);

  // Fetch real OSRM road route polylines for active orders
  useEffect(() => {
    const controller = new AbortController();

    async function computeRoutes() {
      const nextMap = {};
      for (const order of activeOrders) {
        const assignedDriver = driverLocations.find((d) => d.id === order.driverId);
        const startLat = assignedDriver ? Number(assignedDriver.latitude) : Number(hub.hubLat);
        const startLng = assignedDriver ? Number(assignedDriver.longitude) : Number(hub.hubLng);
        const endLat = Number(order.deliveryLat);
        const endLng = Number(order.deliveryLng);

        const route = await fetchOsrmRoute(startLat, startLng, endLat, endLng, controller.signal);
        if (route) {
          nextMap[order.id] = route;
        }
      }
      if (!controller.signal.aborted) {
        setRoutesMap(nextMap);
      }
    }

    if (activeOrders.length > 0) {
      computeRoutes();
    } else {
      setRoutesMap({});
    }

    return () => controller.abort();
  }, [activeOrders, driverLocations, hub.hubLat, hub.hubLng]);

  const hubCenter = [Number(hub.hubLat || DEFAULT_HUB.hubLat), Number(hub.hubLng || DEFAULT_HUB.hubLng)];

  return (
    <div className="space-y-4">
      {mapError && (
        <div className="p-3 rounded-xl bg-rose-50 border border-rose-200 text-xs text-rose-700">
          {mapError}
        </div>
      )}

      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
        <div>
          <h1 className="text-2xl font-bold text-charcoal-ink tracking-tight">Live Delivery &amp; Fleet Tracking</h1>
          <p className="text-sm text-charcoal-muted">
            Real-time driver GPS tracking, OSRM road routes, at distance/ETA para sa active deliveries.
          </p>
        </div>
        <div className="flex items-center gap-2 text-xs font-semibold">
          <span className="px-3 py-1.5 rounded-full bg-white border border-charcoal-border text-charcoal-header flex items-center gap-1.5">
            <Navigation className="w-3.5 h-3.5 text-charcoal-eco" />
            {driverLocations.length} Online Driver(s)
          </span>
          <span className="px-3 py-1.5 rounded-full bg-white border border-charcoal-border text-charcoal-ink flex items-center gap-1.5">
            <Route className="w-3.5 h-3.5 text-blue-600" />
            {activeOrders.length} Active Drop-off(s)
          </span>
        </div>
      </div>

      <div className="grid grid-cols-1 xl:grid-cols-4 gap-4">
        {/* Map */}
        <div className="xl:col-span-3 h-[580px] w-full bg-white border border-charcoal-border rounded-2xl overflow-hidden shadow-sm relative">
          <MapContainer center={hubCenter} zoom={14} scrollWheelZoom={true} className="h-full w-full">
            <TileLayer
              attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
              url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
            />
            <HubCenterUpdater center={hubCenter} />

            {/* Real Hub Pin from Settings */}
            <Marker position={hubCenter} icon={hubIcon}>
              <Popup>
                <div className="text-slate-900 font-sans p-1">
                  <p className="font-bold text-sm text-emerald-700">🏭 {hub.hubName}</p>
                  <p className="text-xs text-slate-600 mt-0.5">Configured dispatch warehouse</p>
                </div>
              </Popup>
            </Marker>

            {/* OSRM Route Polylines */}
            {activeOrders.map((order) => {
              const route = routesMap[order.id];
              if (!route?.coords) return null;
              return (
                <Polyline
                  key={`route-${order.id}`}
                  positions={route.coords}
                  pathOptions={{
                    color: order.status === 'Out for Delivery' ? '#3E7C59' : '#2563eb',
                    weight: 4,
                    opacity: 0.85,
                    dashArray: order.status === 'Confirmed' ? '6 8' : undefined,
                  }}
                />
              );
            })}

            {/* Active Delivery Destination Pins */}
            {activeOrders.map((order) => {
              const route = routesMap[order.id];
              return (
                <Marker
                  key={order.id}
                  position={[Number(order.deliveryLat), Number(order.deliveryLng)]}
                  icon={customerIcon}
                >
                  <Popup>
                    <div className="text-slate-900 font-sans p-1">
                      <p className="font-bold text-sm text-blue-700">🏠 {order.customerName}</p>
                      <p className="text-xs text-slate-600 font-semibold">{order.deliveryAddress}</p>
                      <p className="text-xs text-emerald-700 mt-1 font-bold">
                        {order.sacksOrdered} Sacks • ₱{Number(order.totalAmount || 0).toLocaleString()} ({order.paymentMethod === 'ONLINE_QR' ? 'Online QR' : 'COD'})
                      </p>
                      <p className="text-[11px] text-slate-700 mt-0.5">
                        Driver: {order.driverName || 'Assigned'} • {order.status}
                      </p>
                      {route && (
                        <p className="text-[11px] font-bold text-teal-700 mt-1">
                          Distance: {route.distanceKm.toFixed(1)} km • ETA ~{route.durationMin} min
                        </p>
                      )}
                    </div>
                  </Popup>
                </Marker>
              );
            })}

            {/* Real Online Drivers */}
            {driverLocations.map((driver) => (
              <Marker
                key={driver.id}
                position={[Number(driver.latitude), Number(driver.longitude)]}
                icon={driverIcon}
              >
                <Popup>
                  <div className="text-slate-900 font-sans p-1">
                    <p className="font-bold text-sm text-emerald-700">🛵 {driver.driverName || 'Delivery Driver'}</p>
                    <p className="text-xs text-slate-500 font-mono mt-0.5">
                      {Number(driver.latitude).toFixed(5)}, {Number(driver.longitude).toFixed(5)}
                    </p>
                    <p className="text-[10px] text-emerald-600 font-bold mt-1">
                      Updated: {driver.lastUpdated ? new Date(driver.lastUpdated).toLocaleTimeString() : 'Live'}
                    </p>
                  </div>
                </Popup>
              </Marker>
            ))}
          </MapContainer>

          {/* Legend */}
          <div className="absolute bottom-5 left-5 z-[1000] bg-white/95 backdrop-blur-md border border-charcoal-border p-3 rounded-xl shadow-lg text-xs text-charcoal-ink space-y-1.5">
            <p className="font-bold text-charcoal-header text-[11px] uppercase tracking-wider mb-1">Map Legend</p>
            <div className="flex items-center gap-2">
              <span className="w-3 h-3 rounded-full bg-charcoal-header"></span>
              <span>{hub.hubName}</span>
            </div>
            <div className="flex items-center gap-2">
              <span className="w-3 h-3 rounded-full bg-charcoal-eco"></span>
              <span>Online Driver GPS ({driverLocations.length})</span>
            </div>
            <div className="flex items-center gap-2">
              <span className="w-3 h-3 rounded-full bg-blue-600"></span>
              <span>Active Customer Pin ({activeOrders.length})</span>
            </div>
          </div>
        </div>

        {/* Active Routes Sidebar */}
        <div className="bg-white border border-charcoal-border rounded-2xl p-4 shadow-sm flex flex-col max-h-[580px]">
          <h3 className="font-bold text-xs uppercase tracking-wider text-charcoal-header pb-3 border-b border-charcoal-border">
            Active Routes &amp; ETA
          </h3>
          {activeOrders.length === 0 ? (
            <div className="flex-1 flex items-center justify-center text-center text-xs text-charcoal-muted py-12">
              Walang Confirmed o Out for Delivery orders ngayon.
            </div>
          ) : (
            <div className="flex-1 overflow-y-auto divide-y divide-charcoal-border pr-1">
              {activeOrders.map((order) => {
                const route = routesMap[order.id];
                return (
                  <div key={order.id} className="py-3 space-y-1 text-xs">
                    <div className="flex items-center justify-between">
                      <span className="font-bold text-charcoal-ink truncate">{order.customerName}</span>
                      <span
                        className={`px-2 py-0.5 rounded-full text-[10px] font-bold ${
                          order.status === 'Out for Delivery'
                            ? 'bg-teal-100 text-teal-800'
                            : 'bg-blue-100 text-blue-800'
                        }`}
                      >
                        {order.status}
                      </span>
                    </div>
                    <p className="text-[11px] text-charcoal-muted truncate">{order.deliveryAddress}</p>
                    <p className="text-[11px] font-semibold text-charcoal-header">
                      Driver: {order.driverName || 'Assigned'}
                    </p>
                    {route && (
                      <div className="flex items-center gap-3 text-[11px] font-mono font-bold text-charcoal-eco pt-0.5">
                        <span className="flex items-center gap-1">
                          <Route className="w-3 h-3" /> {route.distanceKm.toFixed(1)} km
                        </span>
                        <span className="flex items-center gap-1">
                          <Clock className="w-3 h-3" /> ~{route.durationMin} min
                        </span>
                      </div>
                    )}
                  </div>
                );
              })}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
