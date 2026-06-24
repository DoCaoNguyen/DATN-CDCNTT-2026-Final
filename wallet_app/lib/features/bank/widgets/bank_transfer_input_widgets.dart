import 'package:flutter/material.dart';

class BankReceiverInfoCard extends StatelessWidget {
  final String bankCode;
  final String displayNickname;
  final String displayName;
  final String accountNumber;
  final String bankName;

  const BankReceiverInfoCard({
    Key? key,
    required this.bankCode,
    required this.displayNickname,
    required this.displayName,
    required this.accountNumber,
    required this.bankName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F3B99),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.white,
            child: ClipOval(
              child: Image.network(
                'https://api.vietqr.io/img/$bankCode.png',
                width: 32,
                height: 32,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Text(
                  bankCode,
                  style: const TextStyle(
                    color: Color(0xFF0F3B99),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayNickname,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  displayName.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$accountNumber - $bankName',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Colors.white),
        ],
      ),
    );
  }
}

class BankTransferAmountInput extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String? errorText;
  final String vietnameseWords;

  const BankTransferAmountInput({
    Key? key,
    required this.controller,
    required this.onChanged,
    this.errorText,
    required this.vietnameseWords,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Số tiền chuyển *',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                      ),
                      onChanged: onChanged,
                    ),
                  ),
                  Container(
                    height: 24,
                    width: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey.shade100,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'đ',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              if (vietnameseWords.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  vietnameseWords,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.red,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    errorText!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class BankTransferNoteInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onChanged;

  const BankTransferNoteInput({
    Key? key,
    required this.controller,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Lời nhắn (${controller.text.length}/70)',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          TextField(
            controller: controller,
            maxLength: 70,
            maxLines: null,
            style: const TextStyle(fontSize: 14),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              isDense: true,
              counterText: '',
            ),
            onChanged: (_) => onChanged(),
          ),
        ],
      ),
    );
  }
}
