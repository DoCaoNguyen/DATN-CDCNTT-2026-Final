import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../../staff/screens/staff_home_screen.dart';
import '../../member/screens/member_home_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  void _handleLogin() async {
    final success = await ref.read(authProvider.notifier).login(
      _phoneController.text,
      _passwordController.text,
    );
    
    if (success && mounted) {
      final user = ref.read(authProvider).user;
      if (user != null) {
        if (user['role'] == 'STAFF' || user['role'] == 'ADMIN') {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const StaffHomeScreen()));
        } else {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MemberHomeScreen()));
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login failed. Check your credentials.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Loyalty App Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Phone Number'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 32),
            authState.isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _handleLogin,
                    child: const Text('Login'),
                  ),
          ],
        ),
      ),
    );
  }
}
