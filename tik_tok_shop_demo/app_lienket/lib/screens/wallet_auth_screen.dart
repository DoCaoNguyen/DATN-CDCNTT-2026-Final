import 'package:flutter/material.dart';

class WalletAuthScreen extends StatefulWidget {
  final String walletName;
  final Color themeColor;

  const WalletAuthScreen({Key? key, required this.walletName, required this.themeColor}) : super(key: key);

  @override
  State<WalletAuthScreen> createState() => _WalletAuthScreenState();
}

class _WalletAuthScreenState extends State<WalletAuthScreen> {
  bool _isLoading = false;

  void _confirmLinking() async {
    setState(() {
      _isLoading = true;
    });
    // Giả lập thời gian xử lý API
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      Navigator.pop(context, true); // Trả về true khi liên kết thành công
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: widget.themeColor,
        elevation: 0,
        title: Text(widget.walletName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context, false), // Hủy liên kết
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: widget.themeColor,
            padding: const EdgeInsets.only(bottom: 24, top: 12),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.account_balance_wallet, size: 40, color: widget.themeColor),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Xác nhận liên kết dịch vụ',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            color: Colors.black,
                            width: 40,
                            height: 40,
                            alignment: Alignment.center,
                            child: const Icon(Icons.shopping_bag, color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'TikTok Shop',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Bằng việc xác nhận, bạn cho phép TikTok Shop tự động trích tiền từ tài khoản của bạn cho các giao dịch thanh toán mua sắm mà không cần xác thực lại (OTP/Mật khẩu) ở những lần sau.',
                      style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.4),
                    ),
                    const Divider(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Nguồn tiền mặc định:', style: TextStyle(color: Colors.grey)),
                        Text('Số dư ví ${widget.walletName}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _confirmLinking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.themeColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Xác nhận',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
