import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PayableCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool isCompleted;
  final Function(String) onPayment;

  const PayableCard({
    Key? key,
    required this.item,
    this.isCompleted = false,
    required this.onPayment,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###', 'vi_VN');
    String creatorName = item['creator_name'] ?? 'Người dùng';
    double amount = double.tryParse(item['my_amount']?.toString() ?? '0') ?? 0;
    String note = item['note'] ?? '';
    DateTime date =
        DateTime.tryParse(item['created_at'] ?? '') ?? DateTime.now();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.pie_chart_rounded,
                          color: Colors.blue,
                          size: 12,
                        ),
                        SizedBox(width: 4),
                        Text(
                          "Chia tiền",
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    note.isNotEmpty
                        ? (note.length > 20
                              ? "${note.substring(0, 20)}..."
                              : note)
                        : "Lời nhắn",
                    style: const TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                ],
              ),
              Text(
                DateFormat('dd/MM/yyyy').format(date),
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.blue.shade50,
                backgroundImage: item['creator_avatar'] != null
                    ? NetworkImage(item['creator_avatar'])
                    : null,
                child: item['creator_avatar'] == null
                    ? Text(
                        creatorName.isNotEmpty
                            ? creatorName[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      creatorName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${formatter.format(amount)}đ",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isCompleted)
                ElevatedButton(
                  onPressed: () =>
                      onPayment(item['member_record_id'].toString()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE91E63),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 0,
                    ),
                    minimumSize: const Size(0, 32),
                  ),
                  child: const Text(
                    "Thanh toán",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                )
              else
                const Text(
                  "Đã thanh toán",
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class ReceivableCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool isCompleted;
  final String meName;
  final List<String> remindedIds;
  final Function(String) onCancel;
  final Function(String) onRemind;

  const ReceivableCard({
    Key? key,
    required this.item,
    this.isCompleted = false,
    required this.meName,
    required this.remindedIds,
    required this.onCancel,
    required this.onRemind,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###', 'vi_VN');
    List<dynamic> members = item['members'] ?? [];
    int totalMembers = members.length;
    int paidMembers = members.where((m) => m['status'] == 'PAID').length;

    double splitAmount =
        double.tryParse(item['split_amount']?.toString() ?? '0') ?? 0;
    double totalAmount =
        double.tryParse(item['total_amount']?.toString() ?? '0') ?? 0;
    double receivedAmount = paidMembers * splitAmount;

    String note = item['note'] ?? '';
    DateTime date =
        DateTime.tryParse(item['created_at'] ?? '') ?? DateTime.now();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted ? Colors.grey.shade200 : Colors.green.shade200,
          width: isCompleted ? 1.0 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isCompleted
                ? Colors.black.withValues(alpha: 0.02)
                : Colors.green.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.pink.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.pie_chart_rounded,
                          color: Colors.pink,
                          size: 12,
                        ),
                        SizedBox(width: 4),
                        Text(
                          "Chia tiền",
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.pink,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    note.isNotEmpty
                        ? (note.length > 20
                              ? "${note.substring(0, 20)}..."
                              : note)
                        : "Lời nhắn",
                    style: const TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                ],
              ),
              Text(
                DateFormat('dd/MM/yyyy').format(date),
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.pink.shade50,
                child: Text(
                  meName.isNotEmpty ? meName[0].toUpperCase() : 'M',
                  style: const TextStyle(
                    color: Colors.pink,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Tổng cần thu",
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Text(
                          "Nhận ",
                          style: TextStyle(color: Colors.black54, fontSize: 13),
                        ),
                        Text(
                          "${formatter.format(receivedAmount)}đ",
                          style: const TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          " / ${formatter.format(totalAmount)}đ",
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Stack(
                      children: [
                        Container(
                          height: 4,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: totalMembers > 0
                              ? (paidMembers / totalMembers)
                              : 0,
                          child: Container(
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (!isCompleted) ...[
                    const Text(
                      "Chưa nhận đủ",
                      style: TextStyle(
                        color: Colors.deepOrange,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        OutlinedButton(
                          onPressed: () => onCancel(item['id'].toString()),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.grey),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 0,
                            ),
                            minimumSize: const Size(0, 32),
                          ),
                          child: const Text(
                            "Hủy",
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        remindedIds.contains(item['id'].toString())
                            ? OutlinedButton(
                                onPressed: null,
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.grey),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 0,
                                  ),
                                  minimumSize: const Size(0, 32),
                                ),
                                child: const Text(
                                  "Đã nhắc nhở",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            : OutlinedButton(
                                onPressed: () =>
                                    onRemind(item['id'].toString()),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                    color: const Color(0xFFE91E63),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 0,
                                  ),
                                  minimumSize: const Size(0, 32),
                                ),
                                child: const Text(
                                  "Nhắc nhở",
                                  style: TextStyle(
                                    color: const Color(0xFFE91E63),
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                      ],
                    ),
                  ] else ...[
                    const Text(
                      "Đã nhận đủ",
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
