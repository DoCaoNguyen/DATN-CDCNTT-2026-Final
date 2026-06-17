import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/screens/login_screen.dart';

class StaffHomeScreen extends ConsumerStatefulWidget {
  const StaffHomeScreen({super.key});

  @override
  ConsumerState<StaffHomeScreen> createState() => _StaffHomeScreenState();
}

class _StaffHomeScreenState extends ConsumerState<StaffHomeScreen> {
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  String? qrData;

  void _createOrder() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) return;

    try {
      final res = await ref.read(apiServiceProvider).createOrder(amount, _descController.text);
      setState(() {
        qrData = res['data']['qr_payload'];
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error creating order')));
    }
  }

  void _logout() async {
    await ref.read(authProvider.notifier).logout();
    if (mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Dashboard'),
        actions: [
          IconButton(icon: const Icon(Icons.history), onPressed: () {
            // Navigate to history
          }),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(labelText: 'Amount (VND)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _createOrder,
              child: const Text('Create Order (Generate QR)'),
            ),
            const SizedBox(height: 32),
            if (qrData != null)
              Column(
                children: [
                  const Text('Ask customer to scan this QR with Wallet App:'),
                  const SizedBox(height: 16),
                  QrImageView(
                    data: qrData!,
                    version: QrVersions.auto,
                    size: 200.0,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
