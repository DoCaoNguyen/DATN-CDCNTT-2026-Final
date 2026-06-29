import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/product.dart';
import '../models/cart.dart';
import 'wallet_auth_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/mio_payment_service.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';

class CheckoutScreen extends StatefulWidget {
  final List<Product> products;

  const CheckoutScreen({Key? key, required this.products}) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  String _selectedPaymentMethod = 'Thanh toán khi nhận hàng (COD)';
  
  // Trạng thái liên kết của các ví/thẻ. null = chưa liên kết, String = đã liên kết (chứa số điện thoại/số thẻ ẩn)
  final Map<String, String?> _linkedMethods = {
    'ZaloPay': null,
    'MoMo': null,
    'Thẻ tín dụng/Ghi nợ': null,
  };

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  void _initDeepLinks() {
    _appLinks = AppLinks();
    
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      if (uri.scheme == 'tiktokshop' && uri.host == 'link-result') {
        final status = uri.queryParameters['status'];
        final phone = uri.queryParameters['phone'] ?? '*******089';
        
        if (!mounted) return;
        
        if (status == 'success') {
          setState(() {
            _linkedMethods['MoMo'] = phone;
            _selectedPaymentMethod = 'MoMo';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã liên kết Ví Mio (MoMo) thành công!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Liên kết Ví Mio thất bại hoặc đã bị hủy!')),
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

  void _showPaymentMethodSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            Widget buildOption(String title, IconData icon, {Color? color, bool requiresLinking = false}) {
              String? linkedAccount = requiresLinking ? _linkedMethods[title] : '';
              bool isLinked = !requiresLinking || (linkedAccount != null);

              return ListTile(
                leading: Icon(icon, color: color ?? Colors.green),
                title: Text(title, style: TextStyle(color: isLinked ? Colors.black : Colors.grey.shade700)),
                subtitle: isLinked && requiresLinking
                    ? Text(linkedAccount ?? '', style: const TextStyle(fontSize: 12, color: Colors.grey))
                    : null,
                trailing: !isLinked
                    ? TextButton(
                        onPressed: () async {
                          // Đóng BottomSheet tạm thời để mở trang chuyển hướng
                          Navigator.pop(context);

                          if (title == 'MoMo') {
                            final url = Uri.parse('mio://link?merchant=tiktokshop');
                            try {
                              await launchUrl(url, mode: LaunchMode.externalApplication);
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(this.context).showSnackBar(
                                  const SnackBar(content: Text('Vui lòng cài đặt ứng dụng Ví Mio để liên kết.')),
                                );
                              }
                            }
                            return; // Dừng ở đây để chờ deep link callback
                          }

                          // Giả lập mở app ZaloPay/Thẻ
                          final bool? result = await Navigator.push(
                            this.context,
                            MaterialPageRoute(
                              builder: (context) => WalletAuthScreen(
                                walletName: title,
                                themeColor: color ?? Colors.blue,
                              ),
                            ),
                          );

                          if (result == true) {
                            setState(() {
                              _linkedMethods[title] = '*******089'; // Giả lập số điện thoại đã che
                              _selectedPaymentMethod = title; // Tự động chọn luôn sau khi liên kết
                            });
                            if (mounted) {
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                SnackBar(content: Text('Đã liên kết $title thành công!')),
                              );
                            }
                          }
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.grey.shade200,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          minimumSize: Size.zero,
                        ),
                        child: const Text('Liên kết', style: TextStyle(color: Color(0xFFfe2c55), fontSize: 13)),
                      )
                    : (_selectedPaymentMethod == title 
                        ? const Icon(Icons.check_circle, color: Color(0xFFfe2c55)) 
                        : const Icon(Icons.circle_outlined, color: Colors.grey)),
                onTap: isLinked
                    ? () {
                        setState(() {
                          _selectedPaymentMethod = title;
                        });
                        Navigator.pop(context);
                      }
                    : null, // Không cho bấm chọn nếu chưa liên kết (phải bấm nút liên kết)
              );
            }

            return Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text('Chọn phương thức thanh toán', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 16),
                  buildOption('Thanh toán khi nhận hàng (COD)', Icons.money),
                  buildOption('ZaloPay', Icons.account_balance_wallet, color: Colors.blue, requiresLinking: true),
                  buildOption('MoMo', Icons.account_balance_wallet, color: Colors.pink, requiresLinking: true),
                  buildOption('Thẻ tín dụng/Ghi nợ', Icons.credit_card, color: Colors.orange, requiresLinking: true),
                ],
              ),
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final double shippingFee = 30000;
    
    final double subTotal = widget.products.fold(0, (sum, item) => sum + item.price);
    final double grandTotal = subTotal > 0 ? subTotal + shippingFee : 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Xác nhận Đơn hàng', style: TextStyle(color: Colors.black, fontSize: 18)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0.5,
      ),
      body: widget.products.isEmpty 
          ? const Center(child: Text("Đơn hàng rỗng"))
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Address Section
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(16.0),
                    margin: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on, color: Color(0xFFfe2c55)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text('Địa chỉ nhận hàng', style: TextStyle(fontWeight: FontWeight.bold)),
                              SizedBox(height: 4),
                              Text('Nguyễn Văn A (+84) 901234567\n123 Đường Cầu Giấy, Phường Quan Hoa, Quận Cầu Giấy, Hà Nội', style: TextStyle(fontSize: 13)),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.grey),
                      ],
                    ),
                  ),
                  
                  // Product Info Section
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(16.0),
                    margin: const EdgeInsets.only(bottom: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.store, size: 20),
                            SizedBox(width: 8),
                            Text('TikTok Shop Official', style: TextStyle(fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...widget.products.map((product) => Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Image.network(
                                  product.imageUrl,
                                  width: 70,
                                  height: 70,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product.name,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          currencyFormatter.format(product.price),
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                        ),
                                        Text('x1', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                                      ],
                                    ),
                                  ],
                                ),
                              )
                            ],
                          ),
                        )).toList(),
                      ],
                    ),
                  ),

                  // Payment method
                  GestureDetector(
                    onTap: _showPaymentMethodSheet,
                    child: Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(16.0),
                      margin: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          const Icon(Icons.payment, color: Colors.orange, size: 20),
                          const SizedBox(width: 8),
                          const Text('Phương thức thanh toán', style: TextStyle(fontSize: 14)),
                          const Spacer(),
                          Expanded(
                            child: Text(
                              _selectedPaymentMethod, 
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                              textAlign: TextAlign.right,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),

                  // Order summary
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Tạm tính', style: TextStyle(color: Colors.grey, fontSize: 14)),
                            Text(currencyFormatter.format(subTotal), style: const TextStyle(fontSize: 14)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Phí vận chuyển', style: TextStyle(color: Colors.grey, fontSize: 14)),
                            Text(currencyFormatter.format(shippingFee), style: const TextStyle(fontSize: 14)),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Tổng cộng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            Text(
                              currencyFormatter.format(grandTotal),
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFfe2c55), fontSize: 17),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
      bottomSheet: widget.products.isEmpty ? null : Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, -3),
            )
          ]
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tổng thanh toán', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text(
                      currencyFormatter.format(grandTotal),
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFfe2c55), fontSize: 18),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (_selectedPaymentMethod == 'MoMo') {
                    final qrCodeUri = await MioPaymentService.createOrder(
                      amount: grandTotal,
                      description: 'Thanh toán đơn hàng TikTok Shop',
                      merchantOrderId: 'TTS_${DateTime.now().millisecondsSinceEpoch}',
                    );
                    
                    if (qrCodeUri != null) {
                      final url = Uri.parse(qrCodeUri);
                      try {
                        await launchUrl(url, mode: LaunchMode.externalApplication);
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Vui lòng cài đặt ứng dụng Ví Mio để thanh toán.')),
                        );
                      }
                    } else {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Lỗi tạo đơn hàng thanh toán.')),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Đặt hàng thành công bằng $_selectedPaymentMethod!')),
                    );
                    CartProvider.clear(); 
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFfe2c55),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
                child: const Text('Đặt hàng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
              )
            ],
          ),
        ),
      ),
    );
  }
}
