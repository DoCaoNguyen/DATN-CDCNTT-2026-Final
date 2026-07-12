import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'savings_confirm_screen.dart';

class SavingsDepositScreen extends StatefulWidget {
  const SavingsDepositScreen({Key? key}) : super(key: key);

  @override
  _SavingsDepositScreenState createState() => _SavingsDepositScreenState();
}

class _SavingsDepositScreenState extends State<SavingsDepositScreen> {
  final TextEditingController _amountController = TextEditingController();
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'đ',
  );

  int _selectedTermMonths = 1;
  int _selectedBankIndex = 2; // Default to Bản Việt Bank
  bool _isAgreed = false;

  String _rawAmount = '';

  final List<int> _terms = [1, 2, 3, 4, 6, 9, 12, 24];

  final List<Map<String, dynamic>> _banks = [
    {
      'name': 'MBV Bank',
      'rate': 4.75,
      'minAmount': 1000000,
      'code': 'MBV',
      'color': const Color(0xFFB71C1C),
    },
    {
      'name': 'MB Bank',
      'rate': 4.5,
      'minAmount': 1000000,
      'code': 'MB',
      'color': const Color(0xFF0D47A1),
    },
    {
      'name': 'Bản Việt Bank',
      'rate': 4.25,
      'minAmount': 500000,
      'code': 'BVB',
      'color': const Color(0xFF01579B),
    },
  ];

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_onAmountChanged);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _onAmountChanged() {
    // Remove non-digit characters to get raw amount
    String text = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (text.isEmpty) {
      setState(() => _rawAmount = '');
      return;
    }

    // Format back with dots
    final formatted = NumberFormat('#,###', 'vi_VN').format(int.parse(text));
    if (formatted != _amountController.text) {
      _amountController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
    setState(() {
      _rawAmount = text;
    });
  }

  double get _currentAmount {
    return _rawAmount.isEmpty ? 0 : double.parse(_rawAmount);
  }

  double get _currentProfit {
    if (_currentAmount <= 0) return 0;
    double rate = _banks[_selectedBankIndex]['rate'] / 100.0;
    // Simple interest calculation: Amount * (Rate / 12) * Months
    return _currentAmount * (rate / 12) * _selectedTermMonths;
  }

  String? get _errorMessage {
    if (_currentAmount <= 0) return null;
    double minAmount = _banks[_selectedBankIndex]['minAmount'].toDouble();
    if (_currentAmount < minAmount) {
      String minStr = _currencyFormat.format(minAmount);
      return 'Số tiền gửi tối thiểu với ${_banks[_selectedBankIndex]['name']} là $minStr.';
    }
    return null;
  }

  bool get _isValid {
    return _currentAmount > 0 && _errorMessage == null && _isAgreed;
  }

  void _onQuickAmountSelected(int amount) {
    _amountController.text = amount.toString(); // The listener will format it
  }

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
          'Gửi Tiết Kiệm Online',
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
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFFFEBF5), Color(0xFFF7F8FA)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [0.0, 1.0],
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: _buildInputCard(),
                  ),
                  const SizedBox(height: 16),
                  _buildPackageSection(),
                  const SizedBox(height: 16),
                  _buildMethodSection(),
                  const SizedBox(height: 24),
                  _buildAgreementSection(),
                ],
              ),
            ),
          ),
          _buildBottomAction(),
        ],
      ),
    );
  }

  Widget _buildInputCard() {
    bool hasError = _errorMessage != null;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(
                color: hasError ? Colors.red : const Color(0xFFD81B60),
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Số tiền gửi tiết kiệm',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Nhập số tiền',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade400,
                            fontWeight: FontWeight.normal,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          suffixText: 'đ',
                          suffixStyle: const TextStyle(
                            fontSize: 22,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                    if (_rawAmount.isNotEmpty)
                      GestureDetector(
                        onTap: () => _amountController.clear(),
                        child: const Icon(
                          Icons.cancel,
                          color: Colors.grey,
                          size: 20,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (hasError)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.red, size: 16),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text(
                'Lãi khi đáo hạn: ',
                style: TextStyle(fontSize: 14, color: Colors.black87),
              ),
              Text(
                _currentProfit > 0
                    ? '+${_currencyFormat.format(_currentProfit.floor())}'
                    : '0đ',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00A651),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPackageSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Gói tiết kiệm',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Chọn kỳ hạn gửi và ngân hàng',
            style: TextStyle(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _terms.map((term) {
                bool isSelected = term == _selectedTermMonths;
                return GestureDetector(
                  onTap: () => setState(() => _selectedTermMonths = term),
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
                      '$term tháng',
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
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          Column(
            children: List.generate(_banks.length, (index) {
              final bank = _banks[index];
              final isSelected = index == _selectedBankIndex;
              return GestureDetector(
                onTap: () => setState(() => _selectedBankIndex = index),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFFE91E63)
                          : Colors.grey.shade300,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.network(
                            'https://api.vietqr.io/img/${bank['code']}.png',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  color: bank['color'].withOpacity(0.1),
                                  alignment: Alignment.center,
                                  child: Text(
                                    bank['code'],
                                    style: TextStyle(
                                      color: bank['color'],
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${bank['rate']}%',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            bank['name'],
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Phương thức đáo hạn',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text(
                'Gửi tiếp cả tiền gốc và lãi',
                style: TextStyle(fontSize: 15, color: Colors.black87),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.info_outline,
                size: 16,
                color: const Color(0xFFD81B60).withOpacity(0.6),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAgreementSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: _isAgreed,
              onChanged: (val) => setState(() => _isAgreed = val ?? false),
              activeColor: const Color(0xFFE91E63),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
                children: [
                  const TextSpan(
                    text: 'Tôi đã đọc và đồng ý với các nội dung của ',
                  ),
                  const TextSpan(
                    text:
                        'Sản phẩm tiền gửi có kỳ hạn, Bảo vệ & xử lý dữ liệu cá nhân',
                    style: TextStyle(color: Colors.blue),
                  ),
                  TextSpan(text: ' của ${_banks[_selectedBankIndex]['name']}.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildQuickAmountChip(100000),
                  _buildQuickAmountChip(500000),
                  _buildQuickAmountChip(1000000),
                  _buildQuickAmountChip(5000000),
                  _buildQuickAmountChip(10000000),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _isValid
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SavingsConfirmScreen(
                            bankName: _banks[_selectedBankIndex]['name'],
                            bankCode: _banks[_selectedBankIndex]['code'],
                            amount: _currentAmount,
                            term: _selectedTermMonths,
                            rate: _banks[_selectedBankIndex]['rate'],
                            profit: _currentProfit,
                          ),
                        ),
                      );
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE91E63),
                disabledBackgroundColor: Colors.grey.shade300,
                disabledForegroundColor: Colors.grey.shade500,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Tiếp tục',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAmountChip(int amount) {
    return GestureDetector(
      onTap: () => _onQuickAmountSelected(amount),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          NumberFormat('#,###', 'vi_VN').format(amount) + 'đ',
          style: const TextStyle(fontSize: 13, color: Colors.black87),
        ),
      ),
    );
  }
}
