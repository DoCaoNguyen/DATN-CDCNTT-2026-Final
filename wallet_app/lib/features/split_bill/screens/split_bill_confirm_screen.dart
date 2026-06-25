import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/services/custom_http_client.dart';
import '../../../core/constants/api_config.dart';
import 'split_bill_success_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class SplitBillConfirmScreen extends StatefulWidget {
  final String token;
  final Map<String, dynamic> transactionData;
  final Map<String, dynamic> me;
  final List<Map<String, dynamic>> selectedFriends;
  final double totalAmount;

  const SplitBillConfirmScreen({
    Key? key,
    required this.token,
    required this.transactionData,
    required this.me,
    required this.selectedFriends,
    required this.totalAmount,
  }) : super(key: key);

  @override
  State<SplitBillConfirmScreen> createState() => _SplitBillConfirmScreenState();
}

class _SplitBillConfirmScreenState extends State<SplitBillConfirmScreen> {
  final NumberFormat _formatter = NumberFormat('#,###', 'vi_VN');
  final TextEditingController _noteController = TextEditingController();

  late List<Map<String, dynamic>> _activeFriends;
  bool _isMeActive = true;
  bool _isLoading = false;
  XFile? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _noteController.text = "Chia tiền!";
    _activeFriends = List.from(widget.selectedFriends);
  }

  int get _activeCount {
    int count = _activeFriends.length;
    if (_isMeActive) count++;
    return count;
  }

  double get _splitAmount {
    if (_activeCount == 0) return 0;
    return widget.totalAmount / _activeCount;
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
    }
  }

  void _sendRequest() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final client = CustomHttpClient();
      List<Map<String, dynamic>> members = [];

      // Add 'me' to members if active. We can use our own id from token? Wait, widget.me might not have real ID.
      // Actually widget.me was hardcoded as 'id': 'me'. But on backend, we just need friends, backend handles creator.
      // Wait, no! My backend logic expects `user_id` for everyone including creator!
      // But we don't have our own ID in `widget.me`. It's hardcoded as 'me'.
      // If we pass 'me', backend might fail parsing to UUID. Let's just exclude 'me' from payload?
      // Ah, in backend: `if member.user_id === creatorId ...`. So we must send our REAL user_id.
      // Wait, I can just fetch our user_id from profile API or from JWT token!
      // Actually, my backend code says: `for (const member of members) { ... }`.
      // I can change backend to automatically insert creator, OR just pass correct ID.
      // But wait! Since the user_id is UUID now, sending 'me' will fail.
      // Let's modify the flutter logic to NOT send 'me', and we'll fix the backend to automatically add creator to `split_bill_members` if `_isMeActive`!
      // Let's pass a boolean `include_me: _isMeActive`.

      for (var f in _activeFriends) {
        members.add({'user_id': f['id'], 'amount': _splitAmount});
      }

      final response = await client.post(
        Uri.parse('${ApiConfig.baseUrl}/split-bill/create'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'total_amount': widget.totalAmount,
          'split_amount': _splitAmount,
          'note': _noteController.text,
          'members': members,
          'include_me': _isMeActive,
        }),
      );

      if (response.statusCode == 201) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          List<Map<String, dynamic>> finalFriends = List.from(_activeFriends);
          if (_isMeActive) {
            finalFriends.insert(0, widget.me);
          }

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SplitBillSuccessScreen(
                token: widget.token,
                transactionData: widget.transactionData,
                me: widget.me,
                activeFriends: finalFriends,
                splitAmount: _splitAmount,
                totalAmount: widget.totalAmount,
                note: _noteController.text,
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Có lỗi xảy ra, vui lòng thử lại!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi kết nối: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFFE4E1), Color(0xFFF6F8FB)],
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.black87),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              "Chia tiền",
              style: TextStyle(
                color: Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.home_rounded, color: Colors.black54),
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header block inside the main card area
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Tổng tiền",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black54,
                              ),
                            ),
                            Text(
                              "${_formatter.format(widget.totalAmount)}đ",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Dashed line (mocked as simple border here)
                      Container(
                        height: 1,
                        color: Colors.grey.shade200,
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      // Message Box
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Stack(
                            children: [
                              TextField(
                                controller: _noteController,
                                maxLines: 4,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.all(12),
                                  hintText: "Nhập lời nhắn...",
                                ),
                              ),
                              if (_selectedImage != null)
                                Positioned(
                                  bottom: 12,
                                  left: 12,
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(8),
                                      image: DecorationImage(
                                        image: FileImage(
                                          File(_selectedImage!.path),
                                        ),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    child: Align(
                                      alignment: Alignment.topRight,
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _selectedImage = null;
                                          });
                                        },
                                        child: Container(
                                          margin: const EdgeInsets.all(2),
                                          decoration: const BoxDecoration(
                                            color: Colors.black54,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            size: 10,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              Positioned(
                                bottom: 12,
                                right: 12,
                                child: GestureDetector(
                                  onTap: _pickImage,
                                  child: Icon(
                                    Icons.image_outlined,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Suggestion pills
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.only(left: 16, bottom: 16),
                        child: Row(
                          children: [
                            _buildSuggestionPill("tiền trà sữa"),
                            _buildSuggestionPill("tiền cơm trưa"),
                            _buildSuggestionPill("tiền nhậu"),
                            _buildSuggestionPill("tiền bún bò"),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // List of Members
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Danh sách (${_activeCount})",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Me
                      _buildMemberRow(
                        widget.me,
                        isActive: _isMeActive,
                        amount: _splitAmount,
                        onChanged: (val) {
                          if (val == true || _activeCount > 1) {
                            setState(() => _isMeActive = val ?? true);
                          }
                        },
                      ),

                      // Friends
                      ...widget.selectedFriends.map((f) {
                        bool isActive = _activeFriends.any(
                          (af) => af['id'] == f['id'],
                        );
                        return _buildMemberRow(
                          f,
                          isActive: isActive,
                          amount: _splitAmount,
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                _activeFriends.add(f);
                              } else {
                                if (_activeCount > 1) {
                                  _activeFriends.removeWhere(
                                    (af) => af['id'] == f['id'],
                                  );
                                }
                              }
                            });
                          },
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.15),
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFFE91E63)),
              ),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: (_activeCount > 0 && _activeFriends.isNotEmpty)
                  ? _sendRequest
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE91E63),
                disabledBackgroundColor: Colors.grey.shade300,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                "Gửi yêu cầu (${_activeFriends.length})",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionPill(String text) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _noteController.text = text;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(text, style: const TextStyle(color: Colors.black87)),
      ),
    );
  }

  Widget _buildMemberRow(
    Map<String, dynamic> member, {
    required bool isActive,
    required double amount,
    required Function(bool?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Checkbox(
            value: isActive,
            activeColor: const Color(0xFFE91E63),
            onChanged: onChanged,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          CircleAvatar(
            radius: 20,
            backgroundColor: member['color'] ?? Colors.pink.shade50,
            backgroundImage: member['avatar'] != null
                ? NetworkImage(member['avatar'])
                : null,
            child: member['avatar'] == null
                ? Text(
                    member['initials'] ?? '',
                    style: const TextStyle(
                      color: Color(0xFFE91E63),
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
                  member['name'],
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: isActive ? Colors.black87 : Colors.grey,
                  ),
                ),
                member['phone'] != null &&
                        member['phone'].toString().contains('*')
                    ? Text.rich(
                        TextSpan(
                          children: member['phone'].toString().split('').map((
                            char,
                          ) {
                            if (char == '*') {
                              return WidgetSpan(
                                alignment: PlaceholderAlignment.middle,
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    '*',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                      fontFamily: 'monospace',
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ),
                              );
                            }
                            return TextSpan(
                              text: char,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                                fontFamily: 'monospace',
                                letterSpacing: 1.2,
                              ),
                            );
                          }).toList(),
                        ),
                      )
                    : Text(
                        member['phone'] ?? '',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                          fontFamily: 'monospace',
                          letterSpacing: 1.2,
                        ),
                      ),
              ],
            ),
          ),
          Text(
            isActive ? "${_formatter.format(amount)}đ" : "0đ",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isActive ? Colors.black87 : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
