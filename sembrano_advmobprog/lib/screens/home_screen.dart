import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../constants.dart';
import '../services/user_service.dart';
import '../widgets/custom_text.dart';
import 'cart_screen.dart';
import 'product_screen.dart';
import 'profile_screen.dart';

// Main Home Screen managing bottom navigation and tab pages
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.username = ''});

  final String username;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();
  String _userFirstName = '';

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  // Load user information to display user first name on profile header
  Future<void> _loadUser() async {
    final userData = await UserService().getUserData();
    if (mounted && userData['firstName'] != null && (userData['firstName'] as String).isNotEmpty) {
      setState(() {
        _userFirstName = userData['firstName'] as String;
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isProfileTab = _selectedIndex == 2;

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          elevation: isProfileTab ? 0 : 2,
          backgroundColor: isProfileTab ? const Color(0xFF2B3A8F) : null,
          foregroundColor: isProfileTab ? Colors.white : null,
          title: _selectedIndex == 0
              ? Image.asset('assets/images/nubdexchange_logo.png', height: 36.h)
              : CustomText(
                  text: _pageTitle,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w600,
                  color: isProfileTab ? Colors.white : null,
                ),
          actions: [
            IconButton(
              key: const Key('settingsButton'),
              icon: Icon(Icons.settings, size: 24.sp, color: isProfileTab ? Colors.white : null),
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
          children: const [
            // Tab 0: Product Catalog Screen
            ProductScreen(),
            // Tab 1: Cart Screen
            CartScreen(),
            // Tab 2: Profile Screen
            ProfileScreen(),
          ],
        ),
        // Floating action button matching sample output
        floatingActionButton: FloatingActionButton(
          onPressed: () {},
          backgroundColor: const Color(0xFFFBB03B),
          foregroundColor: Colors.black,
          shape: const CircleBorder(),
          elevation: 4,
          child: Icon(Icons.comment, size: 24.sp),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        // Bottom navigation bar (Shop, Cart, Profile) matching sample output
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: const Color(0x14000000),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            backgroundColor: Colors.white,
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            showSelectedLabels: false,
            showUnselectedLabels: false,
            selectedItemColor: const Color(0xFF2B3A8F),
            unselectedItemColor: const Color(0xFF757575),
            iconSize: 26.sp,
            onTap: _openPage,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.shopping_bag),
                label: 'Shop',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.shopping_cart),
                label: 'Cart',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _pageTitle {
    return switch (_selectedIndex) {
      1 => 'Cart',
      2 => _userFirstName.isNotEmpty ? _userFirstName : 'Profile',
      _ => AppConstants.appName,
    };
  }

  void _openPage(int index) {
    setState(() => _selectedIndex = index);
    _pageController.jumpToPage(index);
  }
}
