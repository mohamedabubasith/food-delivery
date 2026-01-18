import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/dashboard_repository.dart';
import '../../../common_widgets/add_address_sheet.dart';

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
    await showAddAddressSheet(context, _fetchAddresses);
  }

  Future<void> _editAddress(Map<String, dynamic> address) async {
    await showAddAddressSheet(context, _fetchAddresses, initialAddress: address);
  }

  Future<void> _setAsPrimary(int id) async {
    try {
      final repo = context.read<DashboardRepository>();
      await repo.setPrimaryAddress(id);
      _fetchAddresses();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Primary address updated")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _deleteAddress(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Address?"),
        content: const Text("Are you sure you want to remove this address?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("CANCEL")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("DELETE", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await context.read<DashboardRepository>().deleteAddress(id);
        _fetchAddresses();
      } catch (e) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
        }
      }
    }
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
                    final isPrimary = addr['is_primary'] == true;
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isPrimary ? Colors.orange : Colors.grey.shade200),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                  child: Icon(addr['label'].toString().toLowerCase() == 'home' ? Icons.home : Icons.work, color: Colors.orange, size: 20),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(addr['label'] ?? "Address", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                          if (isPrimary) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                                              child: const Text("PRIMARY", style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                                            )
                                          ]
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(addr['address_line'] ?? "", style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                                      Text("${addr['city']}, ${addr['zip_code']}", style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (!isPrimary)
                                  TextButton(
                                    onPressed: () => _setAsPrimary(addr['id']),
                                    child: const Text("SET AS DEFAULT", style: TextStyle(color: Colors.grey, fontSize: 12)),
                                  ),
                                TextButton(
                                  onPressed: () => _editAddress(addr),
                                  child: const Text("EDIT", style: TextStyle(color: Colors.orange, fontSize: 12)),
                                ),
                                TextButton(
                                  onPressed: () => _deleteAddress(addr['id']),
                                  child: const Text("DELETE", style: TextStyle(color: Colors.red, fontSize: 12)),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
