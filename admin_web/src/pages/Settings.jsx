import React, { useEffect, useState } from 'react';
import { MapContainer, TileLayer, Marker, Popup, useMap, useMapEvents } from 'react-leaflet';
import L from 'leaflet';
import { ref, onValue, set } from 'firebase/database';
import { db } from '../firebase';
import { sanitizeText, validatePositivePrice } from '../utils/validators';
import { DEFAULT_HUB, searchNominatimAddress } from '../utils/routing';
import {
  MapPin,
  Search,
  QrCode,
  Truck,
  Save,
  Upload,
  Trash2,
  CheckCircle2,
  AlertCircle,
} from 'lucide-react';

const hubPinIcon = L.divIcon({
  className: 'custom-hub-pin',
  html: `<div style="background-color:#243D3C;color:white;width:36px;height:36px;border-radius:50%;display:flex;align-items:center;justify-content:center;font-size:17px;border:3px solid white;box-shadow:0 4px 10px rgba(0,0,0,0.4);">🏭</div>`,
  iconSize: [36, 36],
  iconAnchor: [18, 18],
});

function MapRecenter({ lat, lng }) {
  const map = useMap();
  useEffect(() => {
    if (Number.isFinite(lat) && Number.isFinite(lng)) {
      map.setView([lat, lng], map.getZoom(), { animate: true });
    }
  }, [lat, lng, map]);
  return null;
}

function HubClickPicker({ onPick }) {
  useMapEvents({
    click(e) {
      onPick(e.latlng.lat, e.latlng.lng);
    },
  });
  return null;
}

/**
 * Compresses an uploaded image file via HTML5 canvas so it fits comfortably in RTDB.
 */
function compressImageToDataUrl(file, maxDimension = 720, quality = 0.82) {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onerror = () => reject(new Error('Failed to read image file.'));
    reader.onload = () => {
      const img = new Image();
      img.onerror = () => reject(new Error('Invalid image file.'));
      img.onload = () => {
        let { width, height } = img;
        if (width > maxDimension || height > maxDimension) {
          const ratio = Math.min(maxDimension / width, maxDimension / height);
          width = Math.round(width * ratio);
          height = Math.round(height * ratio);
        }
        const canvas = document.createElement('canvas');
        canvas.width = width;
        canvas.height = height;
        const ctx = canvas.getContext('2d');
        ctx.fillStyle = '#FFFFFF';
        ctx.fillRect(0, 0, width, height);
        ctx.drawImage(img, 0, 0, width, height);
        const dataUrl = canvas.toDataURL('image/jpeg', quality);
        if (dataUrl.length > 420000) {
          reject(new Error('Compressed QR image is still too large. Please crop or use a smaller file.'));
          return;
        }
        resolve(dataUrl);
      };
      img.src = reader.result;
    };
    reader.readAsDataURL(file);
  });
}

export default function Settings() {
  const [form, setForm] = useState(DEFAULT_HUB);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  const [searchQuery, setSearchQuery] = useState('');
  const [searchResults, setSearchResults] = useState([]);
  const [searching, setSearching] = useState(false);

  useEffect(() => {
    const settingsRef = ref(db, 'settings');
    const unsub = onValue(
      settingsRef,
      (snap) => {
        if (snap.exists()) {
          setForm({ ...DEFAULT_HUB, ...snap.val() });
        } else {
          setForm(DEFAULT_HUB);
        }
        setLoading(false);
      },
      (err) => {
        setError(err.message || 'Unable to load settings.');
        setLoading(false);
      }
    );
    return () => unsub();
  }, []);

  const handleSearchAddress = async (e) => {
    e.preventDefault();
    if (!searchQuery.trim()) return;
    setSearching(true);
    setError('');
    try {
      const results = await searchNominatimAddress(searchQuery);
      setSearchResults(results);
      if (results.length === 0) {
        setError('No matching address found on OpenStreetMap. Try clicking directly on the map.');
      }
    } catch {
      setError('Address search failed. Please click directly on the map.');
    } finally {
      setSearching(false);
    }
  };

  const handleQrFileChange = async (e) => {
    const file = e.target.files?.[0];
    if (!file) return;
    setError('');
    setSuccess('');

    const allowed = ['image/png', 'image/jpeg', 'image/jpg', 'image/webp'];
    if (!allowed.includes(file.type)) {
      setError('Please upload a PNG, JPG, or WEBP QR code image.');
      return;
    }
    if (file.size > 5 * 1024 * 1024) {
      setError('Original image must be under 5 MB.');
      return;
    }

    try {
      const dataUrl = await compressImageToDataUrl(file);
      setForm((prev) => ({ ...prev, paymentQrImage: dataUrl }));
    } catch (err) {
      setError(err.message || 'Could not process QR image.');
    }
  };

  const handleSave = async (e) => {
    e.preventDefault();
    if (saving) return;
    setError('');
    setSuccess('');

    const cleanHubName = sanitizeText(form.hubName);
    if (cleanHubName.length < 2 || cleanHubName.length > 100) {
      return setError('Warehouse / Hub name must be 2–100 characters.');
    }

    const flatErr = validatePositivePrice(form.flatDeliveryFee, 0, 10000, 'Flat delivery fee');
    if (flatErr) return setError(flatErr);

    const baseErr = validatePositivePrice(form.distanceBaseFee, 0, 10000, 'Distance base fee');
    if (baseErr) return setError(baseErr);

    const perKmErr = validatePositivePrice(form.distancePerKm, 0, 1000, 'Rate per km');
    if (perKmErr) return setError(perKmErr);

    setSaving(true);
    try {
      await set(ref(db, 'settings'), {
        hubName: cleanHubName,
        hubLat: Number(form.hubLat),
        hubLng: Number(form.hubLng),
        deliveryFeeMode: form.deliveryFeeMode === 'distance' ? 'distance' : 'flat',
        flatDeliveryFee: Math.round(Number(form.flatDeliveryFee)),
        distanceBaseFee: Math.round(Number(form.distanceBaseFee)),
        distancePerKm: Math.round(Number(form.distancePerKm)),
        paymentQrImage: form.paymentQrImage || '',
        paymentAccountName: sanitizeText(form.paymentAccountName || '').slice(0, 80),
        paymentAccountNumber: sanitizeText(form.paymentAccountNumber || '').slice(0, 40),
        updatedAt: new Date().toISOString(),
      });
      setSuccess('Settings saved! Live checkout, delivery fees, QR code, at map hub ay updated na.');
    } catch (err) {
      setError(err.message || 'Failed to save settings.');
    } finally {
      setSaving(false);
    }
  };

  if (loading) {
    return (
      <div className="py-16 text-center text-charcoal-muted text-sm">
        Loading shop &amp; delivery settings...
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-charcoal-ink tracking-tight">Shop, Delivery &amp; Payment Settings</h1>
        <p className="text-sm text-charcoal-muted">
          I-set ang totoong Warehouse Pin sa mapa, Delivery Fee rules, at Online Payment QR Code para sa customer mobile app.
        </p>
      </div>

      {error && (
        <div className="p-3.5 rounded-xl bg-rose-50 border border-rose-200 flex items-start gap-2.5 text-xs text-rose-700">
          <AlertCircle className="w-4 h-4 text-rose-600 shrink-0 mt-0.5" />
          <span>{error}</span>
        </div>
      )}

      {success && (
        <div className="p-3.5 rounded-xl bg-[#E8F3EC] border border-[#B7DFC7] flex items-start gap-2.5 text-xs text-charcoal-eco font-semibold">
          <CheckCircle2 className="w-4 h-4 shrink-0 mt-0.5" />
          <span>{success}</span>
        </div>
      )}

      <form onSubmit={handleSave} className="space-y-6">
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          {/* Card 1: Warehouse / Hub Pin */}
          <div className="bg-white border border-charcoal-border rounded-2xl p-5 shadow-sm space-y-4">
            <div className="flex items-center gap-2 border-b border-charcoal-border pb-3">
              <MapPin className="w-5 h-5 text-charcoal-header" />
              <div>
                <h2 className="font-bold text-sm text-charcoal-ink">Warehouse / Hub Location</h2>
                <p className="text-[11px] text-charcoal-muted">I-click ang mapa o mag-search para ituro ang dispatch hub.</p>
              </div>
            </div>

            <div>
              <label className="block text-xs font-semibold text-charcoal-ink mb-1">Hub Display Name</label>
              <input
                type="text"
                maxLength={100}
                value={form.hubName}
                onChange={(e) => setForm({ ...form, hubName: e.target.value })}
                className="w-full bg-charcoal-canvas border border-charcoal-border rounded-xl px-3.5 py-2 text-xs text-charcoal-ink focus:outline-none focus:border-charcoal-header"
                required
              />
            </div>

            <div className="flex gap-2">
              <div className="relative flex-1">
                <Search className="w-3.5 h-3.5 text-charcoal-muted absolute left-3 top-2.5" />
                <input
                  type="text"
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  onKeyDown={(e) => {
                    if (e.key === 'Enter') {
                      e.preventDefault();
                      handleSearchAddress(e);
                    }
                  }}
                  placeholder="Search street, barangay, or city..."
                  className="w-full bg-charcoal-canvas border border-charcoal-border rounded-xl pl-8 pr-3 py-2 text-xs text-charcoal-ink focus:outline-none focus:border-charcoal-header"
                />
              </div>
              <button
                type="button"
                onClick={handleSearchAddress}
                disabled={searching}
                className="px-3.5 py-2 bg-charcoal-header hover:bg-charcoal-dark text-white rounded-xl text-xs font-semibold disabled:opacity-60"
              >
                {searching ? '...' : 'Search'}
              </button>
            </div>

            {searchResults.length > 0 && (
              <div className="bg-charcoal-canvas border border-charcoal-border rounded-xl divide-y divide-charcoal-border max-h-36 overflow-y-auto text-xs">
                {searchResults.map((res, idx) => (
                  <button
                    key={idx}
                    type="button"
                    onClick={() => {
                      setForm((prev) => ({ ...prev, hubLat: res.lat, hubLng: res.lng }));
                      setSearchResults([]);
                    }}
                    className="w-full text-left px-3 py-2 hover:bg-white transition-colors truncate text-charcoal-ink"
                  >
                    {res.displayName}
                  </button>
                ))}
              </div>
            )}

            <div className="h-64 rounded-xl overflow-hidden border border-charcoal-border">
              <MapContainer
                center={[Number(form.hubLat), Number(form.hubLng)]}
                zoom={14}
                className="h-full w-full"
              >
                <TileLayer
                  attribution="&copy; OpenStreetMap"
                  url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
                />
                <MapRecenter lat={Number(form.hubLat)} lng={Number(form.hubLng)} />
                <HubClickPicker
                  onPick={(lat, lng) =>
                    setForm((prev) => ({
                      ...prev,
                      hubLat: Number(lat.toFixed(6)),
                      hubLng: Number(lng.toFixed(6)),
                    }))
                  }
                />
                <Marker position={[Number(form.hubLat), Number(form.hubLng)]} icon={hubPinIcon}>
                  <Popup>{form.hubName}</Popup>
                </Marker>
              </MapContainer>
            </div>

            <div className="grid grid-cols-2 gap-3 text-xs">
              <div>
                <label className="block text-charcoal-muted mb-1">Latitude</label>
                <input
                  type="text"
                  readOnly
                  value={Number(form.hubLat).toFixed(6)}
                  className="w-full bg-charcoal-canvas border border-charcoal-border rounded-lg px-3 py-1.5 font-mono text-charcoal-ink"
                />
              </div>
              <div>
                <label className="block text-charcoal-muted mb-1">Longitude</label>
                <input
                  type="text"
                  readOnly
                  value={Number(form.hubLng).toFixed(6)}
                  className="w-full bg-charcoal-canvas border border-charcoal-border rounded-lg px-3 py-1.5 font-mono text-charcoal-ink"
                />
              </div>
            </div>
          </div>

          {/* Right Column: Delivery Fees + Online QR Code */}
          <div className="space-y-6">
            {/* Card 2: Delivery Fee Config */}
            <div className="bg-white border border-charcoal-border rounded-2xl p-5 shadow-sm space-y-4">
              <div className="flex items-center gap-2 border-b border-charcoal-border pb-3">
                <Truck className="w-5 h-5 text-charcoal-eco" />
                <div>
                  <h2 className="font-bold text-sm text-charcoal-ink">Delivery Fee Computation</h2>
                  <p className="text-[11px] text-charcoal-muted">Piliin kung Free/Flat rate o Distance-based (₱/km) sa checkout.</p>
                </div>
              </div>

              <div className="grid grid-cols-2 gap-3 text-xs">
                <button
                  type="button"
                  onClick={() => setForm({ ...form, deliveryFeeMode: 'flat' })}
                  className={`p-3 rounded-xl border text-left transition-all ${
                    form.deliveryFeeMode === 'flat'
                      ? 'bg-[#E8F3EC] border-charcoal-eco text-charcoal-ink font-bold'
                      : 'bg-charcoal-canvas border-charcoal-border text-charcoal-muted'
                  }`}
                >
                  <div>Flat / Free Rate</div>
                  <div className="text-[11px] font-normal mt-0.5">Parehong fee sa lahat ng lugar</div>
                </button>
                <button
                  type="button"
                  onClick={() => setForm({ ...form, deliveryFeeMode: 'distance' })}
                  className={`p-3 rounded-xl border text-left transition-all ${
                    form.deliveryFeeMode === 'distance'
                      ? 'bg-[#E8F3EC] border-charcoal-eco text-charcoal-ink font-bold'
                      : 'bg-charcoal-canvas border-charcoal-border text-charcoal-muted'
                  }`}
                >
                  <div>Distance-Based (₱/km)</div>
                  <div className="text-[11px] font-normal mt-0.5">Base fee + per km mula Hub</div>
                </button>
              </div>

              {form.deliveryFeeMode === 'flat' ? (
                <div className="text-xs">
                  <label className="block font-semibold text-charcoal-ink mb-1">
                    Flat Delivery Fee (₱) — ilagay ang <span className="font-mono">0</span> para Free Delivery
                  </label>
                  <input
                    type="number"
                    min="0"
                    max="10000"
                    step="1"
                    value={form.flatDeliveryFee}
                    onChange={(e) => setForm({ ...form, flatDeliveryFee: e.target.value })}
                    className="w-full bg-charcoal-canvas border border-charcoal-border rounded-xl px-3.5 py-2 font-mono text-charcoal-ink focus:outline-none focus:border-charcoal-header"
                  />
                </div>
              ) : (
                <div className="grid grid-cols-2 gap-3 text-xs">
                  <div>
                    <label className="block font-semibold text-charcoal-ink mb-1">Base Fee (₱)</label>
                    <input
                      type="number"
                      min="0"
                      max="10000"
                      step="1"
                      value={form.distanceBaseFee}
                      onChange={(e) => setForm({ ...form, distanceBaseFee: e.target.value })}
                      className="w-full bg-charcoal-canvas border border-charcoal-border rounded-xl px-3.5 py-2 font-mono text-charcoal-ink focus:outline-none focus:border-charcoal-header"
                    />
                  </div>
                  <div>
                    <label className="block font-semibold text-charcoal-ink mb-1">Additional Rate per km (₱)</label>
                    <input
                      type="number"
                      min="0"
                      max="1000"
                      step="1"
                      value={form.distancePerKm}
                      onChange={(e) => setForm({ ...form, distancePerKm: e.target.value })}
                      className="w-full bg-charcoal-canvas border border-charcoal-border rounded-xl px-3.5 py-2 font-mono text-charcoal-ink focus:outline-none focus:border-charcoal-header"
                    />
                  </div>
                </div>
              )}
            </div>

            {/* Card 3: Online Payment QR Code Upload */}
            <div className="bg-white border border-charcoal-border rounded-2xl p-5 shadow-sm space-y-4">
              <div className="flex items-center gap-2 border-b border-charcoal-border pb-3">
                <QrCode className="w-5 h-5 text-charcoal-header" />
                <div>
                  <h2 className="font-bold text-sm text-charcoal-ink">Online Payment QR Code (GCash / Maya / QRPH)</h2>
                  <p className="text-[11px] text-charcoal-muted">Makikita at mai-scan ito ng customer kapag pinili ang Online Payment.</p>
                </div>
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 text-xs">
                <div>
                  <label className="block font-semibold text-charcoal-ink mb-1">Account Label / Name</label>
                  <input
                    type="text"
                    maxLength={80}
                    value={form.paymentAccountName || ''}
                    onChange={(e) => setForm({ ...form, paymentAccountName: e.target.value })}
                    placeholder="Hal. GCash - Charcoal Express"
                    className="w-full bg-charcoal-canvas border border-charcoal-border rounded-xl px-3.5 py-2 text-charcoal-ink focus:outline-none focus:border-charcoal-header"
                  />
                </div>
                <div>
                  <label className="block font-semibold text-charcoal-ink mb-1">Account / Wallet Number</label>
                  <input
                    type="text"
                    maxLength={40}
                    value={form.paymentAccountNumber || ''}
                    onChange={(e) => setForm({ ...form, paymentAccountNumber: e.target.value })}
                    placeholder="Hal. 0917 123 4567"
                    className="w-full bg-charcoal-canvas border border-charcoal-border rounded-xl px-3.5 py-2 font-mono text-charcoal-ink focus:outline-none focus:border-charcoal-header"
                  />
                </div>
              </div>

              <div className="flex flex-col sm:flex-row items-center gap-4">
                {form.paymentQrImage ? (
                  <div className="relative group shrink-0">
                    <img
                      src={form.paymentQrImage}
                      alt="Payment QR Preview"
                      className="w-36 h-36 object-contain rounded-xl border border-charcoal-border bg-white p-1"
                    />
                    <button
                      type="button"
                      onClick={() => setForm({ ...form, paymentQrImage: '' })}
                      className="mt-2 w-full flex items-center justify-center gap-1 py-1 text-[11px] text-rose-600 hover:bg-rose-50 rounded-lg border border-rose-200 font-semibold"
                    >
                      <Trash2 className="w-3 h-3" /> Remove QR
                    </button>
                  </div>
                ) : (
                  <div className="w-36 h-36 rounded-xl border-2 border-dashed border-charcoal-border bg-charcoal-canvas flex flex-col items-center justify-center text-charcoal-muted text-[11px] text-center p-2 shrink-0">
                    <QrCode className="w-7 h-7 mb-1 opacity-50" />
                    No QR Uploaded
                  </div>
                )}

                <div className="flex-1 space-y-2 text-xs">
                  <label className="inline-flex items-center gap-2 px-4 py-2.5 bg-charcoal-header hover:bg-charcoal-dark text-white rounded-xl font-bold cursor-pointer shadow-sm">
                    <Upload className="w-4 h-4" />
                    Upload QR Code Image
                    <input
                      type="file"
                      accept="image/png,image/jpeg,image/webp"
                      onChange={handleQrFileChange}
                      className="hidden"
                    />
                  </label>
                  <p className="text-[11px] text-charcoal-muted">
                    Awtomatikong iko-compress ang QR picture para bumukas nang mabilis sa mobile app at hindi kailanganin ng paid storage.
                  </p>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div className="flex justify-end">
          <button
            type="submit"
            disabled={saving}
            className="px-6 py-3 bg-charcoal-eco hover:bg-[#2F6346] disabled:opacity-60 text-white rounded-xl text-xs font-bold shadow-md flex items-center gap-2 uppercase tracking-wide"
          >
            <Save className="w-4 h-4" />
            {saving ? 'Saving Settings...' : 'Save All Settings'}
          </button>
        </div>
      </form>
    </div>
  );
}
