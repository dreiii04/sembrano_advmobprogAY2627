import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants.dart';
import '../models/cart.dart';

class CartService {
  const CartService();

  // Enhancement 3: Get the cart that belongs to one user.
  Future<Cart?> getCartByUser(int userId) async {
    final response = await http.get(Uri.parse('$host/carts/user/$userId'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final cartsJson = data['carts'] as List? ?? const [];
      final carts = cartsJson.whereType<Map<String, dynamic>>();
      if (carts.isEmpty) return null;

      return Cart.fromJson(carts.first);
    }

    throw Exception('Failed to load cart');
  }

  // Enhancement 3: Send the chosen product to the add cart endpoint.
  Future<Cart> addToCart({
    required int userId,
    required int productId,
    int quantity = 1,
  }) async {
    final response = await http.post(
      Uri.parse('$host/carts/add'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userId,
        'products': [
          {'id': productId, 'quantity': quantity},
        ],
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Cart.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }

    throw Exception('Failed to add product to cart');
  }
}
