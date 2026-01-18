import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../features/dashboard/data/dashboard_repository.dart';

class AddAddressBottomSheet extends StatefulWidget {
  final VoidCallback onAddressAdded;
  final Map<String, dynamic>? initialAddress;

  const AddAddressBottomSheet({
    super.key, 
    required this.onAddressAdded,
    this.initialAddress,
  });

  @override
  State<AddAddressBottomSheet> createState() => _AddAddressBottomSheetState();
}

class _AddAddressBottomSheetState extends State<AddAddressBottomSheet> {
  late final TextEditingController _labelController;
  late final TextEditingController _lineController;
  late final TextEditingController _cityController;
  late final TextEditingController _zipController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.initialAddress?['label'] ?? '');
    _lineController = TextEditingController(text: widget.initialAddress?['address_line'] ?? '');
    _cityController = TextEditingController(text: widget.initialAddress?['city'] ?? '');
    _zipController = TextEditingController(text: widget.initialAddress?['zip_code'] ?? '');
  }

  @override
  void dispose() {
    _labelController.dispose();
    _lineController.dispose();
    _cityController.dispose();
    _zipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color inputFillColor = Color(0xFFF7F7F7);
    final isEditing = widget.initialAddress != null;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 12,
        left: 24,
        right: 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          Text(
            isEditing ? "Update Address" : "Add New Address",
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.5),
          ),
          const SizedBox(height: 8),
          Text(
            isEditing ? "Modify your address details below" : "Enter your delivery details to continue",
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          const SizedBox(height: 24),

          _buildTextField(
            controller: _labelController,
            label: "Address Label",
            hint: "e.g. Home, Work, Gym",
            icon: Icons.label_important_outline,
            fillColor: inputFillColor,
          ),
          const SizedBox(height: 16),
          
          _buildTextField(
            controller: _lineController,
            label: "Address Line",
            hint: "House No, Street, Landmark",
            icon: Icons.location_on_outlined,
            fillColor: inputFillColor,
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _cityController,
                  label: "City",
                  hint: "Your City",
                  icon: Icons.apartment_outlined,
                  fillColor: inputFillColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: _zipController,
                  label: "Zip Code",
                  hint: "6 Digits",
                  icon: Icons.pin_drop_outlined,
                  keyboardType: TextInputType.number,
                  fillColor: inputFillColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveAddress,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: _isSaving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      isEditing ? "UPDATE ADDRESS" : "SAVE & CONTINUE",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    required Color fillColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: Colors.grey[500], size: 20),
            filled: true,
            fillColor: fillColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          ),
        ),
      ],
    );
  }

  Future<void> _saveAddress() async {
    if (_labelController.text.isEmpty || _lineController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in the required fields")),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final repo = context.read<DashboardRepository>();
      final data = {
        "label": _labelController.text,
        "address_line": _lineController.text,
        "city": _cityController.text,
        "zip_code": _zipController.text,
      };

      if (widget.initialAddress != null) {
        await repo.updateAddress(widget.initialAddress!['id'], data);
      } else {
        await repo.addAddress(data);
      }

      if (mounted) {
        widget.onAddressAdded();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

// Global static helper to show the sheet
Future<void> showAddAddressSheet(BuildContext context, VoidCallback onAdded, {Map<String, dynamic>? initialAddress}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => AddAddressBottomSheet(
      onAddressAdded: onAdded,
      initialAddress: initialAddress,
    ),
  );
}
