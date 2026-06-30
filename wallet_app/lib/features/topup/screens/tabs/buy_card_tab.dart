import 'package:flutter/material.dart';
import '../../../../core/widgets/pin_confirm_bottom_sheet.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../services/topup_service.dart';
import '../../../offers/screens/redeem_success_screen.dart';

class BuyCardTab extends StatefulWidget {
  final String token;
  final String? initialProvider;
  final int? initialValue;

  const BuyCardTab({
    Key? key, 
    required this.token,
    this.initialProvider,
    this.initialValue,
  }) : super(key: key);

  @override
  State<BuyCardTab> createState() => _BuyCardTabState();
}

class _BuyCardTabState extends State<BuyCardTab> {
  final List<String> _providers = ['Viettel', 'Mobifone', 'Vinaphone', 'Vietnamobile'];
  final List<int> _values = [10000, 20000, 30000, 50000, 100000, 200000, 300000, 500000];

  String? _selectedProvider;
  int? _selectedValue;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialProvider != null && _providers.contains(widget.initialProvider)) {
      _selectedProvider = widget.initialProvider;
    }
    if (widget.initialValue != null && _values.contains(widget.initialValue)) {
      _selectedValue = widget.initialValue;
    }
    
    // Auto show confirm dialog if both are provided by AI
    if (_selectedProvider != null && _selectedValue != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showConfirmDialog();
      });
    }
  }

  void _showConfirmDialog() {
    if (_selectedProvider == null || _selectedValue == null) {
      SnackbarUtils.showError(context, 'Vui lòng chọn nhà mạng và mệnh giá');
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PinConfirmBottomSheet(
        onPinEntered: (pin) async {
          Navigator.pop(context); // Close PIN
          await _processTopup();
          return null; // Don't show pin error here, handle below
        },
      ),
    );
  }

  Future<void> _processTopup() async {
    setState(() => _isLoading = true);
    try {
      final service = TopupService(token: widget.token);
      final result = await service.processTopup(
        type: 'CARD',
        provider: _selectedProvider,
        amount: _selectedValue!,
      );

      if (!mounted) return;
      
      // Navigate to success screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => RedeemSuccessScreen(
            provider: result['provider'],
            faceValue: result['amount'],
            cardCode: result['cardCode'],
            serial: result['serial'],
            deductedPoints: result['amount'], // We use deducted points to show money deducted
            transactionId: result['transaction_id'].toString(),
            isMoney: true,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      SnackbarUtils.showError(context, e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatNumber(int value) {
    return value.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.pink));
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Chọn nhà mạng', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _providers.map((p) {
              final isSelected = _selectedProvider == p;
              return GestureDetector(
                onTap: () => setState(() => _selectedProvider = p),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.pink.shade50 : Colors.white,
                    border: Border.all(color: isSelected ? Colors.pink : Colors.grey.shade300, width: isSelected ? 2 : 1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    p,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.pink : Colors.black87,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          const Text('Chọn mệnh giá', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 2.5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _values.length,
            itemBuilder: (context, index) {
              final val = _values[index];
              final isSelected = _selectedValue == val;
              return GestureDetector(
                onTap: () => setState(() => _selectedValue = val),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.pink.shade50 : Colors.white,
                    border: Border.all(color: isSelected ? Colors.pink : Colors.grey.shade300, width: isSelected ? 2 : 1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_formatNumber(val)}đ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.pink : Colors.black87,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: (_selectedProvider != null && _selectedValue != null) ? _showConfirmDialog : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Mua ngay', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }
}
