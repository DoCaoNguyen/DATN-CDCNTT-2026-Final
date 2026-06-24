import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dmrtd/dmrtd.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';

/// Lớp kết quả sau khi thực hiện eKYC qua NFC
class CccdKycResult {
  final String documentNumber;
  final String fullName;
  final String dateOfBirth;
  final String sex;
  final Uint8List? faceImageBytes;

  CccdKycResult({
    required this.documentNumber,
    required this.fullName,
    required this.dateOfBirth,
    required this.sex,
    this.faceImageBytes,
  });
}

/// Implement ComProvider của dmrtd sử dụng flutter_nfc_kit
class NfcKitComProvider implements ComProvider {
  bool _connected = false;

  @override
  bool isConnected() => _connected;

  @override
  Future<void> connect() async {
    // Việc poll NFC đã được thực hiện ở mức Service trước đó
    _connected = true;
  }

  @override
  Future<void> disconnect() async {
    await FlutterNfcKit.finish();
    _connected = false;
  }

  @override
  Future<Uint8List> transceive(Uint8List apdu) async {
    final response = await FlutterNfcKit.transceive(apdu);
    return response;
  }
}

class NfcKycService {
  /// Hàm tách chuỗi QR Code của CCCD Việt Nam
  /// Định dạng: Số_CCCD|Số_CMND_cũ|Họ_tên|Ngày_sinh(DDMMYYYY)|Giới_tính|Địa_chỉ|Ngày_cấp
  static Map<String, String>? parseCccdQr(String qrData) {
    try {
      final parts = qrData.split('|');
      if (parts.length < 7) return null;

      return {
        'documentNumber': parts[0],
        'oldIdNumber': parts[1],
        'fullName': parts[2],
        'dob': parts[3], // DDMMYYYY
        'gender': parts[4],
        'address': parts[5],
        'issueDate': parts[6], // DDMMYYYY
      };
    } catch (e) {
      return null;
    }
  }

  /// Tính toán ngày hết hạn (Date of Expiry - DOE) của CCCD Việt Nam theo quy định:
  /// CCCD hết hạn vào ngày sinh nhật ở các mốc tuổi: 25, 40 và 60.
  /// Định dạng trả về: YYMMDD phục vụ cho ICAO BAC.
  static String calculateExpiryDate(String dobStr, [String? issueDateStr]) {
    final cleanedDob = dobStr.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanedDob.length < 8) return '';

    final birthDay = int.parse(cleanedDob.substring(0, 2));
    final birthMonth = int.parse(cleanedDob.substring(2, 4));
    final birthYear = int.parse(cleanedDob.substring(4, 8));

    int referenceYear = DateTime.now().year;
    int referenceMonth = DateTime.now().month;
    int referenceDay = DateTime.now().day;

    // Nếu có ngày cấp, tính tuổi tại thời điểm cấp
    if (issueDateStr != null && issueDateStr.isNotEmpty) {
      final cleanedIssue = issueDateStr.replaceAll(RegExp(r'[^0-9]'), '');
      if (cleanedIssue.length >= 8) {
        referenceDay = int.parse(cleanedIssue.substring(0, 2));
        referenceMonth = int.parse(cleanedIssue.substring(2, 4));
        referenceYear = int.parse(cleanedIssue.substring(4, 8));
      }
    }

    int currentAge = referenceYear - birthYear;
    if (referenceMonth < birthMonth ||
        (referenceMonth == birthMonth && referenceDay < birthDay)) {
      currentAge--;
    }

    int expiryYear;
    // Theo luật CCCD: cấp trước 2 năm của mốc tuổi thì được cộng dồn đến mốc tiếp theo
    // Các mốc: 25, 40, 60
    if (currentAge < 23) {
      expiryYear = birthYear + 25;
    } else if (currentAge < 38) {
      expiryYear = birthYear + 40;
    } else if (currentAge < 58) {
      expiryYear = birthYear + 60;
    } else {
      // Cấp từ 58 tuổi trở lên là Không thời hạn. Đa số chip dùng 991231 hoặc birthYear + 100
      expiryYear = birthYear + 100;
    }

    final yy = (expiryYear % 100).toString().padLeft(2, '0');
    final mm = birthMonth.toString().padLeft(2, '0');
    final dd = birthDay.toString().padLeft(2, '0');
    return '$yy$mm$dd';
  }

  /// Định dạng ngày sinh từ bất kỳ dạng nào chứa 8 chữ số sang YYMMDD phục vụ cho ICAO BAC
  static String formatDobToYYMMDD(String dobStr) {
    final cleaned = dobStr.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.length < 8) return '';
    final dayStr = cleaned.substring(0, 2);
    final monthStr = cleaned.substring(2, 4);
    final yearStr = cleaned.substring(4, 8);
    final yy = yearStr.substring(2, 4);
    return '$yy$monthStr$dayStr';
  }

  /// Thực hiện đọc chip NFC trên CCCD
  /// [documentNumber]: Số CCCD (12 chữ số)
  /// [dobYYMMDD]: Ngày sinh dạng YYMMDD
  /// [doeYYMMDD]: Ngày hết hạn dạng YYMMDD
  static Future<CccdKycResult> readCCCDChip({
    required String documentNumber,
    required String dobYYMMDD,
    required String doeYYMMDD,
  }) async {
    debugPrint("[NFC_DEBUG] Bắt đầu quá trình đọc chip NFC");
    debugPrint(
      "[NFC_DEBUG] Tham số đầu vào: CCCD=$documentNumber, dobYYMMDD=$dobYYMMDD, doeYYMMDD=$doeYYMMDD",
    );

    // 1. Kiểm tra phần cứng NFC và bắt đầu Poll (đọc NFC)
    final availability = await FlutterNfcKit.nfcAvailability;
    debugPrint("[NFC_DEBUG] Trạng thái NFC Availability: $availability");
    if (availability == NFCAvailability.not_supported) {
      throw Exception("Thiết bị của bạn không hỗ trợ tính năng NFC.");
    }

    debugPrint("[NFC_DEBUG] Bắt đầu Poll thẻ NFC (timeout 20s)...");
    NFCTag tag;
    try {
      tag = await FlutterNfcKit.poll(
        timeout: const Duration(seconds: 20),
        androidPlatformSound: true,
      );
      debugPrint("[NFC_DEBUG] Đã phát hiện thẻ NFC!");
      debugPrint(
        "[NFC_DEBUG] Chi tiết thẻ - Type: ${tag.type}, ID: ${tag.id}, Standard: ${tag.standard}",
      );
    } catch (e) {
      debugPrint("[NFC_DEBUG] Lỗi khi quét/poll thẻ NFC: $e");
      rethrow;
    }

    // 2. Kiểm tra định dạng thẻ (CCCD Việt Nam/Hộ chiếu tuân theo ISO 7816)
    if (tag.type != NFCTagType.iso7816) {
      debugPrint(
        "[NFC_DEBUG] Loại thẻ không khớp iso7816 (phát hiện: ${tag.type})",
      );
      await FlutterNfcKit.finish();
      throw Exception("Định dạng thẻ không tương thích với CCCD gắn chip.");
    }

    // 3. Khởi tạo ComProvider và Passport session của dmrtd
    debugPrint("[NFC_DEBUG] Kết nối NfcKitComProvider...");
    final comProvider = NfcKitComProvider();
    await comProvider.connect();
    final passport = Passport(comProvider);

    try {
      // 4. Thiết lập Basic Access Control (BAC) dùng MRZ Keys
      final parsedDob = _parseYYMMDD(dobYYMMDD);
      final parsedDoe = _parseYYMMDD(doeYYMMDD);
      debugPrint("[NFC_DEBUG] Khởi tạo DBAKey với:");
      debugPrint("            - Document Number: $documentNumber");
      debugPrint("            - DOB Parsed: $parsedDob (yymmdd: $dobYYMMDD)");
      debugPrint("            - DOE Parsed: $parsedDoe (yymmdd: $doeYYMMDD)");

      final dbaKey = DBAKey(documentNumber, parsedDob, parsedDoe);

      // Bắt đầu Session BAC
      debugPrint("[NFC_DEBUG] Đang thiết lập session BAC (startSession)...");
      try {
        await passport.startSession(dbaKey);
        debugPrint("[NFC_DEBUG] Thiết lập session BAC thành công!");
      } catch (sessionError) {
        debugPrint(
          "[NFC_DEBUG] THẤT BẠI khi thiết lập session BAC: $sessionError",
        );
        throw Exception(
          "Không thể thiết lập kết nối bảo mật BAC với thẻ chip. Vui lòng kiểm tra Số CCCD, Ngày sinh và Ngày hết hạn đã chính xác chưa.\nChi tiết: $sessionError",
        );
      }

      // 5. Đọc các tệp dữ liệu Data Group 1 (DG1 - Thông tin cá nhân)
      debugPrint("[NFC_DEBUG] Đang đọc EfCOM...");
      EfCOM efcom;
      try {
        efcom = await passport.readEfCOM();
        debugPrint(
          "[NFC_DEBUG] Đọc EfCOM thành công! Các DG tags có sẵn: ${efcom.dgTags}",
        );
      } catch (efcomError) {
        debugPrint("[NFC_DEBUG] Lỗi khi đọc EfCOM: $efcomError");
        throw Exception(
          "Không thể đọc tệp EfCOM cấu trúc thẻ. Chi tiết: $efcomError",
        );
      }

      String fullName = "Không xác định";
      String sex = "Không xác định";
      String dob = dobYYMMDD;

      if (efcom.dgTags.contains(EfDG1.TAG)) {
        debugPrint("[NFC_DEBUG] Đang đọc EfDG1 (Thông tin cá nhân)...");
        try {
          final dg1 = await passport.readEfDG1();
          debugPrint("[NFC_DEBUG] Đọc EfDG1 thành công!");
          final mrz = dg1.mrz;
          fullName = "${mrz.firstName} ${mrz.lastName}".trim();
          sex = mrz.gender.toString();
          dob = mrz.dateOfBirth.toString();
          debugPrint(
            "[NFC_DEBUG] Dữ liệu MRZ trích xuất: Họ tên=$fullName, Giới tính=$sex, Ngày sinh=$dob",
          );
        } catch (dg1Error) {
          debugPrint("[NFC_DEBUG] Lỗi khi đọc/phân tích EfDG1: $dg1Error");
          throw Exception(
            "Không thể đọc thông tin cá nhân từ DG1. Chi tiết: $dg1Error",
          );
        }
      } else {
        debugPrint("[NFC_DEBUG] Cảnh báo: Thẻ không chứa DG1 tag!");
      }

      // 6. Đọc tệp dữ liệu Data Group 2 (DG2 - Ảnh chân dung)
      Uint8List? faceBytes;
      if (efcom.dgTags.contains(EfDG2.TAG)) {
        debugPrint("[NFC_DEBUG] Đang đọc EfDG2 (Ảnh chân dung)...");
        try {
          final dg2 = await passport.readEfDG2();
          faceBytes = dg2.imageData;
          debugPrint(
            "[NFC_DEBUG] Đọc EfDG2 thành công! Độ dài ảnh: ${faceBytes?.length} bytes",
          );
        } catch (dg2Error) {
          debugPrint("[NFC_DEBUG] Lỗi khi đọc EfDG2: $dg2Error");
          // Không throw để vẫn trả về thông tin văn bản nếu chỉ lỗi ảnh chân dung
        }
      } else {
        debugPrint("[NFC_DEBUG] Cảnh báo: Thẻ không chứa DG2 tag!");
      }

      // 7. Giải phóng NFC và trả về kết quả
      debugPrint("[NFC_DEBUG] Hoàn thành đọc NFC. Ngắt kết nối...");
      await comProvider.disconnect();
      return CccdKycResult(
        documentNumber: documentNumber,
        fullName: fullName,
        dateOfBirth: dob,
        sex: sex,
        faceImageBytes: faceBytes,
      );
    } catch (e) {
      debugPrint("[NFC_DEBUG] Phát hiện ngoại lệ trong quá trình đọc NFC: $e");
      // Luôn đảm bảo đóng kết nối NFC kể cả khi lỗi xảy ra
      await comProvider.disconnect();
      rethrow;
    }
  }

  /// Helper giải mã chuỗi ngày YYMMDD thành đối tượng DateTime
  static DateTime _parseYYMMDD(String yymmdd) {
    if (yymmdd.length < 6) return DateTime.now();
    final yy = int.parse(yymmdd.substring(0, 2));
    final mm = int.parse(yymmdd.substring(2, 4));
    final dd = int.parse(yymmdd.substring(4, 6));
    final year = yy < 50 ? 2000 + yy : 1900 + yy;
    return DateTime(year, mm, dd);
  }
}
