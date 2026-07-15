import 'package:lumacart/core/constants/api_paths.dart';
import 'package:lumacart/core/constants/storage_keys.dart';
import 'package:lumacart/core/errors/failure.dart';
import 'package:lumacart/core/network/api_client.dart';
import 'package:lumacart/core/storage/local_store.dart';
import 'package:lumacart/core/utils/json_parsing.dart';
import 'package:lumacart/features/cart/domain/cart_models.dart';
import 'package:lumacart/features/cart/domain/cart_repository.dart';
import 'package:uuid/uuid.dart';

class CartRepositoryImpl implements CartRepository {
  CartRepositoryImpl({
    required LocalStore localStore,
    required ApiClient apiClient,
    Uuid? uuid,
  })  : _localStore = localStore,
        _apiClient = apiClient,
        _uuid = uuid ?? const Uuid();

  final LocalStore _localStore;
  final ApiClient _apiClient;
  final Uuid _uuid;

  @override
  Future<LocalCart> loadCurrent(String ownerKey) async {
    final Map<String, Object?> carts = _currentCartMap();
    final Object? raw = carts[ownerKey];
    if (raw == null) return LocalCart.empty(ownerKey);
    final LocalCart cart = LocalCart.fromJson(raw);
    if (cart.ownerKey != ownerKey) return LocalCart.empty(ownerKey);
    return cart;
  }

  @override
  Future<void> saveCurrent(LocalCart cart) async {
    final Map<String, Object?> carts = _currentCartMap();
    carts[cart.ownerKey] = cart.toJson();
    await _localStore.writeApp(StorageKeys.currentCarts, carts);
  }

  @override
  Future<List<SavedCart>> loadSaved(String ownerKey) async {
    final List<SavedCart> carts = _allSaved()
        .where((SavedCart cart) => cart.ownerKey == ownerKey)
        .toList(growable: false)
      ..sort((SavedCart first, SavedCart second) =>
          second.createdAt.compareTo(first.createdAt));
    return carts;
  }

  @override
  Future<SavedCartResult> saveSnapshot({
    required LocalCart cart,
    required String name,
    int? apiUserId,
  }) async {
    if (cart.isEmpty) {
      throw const Failure(
        message: 'Add at least one product before saving this cart.',
        type: FailureType.validation,
      );
    }
    final SavedCart snapshot = SavedCart(
      id: _uuid.v4(),
      ownerKey: cart.ownerKey,
      name: name.trim().isEmpty ? 'Saved cart' : name.trim(),
      lines: List<CartLine>.unmodifiable(cart.lines),
      createdAt: DateTime.now().toUtc(),
    );
    final List<SavedCart> all = <SavedCart>[snapshot, ..._allSaved()];
    await _writeSaved(all);

    if (apiUserId == null || apiUserId <= 0) {
      return SavedCartResult(savedCart: snapshot);
    }

    try {
      final Object? response = await _apiClient.post(
        ApiPaths.carts,
        data: <String, Object?>{
          'userId': apiUserId,
          'date': snapshot.createdAt.toIso8601String().split('T').first,
          'products': snapshot.lines
              .map((CartLine line) => <String, Object?>{
                    'productId': line.product.id,
                    'quantity': line.quantity,
                  })
              .toList(),
        },
      );
      final int remoteId = intValue(mapValue(response)['id']);
      final SavedCart updated = remoteId > 0
          ? snapshot.copyWith(simulatedRemoteId: remoteId)
          : snapshot;
      if (remoteId > 0) {
        final List<SavedCart> updatedAll = all
            .map((SavedCart item) => item.id == snapshot.id ? updated : item)
            .toList(growable: false);
        await _writeSaved(updatedAll);
      }
      return SavedCartResult(
        savedCart: updated,
        syncNotice: 'Saved locally. The API also returned a simulated cart response.',
      );
    } on Failure {
      return SavedCartResult(
        savedCart: snapshot,
        syncNotice: 'Saved locally. The optional API demonstration could not be reached.',
      );
    }
  }

  @override
  Future<void> deleteSaved(String savedCartId) async {
    final List<SavedCart> updated = _allSaved()
        .where((SavedCart cart) => cart.id != savedCartId)
        .toList(growable: false);
    await _writeSaved(updated);
  }

  @override
  Future<List<Cart>> loadRemoteHistory(int userId) async {
    final Object? response = await _apiClient.get(ApiPaths.cartsByUser(userId));
    return listValue(response)
        .map(Cart.fromJson)
        .where((Cart cart) => cart.id > 0)
        .toList(growable: false);
  }

  Map<String, Object?> _currentCartMap() {
    final Object? raw =
        _localStore.readApp<Object?>(StorageKeys.currentCarts);
    return Map<String, Object?>.from(mapValue(raw));
  }

  List<SavedCart> _allSaved() {
    final Object? raw = _localStore.readApp<Object?>(StorageKeys.savedCarts);
    return listValue(raw)
        .map(SavedCart.fromJson)
        .where((SavedCart cart) => cart.id.isNotEmpty && cart.ownerKey.isNotEmpty)
        .toList(growable: false);
  }

  Future<void> _writeSaved(List<SavedCart> carts) {
    return _localStore.writeApp(
      StorageKeys.savedCarts,
      carts.map((SavedCart cart) => cart.toJson()).toList(),
    );
  }
}
