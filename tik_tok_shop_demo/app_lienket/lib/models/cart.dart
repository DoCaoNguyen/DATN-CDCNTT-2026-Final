import 'package:flutter/material.dart';
import 'product.dart';

class CartProvider {
  // Biến trạng thái toàn cục đơn giản cho Giỏ hàng
  static final ValueNotifier<List<Product>> items = ValueNotifier([]);

  static void addToCart(Product product) {
    items.value = [...items.value, product];
  }

  static void removeFromCart(Product product) {
    final newList = List<Product>.from(items.value);
    newList.remove(product); // Xóa 1 instance
    items.value = newList;
  }

  static double get totalAmount {
    return items.value.fold(0, (sum, item) => sum + item.price);
  }
  
  static void clear() {
    items.value = [];
  }
}
