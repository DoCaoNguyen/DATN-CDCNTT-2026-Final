import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PinConfirmBottomSheet extends StatefulWidget {
  final Future<String?> Function(String pin) onPinEntered;
  final String title;
  final String subtitle;

  const PinConfirmBottomSheet({
    Key? key,
    required this.onPinEntered,
    this.title = 'Xác thực bảo mật',
    this.subtitle = 'Vui lòng nhập mã PIN để xem API Keys',
  }) : super(key: key);

  @override
  State<PinConfirmBottomSheet> createState() => _PinConfirmBottomSheetState();
}

class _PinConfirmBottomSheetState extends State<PinConfirmBottomSheet> {
  String _pin = '';
  bool _isLoading = false;
  String? _errorMsg;

  void _onNumberTap(String number) {
    if (_pin.length < 6) {
      setState(() {
        _pin += number;
        _errorMsg = null;
      });
      if (_pin.length == 6) {
        _verifyPin();
      }
    }
  }

  void _onDeleteTap() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
        _errorMsg = null;
      });
    }
  }

  Future<void> _verifyPin() async {
    setState(() => _isLoading = true);
    
    // Simulate short delay for better UX
    await Future.delayed(const Duration(milliseconds: 300));
    
    final error = await widget.onPinEntered(_pin);
    
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (error != null) {
          _errorMsg = error;
          _pin = ''; // Reset pin on error
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Icon(Icons.lock_outline_rounded, size: 48, color: Colors.pink),
            const SizedBox(height: 16),
            Text(
              widget.title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              widget.subtitle,
              style: const TextStyle(fontSize: 14, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
            // PIN Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (index) {
                bool isFilled = index < _pin.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isFilled ? Colors.pink : Colors.grey.shade200,
                    border: Border.all(
                      color: isFilled ? Colors.pink : Colors.grey.shade300,
                      width: 1,
                    ),
                  ),
                );
              }),
            ),
            
            if (_errorMsg != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  _errorMsg!,
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                ),
              ),
              
            const SizedBox(height: 32),
            
            if (_isLoading)
              const CircularProgressIndicator(color: Colors.pink)
            else
              // Numpad
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 1.5,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                ),
                itemCount: 12,
                itemBuilder: (context, index) {
                  if (index == 9) return const SizedBox(); // Empty space bottom left
                  if (index == 11) {
                    // Delete button
                    return InkWell(
                      onTap: _onDeleteTap,
                      customBorder: const CircleBorder(),
                      child: const Center(
                        child: Icon(Icons.backspace_outlined, color: Colors.black54),
                      ),
                    );
                  }
                  
                  // Numbers 1-9 and 0
                  final number = index == 10 ? '0' : '${index + 1}';
                  return InkWell(
                    onTap: () => _onNumberTap(number),
                    customBorder: const CircleBorder(),
                    child: Center(
                      child: Text(
                        number,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
                      ),
                    ),
                  );
                },
              ),
              
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
