import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../auth/models/user_model.dart';
import '../../inventory/services/inventory_service.dart';
import '../../inventory/models/inventory_model.dart';
import '../../profile/screens/profile_screen.dart';
import '../services/order_service.dart';
import 'customer_tracking_screen.dart';
import 'customer_orders_screen.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/connection_banner.dart';

class CustomerHomeScreen extends StatefulWidget {
  final AppUser currentUser;

  const CustomerHomeScreen({super.key, required this.currentUser});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  final _inventoryService = InventoryService();
  final _orderService = OrderService();
  final _addressCtrl = TextEditingController(text: 'Sampaloc, Manila');

  int _quantity = 2;
  LatLng _pinnedLocation = const LatLng(14.6042, 120.9822);
  final MapController _mapController = MapController();
  bool _isOrdering = false;

  @override
  void dispose() {
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Naka-off ang GPS/Location ng device. I-on ito o i-tap ang mapa.')),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kailangan ng Location permission para sa My GPS, o i-tap ang mapa.')),
        );
        return;
      }

      final pos = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _pinnedLocation = LatLng(pos.latitude, pos.longitude);
      });
      _mapController.move(_pinnedLocation, 16.0);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hindi makuha ang GPS. Paki-tap sa mapa ang iyong lokasyon.')),
      );
    }
  }

  Future<void> _handlePlaceOrder(CharcoalInventory inv) async {
    if (_isOrdering) return;

    final qtyErr = Validators.validateOrderQuantity(_quantity, inv.currentStock);
    if (qtyErr != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(qtyErr)));
      return;
    }

    final addrErr = Validators.validateAddress(_addressCtrl.text);
    if (addrErr != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(addrErr)));
      return;
    }

    setState(() => _isOrdering = true);

    try {
      final order = await _orderService.placeOrder(
        customerId: widget.currentUser.uid,
        customerName: widget.currentUser.name,
        customerPhone: widget.currentUser.phone,
        deliveryAddress: _addressCtrl.text,
        deliveryLat: _pinnedLocation.latitude,
        deliveryLng: _pinnedLocation.longitude,
        sacksOrdered: _quantity,
        pricePerUnit: inv.pricePerUnit,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppTheme.emeraldGreen,
          content: Text('Order Placed Successfully! Cash on Delivery (COD)'),
        ),
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CustomerTrackingScreen(order: order),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hindi maisumite ang order: ${e.toString().replaceAll('Exception: ', '')}')),
      );
    } finally {
      if (mounted) setState(() => _isOrdering = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bumili ng Uling'),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long, color: AppTheme.primaryAmber),
            tooltip: 'My Orders',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CustomerOrdersScreen(customerId: widget.currentUser.uid),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined, color: Colors.white70),
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
        child: StreamBuilder<CharcoalInventory>(
          stream: _inventoryService.inventoryStream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text(
                    'Hindi ma-load ang stock mula sa server. Paki-check ang internet connection.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              );
            }
            final inv = snapshot.data ?? CharcoalInventory(
              itemName: 'Standard Charcoal Sack',
              currentStock: 100,
              pricePerUnit: 250.0,
              lowStockLimit: 20,
              unit: 'sack',
            );

            final total = _quantity * inv.pricePerUnit;

            return SingleChildScrollView(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFD97706), Color(0xFF92400E)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withOpacity(0.2),
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
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
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
                ),

                const SizedBox(height: 18),

                // Charcoal Product & Stepper Card
                Card(
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
                                color: Colors.amber.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(16),
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
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '₱ ${inv.pricePerUnit.toStringAsFixed(2)} bawat sako (~25kg)',
                                    style: const TextStyle(color: AppTheme.emeraldGreen, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Available Stock: ${inv.currentStock} sako',
                                    style: TextStyle(
                                      color: inv.currentStock <= inv.lowStockLimit ? Colors.redAccent : Colors.lightBlueAccent,
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
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF090D16),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppTheme.surfaceBorder),
                              ),
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove, size: 18),
                                    onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                                  ),
                                  Text(
                                    '$_quantity',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryAmber),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add, size: 18),
                                    onPressed: _quantity < inv.currentStock ? () => setState(() => _quantity++) : null,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // Leaflet Map Delivery Pin Picker
                Card(
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
                                Icon(Icons.location_on, color: Colors.redAccent, size: 20),
                                SizedBox(width: 6),
                                Text(
                                  'Delivery Location Pin',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                                ),
                              ],
                            ),
                            TextButton.icon(
                              onPressed: _getCurrentLocation,
                              icon: const Icon(Icons.my_location, size: 16, color: AppTheme.primaryAmber),
                              label: const Text('My GPS', style: TextStyle(fontSize: 12, color: AppTheme.primaryAmber)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'I-tap ang iyong lokasyon sa Leaflet map para malaman ng driver kung saan dadalhin.',
                          style: TextStyle(fontSize: 11, color: Colors.white60),
                        ),
                        const SizedBox(height: 12),

                        // Interactive Leaflet Map
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: SizedBox(
                            height: 190,
                            child: FlutterMap(
                              mapController: _mapController,
                              options: MapOptions(
                                initialCenter: _pinnedLocation,
                                initialZoom: 15.0,
                                onTap: (tapPosition, point) {
                                  setState(() => _pinnedLocation = point);
                                },
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName: 'com.coal.charcoal_app',
                                ),
                                MarkerLayer(
                                  markers: [
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
                          decoration: const InputDecoration(
                            labelText: 'Address Details / Landmarks',
                            hintText: 'Hal. Brgy. 4, Katapat ng Bakery',
                            prefixIcon: Icon(Icons.home_outlined),
                            counterText: '',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // Payment Method: Cash on Delivery (COD)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.emeraldGreen.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text('💵', style: TextStyle(fontSize: 22)),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Cash on Delivery (COD)',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Magbayad sa driver pagka-deliver ng sako ng uling.',
                                style: TextStyle(fontSize: 11, color: Colors.white60),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.check_circle, color: AppTheme.emeraldGreen, size: 22),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Order Checkout Button
                ElevatedButton(
                  onPressed: (_isOrdering || inv.currentStock <= 0) ? null : () => _handlePlaceOrder(inv),
                  child: _isOrdering
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(inv.currentStock <= 0 ? 'OUT OF STOCK' : 'PLACE ORDER (COD)'),
                            Text(
                              '₱ ${total.toStringAsFixed(2)}',
                              style: const TextStyle(fontFamily: 'monospace', fontSize: 16),
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
      ),
    );
  }
}
