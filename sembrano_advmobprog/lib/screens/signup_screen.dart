import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants.dart';
import '../services/user_service.dart';
import '../widgets/custom_text.dart';

//This is the signup screen UI where new users can register their account
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for each required field based on dummyjson user schema
  final _fNameController = TextEditingController();
  final _lNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _contactNoController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _fNameController.dispose();
    _lNameController.dispose();
    _ageController.dispose();
    _contactNoController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  //  Signs up the user in Firebase Auth and saves their extra profile info locally
  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userService = UserService();

      // Create account in Firebase using email and password
      await userService.createAccount(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Set the username as the Firebase display name
      await userService.updateUsername(newUsername: _usernameController.text.trim());

      // Save the other user details into SharedPreferences so they can be shown on the profile screen
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('loginType', 'firebase');
      await prefs.setString('firstName', _fNameController.text.trim());
      await prefs.setString('lastName', _lNameController.text.trim());
      await prefs.setString('username', _usernameController.text.trim());
      await prefs.setString('email', _emailController.text.trim());
      await prefs.setString('contactNo', _contactNoController.text.trim());
      await prefs.setInt('age', int.tryParse(_ageController.text.trim()) ?? 0);

      if (!mounted) return;
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account created successfully!')),
      );

      // Navigate to splash screen to verify session and enter the app
      Navigator.pushReplacementNamed(context, AppConstants.splashRoute);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Registration failed')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign up failed: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Create Account'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2B3A8F),
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  CustomText(
                    text: 'Join NUBD Exchange',
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  SizedBox(height: 6.h),
                  CustomText(
                    text: 'Please fill out your details to get started',
                    fontSize: 13.sp,
                    color: Colors.grey.shade600,
                  ),
                  SizedBox(height: 24.h),

                  // First Name & Last Name
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _fNameController,
                          decoration: InputDecoration(
                            labelText: 'First Name',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
                          ),
                          validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: TextFormField(
                          controller: _lNameController,
                          decoration: InputDecoration(
                            labelText: 'Last Name',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
                          ),
                          validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 14.h),

                  // Age & Contact Number
                  Row(
                    children: [
                      SizedBox(
                        width: 100.w,
                        child: TextFormField(
                          controller: _ageController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Age',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) return 'Required';
                            if (int.tryParse(value.trim()) == null) return 'Invalid';
                            return null;
                          },
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: TextFormField(
                          controller: _contactNoController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: 'Contact No',
                            hintText: '09xxxxxxxxx',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
                          ),
                          validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 14.h),

                  // Username
                  TextFormField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: 'Username',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty ? 'Please enter a username' : null,
                  ),
                  SizedBox(height: 14.h),

                  // Email Address
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return 'Please enter your email';
                      if (!value.contains('@') || !value.contains('.')) return 'Please enter a valid email';
                      return null;
                    },
                  ),
                  SizedBox(height: 14.h),

                  // Password with minimum 6 characters validation for Firebase Auth
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Please enter a password';
                      if (value.length < 6) return 'Password must be at least 6 characters';
                      return null;
                    },
                  ),
                  SizedBox(height: 24.h),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 48.h,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _signUp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2B3A8F),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                      ),
                      child: _isLoading
                          ? SizedBox(
                              height: 20.h,
                              width: 20.h,
                              child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : CustomText(
                              text: 'Sign Up',
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                            ),
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // Navigation back to Sign In
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Already have an account? '),
                      TextButton(
                        onPressed: () => Navigator.pushReplacementNamed(context, AppConstants.signinRoute),
                        child: const Text('Sign In', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

