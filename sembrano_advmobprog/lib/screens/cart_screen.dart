import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../constants.dart';
import '../models/cart.dart';
import '../services/cart_service.dart';
import '../services/user_service.dart';
import '../widgets/custom_text.dart';
import 'detail_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  Cart? _cart;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  // Enhancement 3: Based on the saved user data render the cart by userId
  Future<void> _loadCart() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final cart = await _fetchCartBySavedUser();
      if (mounted) {
        setState(() {
          _cart = cart;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  // Enhancement 3: Fetch cart for the saved user
  Future<Cart?> _fetchCartBySavedUser() async {
    final userData = await UserService().getUserData();
    final userId = userData['id'] as int? ?? 0;
    return const CartService().getCartByUser(userId > 0 ? userId : AppConstants.cartUserId);
  }

  // Increase the quantity of an item in the cart
  void _increaseQuantity(int index) {
    if (_cart == null) return;
    final products = List<CartProduct>.from(_cart!.products);
    final item = products[index];
    final newQty = item.quantity + 1;
    final unitPrice = item.price;
    final newTotal = unitPrice * newQty;
    final discountedUnit = item.discountedTotal / (item.quantity > 0 ? item.quantity : 1);
    final newDiscountedTotal = discountedUnit * newQty;

    products[index] = item.copyWith(
      quantity: newQty,
      total: newTotal,
      discountedTotal: newDiscountedTotal,
    );

    _updateCartTotals(products);
  }

  // Reduce the quantity of an item in the cart, or remove if quantity is 1
  void _reduceQuantity(int index) {
    if (_cart == null) return;
    final products = List<CartProduct>.from(_cart!.products);
    final item = products[index];

    if (item.quantity > 1) {
      final newQty = item.quantity - 1;
      final unitPrice = item.price;
      final newTotal = unitPrice * newQty;
      final discountedUnit = item.discountedTotal / item.quantity;
      final newDiscountedTotal = discountedUnit * newQty;

      products[index] = item.copyWith(
        quantity: newQty,
        total: newTotal,
        discountedTotal: newDiscountedTotal,
      );

      _updateCartTotals(products);
    } else {
      _confirmRemoveItem(index);
    }
  }

  // Confirm removal of item when reduced to 0
  void _confirmRemoveItem(int index) {
    if (_cart == null) return;
    final item = _cart!.products[index];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Item'),
        content: Text('Remove "${item.title}" from your cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              final products = List<CartProduct>.from(_cart!.products);
              final removed = products.removeAt(index);
              _updateCartTotals(products);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${removed.title} removed from cart'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  // Recalculates total items, total price, and discounted total for the cart
  void _updateCartTotals(List<CartProduct> products) {
    int totalQty = 0;
    double total = 0.0;
    double discountedTotal = 0.0;

    for (final p in products) {
      totalQty += p.quantity;
      total += p.total;
      discountedTotal += p.discountedTotal;
    }

    setState(() {
      _cart = _cart!.copyWith(
        products: products,
        totalQuantity: totalQty,
        totalProducts: products.length,
        total: total,
        discountedTotal: discountedTotal,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomText(text: 'Could not load the cart.', fontSize: 14.sp),
            SizedBox(height: 8.h),
            ElevatedButton(
              onPressed: _loadCart,
              child: const Text('Try again'),
            ),
          ],
        ),
      );
    }

    if (_cart == null || _cart!.products.isEmpty) {
      return const Center(child: Text('The cart is empty.'));
    }

    return RefreshIndicator(
      onRefresh: _loadCart,
      child: ListView.separated(
        padding: EdgeInsets.all(16.r),
        itemCount: _cart!.products.length + 1,
        separatorBuilder: (_, _) => SizedBox(height: 10.h),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _CartSummary(cart: _cart!);
          }

          final productIndex = index - 1;
          final product = _cart!.products[productIndex];

          return Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Padding(
              padding: EdgeInsets.all(12.r),
              child: Row(
                children: [
                  // Product Thumbnail with tap to view details
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => ProductDetailScreen.fromCartProduct(
                          product: product,
                        ),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8.r),
                      child: Image.network(
                        product.thumbnail,
                        width: 60.w,
                        height: 60.h,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const Icon(Icons.shopping_bag),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),

                  // Product Details (Title, Price)
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => ProductDetailScreen.fromCartProduct(
                            product: product,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            '\$${product.discountedTotal.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: const Color(0xFF2B3A8F),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Add and Reduce Quantity Controls
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          iconSize: 18.sp,
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(minWidth: 32.w, minHeight: 32.h),
                          onPressed: () => _reduceQuantity(productIndex),
                          tooltip: 'Reduce',
                        ),
                        Text(
                          '${product.quantity}',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          iconSize: 18.sp,
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(minWidth: 32.w, minHeight: 32.h),
                          onPressed: () => _increaseQuantity(productIndex),
                          tooltip: 'Add',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${cart.totalQuantity} items',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              'Total: \$${cart.discountedTotal.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
