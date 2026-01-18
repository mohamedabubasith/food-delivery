import 'package:dio/dio.dart';

class DashboardRepository {
  final Dio _dio;

  DashboardRepository(this._dio);

  Future<List<dynamic>> getRestaurants() async {
    try {
      final response = await _dio.get('/restaurants/');
      if (response.data is Map && response.data.containsKey('data')) {
        return response.data['data'] as List<dynamic>;
      }
      return response.data as List<dynamic>;
    } catch (e) {
      if (e is DioException) {
        throw Exception(e.response?.data['detail'] ?? 'Failed to fetch restaurants');
      }
      rethrow;
    }
  }

  Future<List<dynamic>> getBanners() async {
    try {
      print("Fetching banners...");
      final response = await _dio.get('/restaurants/marketing/banners');
      print("Banners response: ${response.data}");
      if (response.data is Map && response.data.containsKey('data')) {
        return response.data['data'] as List<dynamic>;
      }
      return response.data as List<dynamic>;
    } catch (e) {
      print("Error fetching banners: $e");
      return [];
    }
  }

  Future<List<dynamic>> getCollections() async {
    try {
      final response = await _dio.get('/restaurants/marketing/collections');
      if (response.data is Map && response.data.containsKey('data')) {
        return response.data['data'] as List<dynamic>;
      }
      return response.data as List<dynamic>;
    } catch (e) {
      return [];
    }
  }

  Future<List<dynamic>> getMenu({String? category, int? restaurantId}) async {
    try {
      final Map<String, dynamic> queryParams = {};
      if (category != null) queryParams['category'] = category;
      if (restaurantId != null) queryParams['restaurant_id'] = restaurantId;

      final response = await _dio.get(
        '/menu/',
        queryParameters: queryParams,
      );
      if (response.data is Map && response.data.containsKey('data')) {
        return response.data['data'] as List<dynamic>;
      }
      return response.data as List<dynamic>;
    } catch (e) {
        // If error, return empty list
       return [];
    }
  }

  Future<Map<String, dynamic>> validateCoupon(String code, double total) async {
    try {
      final response = await _dio.post('/restaurants/marketing/apply-coupon', data: {
        "code": code,
        "cart_total": total,
      });
      
      if (response.data is Map && response.data.containsKey('data')) {
         return response.data['data'] as Map<String, dynamic>;
      }
      return response.data as Map<String, dynamic>;
    } catch (e) {
      if (e is DioException) {
        throw Exception(e.response?.data['detail'] ?? "Invalid Coupon");
      }
      throw Exception("Failed to apply coupon");
    }
  }

  Future<List<dynamic>> getUserCoupons() async {
    try {
      final response = await _dio.get('/restaurants/marketing/my-coupons');
      if (response.data is Map && response.data.containsKey('data')) {
        return response.data['data'] as List<dynamic>;
      }
      return response.data as List<dynamic>;
    } catch (e) {
      return [];
    }
  }

  Future<void> claimCoupon(String code) async {
    try {
      await _dio.post('/restaurants/marketing/claim-coupon', data: {"code": code});
    } catch (e) {
       if (e is DioException) {
        throw Exception(e.response?.data['detail'] ?? "Failed to claim coupon");
      }
      throw Exception("Failed to claim coupon");
    }
  }

  Future<List<dynamic>> getFavorites() async {
    try {
      final response = await _dio.get('/menu/favorites');
      if (response.data is Map && response.data.containsKey('data')) {
        return response.data['data'] as List<dynamic>;
      }
      return response.data as List<dynamic>;
    } catch (e) {
      print("Error getting favorites: $e");
      return [];
    }
  }

  Future<void> toggleFavorite(int foodId) async {
    try {
      await _dio.post('/menu/$foodId/favorite');
    } catch (e) {
       print("Error toggling favorite: $e");
       rethrow;
    }
  }
}
