import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/dashboard_repository.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<dynamic> _orders = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    try {
      final repo = context.read<DashboardRepository>();
      final orders = await repo.getOrders();
      print('🛒 Orders fetched: ${orders.length} orders');
      if (orders.isNotEmpty) {
        print('🛒 First order data: ${orders[0]}');
      }
      if (mounted) {
        setState(() {
          _orders = orders;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error fetching orders: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text("My Orders", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text("Error: $_error"))
              : _orders.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          const Text("No orders found", style: TextStyle(fontSize: 18, color: Colors.grey)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _orders.length,
                      itemBuilder: (context, index) {
                        final order = _orders[index];
                        final date = DateTime.tryParse(order['created_at'] ?? '') ?? DateTime.now();
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("Order #${order['id']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text(
                                    order['status']?.toString().toUpperCase() ?? "PENDING",
                                    style: TextStyle(
                                      color: order['status'] == 'delivered' ? Colors.green : Colors.orange,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 24),
                              Row(
                                children: [
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                                    child: const Icon(Icons.fastfood, color: Colors.grey),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(order['food']?['food_name'] ?? "Meal", style: const TextStyle(fontWeight: FontWeight.bold)),
                                        Text("Quantity: ${order['quantity']}", style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                                      ],
                                    ),
                                  ),
                                  Builder(
                                    builder: (context) {
                                      // Calculate price with fallback logic
                                      double? price;
                                      
                                      if (order['price_at_order'] != null) {
                                        // Use snapshot price if available
                                        price = (order['price_at_order'] as num).toDouble();
                                      } else if (order['variant'] != null && order['variant']['variant_price'] != null) {
                                        // Use variant price if order has a variant
                                        price = (order['variant']['variant_price'] as num).toDouble();
                                      } else if (order['food']?['food_price'] != null) {
                                        // Fallback to base food price
                                        price = (order['food']['food_price'] as num).toDouble();
                                      }
                                      
                                      // Calculate total with quantity
                                      final quantity = order['quantity'] ?? 1;
                                      final total = price != null ? (price * quantity) : null;
                                      
                                      return Text(
                                        total != null ? "₹${total.toStringAsFixed(0)}" : "N/A",
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      );
                                    },
                                  ),
                                ],
                              ),
                              const Divider(height: 24),
                              Text(
                                "${date.day}/${date.month}/${date.year} • ${date.hour}:${date.minute}",
                                style: TextStyle(color: Colors.grey[500], fontSize: 12),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
    );
  }
}
