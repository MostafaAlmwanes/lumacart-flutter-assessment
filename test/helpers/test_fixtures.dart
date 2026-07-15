import 'package:lumacart/features/auth/domain/auth_models.dart';
import 'package:lumacart/features/cart/domain/cart_models.dart';
import 'package:lumacart/features/products/domain/product.dart';

const Product testProduct = Product(
  id: 1,
  title: 'Test backpack',
  price: 19.99,
  description: 'A useful test product.',
  category: 'bags',
  imageUrl: '',
  rating: Rating(rate: 4.5, count: 12),
);

const Product secondProduct = Product(
  id: 2,
  title: 'Test jacket',
  price: 25.50,
  description: 'Another useful test product.',
  category: 'clothing',
  imageUrl: '',
  rating: Rating(rate: 3.8, count: 8),
);

const StoreUser testUser = StoreUser(
  id: 7,
  email: 'user@example.com',
  username: 'test_user',
  name: UserName(firstName: 'Test', lastName: 'User'),
  address: Address(
    city: 'Amsterdam',
    street: 'Teststraat',
    number: 12,
    zipCode: '1000 AA',
    geoLocation: GeoLocation(latitude: '0', longitude: '0'),
  ),
  phone: '+31 20 123 4567',
);

final AuthSession testSession = AuthSession(
  accountKey: 'api:7',
  user: testUser,
  accountType: AccountType.api,
  signedInAt: DateTime.utc(2026, 7, 13),
  token: const AuthToken('token'),
);

LocalCart testCart({String ownerKey = 'api:7'}) => LocalCart(
      ownerKey: ownerKey,
      lines: const <CartLine>[
        CartLine(product: testProduct, quantity: 2),
      ],
      updatedAt: DateTime.utc(2026, 7, 13),
    );
