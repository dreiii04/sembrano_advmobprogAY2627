// ignore_for_file: deprecated_member_use, use_build_context_synchronously, use_super_parameters

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../services/chat_service.dart';
import '../services/user_service.dart';
import '../widgets/custom_text.dart';

final ChatService chatService = ChatService();

class ChatDetailScreen extends StatefulWidget {
  final String currentUserEmail;
  final Map<String, dynamic> tappedUser;

  const ChatDetailScreen({
    Key? key,
    required this.currentUserEmail,
    required this.tappedUser,
  }) : super(key: key);

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen>
    with TickerProviderStateMixin {
  final TextEditingController _msgCtrl = TextEditingController();
  final FocusNode _msgFocus = FocusNode();
  final ScrollController _scrollCtrl = ScrollController();

  late Future<String> _currentUserIdFuture;

  // Tracks if message is sending to show sending state and spinner
  bool _isSending = false;
  Timestamp? _sendingStartedAt;

  // Stores message text to render temporary sending bubble
  String _pendingMessage = '';

  // Delay so sending state animation is visible before delivered
  static const _postSendDelay = Duration(milliseconds: 600);

  @override
  void initState() {
    super.initState();
    _currentUserIdFuture = _getCurrentUserId();
  }

  // Fetches logged-in user UID to separate sender from receiver
  Future<String> _getCurrentUserId() async {
    final userData = await userService.value.getUserData();
    return (userData['uid'] ?? '').toString();
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _msgFocus.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // Sends message to Firestore, updates sending state, and auto-scrolls
  Future<void> _send(String currentUserId, String receiverId) async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
      _pendingMessage = text;
      _sendingStartedAt = Timestamp.now();
    });

    try {
      _msgCtrl.clear();
      await chatService.sendMessage(receiverId, text);
      _msgFocus.requestFocus();

      // Scrolls to bottom when new message is sent
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          0.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }

      await Future.delayed(_postSendDelay);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
          _pendingMessage = '';
          _sendingStartedAt = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tappedUserId = (widget.tappedUser['uid'] ?? '').toString();
    // Shows username in AppBar with fallback to first name
    final tappedUserName =
        (widget.tappedUser['username'] ?? widget.tappedUser['firstName'] ?? '')
            .toString();

    return FutureBuilder<String>(
      future: _currentUserIdFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.hasError || !snap.hasData || snap.data!.isEmpty) {
          return const Scaffold(
            body: Center(child: Text('Error loading user data')),
          );
        }

        final currentUserId = snap.data!;

        return Scaffold(
          // Modern redesigned AppBar with avatar initial and username
          appBar: AppBar(
            centerTitle: true,
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor:
                      Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  child: Text(
                    tappedUserName.isNotEmpty
                        ? tappedUserName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                CustomText(text: tappedUserName, fontSize: 20.sp),
              ],
            ),
          ),
          backgroundColor: Colors.grey.shade50,
          body: Column(
            children: [
              // Real-time message stream with transition animations
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: chatService.getMessage(currentUserId, tappedUserId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child:
                            Text('Error loading messages: ${snapshot.error}'),
                      );
                    }

                    List<QueryDocumentSnapshot> docs =
                        snapshot.data?.docs ?? [];

                    // Hides just-sent message until sending delay finishes
                    if (_isSending && _sendingStartedAt != null) {
                      docs = docs.where((d) {
                        final data = d.data() as Map<String, dynamic>;
                        final senderId = (data['senderId'] ?? '').toString();
                        final ts = data['timestamp'];
                        if (senderId != currentUserId) return true;
                        if (ts is Timestamp) {
                          return ts.compareTo(_sendingStartedAt!) < 0;
                        }
                        return true;
                      }).toList();
                    }

                    if (docs.isEmpty && !_isSending) {
                      return const Center(child: Text('No messages yet'));
                    }

                    final totalItems = docs.length + (_isSending ? 1 : 0);

                    return ListView.builder(
                      controller: _scrollCtrl,
                      reverse: true,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: totalItems,
                      itemBuilder: (context, index) {
                        // Renders pending sending bubble at the bottom
                        if (_isSending && index == 0) {
                          return _buildPendingBubble(context);
                        }

                        final docIndex = _isSending ? index - 1 : index;
                        final data =
                            docs[docIndex].data() as Map<String, dynamic>;
                        final msgText = (data['message'] ?? '').toString();
                        final senderId = (data['senderId'] ?? '').toString();
                        final isMe = senderId == currentUserId;

                        // Smooth fade and slide up animation for messages
                        return TweenAnimationBuilder<double>(
                          key: ValueKey(docs[docIndex].id),
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeOut,
                          builder: (context, value, child) {
                            return Opacity(
                              opacity: value,
                              child: Transform.translate(
                                offset: Offset(0, 20 * (1 - value)),
                                child: child,
                              ),
                            );
                          },
                          child: _buildMessageBubble(
                            context: context,
                            text: msgText,
                            isMe: isMe,
                            status: isMe ? 'delivered' : null,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              // Modern message composer with rounded input and send button
              SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, -1),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _msgCtrl,
                          focusNode: _msgFocus,
                          enabled: !_isSending,
                          textInputAction: TextInputAction.send,
                          minLines: 1,
                          maxLines: 4,
                          onSubmitted: (_) => !_isSending
                              ? _send(currentUserId, tappedUserId)
                              : null,
                          decoration: InputDecoration(
                            hintText: 'Type a message...',
                            hintStyle: const TextStyle(fontFamily: 'Poppins'),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Shows spinner while sending, otherwise circular send button
                      _isSending
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            )
                          : CircleAvatar(
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                              radius: 20,
                              child: IconButton(
                                icon: const Icon(Icons.send,
                                    color: Colors.white, size: 18),
                                onPressed: () =>
                                    _send(currentUserId, tappedUserId),
                              ),
                            ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Builds temporary bubble with "sending..." text and mini spinner
  Widget _buildPendingBubble(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: _buildMessageBubble(
        context: context,
        text: _pendingMessage,
        isMe: true,
        status: 'sending',
      ),
    );
  }

  // Redesigned chat bubble with distinct colors, corners, and checkmarks
  Widget _buildMessageBubble({
    required BuildContext context,
    required String text,
    required bool isMe,
    String? status,
  }) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMe
              ? Theme.of(context).colorScheme.primary.withOpacity(0.85)
              : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft:
                isMe ? const Radius.circular(18) : const Radius.circular(4),
            bottomRight:
                isMe ? const Radius.circular(4) : const Radius.circular(18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            CustomText(
              text: text.isNotEmpty ? text : '[empty]',
              fontSize: 15.sp,
              fontWeight: FontWeight.normal,
              textAlign: TextAlign.left,
              color: isMe ? Colors.white : Colors.black87,
            ),
            // Shows "sending..." with spinner or delivered double checkmarks
            if (isMe && status != null)
              Padding(
                padding: EdgeInsets.only(top: 4.h),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (status == 'sending') ...[
                      Text(
                        'sending...',
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: Colors.white70,
                          fontFamily: 'Poppins',
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      SizedBox(
                        height: 10.sp,
                        width: 10.sp,
                        child: const CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: Colors.white70,
                        ),
                      ),
                    ] else if (status == 'delivered') ...[
                      Icon(
                        Icons.done_all,
                        size: 14.sp,
                        color: Colors.white70,
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
