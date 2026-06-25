import 'package:flutter/material.dart';

class CategoryBottomSheet extends StatefulWidget {
  final String? currentCategory;
  final bool initialIsCounted;
  final Future<bool> Function(String categoryName, bool isCounted)
  onCategorySelected;

  const CategoryBottomSheet({
    Key? key,
    required this.currentCategory,
    required this.initialIsCounted,
    required this.onCategorySelected,
  }) : super(key: key);

  static void show(
    BuildContext context, {
    required String? currentCategory,
    required bool initialIsCounted,
    required Future<bool> Function(String categoryName, bool isCounted)
    onCategorySelected,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return CategoryBottomSheet(
          currentCategory: currentCategory,
          initialIsCounted: initialIsCounted,
          onCategorySelected: onCategorySelected,
        );
      },
    );
  }

  @override
  State<CategoryBottomSheet> createState() => _CategoryBottomSheetState();
}

class _CategoryBottomSheetState extends State<CategoryBottomSheet> {
  late bool localIsCounted;
  bool _isUpdating = false;

  final List<Map<String, dynamic>> categories = [
    // Chi tiêu - sinh hoạt
    {
      'name': 'Chợ, siêu thị',
      'group': 'Chi tiêu - sinh hoạt',
      'icon': Icons.shopping_basket_outlined,
      'color': Colors.orange,
    },
    {
      'name': 'Ăn uống',
      'group': 'Chi tiêu - sinh hoạt',
      'icon': Icons.restaurant_outlined,
      'color': Colors.orange,
    },
    {
      'name': 'Di chuyển',
      'group': 'Chi tiêu - sinh hoạt',
      'icon': Icons.directions_car_filled_outlined,
      'color': Colors.orange,
    },
    // Chi phí phát sinh
    {
      'name': 'Mua sắm',
      'group': 'Chi phí phát sinh',
      'icon': Icons.shopping_bag_outlined,
      'color': Colors.pink,
    },
    {
      'name': 'Giải trí',
      'group': 'Chi phí phát sinh',
      'icon': Icons.movie_creation_outlined,
      'color': Colors.pink,
    },
    {
      'name': 'Làm đẹp',
      'group': 'Chi phí phát sinh',
      'icon': Icons.face_retouching_natural_outlined,
      'color': Colors.pink,
    },
    {
      'name': 'Sức khỏe',
      'group': 'Chi phí phát sinh',
      'icon': Icons.health_and_safety_outlined,
      'color': Colors.pink,
    },
    {
      'name': 'Từ thiện',
      'group': 'Chi phí phát sinh',
      'icon': Icons.favorite_border_outlined,
      'color': Colors.pink,
    },
    // Chi phí cố định
    {
      'name': 'Hóa đơn',
      'group': 'Chi phí cố định',
      'icon': Icons.receipt_outlined,
      'color': Colors.blue,
    },
    {
      'name': 'Nhà cửa',
      'group': 'Chi phí cố định',
      'icon': Icons.home_work_outlined,
      'color': Colors.blue,
    },
    {
      'name': 'Người thân',
      'group': 'Chi phí cố định',
      'icon': Icons.people_outline,
      'color': Colors.blue,
    },
    // Đầu tư - tiết kiệm
    {
      'name': 'Đầu tư',
      'group': 'Đầu tư - tiết kiệm',
      'icon': Icons.account_balance_outlined,
      'color': Colors.teal,
    },
    {
      'name': 'Học tập',
      'group': 'Đầu tư - tiết kiệm',
      'icon': Icons.school_outlined,
      'color': Colors.teal,
    },
  ];

  @override
  void initState() {
    super.initState();
    localIsCounted = widget.initialIsCounted;
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var cat in categories) {
      final g = cat['group'] as String;
      if (!grouped.containsKey(g)) {
        grouped[g] = [];
      }
      grouped[g]!.add(cat);
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFFF7F8FA),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Stack(
        children: [
          Column(
            children: [
              // Title Bar
              Padding(
                padding: const EdgeInsets.only(
                  left: 20,
                  right: 8,
                  top: 12,
                  bottom: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Chọn danh mục",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.black54),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Search & Add Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: const [
                            Icon(Icons.search, color: Colors.grey, size: 20),
                            SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                decoration: InputDecoration(
                                  hintText: "Tìm kiếm",
                                  border: InputBorder.none,
                                  isDense: true,
                                  hintStyle: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    TextButton.icon(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.add_circle_outline,
                        color: Colors.black87,
                        size: 20,
                      ),
                      label: const Text(
                        "Tạo mới",
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Switch Banner
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F7FA),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.bar_chart, color: Colors.teal),
                        SizedBox(width: 8),
                        Text(
                          "Tính khoản này vào Chi tiêu",
                          style: TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Switch(
                      value: localIsCounted,
                      activeColor: Colors.green,
                      onChanged: (val) {
                        setState(() {
                          localIsCounted = val;
                        });
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Grid list of categories
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: grouped.keys.map((groupName) {
                      final items = grouped[groupName]!;

                      Color groupColor = Colors.orange;
                      if (groupName.contains("phát sinh"))
                        groupColor = Colors.pink;
                      if (groupName.contains("cố định"))
                        groupColor = Colors.blue;
                      if (groupName.contains("tiết kiệm"))
                        groupColor = Colors.teal;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.bookmark,
                                  color: groupColor,
                                  size: 18,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  groupName,
                                  style: TextStyle(
                                    color: groupColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.all(12),
                            child: GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    mainAxisSpacing: 12,
                                    crossAxisSpacing: 12,
                                    childAspectRatio: 1.2,
                                  ),
                              itemCount: items.length,
                              itemBuilder: (context, idx) {
                                final cat = items[idx];
                                final catName = cat['name'] as String;
                                final catIcon = cat['icon'] as IconData;
                                final isSelected =
                                    widget.currentCategory == catName;

                                return GestureDetector(
                                  onTap: () async {
                                    setState(() {
                                      _isUpdating = true;
                                    });

                                    final success = await widget
                                        .onCategorySelected(
                                          catName,
                                          localIsCounted,
                                        );

                                    if (mounted) {
                                      setState(() {
                                        _isUpdating = false;
                                      });
                                      if (success) {
                                        Navigator.pop(context);
                                      } else {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              "Phân loại danh mục thất bại",
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? cat['color'].withValues(
                                                  alpha: 0.2,
                                                )
                                              : Colors.grey.shade100,
                                          shape: BoxShape.circle,
                                          border: isSelected
                                              ? Border.all(
                                                  color: cat['color'],
                                                  width: 2,
                                                )
                                              : null,
                                        ),
                                        child: Icon(
                                          catIcon,
                                          color: isSelected
                                              ? cat['color']
                                              : Colors.black54,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        catName,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                          color: isSelected
                                              ? Colors.black87
                                              : Colors.black54,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
          if (_isUpdating)
            Container(
              color: Colors.black.withValues(alpha: 0.15),
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFFE91E63)),
              ),
            ),
        ],
      ),
    );
  }
}
