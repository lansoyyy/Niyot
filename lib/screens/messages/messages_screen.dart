import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/conversation_model.dart';
import '../../services/messaging_service.dart';
import 'chat_screen.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final _currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

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

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  String _otherInitials(String name) {
    final parts = name
        .trim()
        .split(' ')
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ConversationModel>>(
      stream: MessagingService().conversationsStream(_currentUid),
      builder: (context, snapshot) {
        final conversations = snapshot.data ?? const <ConversationModel>[];
        final recentContacts = conversations
            .where(
              (conversation) =>
                  DateTime.now()
                      .difference(conversation.lastMessageTime)
                      .inHours <
                  24,
            )
            .toList();

        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Messages',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1A1A),
                        ),
                      ),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.edit_rounded,
                          size: 18,
                          color: Color(0xFFC62828),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 14),
                        const Icon(
                          Icons.search_rounded,
                          color: Color(0xFFBDBDBD),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Search conversations...',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: const Color(0xFFBDBDBD),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (recentContacts.isNotEmpty)
                  SizedBox(
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: recentContacts.length,
                      itemBuilder: (context, index) {
                        final conversation = recentContacts[index];
                        final otherId = conversation.getOtherUserId(
                          _currentUid,
                        );
                        final otherName = conversation.getOtherUserName(
                          _currentUid,
                        );

                        return Container(
                          margin: const EdgeInsets.only(right: 16),
                          child: Column(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: _otherGradient(otherId),
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    _otherInitials(otherName),
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                otherName.split(' ').first,
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: const Color(0xFF7A7A7A),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                if (recentContacts.isNotEmpty) const SizedBox(height: 8),
                Divider(color: Colors.grey.shade100, height: 1),
                Expanded(
                  child:
                      snapshot.connectionState == ConnectionState.waiting &&
                          conversations.isEmpty
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFC62828),
                          ),
                        )
                      : conversations.isEmpty
                      ? Center(
                          child: Text(
                            'No conversations yet',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: const Color(0xFF9E9E9E),
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(top: 8, bottom: 100),
                          itemCount: conversations.length,
                          itemBuilder: (context, index) {
                            final conversation = conversations[index];
                            final otherId = conversation.getOtherUserId(
                              _currentUid,
                            );
                            final otherName = conversation.getOtherUserName(
                              _currentUid,
                            );
                            final unread = conversation.getUnreadCount(
                              _currentUid,
                            );
                            final hasUnread = unread > 0;

                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 6,
                              ),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ChatScreen(
                                      conversationId: conversation.id,
                                      otherUserId: otherId,
                                      otherUserName: otherName,
                                    ),
                                  ),
                                );
                              },
                              leading: Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: _otherGradient(otherId),
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    _otherInitials(otherName),
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      otherName,
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: hasUnread
                                            ? FontWeight.w700
                                            : FontWeight.w600,
                                        color: const Color(0xFF1A1A1A),
                                      ),
                                    ),
                                  ),
                                  Text(
                                    _timeAgo(conversation.lastMessageTime),
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: hasUnread
                                          ? const Color(0xFFC62828)
                                          : const Color(0xFFBDBDBD),
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      conversation.lastMessage.isEmpty
                                          ? 'No messages yet'
                                          : conversation.lastMessage,
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: hasUnread
                                            ? const Color(0xFF374151)
                                            : const Color(0xFFBDBDBD),
                                        fontWeight: hasUnread
                                            ? FontWeight.w500
                                            : FontWeight.w400,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (hasUnread)
                                    Container(
                                      width: 20,
                                      height: 20,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFC62828),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          '$unread',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
