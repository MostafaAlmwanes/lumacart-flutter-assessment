abstract class ApiPaths {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://fakestoreapi.com',
  );

  static const String login = '/auth/login';
  static const String products = '/products';
  static const String categories = '/products/categories';
  static const String users = '/users';
  static const String carts = '/carts';

  static String product(int id) => '$products/$id';
  static String productsByCategory(String category) =>
      '$products/category/${Uri.encodeComponent(category)}';
  static String user(int id) => '$users/$id';
  static String cartsByUser(int userId) => '$carts/user/$userId';
}
