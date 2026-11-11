export const DEFAULT_HUB = {
  hubName: 'Charcoal Central Warehouse',
  hubLat: 14.6042,
  hubLng: 120.9822,
  deliveryFeeMode: 'flat',
  flatDeliveryFee: 0,
  distanceBaseFee: 40,
  distancePerKm: 15,
  paymentQrImage: '',
  paymentAccountName: '',
  paymentAccountNumber: '',
};

/**
 * Haversine great-circle distance in kilometers.
 */
export function haversineDistanceKm(lat1, lng1, lat2, lng2) {
  const toRad = (deg) => (deg * Math.PI) / 180;
  const R = 6371;
  const dLat = toRad(lat2 - lat1);
  const dLng = toRad(lng2 - lng1);
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRad(lat1)) *
      Math.cos(toRad(lat2)) *
      Math.sin(dLng / 2) *
      Math.sin(dLng / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

/**
 * Fetches a driving route from public OSRM API.
 * Falls back gracefully to straight line & 30 km/h estimate if unreachable.
 */
export async function fetchOsrmRoute(fromLat, fromLng, toLat, toLng, signal) {
  try {
    const url = `https://router.project-osrm.org/route/v1/driving/${fromLng},${fromLat};${toLng},${toLat}?overview=full&geometries=geojson`;
    const res = await fetch(url, { signal });
    if (!res.ok) throw new Error('OSRM HTTP error');
    const data = await res.json();
    if (data.code === 'Ok' && data.routes && data.routes.length > 0) {
      const route = data.routes[0];
      const coords = route.geometry.coordinates.map(([lng, lat]) => [lat, lng]);
      const distanceKm = route.distance / 1000;
      const durationMin = Math.max(1, Math.round(route.duration / 60));
      return { coords, distanceKm, durationMin, isEstimated: false };
    }
  } catch (err) {
    if (err.name === 'AbortError') return null;
  }

  const dist = haversineDistanceKm(fromLat, fromLng, toLat, toLng);
  return {
    coords: [
      [fromLat, fromLng],
      [toLat, toLng],
    ],
    distanceKm: dist,
    durationMin: Math.max(1, Math.round((dist / 25) * 60)),
    isEstimated: true,
  };
}

/**
 * Searches places via OpenStreetMap Nominatim.
 */
export async function searchNominatimAddress(query) {
  const clean = String(query || '').trim();
  if (clean.length < 3) return [];
  const url = `https://nominatim.openstreetmap.org/search?format=json&limit=5&countrycodes=ph&q=${encodeURIComponent(clean)}`;
  const res = await fetch(url, {
    headers: { Accept: 'application/json' },
  });
  if (!res.ok) return [];
  const data = await res.json();
  return Array.isArray(data)
    ? data.map((item) => ({
        displayName: item.display_name,
        lat: Number(item.lat),
        lng: Number(item.lon),
      }))
    : [];
}
