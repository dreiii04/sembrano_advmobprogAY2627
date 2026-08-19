import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants.dart';
import '../models/product.dart';

class ProductService {
  const ProductService();

  Future<List<Product>> getAllProducts() async {
    final response = await http.get(Uri.parse('$host/products'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final productsJson = data['products'] as List? ?? const [];

      return productsJson
          .whereType<Map<String, dynamic>>()
          .map(Product.fromJson)
          .toList();
    }

    throw Exception('Failed to load products');
  }
}
