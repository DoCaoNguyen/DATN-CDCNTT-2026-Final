import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'transfer_confirm_screen.dart';

class TransferAmountScreen extends StatefulWidget {
  final String token;
  final String receiverName;
  final String receiverPhone;
  final String? amount;
  final String? note;
  final bool isFixed;

  const TransferAmountScreen({
    Key? key,
    required this.token,
    required this.receiverName,
    required this.receiverPhone,
    this.amount,
    this.note,
    this.isFixed = false,
  }) : super(key: key);

  @override
  State<TransferAmountScreen> createState() => _TransferAmountScreenState();
}

class _TransferAmountScreenState extends State<TransferAmountScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  String? _amountError;

  final FocusNode _amountFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    if (widget.amount != null) {
      final cleanedAmount = widget.amount!.replaceAll(RegExp(r'[^\d]'), '');
      _amountController.text = _formatAmount(cleanedAmount);
    }
    if (widget.note != null) {
      _noteController.text = widget.note!;
    }
    _amountFocusNode.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  String _formatAmount(String value) {
    if (value.isEmpty) return '';
    final number = int.tryParse(value.replaceAll('.', ''));
    if (number == null) return '';
    return number
        .toString()
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  void _goToConfirmScreen() {
    if (_amountController.text.isEmpty) return;
    final rawAmount = _amountController.text.replaceAll('.', '');
    final intAmount = int.tryParse(rawAmount) ?? 0;
    if (intAmount < 1000) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TransferConfirmScreen(
          token: widget.token,
          receiverName: widget.receiverName,
          receiverPhone: widget.receiverPhone,
          amount: rawAmount,
          note: _noteController.text.isNotEmpty
              ? _noteController.text
              : 'Chuyển tiền',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool hasAmount = _amountController.text.isNotEmpty;
    final bool isButtonEnabled = hasAmount && _amountError == null;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF0F5),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.receiverName,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              widget.receiverPhone,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF0F5), Color(0xFFF5F5F9)],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    // Card nhập liệu
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Trường số tiền: Sử dụng prefix/suffix hoặc Stack để chữ "đ" đi sát sau số tiền thay vì nằm ở góc phải
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              // Ẩn TextField đằng sau nhưng nó vẫn bắt sự kiện và nhận giá trị
                              Opacity(
                                opacity: 0,
                                child: TextField(
                                  controller: _amountController,
                                  focusNode: _amountFocusNode,
                                  autofocus: !widget.isFixed,
                                  readOnly: widget.isFixed,
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                  onChanged: (val) {
                                    if (widget.isFixed) return;
                                    String cleanVal = val.replaceAll(RegExp(r'[^0-9]'), '');
                                    if (cleanVal.length > 8) {
                                      cleanVal = cleanVal.substring(0, 8);
                                    }
                                    final formatted = _formatAmount(cleanVal);
                                    _amountController.value = TextEditingValue(
                                      text: formatted,
                                      selection: TextSelection.collapsed(offset: formatted.length),
                                    );
                                    setState(() {
                                      final rawAmount = formatted.replaceAll('.', '');
                                      final intAmount = int.tryParse(rawAmount) ?? 0;
                                      if (rawAmount.isNotEmpty && intAmount < 1000) {
                                        _amountError = 'Số tiền chuyển tối thiểu là 1.000đ';
                                      } else if (intAmount > 50000000) {
                                        _amountError = 'Số tiền chuyển tối đa là 50.000.000đ/ngày';
                                      } else {
                                        _amountError = null;
                                      }
                                    });
                                  },
                                ),
                              ),
                              // Dùng GestureDetector để khi click vào Text thì focus vào TextField ẩn phía dưới
                              GestureDetector(
                                onTap: () {
                                  if (!widget.isFixed) {
                                    _amountFocusNode.requestFocus();
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.only(bottom: 2),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: _amountError != null
                                            ? const Color(0xFFD32F2F)
                                            : (_amountFocusNode.hasFocus ? Colors.pink : Colors.grey.shade300),
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        hasAmount ? _amountController.text : '0',
                                        style: TextStyle(
                                          fontSize: 40,
                                          fontWeight: FontWeight.bold,
                                          color: _amountError != null
                                              ? const Color(0xFFD32F2F)
                                              : (hasAmount ? Colors.black : Colors.grey),
                                        ),
                                      ),
                                      if (_amountFocusNode.hasFocus)
                                        const FlashingCursor(),
                                      const SizedBox(width: 4),
                                      Text(
                                        'đ',
                                        style: TextStyle(
                                          fontSize: 38,
                                          fontWeight: FontWeight.bold,
                                          color: _amountError != null
                                              ? const Color(0xFFD32F2F)
                                              : (hasAmount ? Colors.black : Colors.grey),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),

                          if (_amountError != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0, bottom: 8.0),
                              child: Text(
                                _amountError!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFFD32F2F),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),

                          const SizedBox(height: 12),

                          // Lời nhắn:
                          TextField(
                            controller: _noteController,
                            readOnly: widget.isFixed,
                            decoration: InputDecoration(
                              hintText: widget.isFixed ? '' : 'Nhập hoặc chọn bên dưới',
                              hintStyle:
                                  const TextStyle(color: Colors.grey, fontSize: 14),
                              labelText: 'Lời nhắn',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                            ),
                            style: const TextStyle(color: Colors.black),
                          ),

                          // Các gợi ý tin nhắn nhanh (chỉ khi !isFixed)
                          if (!widget.isFixed) ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: Wrap(
                                alignment: WrapAlignment.start,
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _buildQuickNote('Mình chuyển tiền nhé 💵'),
                                  _buildQuickNote('Em cảm ơn ạ! 💰'),
                                  _buildQuickNote('Em chuyển tiền nha 😻'),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Nút Chuyển tiền & các nút gợi ý số tiền nhanh
            SafeArea(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Color(0xFFEEEEEE), width: 1)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!widget.isFixed) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildQuickAmountBtn('50.000'),
                          _buildQuickAmountBtn('100.000'),
                          _buildQuickAmountBtn('200.000'),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isButtonEnabled ? _goToConfirmScreen : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isButtonEnabled ? Colors.pink : Colors.grey.shade300,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Chuyển tiền',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickNote(String text) {
    return GestureDetector(
      onTap: () => setState(() => _noteController.text = text),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 13, color: Colors.black87),
        ),
      ),
    );
  }

  Widget _buildQuickAmountBtn(String amount) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey.shade100,
        elevation: 0,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      onPressed: () {
        setState(() {
          _amountController.text = amount;
          _amountError = null;
        });
      },
      child: Text('${amount}đ'),
    );
  }
}

class FlashingCursor extends StatefulWidget {
  const FlashingCursor({Key? key}) : super(key: key);

  @override
  State<FlashingCursor> createState() => _FlashingCursorState();
}

class _FlashingCursorState extends State<FlashingCursor> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 1.0, end: 0.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Container(
        width: 2.0,
        height: 50.0,
        color: Colors.pink,
      ),
    );
  }
}