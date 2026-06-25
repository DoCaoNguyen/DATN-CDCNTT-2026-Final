import 'package:flutter/material.dart';

class TransactionDetailsCard extends StatelessWidget {
  final String bankCode;
  final String? cardHolderName;
  final String bankName;
  final String accountNumber;
  final String amountFormatted;
  final String note;
  final String nickname;

  const TransactionDetailsCard({
    Key? key,
    required this.bankCode,
    this.cardHolderName,
    required this.bankName,
    required this.accountNumber,
    required this.amountFormatted,
    required this.note,
    required this.nickname,
  }) : super(key: key);

  Widget _buildDetailRow(String title, String value, {bool isBlue = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: isBlue ? Colors.blue.shade700 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade200),
                  color: Colors.white,
                ),
                alignment: Alignment.center,
                child: ClipOval(
                  child: Image.network(
                    'https://api.vietqr.io/img/$bankCode.png',
                    fit: BoxFit.contain,
                    width: 30,
                    height: 30,
                    errorBuilder: (context, error, stackTrace) {
                      return Text(
                        bankCode,
                        style: const TextStyle(
                          color: Color(0xFF0F3B99),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (cardHolderName ?? 'PHAN VAN THONG').toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "$bankName - $accountNumber",
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          _buildDetailRow('Số tiền', amountFormatted),
          _buildDetailRow('Tên gợi nhớ', nickname),
          _buildDetailRow('Tin nhắn', note),
          _buildDetailRow('Phí giao dịch', 'Miễn phí'),
        ],
      ),
    );
  }
}
