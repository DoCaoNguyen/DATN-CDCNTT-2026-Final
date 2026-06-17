import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/api_service.dart';

final apiServiceProvider = Provider((ref) => ApiService());

class AuthState {
  final bool isLoading;
  final String? error;
  final Map<String, dynamic>? user;
  
  AuthState({this.isLoading = false, this.error, this.user});
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    return AuthState();
  }

  Future<bool> login(String phone, String password) async {
    state = AuthState(isLoading: true);
    try {
      final apiService = ref.read(apiServiceProvider);
      final data = await apiService.login(phone, password);
      state = AuthState(isLoading: false, user: data['user']);
      return true;
    } catch (e) {
      state = AuthState(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('role');
    state = AuthState();
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
