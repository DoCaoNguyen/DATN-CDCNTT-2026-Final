import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  late Dio _dio;
  
  // URL giả định cho emulator/localhost
  final String baseUrl = 'http://127.0.0.1:3001/api/v1'; 

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 3),
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
    ));
  }

  Dio get dio => _dio;

  Future<Map<String, dynamic>> login(String phone, String password) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'phone_number': phone,
        'password': password,
      });
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', response.data['token']);
      await prefs.setString('role', response.data['user']['role']);
      
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  // Staff APIs
  Future<Map<String, dynamic>> createOrder(double amount, String description) async {
    final res = await _dio.post('/staff/order/create', data: {
      'amount': amount,
      'description': description,
    });
    return res.data;
  }

  Future<List<dynamic>> getStaffHistory() async {
    final res = await _dio.get('/staff/history');
    return res.data['data'];
  }

  // Member APIs
  Future<Map<String, dynamic>> getMemberProfile() async {
    final res = await _dio.get('/member/profile');
    return res.data['data'];
  }

  Future<List<dynamic>> getMemberHistory() async {
    final res = await _dio.get('/member/history');
    return res.data['data'];
  }

  Future<List<dynamic>> getRewards() async {
    final res = await _dio.get('/member/rewards');
    return res.data['data'];
  }
}
