import 'package:equatable/equatable.dart';
import 'package:lumacart/core/utils/json_parsing.dart';
import 'package:lumacart/core/utils/money.dart';

class Rating extends Equatable {
  const Rating({required this.rate, required this.count});

  factory Rating.fromJson(Object? json) {
    final Map<String, Object?> map = mapValue(json);
    return Rating(
      rate: doubleValue(map['rate']).clamp(0, 5).toDouble(),
      count: intValue(map['count']).clamp(0, 1 << 31).toInt(),
    );
  }

  static const Rating empty = Rating(rate: 0, count: 0);

  final double rate;
  final int count;

  Map<String, Object?> toJson() => <String, Object?>{
        'rate': rate,
        'count': count,
      };

  @override
  List<Object?> get props => <Object?>[rate, count];
}

class Product extends Equatable {
  const Product({
    required this.id,
    required this.title,
    required this.price,
    required this.description,
    required this.category,
    required this.imageUrl,
    required this.rating,
  });

  factory Product.fromJson(Object? json) {
    final Map<String, Object?> map = mapValue(json);
    final double parsedPrice = doubleValue(map['price']);
    return Product(
      id: intValue(map['id']),
      title: stringValue(map['title'], fallback: 'Untitled product'),
      price: parsedPrice < 0 ? 0.0 : parsedPrice,
      description: stringValue(map['description']),
      category: stringValue(map['category'], fallback: 'Other'),
      imageUrl: stringValue(map['image']),
      rating: Rating.fromJson(map['rating']),
    );
  }

  final int id;
  final String title;
  final double price;
  final String description;
  final String category;
  final String imageUrl;
  final Rating rating;

  int get priceCents => Money.centsFromDouble(price);

  bool get isUsable => id > 0 && title.isNotEmpty;

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'title': title,
        'price': price,
        'description': description,
        'category': category,
        'image': imageUrl,
        'rating': rating.toJson(),
      };

  @override
  List<Object?> get props => <Object?>[
        id,
        title,
        price,
        description,
        category,
        imageUrl,
        rating,
      ];
}
