import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../constants.dart';
import '../models/cart.dart';
import '../models/product.dart';
import '../services/cart_service.dart';
import '../services/user_service.dart';
import '../widgets/custom_text.dart';

// Product detail screen displaying item details and add-to-cart option
class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({required Product product, Key? key})
    : this._(product: product, key: key);

  const ProductDetailScreen.fromCartProduct({
    required CartProduct product,
    Key? key,
  }) : this._(cartProduct: product, key: key);

  const ProductDetailScreen._({this.product, this.cartProduct, super.key});

  final Product? product;
  final CartProduct? cartProduct;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  bool _isAdding = false;

  int get _id => widget.product?.id ?? widget.cartProduct!.id;
  String get _title => widget.product?.title ?? widget.cartProduct!.title;
  double get _price => widget.product?.price ?? widget.cartProduct!.price;
  String get _thumbnail =>
      widget.product?.thumbnail ?? widget.cartProduct!.thumbnail;

  // Process to add the current product to the user's cart
  Future<void> _addToCart() async {
    setState(() => _isAdding = true);

    try {
      // Enhancement 3: Use saved user ID for cart addition
      final userData = await UserService().getUserData();
      final userId = userData['id'] as int? ?? AppConstants.cartUserId;

      await const CartService().addToCart(
        userId: userId > 0 ? userId : AppConstants.cartUserId,
        productId: _id,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Product added to cart.')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not add the product.')),
      );
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Product details')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 320.h,
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Image.network(
                _thumbnail,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) =>
                    Icon(Icons.image_not_supported_outlined, size: 72.sp),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(20.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.product != null) ...[
                    Chip(label: Text(widget.product!.category)),
                    SizedBox(height: 12.h),
                  ],
                  CustomText(
                    text: _title,
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  SizedBox(height: 8.h),
                  CustomText(
                    text: '\$${_price.toStringAsFixed(2)}',
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  SizedBox(height: 16.h),
                  if (widget.product != null) ...[
                    CustomText(
                      text: widget.product!.description,
                      fontSize: 14.sp,
                    ),
                    SizedBox(height: 16.h),
                    CustomText(
                      text:
                          'Rating: ${widget.product!.rating.toStringAsFixed(1)} '
                          '| Stock: ${widget.product!.stock}',
                      fontSize: 13.sp,
                    ),
                  ] else ...[
                    CustomText(
                      text: 'Quantity: ${widget.cartProduct!.quantity}',
                      fontSize: 14.sp,
                    ),
                    SizedBox(height: 8.h),
                    CustomText(
                      text:
                          'Discounted total: '
                          '\$${widget.cartProduct!.discountedTotal.toStringAsFixed(2)}',
                      fontSize: 14.sp,
                    ),
                  ],
                  SizedBox(height: 24.h),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _isAdding ? null : _addToCart,
                      icon: _isAdding
                          ? SizedBox.square(
                              dimension: 18.r,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.add_shopping_cart),
                      label: Text(_isAdding ? 'Adding...' : 'Add to cart'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

