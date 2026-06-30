import 'package:flutter/material.dart';
import 'screens/shop_screen.dart';
import 'dart:async';
import 'package:app_links/app_links.dart';

void main() {
  runApp(const TikTokShopApp());
}

class TikTokShopApp extends StatelessWidget {
  const TikTokShopApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TikTok Shop Clone',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFFfe2c55),
        scaffoldBackgroundColor: Colors.black,
        fontFamily: 'ProximaNova', // Sử dụng font mặc định hoặc thêm sau
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: const Color(0xFFfe2c55),
          secondary: const Color(0xFF25f4ee),
        ),
      ),
      home: const MainNavigation(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({Key? key}) : super(key: key);

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 1; // Mặc định mở tab Shop
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  void _initDeepLinks() {
    _appLinks = AppLinks();
    
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      if (uri.scheme == 'tiktokshop' && uri.host == 'payment-result') {
        final status = uri.queryParameters['status'];
        final orderCode = uri.queryParameters['order_code'];
        
        if (!mounted) return;
        
        if (status == 'success') {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Thanh toán thành công 🎉'),
              content: Text('Đơn hàng $orderCode đã được thanh toán qua Ví Mio.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Đóng'),
                ),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Thanh toán thất bại hoặc đã bị hủy!')),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  // Các trang tạm thời để hiển thị khi chuyển tab
  final List<Widget> _screens = [
    const Center(child: Text('Home (For You)', style: TextStyle(color: Colors.white, fontSize: 24))),
    const ShopScreen(),
    const Center(child: Text('Inbox', style: TextStyle(color: Colors.white, fontSize: 24))),
    const Center(child: Text('Profile', style: TextStyle(color: Colors.white, fontSize: 24))),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Nếu tab Shop đang mở thì navbar có thể sáng màu hoặc ngược lại.
    // TikTok thường dùng navbar đen.
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          canvasColor: Colors.black, // Màu nền đen cho bottom nav
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          backgroundColor: Colors.black,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.grey.shade600,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedFontSize: 10,
          unselectedFontSize: 10,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Trang chủ',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_bag_outlined),
              activeIcon: Icon(Icons.shopping_bag),
              label: 'Shop',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              activeIcon: Icon(Icons.chat_bubble),
              label: 'Hộp thư',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Hồ sơ',
            ),
          ],
        ),
      ),
    );
  }
}
