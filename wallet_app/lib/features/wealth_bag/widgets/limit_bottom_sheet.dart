import 'package:flutter/material.dart';

void showDepositLimitSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF5F5F9),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 24),
                const Text(
                  "Chi tiết hạn mức",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Hạn mức nạp tiền vào Túi",
                  style: TextStyle(fontSize: 14, color: Colors.black87),
                ),
                const SizedBox(height: 12),
                _buildLimitCard(
                  "Nạp từ Mio/ngân hàng liên kết",
                  "Đã nạp: 0đ",
                  "Còn lại: 50 triệu",
                  "Nạp từ Mio/ngân hàng liên kết tối đa: 50 triệu/tháng",
                  Colors.white,
                ),
                const SizedBox(height: 12),
                _buildBankLimitCard(),
                const SizedBox(height: 16),
                const Text(
                  "Sức chứa tối đa của Túi Thần Tài",
                  style: TextStyle(fontSize: 14, color: Colors.black87),
                ),
                const SizedBox(height: 12),
                _buildLimitCard(
                  null,
                  "Đang chứa: 0đ",
                  "Còn lại: 500 triệu",
                  "Số tiền lớn nhất có thể duy trì trong Túi: 500 triệu",
                  Colors.white,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildLimitCard(
  String? title,
  String leftText,
  String rightText,
  String subtext,
  Color bgColor,
) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 12),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(leftText, style: const TextStyle(color: Colors.black87)),
              ],
            ),
            Text(rightText, style: const TextStyle(color: Colors.black87)),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 12),
        Text(subtext, style: const TextStyle(color: Colors.grey, fontSize: 13)),
      ],
    ),
  );
}

Widget _buildBankLimitCard() {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Chuyển khoản từ ngân hàng",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 16),
        _buildDottedRow("Số lần nạp mỗi ngày:", "3 lần"),
        _buildDottedRow("Số tiền mỗi giao dịch:", "Không giới hạn*"),
        _buildDottedRow("Số tiền nạp mỗi tháng:", "Không giới hạn*"),
        const SizedBox(height: 8),
        const Text(
          "* Không vượt quá sức chứa tối đa của Túi",
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ],
    ),
  );
}

Widget _buildDottedRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.black87)),
            Text(value, style: const TextStyle(color: Colors.black87)),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: List.generate(
            40,
            (index) => Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                height: 1,
                color: Colors.grey.shade300,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

void showWithdrawLimitSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF5F5F9),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 24),
                const Text(
                  "Hạn mức rút trong ngày",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLimitCard(
                  "Rút về Ví Mio",
                  "Đã rút: 0đ",
                  "Còn lại: 50 triệu",
                  "Hạn mức rút trong ngày: 50 triệu",
                  Colors.white,
                ),
                const SizedBox(height: 12),
                _buildLimitCard(
                  "Rút về ngân hàng",
                  "Đã rút: 0đ",
                  "Còn lại: 50 triệu",
                  "Hạn mức rút trong ngày: 50 triệu",
                  Colors.white,
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Thông tin thêm",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "• Số tiền rút tối đa mỗi giao dịch: 50 triệu.",
                        style: TextStyle(color: Colors.black87, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
