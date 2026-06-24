import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/nfc_kyc_service.dart';

class CccdEkycScreen extends StatefulWidget {
  const CccdEkycScreen({Key? key}) : super(key: key);

  @override
  State<CccdEkycScreen> createState() => _CccdEkycScreenState();
}

class _CccdEkycScreenState extends State<CccdEkycScreen> {
  int _currentStep = 1; // 1: Quét QR, 2: Đọc NFC, 3: Kết quả

  // Thông tin trích xuất từ QR
  Map<String, String>? _qrResult;
  String _docNumber = '';
  String _dobYYMMDD = '';
  String _doeYYMMDD = '';

  // Kết quả đọc từ Chip NFC
  CccdKycResult? _nfcResult;

  // Trạng thái quét & đọc
  bool _isNfcLoading = false;
  String _nfcStatusMessage = '';
  String? _errorMessage;

  // Điều khiển Camera
  final MobileScannerController _cameraController = MobileScannerController();

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  // Luồng xử lý khi quét trúng mã QR mặt trước CCCD
  void _onQrCodeDetected(BarcodeCapture capture) {
    final barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final rawVal = barcode.rawValue;
      if (rawVal == null || rawVal.isEmpty) continue;

      final parsed = NfcKycService.parseCccdQr(rawVal);
      if (parsed != null) {
        // Tách chuỗi thành công, dừng Camera
        _cameraController.stop();

        setState(() {
          _qrResult = parsed;
          _docNumber = parsed['documentNumber'] ?? '';

          // Chuyển đổi định dạng ngày phục vụ cho BAC
          final rawDob = parsed['dob'] ?? '';
          final rawIssueDate = parsed['issueDate'] ?? '';
          _dobYYMMDD = NfcKycService.formatDobToYYMMDD(rawDob);
          _doeYYMMDD = NfcKycService.calculateExpiryDate(rawDob, rawIssueDate);

          _currentStep = 2; // Chuyển sang bước đọc NFC
          _errorMessage = null;
        });
        break;
      }
    }
  }

  // Kích hoạt luồng đọc chip NFC
  Future<void> _startNfcReading() async {
    setState(() {
      _isNfcLoading = true;
      _nfcStatusMessage = 'Vui lòng áp thẻ CCCD vào mặt lưng điện thoại...';
      _errorMessage = null;
    });

    try {
      final result = await NfcKycService.readCCCDChip(
        documentNumber: _docNumber,
        dobYYMMDD: _dobYYMMDD,
        doeYYMMDD: _doeYYMMDD,
      );

      setState(() {
        _nfcResult = result;
        _isNfcLoading = false;
        _currentStep = 3; // Chuyển sang màn hình kết quả
      });
    } catch (e) {
      String userFriendlyError = 'Đọc NFC thất bại. Vui lòng thử lại!';
      final errStr = e.toString().toLowerCase();

      if (errStr.contains('timeout')) {
        userFriendlyError =
            'Thời gian kết nối quá hạn. Vui lòng áp thẻ sát hơn.';
      } else if (errStr.contains('session') ||
          errStr.contains('bac') ||
          errStr.contains('security')) {
        userFriendlyError =
            'Sai thông tin BAC (Số CCCD hoặc Ngày sinh không khớp với chip).';
      } else if (errStr.contains('not supported')) {
        userFriendlyError = 'Thiết bị không hỗ trợ tính năng đọc NFC.';
      } else if (errStr.contains('nfc finish') ||
          errStr.contains('disconnected')) {
        userFriendlyError =
            'Thẻ bị ngắt kết nối đột ngột. Hãy giữ yên thẻ khi đọc.';
      }

      setState(() {
        _isNfcLoading = false;
        _errorMessage = userFriendlyError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Xác thực danh tính eKYC',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (_currentStep > 1) {
              setState(() {
                _currentStep--;
                if (_currentStep == 1) {
                  _cameraController.start();
                }
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      backgroundColor: const Color(0xFFF9F9FB),
      body: SafeArea(
        child: Column(
          children: [
            _buildStepIndicator(),
            Expanded(
              child: _errorMessage != null && _currentStep != 2
                  ? _buildErrorWidget()
                  : _buildCurrentStepBody(),
            ),
          ],
        ),
      ),
    );
  }

  // Widget hiển thị thanh chỉ báo 3 bước
  Widget _buildStepIndicator() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildStepCircle(1, 'Quét QR'),
          _buildStepLine(1),
          _buildStepCircle(2, 'Đọc NFC'),
          _buildStepLine(2),
          _buildStepCircle(3, 'Hoàn thành'),
        ],
      ),
    );
  }

  Widget _buildStepCircle(int step, String label) {
    final isActive = _currentStep >= step;
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive ? Colors.pink : Colors.grey.shade300,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$step',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? Colors.black87 : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(int activeAfterStep) {
    final isActive = _currentStep > activeAfterStep;
    return Container(
      width: 50,
      height: 2,
      margin: const EdgeInsets.only(bottom: 16),
      color: isActive ? Colors.pink : Colors.grey.shade300,
    );
  }

  // Widget thân trang dựa theo Step hiện tại
  Widget _buildCurrentStepBody() {
    switch (_currentStep) {
      case 1:
        return _buildQrScannerStep();
      case 2:
        return _buildNfcReadingStep();
      case 3:
        return _buildResultStep();
      default:
        return const SizedBox.shrink();
    }
  }

  // --- BƯỚC 1: QUÉT QR ---
  Widget _buildQrScannerStep() {
    return Stack(
      children: [
        MobileScanner(
          controller: _cameraController,
          onDetect: _onQrCodeDetected,
        ),
        // Lớp phủ tối đục lỗ khung quét ở giữa
        ColorFiltered(
          colorFilter: ColorFilter.mode(
            Colors.black.withValues(alpha: 0.6),
            BlendMode.srcOut,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: Colors.black,
                  backgroundBlendMode: BlendMode.dstOut,
                ),
              ),
              Center(
                child: Container(
                  width: 300,
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Khung viền chỉ dẫn quét
        Center(
          child: Container(
            width: 300,
            height: 180,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.pink, width: 2),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        const Positioned(
          bottom: 40,
          left: 16,
          right: 16,
          child: Column(
            children: [
              Text(
                'Quét mã QR trên CCCD',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'Đặt mã QR ở góc trên bên phải mặt trước CCCD vào trong khung quét',
                style: TextStyle(color: Colors.white70, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- BƯỚC 2: ĐỌC CHIP NFC ---
  Widget _buildNfcReadingStep() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Hình mô phỏng NFC
          Container(
            width: 160,
            height: 160,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.pink.shade50,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.contactless_rounded,
              size: 90,
              color: Colors.pink,
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Kết nối NFC với CCCD',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _isNfcLoading
                ? _nfcStatusMessage
                : 'Đặt mặt sau thẻ CCCD áp sát vào đầu đọc NFC ở lưng điện thoại và giữ nguyên tay.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          if (_errorMessage != null) ...[
            Text(
              _errorMessage!,
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
          ],
          if (_isNfcLoading)
            const CircularProgressIndicator(color: Colors.pink)
          else
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _startNfcReading,
                icon: const Icon(Icons.nfc_rounded, color: Colors.white),
                label: const Text(
                  'Bắt đầu đọc NFC',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // --- BƯỚC 3: KẾT QUẢ ---
  Widget _buildResultStep() {
    if (_nfcResult == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.verified_rounded,
              color: Colors.green,
              size: 48,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Xác thực thẻ chip thành công!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 24),

          // Hiển thị ảnh trích xuất từ chip
          if (_nfcResult!.faceImageBytes != null) ...[
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: Image.memory(
                  _nfcResult!.faceImageBytes!,
                  width: 140,
                  height: 170,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 140,
                      height: 170,
                      color: Colors.grey.shade100,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.broken_image_rounded,
                            color: Colors.grey,
                            size: 36,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Lỗi nén JP2\n(Cần giải mã)',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 11,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Thẻ thông tin cá nhân trích xuất
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Column(
              children: [
                _buildInfoRow(
                  'Số CCCD',
                  _nfcResult!.documentNumber,
                  isBoldValue: true,
                ),
                const Divider(),
                _buildInfoRow('Họ và Tên', _nfcResult!.fullName),
                const Divider(),
                _buildInfoRow('Ngày sinh', _nfcResult!.dateOfBirth),
                const Divider(),
                _buildInfoRow(
                  'Giới tính',
                  _nfcResult!.sex == 'F' ? 'Nữ' : 'Nam',
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                // Hoàn thành eKYC, trả về kết quả
                Navigator.pop(context, _nfcResult);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Hoàn tất xác thực',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBoldValue = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBoldValue ? FontWeight.bold : FontWeight.w600,
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.red, size: 64),
          const SizedBox(height: 16),
          const Text(
            'Lỗi xảy ra',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _errorMessage ?? 'Đã xảy ra lỗi không xác định.',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _errorMessage = null;
                _currentStep = 1;
                _cameraController.start();
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.pink),
            child: const Text(
              'Thử lại từ đầu',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
