import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/models/shop_settings_model.dart';
import '../../../core/services/routing_service.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/connection_banner.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';
import '../widgets/order_receipt_sheet.dart';

class CustomerTrackingScreen extends StatefulWidget {
  final CharcoalOrder order;

  const CustomerTrackingScreen({super.key, required this.order});

  @override
  State<CustomerTrackingScreen> createState() => _CustomerTrackingScreenState();
}

class _CustomerTrackingScreenState extends State<CustomerTrackingScreen> {
  final _orderService = OrderService();
  final _settingsService = SettingsService();
  final MapController _mapController = MapController();

  RouteResult? _route;
  LatLng? _lastRouteOrigin;
  LatLng? _lastRouteDest;
  bool _isFetchingRoute = false;
  bool _followDriver = true;
  bool _isCancelling = false;

  Future<void> _maybeRefreshRoute(LatLng origin, LatLng dest) async {
    if (_isFetchingRoute) return;
    if (_lastRouteOrigin != null && _lastRouteDest != null) {
      final movedKm = ShopSettings.calculateHaversineKm(
        _lastRouteOrigin!.latitude,
        _lastRouteOrigin!.longitude,
        origin.latitude,
        origin.longitude,
      );
      final destSame = ShopSettings.calculateHaversineKm(
            _lastRouteDest!.latitude,
            _lastRouteDest!.longitude,
            dest.latitude,
            dest.longitude,
          ) <
          0.01;
      if (movedKm < 0.12 && destSame && _route != null) return;
    }

    _isFetchingRoute = true;
    _lastRouteOrigin = origin;
    _lastRouteDest = dest;
    final res = await RoutingService.getDrivingRoute(origin, dest);
    _isFetchingRoute = false;
    if (!mounted) return;
    setState(() => _route = res);
  }

  Future<void> _callDriver(String phone) async {
    final cleaned = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleaned.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: cleaned);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to open dialer for $phone')),
      );
    }
  }

  Future<void> _promptCancelOrder(CharcoalOrder order) async {
    final reasonCtrl = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardWhite,
        title: Text(
          'Cancel ${order.id}?',
          style: const TextStyle(
            color: AppTheme.inkCharcoal,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Are you sure you want to cancel this pending order? Stock will be restored to inventory.',
              style: TextStyle(fontSize: 12, color: AppTheme.mutedSlate),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              maxLength: 120,
              decoration: const InputDecoration(
                labelText: 'Reason (optional)',
                counterText: '',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep Order'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () {
              final r = Validators.sanitizeText(reasonCtrl.text);
              Navigator.pop(ctx, r.isEmpty ? 'Cancelled by Customer' : r);
            },
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
    reasonCtrl.dispose();

    if (reason == null) return;
    setState(() => _isCancelling = true);
    try {
      await _orderService.cancelOrder(order, reason: reason);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppTheme.emeraldGreen,
          content: Text('Order cancelled and stock restored.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to cancel: ${e.toString().replaceAll('Exception: ', '')}',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isCancelling = false);
    }
  }

  int _stepForStatus(String status) {
    switch (status) {
      case 'Delivered':
        return 4;
      case 'Out for Delivery':
        return 3;
      case 'Confirmed':
        return 2;
      default:
        return 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Track ${widget.order.id}')),
      body: ConnectionBanner(
        child: StreamBuilder<ShopSettings>(
          stream: _settingsService.settingsStream,
          builder: (context, settingsSnap) {
            final settings = settingsSnap.data ?? const ShopSettings();
            final hubLoc = LatLng(settings.hubLat, settings.hubLng);

            return StreamBuilder<List<CharcoalOrder>>(
              stream: _orderService.streamCustomerOrders(widget.order.customerId),
              builder: (context, orderSnap) {
                if (orderSnap.hasError) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text(
                        'Unable to load tracking updates. Please check your internet connection.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.mutedSlate),
                      ),
                    ),
                  );
                }

                final orders = orderSnap.data ?? [widget.order];
                final currentOrder = orders.firstWhere(
                  (o) => o.id == widget.order.id,
                  orElse: () => widget.order,
                );
                final isCancelled = currentOrder.status == 'Cancelled';
                final step = _stepForStatus(currentOrder.status);
                final customerLoc = LatLng(
                  currentOrder.deliveryLat,
                  currentOrder.deliveryLng,
                );

                return Column(
                  children: [
                    _buildHeaderCard(currentOrder, isCancelled, step),
                    Expanded(
                      child: isCancelled
                          ? _buildCancelledBody(currentOrder)
                          : _buildLiveMap(currentOrder, hubLoc, customerLoc),
                    ),
                    _buildBottomBar(currentOrder, isCancelled),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeaderCard(
    CharcoalOrder currentOrder,
    bool isCancelled,
    int step,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppTheme.cardWhite,
        border: Border(bottom: BorderSide(color: AppTheme.surfaceBorder)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${currentOrder.sacksOrdered} ${currentOrder.sacksOrdered == 1 ? 'Sack' : 'Sacks'} • ₱${currentOrder.totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppTheme.inkCharcoal,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${currentOrder.paymentMethod == 'ONLINE_QR' ? 'Online QR' : 'COD'} • ${currentOrder.paymentStatus}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.mutedSlate,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isCancelled
                      ? Colors.red.withValues(alpha: 0.12)
                      : (currentOrder.status == 'Delivered'
                          ? AppTheme.emeraldGreen.withValues(alpha: 0.15)
                          : AppTheme.headerForest.withValues(alpha: 0.1)),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isCancelled
                        ? Colors.red.shade700
                        : (currentOrder.status == 'Delivered'
                            ? AppTheme.emeraldGreen
                            : AppTheme.headerForest),
                  ),
                ),
                child: Text(
                  currentOrder.status,
                  style: TextStyle(
                    color: isCancelled
                        ? Colors.red.shade700
                        : (currentOrder.status == 'Delivered'
                            ? AppTheme.emeraldGreen
                            : AppTheme.headerForest),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (!isCancelled) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStepNode(1, 'Placed', step >= 1),
                _buildStepLine(step >= 2),
                _buildStepNode(2, 'Confirmed', step >= 2),
                _buildStepLine(step >= 3),
                _buildStepNode(3, 'On the Way', step >= 3),
                _buildStepLine(step >= 4),
                _buildStepNode(4, 'Delivered', step >= 4),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCancelledBody(CharcoalOrder currentOrder) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cancel_outlined,
                    size: 54, color: Colors.red.shade700),
                const SizedBox(height: 12),
                const Text(
                  'Order Cancelled',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: AppTheme.inkCharcoal,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  currentOrder.cancelReason?.isNotEmpty == true
                      ? 'Reason: ${currentOrder.cancelReason}'
                      : 'This order was cancelled and reserved stock has been restored.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppTheme.mutedSlate,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLiveMap(
    CharcoalOrder currentOrder,
    LatLng hubLoc,
    LatLng customerLoc,
  ) {
    return StreamBuilder<Map<String, double>?>(
      stream: currentOrder.driverId != null
          ? _orderService.streamDriverLocation(currentOrder.driverId!)
          : const Stream.empty(),
      builder: (context, locSnapshot) {
        final driverCoords = locSnapshot.data;
        final driverLoc = driverCoords != null
            ? LatLng(driverCoords['lat']!, driverCoords['lng']!)
            : null;
        final routeOrigin = driverLoc ?? hubLoc;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _maybeRefreshRoute(routeOrigin, customerLoc);
          if (_followDriver && driverLoc != null) {
            try {
              _mapController.move(driverLoc, _mapController.camera.zoom);
            } catch (_) {}
          }
        });

        final isDriverOffline =
            driverCoords != null && driverCoords['isOnline'] == 0.0;

        return Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: driverLoc ?? customerLoc,
                initialZoom: 14.5,
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
                      point: hubLoc,
                      width: 38,
                      height: 38,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.headerForest,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Center(
                          child: Text('🏭', style: TextStyle(fontSize: 18)),
                        ),
                      ),
                    ),
                    Marker(
                      point: customerLoc,
                      width: 48,
                      height: 48,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue.shade600,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: const [
                            BoxShadow(color: Colors.black45, blurRadius: 6)
                          ],
                        ),
                        child: const Center(
                          child: Text('🏠', style: TextStyle(fontSize: 22)),
                        ),
                      ),
                    ),
                    if (driverLoc != null)
                      Marker(
                        point: driverLoc,
                        width: 52,
                        height: 52,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppTheme.primaryAmber,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: const [
                              BoxShadow(color: Colors.black45, blurRadius: 10)
                            ],
                          ),
                          child: const Center(
                            child: Text('🛵', style: TextStyle(fontSize: 26)),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            if (_route != null)
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.cardWhite.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 6),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.directions,
                        size: 16,
                        color: AppTheme.emeraldGreen,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${_route!.distanceKm.toStringAsFixed(1)} km • ~${_route!.durationMinutes} min'
                        '${_route!.isEstimated ? ' (est.)' : ''}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.inkCharcoal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (driverLoc != null)
              Positioned(
                top: 12,
                right: 12,
                child: FloatingActionButton.small(
                  heroTag: 'follow_driver_fab',
                  backgroundColor: _followDriver
                      ? AppTheme.emeraldGreen
                      : AppTheme.cardWhite,
                  foregroundColor:
                      _followDriver ? Colors.white : AppTheme.inkCharcoal,
                  onPressed: () {
                    setState(() => _followDriver = !_followDriver);
                    if (_followDriver) {
                      try {
                        _mapController.move(driverLoc, 15.0);
                      } catch (_) {}
                    }
                  },
                  child: const Icon(Icons.my_location, size: 18),
                ),
              ),
            if (isDriverOffline)
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.amber.shade700),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.gps_off, size: 16, color: Colors.amber.shade700),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Driver GPS paused / waiting for signal',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.inkCharcoal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildBottomBar(CharcoalOrder currentOrder, bool isCancelled) {
    final hasPhone = currentOrder.driverPhone != null &&
        currentOrder.driverPhone!.trim().isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppTheme.cardWhite,
        border: Border(top: BorderSide(color: AppTheme.surfaceBorder)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: AppTheme.headerForest,
            child: Text('🛵', style: TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentOrder.driverName ?? 'Waiting for driver assignment...',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppTheme.inkCharcoal,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isCancelled
                      ? 'Order cancelled'
                      : (currentOrder.status == 'Delivered'
                          ? 'Successfully delivered!'
                          : (currentOrder.status == 'Out for Delivery'
                              ? 'Your driver is on the way to your location.'
                              : 'Preparing your charcoal order.')),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.mutedSlate,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'View Receipt',
            onPressed: () => OrderReceiptSheet.show(context, currentOrder),
            icon: const Icon(Icons.receipt_long_outlined, color: AppTheme.headerForest),
          ),
          if (!isCancelled && hasPhone)
            IconButton.filled(
              style: IconButton.styleFrom(
                backgroundColor: AppTheme.emeraldGreen,
              ),
              tooltip: 'Call Driver',
              onPressed: () => _callDriver(currentOrder.driverPhone!),
              icon: const Icon(Icons.call, color: Colors.white, size: 18),
            ),
          if (currentOrder.status == 'Pending') ...[
            const SizedBox(width: 8),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red.shade700,
                side: BorderSide(color: Colors.red.shade300),
              ),
              onPressed: _isCancelling
                  ? null
                  : () => _promptCancelOrder(currentOrder),
              child: Text(_isCancelling ? '...' : 'Cancel'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStepNode(int index, String label, bool isDone) {
    return Column(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: isDone ? AppTheme.emeraldGreen : AppTheme.sageWatermark,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : Text(
                    '$index',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppTheme.inkCharcoal,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isDone ? AppTheme.inkCharcoal : AppTheme.mutedSlate,
            fontWeight: isDone ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(bool isDone) {
    return Expanded(
      child: Container(
        height: 2,
        color: isDone ? AppTheme.emeraldGreen : AppTheme.surfaceBorder,
      ),
    );
  }
}
