import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrHelper {
  static String removeDiacritics(String str) {
    var withDia = 'áàảãạăắằẳẵặâấầẩẫậđéèẻẽẹêếềểễệíìỉĩịóòỏõọôốồổỗộơớờởỡợúùủũụưứừửữựýỳỷỹỵ';
    var withoutDia = 'aaaaaaaaaaaaaaaaadeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyy';
    for (int i = 0; i < withDia.length; i++) {
      str = str.replaceAll(withDia[i], withoutDia[i]);
      str = str.replaceAll(withDia[i].toUpperCase(), withoutDia[i].toUpperCase());
    }
    return str;
  }

  static Future<bool> validateIdCardQuality(File imageFile, bool isFront, {String? expectedId, String? expectedName}) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      textRecognizer.close();

      String text = recognizedText.text.toUpperCase();
      if (text.trim().isEmpty) return false;

      if (isFront) {
        // Nếu để nguyên thẻ vừa vặn trong khung, ML Kit thường gom chữ lại thành 3-4 blocks.
        // Cần hạ điều kiện xuống 3 để không bắt người dùng phải đưa camera quá sát (lố khung).
        if (recognizedText.blocks.length < 3) return false;
        bool hasId = RegExp(r'\d{9,12}').hasMatch(text);
        return hasId;
      } else {
        if (recognizedText.blocks.length < 2) return false;
        
        String cleanText = text.replaceAll(RegExp(r'[\s<]+'), '');
        
        if (expectedId != null && expectedId.isNotEmpty) {
           if (!cleanText.contains(expectedId)) return false;
        }
        
        if (expectedName != null && expectedName.isNotEmpty) {
           String noDiaName = removeDiacritics(expectedName).toUpperCase().replaceAll(' ', '');
           if (!cleanText.contains(noDiaName)) return false;
        }
        
        return true;
      }
    } catch (e) {
      return false;
    }
  }

  // Bóc tách thông tin từ ảnh mặt trước
  static Future<Map<String, String>> extractInfo(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
    String fullText = recognizedText.text;
    textRecognizer.close();

    Map<String, String> data = {"id": "", "dob": "", "name": "", "gender": "", "address": ""};
    
    String cleanTextForId = fullText.replaceAll(RegExp(r'\s+'), '').replaceAll('-', '');
    data["id"] = RegExp(r'\d{12}').stringMatch(cleanTextForId) ?? "";

    List<String> lines = fullText.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    for (int i = 0; i < lines.length; i++) {
      String line = lines[i];
      String upperLine = line.toUpperCase();

      if (data["dob"]!.isEmpty && RegExp(r'(SINH|BIRTH)').hasMatch(upperLine)) {
        data["dob"] = RegExp(r'\d{2}[-/]\d{2}[-/]\d{4}').stringMatch(line) ?? "";
      }
      if (data["name"]!.isEmpty && RegExp(r'(TÊN|NAME|NARNE)').hasMatch(upperLine)) {
        String val = line.replaceAll(RegExp(r'.*(TÊN|NAME|NARNE)[\s:/*]*', caseSensitive: false), '').trim();
        if (val.length > 4 && !RegExp(r'\d').hasMatch(val)) {
          data["name"] = val.toUpperCase();
        } else if (i + 1 < lines.length) {
          data["name"] = lines[i + 1].toUpperCase();
        }
      }
      if (data["gender"]!.isEmpty && RegExp(r'(TÍNH|TINH|SEX)').hasMatch(upperLine)) {
        var gMatch = RegExp(r'(Nam|Nữ|Nu)', caseSensitive: false).firstMatch(line.replaceAll(RegExp(r'(VIỆT NAM|VIET NAM)', caseSensitive: false), ''));
        if (gMatch != null) data["gender"] = gMatch.group(1)!.toLowerCase() == 'nam' ? 'Nam' : 'Nữ';
      }
      if (data["address"]!.isEmpty && RegExp(r'(TRÚ|TRÙ|RESIDENCE)').hasMatch(upperLine)) {
        data["address"] = line.replaceAll(RegExp(r'.*(TRÚ|TRÙ|RESIDENCE)[\s:/*]*', caseSensitive: false), '').trim();
        if (i + 1 < lines.length && lines[i + 1].length > 4 && !RegExp(r'^[0-9]+$').hasMatch(lines[i + 1])) {
          data["address"] = "${data["address"]}, ${lines[i + 1]}";
        }
        data["address"] = data["address"]!.replaceFirst(RegExp(r'^,\s*'), '').trim();
      }
    }
    return data;
  }

  static bool isOver18(String dobStr) {
    try {
      List<String> parts = dobStr.split(RegExp(r'[-/]'));
      if (parts.length != 3) return false;
      DateTime birthDate = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
      DateTime today = DateTime.now();
      int age = today.year - birthDate.year;
      if (today.month < birthDate.month || (today.month == birthDate.month && today.day < birthDate.day)) age--;
      return age >= 18;
    } catch (e) {
      return false; 
    }
  }
}