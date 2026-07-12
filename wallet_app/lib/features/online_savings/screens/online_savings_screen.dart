import 'package:flutter/material.dart';
import 'savings_deposit_screen.dart';

class OnlineSavingsScreen extends StatefulWidget {
  const OnlineSavingsScreen({Key? key}) : super(key: key);

  @override
  _OnlineSavingsScreenState createState() => _OnlineSavingsScreenState();
}

class _OnlineSavingsScreenState extends State<OnlineSavingsScreen> {
  int _selectedTermIndex = 2; // Default to 6 tháng
  final List<String> _terms = [
    '1 tháng',
    '3 tháng',
    '6 tháng',
    '9 tháng',
    '12 tháng',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFEBF5),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Tiết Kiệm Online',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.star_border, color: Colors.black87),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(
              Icons.support_agent_outlined,
              color: Colors.black87,
            ),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.home_outlined, color: Colors.black87),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildTopBanner(),
            _buildCalculatorSection(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBanner() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFEBF5), Color(0xFFF7F8FA)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0.0, 1.0],
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFFB6D9), width: 1.5),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.stars, color: Color(0xFFD81B60), size: 16),
                const SizedBox(width: 4),
                Text(
                  'Gửi Tiết kiệm với MoMo',
                  style: TextStyle(
                    color: const Color(0xFFD81B60).withOpacity(0.8),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildBenefitItem(Icons.security, 'An toàn bảo mật\nbởi NHNN'),
                _buildBenefitItem(
                  Icons.trending_up,
                  'Lãi suất hấp dẫn\nđến 7%',
                ),
                _buildBenefitItem(Icons.payments, 'Rút trước hạn\nlinh hoạt'),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SavingsDepositScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE91E63),
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Mở sổ tiết kiệm ngay',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  size: 14,
                  color: Colors.black54,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Sổ tiết kiệm được mở tại Ngân hàng MB, MBV, Bản Việt và bảo đảm bởi Ngân hàng nhà nước Việt Nam',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitItem(IconData icon, String text) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF5FA),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.pinkAccent.shade200, size: 28),
            const SizedBox(height: 8),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.black87,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalculatorSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tính thử tiền lãi',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Nhập số tiền bạn muốn gửi',
            style: TextStyle(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    '50.000.000',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  'đ',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Chọn kỳ hạn',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(_terms.length, (index) {
                final isSelected = index == _selectedTermIndex;
                return GestureDetector(
                  onTap: () => setState(() => _selectedTermIndex = index),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFFFF0F6)
                          : Colors.white,
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFE91E63)
                            : Colors.grey.shade300,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _terms[index],
                      style: TextStyle(
                        color: isSelected
                            ? const Color(0xFFE91E63)
                            : Colors.black87,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: const Color(0xFFFFB6D9).withOpacity(0.5),
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
                  child: Text(
                    'Lãi suất các ngân hàng (%/năm)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                _buildBankRateItem(
                  'MBV Bank',
                  '7%',
                  '+1.764.384đ',
                  Colors.redAccent,
                ),
                Divider(
                  height: 1,
                  color: Colors.grey.shade200,
                  indent: 16,
                  endIndent: 16,
                ),
                _buildBankRateItem(
                  'Bản Việt Bank',
                  '6,5%',
                  '+1.638.356đ',
                  Colors.blue,
                ),
                Divider(
                  height: 1,
                  color: Colors.grey.shade200,
                  indent: 16,
                  endIndent: 16,
                ),
                _buildBankRateItem(
                  'MB Bank',
                  '5,7%',
                  '+1.436.712đ',
                  Colors.blue.shade800,
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFF0F6),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.stars, color: Colors.grey, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Thêm Túi+ nhận thêm lên đến 0,5% lãi suất',
                        style: TextStyle(
                          color: const Color(0xFFD81B60).withOpacity(0.8),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.chevron_right,
                        color: const Color(0xFFD81B60).withOpacity(0.8),
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          RichText(
            text: TextSpan(
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              children: const [
                TextSpan(
                  text: 'Xem chi tiết bảng so sánh lãi suất các ngân hàng. ',
                ),
                TextSpan(
                  text: 'Tại đây.',
                  style: TextStyle(color: Color(0xFFD81B60)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBankRateItem(
    String bankName,
    String rate,
    String profit,
    Color bankColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: bankColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.account_balance, color: bankColor, size: 18),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                bankName,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 2),
              Text(
                rate,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            profit,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF00A651),
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, color: Colors.black54, size: 18),
        ],
      ),
    );
  }
}
