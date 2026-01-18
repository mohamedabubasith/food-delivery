import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../cart/application/cart_bloc.dart';
import '../../cart/application/cart_event.dart';
import '../../cart/application/cart_state.dart';
import '../data/dashboard_repository.dart';

class OfferScreen extends StatefulWidget {
  final Map<String, dynamic> banner;

  const OfferScreen({super.key, required this.banner});

  @override
  State<OfferScreen> createState() => _OfferScreenState();
}

class _OfferScreenState extends State<OfferScreen> {
  List<dynamic> _promoItems = [];
  bool _isLoading = false;
  String? _mode; // 'coupon' or 'collection'

  @override
  void initState() {
    super.initState();
    _initMode();
  }

  void _initMode() {
    final link = widget.banner['deep_link'] as String? ?? "";
    if (link.contains("offer")) {
      setState(() => _mode = 'coupon');
    } else {
      setState(() {
        _mode = 'collection';
        _isLoading = true;
      });
      _fetchPromoItems(link);
    }
  }

  Future<void> _fetchPromoItems(String link) async {
    // Extract category from link (app://menu/mandi -> mandi)
    String? category;
    if (link.contains("mandi")) category = "Mandi";
    if (link.contains("grills")) category = "Grills";

    if (category != null) {
      try {
        final repo = context.read<DashboardRepository>();
        final items = await repo.getMenu(category: category);
        if (mounted) {
          setState(() {
            _promoItems = items;
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
       if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Extract color from title maybe?
    final Color primaryColor = const Color(0xFFD4AF37); // Gold

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        children: [
          // Background Image (Fixed/Parallax feel)
          Positioned.fill(
            child: Image.network(
              widget.banner['image_url'] ?? "",
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: Colors.grey[900]),
            ),
          ),
          // Gradient Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.9),
                  ],
                ),
              ),
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(flex: 2), // Push text down initially
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _mode == 'coupon' ? "LIMITED TIME OFFER" : "FEATURED COLLECTION",
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.banner['title'] ?? "Special Offer",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Description / Subtext
                if (_mode == 'coupon')
                  const Text(
                    "Get 50% flat discount on all Arabian dishes! Use code OFFER50 at checkout.",
                    style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
                  ),
                
                const SizedBox(height: 24),

                // MODE: COUPON -> SHOW BUTTON
                if (_mode == 'coupon') ...[
                  const Spacer(),
                  BlocConsumer<CartBloc, CartState>(
                    listener: (context, state) {
                       if (state.couponCode == "OFFER50") {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Coupon Applied Successfully! 🎉"), backgroundColor: Colors.green),
                          );
                          context.pop(); // Go back
                       }
                    },
                    builder: (context, state) {
                      final isApplied = state.couponCode == "OFFER50";
                      return SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: isApplied 
                              ? null 
                              : () => context.read<CartBloc>().add(const CartCouponApplied("OFFER50")),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          child: Text(
                            isApplied ? "COUPON APPLIED" : "CLAIM OFFER",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 40),
                ]
                
                // MODE: COLLECTION -> SHOW HORIZONTAL LIST
                else ...[
                   Expanded(
                     flex: 3,
                     child: _isLoading 
                        ? const Center(child: CircularProgressIndicator(color: Colors.white))
                        : ListView.builder(
                           scrollDirection: Axis.horizontal,
                           itemCount: _promoItems.length,
                           itemBuilder: (context, index) {
                             final item = _promoItems[index];
                             return Container(
                               width: 200,
                               margin: const EdgeInsets.only(right: 16, bottom: 20),
                               decoration: BoxDecoration(
                                 color: Colors.white.withOpacity(0.1),
                                 borderRadius: BorderRadius.circular(16),
                                 border: Border.all(color: Colors.white24),
                               ),
                               padding: const EdgeInsets.all(12),
                               child: Column(
                                 crossAxisAlignment: CrossAxisAlignment.start,
                                 children: [
                                   Expanded(
                                     child: ClipRRect(
                                       borderRadius: BorderRadius.circular(12),
                                       child: Image.network(
                                         item['image_url'] ?? "",
                                         width: double.infinity,
                                         fit: BoxFit.cover,
                                         errorBuilder: (_,__,___) => const Icon(Icons.fastfood, color: Colors.white54),
                                       ),
                                     ),
                                   ),
                                   const SizedBox(height: 12),
                                   Text(item['food_name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                                   
                                   // Price Row with Discount
                                   Builder(
                                     builder: (context) {
                                       final price = (item['food_price'] as num?)?.toDouble() ?? 0.0;
                                       final discountPercent = (item['discount_percentage'] as num?)?.toDouble() ?? 0.0;
                                       
                                       if (discountPercent > 0) {
                                         final discountedPrice = price * (1 - (discountPercent / 100));
                                         
                                         return Row(
                                           children: [
                                             Text(
                                               "₹${discountedPrice.toStringAsFixed(1)}", 
                                               style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 16)
                                             ),
                                             const SizedBox(width: 8),
                                             Text(
                                               "₹${price.toStringAsFixed(0)}", 
                                               style: const TextStyle(
                                                 color: Colors.white54, 
                                                 decoration: TextDecoration.lineThrough,
                                                 fontSize: 12
                                               )
                                             ),
                                             const SizedBox(width: 4),
                                             Container(
                                               padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                               decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(4)),
                                               child: Text("${discountPercent.toInt()}% OFF", style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                                             )
                                           ],
                                         );
                                       }
                                       
                                       return Text("₹${price.toStringAsFixed(1)}", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold));
                                     }
                                   ),
                                   
                                   const SizedBox(height: 8),
                                   // Add Button
                                   SizedBox(
                                     width: double.infinity,
                                     child: ElevatedButton(
                                       onPressed: () {
                                          context.read<CartBloc>().add(CartItemAdded(item));
                                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Added to cart!"), duration: Duration(milliseconds: 500)));
                                       },
                                       style: ElevatedButton.styleFrom(
                                         backgroundColor: Colors.white,
                                         foregroundColor: Colors.black,
                                         visualDensity: VisualDensity.compact,
                                       ),
                                       child: const Text("ADD"),
                                     ),
                                   )
                                 ],
                               ),
                             );
                           },
                        ),
                   ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
