import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../features/dashboard/data/dashboard_repository.dart';

class AddAddressBottomSheet extends StatefulWidget {
  final VoidCallback onAddressAdded;

  const AddAddressBottomSheet({super.key, required this.onAddressAdded});

  @override
  State<AddAddressBottomSheet> createState() => _AddAddressBottomSheetState();
}

class _AddAddressBottomSheetState extends State<AddAddressBottomSheet> {
  final _labelController = TextEditingController();
  final _lineController = TextEditingController();
  final _cityController = TextEditingController();
  final _zipController = TextEditingController();
  bool _isSaving = false;

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
    const Color primaryColor = Color(0xFFD4AF37); // Gold accent
    const Color inputFillColor = Color(0xFFF7F7F7);

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
          
          const Text(
            "Add New Address",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.5),
          ),
          const SizedBox(height: 8),
          Text(
            "Enter your delivery details to continue",
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
                  : const Text(
                      "SAVE & CONTINUE",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1),
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
      await repo.addAddress({
        "label": _labelController.text,
        "address_line": _lineController.text,
        "city": _cityController.text,
        "zip_code": _zipController.text,
      });
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
Future<void> showAddAddressSheet(BuildContext context, VoidCallback onAdded) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => AddAddressBottomSheet(onAddressAdded: onAdded),
  );
}
