import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/dashboard_repository.dart';

class AddressesScreen extends StatefulWidget {
  const AddressesScreen({super.key});

  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  List<dynamic> _addresses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAddresses();
  }

  Future<void> _fetchAddresses() async {
    try {
      final repo = context.read<DashboardRepository>();
      final addresses = await repo.getAddresses();
      if (mounted) {
        setState(() {
          _addresses = addresses;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addNewAddress() async {
    final labelController = TextEditingController();
    final lineController = TextEditingController();
    final cityController = TextEditingController();
    final zipController = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, top: 20, left: 20, right: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Add New Address", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(controller: labelController, decoration: const InputDecoration(labelText: "Label (e.g. Home, Office)")),
            TextField(controller: lineController, decoration: const InputDecoration(labelText: "Address Line")),
            TextField(controller: cityController, decoration: const InputDecoration(labelText: "City")),
            TextField(controller: zipController, decoration: const InputDecoration(labelText: "Zip Code (6 digits)"), keyboardType: TextInputType.number),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  try {
                    final repo = context.read<DashboardRepository>();
                    await repo.addAddress({
                      "label": labelController.text,
                      "address_line": lineController.text,
                      "city": cityController.text,
                      "zip_code": zipController.text,
                    });
                    Navigator.pop(ctx);
                    _fetchAddresses();
                  } catch (e) {
                    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(e.toString())));
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
                child: const Text("SAVE ADDRESS"),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text("My Addresses", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.orange),
            onPressed: _addNewAddress,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _addresses.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_off_outlined, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      const Text("No addresses saved", style: TextStyle(fontSize: 18, color: Colors.grey)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _addNewAddress,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
                        child: const Text("Add New Address"),
                      )
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _addresses.length,
                  itemBuilder: (context, index) {
                    final addr = _addresses[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(addr['label'].toString().toLowerCase() == 'home' ? Icons.home : Icons.work, color: Colors.orange),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(addr['label'] ?? "Address", style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text(addr['address_line'] ?? "", style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                                Text("${addr['city']}, ${addr['zip_code']}", style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                              ],
                            ),
                          ),
                          IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () {}), // Delete not implemented yet but UI looks better
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
