import 'package:flutter/material.dart';

class QuickTransferSection extends StatelessWidget {
  const QuickTransferSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Chọn chuyển nhanh',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          const QuickTransferUser(
            avatarColor: Color(0xFFBCAAA4), // Colors.brown.shade200
            initials: 'HT',
            name: 'Hoàng Tính',
          ),
          const Divider(height: 1, indent: 70),
          const QuickTransferUser(
            avatarColor: Color(0xFFE1BEE7), // Colors.purple.shade100
            initials: 'V',
            name: 'Vinh',
          ),
        ],
      ),
    );
  }
}

class QuickTransferUser extends StatelessWidget {
  final Color avatarColor;
  final String initials;
  final String name;

  const QuickTransferUser({
    Key? key,
    required this.avatarColor,
    required this.initials,
    required this.name,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: avatarColor,
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.pink,
                  shape: BoxShape.circle,
                ),
                child: const Text(
                  'mio',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 6,
                    fontWeight: FontWeight.bold,
                    height: 1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      title: Text(
        name,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
      ),
      trailing: const Icon(Icons.history_rounded, color: Colors.grey),
      onTap: () {},
    );
  }
}
