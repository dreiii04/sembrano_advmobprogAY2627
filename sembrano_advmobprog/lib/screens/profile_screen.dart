import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../constants.dart';
import '../services/user_service.dart';
import '../widgets/custom_text.dart';

//  Profile screen that displays user details based on their LoginType and provides account management
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();
  Map<String, dynamic> _userData = {};
  String _loginType = 'dummyjson';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    //  When the screen opens, we fetch the saved user data and the login type
    _loadUser();
  }

  //  Helper function that gets the current user's profile and checks if they used DummyJSON or Firebase
  Future<void> _loadUser() async {
    setState(() => _isLoading = true);
    final data = await _userService.getUserData();
    final type = await _userService.getLoginType();
    if (mounted) {
      setState(() {
        _userData = data;
        _loginType = type;
        _isLoading = false;
      });
    }
  }

  // Logs out the user from Firebase and local storage, then redirects to the sign in screen
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

  // Opens a dialog so the user can type a new username and updates it via UserService
  Future<void> _showUpdateUsernameDialog() async {
    final controller = TextEditingController(text: _userData['username'] ?? '');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Update Username'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'New Username',
            hintText: 'Enter new username',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2B3A8F),
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (confirmed == true && controller.text.trim().isNotEmpty) {
      try {
        await _userService.updateUsername(newUsername: controller.text.trim());
        await _loadUser();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Username updated successfully!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update username: $e')),
          );
        }
      }
    }
  }

  //Opens a dialog asking for the current and new passwords to reset password in Firebase
  Future<void> _showChangePasswordDialog() async {
    final currentPassController = TextEditingController();
    final newPassController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPassController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Current Password'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPassController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New Password (min. 6 chars)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2B3A8F),
              foregroundColor: Colors.white,
            ),
            child: const Text('Update'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (currentPassController.text.isEmpty || newPassController.text.length < 6) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('New password must be at least 6 characters')),
          );
        }
        return;
      }

      try {
        await _userService.resetPasswordFromCurrentPassword(
          currentPassword: currentPassController.text,
          newPassword: newPassController.text,
          email: _userData['email'] ?? '',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Password updated successfully!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to change password: $e')),
          );
        }
      }
    }
  }

  // Confirms with the user and deletes their Firebase account permanently
  Future<void> _showDeleteAccountDialog() async {
    final passController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure? This action is permanent and cannot be undone.'),
            const SizedBox(height: 12),
            TextField(
              controller: passController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Confirm Password'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && passController.text.isNotEmpty) {
      try {
        await _userService.deleteAccount(
          email: _userData['email'] ?? '',
          password: passController.text,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account deleted successfully')),
          );
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppConstants.signinRoute,
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete account: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final isFirebase = _loginType == 'firebase';
    final firstName = _userData['firstName'] as String? ?? '';
    final lastName = _userData['lastName'] as String? ?? '';
    final username = _userData['username'] as String? ?? 'User';
    final email = _userData['email'] as String? ?? '';
    final image = _userData['image'] as String? ?? '';
    final contactNo = _userData['contactNo'] as String? ?? '';
    final age = _userData['age']?.toString() ?? '';
    final gender = _userData['gender'] as String? ?? '';
    final id = _userData['id']?.toString() ?? '';
    final firebaseUid = _userService.currentUser?.uid ?? '';

    final fullName = '$firstName $lastName'.trim();
    final displayName = fullName.isNotEmpty ? fullName : username;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        child: Column(
          children: [
            // Header Card with Avatar, Name, Username and LoginType badge
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 20.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 38.r,
                    backgroundColor: Colors.grey.shade100,
                    backgroundImage: image.isNotEmpty ? NetworkImage(image) : null,
                    child: image.isEmpty ? Icon(Icons.person, size: 38.sp, color: Colors.grey) : null,
                  ),
                  SizedBox(height: 10.h),
                  CustomText(
                    text: displayName,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  SizedBox(height: 4.h),
                  CustomText(
                    text: '@$username',
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFE5A823),
                  ),
                  SizedBox(height: 8.h),
                  // Badge showing if the current session is from Firebase or DummyJSON
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: isFirebase ? Colors.green.shade50 : Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: isFirebase ? Colors.green.shade300 : Colors.blue.shade300,
                      ),
                    ),
                    child: Text(
                      isFirebase ? 'Firebase Authentication' : 'DummyJSON Authentication',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: isFirebase ? Colors.green.shade800 : Colors.blue.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            //  Details Card showing specific fields based on the LoginType
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _ProfileDetailRow(
                    icon: Icons.mail_outline,
                    label: 'Email',
                    value: email,
                  ),
                  if (isFirebase) ...[
                    if (contactNo.isNotEmpty) ...[
                      const Divider(height: 1),
                      _ProfileDetailRow(
                        icon: Icons.phone_outlined,
                        label: 'Contact No',
                        value: contactNo,
                      ),
                    ],
                    if (age.isNotEmpty && age != '0') ...[
                      const Divider(height: 1),
                      _ProfileDetailRow(
                        icon: Icons.calendar_today_outlined,
                        label: 'Age',
                        value: age,
                      ),
                    ],
                    const Divider(height: 1),
                    _ProfileDetailRow(
                      icon: Icons.fingerprint,
                      label: 'Firebase UID',
                      value: firebaseUid.length > 12 ? '${firebaseUid.substring(0, 12)}...' : firebaseUid,
                    ),
                  ] else ...[
                    const Divider(height: 1),
                    _ProfileDetailRow(
                      icon: Icons.people_outline,
                      label: 'Gender',
                      value: gender,
                    ),
                    const Divider(height: 1),
                    _ProfileDetailRow(
                      icon: Icons.badge_outlined,
                      label: 'User ID',
                      value: '#$id',
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: 16.h),

            //  Account actions card allowing update username, change password, and delete account
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.edit_outlined, color: Color(0xFF2B3A8F)),
                    title: const Text('Update Username'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _showUpdateUsernameDialog,
                  ),
                  if (isFirebase) ...[
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.lock_reset, color: Color(0xFF2B3A8F)),
                      title: const Text('Change Password'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _showChangePasswordDialog,
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.delete_forever, color: Colors.red),
                      title: const Text('Delete Account', style: TextStyle(color: Colors.red)),
                      trailing: const Icon(Icons.chevron_right, color: Colors.red),
                      onTap: _showDeleteAccountDialog,
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: 20.h),

            // Logout button that clears session/token and redirects to login
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
