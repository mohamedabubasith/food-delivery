import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../data/dashboard_repository.dart';
import '../../../common_widgets/base_header.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<dynamic> _favorites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFavorites();
  }

  Future<void> _fetchFavorites() async {
    try {
      final favs = await context.read<DashboardRepository>().getFavorites();
      if(mounted) setState(() { _favorites = favs; _isLoading = false; });
    } catch(e) {
      print("Error fetching favorites: $e");
      if(mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _removeFavorite(int id) async {
      setState(() {
          _favorites.removeWhere((item) => item['food_id'] == id);
      });
      await context.read<DashboardRepository>().toggleFavorite(id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BaseHeader(title: "My Favorites"),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : _favorites.isEmpty 
           ? const Center(child: Text("No favorites yet")) 
           : ListView.builder(
               itemCount: _favorites.length,
               padding: const EdgeInsets.all(16),
               itemBuilder: (context, index) {
                 final item = _favorites[index];
                 return GestureDetector(
                   onTap: () {
                      final safeItem = Map<String, dynamic>.from(item);
                      if (safeItem['variants'] == null) safeItem['variants'] = [];
                      safeItem['isFavorite'] = true;
                      
                      context.push('/product-details', extra: safeItem).then((_) {
                           _fetchFavorites();
                      });
                   },
                   child: Container(
                     margin: const EdgeInsets.only(bottom: 16),
                     decoration: BoxDecoration(
                       color: Colors.white,
                       borderRadius: BorderRadius.circular(16),
                       boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
                     ),
                     child: Row(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         // Image
                         ClipRRect(
                           borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                           child: Image.network(
                             item['image_url'] ?? '',
                             width: 100, height: 100, fit: BoxFit.cover,
                             errorBuilder: (_,__,___) => Container(width: 100, color: Colors.grey[200], child: const Icon(Icons.fastfood, color: Colors.grey)),
                           ),
                         ),
                         
                         // Content
                         Expanded(
                           child: Padding(
                             padding: const EdgeInsets.all(12),
                             child: Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                 Text(item['food_name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                                 const SizedBox(height: 4),
                                 Text(item['food_category'] ?? 'General', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                                 const SizedBox(height: 12),
                                 Row(
                                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                   children: [
                                     Text("₹${item['food_price']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                     // Heart
                                     GestureDetector(
                                       onTap: () => _removeFavorite(item['food_id']),
                                       behavior: HitTestBehavior.opaque,
                                       child: Container(
                                         padding: const EdgeInsets.all(8),
                                         child: const Icon(Icons.favorite, color: Colors.red),
                                       ),
                                     )
                                   ],
                                 )
                               ],
                             ),
                           ),
                         )
                       ],
                     ),
                   ),
                 );
               },
             ),
    );
  }
}
