import 'package:flutter/material.dart';

class FinancialCenterAppBarActions extends StatelessWidget {
  const FinancialCenterAppBarActions({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.support_agent_rounded, color: Colors.black87, size: 20),
          const SizedBox(width: 4),
          Container(width: 1, height: 16, color: Colors.grey.shade400),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => Navigator.of(context).popUntil((route) => route.isFirst),
            child: const Icon(Icons.home_outlined, color: Colors.black87, size: 20),
          ),
        ],
      ),
    );
  }
}
