import 'package:equatable/equatable.dart';

enum CartStatus { initial, loading, success, failure }

class CartState extends Equatable {
  final CartStatus status;
  final List<Map<String, dynamic>> items;
  final String? couponCode;
  final double discountAmount;
  final String? error;
  final String? validationError; // For inline check failures
  
  final List<dynamic> userCoupons;
  final bool isClaiming;
  final String? claimError;

  const CartState({
    this.status = CartStatus.initial,
    this.items = const [],
    this.couponCode,
    this.discountAmount = 0.0,
    this.error,
    this.validationError,
    this.userCoupons = const [],
    this.isClaiming = false,
    this.claimError,
  });

  double get subtotal => items.fold(0.0, (sum, item) {
    final price = (item['food_price'] as num?)?.toDouble() ?? 0.0;
    final discount = (item['discount_percentage'] as num?)?.toDouble() ?? 0.0;
    return sum + (price * (1 - (discount / 100)));
  });
  double get total => subtotal - discountAmount > 0 ? subtotal - discountAmount : 0.0;

  CartState copyWith({
    CartStatus? status,
    List<Map<String, dynamic>>? items,
    String? couponCode,
    double? discountAmount,
    String? error,
    String? validationError,
    List<dynamic>? userCoupons,
    bool? isClaiming,
    String? claimError,
  }) {
    return CartState(
      status: status ?? this.status,
      items: items ?? this.items,
      couponCode: couponCode ?? this.couponCode,
      discountAmount: discountAmount ?? this.discountAmount,
      error: error,
      validationError: validationError,
      userCoupons: userCoupons ?? this.userCoupons,
      isClaiming: isClaiming ?? this.isClaiming,
      claimError: claimError,
    );
  }

  @override
  List<Object?> get props => [status, items, couponCode, discountAmount, error, validationError, userCoupons, isClaiming, claimError];
}
