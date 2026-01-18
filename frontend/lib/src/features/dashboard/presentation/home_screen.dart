import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:frontend/src/l10n/app_localizations.dart';
import '../../auth/application/auth_bloc.dart';
import '../../cart/application/cart_bloc.dart';
import '../../cart/application/cart_event.dart';
import '../../cart/application/cart_state.dart';
import '../data/dashboard_repository.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Data
  Map<String, dynamic>? _restaurant;
  List<dynamic> _menuItems = [];
  List<dynamic> _banners = [];
  List<dynamic> _filteredItems = [];
  Set<int> _favoriteIds = {};
  
  // UI State
  bool _isLoading = true;
  String? _error;
  String _selectedCategory = "All";
  final TextEditingController _searchController = TextEditingController();

  // Auto-Scroll State
  late PageController _pageController;
  int _currentBannerIndex = 0;
  Timer? _bannerTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.92);
    _fetchDashboardData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pageController.dispose();
    _bannerTimer?.cancel();
    super.dispose();
  }

  void _startAutoScroll() {
    _bannerTimer?.cancel();
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_banners.isEmpty || !mounted) return;
      if (_pageController.hasClients) {
        int nextPage = _currentBannerIndex + 1;
        if (nextPage >= _banners.length) {
          nextPage = 0;
        }
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
         // Note: onPageChanged updates _currentBannerIndex
      }
    });
  }

  void _onSearchChanged() {
    _filterMenu();
  }

  void _filterMenu() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredItems = _menuItems.where((item) {
        final matchesCategory = _selectedCategory == "All" || item['food_category'] == _selectedCategory;
        final matchesQuery = (item['food_name'] as String).toLowerCase().contains(query);
        return matchesCategory && matchesQuery;
      }).toList();
    });
  }

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
      _filterMenu();
    });
  }

  Future<void> _toggleFavorite(int foodId) async {
    final isFav = _favoriteIds.contains(foodId);
    setState(() {
      if (isFav) {
        _favoriteIds.remove(foodId);
      } else {
        _favoriteIds.add(foodId);
      }
    });
    
    try {
      await context.read<DashboardRepository>().toggleFavorite(foodId);
    } catch (e) {
      setState(() {
        if (isFav) _favoriteIds.add(foodId); else _favoriteIds.remove(foodId);
      });
    }
  }

  Future<void> _fetchDashboardData() async {
    try {
      final repo = context.read<DashboardRepository>();
      
      // 1. Fetch Restaurant Info first
      final restaurants = await repo.getRestaurants();
      
      if (mounted) {
        setState(() {
           if (restaurants.isNotEmpty) {
            _restaurant = restaurants.first;
            // Use the "Al-Brisk" one if available, searching by name if needed
            final alBrisk = restaurants.firstWhere(
              (r) => r['name'].toString().contains("Al-Brisk"), 
              orElse: () => restaurants.first
            );
            _restaurant = alBrisk;
          } else {
             _restaurant = {
               "id": 1,
               "name": "Al-Brisk Arabian Mandi",
               "image_url": "https://images.unsplash.com/photo-1549488344-1f9b8d2bd1f3",
               "address": "Downtown",
             };
          }
        });
      }

      // 2. Fetch Menu and Banners
      final restaurantId = _restaurant?['id'] as int?;
      final results = await Future.wait([
        repo.getMenu(restaurantId: restaurantId),
        repo.getBanners(),
        repo.getFavorites(),
      ]);

      if (mounted) {
        setState(() {
          _menuItems = results[0] as List<dynamic>;
          _banners = results[1] as List<dynamic>;
          final favs = results[2] as List<dynamic>;
          _favoriteIds = favs.map<int>((e) => e['food_id'] as int).toSet();

          if (_banners.isNotEmpty) {
             _startAutoScroll();
          }
          
          // Initial filter
          _filterMenu();
          _isLoading = false;
        });
      }
    } catch (e) {
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
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.amber))); // Use theme color
    }
    
    if (_error != null) {
      return Scaffold(body: Center(child: Text('Error: $_error')));
    }

    final theme = Theme.of(context);
    // Modern "Arabian Gold" theme colors
    const Color primaryColor = Color(0xFFD4AF37); // Gold
    const Color darkColor = Color(0xFF1A1A1A);
    const Color surfaceColor = Colors.white;

    return BlocListener<CartBloc, CartState>(
      listenWhen: (previous, current) => previous.status != current.status || previous.couponCode != current.couponCode,
      listener: (context, state) {
        if (state.status == CartStatus.success && state.couponCode != null && state.discountAmount > 0) {
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
               content: Text("Success! Coupon '${state.couponCode}' applied. You saved ₹${state.discountAmount}!"),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state.status == CartStatus.failure) {
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Coupon Failed: ${state.error ?? 'Unknown error'}"),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: CustomScrollView(
        slivers: [
          // 1. Standard Modern AppBar (Pinned)
          SliverAppBar(
            expandedHeight: 0, // No expansion
            toolbarHeight: 60,
            floating: true,
            pinned: true,
            centerTitle: false, // Ensure title is left aligned
            backgroundColor: surfaceColor,
            elevation: 0,
            leading: const Icon(Icons.location_on, color: Colors.deepOrange), // Location icon instead of back
            titleSpacing: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Delivering to", 
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                Text(
                  _restaurant?['address'] ?? "Select Location",
                  style: const TextStyle(color: darkColor, fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            actions: [
               Padding(
                 padding: const EdgeInsets.only(right: 16),
                 child: Row(
                   children: [
                      Container(
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.grey[100]),
                        child: IconButton(
                          icon: const Icon(Icons.favorite, color: Colors.red),
                          onPressed: () => context.push('/favorites'),
                        ),
                      ),
                     // Cart Icon with Badge
                     Stack(
                       clipBehavior: Clip.none,
                       children: [
                         Container(
                           decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.grey[100]),
                           child: IconButton(
                             icon: const Icon(Icons.shopping_cart_outlined, color: darkColor),
                             onPressed: () => context.push('/cart'),
                           ),
                         ),
                         BlocBuilder<CartBloc, CartState>(
                           builder: (context, state) {
                             if (state.items.isEmpty) return const SizedBox.shrink();
                             return Positioned(
                               right: 0,
                               top: 0,
                               child: Container(
                                 padding: const EdgeInsets.all(4),
                                 decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                 constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                 child: Text(
                                   "${state.items.length}",
                                   style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                   textAlign: TextAlign.center,
                                 ),
                               ),
                             );
                           },
                         ),
                       ],
                     ),
                     const SizedBox(width: 12),
                     // Profile Menu
                     PopupMenuButton<String>(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.grey[100]),
                        child: const Icon(Icons.person, color: darkColor),
                      ),
                      onSelected: (value) {
                        if (value == 'logout') {
                          context.read<AuthBloc>().add(AuthLogoutRequested());
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'profile', child: Text("Profile")),
                        const PopupMenuItem(value: 'orders', child: Text("Orders")),
                        const PopupMenuItem(value: 'logout', child: Text("Logout", style: TextStyle(color: Colors.red))),
                      ],
                    ),
                   ],
                 ),
               )
            ],
          ),

          // 2. Banners Carousel & Search (The new Hero)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   // Search Bar First? Or Banners? User said "Offer banner below header".
                   // Let's put Banners then Search or Search then Banners.
                   // Common UX: Search -> Banners. But user said "Offer banner... then categories".
                   // Let's do Banners first as requested "below header".
                  
                  if (_banners.isNotEmpty) ...[
                    SizedBox(
                      height: 180, // Taller for "Hero" feel
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: _banners.length,
                        onPageChanged: (index) {
                          setState(() {
                            _currentBannerIndex = index;
                          });
                        },
                        itemBuilder: (context, index) {
                          final banner = _banners[index]; // Access safely
                          return GestureDetector(
                            onTap: () {
                              final link = banner['deep_link'] as String?;
                              print("🔴 Tapped banner: ${banner['title']} - Link: $link");
                              
                              if (link == null) {
                                print("Link is null");
                                return;
                              }
                              
                              // For now, open Offer Screen for ALL banners to show detail
                              context.push('/offer', extra: banner);
                              
                              /*
                              // Handle Deep Links
                              if (link.contains("offer")) {
                                context.push('/offer', extra: banner);
                              } else if (link.contains("mandi")) {
                                _onCategorySelected("Mandi");
                                // Scroll to menu?
                              } else if (link.contains("grills")) {
                                _onCategorySelected("Grills");
                              }
                              */
                            },
                            behavior: HitTestBehavior.opaque,
                            child: Container(
                              margin: const EdgeInsets.only(right: 16),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                  Image.network(
                                    banner['image_url'] ?? "",
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      // Error Fallback
                                      return Container(
                                        color: Colors.grey[300],
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Icon(Icons.broken_image, color: Colors.grey),
                                            Text("Error loading image", style: TextStyle(color: Colors.grey[600], fontSize: 10)),
                                          ],
                                        ),
                                      );
                                    },
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Center(
                                        child: CircularProgressIndicator(
                                          value: loadingProgress.expectedTotalBytes != null
                                              ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                              : null,
                                        ),
                                      );
                                    },
                                  ),
                                  // Overlay Text if any
                                  if (banner['title'] != null)
                                    Positioned(
                                      bottom: 10, left: 10,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                                        child: Text(banner['title'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                      ),
                                    )
                                ],
                              ),
                            ),
                          ));
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_banners.length, (index) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          height: 8,
                          width: _currentBannerIndex == index ? 24 : 8,
                          decoration: BoxDecoration(
                            color: _currentBannerIndex == index ? primaryColor : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Search Bar (Floating feel)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: "Search for 'Mandi'...",
                        hintStyle: TextStyle(color: Colors.grey),
                        prefixIcon: Icon(Icons.search, color: primaryColor),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Sticky Categories Header
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverCategoryDelegate(
              categories: ["All", "Mandi", "Shawarma", "Grills", "Starters", "Desserts"],
              selectedCategory: _selectedCategory,
              onCategorySelected: _onCategorySelected,
            ),
          ),
          
          const SliverPadding(padding: EdgeInsets.only(top: 16)),

          // 4. Menu List (Modern Cards)
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = _filteredItems[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: GestureDetector(
                    onTap: () async {
                       final itemWithFav = Map<String, dynamic>.from(item);
                       itemWithFav['isFavorite'] = _favoriteIds.contains(item['food_id']);
                       await context.push('/product-details', extra: itemWithFav);
                       final repo = context.read<DashboardRepository>();
                       final favs = await repo.getFavorites();
                       if (mounted) {
                         setState(() {
                           _favoriteIds = favs.map<int>((e) => e['food_id'] as int).toSet();
                         });
                       }
                    },
                    child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.08),
                          spreadRadius: 2,
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                         // Image on Left
                        Stack(
                          children: [
                            Hero(
                              tag: item['food_name'] ?? 'food_$index',
                              child: ClipRRect(
                                borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), bottomLeft: Radius.circular(20)),
                                child: Image.network(
                                  item['image_url'] ?? "",
                                  width: 120,
                                  height: 120,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c,e,s) => Container(width: 120, height: 120, color: Colors.grey[200], child: const Icon(Icons.fastfood, color: Colors.grey)),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 8,
                              left: 8,
                              child: GestureDetector(
                                onTap: () => _toggleFavorite(item['food_id']),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
                                  child: Icon(
                                     _favoriteIds.contains(item['food_id']) ? Icons.favorite : Icons.favorite_border,
                                     color: Colors.red,
                                     size: 18
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        // Content
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  item['food_name'] ?? "",
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkColor),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item['description'] ?? "Delicious Arabian food",
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Dynamic Price Display
                                    // Dynamic Price Display
                                    Builder(
                                      builder: (context) {
                                        final price = (item['food_price'] as num?)?.toDouble() ?? 0.0;
                                        final discountPercent = (item['discount_percentage'] as num?)?.toDouble() ?? 0.0;
                                        
                                        if (discountPercent > 0) {
                                          final discountedPrice = price * (1 - (discountPercent / 100));
                                          
                                          return Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "₹${discountedPrice.toStringAsFixed(1)}",
                                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: primaryColor),
                                              ),
                                              Row(
                                                children: [
                                                  Text(
                                                    "₹${price.toStringAsFixed(0)}",
                                                    style: const TextStyle(
                                                      fontSize: 12, 
                                                      color: Colors.grey, 
                                                      decoration: TextDecoration.lineThrough
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    "${discountPercent.toInt()}% OFF",
                                                    style: const TextStyle(
                                                      fontSize: 10, 
                                                      fontWeight: FontWeight.bold, 
                                                      color: Colors.green
                                                    ),
                                                  )
                                                ],
                                              ),
                                            ],
                                          );
                                        }

                                        return Text(
                                          "₹${price.toStringAsFixed(1)}",
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: primaryColor),
                                        );
                                      }
                                    ),
                                    InkWell(
                                      onTap: () async {
                                        if (item['variants'] != null && (item['variants'] as List).isNotEmpty) {
                                           final itemWithFav = Map<String, dynamic>.from(item);
                                           itemWithFav['isFavorite'] = _favoriteIds.contains(item['food_id']);
                                           await context.push('/product-details', extra: itemWithFav);
                                           final repo = context.read<DashboardRepository>();
                                           final favs = await repo.getFavorites();
                                           if (mounted) {
                                             setState(() {
                                               _favoriteIds = favs.map<int>((e) => e['food_id'] as int).toSet();
                                             });
                                           }
                                        } else {
                                          context.read<CartBloc>().add(CartItemAdded(item));
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text("${item['food_name']} added to cart +"),
                                              duration: const Duration(milliseconds: 600),
                                              backgroundColor: Colors.black87,
                                            ),
                                          );
                                        }
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: darkColor,
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        child: const Text("ADD", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  )).animate().fadeIn(duration: 400.ms).slideX(begin: 0.1),
                );
              },
              childCount: _filteredItems.length,
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
      ),
    );
  }
}

class _SliverCategoryDelegate extends SliverPersistentHeaderDelegate {
  final List<String> categories;
  final String selectedCategory;
  final Function(String) onCategorySelected;

  _SliverCategoryDelegate({
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  double get minExtent => 60;
  @override
  double get maxExtent => 60;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: const Color(0xFFFAFAFA), // Match background
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => onCategorySelected(cat),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFD4AF37) : Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    if (!isSelected)
                     BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  cat,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  bool shouldRebuild(_SliverCategoryDelegate oldDelegate) {
    return oldDelegate.selectedCategory != selectedCategory;
  }
}
