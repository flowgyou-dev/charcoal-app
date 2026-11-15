import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/connection_banner.dart';
import '../../auth/models/user_model.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';
import '../widgets/order_receipt_sheet.dart';
import 'customer_tracking_screen.dart';

class CustomerDashboardScreen extends StatelessWidget {
  final AppUser currentUser;
  final VoidCallback onGoToOrder;

  const CustomerDashboardScreen({
    super.key,
    required this.currentUser,
    required this.onGoToOrder,
  });

  int _stepForStatus(String status) {
    switch (status) {
      case 'Confirmed':
        return 1;
      case 'Out for Delivery':
        return 2;
      case 'Delivered':
        return 3;
      default:
        return 0;
    }
  }

  Future<void> _callDriver(BuildContext context, String phone) async {
    final uri = Uri(scheme: 'tel', path: phone.trim());
    if (!await launchUrl(uri)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open phone dialer.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderService = OrderService();

    return ConnectionBanner(
      child: StreamBuilder<List<CharcoalOrder>>(
        stream: orderService.streamCustomerOrders(currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final allOrders = snapshot.data ?? [];
          final activeOrders = allOrders
              .where((o) => o.status != 'Delivered' && o.status != 'Cancelled')
              .toList();
          final currentOrder =
              activeOrders.isNotEmpty ? activeOrders.first : null;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Text(
                  'Good day, ${currentUser.name}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.inkCharcoal,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (currentOrder == null)
                _buildEmptyOrderCard()
              else
                _buildCurrentOrderCard(context, currentOrder),
              if (currentOrder != null) ...[
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.emeraldGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: onGoToOrder,
                    icon: const Icon(Icons.add_shopping_cart),
                    label: const Text(
                      'Order More Charcoal',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyOrderCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTheme.surfaceBorder),
      ),
      child: Column(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: AppTheme.headerForest.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.local_fire_department_outlined,
              size: 36,
              color: AppTheme.headerForest,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Active Order',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.inkCharcoal,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Your current charcoal delivery status and live tracking will appear here once you place an order.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppTheme.mutedSlate),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.headerForest,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: onGoToOrder,
              icon: const Icon(Icons.shopping_bag_outlined),
              label: const Text(
                'Order Charcoal Now',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentOrderCard(BuildContext context, CharcoalOrder order) {
    final step = _stepForStatus(order.status);
    final hasDriverPhone =
        order.driverPhone != null && order.driverPhone!.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTheme.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CURRENT ORDER',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.mutedSlate,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    order.id,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppTheme.inkCharcoal,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.emeraldGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  order.status,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.emeraldGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _stepDot('Placed', step >= 0),
              _stepLine(step >= 1),
              _stepDot('Confirmed', step >= 1),
              _stepLine(step >= 2),
              _stepDot('On the way', step >= 2),
              _stepLine(step >= 3),
              _stepDot('Delivered', step >= 3),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _infoTile(
                  'Items',
                  '${order.sacksOrdered} sack(s)',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _infoTile(
                  'Total (${order.paymentMethod == 'ONLINE_QR' ? 'Online QR' : 'COD'})',
                  '₱ ${order.totalAmount.toStringAsFixed(2)}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _infoTile(
            'Delivery Address',
            order.deliveryAddress,
          ),
          if (order.driverName != null && order.driverName!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            _infoTile(
              'Assigned Driver',
              hasDriverPhone
                  ? '${order.driverName} (${order.driverPhone})'
                  : order.driverName!,
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.headerForest,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CustomerTrackingScreen(order: order),
                      ),
                    );
                  },
                  icon: const Icon(Icons.my_location, size: 17),
                  label: const Text(
                    'Track Live',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              if (hasDriverPhone) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.emeraldGreen,
                      side: const BorderSide(color: AppTheme.emeraldGreen),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => _callDriver(context, order.driverPhone!),
                    icon: const Icon(Icons.call, size: 17),
                    label: const Text(
                      'Call Driver',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton.icon(
              onPressed: () => OrderReceiptSheet.show(context, order),
              icon: const Icon(Icons.receipt_long_outlined, size: 16),
              label: const Text('View Digital Receipt'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepDot(String label, bool active) {
    return Column(
      children: [
        CircleAvatar(
          radius: 11,
          backgroundColor: active ? AppTheme.emeraldGreen : AppTheme.surfaceBorder,
          child: Icon(
            active ? Icons.check : Icons.circle,
            size: active ? 13 : 7,
            color: active ? Colors.white : AppTheme.mutedSlate,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
            color: active ? AppTheme.inkCharcoal : AppTheme.mutedSlate,
          ),
        ),
      ],
    );
  }

  Widget _stepLine(bool active) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 16),
        color: active ? AppTheme.emeraldGreen : AppTheme.surfaceBorder,
      ),
    );
  }

  Widget _infoTile(String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F5F4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: AppTheme.mutedSlate),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppTheme.inkCharcoal,
            ),
          ),
        ],
      ),
    );
  }
}
