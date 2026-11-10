import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';

class CustomerTrackingScreen extends StatefulWidget {
  final CharcoalOrder order;

  const CustomerTrackingScreen({super.key, required this.order});

  @override
  State<CustomerTrackingScreen> createState() => _CustomerTrackingScreenState();
}

class _CustomerTrackingScreenState extends State<CustomerTrackingScreen> {
  final _orderService = OrderService();
  final MapController _mapController = MapController();

  int _getStatusStep(String status) {
    switch (status) {
      case 'Pending':
        return 1;
      case 'Confirmed':
        return 2;
      case 'Out for Delivery':
        return 3;
      case 'Delivered':
        return 4;
      default:
        return 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Track ${widget.order.id}'),
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: FirebaseDatabase.instance.ref('${AppConstants.dbOrders}/${widget.order.id}').onValue,
        builder: (context, orderSnapshot) {
          CharcoalOrder currentOrder = widget.order;
          if (orderSnapshot.hasData && orderSnapshot.data!.snapshot.exists) {
            currentOrder = CharcoalOrder.fromMap(
              widget.order.id,
              orderSnapshot.data!.snapshot.value as Map<dynamic, dynamic>,
            );
          }

          final step = _getStatusStep(currentOrder.status);
          final customerLoc = LatLng(currentOrder.deliveryLat, currentOrder.deliveryLng);

          return Column(
            children: [
              // Order Summary & Status Stepper
              Container(
                padding: const EdgeInsets.all(16),
                color: AppTheme.cardBg,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentOrder.id,
                              style: const TextStyle(fontFamily: 'monospace', color: AppTheme.primaryAmber, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${currentOrder.sacksOrdered} Sako • ₱${currentOrder.totalAmount.toStringAsFixed(2)} (COD)',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: currentOrder.status == 'Delivered'
                                ? AppTheme.emeraldGreen.withOpacity(0.15)
                                : AppTheme.primaryAmber.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: currentOrder.status == 'Delivered' ? AppTheme.emeraldGreen : AppTheme.primaryAmber,
                            ),
                          ),
                          child: Text(
                            currentOrder.status,
                            style: TextStyle(
                              color: currentOrder.status == 'Delivered' ? AppTheme.emeraldGreen : AppTheme.primaryAmber,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 4-Step Stepper
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
                ),
              ),

              // Live Map with Driver GPS
              Expanded(
                child: StreamBuilder<Map<String, double>?>(
                  stream: currentOrder.driverId != null
                      ? _orderService.streamDriverLocation(currentOrder.driverId!)
                      : const Stream.empty(),
                  builder: (context, locSnapshot) {
                    final driverCoords = locSnapshot.data;
                    final driverLoc = driverCoords != null
                        ? LatLng(driverCoords['lat']!, driverCoords['lng']!)
                        : null;

                    return FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: driverLoc ?? customerLoc,
                        initialZoom: 15.0,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.coal.charcoal_app',
                        ),
                        MarkerLayer(
                          markers: [
                            // Customer Destination Pin
                            Marker(
                              point: customerLoc,
                              width: 48,
                              height: 48,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade600,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                  boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 6)],
                                ),
                                child: const Center(
                                  child: Text('🏠', style: TextStyle(fontSize: 22)),
                                ),
                              ),
                            ),

                            // Driver Real-time GPS Marker
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
                                    boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 10)],
                                  ),
                                  child: const Center(
                                    child: Text('🛵', style: TextStyle(fontSize: 26)),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),

              // Driver Contact / Live Info Bar
              Container(
                padding: const EdgeInsets.all(16),
                color: AppTheme.darkBg,
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.purple.shade700,
                      child: const Text('🛵', style: TextStyle(fontSize: 18)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentOrder.driverName ?? 'Waiting for driver assignment...',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            currentOrder.status == 'Out for Delivery'
                                ? 'Papunta na si Kuya Driver sa lokasyon mo.'
                                : 'Ihahanda na ang iyong sako ng uling.',
                            style: const TextStyle(fontSize: 11, color: Colors.white60),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
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
            color: isDone ? AppTheme.primaryAmber : AppTheme.surfaceBorder,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : Text('$index', style: const TextStyle(fontSize: 10, color: Colors.white70)),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: isDone ? Colors.white : Colors.white38),
        ),
      ],
    );
  }

  Widget _buildStepLine(bool isDone) {
    return Expanded(
      child: Container(
        height: 2,
        color: isDone ? AppTheme.primaryAmber : AppTheme.surfaceBorder,
      ),
    );
  }
}
