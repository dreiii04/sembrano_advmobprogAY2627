import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../services/chat_service.dart';
import '../services/user_service.dart';
import '../widgets/custom_text.dart';
import 'chat_detailscreen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  //Controller that manages what the user types in the search bar
  final TextEditingController _searchChatController = TextEditingController();
  final ChatService _chatService = ChatService();

  // Holds the logged-in user's email so we can filter them out of the list
  String? _currentUserEmail;

  // Holds the current search text so the user list can filter in real-time
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _loadCurrentUserEmail();
  }
  // Calls userService.value.getUserData() to fetch the logged-in user's profile info.
  
  Future<void> _loadCurrentUserEmail() async {
    final userData = await userService.value.getUserData();
    setState(() {
      _currentUserEmail = userData['email'];
    });
  }

  @override
  void dispose() {
    _searchChatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: 20.h),

          Padding(
            padding: EdgeInsets.symmetric(horizontal: 23.w),
            child: TextField(
              controller: _searchChatController,
              textInputAction: TextInputAction.search,

              onChanged: (value) {
                setState(() {
                  _searchText = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search chat...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: (_searchChatController.text.isNotEmpty)
                    ? IconButton(
                        tooltip: 'Clear',
                        icon: const Icon(Icons.cancel),
                        onPressed: () {
                          setState(() {
                            _searchChatController.clear();
                            _searchText = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          SizedBox(height: 10.h),

          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _chatService.getUsersStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Container(
                  height: ScreenUtil().screenHeight * 0.6,
                  padding: EdgeInsets.all(16.sp),
                  child: const Center(
                    child: CircularProgressIndicator.adaptive(),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Container(
                  height: ScreenUtil().screenHeight * 0.6,
                  padding: EdgeInsets.all(16.sp),
                  child: Center(
                    child: CustomText(
                      text: 'Error loading users',
                      fontSize: 16.sp,
                    ),
                  ),
                );
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Container(
                  height: ScreenUtil().screenHeight * 0.6,
                  padding: EdgeInsets.all(16.sp),
                  child: Center(
                    child: CustomText(
                      text: 'No users found',
                      fontSize: 16.sp,
                    ),
                  ),
                );
              }
              //  Compares user['email'] with _currentUserEmail.
              //    If they match, it returns false to exclude the logged-in user from the list.
              //  If the search bar has text, it converts the search text
              //    and user fields (firstName, username, email) to lowercase and checks if any
              //    contain the query string.
              final users = snapshot.data!.where((user) {
                final email = user['email'] ?? '';
                final isNotCurrentUser = email != _currentUserEmail;
                if (_searchText.isEmpty) return isNotCurrentUser;

                final firstName = (user['firstName'] ?? '').toString().toLowerCase();
                final username = (user['username'] ?? '').toString().toLowerCase();
                final search = _searchText.toLowerCase();

                final matchesSearch = firstName.contains(search) ||
                    username.contains(search) ||
                    email.toString().toLowerCase().contains(search);

                return isNotCurrentUser && matchesSearch;
              }).toList();

              if (users.isEmpty) {
                return Container(
                  height: ScreenUtil().screenHeight * 0.6,
                  padding: EdgeInsets.all(16.sp),
                  child: Center(
                    child: CustomText(
                      text: 'No messages found...',
                      fontSize: 16.sp,
                    ),
                  ),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                physics: const NeverScrollableScrollPhysics(),
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  return GestureDetector(

                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatDetailScreen(
                            currentUserEmail: _currentUserEmail!,
                            tappedUser: user,
                          ),
                        ),
                      );
                    },
                    child: Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          child: CustomText(
                            text:
                                user['firstName'] != null &&
                                        user['firstName'].toString().isNotEmpty
                                    ? user['firstName'][0].toUpperCase()
                                    : '?',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        // Shows the username, falling back to firstName if username is blank
                        title: CustomText(
                          text: user['username'] ?? user['firstName'] ?? 'Unknown',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        subtitle: CustomText(
                          text: user['email'] ?? 'No email',
                          fontSize: 12,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}