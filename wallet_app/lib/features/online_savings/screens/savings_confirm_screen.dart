import 'package:flutter/material.dart';

class SavingsConfirmScreen extends StatefulWidget {
  final String bankName;
  final String bankCode;
  final double amount;
  final int term;
  final double rate;
  final double profit;

  const SavingsConfirmScreen({
    Key? key,
    required this.bankName,
    required this.bankCode,
    required this.amount,
    required this.term,
    required this.rate,
    required this.profit,
  }) : super(key: key);

  @override
  _SavingsConfirmScreenState createState() => _SavingsConfirmScreenState();
}

class _SavingsConfirmScreenState extends State<SavingsConfirmScreen> {
  int _gender = 0; // 0 = Nam, 1 = Nữ
  bool _isConfirmed = false;

  final TextEditingController _emailController = TextEditingController(
    text: 'gfffccvgg86cvgg@gmail.com',
  );
  final TextEditingController _addressController = TextEditingController(
    text: 'BẮC HÒA, HUYỆN TÂN THẠNH, TỈNH LONG AN',
  );

  @override
  void dispose() {
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
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
          'Xác nhận thông tin',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
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
                    child: _buildBankHeader(),
                  ),
                  const SizedBox(height: 16),
                  _buildRegisteredInfo(),
                  const SizedBox(height: 16),
                  _buildAdditionalInfo(),
                  const SizedBox(height: 24),
                  _buildConfirmationCheck(),
                ],
              ),
            ),
          ),
          _buildBottomAction(),
        ],
      ),
    );
  }

  Widget _buildBankHeader() {
    return Container(
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
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(
                'https://api.vietqr.io/img/${widget.bankCode}.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.blue.withOpacity(0.1),
                  alignment: Alignment.center,
                  child: Text(
                    widget.bankCode,
                    style: const TextStyle(
                      color: Colors.blue,
                      fontSize: 12,
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
                widget.bankName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Ngân hàng ${widget.bankName.replaceAll(' Bank', '')}',
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRegisteredInfo() {
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
            'Thông tin đăng ký',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Họ và tên', 'Phan Văn Thống'),
          const Divider(height: 24, color: Color(0xFFF0F0F0)),
          _buildInfoRow('Ngày sinh', '05/07/2005'),
          const Divider(height: 24, color: Color(0xFFF0F0F0)),
          _buildInfoRow('Số CMND/CCCD', '080205015346'),
          const Divider(height: 24, color: Color(0xFFF0F0F0)),
          _buildInfoRow('Số điện thoại', '0855313437'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.black54),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildAdditionalInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFEBF5), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bạn cần bổ sung thông tin',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text(
                'Giới tính',
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const Spacer(),
              Row(
                children: [
                  Radio<int>(
                    value: 0,
                    groupValue: _gender,
                    onChanged: (val) => setState(() => _gender = val!),
                    activeColor: const Color(0xFFE91E63),
                    visualDensity: VisualDensity.compact,
                  ),
                  const Text(
                    'Nam',
                    style: TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                  const SizedBox(width: 16),
                  Radio<int>(
                    value: 1,
                    groupValue: _gender,
                    onChanged: (val) => setState(() => _gender = val!),
                    activeColor: const Color(0xFFE91E63),
                    visualDensity: VisualDensity.compact,
                  ),
                  const Text(
                    'Nữ',
                    style: TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email*',
                labelStyle: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                ),
                border: InputBorder.none,
                isDense: true,
              ),
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextField(
              controller: _addressController,
              decoration: InputDecoration(
                labelText: 'Địa chỉ*',
                labelStyle: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                ),
                border: InputBorder.none,
                isDense: true,
              ),
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationCheck() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: _isConfirmed,
              onChanged: (val) => setState(() => _isConfirmed = val ?? false),
              activeColor: const Color(0xFFE91E63),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Tôi xác nhận thông tin trên là hoàn toàn chính xác và chịu trách nhiệm về các thông tin này. Tôi đồng ý cung cấp cho ${widget.bankName} để thực hiện việc gửi tiết kiệm.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
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
      child: ElevatedButton(
        onPressed: _isConfirmed
            ? () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tạo sổ tiết kiệm thành công!')),
                );
                Navigator.popUntil(context, (route) => route.isFirst);
              }
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE91E63),
          disabledBackgroundColor: Colors.grey.shade300,
          disabledForegroundColor: Colors.grey.shade500,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
        child: const Text(
          'Xác nhận',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
