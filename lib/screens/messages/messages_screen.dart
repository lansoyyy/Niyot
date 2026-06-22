import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/conversation_model.dart';
import '../../models/user_model.dart';
import '../../services/block_service.dart';
import '../../services/messaging_service.dart';
import '../../services/user_service.dart';
import '../../widgets/common/app_profile_avatar.dart';
import 'chat_screen.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final _currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
  Set<String> _blockedUserIds = <String>{};

  @override
  void initState() {
    super.initState();
    if (_currentUid.isNotEmpty) {
      BlockService().blockedUserIdsStream(_currentUid).listen((ids) {
        if (mounted) {
          setState(() => _blockedUserIds = ids);
        }
      });
    }
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ConversationModel>>(
      stream: MessagingService().conversationsStream(_currentUid),
      builder: (context, snapshot) {
        final allConversations = snapshot.data ?? const <ConversationModel>[];
        final conversations = allConversations.where((c) {
          final otherId = c.getOtherUserId(_currentUid);
          return !_blockedUserIds.contains(otherId);
        }).toList();

        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Messages',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
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
                const SizedBox(height: 8),
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
                              leading: _ConversationAvatar(
                                otherUserId: otherId,
                                fallbackName: otherName,
                                stalePhotoUrl: conversation.getOtherUserPhotoUrl(
                                  _currentUid,
                                ),
                                size: 52,
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

class _ConversationAvatar extends StatelessWidget {
  const _ConversationAvatar({
    required this.otherUserId,
    required this.fallbackName,
    required this.stalePhotoUrl,
    required this.size,
  });

  final String otherUserId;
  final String fallbackName;
  final String? stalePhotoUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserModel?>(
      stream: UserService().userStream(otherUserId),
      builder: (context, snap) {
        final u = snap.data;
        final url = u?.photoUrl ?? stalePhotoUrl;
        final name = (u?.name.trim().isNotEmpty ?? false)
            ? u!.name
            : fallbackName;
        return AppProfileAvatar(
          displayName: name,
          photoUrl: url,
          size: size,
        );
      },
    );
  }
}
