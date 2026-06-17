import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/screens/login_screen.dart';

class MemberHomeScreen extends ConsumerStatefulWidget {
  const MemberHomeScreen({super.key});

  @override
  ConsumerState<MemberHomeScreen> createState() => _MemberHomeScreenState();
}

class _MemberHomeScreenState extends ConsumerState<MemberHomeScreen> {
  Map<String, dynamic>? profile;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final data = await ref.read(apiServiceProvider).getMemberProfile();
      setState(() {
        profile = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
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
        title: const Text('Member Dashboard'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadProfile),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: isLoading 
          ? const Center(child: CircularProgressIndicator())
          : profile == null
              ? const Center(child: Text('Error loading profile'))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text('Welcome, ${profile!['full_name']}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      Card(
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Text('Tier: ${profile!['tier']}', style: const TextStyle(fontSize: 20)),
                              const SizedBox(height: 8),
                              Text('Points: ${profile!['total_points']}', style: const TextStyle(fontSize: 28, color: Colors.blue, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Text('Your Loyalty Barcode/QR:'),
                      const SizedBox(height: 16),
                      QrImageView(
                        data: profile!['phone_number'],
                        version: QrVersions.auto,
                        size: 150.0,
                      ),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            icon: const Icon(Icons.card_giftcard),
                            label: const Text('Rewards'),
                            onPressed: () {
                              // Navigate to rewards
                            },
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.history),
                            label: const Text('History'),
                            onPressed: () {
                              // Navigate to history
                            },
                          ),
                        ],
                      )
                    ],
                  ),
                ),
    );
  }
}
