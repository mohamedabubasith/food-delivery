import 'package:equatable/equatable.dart';

abstract class CartEvent extends Equatable {
  const CartEvent();

  @override
  List<Object?> get props => [];
}

class CartStarted extends CartEvent {}

class CartItemAdded extends CartEvent {
  final Map<String, dynamic> item;
  const CartItemAdded(this.item);

  @override
  List<Object?> get props => [item];
}

class CartItemRemoved extends CartEvent {
  final Map<String, dynamic> item;
  const CartItemRemoved(this.item);

  @override
  List<Object?> get props => [item];
}

class CartCouponApplied extends CartEvent {
  final String code;
  const CartCouponApplied(this.code);

  @override
  List<Object?> get props => [code];
}

class CartCleared extends CartEvent {}

class CartUserCouponsRequested extends CartEvent {}

class CartCouponClaimed extends CartEvent {
  final String code;
  const CartCouponClaimed(this.code);

  @override
  List<Object?> get props => [code];
}
