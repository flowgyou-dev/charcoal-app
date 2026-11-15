import 'package:flutter/material.dart';
import '../../../core/models/shop_settings_model.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/models/user_model.dart';
import '../../profile/screens/profile_screen.dart';
import 'customer_dashboard_screen.dart';
import 'customer_home_screen.dart';
import 'customer_orders_screen.dart';

class CustomerShellScreen extends StatefulWidget {
  final AppUser currentUser;

  const CustomerShellScreen({super.key, required this.currentUser});

  @override
  State<CustomerShellScreen> createState() => _CustomerShellScreenState();
}

class _CustomerShellScreenState extends State<CustomerShellScreen> {
  int _tabIndex = 0;
  Map<String, dynamic>? _orderPrefill;

  static const _titles = [
    'Home',
    'Order Charcoal',
    'My Orders',
    'Profile',
  ];

  static const _tabs = [
    'Home',
    'Order',
    'My Orders',
  ];

  void _selectTab(int index) {
    if (index == _tabIndex) return;
    setState(() => _tabIndex = index);
  }

  void _handleOrderAgain(Map<String, dynamic> prefill) {
    setState(() {
      _orderPrefill = Map<String, dynamic>.from(prefill);
      _tabIndex = 1;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Previous order details loaded!'),
        backgroundColor: AppTheme.emeraldGreen,
      ),
    );
  }

  Widget _buildBrandLogo(ShopSettings settings) {
    final logoBytes = settings.decodeSystemLogoBytes();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: logoBytes != null
          ? Image.memory(
              logoBytes,
              height: 30,
              fit: BoxFit.contain,
            )
          : Image.asset(
              'assets/images/logo.png',
              height: 30,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Text(
                settings.systemName,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.inkCharcoal,
                ),
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ShopSettings>(
      stream: SettingsService().settingsStream,
      builder: (context, settingsSnap) {
        final settings = settingsSnap.data ?? const ShopSettings();
        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            titleSpacing: 12,
            title: Row(
              children: [
                _buildBrandLogo(settings),
                Expanded(
                  child: Text(
                    _titles[_tabIndex],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long, color: Colors.white),
            tooltip: 'My Orders',
            onPressed: () => _selectTab(2),
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined, color: Colors.white),
            tooltip: 'Profile',
            onPressed: () => _selectTab(3),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: AppTheme.cardWhite,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AppTheme.surfaceBorder),
              ),
              child: Row(
                children: List.generate(_tabs.length, (i) {
                  final selected = _tabIndex == i;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => _selectTab(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppTheme.headerForest
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Text(
                          _tabs[i],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: selected ? Colors.white : AppTheme.mutedSlate,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: _tabIndex,
              children: [
                CustomerDashboardScreen(
                  currentUser: widget.currentUser,
                  onGoToOrder: () => _selectTab(1),
                ),
                CustomerHomeScreen(
                  currentUser: widget.currentUser,
                  embedded: true,
                  initialPrefill: _orderPrefill,
                ),
                CustomerOrdersScreen(
                  customerId: widget.currentUser.uid,
                  embedded: true,
                  onOrderAgain: _handleOrderAgain,
                ),
                ProfileScreen(
                  name: widget.currentUser.name,
                  email: widget.currentUser.email,
                  phone: widget.currentUser.phone,
                  role: widget.currentUser.role,
                  embedded: true,
                ),
              ],
            ),
          ),
        ],
      ),
        );
      },
    );
  }
}
