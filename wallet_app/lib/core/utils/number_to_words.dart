class NumberToWords {
  static String convert(int number) {
    if (number == 0) return '';
    final units = [
      '',
      'một',
      'hai',
      'ba',
      'bốn',
      'năm',
      'sáu',
      'bảy',
      'tám',
      'chín',
    ];
    final tens = [
      '',
      'mười',
      'hai mươi',
      'ba mươi',
      'bốn mươi',
      'năm mươi',
      'sáu mươi',
      'bảy mươi',
      'tám mươi',
      'chín mươi',
    ];

    String convertGroup(int n) {
      int h = n ~/ 100;
      int t = (n % 100) ~/ 10;
      int u = n % 10;
      String res = '';
      if (h > 0) {
        res += '${units[h]} trăm ';
      }
      if (t > 0) {
        if (t == 1) {
          res += 'mười ';
        } else {
          res += '${units[t]} mươi ';
        }
      } else if (h > 0 && u > 0) {
        res += 'lẻ ';
      }
      if (u > 0) {
        if (u == 1 && t > 1) {
          res += 'mốt ';
        } else if (u == 5 && t > 0) {
          res += 'lăm ';
        } else {
          res += '${units[u]} ';
        }
      }
      return res.trim();
    }

    final groups = <String>[];
    final scales = ['', 'nghìn', 'triệu', 'tỷ'];
    int temp = number;
    int scaleIdx = 0;
    while (temp > 0) {
      int g = temp % 1000;
      if (g > 0) {
        String gStr = convertGroup(g);
        if (scaleIdx > 0) {
          gStr += ' ${scales[scaleIdx]}';
        }
        groups.insert(0, gStr);
      }
      temp = temp ~/ 1000;
      scaleIdx++;
    }

    String result = groups.join(' ');
    return result.isEmpty
        ? ''
        : result[0].toUpperCase() + result.substring(1) + ' đồng';
  }
}
