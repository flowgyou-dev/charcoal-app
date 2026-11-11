import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

/// Displays an offline warning banner whenever Firebase Realtime Database
/// loses connection, and reports connectivity changes to parent widgets if needed.
class ConnectionBanner extends StatelessWidget {
  final Widget? child;

  const ConnectionBanner({super.key, this.child});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DatabaseEvent>(
      stream: FirebaseDatabase.instance.ref('.info/connected').onValue,
      builder: (context, snapshot) {
        final isConnected = snapshot.data?.snapshot.value as bool? ?? true;

        return Column(
          children: [
            if (!isConnected)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                color: Colors.redAccent.shade700,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.wifi_off, color: Colors.white, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Walang internet connection. Iche-check uli kapag bumalik ang signal.',
                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            if (child != null) Expanded(child: child!),
          ],
        );
      },
    );
  }
}
