import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../../../core/services/custom_http_client.dart';
import '../../../core/constants/api_config.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../screens/notification_screen.dart';
import '../../transfer/screens/transfer_confirm_screen.dart';
import '../../bank/screens/deposit_withdraw_screen.dart';
import '../../transfer/screens/transfer_search_screen.dart';

import '../../chat/screens/chat_list_screen.dart';
import '../../ai/screens/voice_transfer_dialog.dart';
import '../services/home_service.dart';
import '../screens/qr_main_screen.dart';
import '../../offers/screens/redeem_scratch_card_screen.dart';
import '../../topup/screens/topup_main_screen.dart';
class HomeHeader extends StatefulWidget {
  final String activeLang;
  final String token;
  final int unreadCount;
  final VoidCallback onRefreshUnread;
  final bool isVerified;
  final VoidCallback onRequireKyc;
  final VoidCallback onDepositWithdraw;

  const HomeHeader({
    Key? key,
    required this.activeLang,
    required this.token,
    required this.unreadCount,
    required this.onRefreshUnread,
    required this.isVerified,
    required this.onRequireKyc,
    required this.onDepositWithdraw,
  }) : super(key: key);

  @override
  State<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<HomeHeader> {
  Widget buildQuickAction(IconData icon, Color color, String title) {
    return GestureDetector(
      onTap: () {
        if (!widget.isVerified) {
          widget.onRequireKyc();
        } else {
          if (title == "Nạp/Rút" || title == "Deposit") {
            widget.onDepositWithdraw();
          } else if (title == "Nhận tiền" || title == "Receive") {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    QrMainScreen(token: widget.token, initialIndex: 1),
              ),
            );
          } else if (title == "QR Thanh toán" || title == "QR Pay") {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    QrMainScreen(token: widget.token, initialIndex: 0),
              ),
            );
          } else if (title == "Ví tiện ích" || title == "Utilities") {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text("Sorry", style: TextStyle(fontWeight: FontWeight.bold)),
                content: const Text("Tính năng sắp sửa ra mắt bạn vui lòng quay lại sau nhé!"),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("OK", style: TextStyle(color: Colors.pink)),
                  ),
                ],
              ),
            );
          } else {
            debugPrint("Đang mở tính năng: $title");
          }
        }
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE0F7FA), Color(0xFFF1F8E9), Colors.white],
        ),
      ),
      padding: const EdgeInsets.only(top: 50, left: 16, right: 16, bottom: 20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    readOnly: true,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TransferSearchScreen(token: widget.token),
                        ),
                      );
                    },
                    textAlignVertical: TextAlignVertical.center,
                    decoration: InputDecoration(
                      isDense: true,
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: Colors.grey,
                      ),
                      hintText: widget.activeLang == 'VIE'
                          ? "Tìm bạn bè để chuyển tiền"
                          : "Find friends to transfer",
                      hintStyle: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          NotificationScreen(token: widget.token),
                    ),
                  );
                  widget.onRefreshUnread(); // Refresh count when coming back
                },
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.pink.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.notifications_none_rounded,
                        size: 22,
                        color: Colors.pink,
                      ),
                    ),
                    if (widget.unreadCount > 0)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          child: Text(
                            widget.unreadCount > 99
                                ? '99+'
                                : widget.unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () async {
                  final result = await showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) =>
                        VoiceTransferDialog(token: widget.token),
                  );

                  if (result != null) {
                    if (result['error'] != null) {
                      SnackbarUtils.showError(context, result['error']);
                    } else if (result['amount'] != null) {
                      String actionType = result['action_type'] ?? "TRANSFER";

                      if (actionType == "DEPOSIT") {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DepositWithdrawScreen(
                              token: widget.token,
                              initialTab: 0,
                              initialAmount: result['amount'].toString(),
                            ),
                          ),
                        );
                        return;
                      } else if (actionType == "WITHDRAW") {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DepositWithdrawScreen(
                              token: widget.token,
                              initialTab: 1,
                              initialAmount: result['amount'].toString(),
                            ),
                          ),
                        );
                        return;
                      } else if (actionType == "BUY_CARD" || actionType == "REDEEM_CARD") {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TopupMainScreen(
                              token: widget.token,
                              initialTab: 0,
                              initialProvider: result['receiver_name'],
                              initialValue: result['amount'],
                            ),
                          ),
                        );
                        return;
                      }

                      String rName = result['receiver_name'] ?? "";
                      String rPhone = "0";

                      if (rName.isEmpty) {
                        SnackbarUtils.showError(
                          context,
                          'Không nghe rõ tên người nhận. Vui lòng thử lại!',
                        );
                      } else {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => const Center(
                            child: CircularProgressIndicator(
                              color: Colors.pink,
                            ),
                          ),
                        );

                        try {
                          final homeService = HomeService();
                          List<Map<String, dynamic>> matchedUsers =
                              await homeService.searchUsersByVoice(rName);

                          final PermissionStatus permissionStatus =
                              await Permission.contacts.request();
                          if (permissionStatus == PermissionStatus.granted) {
                            final contacts = await FlutterContacts.getContacts(
                              withProperties: true,
                            );
                            String searchName = rName.toLowerCase();
                            for (var contact in contacts) {
                              String displayName = contact.displayName
                                  .toLowerCase();
                              if (displayName.contains(searchName) ||
                                  searchName.contains(displayName)) {
                                if (contact.phones.isNotEmpty) {
                                  String num = contact.phones.first.number
                                      .replaceAll(RegExp(r'[^0-9+]'), '');
                                  if (num.startsWith('+84'))
                                    num = '0${num.substring(3)}';
                                  if (num.startsWith('84'))
                                    num = '0${num.substring(2)}';
                                  if (num.length >= 10 && num.length <= 11) {
                                    bool exists = matchedUsers.any(
                                      (u) => u['phone'] == num,
                                    );
                                    if (!exists) {
                                      matchedUsers.add({
                                        'name': contact.displayName,
                                        'phone': num,
                                        'source': 'Danh bạ',
                                      });
                                    }
                                  }
                                }
                              }
                            }
                          }

                          if (mounted) Navigator.pop(context); // Tắt loading

                          if (matchedUsers.isEmpty) {
                            SnackbarUtils.showError(
                              context,
                              'Không tìm thấy "$rName" trong danh bạ hoặc trên hệ thống.',
                            );
                          } else if (matchedUsers.length == 1) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TransferConfirmScreen(
                                  token: widget.token,
                                  receiverPhone: matchedUsers[0]['phone'],
                                  receiverName: matchedUsers[0]['name'],
                                  amount: result['amount'].toString(),
                                  note: result['note'] ?? "",
                                ),
                              ),
                            );
                          } else {
                            final selected =
                                await showModalBottomSheet<
                                  Map<String, dynamic>
                                >(
                                  context: context,
                                  backgroundColor: Colors.white,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(20),
                                    ),
                                  ),
                                  builder: (context) {
                                    return SafeArea(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const SizedBox(height: 16),
                                          const Text(
                                            "Tìm thấy nhiều kết quả, vui lòng chọn:",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          const Divider(),
                                          Flexible(
                                            child: ListView.builder(
                                              shrinkWrap: true,
                                              itemCount: matchedUsers.length,
                                              itemBuilder: (context, index) {
                                                final u = matchedUsers[index];
                                                return ListTile(
                                                  leading: CircleAvatar(
                                                    backgroundColor:
                                                        u['source'] == 'Mio App'
                                                        ? Colors.blue.shade100
                                                        : Colors.green.shade100,
                                                    child: Icon(
                                                      u['source'] == 'Mio App'
                                                          ? Icons.app_shortcut
                                                          : Icons.contacts,
                                                      color:
                                                          u['source'] ==
                                                              'Mio App'
                                                          ? Colors.blue
                                                          : Colors.green,
                                                      size: 20,
                                                    ),
                                                  ),
                                                  title: Text(
                                                    u['name'],
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  subtitle: Text(
                                                    '${u['phone']} • ${u['source']}',
                                                  ),
                                                  onTap: () =>
                                                      Navigator.pop(context, u),
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                );

                            if (selected != null) {
                              if (mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => TransferConfirmScreen(
                                      token: widget.token,
                                      receiverPhone: selected['phone'],
                                      receiverName: selected['name'],
                                      amount: result['amount'].toString(),
                                      note: result['note'] ?? "",
                                    ),
                                  ),
                                );
                              }
                            }
                          }
                        } catch (e) {
                          debugPrint("Voice Transfer search error: $e");
                          if (mounted)
                            Navigator.pop(
                              context,
                            ); // Đảm bảo tắt loading nếu lỗi
                        }
                      }
                    }
                  }
                },
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.pink.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    size: 22,
                    color: Colors.pink,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatListScreen(token: widget.token),
                    ),
                  );
                },
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.pink.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 20,
                    color: Colors.pink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                buildQuickAction(
                  Icons.account_balance_wallet_rounded,
                  Colors.pink,
                  widget.activeLang == 'VIE' ? "Nạp/Rút" : "Deposit",
                ),
                buildQuickAction(
                  Icons.qr_code_rounded,
                  Colors.pink,
                  widget.activeLang == 'VIE' ? "Nhận tiền" : "Receive",
                ),
                buildQuickAction(
                  Icons.qr_code_scanner_rounded,
                  Colors.pink,
                  widget.activeLang == 'VIE' ? "QR Thanh toán" : "QR Pay",
                ),
                buildQuickAction(
                  Icons.apps_rounded,
                  Colors.pink,
                  widget.activeLang == 'VIE' ? "Ví tiện ích" : "Utilities",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
