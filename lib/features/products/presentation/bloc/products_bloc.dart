import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lumacart/core/constants/app_constants.dart';
import 'package:lumacart/core/errors/failure.dart';
import 'package:lumacart/features/products/domain/product.dart';
import 'package:lumacart/features/products/domain/products_repository.dart';

abstract class ProductsEvent extends Equatable {
  const ProductsEvent();

  @override
  List<Object?> get props => const <Object?>[];
}

class ProductsLoadRequested extends ProductsEvent {
  const ProductsLoadRequested();
}

class ProductsRefreshRequested extends ProductsEvent {
  const ProductsRefreshRequested();
}

class ProductsSearchChanged extends ProductsEvent {
  const ProductsSearchChanged(this.query);

  final String query;

  @override
  List<Object?> get props => <Object?>[query];
}

class ProductsSearchApplied extends ProductsEvent {
  const ProductsSearchApplied(this.query);

  final String query;

  @override
  List<Object?> get props => <Object?>[query];
}

class ProductsCategorySelected extends ProductsEvent {
  const ProductsCategorySelected(this.category);

  final String? category;

  @override
  List<Object?> get props => <Object?>[category];
}

enum ProductsStatus { initial, loading, success, empty, failure }

class ProductsState extends Equatable {
  const ProductsState({
    this.status = ProductsStatus.initial,
    this.allProducts = const <Product>[],
    this.visibleProducts = const <Product>[],
    this.categories = const <String>[],
    this.searchQuery = '',
    this.selectedCategory,
    this.message,
    this.warning,
    this.isRefreshing = false,
  });

  final ProductsStatus status;
  final List<Product> allProducts;
  final List<Product> visibleProducts;
  final List<String> categories;
  final String searchQuery;
  final String? selectedCategory;
  final String? message;
  final String? warning;
  final bool isRefreshing;

  ProductsState copyWith({
    ProductsStatus? status,
    List<Product>? allProducts,
    List<Product>? visibleProducts,
    List<String>? categories,
    String? searchQuery,
    String? selectedCategory,
    bool clearCategory = false,
    String? message,
    bool clearMessage = false,
    String? warning,
    bool clearWarning = false,
    bool? isRefreshing,
  }) {
    return ProductsState(
      status: status ?? this.status,
      allProducts: allProducts ?? this.allProducts,
      visibleProducts: visibleProducts ?? this.visibleProducts,
      categories: categories ?? this.categories,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategory:
          clearCategory ? null : selectedCategory ?? this.selectedCategory,
      message: clearMessage ? null : message ?? this.message,
      warning: clearWarning ? null : warning ?? this.warning,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        status,
        allProducts,
        visibleProducts,
        categories,
        searchQuery,
        selectedCategory,
        message,
        warning,
        isRefreshing,
      ];
}

class ProductsBloc extends Bloc<ProductsEvent, ProductsState> {
  ProductsBloc({required ProductsRepository repository})
      : _repository = repository,
        super(const ProductsState()) {
    on<ProductsEvent>(
      _onEvent,
      transformer: _sequential<ProductsEvent>(),
    );
  }

  final ProductsRepository _repository;
  Timer? _searchTimer;

  Future<void> _onEvent(
    ProductsEvent event,
    Emitter<ProductsState> emit,
  ) async {
    if (event is ProductsLoadRequested) {
      await _onLoad(event, emit);
    } else if (event is ProductsRefreshRequested) {
      await _onRefresh(event, emit);
    } else if (event is ProductsSearchChanged) {
      _onSearchChanged(event, emit);
    } else if (event is ProductsSearchApplied) {
      _onSearchApplied(event, emit);
    } else if (event is ProductsCategorySelected) {
      _onCategorySelected(event, emit);
    }
  }

  Future<void> _onLoad(
    ProductsLoadRequested event,
    Emitter<ProductsState> emit,
  ) async {
    if (state.status == ProductsStatus.loading) return;
    emit(state.copyWith(
      status: ProductsStatus.loading,
      clearMessage: true,
      clearWarning: true,
    ));
    await _loadIntoState(emit);
  }

  Future<void> _onRefresh(
    ProductsRefreshRequested event,
    Emitter<ProductsState> emit,
  ) async {
    emit(state.copyWith(
      isRefreshing: true,
      clearMessage: true,
      clearWarning: true,
    ));
    await _loadIntoState(emit);
  }

  Future<void> _loadIntoState(Emitter<ProductsState> emit) async {
    try {
      final ProductCatalogResult result = await _repository.loadCatalog();
      final List<Product> filtered = _filter(
        result.products,
        state.searchQuery,
        state.selectedCategory,
      );
      emit(state.copyWith(
        status: filtered.isEmpty ? ProductsStatus.empty : ProductsStatus.success,
        allProducts: result.products,
        visibleProducts: filtered,
        categories: result.categories,
        warning: result.warning,
        clearWarning: result.warning == null,
        isRefreshing: false,
      ));
    } on Failure catch (failure) {
      emit(state.copyWith(
        status: state.allProducts.isEmpty
            ? ProductsStatus.failure
            : ProductsStatus.success,
        message: failure.message,
        isRefreshing: false,
      ));
    } on Object {
      emit(state.copyWith(
        status: state.allProducts.isEmpty
            ? ProductsStatus.failure
            : ProductsStatus.success,
        message: 'Products could not be loaded.',
        isRefreshing: false,
      ));
    }
  }

  void _onSearchChanged(
    ProductsSearchChanged event,
    Emitter<ProductsState> emit,
  ) {
    emit(state.copyWith(searchQuery: event.query));
    _searchTimer?.cancel();
    _searchTimer = Timer(
      AppConstants.searchDebounce,
      () => add(ProductsSearchApplied(event.query)),
    );
  }

  void _onSearchApplied(
    ProductsSearchApplied event,
    Emitter<ProductsState> emit,
  ) {
    if (event.query != state.searchQuery) return;
    final List<Product> filtered = _filter(
      state.allProducts,
      event.query,
      state.selectedCategory,
    );
    emit(state.copyWith(
      status: filtered.isEmpty ? ProductsStatus.empty : ProductsStatus.success,
      visibleProducts: filtered,
      clearMessage: true,
    ));
  }

  void _onCategorySelected(
    ProductsCategorySelected event,
    Emitter<ProductsState> emit,
  ) {
    final List<Product> filtered = _filter(
      state.allProducts,
      state.searchQuery,
      event.category,
    );
    emit(state.copyWith(
      status: filtered.isEmpty ? ProductsStatus.empty : ProductsStatus.success,
      visibleProducts: filtered,
      selectedCategory: event.category,
      clearCategory: event.category == null,
      clearMessage: true,
    ));
  }

  List<Product> _filter(
    List<Product> products,
    String query,
    String? category,
  ) {
    final String normalizedQuery = query.trim().toLowerCase();
    final String? normalizedCategory = category?.toLowerCase();
    return products.where((Product product) {
      final bool categoryMatches = normalizedCategory == null ||
          product.category.toLowerCase() == normalizedCategory;
      final bool queryMatches = normalizedQuery.isEmpty ||
          product.title.toLowerCase().contains(normalizedQuery) ||
          product.category.toLowerCase().contains(normalizedQuery);
      return categoryMatches && queryMatches;
    }).toList(growable: false);
  }

  @override
  Future<void> close() {
    _searchTimer?.cancel();
    return super.close();
  }
}

EventTransformer<Event> _sequential<Event>() {
  return (events, mapper) => events.asyncExpand(mapper);
}
