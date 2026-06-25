import 'package:flutter/material.dart';

class TransactionHistorySearch extends StatelessWidget {
  final TextEditingController searchController;
  final bool hasActiveFilter;
  final VoidCallback onFilterTap;
  final VoidCallback onUtilityTap;

  const TransactionHistorySearch({
    Key? key,
    required this.searchController,
    required this.hasActiveFilter,
    required this.onFilterTap,
    required this.onUtilityTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(22),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(
                    Icons.search_rounded,
                    color: Colors.grey,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: searchController,
                      style: const TextStyle(fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: "Tìm kiếm giao dịch",
                        hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: onFilterTap,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: hasActiveFilter
                    ? Colors.pink.shade50
                    : const Color(0xFFF5F5F5),
                shape: BoxShape.circle,
                border: hasActiveFilter
                    ? Border.all(color: Colors.pink.shade200)
                    : null,
              ),
              child: Icon(
                Icons.tune_rounded,
                color: hasActiveFilter ? Colors.pink : Colors.grey.shade600,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onUtilityTap,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Color(0xFFF5F5F5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.grid_view_rounded,
                color: Colors.black54,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
