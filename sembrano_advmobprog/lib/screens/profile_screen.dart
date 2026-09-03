import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../constants.dart';
import '../models/user.dart';
import '../services/user_service.dart';
import '../widgets/custom_text.dart';

//Profile screen rendering user data from user.dart model
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();
  User? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    //Fetch saved user data on screen initialization
    _loadUser();
  }

  //Load user model from SharedPreferences using UserService
  Future<void> _loadUser() async {
    setState(() => _isLoading = true);
    final user = await _userService.getUser();
    if (mounted) {
      setState(() {
        _user = user;
        _isLoading = false;
      });
    }
  }

  //Log out the user and return to sign in screen
  Future<void> _logout() async {
    await _userService.logout();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppConstants.signinRoute,
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_user == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CustomText(text: 'No user data found.', fontSize: 16),
            SizedBox(height: 12.h),
            ElevatedButton(
              onPressed: _logout,
              child: const Text('Go to Login'),
            ),
          ],
        ),
      );
    }

    final fullName = '${_user!.firstName} ${_user!.lastName}'.trim();
    final displayName = fullName.isEmpty ? _user!.username : fullName;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        child: Column(
          children: [
            
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 24.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0x0A000000),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 38.r,
                    backgroundColor: Colors.grey.shade100,
                    backgroundImage: _user!.image.isNotEmpty
                        ? NetworkImage(_user!.image)
                        : null,
                    child: _user!.image.isEmpty
                        ? Icon(Icons.person, size: 38.sp, color: Colors.grey)
                        : null,
                  ),
                  SizedBox(height: 12.h),
                  CustomText(
                    text: displayName,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  SizedBox(height: 4.h),
                  CustomText(
                    text: '@${_user!.username}',
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFE5A823),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0x0A000000),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _ProfileDetailRow(
                    icon: Icons.mail_outline,
                    label: 'Email',
                    value: _user!.email,
                  ),
                  const Divider(height: 1),
                  _ProfileDetailRow(
                    icon: Icons.people_outline,
                    label: 'Gender',
                    value: _user!.gender,
                  ),
                  const Divider(height: 1),
                  _ProfileDetailRow(
                    icon: Icons.badge_outlined,
                    label: 'User ID',
                    value: '#${_user!.id}',
                  ),
                ],
              ),
            ),
            SizedBox(height: 24.h),

            SizedBox(
              width: double.infinity,
              height: 46.h,
              child: ElevatedButton.icon(
                onPressed: _logout,
                icon: Icon(Icons.logout, size: 18.sp, color: Colors.white),
                label: const CustomText(
                  text: 'Log Out',
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF574D),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileDetailRow extends StatelessWidget {
  const _ProfileDetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Row(
        children: [
          Icon(icon, size: 20.sp, color: const Color(0xFFE5A823)),
          SizedBox(width: 12.w),
          CustomText(
            text: label,
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
          ),
          const Spacer(),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13.sp,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
