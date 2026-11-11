import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/models/shop_settings_model.dart';
import '../../../core/services/routing_service.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/connection_banner.dart';
import '../../auth/models/user_model.dart';
import '../../inventory/models/inventory_model.dart';
import '../../inventory/services/inventory_service.dart';
import '../../profile/screens/profile_screen.dart';
import '../services/order_service.dart';
import '../services/receipt_ocr_service.dart';
import 'customer_orders_screen.dart';
import 'customer_tracking_screen.dart';

class CustomerHomeScreen extends StatefulWidget {
  final AppUser currentUser;

  const CustomerHomeScreen({super.key, required this.currentUser});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  final _inventoryService = InventoryService();
  final _orderService = OrderService();
  final _settingsService = SettingsService();

  final _addressCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  final _refCtrl = TextEditingController();
  final MapController _mapController = MapController();

  int _quantity = 1;
  bool _isOrdering = false;
  bool _isLocating = false;
  bool _isSearchingAddress = false;
  bool _isScanningReceipt = false;
  bool _userAdjustedPin = false;
  bool _userEditedAddress = false;

  String _paymentMethod = 'COD';
  ReceiptScanResult? _scannedReceipt;

  LatLng _pinnedLocation = const LatLng(14.5995, 120.9842);
  List<NominatimPlace> _searchResults = [];
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _addressCtrl.dispose();
    _searchCtrl.dispose();
    _refCtrl.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _initLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );
      if (!mounted || _userAdjustedPin) return;

      final nextLoc = LatLng(pos.latitude, pos.longitude);
      setState(() => _pinnedLocation = nextLoc);
      _safeMoveMap(nextLoc, 15.5);
      await _reverseGeocodeIfNeeded(nextLoc);
    } catch (_) {
      // Silent fallback to default pin if GPS is unavailable on startup.
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLocating = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnack('Paki-on ang GPS ng device.');
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        _showSnack('Kailangan ng Location permission para makuha ang GPS.');
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      if (!mounted) return;
      final nextLoc = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _pinnedLocation = nextLoc;
        _userAdjustedPin = true;
      });
      _safeMoveMap(nextLoc, 16.0);
      await _reverseGeocodeIfNeeded(nextLoc, forceFill: true);
    } catch (e) {
      if (mounted) _showSnack('Hindi makuha ang GPS: $e');
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  void _safeMoveMap(LatLng center, double zoom) {
    try {
      _mapController.move(center, zoom);
    } catch (_) {
      // Ignore if map widget hasn't mounted controller yet.
    }
  }

  Future<void> _reverseGeocodeIfNeeded(LatLng point, {bool forceFill = false}) async {
    if (!forceFill && _userEditedAddress && _addressCtrl.text.trim().isNotEmpty) {
      return;
    }
    final resolved = await RoutingService.reverseGeocode(point);
    if (!mounted || resolved == null || resolved.isEmpty) return;
    if (!forceFill && _userEditedAddress && _addressCtrl.text.trim().isNotEmpty) {
      return;
    }
    setState(() {
      _addressCtrl.text = resolved;
      _userEditedAddress = false;
    });
  }

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    if (query.trim().length < 3) {
      setState(() => _searchResults = []);
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 550), () {
      _runAddressSearch(query);
    });
  }

  Future<void> _runAddressSearch(String query) async {
    if (query.trim().length < 3) return;
    setState(() => _isSearchingAddress = true);
    final results = await RoutingService.searchAddress(query);
    if (!mounted) return;
    setState(() {
      _searchResults = results;
      _isSearchingAddress = false;
    });
  }

  void _selectSearchPlace(NominatimPlace place) {
    setState(() {
      _pinnedLocation = place.location;
      _userAdjustedPin = true;
      _addressCtrl.text = place.displayName;
      _userEditedAddress = false;
      _searchResults = [];
      _searchCtrl.clear();
    });
    _safeMoveMap(place.location, 16.0);
    FocusScope.of(context).unfocus();
  }

  Future<void> _pickAndScanReceipt(ImageSource source) async {
    setState(() => _isScanningReceipt = true);
    try {
      final result = await ReceiptOcrService.pickAndScanReceipt(source);
      if (!mounted) return;
      if (result == null) return;
      setState(() {
        _scannedReceipt = result;
        _refCtrl.text = result.refNumber;
      });
      _showSnack(
        'Na-scan ang Reference No: ${result.refNumber}',
        backgroundColor: AppTheme.emeraldGreen,
      );
    } catch (e) {
      if (mounted) {
        _showSnack(e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isScanningReceipt = false);
    }
  }

  Future<void> _handlePlaceOrder(CharcoalInventory inv) async {
    final address = _addressCtrl.text.trim();
    if (address.isEmpty) {
      _showSnack('Ilagay muna ang iyong delivery address o landmark.');
      return;
    }

    if (inv.currentStock < _quantity || _quantity <= 0) {
      _showSnack('Walang sapat na stock ng uling.');
      return;
    }

    if (_paymentMethod == 'ONLINE_QR' &&
        (_scannedReceipt == null || _scannedReceipt!.refNumber.isEmpty)) {
      _showSnack('I-upload at i-scan muna ang payment receipt bago mag-order.');
      return;
    }

    setState(() => _isOrdering = true);
    try {
      final order = await _orderService.placeOrder(
        customerId: widget.currentUser.uid,
        customerName: widget.currentUser.name,
        customerPhone: widget.currentUser.phone,
        deliveryAddress: address,
        deliveryLat: _pinnedLocation.latitude,
        deliveryLng: _pinnedLocation.longitude,
        sacksOrdered: _quantity,
        paymentMethod: _paymentMethod,
        scannedReceipt: _paymentMethod == 'ONLINE_QR' ? _scannedReceipt : null,
      );

      if (!mounted) return;
      _showSnack(
        _paymentMethod == 'ONLINE_QR'
            ? 'Order Placed! Receipt ref ${order.receiptRefNumber ?? ''} submitted.'
            : 'Order Placed Successfully! Cash on Delivery (COD)',
        backgroundColor: AppTheme.emeraldGreen,
      );

      setState(() {
        _scannedReceipt = null;
        _refCtrl.clear();
        _paymentMethod = 'COD';
        _quantity = 1;
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CustomerTrackingScreen(order: order),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showSnack(
        'Hindi maisumite ang order: ${e.toString().replaceAll('Exception: ', '')}',
      );
    } finally {
      if (mounted) setState(() => _isOrdering = false);
    }
  }

  void _showSnack(String message, {Color? backgroundColor}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: backgroundColor,
        content: Text(message),
      ),
    );
  }

  Uint8List? _decodeDataUrl(String dataUrl) {
    if (dataUrl.isEmpty) return null;
    try {
      final commaIdx = dataUrl.indexOf(',');
      final rawBase64 = commaIdx >= 0 ? dataUrl.substring(commaIdx + 1) : dataUrl;
      return base64Decode(rawBase64);
    } catch (_) {
      return null;
    }
  }

  void _showQrZoomDialog(Uint8List bytes, ShopSettings settings) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppTheme.cardWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Scan to Pay via E-Wallet / Bank QR',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppTheme.inkCharcoal,
                ),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(bytes, width: 250, height: 250, fit: BoxFit.contain),
              ),
              if (settings.paymentAccountName.isNotEmpty ||
                  settings.paymentAccountNumber.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  settings.paymentAccountName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.headerForest,
                  ),
                ),
                Text(
                  settings.paymentAccountNumber,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    color: AppTheme.inkCharcoal,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bumili ng Uling'),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long, color: Colors.white),
            tooltip: 'My Orders',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      CustomerOrdersScreen(customerId: widget.currentUser.uid),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined, color: Colors.white),
            tooltip: 'Account & Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfileScreen(
                    name: widget.currentUser.name,
                    email: widget.currentUser.email,
                    phone: widget.currentUser.phone,
                    role: widget.currentUser.role,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: ConnectionBanner(
        child: StreamBuilder<ShopSettings>(
          stream: _settingsService.settingsStream,
          builder: (context, settingsSnap) {
            final settings = settingsSnap.data ?? const ShopSettings();

            return StreamBuilder<CharcoalInventory?>(
              stream: _inventoryService.inventoryStream,
              builder: (context, invSnap) {
                if (invSnap.hasError) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text(
                        'Hindi ma-load ang stock mula sa server. Paki-check ang internet connection.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.mutedSlate),
                      ),
                    ),
                  );
                }

                if (invSnap.connectionState == ConnectionState.waiting &&
                    !invSnap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final inv = invSnap.data;
                if (inv == null) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text(
                        'Walang aktibong produkto sa inventory ngayon. Maghintay hanggang mag-stock ang Admin.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.mutedSlate),
                      ),
                    ),
                  );
                }

                final safeQty = inv.currentStock <= 0
                    ? 1
                    : _quantity.clamp(1, inv.currentStock);
                final distKm = settings.distanceFromHubKm(
                  _pinnedLocation.latitude,
                  _pinnedLocation.longitude,
                );
                final deliveryFee = settings.calculateDeliveryFee(
                  destLat: _pinnedLocation.latitude,
                  destLng: _pinnedLocation.longitude,
                );
                final subtotal = safeQty * inv.pricePerUnit;
                final grandTotal = subtotal + deliveryFee;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(18.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildGreetingBanner(),
                      const SizedBox(height: 18),
                      _buildProductCard(inv, safeQty),
                      const SizedBox(height: 18),
                      _buildMapAndAddressCard(settings, distKm),
                      const SizedBox(height: 18),
                      _buildPaymentSection(settings, grandTotal),
                      const SizedBox(height: 18),
                      _buildCostBreakdownCard(
                        inv: inv,
                        qty: safeQty,
                        subtotal: subtotal,
                        deliveryFee: deliveryFee,
                        distKm: distKm,
                        grandTotal: grandTotal,
                        settings: settings,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: (_isOrdering || inv.currentStock <= 0)
                            ? null
                            : () {
                                if (_quantity != safeQty) {
                                  setState(() => _quantity = safeQty);
                                }
                                _handlePlaceOrder(inv);
                              },
                        child: _isOrdering
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    inv.currentStock <= 0
                                        ? 'OUT OF STOCK'
                                        : (_paymentMethod == 'ONLINE_QR'
                                            ? 'PLACE ORDER (ONLINE QR)'
                                            : 'PLACE ORDER (COD)'),
                                  ),
                                  Text(
                                    '₱ ${grandTotal.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildGreetingBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.headerForest, AppTheme.emeraldGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.headerForest.withValues(alpha: 0.18),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          const Text('🔥', style: TextStyle(fontSize: 36)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Maligayang araw, ${widget.currentUser.name}!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Direktang delivery ng hardwood uling sa iyong lokasyon.',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(CharcoalInventory inv, int safeQty) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppTheme.canvasMist,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.surfaceBorder),
                  ),
                  child: const Center(
                    child: Text('🪵', style: TextStyle(fontSize: 28)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        inv.itemName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppTheme.inkCharcoal,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₱ ${inv.pricePerUnit.toStringAsFixed(2)} bawat ${inv.unit}',
                        style: const TextStyle(
                          color: AppTheme.emeraldGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Available Stock: ${inv.currentStock} ${inv.unit}',
                        style: TextStyle(
                          color: inv.currentStock <= inv.lowStockLimit
                              ? Colors.red.shade700
                              : AppTheme.headerForest,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24, color: AppTheme.surfaceBorder),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Dami ng Sako:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppTheme.inkCharcoal,
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.canvasMist,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.surfaceBorder),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.remove,
                          size: 18,
                          color: AppTheme.inkCharcoal,
                        ),
                        onPressed: safeQty > 1
                            ? () => setState(() => _quantity = safeQty - 1)
                            : null,
                      ),
                      Text(
                        '$safeQty',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.headerForest,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.add,
                          size: 18,
                          color: AppTheme.inkCharcoal,
                        ),
                        onPressed: safeQty < inv.currentStock
                            ? () => setState(() => _quantity = safeQty + 1)
                            : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapAndAddressCard(ShopSettings settings, double distKm) {
    final hubLoc = LatLng(settings.hubLat, settings.hubLng);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.location_on, color: AppTheme.headerForest, size: 20),
                    SizedBox(width: 6),
                    Text(
                      'Delivery Location Pin',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppTheme.inkCharcoal,
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: _isLocating ? null : _getCurrentLocation,
                  icon: _isLocating
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(
                          Icons.my_location,
                          size: 16,
                          color: AppTheme.emeraldGreen,
                        ),
                  label: const Text(
                    'My GPS',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.emeraldGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Maghanap ng lugar o i-tap ang mapa (${distKm.toStringAsFixed(1)} km mula sa ${settings.hubName}).',
              style: const TextStyle(fontSize: 11, color: AppTheme.mutedSlate),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _searchCtrl,
              onChanged: _onSearchChanged,
              onSubmitted: _runAddressSearch,
              decoration: InputDecoration(
                hintText: 'Search barangay, street, or landmark...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _isSearchingAddress
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : (_searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () => setState(() {
                              _searchCtrl.clear();
                              _searchResults = [];
                            }),
                          )
                        : null),
              ),
            ),
            if (_searchResults.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 6),
                decoration: BoxDecoration(
                  color: AppTheme.canvasMist,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.surfaceBorder),
                ),
                constraints: const BoxConstraints(maxHeight: 160),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _searchResults.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: AppTheme.surfaceBorder),
                  itemBuilder: (_, idx) {
                    final place = _searchResults[idx];
                    return ListTile(
                      dense: true,
                      leading: const Icon(
                        Icons.place_outlined,
                        size: 18,
                        color: AppTheme.headerForest,
                      ),
                      title: Text(
                        place.displayName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                      onTap: () => _selectSearchPlace(place),
                    );
                  },
                ),
              ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                height: 190,
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _pinnedLocation,
                    initialZoom: 15.0,
                    onTap: (_, point) {
                      setState(() {
                        _pinnedLocation = point;
                        _userAdjustedPin = true;
                      });
                      _reverseGeocodeIfNeeded(point);
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.coal.charcoal_app',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: hubLoc,
                          width: 36,
                          height: 36,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppTheme.headerForest,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Center(
                              child: Text('🏭', style: TextStyle(fontSize: 16)),
                            ),
                          ),
                        ),
                        Marker(
                          point: _pinnedLocation,
                          width: 44,
                          height: 44,
                          child: const Icon(
                            Icons.location_pin,
                            size: 44,
                            color: Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _addressCtrl,
              maxLength: 200,
              onChanged: (_) => _userEditedAddress = true,
              decoration: InputDecoration(
                labelText: 'Address Details / Landmarks',
                hintText: 'Hal. Brgy. 4, Katapat ng Bakery',
                prefixIcon: const Icon(Icons.home_outlined),
                counterText: '',
                suffixIcon: IconButton(
                  tooltip: 'Fill from map pin',
                  icon: const Icon(Icons.auto_fix_high, size: 18),
                  onPressed: () =>
                      _reverseGeocodeIfNeeded(_pinnedLocation, forceFill: true),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSection(ShopSettings settings, double grandTotal) {
    final qrBytes = settings.hasPaymentQr
        ? _decodeDataUrl(settings.paymentQrImage)
        : null;
    final receiptBytes = _scannedReceipt != null
        ? _decodeDataUrl(_scannedReceipt!.imageBase64DataUrl)
        : null;
    final detectedAmt = _scannedReceipt?.detectedAmount;
    final hasAmountMismatch =
        detectedAmt != null && (detectedAmt - grandTotal).abs() > 1.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment Method',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppTheme.inkCharcoal,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildPaymentChoice(
                    value: 'COD',
                    icon: '💵',
                    title: 'Cash on Delivery',
                    subtitle: 'Magbayad pagdating',
                    enabled: true,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildPaymentChoice(
                    value: 'ONLINE_QR',
                    icon: '📱',
                    title: 'Online QR',
                    subtitle: settings.hasPaymentQr
                        ? 'Scan & Upload Receipt'
                        : 'Unavailable',
                    enabled: settings.hasPaymentQr,
                  ),
                ),
              ],
            ),
            if (_paymentMethod == 'ONLINE_QR' && settings.hasPaymentQr) ...[
              const Divider(height: 24, color: AppTheme.surfaceBorder),
              if (qrBytes != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.canvasMist,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.surfaceBorder),
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => _showQrZoomDialog(qrBytes, settings),
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.memory(
                                qrBytes,
                                width: 92,
                                height: 92,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.zoom_in,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'I-scan o magpadala sa:',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.mutedSlate,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (settings.paymentAccountName.isNotEmpty)
                              Text(
                                settings.paymentAccountName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.inkCharcoal,
                                  fontSize: 13,
                                ),
                              ),
                            if (settings.paymentAccountNumber.isNotEmpty)
                              Text(
                                settings.paymentAccountNumber,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  color: AppTheme.headerForest,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            const SizedBox(height: 4),
                            Text(
                              'Amount: ₱ ${grandTotal.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.emeraldGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              const Text(
                'Upload Payment Receipt (OCR Auto-Verify)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.inkCharcoal,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isScanningReceipt
                          ? null
                          : () => _pickAndScanReceipt(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_outlined, size: 18),
                      label: const Text('Gallery'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isScanningReceipt
                          ? null
                          : () => _pickAndScanReceipt(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt_outlined, size: 18),
                      label: const Text('Camera'),
                    ),
                  ),
                ],
              ),
              if (_isScanningReceipt) ...[
                const SizedBox(height: 12),
                const LinearProgressIndicator(),
                const SizedBox(height: 6),
                const Text(
                  'Binabasa ng ML Kit OCR ang Reference No...',
                  style: TextStyle(fontSize: 11, color: AppTheme.mutedSlate),
                ),
              ],
              if (_scannedReceipt != null) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _refCtrl,
                  readOnly: true,
                  enableInteractiveSelection: false,
                  decoration: InputDecoration(
                    labelText: 'Scanned Reference Number (OCR Locked)',
                    prefixIcon: const Icon(
                      Icons.verified,
                      color: AppTheme.emeraldGreen,
                    ),
                    suffixIcon: IconButton(
                      tooltip: 'Clear receipt',
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => setState(() {
                        _scannedReceipt = null;
                        _refCtrl.clear();
                      }),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                if (detectedAmt != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: hasAmountMismatch
                          ? Colors.orange.withValues(alpha: 0.12)
                          : AppTheme.emeraldGreen.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: hasAmountMismatch
                            ? Colors.orange
                            : AppTheme.emeraldGreen,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          hasAmountMismatch
                              ? Icons.warning_amber_rounded
                              : Icons.check_circle_outline,
                          size: 16,
                          color: hasAmountMismatch
                              ? Colors.orange.shade800
                              : AppTheme.emeraldGreen,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            hasAmountMismatch
                                ? 'OCR detected ₱${detectedAmt.toStringAsFixed(2)}, expected ₱${grandTotal.toStringAsFixed(2)}. Admin will double-check.'
                                : 'OCR detected amount matches: ₱${detectedAmt.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: hasAmountMismatch
                                  ? Colors.orange.shade900
                                  : AppTheme.headerForest,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (receiptBytes != null) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.memory(
                      receiptBytes,
                      height: 110,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentChoice({
    required String value,
    required String icon,
    required String title,
    required String subtitle,
    required bool enabled,
  }) {
    final selected = _paymentMethod == value;
    return InkWell(
      onTap: enabled ? () => setState(() => _paymentMethod = value) : null,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.emeraldGreen.withValues(alpha: 0.10)
              : (enabled ? AppTheme.canvasMist : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppTheme.emeraldGreen : AppTheme.surfaceBorder,
            width: selected ? 1.8 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(icon, style: const TextStyle(fontSize: 20)),
                if (selected)
                  const Icon(
                    Icons.check_circle,
                    color: AppTheme.emeraldGreen,
                    size: 18,
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: enabled ? AppTheme.inkCharcoal : AppTheme.mutedSlate,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 10, color: AppTheme.mutedSlate),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCostBreakdownCard({
    required CharcoalInventory inv,
    required int qty,
    required double subtotal,
    required double deliveryFee,
    required double distKm,
    required double grandTotal,
    required ShopSettings settings,
  }) {
    final feeLabel = settings.deliveryFeeMode == 'distance'
        ? 'Delivery Fee (${distKm.toStringAsFixed(1)} km)'
        : 'Delivery Fee (Flat Rate)';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _summaryRow(
              'Subtotal ($qty × ₱${inv.pricePerUnit.toStringAsFixed(2)})',
              '₱ ${subtotal.toStringAsFixed(2)}',
            ),
            const SizedBox(height: 6),
            _summaryRow(
              feeLabel,
              deliveryFee <= 0
                  ? 'FREE'
                  : '₱ ${deliveryFee.toStringAsFixed(2)}',
              valueColor: deliveryFee <= 0 ? AppTheme.emeraldGreen : null,
            ),
            const Divider(height: 18, color: AppTheme.surfaceBorder),
            _summaryRow(
              'Total Amount',
              '₱ ${grandTotal.toStringAsFixed(2)}',
              isBold: true,
              valueColor: AppTheme.headerForest,
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 14 : 12,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isBold ? AppTheme.inkCharcoal : AppTheme.mutedSlate,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: isBold ? 16 : 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: valueColor ?? AppTheme.inkCharcoal,
          ),
        ),
      ],
    );
  }
}
