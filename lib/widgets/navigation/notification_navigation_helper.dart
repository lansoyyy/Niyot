import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/notification_model.dart';
import '../../screens/bookings/booking_detail_screen.dart';
import '../../screens/messages/chat_screen.dart';
import '../../services/booking_service.dart';
import '../../services/messaging_service.dart';

/// Opens the screen that matches a notification ([relatedId] + [type]).
class NotificationNavigationHelper {
  NotificationNavigationHelper._();

  static Future<void> openFromNotification(
    BuildContext context,
    NotificationModel notification,
  ) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final related = notification.relatedId;
    if (related == null || related.isEmpty) {
      _snack(context, 'No link available for this notification.');
      return;
    }

    try {
      switch (notification.type) {
        case NotificationType.bookingRequest:
        case NotificationType.bookingConfirmed:
        case NotificationType.bookingDeclined:
        case NotificationType.paymentReceived:
        case NotificationType.reviewLeft:
          final booking = await BookingService().getBookingById(related);
          if (!context.mounted) return;
          if (booking == null) {
            _snack(context, 'This booking is no longer available.');
            return;
          }
          final isPhotographer = booking.photographerId == uid;
          await Navigator.of(context).push<void>(
            MaterialPageRoute<void>(
              builder: (_) => BookingDetailScreen(
                booking: booking,
                isPhotographer: isPhotographer,
              ),
            ),
          );
          break;
        case NotificationType.newMessage:
          final conv = await MessagingService().getConversationById(related);
          if (!context.mounted) return;
          if (conv == null) {
            _snack(context, 'This conversation could not be opened.');
            return;
          }
          final otherId = conv.getOtherUserId(uid);
          final otherName = conv.getOtherUserName(uid);
          if (otherId.isEmpty) {
            _snack(context, 'This conversation could not be opened.');
            return;
          }
          await Navigator.of(context).push<void>(
            MaterialPageRoute<void>(
              builder: (_) => ChatScreen(
                conversationId: conv.id,
                otherUserId: otherId,
                otherUserName: otherName.isEmpty ? 'Chat' : otherName,
              ),
            ),
          );
          break;
        case NotificationType.profileView:
          _snack(
            context,
            'Profile views are summarized on your photographer dashboard.',
          );
          break;
        case NotificationType.system:
          _snack(context, 'No additional details for this notification.');
          break;
      }
    } catch (_) {
      if (context.mounted) {
        _snack(context, 'Something went wrong opening that link.');
      }
    }
  }

  static void _snack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.poppins(fontSize: 13)),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
