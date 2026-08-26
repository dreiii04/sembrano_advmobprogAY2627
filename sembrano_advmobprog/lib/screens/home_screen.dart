import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../constants.dart';
import '../widgets/custom_text.dart';
import 'cart_screen.dart';
import 'product_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.username = ''});

  final String username;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  int _selectedTab = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          elevation: 2,
          title: _selectedIndex == 0
              ? Image.asset('assets/images/nubdexchange_logo.png', height: 36.h)
              : CustomText(
                  text: _pageTitle,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w600,
                ),
          actions: [
            IconButton(
              key: const Key('settingsButton'),
              icon: Icon(Icons.settings, size: 24.sp),
              tooltip: 'Settings',
              onPressed: () =>
                  Navigator.pushNamed(context, AppConstants.settingsRoute),
            ),
          ],
        ),
        body: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          onPageChanged: (page) => setState(() => _selectedIndex = page),
          children: [
            const ProductScreen(),
            const _PlaceholderPage(
              icon: Icons.chat_bubble_outline,
              label: 'Chat',
            ),
            _PlaceholderPage(
              icon: Icons.person_outline,
              label: widget.username.isEmpty ? 'Profile' : widget.username,
            ),
            const CartScreen(),
          ],
        ),
        // Enhancement 2: Hide the cart button while the cart is open.
        floatingActionButton: _selectedIndex == 3
            ? null
            : FloatingActionButton(
                onPressed: () => _openPage(3),
                tooltip: 'Cart',
                child: const Icon(Icons.shopping_cart),
              ),
        // Enhancement 2: Use a floating cart button above the bottom menu.
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedTab,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          onTap: _openPage,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.shop_2), label: 'Shop'),
            BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }

  String get _pageTitle {
    return switch (_selectedIndex) {
      1 => 'Chat',
      2 => 'Profile',
      3 => 'Cart',
      _ => AppConstants.appName,
    };
  }

  void _openPage(int index) {
    setState(() {
      _selectedIndex = index;
      if (index < 3) _selectedTab = index;
    });
    _pageController.jumpToPage(index);
  }
}

class _PlaceholderPage extends StatelessWidget {
  const _PlaceholderPage({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48.sp),
          SizedBox(height: 12.h),
          CustomText(text: label, fontSize: 18.sp),
        ],
      ),
    );
  }
}
