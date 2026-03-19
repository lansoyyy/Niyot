import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/message_model.dart';
import '../../services/messaging_service.dart';
import '../../services/storage_service.dart';
import '../../services/user_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.otherUserId,
    required this.otherUserName,
  });

  final String conversationId;
  final String otherUserId;
  final String otherUserName;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _picker = ImagePicker();
  final _currentUser = FirebaseAuth.instance.currentUser;

  bool _isSending = false;

  static const _gradients = [
    [Color(0xFF6B0000), Color(0xFFC62828)],
    [Color(0xFF4A0000), Color(0xFF880E0E)],
    [Color(0xFF1A237E), Color(0xFF3949AB)],
    [Color(0xFF1B5E20), Color(0xFF388E3C)],
    [Color(0xFF004D40), Color(0xFF00897B)],
    [Color(0xFFBF360C), Color(0xFFE64A19)],
    [Color(0xFF4A148C), Color(0xFF7B1FA2)],
  ];

  List<Color> _otherGradient(String userId) {
    final index =
        userId.codeUnits.fold<int>(0, (sum, c) => sum + c) % _gradients.length;
    return _gradients[index].cast<Color>();
  }

  String _initials(String name) {
    final parts = name
        .trim()
        .split(' ')
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  String _formatTime(DateTime date) {
    final hour = date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  void _scrollToBottom({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final offset = _scrollController.position.maxScrollExtent;
      if (animated) {
        _scrollController.animateTo(
          offset,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(offset);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final uid = _currentUser?.uid;
      if (uid != null) {
        await MessagingService().markConversationRead(
          widget.conversationId,
          uid,
        );
      }
      _scrollToBottom(animated: false);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    final uid = _currentUser?.uid;
    if (text.isEmpty || uid == null || _isSending) return;

    final senderName =
        UserService().cachedUser?.name ??
        _currentUser?.displayName ??
        _currentUser?.email ??
        'User';

    setState(() => _isSending = true);
    try {
      await MessagingService().sendMessage(
        conversationId: widget.conversationId,
        senderId: uid,
        senderName: senderName,
        text: text,
      );
      _messageController.clear();
      _scrollToBottom();
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<void> _pickAndSendImage() async {
    final uid = _currentUser?.uid;
    if (uid == null || _isSending) return;

    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (pickedFile == null) return;

    final senderName =
        UserService().cachedUser?.name ??
        _currentUser?.displayName ??
        _currentUser?.email ??
        'User';
    final caption = _messageController.text.trim();
    final extension = pickedFile.path.contains('.')
        ? pickedFile.path.split('.').last
        : 'jpg';
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_$uid.$extension';

    setState(() => _isSending = true);
    try {
      final imageUrl = await StorageService().uploadChatAttachment(
        widget.conversationId,
        fileName,
        File(pickedFile.path),
      );

      await MessagingService().sendMessage(
        conversationId: widget.conversationId,
        senderId: uid,
        senderName: senderName,
        text: caption,
        mediaUrl: imageUrl,
        mediaType: 'image',
      );

      _messageController.clear();
      _scrollToBottom();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to send image right now.',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final gradient = _otherGradient(widget.otherUserId);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 16,
              color: Color(0xFF374151),
            ),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  _initials(widget.otherUserName),
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.otherUserName,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
                Text(
                  'Conversation',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: const Color(0xFFBDBDBD),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: const [],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: MessagingService().messagesStream(widget.conversationId),
              builder: (context, snapshot) {
                final messages = snapshot.data ?? const <MessageModel>[];

                if (snapshot.connectionState == ConnectionState.waiting &&
                    messages.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFFC62828)),
                  );
                }

                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      'No messages yet',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: const Color(0xFF9E9E9E),
                      ),
                    ),
                  );
                }

                final uid = _currentUser?.uid ?? '';
                WidgetsBinding.instance.addPostFrameCallback((_) async {
                  _scrollToBottom();
                  if (uid.isNotEmpty) {
                    await MessagingService().markConversationRead(
                      widget.conversationId,
                      uid,
                    );
                  }
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.isSentBy(uid);
                    final showDayLabel =
                        index == 0 ||
                        !_isSameDay(
                          message.timestamp,
                          messages[index - 1].timestamp,
                        );

                    return Column(
                      children: [
                        if (showDayLabel)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Text(
                              _dayLabel(message.timestamp),
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: const Color(0xFFBDBDBD),
                              ),
                            ),
                          ),
                        _MessageBubble(
                          text: message.text,
                          mediaUrl: message.mediaUrl,
                          mediaType: message.mediaType,
                          time: _formatTime(message.timestamp),
                          isMe: isMe,
                          gradient: gradient,
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            color: Colors.white,
            child: Row(
              children: [
                IconButton(
                  onPressed: _pickAndSendImage,
                  icon: const Icon(
                    Icons.attach_file_rounded,
                    color: Color(0xFF9E9E9E),
                    size: 22,
                  ),
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _messageController,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: const Color(0xFF1F2937),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: GoogleFonts.poppins(
                          fontSize: 13,
                          color: const Color(0xFFBDBDBD),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        isDense: true,
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _isSending
                            ? const [Color(0xFFBDBDBD), Color(0xFF9E9E9E)]
                            : const [Color(0xFF6B0000), Color(0xFFC62828)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isSending
                          ? Icons.hourglass_top_rounded
                          : Icons.send_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _dayLabel(DateTime date) {
    final now = DateTime.now();
    if (_isSameDay(date, now)) return 'Today';
    if (_isSameDay(date, now.subtract(const Duration(days: 1)))) {
      return 'Yesterday';
    }

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.text,
    this.mediaUrl,
    this.mediaType,
    required this.time,
    required this.isMe,
    required this.gradient,
  });

  final String text;
  final String? mediaUrl;
  final String? mediaType;
  final String time;
  final bool isMe;
  final List<Color> gradient;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: isMe
              ? LinearGradient(
                  colors: gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isMe ? null : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: isMe
                ? const Radius.circular(18)
                : const Radius.circular(4),
            bottomRight: isMe
                ? const Radius.circular(4)
                : const Radius.circular(18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            if (mediaType == 'image' && mediaUrl != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  mediaUrl!,
                  width: MediaQuery.of(context).size.width * 0.6,
                  height: 180,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: MediaQuery.of(context).size.width * 0.6,
                    height: 180,
                    color: isMe
                        ? Colors.white.withValues(alpha: 0.12)
                        : const Color(0xFFF1F5F9),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.broken_image_rounded,
                      color: isMe ? Colors.white : const Color(0xFF9E9E9E),
                    ),
                  ),
                ),
              ),
              if (text.isNotEmpty) const SizedBox(height: 8),
            ],
            if (text.isNotEmpty)
              Text(
                text,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: isMe ? Colors.white : const Color(0xFF374151),
                  height: 1.4,
                ),
              ),
            const SizedBox(height: 4),
            Text(
              time,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: isMe
                    ? Colors.white.withValues(alpha: 0.7)
                    : const Color(0xFFBDBDBD),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
