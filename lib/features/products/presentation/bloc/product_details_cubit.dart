import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lumacart/core/constants/app_constants.dart';
import 'package:lumacart/core/errors/failure.dart';
import 'package:lumacart/features/products/domain/product.dart';
import 'package:lumacart/features/products/domain/products_repository.dart';

enum ProductDetailsStatus { initial, loading, success, failure }

class ProductDetailsState extends Equatable {
  const ProductDetailsState({
    this.status = ProductDetailsStatus.initial,
    this.product,
    this.quantity = 1,
    this.message,
  });

  final ProductDetailsStatus status;
  final Product? product;
  final int quantity;
  final String? message;

  ProductDetailsState copyWith({
    ProductDetailsStatus? status,
    Product? product,
    int? quantity,
    String? message,
    bool clearMessage = false,
  }) {
    return ProductDetailsState(
      status: status ?? this.status,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      message: clearMessage ? null : message ?? this.message,
    );
  }

  @override
  List<Object?> get props => <Object?>[status, product, quantity, message];
}

class ProductDetailsCubit extends Cubit<ProductDetailsState> {
  ProductDetailsCubit({
    required ProductsRepository repository,
    Product? initialProduct,
  })  : _repository = repository,
        super(
          initialProduct == null
              ? const ProductDetailsState()
              : ProductDetailsState(
                  status: ProductDetailsStatus.success,
                  product: initialProduct,
                ),
        );

  final ProductsRepository _repository;

  Future<void> load(int id) async {
    if (state.product?.id == id) return;
    emit(state.copyWith(
      status: ProductDetailsStatus.loading,
      clearMessage: true,
    ));
    try {
      final Product product = await _repository.getProduct(id);
      emit(state.copyWith(
        status: ProductDetailsStatus.success,
        product: product,
      ));
    } on Failure catch (failure) {
      emit(state.copyWith(
        status: ProductDetailsStatus.failure,
        message: failure.message,
      ));
    } on Object {
      emit(state.copyWith(
        status: ProductDetailsStatus.failure,
        message: 'Product details could not be loaded.',
      ));
    }
  }

  void increment() {
    if (state.quantity >= AppConstants.maxCartQuantity) return;
    emit(state.copyWith(quantity: state.quantity + 1));
  }

  void decrement() {
    if (state.quantity <= 1) return;
    emit(state.copyWith(quantity: state.quantity - 1));
  }
}
