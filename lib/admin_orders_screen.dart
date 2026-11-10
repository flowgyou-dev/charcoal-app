import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'main.dart';

class AdminOrdersScreen extends StatelessWidget {
  const AdminOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ORDER MANAGEMENT'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Error loading orders:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final orders = snapshot.data?.docs ?? [];

          if (orders.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 70,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No orders yet',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Customer orders will appear here.',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final orderDoc = orders[index];
              final order = orderDoc.data();

              final String orderId =
              (order['orderId'] ?? orderDoc.id).toString();

              final String customerEmail =
              (order['customerEmail'] ?? 'No email').toString();

              final String product =
              (order['product'] ?? 'Unknown product').toString();

              final String quantity =
              (order['quantity'] ?? 0).toString();

              final String method =
              (order['method'] ?? 'N/A').toString();

              final String date =
              (order['date'] ?? 'N/A').toString();

              final String time =
              (order['time'] ?? 'N/A').toString();

              final String total =
              (order['total'] ?? 0).toString();

              final String status =
              (order['status'] ?? 'PENDING')
                  .toString()
                  .toUpperCase();

              final String location =
              (order['location'] ?? 'No location').toString();

              final String driverId =
              (order['driverId'] ?? '').toString();

              final String driverName =
              (order['driverName'] ?? '').toString();

              final String driverEmail =
              (order['driverEmail'] ?? '').toString();

              final double? latitude =
              (order['latitude'] as num?)?.toDouble();

              final double? longitude =
              (order['longitude'] as num?)?.toDouble();

              final bool hasLocation =
                  latitude != null && longitude != null;

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Order #$orderId',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          _statusBadge(status),
                        ],
                      ),

                      const SizedBox(height: 16),

                      _orderInfo(
                        Icons.email_outlined,
                        'Customer',
                        customerEmail,
                      ),

                      _orderInfo(
                        Icons.inventory_2_outlined,
                        'Product',
                        product,
                      ),

                      _orderInfo(
                        Icons.shopping_bag_outlined,
                        'Quantity',
                        quantity,
                      ),

                      _orderInfo(
                        Icons.local_shipping_outlined,
                        'Method',
                        method,
                      ),

                      _orderInfo(
                        Icons.calendar_today_outlined,
                        'Schedule',
                        '$date • $time',
                      ),

                      _orderInfo(
                        Icons.location_on_outlined,
                        'Location',
                        location,
                      ),

                      _orderInfo(
                        Icons.payments_outlined,
                        'Total',
                        '₱$total',
                      ),

                      const SizedBox(height: 10),

                      // DRIVER ASSIGNMENT
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F1E7),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFFD7CCC8),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.person_pin_circle,
                                  color: Color(0xFF5D4037),
                                ),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'DRIVER ASSIGNMENT',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF3E2723),
                                    ),
                                  ),
                                ),
                                if (driverId.isNotEmpty)
                                  const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                  ),
                              ],
                            ),

                            const SizedBox(height: 10),

                            Text(
                              driverId.isEmpty
                                  ? 'No driver assigned'
                                  : driverName.isNotEmpty
                                  ? driverName
                                  : driverEmail,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),

                            if (driverEmail.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(
                                driverEmail,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13,
                                ),
                              ),
                            ],

                            const SizedBox(height: 10),

                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  _showDriverDialog(
                                    context,
                                    orderDoc.reference,
                                    driverId,
                                  );
                                },
                                icon: Icon(
                                  driverId.isEmpty
                                      ? Icons.person_add
                                      : Icons.swap_horiz,
                                ),
                                label: Text(
                                  driverId.isEmpty
                                      ? 'ASSIGN DRIVER'
                                      : 'CHANGE DRIVER',
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                  const Color(0xFF5D4037),
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),

                            if (driverId.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              SizedBox(
                                width: double.infinity,
                                child: TextButton(
                                  onPressed: () {
                                    _removeDriver(
                                      context,
                                      orderDoc.reference,
                                    );
                                  },
                                  child: const Text(
                                    'REMOVE DRIVER',
                                    style: TextStyle(
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // CUSTOMER LOCATION
                      if (hasLocation)
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      CustomerLocationMapScreen(
                                        latitude: latitude,
                                        longitude: longitude,
                                        locationLabel:
                                        'Customer Delivery Location',
                                      ),
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.location_on,
                            ),
                            label: const Text(
                              'VIEW CUSTOMER LOCATION',
                            ),
                          ),
                        ),

                      if (hasLocation)
                        const SizedBox(height: 8),

                      // STATUS
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _showStatusDialog(
                              context,
                              orderDoc.reference,
                              status,
                            );
                          },
                          icon: const Icon(Icons.edit),
                          label: const Text(
                            'UPDATE STATUS',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _orderInfo(
      IconData icon,
      String label,
      String value,
      ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: Colors.brown,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                ),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text: value,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color color;

    switch (status) {
      case 'COMPLETED':
        color = Colors.green;
        break;
      case 'CANCELLED':
        color = Colors.red;
        break;
      case 'PROCESSING':
        color = Colors.blue;
        break;
      case 'READY':
        color = Colors.purple;
        break;
      case 'OUT FOR DELIVERY':
        color = Colors.indigo;
        break;
      default:
        color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }

  // ============================================================
  // DRIVER ASSIGNMENT
  // ============================================================

  void _showDriverDialog(
      BuildContext context,
      DocumentReference<Map<String, dynamic>> orderRef,
      String currentDriverId,
      ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return StreamBuilder<
            QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .where(
            'role',
            isEqualTo: 'driver',
          )
              .where(
            'status',
            isEqualTo: 'active',
          )
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return AlertDialog(
                title: const Text(
                  'Assign Driver',
                ),
                content: Text(
                  'Unable to load drivers.\n\n'
                      '${snapshot.error}',
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                    },
                    child: const Text('CLOSE'),
                  ),
                ],
              );
            }

            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return const AlertDialog(
                title: Text(
                  'Assign Driver',
                ),
                content: SizedBox(
                  height: 80,
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              );
            }

            final drivers = snapshot.data?.docs ?? [];

            if (drivers.isEmpty) {
              return AlertDialog(
                title: const Text(
                  'Assign Driver',
                ),
                content: const Text(
                  'No active driver found.',
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                    },
                    child: const Text('CLOSE'),
                  ),
                ],
              );
            }

            return AlertDialog(
              title: const Text(
                'Select Driver',
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: drivers.length,
                  separatorBuilder: (context, index) {
                    return const Divider();
                  },
                  itemBuilder: (context, index) {
                    final driver =
                    drivers[index].data();

                    final String id =
                        drivers[index].id;

                    final String firstName =
                    (driver['firstName'] ?? '')
                        .toString();

                    final String lastName =
                    (driver['lastName'] ?? '')
                        .toString();

                    final String email =
                    (driver['email'] ?? '')
                        .toString();

                    final String name =
                    '$firstName $lastName'.trim();

                    final String displayName =
                    name.isNotEmpty
                        ? name
                        : email.isNotEmpty
                        ? email
                        : 'Driver';

                    final bool selected =
                        id == currentDriverId;

                    return ListTile(
                      leading: const CircleAvatar(
                        backgroundColor:
                        Color(0xFFEDE0D4),
                        child: Icon(
                          Icons.person,
                          color: Color(0xFF5D4037),
                        ),
                      ),
                      title: Text(
                        displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        email.isNotEmpty
                            ? email
                            : 'No email',
                      ),
                      trailing: selected
                          ? const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                      )
                          : const Icon(
                        Icons.chevron_right,
                      ),
                      onTap: () async {
                        Navigator.pop(dialogContext);

                        try {
                          await orderRef.update({
                            'driverId': id,
                            'driverEmail': email,
                            'driverName': displayName,
                            'assignedAt':
                            FieldValue.serverTimestamp(),
                          });

                          if (!context.mounted) {
                            return;
                          }

                          ScaffoldMessenger.of(context)
                              .showSnackBar(
                            SnackBar(
                              content: Text(
                                '$displayName assigned successfully.',
                              ),
                            ),
                          );
                        } catch (e) {
                          if (!context.mounted) {
                            return;
                          }

                          ScaffoldMessenger.of(context)
                              .showSnackBar(
                            SnackBar(
                              content: Text(
                                'Failed to assign driver: $e',
                              ),
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('CANCEL'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ============================================================
  // REMOVE DRIVER
  // ============================================================

  Future<void> _removeDriver(
      BuildContext context,
      DocumentReference<Map<String, dynamic>> orderRef,
      ) async {
    try {
      await orderRef.update({
        'driverId': FieldValue.delete(),
        'driverEmail': FieldValue.delete(),
        'driverName': FieldValue.delete(),
        'assignedAt': FieldValue.delete(),
      });

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Driver assignment removed.',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to remove driver: $e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // UPDATE STATUS
  // ============================================================

  void _showStatusDialog(
      BuildContext context,
      DocumentReference<Map<String, dynamic>> orderRef,
      String currentStatus,
      ) {
    const List<String> statuses = [
      'PENDING',
      'PROCESSING',
      'READY',
      'OUT FOR DELIVERY',
      'COMPLETED',
      'CANCELLED',
    ];

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Update Order Status',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: statuses.map((status) {
              return ListTile(
                title: Text(status),
                trailing: status == currentStatus
                    ? const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                )
                    : null,
                onTap: () async {
                  Navigator.pop(dialogContext);

                  try {
                    await orderRef.update({
                      'status': status,
                    });

                    if (!context.mounted) {
                      return;
                    }

                    ScaffoldMessenger.of(context)
                        .showSnackBar(
                      SnackBar(
                        content: Text(
                          'Order status updated to $status.',
                        ),
                      ),
                    );
                  } catch (e) {
                    if (!context.mounted) {
                      return;
                    }

                    ScaffoldMessenger.of(context)
                        .showSnackBar(
                      SnackBar(
                        content: Text(
                          'Failed to update status: $e',
                        ),
                      ),
                    );
                  }
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }
}