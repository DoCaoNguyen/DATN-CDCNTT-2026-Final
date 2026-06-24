import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/services/custom_http_client.dart';
import '../../../core/constants/api_config.dart';

class QrReceiveTab extends StatefulWidget {
  final bool isLoading;
  final String fullName;
  final String phone;

  const QrReceiveTab({
    Key? key,
    required this.isLoading,
    required this.fullName,
    required this.phone,
  }) : super(key: key);

  @override
  State<QrReceiveTab> createState() => _QrReceiveTabState();
}

class _QrReceiveTabState extends State<QrReceiveTab> {
  final _client = CustomHttpClient();
  String? _customQrContent;
  int? _customAmount;
  String _customDescription = '';
  bool _isGeneratingQR = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFFF0F5),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.black,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Nhận tiền',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: widget.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.pink),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        children: [
                          // Khung trắng chứa mã QR
                          Container(
                            margin: const EdgeInsets.all(24),
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'mio',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.pink.shade700,
                                        fontWeight: FontWeight.bold,
                                        height: 1,
                                        fontSize: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Container(
                                      width: 1,
                                      height: 20,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'VietQR',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Container(
                                      width: 1,
                                      height: 20,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'napas 247',
                                      style: TextStyle(
                                        color: Colors.blue,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),

                                // QR: Hiển thị QR tuỳ chỉnh (nhận tiền) hoặc QR chuyển tiền mặc định
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    QrImageView(
                                      data:
                                          _customQrContent ??
                                          jsonEncode({
                                            "action": "TRANSFER",
                                            "phone": widget.phone,
                                            "name": widget.fullName,
                                          }),
                                      version: QrVersions.auto,
                                      size: 220.0,
                                      backgroundColor: Colors.white,
                                    ),
                                    if (_isGeneratingQR)
                                      Container(
                                        width: 220,
                                        height: 220,
                                        color: Colors.white.withValues(
                                          alpha: 0.8,
                                        ),
                                        child: const Center(
                                          child: CircularProgressIndicator(
                                            color: Colors.pink,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),

                                const SizedBox(height: 16),

                                if (_customAmount != null)
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.pink.shade50,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.pink.shade200,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '${_formatAmount(_customAmount!)}đ',
                                          style: const TextStyle(
                                            color: Colors.pink,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        GestureDetector(
                                          onTap: () => setState(() {
                                            _customAmount = null;
                                            _customQrContent = null;
                                            _customDescription = '';
                                          }),
                                          child: const Icon(
                                            Icons.close_rounded,
                                            size: 16,
                                            color: Colors.pink,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                GestureDetector(
                                  onTap: _showAmountBottomSheet,
                                  child: Text(
                                    _customAmount == null
                                        ? '+ Thêm số tiền'
                                        : 'Sửa số tiền',
                                    style: const TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Thẻ thông tin tài khoản bên dưới
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 24),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Tên người nhận',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                    Text(
                                      widget.fullName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                const Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Ngân hàng',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                    Text(
                                      'Mio',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Số tài khoản',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                    Text(
                                      widget.phone,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),

                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: Divider(height: 1),
                                ),

                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Expanded(
                                      child: Text(
                                        'Sao chép thông tin tài khoản nhận tiền của bạn',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ),
                                    TextButton.icon(
                                      onPressed: () {
                                        /* Logic Copy SĐT */
                                      },
                                      icon: const Icon(
                                        Icons.copy_rounded,
                                        size: 16,
                                        color: Colors.pink,
                                      ),
                                      label: const Text(
                                        'Sao chép',
                                        style: TextStyle(color: Colors.pink),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatAmount(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }

  void _showAmountBottomSheet() {
    final amountController = TextEditingController(
      text: _customAmount != null ? _formatAmount(_customAmount!) : '',
    );
    final noteController = TextEditingController(text: _customDescription);
    String? sheetAmountError;
    int noteLength = _customDescription.length;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 4),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Title
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Tuỳ chỉnh số tiền',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 22),
                          onPressed: () => Navigator.pop(sheetCtx),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Amount field
                        TextField(
                          controller: amountController,
                          keyboardType: TextInputType.number,
                          autofocus: true,
                          decoration: InputDecoration(
                            labelText: 'Số tiền',
                            labelStyle: TextStyle(
                              color: sheetAmountError != null
                                  ? Colors.red
                                  : Colors.pink,
                              fontWeight: FontWeight.w500,
                            ),
                            hintText: '0đ',
                            suffix: amountController.text.isNotEmpty
                                ? GestureDetector(
                                    onTap: () {
                                      amountController.clear();
                                      setSheetState(
                                        () => sheetAmountError = null,
                                      );
                                    },
                                    child: const Icon(
                                      Icons.cancel_rounded,
                                      size: 18,
                                      color: Colors.grey,
                                    ),
                                  )
                                : null,
                            errorText: sheetAmountError,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Colors.pink,
                                width: 1.5,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Colors.red,
                                width: 1.5,
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Colors.red,
                                width: 1.5,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                          onChanged: (val) {
                            final digits = val.replaceAll('.', '');
                            final formatted = digits.isEmpty
                                ? ''
                                : int.tryParse(
                                        digits,
                                      )?.toString().replaceAllMapped(
                                        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                                        (m) => '${m[1]}.',
                                      ) ??
                                      val;
                            amountController.value = TextEditingValue(
                              text: formatted,
                              selection: TextSelection.collapsed(
                                offset: formatted.length,
                              ),
                            );
                            final raw =
                                int.tryParse(formatted.replaceAll('.', '')) ??
                                0;
                            setSheetState(() {
                              sheetAmountError =
                                  (formatted.isNotEmpty && raw < 1000)
                                  ? 'Số tiền tối thiểu 1.000đ'
                                  : null;
                            });
                          },
                        ),

                        const SizedBox(height: 16),

                        // Note field
                        TextField(
                          controller: noteController,
                          maxLength: 50,
                          decoration: InputDecoration(
                            labelText: 'Lời nhắn-Slogan (${noteLength}/50)',
                            labelStyle: const TextStyle(
                              color: Colors.grey,
                              fontSize: 13,
                            ),
                            hintText: 'Nhập lời nhắn',
                            hintStyle: const TextStyle(color: Colors.grey),
                            counterText: '',
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Colors.pink,
                                width: 1.5,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                          onChanged: (val) =>
                              setSheetState(() => noteLength = val.length),
                        ),

                        const SizedBox(height: 12),

                        // Quick note chips
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children:
                              [
                                    'Chuyển tiền cho mình nhé',
                                    'Tiền nước',
                                    'Tiền cơm trưa',
                                  ]
                                  .map(
                                    (label) => GestureDetector(
                                      onTap: () {
                                        noteController.text = label;
                                        setSheetState(
                                          () => noteLength = label.length,
                                        );
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 7,
                                        ),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.grey.shade300,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          color: Colors.grey.shade50,
                                        ),
                                        child: Text(
                                          label,
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                        ),

                        const SizedBox(height: 20),

                        // Buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  amountController.clear();
                                  noteController.clear();
                                  setSheetState(() {
                                    sheetAmountError = null;
                                    noteLength = 0;
                                  });
                                },
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: Colors.grey.shade300),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                ),
                                child: const Text(
                                  'Xóa tất cả',
                                  style: TextStyle(color: Colors.black54),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed:
                                    sheetAmountError != null ||
                                        amountController.text.isEmpty
                                    ? null
                                    : () async {
                                        final rawAmount = int.parse(
                                          amountController.text.replaceAll(
                                            '.',
                                            '',
                                          ),
                                        );
                                        final note = noteController.text;
                                        Navigator.pop(sheetCtx);
                                        await _createRequestMoneyQR(
                                          rawAmount,
                                          note,
                                        );
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.pink,
                                  disabledBackgroundColor: Colors.grey.shade300,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  'Lưu',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _createRequestMoneyQR(int amount, String description) async {
    setState(() => _isGeneratingQR = true);

    try {
      final response = await _client.post(
        Uri.parse(ApiConfig.requestMoneyQR),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'amount': amount, 'description': description}),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body)['data'];
        setState(() {
          _customQrContent = data['qr_content'];
          _customAmount = amount;
          _customDescription = description;
          _isGeneratingQR = false;
        });
      } else {
        setState(() => _isGeneratingQR = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                jsonDecode(response.body)['error'] ?? 'Tạo QR thất bại',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isGeneratingQR = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lỗi kết nối. Vui lòng thử lại.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
