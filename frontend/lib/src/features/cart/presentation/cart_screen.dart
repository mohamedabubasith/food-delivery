import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../cart/application/cart_bloc.dart';
import '../../cart/application/cart_event.dart';
import '../../cart/application/cart_state.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final TextEditingController _couponController = TextEditingController();

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFFD4AF37); // Gold

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text("My Cart", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () {
               context.read<CartBloc>().add(CartCleared());
            },
          )
        ],
      ),
      body: BlocConsumer<CartBloc, CartState>(
        listener: (context, state) {
           if (state.status == CartStatus.success && state.validationError != null) {
             ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.validationError!),
                backgroundColor: Colors.redAccent,
                duration: const Duration(seconds: 3),
              ),
            );
        }
        if (state.status == CartStatus.failure && state.error != null) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${state.error}"), backgroundColor: Colors.red));
           }
        },
        builder: (context, state) {
          if (state.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text("Your cart is empty", style: TextStyle(fontSize: 18, color: Colors.grey)),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.pop(),
                    style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.black),
                    child: const Text("Browse Menu"),
                  )
                ],
              ),
            );
          }

          final subtotal = state.subtotal;
          final discount = state.discountAmount;
          final total = subtotal - discount;

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Items List
                    ...state.items.map((item) {
                       final price = (item['food_price'] as num?)?.toDouble() ?? 0.0;
                       final discountItem = (item['discount_percentage'] as num?)?.toDouble() ?? 0.0;
                       final finalPrice = price * (1 - (discountItem / 100));
                       
                       return Container(
                         margin: const EdgeInsets.only(bottom: 12),
                         padding: const EdgeInsets.all(12),
                         decoration: BoxDecoration(
                           color: Colors.white,
                           borderRadius: BorderRadius.circular(12),
                           boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                         ),
                         child: Row(
                           children: [
                             ClipRRect(
                               borderRadius: BorderRadius.circular(8),
                               child: Image.network(
                                 item['image_url'] ?? "",
                                 width: 60, height: 60, fit: BoxFit.cover,
                                 errorBuilder: (_,__,___) => Container(width: 60, height: 60, color: Colors.grey[200], child: const Icon(Icons.fastfood, size: 20)),
                               ),
                             ),
                             const SizedBox(width: 12),
                             Expanded(
                               child: Column(
                                 crossAxisAlignment: CrossAxisAlignment.start,
                                 children: [
                                   Text(item['food_name'] ?? "Unknown", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                   const SizedBox(height: 4),
                                   if (discountItem > 0)
                                     Row(
                                       children: [
                                         Text("₹${finalPrice.toStringAsFixed(1)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                         const SizedBox(width: 6),
                                         Text("₹${price.toStringAsFixed(0)}", style: const TextStyle(color: Colors.grey, decoration: TextDecoration.lineThrough, fontSize: 12)),
                                         const SizedBox(width: 4),
                                         Text("${discountItem.toInt()}% OFF", style: const TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                                       ],
                                     )
                                   else
                                     Text("₹${finalPrice.toStringAsFixed(1)}", style: TextStyle(color: Colors.grey[600])),
                                 ],
                               ),
                             ),
                             IconButton(
                               icon: const Icon(Icons.close, size: 20, color: Colors.grey),
                               onPressed: () {
                                 context.read<CartBloc>().add(CartItemRemoved(item));
                               },
                             )
                           ],
                         ),
                       );
                    }),

                    const SizedBox(height: 24),
                    
                    // Coupon Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Have a coupon?", style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: state.couponCode != null 
                                  ? Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.check_circle, color: Colors.green, size: 20),
                                          const SizedBox(width: 8),
                                          Text("Code ${state.couponCode} applied", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    )
                                  : TextField(
                                      controller: _couponController,
                                      decoration: InputDecoration(
                                        hintText: "Enter Code",
                                        hintStyle: TextStyle(color: Colors.grey[400]),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                                      ),
                                    ),
                              ),
                              if (state.couponCode == null) ...[
                                const SizedBox(width: 12),
                                ElevatedButton(
                                  onPressed: () {
                                    if (_couponController.text.isNotEmpty) {
                                      context.read<CartBloc>().add(CartCouponApplied(_couponController.text.toUpperCase()));
                                      _couponController.clear();
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                                  child: const Text("APPLY"),
                                ),
                              ]
                            ],
                          ),
                          if (state.couponCode == null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: InkWell(
                                onTap: () => _showCouponWallet(context),
                                child: const Text("View My Coupons", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
                              ),
                            ),
                        ],
                      ),
                    ),
                    
                    if (state.validationError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8, left: 16, right: 16),
                        child: Text(
                          state.validationError!,
                          style: const TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),

                    const SizedBox(height: 24),

                    // Bill Summary
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          _buildSummaryRow("Subtotal", subtotal),
                          if (state.couponCode != null) 
                            _buildSummaryRow("Coupon Discount", -discount, isDiscount: true),
                          const Divider(height: 24),
                          _buildSummaryRow("Total", total, isBold: true),
                        ],
                      ),
                    ),
                    const SizedBox(height: 100), // Space for FAB
                  ],
                ),
              ),
              
              // Bottom Checkout Bar
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
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Proceeding to Payment...")));
                        // Implement Checkout Flow
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: const Text("CHECKOUT", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    ),
                  ),
                ),
              )
            ],
          );
        },
      ),
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

  void _showCouponWallet(BuildContext context) {
    context.read<CartBloc>().add(CartUserCouponsRequested());
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => BlocConsumer<CartBloc, CartState>(
        bloc: context.read<CartBloc>(), // Use parent bloc
        listener: (ctx, state) {
           if (state.claimError != null) {
              ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text("Error: ${state.claimError}"), backgroundColor: Colors.red));
           }
        },
        builder: (ctx, state) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, top: 20, left: 20, right: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("My Coupons", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                
                // Claim Section
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _couponController, // Reuse controller
                        decoration: const InputDecoration(
                          hintText: "Enter Code to Claim",
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: state.isClaiming ? null : () {
                         if (_couponController.text.isNotEmpty) {
                            context.read<CartBloc>().add(CartCouponClaimed(_couponController.text.toUpperCase()));
                            _couponController.clear();
                         }
                      },
                      child: state.isClaiming ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text("Claim"),
                    )
                  ],
                ),
                const SizedBox(height: 20),
                
                // List
                if (state.userCoupons.isEmpty)
                   const Padding(padding: EdgeInsets.all(20), child: Center(child: Text("No coupons found"))),
                   
                ...state.userCoupons.map((uc) {
                   final coupon = uc['coupon'];
                   final code = coupon['code'];
                   final desc = coupon['description'] ?? "${coupon['discount_value']} Off"; // Fallback description
                   return ListTile(
                     title: Text(code, style: const TextStyle(fontWeight: FontWeight.bold)),
                     subtitle: Text("Expires: ${coupon['valid_until']?.substring(0,10)}"),
                     trailing: ElevatedButton(
                       onPressed: () {
                         context.read<CartBloc>().add(CartCouponApplied(code));
                         Navigator.pop(ctx);
                       },
                       style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                       child: const Text("APPLY"),
                     ),
                   );
                }).toList(),
                
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }
}
