import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../application/cart_bloc.dart';
import '../application/cart_event.dart';
import '../application/cart_state.dart';
import '../../dashboard/data/dashboard_repository.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  int? _selectedAddressId;
  List<dynamic> _addresses = [];
  bool _isLoadingAddresses = true;
  bool _isPlacingOrder = false;

  @override
  void initState() {
    super.initState();
    _fetchAddresses();
  }

  Future<void> _fetchAddresses() async {
    final repo = context.read<DashboardRepository>();
    final addresses = await repo.getAddresses();
    if (mounted) {
      setState(() {
        _addresses = addresses;
        _isLoadingAddresses = false;
        if (addresses.isNotEmpty) {
          _selectedAddressId = addresses.first['id'];
        }
      });
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
            TextField(controller: zipController, decoration: const InputDecoration(labelText: "Zip Code (6 digits Indian Pincode)"), keyboardType: TextInputType.number),
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

  Future<void> _placeOrder(CartState state) async {
    if (_selectedAddressId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a delivery address")));
      return;
    }

    setState(() => _isPlacingOrder = true);
    try {
      final repo = context.read<DashboardRepository>();
      
      // Group items for backend
      final groupedItems = <String, Map<String, dynamic>>{};
      for (var item in state.items) {
        final key = "${item['food_id']}_${item['variant_id']}";
        if (groupedItems.containsKey(key)) {
          groupedItems[key]!['quantity'] += 1;
        } else {
          groupedItems[key] = {
            "food_id": item['food_id'],
            "variant_id": item['variant_id'],
            "quantity": 1,
          };
        }
      }
      final itemsForBackend = groupedItems.values.toList();

      await repo.checkout(
        items: itemsForBackend,
        addressId: _selectedAddressId,
        couponCode: state.couponCode,
      );

      if (!mounted) return;
      
      // Clear cart
      context.read<CartBloc>().add(CartCleared());
      
      // Success Dialog/Screen
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.check_circle, color: Colors.green, size: 60),
          title: const Text("Order Placed Successfully!"),
          content: const Text("Your delicious food is being prepared."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop(); // Dialog
                context.go('/'); // Home
              },
              child: const Text("GO TO HOME"),
            )
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isPlacingOrder = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFFD4AF37); // Gold

    return BlocBuilder<CartBloc, CartState>(
      builder: (context, state) {
        if (state.items.isEmpty && !_isPlacingOrder) {
          // If cart becomes empty (e.g. after success), don't show the summary
          return Container();
        }

        return Scaffold(
          backgroundColor: const Color(0xFFFAFAFA),
          appBar: AppBar(
            title: const Text("Confirm Order", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            backgroundColor: Colors.white,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.black),
          ),
          body: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Order Summary
                    const Text("Review Items", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    ...(() {
                      final grouped = <String, Map<String, dynamic>>{};
                      for (var item in state.items) {
                        final key = "${item['food_id']}_${item['variant_id']}";
                        if (grouped.containsKey(key)) {
                          grouped[key]!['qty'] += 1;
                        } else {
                          grouped[key] = {
                            'name': item['food_name'],
                            'price': item['food_price'],
                            'qty': 1,
                          };
                        }
                      }
                      return grouped.values.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("${item['qty']}x ${item['name']}", style: const TextStyle(fontSize: 15)),
                            Text("₹${((item['price'] ?? 0) * (item['qty'] ?? 1)).toStringAsFixed(1)}"),
                          ],
                        ),
                      ));
                    })(),
                    const Divider(height: 32),

                    // Delivery Address
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Delivery Address", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        TextButton(
                          onPressed: _addNewAddress,
                          child: const Text("+ Add New", style: TextStyle(color: Colors.orange)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_isLoadingAddresses)
                      const Center(child: CircularProgressIndicator())
                    else if (_addresses.isEmpty)
                       Container(
                         padding: const EdgeInsets.all(20),
                         decoration: BoxDecoration(color: Colors.orange.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.orange.withOpacity(0.2))),
                         child: const Text("No addresses found. Please add one to continue.", textAlign: TextAlign.center),
                       )
                    else
                      SizedBox(
                        height: 120,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _addresses.length,
                          itemBuilder: (ctx, index) {
                            final addr = _addresses[index];
                            final isSelected = _selectedAddressId == addr['id'];
                            return GestureDetector(
                              onTap: () => setState(() => _selectedAddressId = addr['id']),
                              child: Container(
                                width: 220,
                                margin: const EdgeInsets.only(right: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.orange.withOpacity(0.1) : Colors.white,
                                  border: Border.all(color: isSelected ? Colors.orange : Colors.grey.shade200),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(addr['label'].toString().toLowerCase() == 'home' ? Icons.home : Icons.work, size: 16, color: isSelected ? Colors.orange : Colors.grey),
                                        const SizedBox(width: 4),
                                        Text(addr['label'] ?? "Address", style: const TextStyle(fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(addr['address_line'] ?? "", maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                    Text("${addr['city']}, ${addr['zip_code']}", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    
                    const SizedBox(height: 32),

                    // Bill Summary
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        children: [
                          _buildSummaryRow("Item Total", state.subtotal),
                          if (state.couponCode != null) 
                            _buildSummaryRow("Coupon Discount", -state.discountAmount, isDiscount: true),
                          const Divider(height: 24),
                          _buildSummaryRow("Total Amount", state.total, isBold: true),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom Bar
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
                ),
                child: SafeArea(
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isPlacingOrder ? null : () => _placeOrder(state),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _isPlacingOrder 
                        ? const CircularProgressIndicator(color: Colors.black)
                        : const Text("PLACE ORDER", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    ),
                  ),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryRow(String label, double amount, {bool isBold = false, bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 16, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: isDiscount ? Colors.green : Colors.black)),
          Text("₹${amount.abs().toStringAsFixed(1)}", style: TextStyle(fontSize: 16, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: isDiscount ? Colors.green : Colors.black)),
        ],
      ),
    );
  }
}
