import 'package:flutter/material.dart';
import '../screens/bag_plus_benefits_screen.dart';

class BagPlusTab extends StatefulWidget {
  const BagPlusTab({Key? key}) : super(key: key);

  @override
  State<BagPlusTab> createState() => _BagPlusTabState();
}

class _BagPlusTabState extends State<BagPlusTab> {
  final PageController _pageController = PageController(viewportFraction: 0.88);
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  final List<Map<String, dynamic>> _tiers = [
    {
      'index': 0,
      'name': 'Hạng Bạc',
      'icon': Icons.shield_outlined,
      'iconColor': Colors.blueGrey,
      'headerColor': Color(0xFFF0F0F0),
      'bgColor': Color(0xFFFFF8F0),
      'borderColor': Color(0xFFE0E0E0),
      'benefits': [
        {
          'check': true,
          'text': 'Thêm ',
          'highlight': '50 triệu',
          'suffix': ' hạn mức rút miễn phí',
        },
        {
          'check': false,
          'text': 'Không hoàn tiền khi thanh toán',
          'highlight': null,
          'suffix': null,
        },
        {
          'check': true,
          'text': 'Thêm ',
          'highlight': '0,2%/năm',
          'suffix': ' lãi suất gửi tiết kiệm',
        },
        {
          'check': true,
          'text': 'Thêm ',
          'highlight': '1 Xu',
          'suffix': ' mỗi 10K thanh toán',
        },
      ],
    },
    {
      'index': 1,
      'name': 'Hạng Vàng',
      'icon': Icons.star_outline,
      'iconColor': Color(0xFFFFAA00),
      'headerColor': Color(0xFFFFF3CC),
      'bgColor': Color(0xFFFFFBF0),
      'borderColor': Color(0xFFFFD966),
      'benefits': [
        {
          'check': true,
          'text': 'Thêm ',
          'highlight': '100 triệu',
          'suffix': ' hạn mức rút miễn phí',
        },
        {
          'check': true,
          'text': 'Hoàn tiền thêm ',
          'highlight': '0,1%',
          'suffix': ' khi thanh toán dịch vụ hoá đơn',
        },
        {
          'check': true,
          'text': 'Thêm ',
          'highlight': '0,3%/năm',
          'suffix': ' lãi suất gửi tiết kiệm',
        },
        {
          'check': true,
          'text': 'Thêm ',
          'highlight': '2 Xu',
          'suffix': ' mỗi 10K thanh toán',
        },
      ],
    },
    {
      'index': 2,
      'name': 'Hạng Bạch Kim',
      'icon': Icons.diamond_outlined,
      'iconColor': Color(0xFF7B68EE),
      'headerColor': Color(0xFF3A3A4A),
      'bgColor': Color(0xFFF5F0FF),
      'borderColor': Color(0xFF9B8EC4),
      'isDark': true,
      'benefits': [
        {
          'check': true,
          'text': 'Hạn mức rút miễn phí ',
          'highlight': 'không giới hạn',
          'suffix': null,
        },
        {
          'check': true,
          'text': 'Hoàn tiền thêm ',
          'highlight': '0,1%',
          'suffix': ' không giới hạn',
        },
        {
          'check': true,
          'text': 'Thêm ',
          'highlight': '0,5%/năm',
          'suffix': ' lãi suất gửi tiết kiệm',
        },
        {
          'check': true,
          'text': 'Thêm ',
          'highlight': '4 Xu',
          'suffix': ' mỗi 10K thanh toán',
        },
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gradient header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFDE8C8), Color(0xFFFAC97A)],
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Túi+ là gì?',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Gói các quyền lợi giúp bạn sinh lời thêm và\nchi tiêu tốt hơn mỗi ngày',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.savings,
                    size: 44,
                    color: Color(0xFFE85D04),
                  ),
                ),
              ],
            ),
          ),

          // Announcement banner
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade100),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE85D04), Color(0xFFFF8C42)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Hạng Túi+ mới, quyền lợi mới!',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Khám phá chi tiết các quyền lợi của từng hạng, và\ncách sở hữu dưới đây!',
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Section title
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            child: RichText(
              text: const TextSpan(
                children: [
                  TextSpan(
                    text: 'Quyền lợi từ ',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  TextSpan(
                    text: 'Túi+',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE85D04),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Horizontally swipeable tier cards
          SizedBox(
            height: 320,
            child: PageView.builder(
              controller: _pageController,
              itemCount: _tiers.length,
              onPageChanged: (i) => setState(() => _currentPage = i),
              itemBuilder: (context, index) {
                final tier = _tiers[index];
                final isDark = tier['isDark'] == true;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: EdgeInsets.only(
                    right: 12,
                    top: _currentPage == index ? 0 : 12,
                    bottom: _currentPage == index ? 0 : 12,
                  ),
                  decoration: BoxDecoration(
                    color: tier['bgColor'] as Color,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: tier['borderColor'] as Color),
                  ),
                  child: Column(
                    children: [
                      // Tier header
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: tier['headerColor'] as Color,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(15),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              tier['icon'] as IconData,
                              size: 16,
                              color: isDark
                                  ? Colors.white70
                                  : tier['iconColor'] as Color,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              tier['name'] as String,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: isDark
                                    ? Colors.white
                                    : tier['iconColor'] as Color,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Benefits list
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              for (
                                var i = 0;
                                i < (tier['benefits'] as List).length;
                                i++
                              ) ...[
                                if (i > 0)
                                  const Divider(
                                    height: 1,
                                    color: Color(0xFFEEEEEE),
                                  ),
                                _buildBenefitRow(
                                  isCheck: tier['benefits'][i]['check'] as bool,
                                  text: tier['benefits'][i]['text'] as String,
                                  highlight:
                                      tier['benefits'][i]['highlight']
                                          as String?,
                                  suffix:
                                      tier['benefits'][i]['suffix'] as String?,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      // Explore button
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE85D04),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 0,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BagPlusBenefitsScreen(
                                    initialIndex: tier['index'] as int,
                                  ),
                                ),
                              );
                            },
                            child: const Text(
                              'Khám phá ngay',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Page indicator dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _tiers.length,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentPage == i ? 20 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentPage == i
                      ? const Color(0xFFE85D04)
                      : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // FAQ section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Câu hỏi thường gặp về Túi+',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildFaqItem(
                  'Túi+ là gì? Có khác với Túi Thần Tài không?',
                  'Túi+ là gói quyền lợi giúp người dùng Túi Thần Tài được hưởng nhiều lợi ích hơn khi sử dụng dịch vụ và không phải một Túi Thần Tài riêng biệt. Các quyền lợi hấp dẫn bao gồm hoàn tiền khi thanh toán với Túi Thần Tài, thêm hạn mức rút tiền miễn phí, tăng lãi suất khi gửi Tiết Kiệm Online... và nhiều quyền lợi khác được cập nhật theo từng thời điểm.',
                ),
                _buildFaqItem(
                  'Làm sao để sở hữu Túi+?',
                  'Có 2 cách:\n- Cách 1: Mua ngay để nhận quyền lợi Túi+ ngay sau khi thanh toán\n- Cách 2: Hoàn thành các điều kiện để nhận Túi+ miễn phí. Với cách này, quyền lợi Túi+ được nhận vào ngày đầu của tháng tiếp theo.\nBạn có thể mua ngay để sở hữu trong tháng này và đồng thời vẫn làm nhiệm vụ cho tháng kế tiếp.',
                ),
                _buildFaqItem(
                  'Thời gian sở hữu Túi+ là bao lâu?',
                  'Túi+ có thời hạn đến hết ngày cuối cùng của mỗi tháng. Bạn cần hoàn thành đủ điều kiện để nhận Túi+ miễn phí hoặc mua để sở hữu Túi+ tháng tiếp theo.',
                ),
                _buildFaqItem(
                  'Nếu tôi không hoàn thành điều kiện nhận Túi+ thì sao?',
                  'Khi qua tháng mới, nếu bạn không đạt điều kiện duy trì hoặc không mua lại, Túi+ hết hiệu lực và các quyền lợi (hoàn tiền, miễn phí rút, cộng lãi, nhận xu/quà...) sẽ không còn hiệu lực.',
                ),
                _buildFaqItem(
                  'Túi+ có bao nhiêu hạng?',
                  'Túi+ đang có 3 hạng với những bộ quyền lợi phù hợp, theo mức độ tăng dần\n- Hạng Bạc\n- Hạng Vàng\n- Hạng Bạch Kim\nBạn có thể nâng cấp lên hạng cao hơn để nhận quyền lợi tốt hơn bằng cách trả phí.',
                ),
                _buildFaqItem(
                  'Túi+ có tự gia hạn không?',
                  'Túi+ không tự gia hạn. Mỗi tháng bạn cần chủ động mua lại hoặc hoàn thành nhiệm vụ trước ngày cuối tháng để được xét cấp cho tháng kế tiếp.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildBenefitRow({
    required bool isCheck,
    required String text,
    required String? highlight,
    required String? suffix,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Icon(
            isCheck ? Icons.check : Icons.close,
            color: isCheck ? Colors.green : Colors.red,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: highlight != null
                ? RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                      children: [
                        TextSpan(text: text),
                        TextSpan(
                          text: highlight,
                          style: const TextStyle(
                            color: Color(0xFFE85D04),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (suffix != null) TextSpan(text: suffix),
                      ],
                    ),
                  )
                : Text(
                    text,
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return ExpansionTile(
      backgroundColor: Colors.white,
      collapsedBackgroundColor: Colors.white,
      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      title: Text(
        question,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
      trailing: const Icon(Icons.keyboard_arrow_down, color: Colors.black54),
      children: [
        Text(
          answer,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.black54,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
