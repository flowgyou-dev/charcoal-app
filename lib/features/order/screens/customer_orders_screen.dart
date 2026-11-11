import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/connection_banner.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';
import 'customer_tracking_screen.dart';

class CustomerOrdersScreen extends StatefulWidget {
  final String customerId;

  const CustomerOrdersScreen({super.key, required this.customerId});

  @override
  State<CustomerOrdersScreen> createState() => _CustomerOrdersScreenState();
}

class _CustomerOrdersScreenState extends State<CustomerOrdersScreen> {
  final _orderService = OrderService();
  final Map<String, String> _knownStatuses = {};
  bool _hasSeededStatuses = false;
  String? _cancellingOrderId;

  void _checkStatusChanges(List<CharcoalOrder> orders) {
    if (!_hasSeededStatuses) {
      for (final o in orders) {
        _knownStatuses[o.id] = o.status;
      }
      _hasSeededStatuses = true;
      return;
    }

    for (final o in orders) {
      final prev = _knownStatuses[o.id];
      if (prev != null && prev != o.status) {
        _knownStatuses[o.id] = o.status;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: o.status == 'Cancelled'
                  ? Colors.red.shade700
                  : AppTheme.emeraldGreen,
              content: Text('Order ${o.id} status updated: ${o.status}'),
            ),
          );
        });
      } else {
        _knownStatuses[o.id] = o.status;
      }
    }
  }

  Future<void> _promptCancelOrder(CharcoalOrder order) async {
    final reasonCtrl = TextEditingController();
    final selectedReason = await showDialog<String>(
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Stock will be restored to inventory when this pending order is cancelled.',
              style: TextStyle(fontSize: 12, color: AppTheme.mutedSlate),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              maxLength: 120,
              decoration: const InputDecoration(
                labelText: 'Reason for cancellation (optional)',
                hintText: 'e.g. Wrong delivery address',
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
              final text = reasonCtrl.text.trim();
              Navigator.pop(
                ctx,
                text.isEmpty ? 'Cancelled by Customer' : text,
              );
            },
            child: const Text('Cancel Order'),
          ),
        ],
      ),
    );
    reasonCtrl.dispose();

    if (selectedReason == null) return;
    setState(() => _cancellingOrderId = order.id);
    try {
      await _orderService.cancelOrder(order, reason: selectedReason);
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
      if (mounted) setState(() => _cancellingOrderId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Orders')),
      body: ConnectionBanner(
        child: StreamBuilder<List<CharcoalOrder>>(
          stream: _orderService.streamCustomerOrders(widget.customerId),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text(
                    'Unable to load your orders. Please check your internet connection.',
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

            final orders = snapshot.data ?? [];
            _checkStatusChanges(orders);

            if (orders.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('📦', style: TextStyle(fontSize: 48)),
                    SizedBox(height: 12),
                    Text(
                      'You have not placed any orders yet.',
                      style: TextStyle(color: AppTheme.mutedSlate),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final o = orders[index];
                final badgeColor = _statusColor(o.status);
                final canCancel = o.status == 'Pending';
                final isOnline = o.paymentMethod == 'ONLINE_QR';

                return Card(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CustomerTrackingScreen(order: o),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                o.id,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.headerForest,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: badgeColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: badgeColor.withValues(alpha: 0.6),
                                  ),
                                ),
                                child: Text(
                                  o.status,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: badgeColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${o.sacksOrdered} ${o.sacksOrdered == 1 ? 'Sack' : 'Sacks'} • ₱ ${o.totalAmount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppTheme.inkCharcoal,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              _pillTag(
                                isOnline ? 'Online QR' : 'COD',
                                isOnline
                                    ? AppTheme.headerForest
                                    : AppTheme.mutedSlate,
                              ),
                              const SizedBox(width: 6),
                              _pillTag(
                                o.paymentStatus,
                                o.paymentStatus == 'Paid' ||
                                        o.paymentStatus == 'Verified'
                                    ? AppTheme.emeraldGreen
                                    : Colors.orange.shade700,
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            o.deliveryAddress,
                            style: const TextStyle(
                              color: AppTheme.mutedSlate,
                              fontSize: 12,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (o.status == 'Cancelled' &&
                              o.cancelReason != null &&
                              o.cancelReason!.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Reason: ${o.cancelReason}',
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                          if (canCancel) ...[
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red.shade700,
                                    side: BorderSide(color: Colors.red.shade300),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                  ),
                                  onPressed: _cancellingOrderId == o.id
                                      ? null
                                      : () => _promptCancelOrder(o),
                                  icon: _cancellingOrderId == o.id
                                      ? const SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.cancel_outlined,
                                          size: 16,
                                        ),
                                  label: const Text(
                                    'Cancel Order',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _pillTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Delivered':
        return AppTheme.emeraldGreen;
      case 'Out for Delivery':
        return AppTheme.primaryAmber;
      case 'Cancelled':
        return Colors.red.shade700;
      case 'Confirmed':
        return Colors.blue.shade700;
      default:
        return AppTheme.headerForest;
    }
  }
}
