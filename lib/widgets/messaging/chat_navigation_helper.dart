import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../screens/messages/chat_screen.dart';
import '../../services/messaging_service.dart';
import '../../services/user_service.dart';

/// Opens the single shared chat thread for the current user and [otherUserId].
class ChatNavigationHelper {
  ChatNavigationHelper._();

  static Future<void> openChat({
    required BuildContext context,
    required String otherUserId,
    required String otherUserName,
    String? otherUserPhotoUrl,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      final profile =
          UserService().cachedUser ?? await UserService().fetchCurrentUser();
      final convId = await MessagingService().getOrCreateConversation(
        myId: currentUser.uid,
        myName: profile?.name ?? currentUser.displayName ?? 'User',
        myPhotoUrl: profile?.photoUrl,
        otherUserId: otherUserId,
        otherUserName: otherUserName,
        otherUserPhotoUrl: otherUserPhotoUrl,
      );
      if (!context.mounted) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => ChatScreen(
            conversationId: convId,
            otherUserId: otherUserId,
            otherUserName: otherUserName,
          ),
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to open chat right now.',
            style: GoogleFonts.poppins(fontSize: 13),
          ),
        ),
      );
    }
  }
}
