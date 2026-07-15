import 'package:equatable/equatable.dart';
import 'package:lumacart/core/utils/json_parsing.dart';
import 'package:lumacart/features/products/domain/product.dart';

class CartProductItem extends Equatable {
  const CartProductItem({required this.productId, required this.quantity});

  factory CartProductItem.fromJson(Object? json) {
    final Map<String, Object?> map = mapValue(json);
    return CartProductItem(
      productId: intValue(map['productId']),
      quantity: intValue(map['quantity'], fallback: 1),
    );
  }

  final int productId;
  final int quantity;

  Map<String, Object?> toJson() => <String, Object?>{
        'productId': productId,
        'quantity': quantity,
      };

  @override
  List<Object?> get props => <Object?>[productId, quantity];
}

class Cart extends Equatable {
  const Cart({
    required this.id,
    required this.userId,
    required this.date,
    required this.products,
  });

  factory Cart.fromJson(Object? json) {
    final Map<String, Object?> map = mapValue(json);
    return Cart(
      id: intValue(map['id']),
      userId: intValue(map['userId']),
      date: DateTime.tryParse(stringValue(map['date'])) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      products: listValue(map['products'])
          .map(CartProductItem.fromJson)
          .where((CartProductItem item) =>
              item.productId > 0 && item.quantity > 0)
          .toList(growable: false),
    );
  }

  final int id;
  final int userId;
  final DateTime date;
  final List<CartProductItem> products;

  @override
  List<Object?> get props => <Object?>[id, userId, date, products];
}

class CartLine extends Equatable {
  const CartLine({required this.product, required this.quantity});

  factory CartLine.fromJson(Object? json) {
    final Map<String, Object?> map = mapValue(json);
    return CartLine(
      product: Product.fromJson(map['product']),
      quantity: intValue(map['quantity'], fallback: 1).clamp(1, 99).toInt(),
    );
  }

  final Product product;
  final int quantity;

  int get lineTotalCents => product.priceCents * quantity;

  CartLine copyWith({int? quantity}) => CartLine(
        product: product,
        quantity: quantity ?? this.quantity,
      );

  Map<String, Object?> toJson() => <String, Object?>{
        'product': product.toJson(),
        'quantity': quantity,
      };

  @override
  List<Object?> get props => <Object?>[product, quantity];
}

class LocalCart extends Equatable {
  const LocalCart({
    required this.ownerKey,
    required this.lines,
    required this.updatedAt,
  });

  factory LocalCart.empty(String ownerKey) => LocalCart(
        ownerKey: ownerKey,
        lines: const <CartLine>[],
        updatedAt: DateTime.now().toUtc(),
      );

  factory LocalCart.fromJson(Object? json) {
    final Map<String, Object?> map = mapValue(json);
    return LocalCart(
      ownerKey: stringValue(map['ownerKey']),
      lines: listValue(map['lines'])
          .map(CartLine.fromJson)
          .where((CartLine line) => line.product.isUsable)
          .toList(growable: false),
      updatedAt: DateTime.tryParse(stringValue(map['updatedAt'])) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  final String ownerKey;
  final List<CartLine> lines;
  final DateTime updatedAt;

  bool get isEmpty => lines.isEmpty;
  int get itemCount =>
      lines.fold<int>(0, (int total, CartLine line) => total + line.quantity);
  int get subtotalCents => lines.fold<int>(
        0,
        (int total, CartLine line) => total + line.lineTotalCents,
      );
  int get grandTotalCents => subtotalCents;

  LocalCart copyWith({List<CartLine>? lines, DateTime? updatedAt}) => LocalCart(
        ownerKey: ownerKey,
        lines: lines ?? this.lines,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, Object?> toJson() => <String, Object?>{
        'ownerKey': ownerKey,
        'lines': lines.map((CartLine line) => line.toJson()).toList(),
        'updatedAt': updatedAt.toUtc().toIso8601String(),
      };

  @override
  List<Object?> get props => <Object?>[ownerKey, lines, updatedAt];
}

class SavedCart extends Equatable {
  const SavedCart({
    required this.id,
    required this.ownerKey,
    required this.name,
    required this.lines,
    required this.createdAt,
    this.simulatedRemoteId,
  });

  factory SavedCart.fromJson(Object? json) {
    final Map<String, Object?> map = mapValue(json);
    return SavedCart(
      id: stringValue(map['id']),
      ownerKey: stringValue(map['ownerKey']),
      name: stringValue(map['name'], fallback: 'Saved cart'),
      lines: listValue(map['lines'])
          .map(CartLine.fromJson)
          .where((CartLine line) => line.product.isUsable)
          .toList(growable: false),
      createdAt: DateTime.tryParse(stringValue(map['createdAt'])) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      simulatedRemoteId: map['simulatedRemoteId'] == null
          ? null
          : intValue(map['simulatedRemoteId']),
    );
  }

  final String id;
  final String ownerKey;
  final String name;
  final List<CartLine> lines;
  final DateTime createdAt;
  final int? simulatedRemoteId;

  int get itemCount =>
      lines.fold<int>(0, (int total, CartLine line) => total + line.quantity);
  int get totalCents => lines.fold<int>(
        0,
        (int total, CartLine line) => total + line.lineTotalCents,
      );

  SavedCart copyWith({int? simulatedRemoteId}) => SavedCart(
        id: id,
        ownerKey: ownerKey,
        name: name,
        lines: lines,
        createdAt: createdAt,
        simulatedRemoteId: simulatedRemoteId ?? this.simulatedRemoteId,
      );

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'ownerKey': ownerKey,
        'name': name,
        'lines': lines.map((CartLine line) => line.toJson()).toList(),
        'createdAt': createdAt.toUtc().toIso8601String(),
        'simulatedRemoteId': simulatedRemoteId,
      };

  @override
  List<Object?> get props => <Object?>[
        id,
        ownerKey,
        name,
        lines,
        createdAt,
        simulatedRemoteId,
      ];
}

enum RestoreMode { replace, merge }

class SavedCartResult extends Equatable {
  const SavedCartResult({required this.savedCart, this.syncNotice});

  final SavedCart savedCart;
  final String? syncNotice;

  @override
  List<Object?> get props => <Object?>[savedCart, syncNotice];
}
