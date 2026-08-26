import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../constants.dart';
import '../models/cart.dart';
import '../services/cart_service.dart';
import '../widgets/custom_text.dart';
import 'product_detail_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late Future<Cart?> _cartFuture;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  void _loadCart() {
    _cartFuture = const CartService().getCartByUser(AppConstants.cartUserId);
  }

  Future<void> _refreshCart() async {
    setState(_loadCart);
    await _cartFuture;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<Cart?>(
        future: _cartFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomText(text: 'Could not load the cart.', fontSize: 14.sp),
                  SizedBox(height: 8.h),
                  ElevatedButton(
                    onPressed: () => setState(_loadCart),
                    child: const Text('Try again'),
                  ),
                ],
              ),
            );
          }

          final cart = snapshot.data;
          if (cart == null || cart.products.isEmpty) {
            return const Center(child: Text('The cart is empty.'));
          }

          return RefreshIndicator(
            onRefresh: _refreshCart,
            child: ListView.separated(
              padding: EdgeInsets.all(16.r),
              itemCount: cart.products.length + 1,
              separatorBuilder: (_, _) => SizedBox(height: 10.h),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _CartSummary(cart: cart);
                }

                final product = cart.products[index - 1];

                // Enhancement 1: A cart item opens the same details screen.
                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => ProductDetailScreen.fromCartProduct(
                          product: product,
                        ),
                      ),
                    ),
                    leading: Image.network(
                      product.thumbnail,
                      width: 56.w,
                      height: 56.h,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Icon(Icons.image),
                    ),
                    title: Text(
                      product.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      'Quantity: ${product.quantity}\n'
                      '\$${product.discountedTotal.toStringAsFixed(2)}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _CartSummary extends StatelessWidget {
  const _CartSummary({required this.cart});

  final Cart cart;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${cart.totalQuantity} items'),
            Text(
              'Total: \$${cart.discountedTotal.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
