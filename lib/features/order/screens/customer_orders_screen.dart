import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';
import 'customer_tracking_screen.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/connection_banner.dart';

class CustomerOrdersScreen extends StatelessWidget {
  final String customerId;

  const CustomerOrdersScreen({super.key, required this.customerId});

  @override
  Widget build(BuildContext context) {
    final orderService = OrderService();

    return Scaffold(
      appBar: AppBar(title: const Text('My Orders')),
      body: ConnectionBanner(
        child: StreamBuilder<List<CharcoalOrder>>(
          stream: orderService.streamCustomerOrders(customerId),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(
                child: Text(
                  'Hindi ma-load ang iyong mga order. I-check ang internet.',
                  style: TextStyle(color: Colors.white60),
                ),
              );
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

          final orders = snapshot.data ?? [];
          if (orders.isEmpty) {
            return const Center(
              child: Text('Wala ka pang uling orders.', style: TextStyle(color: Colors.white60)),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final order = orders[index];
              return Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(order.id, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace', color: AppTheme.primaryAmber)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: order.status == 'Delivered' ? AppTheme.emeraldGreen.withOpacity(0.15) : AppTheme.primaryAmber.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: order.status == 'Delivered' ? AppTheme.emeraldGreen : AppTheme.primaryAmber),
                        ),
                        child: Text(
                          order.status,
                          style: TextStyle(
                            color: order.status == 'Delivered' ? AppTheme.emeraldGreen : AppTheme.primaryAmber,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text('${order.sacksOrdered} Sako ng Uling • ₱${order.totalAmount.toStringAsFixed(2)} (COD)', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(order.deliveryAddress, style: const TextStyle(color: Colors.white60, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right, color: Colors.white38),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CustomerTrackingScreen(order: order),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      ),
    );
  }
}
