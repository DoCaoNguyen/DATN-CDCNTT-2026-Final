import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/api_config.dart';
import '../../../core/services/custom_http_client.dart';
import '../../../core/utils/snackbar_utils.dart';
import 'split_bill_confirm_screen.dart';

class SplitBillInputAmountScreen extends StatefulWidget {
  final String token;
  final Map<String, dynamic> transactionData;
  final Map<String, dynamic> me;
  final List<Map<String, dynamic>> selectedFriends;

  const SplitBillInputAmountScreen({
    Key? key,
    required this.token,
    required this.transactionData,
    required this.me,
    required this.selectedFriends,
  }) : super(key: key);

  @override
  State<SplitBillInputAmountScreen> createState() =>
      _SplitBillInputAmountScreenState();
}

class _SplitBillInputAmountScreenState
    extends State<SplitBillInputAmountScreen> {
  final TextEditingController _amountController = TextEditingController();
  final NumberFormat _formatter = NumberFormat('#,###', 'vi_VN');

  double _amount = 0;

  @override
  void initState() {
    super.initState();
    // Initialize with transaction amount if available
    if (widget.transactionData['amount'] != null) {
      double txAmount =
          double.tryParse(widget.transactionData['amount'].toString()) ?? 0;
      if (txAmount > 0) {
        _amount = txAmount;
        _amountController.text = _formatter.format(_amount);
      }
    }
  }

  int get _totalMembers => widget.selectedFriends.length + 1; // +1 for "Me"

  bool _isScanning = false;

  Future<void> _scanReceipt() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    setState(() {
      _isScanning = true;
    });

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/ai/scan-receipt'),
      );
      request.headers['Authorization'] = 'Bearer ${widget.token}';
      request.files.add(
        await http.MultipartFile.fromPath('image', pickedFile.path),
      );

      final client = CustomHttpClient();
      var response = await client.send(request);
      var responseData = await response.stream.bytesToString();
      var data = jsonDecode(responseData);

      if (response.statusCode == 200) {
        final double total =
            double.tryParse(data['data']['totalAmount'].toString()) ?? 0;
        if (total > 0) {
          _onAmountChanged(total.toInt().toString());
          SnackbarUtils.showSuccess(context, 'Đã quét thành công hóa đơn!');
        } else {
          SnackbarUtils.showError(
            context,
            'Không tìm thấy tổng tiền trên hóa đơn.',
          );
        }
      } else {
        SnackbarUtils.showError(
          context,
          data['error'] ?? 'Lỗi khi quét hóa đơn',
        );
      }
    } catch (e) {
      SnackbarUtils.showError(context, 'Có lỗi xảy ra: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    }
  }

  bool get _isButtonEnabled {
    if (_totalMembers == 0) return false;
    return (_amount / _totalMembers) > 1000;
  }

  void _onAmountChanged(String value) {
    String cleanVal = value.replaceAll('.', '');
    if (cleanVal.isEmpty) {
      setState(() {
        _amount = 0;
      });
      _amountController.clear();
      return;
    }

    double? val = double.tryParse(cleanVal);
    if (val != null) {
      setState(() {
        _amount = val;
      });

      String formatted = _formatter.format(val);
      _amountController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFFE4E1), Colors.white],
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.black87),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              "Chia tiền",
              style: TextStyle(
                color: Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.history_rounded, color: Colors.black54),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.home_rounded, color: Colors.black54),
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 60),
                  const Text(
                    "Nhập số tiền",
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IntrinsicWidth(
                        child: TextField(
                          controller: _amountController,
                          autofocus: true,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          onChanged: _onAmountChanged,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: "0",
                            hintStyle: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                      const Text(
                        "đ",
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      if (_amount > 0)
                        IconButton(
                          icon: const Icon(Icons.cancel, color: Colors.black54),
                          onPressed: () {
                            setState(() {
                              _amount = 0;
                            });
                            _amountController.clear();
                          },
                        ),
                    ],
                  ),
                  Container(
                    width: 200,
                    height: 2,
                    color: const Color(0xFFE91E63),
                  ),
                  const SizedBox(height: 24),
                  if (_isScanning)
                    const Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: CircularProgressIndicator(color: Colors.pink),
                    )
                  else
                    TextButton.icon(
                      onPressed: _scanReceipt,
                      icon: const Icon(
                        Icons.document_scanner_rounded,
                        color: Colors.pink,
                      ),
                      label: const Text(
                        'Quét hóa đơn bằng AI',
                        style: TextStyle(
                          color: Colors.pink,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  if (!_isButtonEnabled && _amount > 0)
                    Text(
                      "Mỗi người phải trả tối thiểu 1.000đ",
                      style: TextStyle(
                        color: Colors.red.shade400,
                        fontSize: 14,
                      ),
                    ),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isButtonEnabled
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SplitBillConfirmScreen(
                                token: widget.token,
                                transactionData: widget.transactionData,
                                me: widget.me,
                                selectedFriends: widget.selectedFriends,
                                totalAmount: _amount,
                              ),
                            ),
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE91E63),
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    "Tiếp tục",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
