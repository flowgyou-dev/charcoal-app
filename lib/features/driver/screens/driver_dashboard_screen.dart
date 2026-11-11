import 'package:flutter/material.dart';
import '../services/driver_service.dart';
import '../../order/models/order_model.dart';
import '../../profile/screens/profile_screen.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/connection_banner.dart';

class DriverDashboardScreen extends StatefulWidget {
  final Map<String, dynamic> driverInfo;

  const DriverDashboardScreen({super.key, required this.driverInfo});

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> {
  final _driverService = DriverService();
  bool _isGpsOn = false;
  final Set<String> _completingOrderIds = {};

  String get _driverId => widget.driverInfo['driverId']?.toString() ?? 'demo_driver_1';
  String get _driverName => widget.driverInfo['name']?.toString() ?? 'Kuya Driver';
  String get _driverEmail => widget.driverInfo['email']?.toString() ?? '';
  String get _driverPhone => widget.driverInfo['phone']?.toString() ?? '';
  String get _vehicle => widget.driverInfo['vehicle']?.toString() ?? 'Motorcycle';
  String get _plate => widget.driverInfo['plateNumber']?.toString() ?? '';

  @override
  void initState() {
    super.initState();
    _startGps();
  }

  Future<void> _startGps() async {
    final ok = await _driverService.startGpsBroadcast(_driverId, _driverName);
    if (!mounted) return;
    setState(() => _isGpsOn = ok);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hindi ma-on ang GPS. Pakibuksan ang Location services at permission.'),
        ),
      );
    }
  }

  Future<void> _toggleGps(bool val) async {
    if (val) {
      final ok = await _driverService.startGpsBroadcast(_driverId, _driverName);
      if (!mounted) return;
      setState(() => _isGpsOn = ok);
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kailangan naka-on ang GPS at Location permission para mag-broadcast.'),
          ),
        );
      }
    } else {
      await _driverService.stopGpsBroadcast(_driverId);
      if (mounted) setState(() => _isGpsOn = false);
    }
  }

  Future<void> _handleCompleteOrder(CharcoalOrder order) async {
    if (_completingOrderIds.contains(order.id)) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardWhite,
        title: const Text('Confirm Delivery & Payment', style: TextStyle(color: AppTheme.inkCharcoal, fontWeight: FontWeight.bold)),
        content: Text(
          'I-mark as Delivered ang Order ${order.id}?\n\nKolektahin ang ₱${order.totalAmount.toStringAsFixed(2)} mula kay ${order.customerName}.',
          style: const TextStyle(color: AppTheme.mutedSlate),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.mutedSlate)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emeraldGreen),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes, Delivered & Paid'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _completingOrderIds.add(order.id));
      try {
        await _driverService.completeOrder(order);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: AppTheme.emeraldGreen,
              content: Text('Order marked as Delivered & Paid! Inventory stock deducted.'),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Hindi na-update ang delivery: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _completingOrderIds.remove(order.id));
      }
    }
  }

  @override
  void dispose() {
    _driverService.stopGpsBroadcast(_driverId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Task Portal'),
        actions: [
          Row(
            children: [
              Text(
                _isGpsOn ? 'GPS ON' : 'GPS OFF',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: _isGpsOn ? const Color(0xFFB7DFC7) : Colors.white60,
                ),
              ),
              Switch(
                value: _isGpsOn,
                activeThumbColor: const Color(0xFF4ADE80),
                onChanged: _toggleGps,
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined, color: Colors.white),
            tooltip: 'Account & Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfileScreen(
                    name: _driverName,
                    email: _driverEmail,
                    phone: _driverPhone,
                    role: 'driver',
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: ConnectionBanner(
        child: Column(
        children: [
          // Driver Status Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppTheme.cardWhite,
              border: Border(bottom: BorderSide(color: AppTheme.surfaceBorder)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppTheme.headerForest.withValues(alpha: 0.1),
                  child: const Icon(Icons.local_shipping_outlined, color: AppTheme.headerForest, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _driverName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.inkCharcoal),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$_vehicle • Plate: ${_plate.isEmpty ? "N/A" : _plate}',
                        style: const TextStyle(color: AppTheme.mutedSlate, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _isGpsOn ? AppTheme.emeraldGreen.withValues(alpha: 0.12) : AppTheme.canvasMist,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _isGpsOn ? AppTheme.emeraldGreen : AppTheme.surfaceBorder),
                  ),
                  child: Text(
                    _isGpsOn ? 'Online' : 'Standby',
                    style: TextStyle(
                      color: _isGpsOn ? AppTheme.emeraldGreen : AppTheme.mutedSlate,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Assigned Orders List
          Expanded(
            child: StreamBuilder<List<CharcoalOrder>>(
              stream: _driverService.streamAssignedOrders(_driverId),
              builder: (context, snapshot) {
                final orders = snapshot.data ?? [];

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (orders.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('📦', style: TextStyle(fontSize: 48)),
                          SizedBox(height: 16),
                          Text(
                            'Walang naka-assign na delivery sa iyo ngayon.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppTheme.inkCharcoal, fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Maghintay na mag-assign ang Admin ng customer order mula sa Admin Web Dashboard.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppTheme.mutedSlate, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: orders.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    final isDelivered = order.status == 'Delivered';

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  order.id,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: AppTheme.headerForest,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isDelivered ? AppTheme.emeraldGreen.withValues(alpha: 0.12) : AppTheme.headerForest.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: isDelivered ? AppTheme.emeraldGreen : AppTheme.headerForest),
                                  ),
                                  child: Text(
                                    order.status,
                                    style: TextStyle(
                                      color: isDelivered ? AppTheme.emeraldGreen : AppTheme.headerForest,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              order.customerName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.inkCharcoal),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '📍 ${order.deliveryAddress}',
                              style: const TextStyle(color: AppTheme.mutedSlate, fontSize: 13),
                            ),
                            if (order.customerPhone.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                '📞 ${order.customerPhone}',
                                style: const TextStyle(color: AppTheme.headerForest, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ],
                            const Divider(height: 24, color: AppTheme.surfaceBorder),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Kargang Uling:', style: TextStyle(color: AppTheme.mutedSlate, fontSize: 11)),
                                    Text('${order.sacksOrdered} Sako', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.inkCharcoal, fontSize: 14)),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text('Sisingilin (COD):', style: TextStyle(color: AppTheme.mutedSlate, fontSize: 11)),
                                    Text(
                                      '₱ ${order.totalAmount.toStringAsFixed(2)}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.emeraldGreen, fontSize: 16, fontFamily: 'monospace'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            if (!isDelivered) ...[
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emeraldGreen),
                                  onPressed: _completingOrderIds.contains(order.id)
                                      ? null
                                      : () => _handleCompleteOrder(order),
                                  icon: const Icon(Icons.check_circle_outline),
                                  label: Text(
                                    _completingOrderIds.contains(order.id)
                                        ? 'UPDATING...'
                                        : 'MARK DELIVERED & PAID',
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      ),
    );
  }
}
