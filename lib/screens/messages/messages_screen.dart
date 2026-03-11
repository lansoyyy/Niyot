import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'chat_screen.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  static const List<Map<String, dynamic>> _chats = [
    {
      'name': 'Sofia Reyes',
      'initials': 'SR',
      'lastMessage': 'Great! I\'ll confirm the location details tomorrow.',
      'time': '2m',
      'unread': 2,
      'online': true,
      'gradient': [Color(0xFF8E0000), Color(0xFFC62828)],
    },
    {
      'name': 'Marcus Chen',
      'initials': 'MC',
      'lastMessage': 'The shoot went amazing! Sending you the preview shots.',
      'time': '1h',
      'unread': 0,
      'online': true,
      'gradient': [Color(0xFF4A0000), Color(0xFF880E0E)],
    },
    {
      'name': 'Ava Thompson',
      'initials': 'AT',
      'lastMessage': 'Your booking request has been received.',
      'time': '3h',
      'unread': 1,
      'online': false,
      'gradient': [Color(0xFF880E4F), Color(0xFFAD1457)],
    },
    {
      'name': 'Liam Park',
      'initials': 'LP',
      'lastMessage': 'Can we reschedule to the following weekend?',
      'time': '1d',
      'unread': 0,
      'online': false,
      'gradient': [Color(0xFFC62828), Color(0xFF6B0000)],
    },
    {
      'name': 'Isabella Cruz',
      'initials': 'IC',
      'lastMessage': 'Thank you for the wonderful experience! ⭐',
      'time': '2d',
      'unread': 0,
      'online': false,
      'gradient': [Color(0xFFAD1457), Color(0xFF560027)],
    },
    {
      'name': 'Niyot Support',
      'initials': 'NS',
      'lastMessage': 'Your account has been verified. Welcome to Niyot!',
      'time': '5d',
      'unread': 0,
      'online': true,
      'gradient': [Color(0xFF6B0000), Color(0xFF8E0000)],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
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
            // Search
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
                    const Icon(Icons.search_rounded,
                        color: Color(0xFFBDBDBD), size: 20),
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
            // Online contacts horizontal scroll
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _chats.where((c) => c['online'] as bool).length,
                itemBuilder: (context, index) {
                  final onlineChats =
                      _chats.where((c) => c['online'] as bool).toList();
                  final chat = onlineChats[index];
                  return Container(
                    margin: const EdgeInsets.only(right: 16),
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: List<Color>.from(
                                      chat['gradient'] as List),
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  chat['initials'] as String,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 1,
                              right: 1,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.white, width: 2),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          (chat['name'] as String).split(' ')[0],
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
            const SizedBox(height: 8),
            Divider(color: Colors.grey.shade100, height: 1),
            // Chat list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 8, bottom: 100),
                itemCount: _chats.length,
                itemBuilder: (context, index) {
                  final chat = _chats[index];
                  final hasUnread = (chat['unread'] as int) > 0;
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 6),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(chatData: chat),
                      ),
                    ),
                    leading: Stack(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors:
                                  List<Color>.from(chat['gradient'] as List),
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              chat['initials'] as String,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        if (chat['online'] as bool)
                          Positioned(
                            bottom: 1,
                            right: 1,
                            child: Container(
                              width: 13,
                              height: 13,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.white, width: 2),
                              ),
                            ),
                          ),
                      ],
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            chat['name'] as String,
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
                          chat['time'] as String,
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
                            chat['lastMessage'] as String,
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
                                '${chat['unread']}',
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
  }
}
