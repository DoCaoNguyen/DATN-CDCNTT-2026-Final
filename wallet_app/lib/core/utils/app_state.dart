import 'package:flutter/material.dart';

class AppState {
  // Biến toàn cục quản lý ngôn ngữ (Mặc định là VIE)
  static final ValueNotifier<String> currentLanguage = ValueNotifier<String>('VIE');
}