import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lumacart/core/constants/app_constants.dart';
import 'package:lumacart/core/errors/failure.dart';
import 'package:lumacart/features/auth/domain/auth_models.dart';
import 'package:lumacart/features/cart/domain/cart_models.dart';
import 'package:lumacart/features/cart/domain/cart_repository.dart';
import 'package:lumacart/features/products/domain/product.dart';

abstract class CartEvent extends Equatable {
  const CartEvent();

  @override
  List<Object?> get props => const <Object?>[];
}

class CartOwnerChanged extends CartEvent {
  const CartOwnerChanged(this.session);

  final AuthSession? session;

  @override
  List<Object?> get props => <Object?>[session];
}

class CartProductAdded extends CartEvent {
  const CartProductAdded(this.product, {this.quantity = 1});

  final Product product;
  final int quantity;

  @override
  List<Object?> get props => <Object?>[product, quantity];
}

class CartProductRemoved extends CartEvent {
  const CartProductRemoved(this.productId);

  final int productId;

  @override
  List<Object?> get props => <Object?>[productId];
}

class CartQuantityIncremented extends CartEvent {
  const CartQuantityIncremented(this.productId);

  final int productId;

  @override
  List<Object?> get props => <Object?>[productId];
}

class CartQuantityDecremented extends CartEvent {
  const CartQuantityDecremented(this.productId);

  final int productId;

  @override
  List<Object?> get props => <Object?>[productId];
}

class CartQuantitySet extends CartEvent {
  const CartQuantitySet(this.productId, this.quantity);

  final int productId;
  final int quantity;

  @override
  List<Object?> get props => <Object?>[productId, quantity];
}

class CartClearRequested extends CartEvent {
  const CartClearRequested();
}

class CartSaveRequested extends CartEvent {
  const CartSaveRequested(this.name);

  final String name;

  @override
  List<Object?> get props => <Object?>[name];
}

class CartRestoreRequested extends CartEvent {
  const CartRestoreRequested(this.savedCartId, this.mode);

  final String savedCartId;
  final RestoreMode mode;

  @override
  List<Object?> get props => <Object?>[savedCartId, mode];
}

class CartSavedDeleted extends CartEvent {
  const CartSavedDeleted(this.savedCartId);

  final String savedCartId;

  @override
  List<Object?> get props => <Object?>[savedCartId];
}

enum CartStatus { initial, loading, ready, saving, failure }

class CartState extends Equatable {
  const CartState({
    this.status = CartStatus.initial,
    this.session,
    this.cart,
    this.savedCarts = const <SavedCart>[],
    this.message,
    this.notice,
  });

  final CartStatus status;
  final AuthSession? session;
  final LocalCart? cart;
  final List<SavedCart> savedCarts;
  final String? message;
  final String? notice;

  int get itemCount => cart?.itemCount ?? 0;

  CartState copyWith({
    CartStatus? status,
    AuthSession? session,
    bool clearSession = false,
    LocalCart? cart,
    bool clearCart = false,
    List<SavedCart>? savedCarts,
    String? message,
    bool clearMessage = false,
    String? notice,
    bool clearNotice = false,
  }) {
    return CartState(
      status: status ?? this.status,
      session: clearSession ? null : session ?? this.session,
      cart: clearCart ? null : cart ?? this.cart,
      savedCarts: savedCarts ?? this.savedCarts,
      message: clearMessage ? null : message ?? this.message,
      notice: clearNotice ? null : notice ?? this.notice,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        status,
        session,
        cart,
        savedCarts,
        message,
        notice,
      ];
}

class CartBloc extends Bloc<CartEvent, CartState> {
  CartBloc({required CartRepository repository})
      : _repository = repository,
        super(const CartState()) {
    on<CartEvent>(
      _onEvent,
      transformer: _sequential<CartEvent>(),
    );
  }

  final CartRepository _repository;

  Future<void> _onEvent(CartEvent event, Emitter<CartState> emit) async {
    if (event is CartOwnerChanged) {
      await _onOwnerChanged(event, emit);
    } else if (event is CartProductAdded) {
      await _onProductAdded(event, emit);
    } else if (event is CartProductRemoved) {
      await _onProductRemoved(event, emit);
    } else if (event is CartQuantityIncremented) {
      await _onIncremented(event, emit);
    } else if (event is CartQuantityDecremented) {
      await _onDecremented(event, emit);
    } else if (event is CartQuantitySet) {
      await _onQuantitySet(event, emit);
    } else if (event is CartClearRequested) {
      await _onClear(event, emit);
    } else if (event is CartSaveRequested) {
      await _onSave(event, emit);
    } else if (event is CartRestoreRequested) {
      await _onRestore(event, emit);
    } else if (event is CartSavedDeleted) {
      await _onDeleteSaved(event, emit);
    }
  }

  Future<void> _onOwnerChanged(
    CartOwnerChanged event,
    Emitter<CartState> emit,
  ) async {
    if (event.session == null) {
      emit(const CartState(status: CartStatus.initial));
      return;
    }
    emit(CartState(status: CartStatus.loading, session: event.session));
    try {
      final LocalCart cart =
          await _repository.loadCurrent(event.session!.accountKey);
      final List<SavedCart> saved =
          await _repository.loadSaved(event.session!.accountKey);
      emit(CartState(
        status: CartStatus.ready,
        session: event.session,
        cart: cart,
        savedCarts: saved,
      ));
    } on Failure catch (failure) {
      emit(CartState(
        status: CartStatus.failure,
        session: event.session,
        cart: LocalCart.empty(event.session!.accountKey),
        message: failure.message,
      ));
    }
  }

  Future<void> _onProductAdded(
    CartProductAdded event,
    Emitter<CartState> emit,
  ) async {
    final LocalCart? current = state.cart;
    if (current == null || !event.product.isUsable) return;
    final int addQuantity = event.quantity
        .clamp(1, AppConstants.maxCartQuantity)
        .toInt();
    final List<CartLine> lines = List<CartLine>.from(current.lines);
    final int index = lines.indexWhere(
      (CartLine line) => line.product.id == event.product.id,
    );
    if (index >= 0) {
      lines[index] = lines[index].copyWith(
        quantity: (lines[index].quantity + addQuantity)
            .clamp(1, AppConstants.maxCartQuantity).toInt(),
      );
    } else {
      lines.add(CartLine(product: event.product, quantity: addQuantity));
    }
    await _persist(
      current.copyWith(lines: lines, updatedAt: DateTime.now().toUtc()),
      emit,
      notice: '${event.product.title} added to cart.',
    );
  }

  Future<void> _onProductRemoved(
    CartProductRemoved event,
    Emitter<CartState> emit,
  ) async {
    final LocalCart? current = state.cart;
    if (current == null) return;
    final List<CartLine> lines = current.lines
        .where((CartLine line) => line.product.id != event.productId)
        .toList(growable: false);
    await _persist(
      current.copyWith(lines: lines, updatedAt: DateTime.now().toUtc()),
      emit,
    );
  }

  Future<void> _onIncremented(
    CartQuantityIncremented event,
    Emitter<CartState> emit,
  ) => _changeQuantity(event.productId, 1, emit);

  Future<void> _onDecremented(
    CartQuantityDecremented event,
    Emitter<CartState> emit,
  ) => _changeQuantity(event.productId, -1, emit);

  Future<void> _onQuantitySet(
    CartQuantitySet event,
    Emitter<CartState> emit,
  ) async {
    if (event.quantity < 1) return;
    final LocalCart? current = state.cart;
    if (current == null) return;
    final List<CartLine> lines = current.lines.map((CartLine line) {
      if (line.product.id != event.productId) return line;
      return line.copyWith(
        quantity: event.quantity
            .clamp(1, AppConstants.maxCartQuantity)
            .toInt(),
      );
    }).toList(growable: false);
    await _persist(
      current.copyWith(lines: lines, updatedAt: DateTime.now().toUtc()),
      emit,
    );
  }

  Future<void> _changeQuantity(
    int productId,
    int delta,
    Emitter<CartState> emit,
  ) async {
    final LocalCart? current = state.cart;
    if (current == null) return;
    final List<CartLine> lines = current.lines.map((CartLine line) {
      if (line.product.id != productId) return line;
      return line.copyWith(
        quantity: (line.quantity + delta)
            .clamp(1, AppConstants.maxCartQuantity).toInt(),
      );
    }).toList(growable: false);
    await _persist(
      current.copyWith(lines: lines, updatedAt: DateTime.now().toUtc()),
      emit,
    );
  }

  Future<void> _onClear(
    CartClearRequested event,
    Emitter<CartState> emit,
  ) async {
    final LocalCart? current = state.cart;
    if (current == null) return;
    await _persist(
      current.copyWith(
        lines: const <CartLine>[],
        updatedAt: DateTime.now().toUtc(),
      ),
      emit,
      notice: 'Cart cleared.',
    );
  }

  Future<void> _onSave(
    CartSaveRequested event,
    Emitter<CartState> emit,
  ) async {
    final LocalCart? current = state.cart;
    if (current == null || current.isEmpty) {
      emit(state.copyWith(
        status: CartStatus.failure,
        message: 'Add at least one product before saving this cart.',
        clearNotice: true,
      ));
      return;
    }
    emit(state.copyWith(
      status: CartStatus.saving,
      clearMessage: true,
      clearNotice: true,
    ));
    try {
      final AuthSession? session = state.session;
      final SavedCartResult result = await _repository.saveSnapshot(
        cart: current,
        name: event.name,
        apiUserId: session?.accountType == AccountType.api
            ? session?.user.id
            : null,
      );
      final List<SavedCart> saved =
          await _repository.loadSaved(current.ownerKey);
      emit(state.copyWith(
        status: CartStatus.ready,
        savedCarts: saved,
        notice: result.syncNotice ?? 'Cart saved.',
        clearMessage: true,
      ));
    } on Failure catch (failure) {
      emit(state.copyWith(
        status: CartStatus.failure,
        message: failure.message,
      ));
    }
  }

  Future<void> _onRestore(
    CartRestoreRequested event,
    Emitter<CartState> emit,
  ) async {
    final LocalCart? current = state.cart;
    if (current == null) return;
    final SavedCart? saved = state.savedCarts
        .where((SavedCart cart) => cart.id == event.savedCartId)
        .firstOrNull;
    if (saved == null) {
      emit(state.copyWith(
        status: CartStatus.failure,
        message: 'The saved cart could not be found.',
      ));
      return;
    }

    final List<CartLine> lines = event.mode == RestoreMode.replace
        ? List<CartLine>.from(saved.lines)
        : _merge(current.lines, saved.lines);
    await _persist(
      current.copyWith(lines: lines, updatedAt: DateTime.now().toUtc()),
      emit,
      notice: event.mode == RestoreMode.replace
          ? 'Saved cart restored.'
          : 'Saved cart merged with the current cart.',
    );
  }

  Future<void> _onDeleteSaved(
    CartSavedDeleted event,
    Emitter<CartState> emit,
  ) async {
    try {
      await _repository.deleteSaved(event.savedCartId);
      emit(state.copyWith(
        savedCarts: state.savedCarts
            .where((SavedCart cart) => cart.id != event.savedCartId)
            .toList(growable: false),
        status: CartStatus.ready,
        notice: 'Saved cart deleted.',
        clearMessage: true,
      ));
    } on Failure catch (failure) {
      emit(state.copyWith(
        status: CartStatus.failure,
        message: failure.message,
      ));
    }
  }

  Future<void> _persist(
    LocalCart updated,
    Emitter<CartState> emit, {
    String? notice,
  }) async {
    try {
      await _repository.saveCurrent(updated);
      emit(state.copyWith(
        status: CartStatus.ready,
        cart: updated,
        notice: notice,
        clearNotice: notice == null,
        clearMessage: true,
      ));
    } on Failure catch (failure) {
      emit(state.copyWith(
        status: CartStatus.failure,
        message: failure.message,
      ));
    }
  }

  List<CartLine> _merge(List<CartLine> current, List<CartLine> saved) {
    final Map<int, CartLine> merged = <int, CartLine>{
      for (final CartLine line in current) line.product.id: line,
    };
    for (final CartLine line in saved) {
      final CartLine? existing = merged[line.product.id];
      merged[line.product.id] = existing == null
          ? line
          : existing.copyWith(
              quantity: (existing.quantity + line.quantity)
                  .clamp(1, AppConstants.maxCartQuantity).toInt(),
            );
    }
    return merged.values.toList(growable: false);
  }
}


EventTransformer<Event> _sequential<Event>() {
  return (events, mapper) => events.asyncExpand(mapper);
}
