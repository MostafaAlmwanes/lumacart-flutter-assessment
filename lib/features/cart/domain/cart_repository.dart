import 'package:lumacart/features/cart/domain/cart_models.dart';

abstract class CartRepository {
  Future<LocalCart> loadCurrent(String ownerKey);

  Future<void> saveCurrent(LocalCart cart);

  Future<List<SavedCart>> loadSaved(String ownerKey);

  Future<SavedCartResult> saveSnapshot({
    required LocalCart cart,
    required String name,
    int? apiUserId,
  });

  Future<void> deleteSaved(String savedCartId);

  Future<List<Cart>> loadRemoteHistory(int userId);
}
