import 'package:flutter_bloc/flutter_bloc.dart';
import '../../dashboard/data/dashboard_repository.dart';
import 'cart_event.dart';
import 'cart_state.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  final DashboardRepository _dashboardRepository;

  CartBloc(this._dashboardRepository) : super(const CartState()) {
    on<CartStarted>(_onStarted);
    on<CartItemAdded>(_onItemAdded);
    on<CartItemRemoved>(_onItemRemoved);
    on<CartCouponApplied>(_onCouponApplied);
    on<CartCleared>(_onCleared);
    on<CartUserCouponsRequested>(_onUserCouponsRequested);
    on<CartCouponClaimed>(_onCouponClaimed);
  }

  void _onStarted(CartStarted event, Emitter<CartState> emit) {
    emit(const CartState(status: CartStatus.success));
  }

  Future<void> _onItemAdded(CartItemAdded event, Emitter<CartState> emit) async {
    final updatedItems = List<Map<String, dynamic>>.from(state.items)..add(event.item);
    
    double newDiscount = state.discountAmount;
    String? validationMsg;
    if (state.couponCode != null) {
       try {
         final subtotal = updatedItems.fold(0.0, (sum, item) {
            final price = (item['food_price'] as num?)?.toDouble() ?? 0.0;
            final discount = (item['discount_percentage'] as num?)?.toDouble() ?? 0.0;
            return sum + (price * (1 - (discount / 100)));
         });
         print("DEBUG: _onItemAdded Subtotal: $subtotal");
         final result = await _dashboardRepository.validateCoupon(state.couponCode!, subtotal);
         print("DEBUG: _onItemAdded Result: $result");
         newDiscount = (result['discount_amount'] as num?)?.toDouble() ?? 0.0;
       } catch (e) {
         print("DEBUG: _onItemAdded Validation Failed: $e");
         newDiscount = 0.0; 
         validationMsg = "Coupon '${state.couponCode}' invalid: ${e.toString().replaceAll('Exception: ', '')}";
       }
    }

    emit(state.copyWith(items: updatedItems, discountAmount: newDiscount, status: CartStatus.success));
  }

  Future<void> _onItemRemoved(CartItemRemoved event, Emitter<CartState> emit) async {
    final updatedItems = List<Map<String, dynamic>>.from(state.items);
    updatedItems.remove(event.item); 
    
    double newDiscount = state.discountAmount;
    String? validationMsg;
    if (state.couponCode != null) {
       try {
         final subtotal = updatedItems.fold(0.0, (sum, item) {
            final price = (item['food_price'] as num?)?.toDouble() ?? 0.0;
            final discount = (item['discount_percentage'] as num?)?.toDouble() ?? 0.0;
            return sum + (price * (1 - (discount / 100)));
         });
         print("DEBUG: _onItemRemoved Subtotal: $subtotal");
         if (subtotal == 0) {
            newDiscount = 0.0;
         } else {
            final result = await _dashboardRepository.validateCoupon(state.couponCode!, subtotal);
            newDiscount = (result['discount_amount'] as num?)?.toDouble() ?? 0.0;
         }
       } catch (e) {
          print("DEBUG: _onItemRemoved Validation Failed: $e");
          newDiscount = 0.0; 
          validationMsg = "Coupon '${state.couponCode}' invalid: ${e.toString().replaceAll('Exception: ', '')}";
       }
    }

    emit(state.copyWith(items: updatedItems, discountAmount: newDiscount, status: CartStatus.success));
  }

  Future<void> _onCouponApplied(CartCouponApplied event, Emitter<CartState> emit) async {
    emit(state.copyWith(status: CartStatus.loading));
    try {
      print("DEBUG: Applying Coupon ${event.code} on Subtotal: ${state.subtotal}");
      final result = await _dashboardRepository.validateCoupon(event.code, state.subtotal);
      print("DEBUG: Apply Coupon Result: $result");
      // result: {valid: true, discount_amount: 10.0, final_amount: 90.0}
      final discount = (result['discount_amount'] as num?)?.toDouble() ?? 0.0;
      
      emit(state.copyWith(
        status: CartStatus.success,
        couponCode: event.code,
        discountAmount: discount,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: CartStatus.failure,
        error: e.toString().replaceAll("Exception: ", ""),
        couponCode: null,
        discountAmount: 0.0, 
      ));
    }
  }

  void _onCleared(CartCleared event, Emitter<CartState> emit) {
    emit(const CartState(status: CartStatus.success, items: []));
  }

  Future<void> _onUserCouponsRequested(CartUserCouponsRequested event, Emitter<CartState> emit) async {
     try {
       final coupons = await _dashboardRepository.getUserCoupons();
       emit(state.copyWith(userCoupons: coupons));
     } catch (e) {
       // Silent fail or minimal error
     }
  }

  Future<void> _onCouponClaimed(CartCouponClaimed event, Emitter<CartState> emit) async {
    emit(state.copyWith(isClaiming: true, claimError: null));
    try {
      await _dashboardRepository.claimCoupon(event.code);
      // Refresh list
      add(CartUserCouponsRequested());
      emit(state.copyWith(isClaiming: false));
    } catch (e) {
      emit(state.copyWith(isClaiming: false, claimError: e.toString().replaceAll("Exception: ", "")));
    }
  }
}
