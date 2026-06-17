import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/auth/screens/login_screen.dart';

void main() {
  runApp(
    const ProviderScope(
      child: LoyaltyApp(),
    ),
  );
}

class LoyaltyApp extends StatelessWidget {
  const LoyaltyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Loyalty App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}
