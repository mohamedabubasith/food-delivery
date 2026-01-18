
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cart/application/cart_bloc.dart';
import '../../cart/application/cart_event.dart';
import '../data/dashboard_repository.dart';

class ProductDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> food;

  const ProductDetailsScreen({super.key, required this.food});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  int quantity = 1;
  int? selectedVariantId;
  Map<String, dynamic>? selectedVariant;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.food['isFavorite'] ?? false;
    // Pre-select first variant if available
    final variants = widget.food['variants'] as List?;
    if (variants != null && variants.isNotEmpty) {
      selectedVariant = variants[0];
      selectedVariantId = selectedVariant!['id']; // Assuming ID exists or we use index? 
      // Backend returns 'id' for FoodVariant.
    }
  }

  Future<void> _toggleFavorite() async {
    final oldStatus = _isFavorite;
    setState(() => _isFavorite = !_isFavorite);
    try {
       await context.read<DashboardRepository>().toggleFavorite(widget.food['food_id']);
    } catch (e) {
       setState(() => _isFavorite = oldStatus);
    }
  }

  double get currentPrice {
    if (selectedVariant != null) {
      return (selectedVariant!['variant_price'] as num).toDouble();
    }
    return (widget.food['food_price'] as num).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final variants = widget.food['variants'] as List?;
    final hasVariants = variants != null && variants.isNotEmpty;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: CircleAvatar(
          backgroundColor: Colors.white,
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        actions: [
           CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                onPressed: _toggleFavorite,
                icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border, color: Colors.red)
              )
           ),
           const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Header
            Stack(
              children: [
                Hero(
                  tag: 'food_${widget.food['food_id']}',
                  child: Image.network(
                    widget.food['image_url'] ?? '',
                    height: 300,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(height: 300, color: Colors.grey[200]),
                  ),
                ),
                if (widget.food['discount_percentage'] != null && (widget.food['discount_percentage'] as num) > 0)
                  Positioned(
                    bottom: 20,
                    left: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "${widget.food['discount_percentage']}% OFF",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
            
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   // Header
                   Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                       Expanded(
                         child: Text(
                           widget.food['food_name'],
                           style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                         ),
                       ),
                       Container(
                         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                         decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(20)),
                         child: Row(
                           children: [
                             const Icon(Icons.star, size: 16, color: Colors.orange),
                             const SizedBox(width: 4),
                             Text("${widget.food['rating'] ?? 4.5}", style: const TextStyle(fontWeight: FontWeight.bold)),
                           ],
                         ),
                       )
                     ],
                   ),
                   const SizedBox(height: 8),
                   Text(
                     widget.food['food_category'] ?? '',
                     style: TextStyle(color: Colors.grey[600], fontSize: 16),
                   ),
                   const SizedBox(height: 16),
                   Text(
                     widget.food['description'] ?? "No description available.",
                     style: TextStyle(color: Colors.grey[700], height: 1.5),
                   ),
                   
                   const SizedBox(height: 24),
                   
                   // Variants
                   if (hasVariants) ...[
                     const Text("Choose Size", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                     const SizedBox(height: 12),
                     Wrap(
                       spacing: 12,
                       children: variants.map<Widget>((v) {
                          final isSelected = selectedVariantId == v['id'];
                          return ChoiceChip(
                            label: Text("${v['variant_name']} - ₹${v['variant_price']}"),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  selectedVariantId = v['id'];
                                  selectedVariant = v;
                                });
                              }
                            },
                            selectedColor: Colors.black,
                            labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
                            backgroundColor: Colors.grey[100],
                          );
                       }).toList(),
                     ),
                     const SizedBox(height: 24),
                   ],
                   
                   // Quantity
                   Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                       const Text("Quantity", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                       Container(
                         decoration: BoxDecoration(
                           border: Border.all(color: Colors.grey.shade300),
                           borderRadius: BorderRadius.circular(30),
                         ),
                         child: Row(
                           children: [
                             IconButton(onPressed: () {
                               if (quantity > 1) setState(() => quantity--);
                             }, icon: const Icon(Icons.remove, size: 20)),
                             Text("$quantity", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                             IconButton(onPressed: () {
                               setState(() => quantity++);
                             }, icon: const Icon(Icons.add, size: 20)),
                           ],
                         ),
                       )
                     ],
                   )
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                // Add to Cart
                final itemToAdd = Map<String, dynamic>.from(widget.food);
                itemToAdd['quantity'] = quantity; // Although backend manages cart logic, bloc expects item
                // Override price and add variant info
                itemToAdd['food_price'] = currentPrice;
                if (selectedVariant != null) {
                  itemToAdd['variant_id'] = selectedVariant!['id'];
                  itemToAdd['variant_name'] = selectedVariant!['variant_name'];
                  // Ensure name reflects variant
                   itemToAdd['food_name'] = "${widget.food['food_name']} (${selectedVariant!['variant_name']})";
                }
                
                // Add multiple qty? Bloc usually adds 1 by default or we loop?
                // CartBloc current implementation adds item to list.
                // If we want quantity > 1, we might need to add multiple times or update Bloc to handle qty.
                // Current CartBloc simply adds the item to the list.
                // So if qty is 2, we add 2 times.
                for(int i=0; i<quantity; i++) {
                   context.read<CartBloc>().add(CartItemAdded(itemToAdd));
                }
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Added to Cart"), backgroundColor: Colors.green));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Add $quantity to Cart"),
                  Text("₹${(currentPrice * quantity).toStringAsFixed(1)}", style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
