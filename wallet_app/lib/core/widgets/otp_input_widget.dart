import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';

class OtpInputWidget extends StatefulWidget {
  final int length;
  final ValueChanged<String> onChanged;
  final VoidCallback? onCompleted;
  final bool hasError;

  const OtpInputWidget({
    Key? key,
    this.length = 6,
    required this.onChanged,
    this.onCompleted,
    this.hasError = false,
  }) : super(key: key);

  @override
  State<OtpInputWidget> createState() => _OtpInputWidgetState();
}

class _OtpInputWidgetState extends State<OtpInputWidget> {
  late List<FocusNode> _focusNodes;
  late List<TextEditingController> _controllers;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _focusNodes = List.generate(widget.length, (index) {
      final node = FocusNode();
      node.addListener(() {
        if (node.hasFocus) {
          setState(() {
            _currentIndex = index;
          });
        }
      });
      return node;
    });
    _controllers = List.generate(widget.length, (_) => TextEditingController());

    // Auto focus first node
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        FocusScope.of(context).requestFocus(_focusNodes[0]);
      }
    });
  }

  @override
  void dispose() {
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _notifyChange() {
    String otp = _controllers.map((c) => c.text).join();
    widget.onChanged(otp);
    if (otp.length == widget.length && widget.onCompleted != null) {
      widget.onCompleted!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(widget.length, (index) {
        final isFocused = _currentIndex == index;
        final hasValue = _controllers[index].text.isNotEmpty;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 48,
          height: 56,
          decoration: BoxDecoration(
            color: isFocused
                ? Colors.white
                : (hasValue ? Colors.white : Colors.grey.shade100),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.hasError
                  ? Colors.red
                  : (isFocused
                        ? AppColors.primaryPink
                        : (hasValue
                              ? AppColors.primaryPink.withOpacity(0.5)
                              : Colors.transparent)),
              width: isFocused ? 2 : 1,
            ),
            boxShadow: isFocused
                ? [
                    BoxShadow(
                      color: AppColors.primaryPink.withOpacity(0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: TextField(
              controller: _controllers[index],
              focusNode: _focusNodes[index],
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 1,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: widget.hasError ? Colors.red : Colors.black87,
              ),
              cursorColor: AppColors.primaryPink,
              showCursor: isFocused,
              decoration: const InputDecoration(
                counterText: '',
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (value) {
                if (value.isNotEmpty) {
                  if (index < widget.length - 1) {
                    FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
                  } else {
                    FocusScope.of(context).unfocus();
                  }
                } else {
                  if (index > 0) {
                    FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
                  }
                }
                _notifyChange();
              },
            ),
          ),
        );
      }),
    );
  }
}
