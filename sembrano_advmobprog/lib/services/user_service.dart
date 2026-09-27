import 'dart:convert';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import '../models/user.dart' as model;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

ValueNotifier<UserService> userService = ValueNotifier(UserService());

class UserService {
  Map<String, dynamic> data = {};

  Future<Map<String, dynamic>> loginUser(String username, String password) async {
    final response = await post(
      Uri.parse('$host/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
        'expiresInMins': 60,
      }),
    );

    if (response.statusCode == 200) {
      data = jsonDecode(response.body);
      data['loginType'] = 'dummyjson';
      await saveUserData(data);
      return data;
    } else {
      throw Exception(response.body);
    }
  }

  /// **Save User Data to SharedPreferences**
  /// Save user data from API response based on User model
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    final user = model.User.fromJson(userData);

    await prefs.setInt('id', user.id);
    await prefs.setString('username', user.username);
    await prefs.setString('email', user.email);
    await prefs.setString('firstName', user.firstName);
    await prefs.setString('lastName', user.lastName);
    await prefs.setString('gender', user.gender);
    await prefs.setString('image', user.image);
    await prefs.setString('accessToken', user.accessToken);
    await prefs.setString('refreshToken', user.refreshToken);
    await prefs.setString('loginType', userData['loginType'] ?? 'dummyjson');

    if (userData.containsKey('contactNo')) {
      await prefs.setString('contactNo', userData['contactNo'] ?? '');
    }
    if (userData.containsKey('age')) {
      await prefs.setInt('age', userData['age'] is int ? userData['age'] : (int.tryParse(userData['age'].toString()) ?? 0));
    }

    // Support generic token key if present in API response
    if (userData.containsKey('token')) {
      await prefs.setString('token', userData['token'] ?? '');
    } else if (user.accessToken.isNotEmpty) {
      await prefs.setString('token', user.accessToken);
    }
  }

  /// Retrieve user data from SharedPreferences
  Future<Map<String, dynamic>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();

    final loginType = prefs.getString('loginType') ?? (firebaseAuth.currentUser != null ? 'firebase' : 'dummyjson');
    final firebaseUser = firebaseAuth.currentUser;

    return {
      'id': prefs.getInt('id') ?? 0,
      'username': prefs.getString('username') ?? (firebaseUser?.displayName ?? ''),
      'email': prefs.getString('email') ?? (firebaseUser?.email ?? ''),
      'firstName': prefs.getString('firstName') ?? '',
      'lastName': prefs.getString('lastName') ?? '',
      'gender': prefs.getString('gender') ?? '',
      'image': prefs.getString('image') ?? (firebaseUser?.photoURL ?? ''),
      'accessToken': prefs.getString('accessToken') ?? '',
      'refreshToken': prefs.getString('refreshToken') ?? '',
      'token': prefs.getString('token') ?? prefs.getString('accessToken') ?? '',
      'loginType': loginType,
      'uid': prefs.getString('uid') ?? (firebaseUser?.uid ?? ''),
      'contactNo': prefs.getString('contactNo') ?? '',
      'age': prefs.getInt('age') ?? 0,
    };
  }

  // Enhancement 3: Helper to check if the current user logged in through Firebase or DummyJSON
  Future<String> getLoginType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('loginType') ?? (firebaseAuth.currentUser != null ? 'firebase' : 'dummyjson');
  }

  /// Retrieve User model from SharedPreferences
  Future<model.User> getUser() async {
    final userData = await getUserData();
    return model.User.fromJson(userData);
  }

  /// **Check if User is Logged In**
  Future<bool> isLoggedIn() async {
    if (firebaseAuth.currentUser != null) return true;
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken') ?? prefs.getString('token');
    return token != null && token.isNotEmpty;
  }

  //  This logs the user out from both Firebase and local storage so the session is fully cleared
  Future<void> logout() async {
    try {
      await firebaseAuth.signOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      throw Exception('Failed to log out: $e');
    }
  }

  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;

  User? get currentUser => firebaseAuth.currentUser;

  Stream<User?> get authStateChanges => firebaseAuth.authStateChanges();

  // Signs in to Firebase with email and password, then saves the auth info locally
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('loginType', 'firebase');
    await prefs.setString('email', email);
    await prefs.setString('token', await credential.user?.getIdToken() ?? '');
    final savedUsername = prefs.getString('username');
    if (savedUsername == null || savedUsername.isEmpty) {
      await prefs.setString('username', credential.user?.displayName ?? email.split('@').first);
    }
    return credential;
  }

  //Creates a new user in Firebase Auth with their email and password
  Future<UserCredential> createAccount({
    required String email,
    required String password,
  }) async {
    final credential = await firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('loginType', 'firebase');
    await prefs.setString('email', email);
    await prefs.setString('token', await credential.user?.getIdToken() ?? '');
    return credential;
  }

  // igns out from Firebase and wipes out all saved preferences
  Future<void> signOut() async {
    await logout();
  }

  //  Updates the username in the Firebase profile and saves it to local storage
  Future<void> updateUsername({required String newUsername}) async {
    try {
      if (currentUser != null) {
        await currentUser!.updateDisplayName(newUsername);
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('username', newUsername);
    } catch (e) {
      throw Exception('Failed to update username: $e');
    }
  }

  //  Re-authenticates the user with their password before permanently deleting their Firebase account
  Future<void> deleteAccount({
    required String email,
    required String password,
  }) async {
    AuthCredential credential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );

    await currentUser!.reauthenticateWithCredential(credential);
    await currentUser!.delete();
    await firebaseAuth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  //  Verifies the current password first, then updates the user's password in Firebase
  Future<void> resetPasswordFromCurrentPassword({
    required String currentPassword,
    required String newPassword,
    required String email,
  }) async {
    AuthCredential credential = EmailAuthProvider.credential(
      email: email,
      password: currentPassword,
    );
    await currentUser!.reauthenticateWithCredential(credential);
    await currentUser!.updatePassword(newPassword);
  }
}
