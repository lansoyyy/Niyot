import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/notification_model.dart';
import '../../services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
  bool _isMarkingAllRead = false;

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) {
      return diff.inHours == 1 ? '1 hour ago' : '${diff.inHours} hours ago';
    }
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    final weeks = (diff.inDays / 7).floor();
    return weeks == 1 ? '1 week ago' : '$weeks weeks ago';
  }

  Future<void> _markAllRead() async {
    if (_isMarkingAllRead) return;
    setState(() => _isMarkingAllRead = true);
    try {
      await NotificationService().markAllRead(_currentUid);
    } finally {
      if (mounted) {
        setState(() => _isMarkingAllRead = false);
      }
    }
  }

  Future<void> _handleTap(NotificationModel notification) async {
    if (!notification.isRead) {
      await NotificationService().markRead(_currentUid, notification.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<NotificationModel>>(
      stream: NotificationService().notificationsStream(_currentUid),
      builder: (context, snapshot) {
        final notifications = snapshot.data ?? const <NotificationModel>[];
        final unread = notifications.where((n) => !n.isRead).length;

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
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notifications',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
                if (unread > 0)
                  Text(
                    '$unread new',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: const Color(0xFFC62828),
                    ),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: unread == 0 || _isMarkingAllRead
                    ? null
                    : _markAllRead,
                child: Text(
                  _isMarkingAllRead ? 'Working...' : 'Mark all read',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: unread == 0
                        ? const Color(0xFFBDBDBD)
                        : const Color(0xFFC62828),
                  ),
                ),
              ),
            ],
          ),
          body:
              snapshot.connectionState == ConnectionState.waiting &&
                  notifications.isEmpty
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFFC62828)),
                )
              : notifications.isEmpty
              ? Center(
                  child: Text(
                    'No notifications yet',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: const Color(0xFF9E9E9E),
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(0, 8, 0, 100),
                  itemCount: notifications.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: Colors.grey.shade100),
                  itemBuilder: (context, index) {
                    final item = notifications[index];
                    return Container(
                      color: item.isRead
                          ? Colors.white
                          : const Color(0xFFFFF5F5),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        onTap: () => _handleTap(item),
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: item.type.bgColor,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            item.type.icon,
                            color: item.type.color,
                            size: 22,
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.title,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: item.isRead
                                      ? FontWeight.w600
                                      : FontWeight.w700,
                                  color: const Color(0xFF1A1A1A),
                                ),
                              ),
                            ),
                            if (!item.isRead)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFC62828),
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 2),
                            Text(
                              item.body,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: const Color(0xFF7A7A7A),
                                height: 1.4,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _timeAgo(item.createdAt),
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: const Color(0xFFBDBDBD),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}
