import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../models/order_model.dart';

/// Displays an itemized digital receipt / order breakdown bottom sheet.
class OrderReceiptSheet {
  static void show(BuildContext context, CharcoalOrder order) {
    final isOnline = order.paymentMethod == 'ONLINE_QR';
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.cardWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Order Receipt',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.inkCharcoal,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.canvasMist,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.surfaceBorder),
                    ),
                    child: Text(
                      order.status,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.headerForest,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Order ID: ${order.id}',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: AppTheme.mutedSlate,
                ),
              ),
              const Divider(height: 24, color: AppTheme.surfaceBorder),
              _row(
                'Charcoal (${order.sacksOrdered} × ₱${order.pricePerUnit.toStringAsFixed(2)})',
                '₱ ${order.subtotalAmount.toStringAsFixed(2)}',
              ),
              const SizedBox(height: 8),
              _row(
                'Delivery Fee',
                order.deliveryFee <= 0
                    ? 'FREE'
                    : '₱ ${order.deliveryFee.toStringAsFixed(2)}',
              ),
              const Divider(height: 20, color: AppTheme.surfaceBorder),
              _row(
                'Total Amount',
                '₱ ${order.totalAmount.toStringAsFixed(2)}',
                isBold: true,
                valueColor: AppTheme.emeraldGreen,
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.canvasMist,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.surfaceBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _row(
                      'Payment Method',
                      isOnline ? 'Online QR' : 'Cash on Delivery (COD)',
                    ),
                    const SizedBox(height: 6),
                    _row('Payment Status', order.paymentStatus),
                    if (isOnline &&
                        order.receiptRefNumber != null &&
                        order.receiptRefNumber!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      _row('Reference No.', order.receiptRefNumber!),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      'Deliver to: ${order.deliveryAddress}',
                      style: const TextStyle(fontSize: 11, color: AppTheme.mutedSlate),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _row(
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: isBold ? 14 : 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isBold ? AppTheme.inkCharcoal : AppTheme.mutedSlate,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: isBold ? 16 : 12,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: valueColor ?? AppTheme.inkCharcoal,
          ),
        ),
      ],
    );
  }
}
