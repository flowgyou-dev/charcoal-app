import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/models/shop_settings_model.dart';
import '../../../core/services/routing_service.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/connection_banner.dart';
import '../../order/models/order_model.dart';
import '../../profile/screens/profile_screen.dart';
import '../models/driver_model.dart';
import '../services/driver_service.dart';

class DriverDashboardScreen extends StatefulWidget {
  final DriverProfile driverProfile;

  const DriverDashboardScreen({super.key, required this.driverProfile});

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> {
  final _driverService = DriverService();
  final _settingsService = SettingsService();

  bool _isGpsOn = false;
  int _selectedTab = 0; // 0 = Active, 1 = Completed History
  final Set<String> _busyOrderIds = {};
  final Set<String> _knownActiveOrderIds = {};
  bool _hasSeededAssignments = false;
  int _newAssignmentCount = 0;

  String get _driverId => widget.driverProfile.driverId;
  String get _driverName => widget.driverProfile.name;
  String get _driverPhone => widget.driverProfile.phone;
  String get _driverEmail => widget.driverProfile.email;
  String get _vehicle => widget.driverProfile.vehicle;
  String get _plate => widget.driverProfile.plateNumber;

  @override
  void initState() {
    super.initState();
    _isGpsOn = widget.driverProfile.isOnline;
  }

  @override
  void dispose() {
    _driverService.stopGpsBroadcast(_driverId);
    super.dispose();
  }

  void _trackNewAssignments(List<CharcoalOrder> activeOrders) {
    final activeIds = activeOrders.map((o) => o.id).toSet();
    if (!_hasSeededAssignments) {
      _knownActiveOrderIds.addAll(activeIds);
      _hasSeededAssignments = true;
      return;
    }

    final newlyAdded = activeIds.difference(_knownActiveOrderIds);
    if (newlyAdded.isNotEmpty) {
      _knownActiveOrderIds.addAll(newlyAdded);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _newAssignmentCount += newlyAdded.length);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.headerForest,
            content: Text(
              'New delivery assignment: ${newlyAdded.join(', ')}',
            ),
          ),
        );
      });
    } else {
      _knownActiveOrderIds
        ..clear()
        ..addAll(activeIds);
    }
  }

  Future<void> _toggleGps(bool val) async {
    try {
      if (val) {
        final ok = await _driverService.startGpsBroadcast(_driverId, _driverName);
        if (!mounted) return;
        setState(() => _isGpsOn = ok);
        if (!ok) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'GPS and Location permission are required to broadcast live location.',
              ),
            ),
          );
        }
      } else {
        await _driverService.stopGpsBroadcast(_driverId);
        if (mounted) setState(() => _isGpsOn = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isGpsOn = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          content: Text('Unable to update GPS status: $e'),
        ),
      );
    }
  }

  Future<void> _handleStartDelivery(CharcoalOrder order) async {
    if (_busyOrderIds.contains(order.id)) return;
    setState(() => _busyOrderIds.add(order.id));
    try {
      await _driverService.startDelivery(order);
      if (!mounted) return;
      if (!_isGpsOn) {
        await _toggleGps(true);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.emeraldGreen,
          content: Text('${order.id} is now Out for Delivery!'),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Unable to start delivery: ${e.toString().replaceAll('Exception: ', '')}',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busyOrderIds.remove(order.id));
    }
  }

  Future<void> _handleCompleteOrder(CharcoalOrder order) async {
    if (_busyOrderIds.contains(order.id)) return;

    final isCod = order.paymentMethod != 'ONLINE_QR';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardWhite,
        title: const Text(
          'Confirm Delivery & Payment',
          style: TextStyle(
            color: AppTheme.inkCharcoal,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          isCod
              ? 'Mark Order ${order.id} as Delivered?\n\nEnsure ₱${order.totalAmount.toStringAsFixed(2)} (COD) is collected from ${order.customerName}.'
              : 'Mark Order ${order.id} as Delivered?\n\nPaid via Online QR (${order.paymentStatus}).',
          style: const TextStyle(color: AppTheme.mutedSlate),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppTheme.mutedSlate),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.emeraldGreen,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(isCod ? 'Yes, Delivered & Paid' : 'Yes, Delivered'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _busyOrderIds.add(order.id));
    try {
      await _driverService.completeOrder(order);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppTheme.emeraldGreen,
            content: Text('Order marked as Delivered & Paid!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to update delivery: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busyOrderIds.remove(order.id));
    }
  }

  Future<void> _launchExternalMaps(CharcoalOrder order) async {
    final lat = order.deliveryLat;
    final lng = order.deliveryLng;
    final candidates = [
      Uri.parse('google.navigation:q=$lat,$lng&mode=d'),
      Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng'),
      Uri.parse('geo:$lat,$lng?q=$lat,$lng'),
    ];

    for (final uri in candidates) {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No navigation app available.')),
      );
    }
  }

  Future<void> _callCustomer(String phone) async {
    final cleaned = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleaned.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: cleaned);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to dial $phone')),
      );
    }
  }

  Future<void> _openInAppRouteModal(
    CharcoalOrder order,
    ShopSettings settings,
  ) async {
    LatLng origin = LatLng(settings.hubLat, settings.hubLng);
    try {
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) {
        origin = LatLng(last.latitude, last.longitude);
      }
    } catch (_) {}

    final dest = LatLng(order.deliveryLat, order.deliveryLng);

    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => _DriverRouteModal(
        order: order,
        origin: origin,
        destination: dest,
        onNavigateExternal: () => _launchExternalMaps(order),
      ),
    );
  }

  bool _isSameDay(String? iso) {
    if (iso == null || iso.isEmpty) return false;
    final parsed = DateTime.tryParse(iso)?.toLocal();
    if (parsed == null) return false;
    final now = DateTime.now();
    return parsed.year == now.year &&
        parsed.month == now.month &&
        parsed.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Driver Task Portal',
          overflow: TextOverflow.ellipsis,
        ),
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
            icon: const Icon(
              Icons.account_circle_outlined,
              color: Colors.white,
            ),
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
        child: StreamBuilder<ShopSettings>(
          stream: _settingsService.settingsStream,
          builder: (context, settingsSnap) {
            final settings = settingsSnap.data ?? const ShopSettings();

            return StreamBuilder<List<CharcoalOrder>>(
              stream: _driverService.streamAssignedOrders(_driverId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text(
                        'Unable to load delivery assignments. Please check your internet connection.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.mutedSlate),
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allOrders = snapshot.data ?? [];
                final activeOrders = allOrders
                    .where((o) =>
                        o.status != 'Delivered' && o.status != 'Cancelled')
                    .toList();
                final completedOrders = allOrders
                    .where((o) => o.status == 'Delivered')
                    .toList();

                _trackNewAssignments(activeOrders);

                final todayDelivered = completedOrders.where((o) =>
                    _isSameDay(o.deliveredAt ?? o.createdAt));
                final codToday = todayDelivered
                    .where((o) => o.paymentMethod != 'ONLINE_QR')
                    .fold<double>(0.0, (sum, o) => sum + o.totalAmount);

                final shownOrders =
                    _selectedTab == 0 ? activeOrders : completedOrders;

                return Column(
                  children: [
                    _buildDriverBanner(codToday, todayDelivered.length),
                    if (_newAssignmentCount > 0)
                      Container(
                        width: double.infinity,
                        color: AppTheme.primaryAmber.withValues(alpha: 0.16),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.notifications_active,
                              size: 16,
                              color: AppTheme.headerForest,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '$_newAssignmentCount new order assignment(s) received!',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.inkCharcoal,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () =>
                                  setState(() => _newAssignmentCount = 0),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      ),
                    _buildTabs(activeOrders.length, completedOrders.length),
                    Expanded(
                      child: shownOrders.isEmpty
                          ? _buildEmptyState(_selectedTab == 0)
                          : ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: shownOrders.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 14),
                              itemBuilder: (context, index) => _buildOrderCard(
                                shownOrders[index],
                                settings,
                              ),
                            ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildDriverBanner(double codToday, int deliveredTodayCount) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppTheme.cardWhite,
        border: Border(bottom: BorderSide(color: AppTheme.surfaceBorder)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppTheme.headerForest.withValues(alpha: 0.1),
                child: const Icon(
                  Icons.local_shipping_outlined,
                  color: AppTheme.headerForest,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _driverName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppTheme.inkCharcoal,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$_vehicle • Plate: ${_plate.isEmpty ? "N/A" : _plate}',
                      style: const TextStyle(
                        color: AppTheme.mutedSlate,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _isGpsOn
                      ? AppTheme.emeraldGreen.withValues(alpha: 0.12)
                      : AppTheme.canvasMist,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isGpsOn
                        ? AppTheme.emeraldGreen
                        : AppTheme.surfaceBorder,
                  ),
                ),
                child: Text(
                  _isGpsOn ? 'Online' : 'Standby',
                  style: TextStyle(
                    color:
                        _isGpsOn ? AppTheme.emeraldGreen : AppTheme.mutedSlate,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.canvasMist,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.surfaceBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'COD Cash Collected Today',
                      style: TextStyle(fontSize: 10, color: AppTheme.mutedSlate),
                    ),
                    Text(
                      '₱ ${codToday.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppTheme.emeraldGreen,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Completed Today',
                      style: TextStyle(fontSize: 10, color: AppTheme.mutedSlate),
                    ),
                    Text(
                      '$deliveredTodayCount Deliveries',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppTheme.headerForest,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs(int activeCount, int completedCount) {
    return Container(
      color: AppTheme.cardWhite,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: Row(
        children: [
          Expanded(
            child: _tabButton(
              index: 0,
              label: 'Active ($activeCount)',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _tabButton(
              index: 1,
              label: 'Completed ($completedCount)',
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabButton({required int index, required String label}) {
    final selected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppTheme.headerForest : AppTheme.canvasMist,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppTheme.headerForest : AppTheme.surfaceBorder,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: selected ? Colors.white : AppTheme.mutedSlate,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isActiveTab) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(isActiveTab ? '📦' : '✅', style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              isActiveTab
                  ? 'No active deliveries assigned to you right now.'
                  : 'No completed deliveries yet.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.inkCharcoal,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isActiveTab
                  ? 'Wait for the Admin to assign a customer order from the Admin Web Dashboard.'
                  : 'Completed deliveries will appear here.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.mutedSlate, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(CharcoalOrder order, ShopSettings settings) {
    final isDelivered = order.status == 'Delivered';
    final isOutForDelivery = order.status == 'Out for Delivery';
    final isOnline = order.paymentMethod == 'ONLINE_QR';
    final isBusy = _busyOrderIds.contains(order.id);

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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: isDelivered
                        ? AppTheme.emeraldGreen.withValues(alpha: 0.12)
                        : (isOutForDelivery
                            ? AppTheme.primaryAmber.withValues(alpha: 0.14)
                            : AppTheme.headerForest.withValues(alpha: 0.1)),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDelivered
                          ? AppTheme.emeraldGreen
                          : (isOutForDelivery
                              ? AppTheme.primaryAmber
                              : AppTheme.headerForest),
                    ),
                  ),
                  child: Text(
                    order.status,
                    style: TextStyle(
                      color: isDelivered
                          ? AppTheme.emeraldGreen
                          : (isOutForDelivery
                              ? AppTheme.primaryAmber
                              : AppTheme.headerForest),
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
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppTheme.inkCharcoal,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '📍 ${order.deliveryAddress}',
              style: const TextStyle(color: AppTheme.mutedSlate, fontSize: 13),
            ),
            if (order.customerPhone.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                '📞 ${order.customerPhone}',
                style: const TextStyle(
                  color: AppTheme.headerForest,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
            const Divider(height: 22, color: AppTheme.surfaceBorder),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Cargo:',
                      style: TextStyle(color: AppTheme.mutedSlate, fontSize: 11),
                    ),
                    Text(
                      '${order.sacksOrdered} ${order.sacksOrdered == 1 ? 'Sack' : 'Sacks'}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.inkCharcoal,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      isOnline
                          ? 'Online QR (${order.paymentStatus}):'
                          : 'Collect (COD):',
                      style: const TextStyle(
                        color: AppTheme.mutedSlate,
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      '₱ ${order.totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.emeraldGreen,
                        fontSize: 16,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (!isDelivered) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _openInAppRouteModal(order, settings),
                      icon: const Icon(Icons.map_outlined, size: 16),
                      label: const Text('Route', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _launchExternalMaps(order),
                      icon: const Icon(Icons.navigation_outlined, size: 16),
                      label: const Text('Navigate', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  if (order.customerPhone.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      tooltip: 'Call Customer',
                      onPressed: () => _callCustomer(order.customerPhone),
                      icon: const Icon(Icons.call, size: 18),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              if (!isOutForDelivery)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.headerForest,
                    ),
                    onPressed: isBusy ? null : () => _handleStartDelivery(order),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text(isBusy ? 'STARTING...' : 'START DELIVERY'),
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.emeraldGreen,
                    ),
                    onPressed:
                        isBusy ? null : () => _handleCompleteOrder(order),
                    icon: const Icon(Icons.check_circle_outline),
                    label: Text(
                      isBusy
                          ? 'UPDATING...'
                          : (isOnline
                              ? 'MARK AS DELIVERED'
                              : 'MARK DELIVERED & PAID'),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DriverRouteModal extends StatefulWidget {
  final CharcoalOrder order;
  final LatLng origin;
  final LatLng destination;
  final VoidCallback onNavigateExternal;

  const _DriverRouteModal({
    required this.order,
    required this.origin,
    required this.destination,
    required this.onNavigateExternal,
  });

  @override
  State<_DriverRouteModal> createState() => _DriverRouteModalState();
}

class _DriverRouteModalState extends State<_DriverRouteModal> {
  RouteResult? _route;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRoute();
  }

  Future<void> _loadRoute() async {
    final res = await RoutingService.getDrivingRoute(
      widget.origin,
      widget.destination,
    );
    if (!mounted) return;
    setState(() {
      _route = res;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.72,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Route to ${widget.order.customerName}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppTheme.inkCharcoal,
                        ),
                      ),
                      Text(
                        _loading
                            ? 'Calculating route...'
                            : '${_route!.distanceKm.toStringAsFixed(1)} km • ~${_route!.durationMinutes} min'
                                '${_route!.isEstimated ? ' (est.)' : ''}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.emeraldGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.emeraldGreen,
                  ),
                  onPressed: widget.onNavigateExternal,
                  icon: const Icon(Icons.navigation, size: 16),
                  label: const Text('Maps'),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(
                    (widget.origin.latitude + widget.destination.latitude) / 2,
                    (widget.origin.longitude + widget.destination.longitude) / 2,
                  ),
                  initialZoom: 13.5,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.coal.charcoal_app',
                  ),
                  if (_route != null && _route!.points.length >= 2)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: _route!.points,
                          color: AppTheme.emeraldGreen,
                          strokeWidth: 4.5,
                        ),
                      ],
                    ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: widget.origin,
                        width: 40,
                        height: 40,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppTheme.primaryAmber,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Center(
                            child: Text('🛵', style: TextStyle(fontSize: 20)),
                          ),
                        ),
                      ),
                      Marker(
                        point: widget.destination,
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
        ],
      ),
    );
  }
}
