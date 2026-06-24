import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/api_config.dart';
import '../../../core/services/custom_http_client.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/utils/currency_formatter.dart';

class RedPacketDialog extends StatefulWidget {
  final String token;
  final String redPacketId;

  const RedPacketDialog({
    Key? key,
    required this.token,
    required this.redPacketId,
  }) : super(key: key);

  @override
  State<RedPacketDialog> createState() => _RedPacketDialogState();
}

class _RedPacketDialogState extends State<RedPacketDialog>
    with SingleTickerProviderStateMixin {
  final _client = CustomHttpClient();
  bool _isLoading = true;
  bool _isClaiming = false;
  Map<String, dynamic>? _details;

  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.elasticOut,
    );

    _fetchDetails();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _fetchDetails() async {
    try {
      final response = await _client.get(
        Uri.parse(ApiConfig.getRedPacketDetails(widget.redPacketId)),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _details = data['data'];
            _isLoading = false;
          });
          _animController.forward();
        }
      } else {
        if (mounted) {
          Navigator.pop(context);
          SnackbarUtils.showError(context, 'Lỗi lấy thông tin lì xì');
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        SnackbarUtils.showError(context, 'Lỗi kết nối mạng');
      }
    }
  }

  Future<void> _claim() async {
    setState(() => _isClaiming = true);
    try {
      final response = await _client.post(
        Uri.parse(ApiConfig.claimRedPacket(widget.redPacketId)),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (response.statusCode == 200) {
        // Mở thành công
        await _fetchDetails();
      } else {
        final err = jsonDecode(response.body);
        SnackbarUtils.showError(context, err['error'] ?? 'Lỗi nhận lì xì');
      }
    } catch (e) {
      SnackbarUtils.showError(context, 'Lỗi kết nối mạng');
    } finally {
      if (mounted) setState(() => _isClaiming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.red));
    }

    if (_details == null) return const SizedBox();

    final isCreator = _details!['is_creator'] == true;
    final myClaim = _details!['my_claim'];
    final status = _details!['status']; // ACTIVE, EXHAUSTED
    final receivers = List<dynamic>.from(_details!['receivers'] ?? []);

    final hasClaimed = myClaim != null;
    final canClaim = status == 'ACTIVE' && !hasClaimed && !isCreator;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            width: 320,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFD32F2F),
              borderRadius: BorderRadius.circular(16),
              image: const DecorationImage(
                image: NetworkImage(
                  'https://www.transparenttextures.com/patterns/cubes.png',
                ),
                repeat: ImageRepeat.repeat,
                opacity: 0.1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Stack(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 36),
                      // Người gửi
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.amber.shade100,
                        child: Text(
                          (_details!['creator_name'] ?? 'U')[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${_details!['creator_name']} đã gửi lì xì',
                        style: const TextStyle(
                          color: Colors.amber,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          _details!['message'] ?? 'Cung hỉ phát tài',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Content: Chưa mở / Đã mở
                      if (canClaim)
                        GestureDetector(
                          onTap: _isClaiming ? null : _claim,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 100,
                            height: 100,
                            decoration: const BoxDecoration(
                              color: Colors.amber,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: _isClaiming
                                  ? const CircularProgressIndicator(
                                      color: Colors.red,
                                    )
                                  : const Text(
                                      'MỞ',
                                      style: TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red,
                                      ),
                                    ),
                            ),
                          ),
                        )
                      else if (hasClaimed)
                        Column(
                          children: [
                            const Text(
                              'Bạn đã nhận được',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              CurrencyFormatter.format(
                                myClaim['amount'].toString(),
                              ),
                              style: const TextStyle(
                                color: Colors.amber,
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text(
                                'Tiền đã vào ví',
                                style: TextStyle(
                                  color: Colors.white,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        )
                      else if (status == 'EXHAUSTED')
                        const Column(
                          children: [
                            Icon(
                              Icons.sentiment_dissatisfied_rounded,
                              color: Colors.white54,
                              size: 48,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Lì xì đã được giật hết',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                      else if (isCreator)
                        const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          child: Text(
                            'Bạn là người gửi bao lì xì này',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),

                      const SizedBox(height: 36),

                      // Lịch sử nhận
                      if (receivers.isNotEmpty)
                        Flexible(
                          child: Container(
                            width: double.infinity,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(16),
                                bottomRight: Radius.circular(16),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Text(
                                    'Đã nhận ${receivers.length}/${_details!['total_count']}',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Flexible(
                                  child: ListView.builder(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    shrinkWrap: true,
                                    itemCount: receivers.length,
                                    itemBuilder: (context, index) {
                                      final r = receivers[index];
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 8,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                CircleAvatar(
                                                  radius: 16,
                                                  backgroundColor:
                                                      Colors.grey.shade200,
                                                  child: Text(
                                                    (r['receiver_name'] ??
                                                            'U')[0]
                                                        .toUpperCase(),
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  r['receiver_name'] ?? '',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Text(
                                              CurrencyFormatter.format(
                                                r['amount'].toString(),
                                              ),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        const SizedBox(height: 48), // Padding dưới nếu ko có ds
                    ],
                  ),
                ),
                // Close btn
                Positioned(
                  top: 8,
                  left: 8,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
