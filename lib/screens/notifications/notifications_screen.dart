import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static const List<Map<String, dynamic>> _notifications = [
    {
      'title': 'Booking Confirmed!',
      'body': 'Sofia Reyes has confirmed your session for Mar 18.',
      'time': '2 min ago',
      'icon': Icons.check_circle_rounded,
      'color': Color(0xFF56AB2F),
      'bgColor': Color(0xFFE8F5E9),
      'read': false,
    },
    {
      'title': 'New Message',
      'body': 'Sofia Reyes: "Great! I\'ll confirm the location details tomorrow."',
      'time': '15 min ago',
      'icon': Icons.chat_bubble_rounded,
      'color': Color(0xFFC62828),
      'bgColor': Color(0xFFFFEBEE),
      'read': false,
    },
    {
      'title': 'Booking Request Received',
      'body': 'You have a new booking request from Ava Thompson for Apr 5.',
      'time': '1 hour ago',
      'icon': Icons.calendar_today_rounded,
      'color': Color(0xFFFF6D00),
      'bgColor': Color(0xFFFFF3E0),
      'read': false,
    },
    {
      'title': 'Profile View',
      'body': 'Your profile was viewed by 12 potential clients today.',
      'time': '3 hours ago',
      'icon': Icons.visibility_rounded,
      'color': Color(0xFF1565C0),
      'bgColor': Color(0xFFE3F2FD),
      'read': true,
    },
    {
      'title': 'New Review!',
      'body': 'Emily Watson left a 5-star review: "Absolutely stunning photos!"',
      'time': 'Yesterday',
      'icon': Icons.star_rounded,
      'color': Color(0xFFFFB300),
      'bgColor': Color(0xFFFFF8E1),
      'read': true,
    },
    {
      'title': 'Payment Received',
      'body': 'You\'ve received \$450 for your session with Isabella Cruz.',
      'time': '2 days ago',
      'icon': Icons.payments_rounded,
      'color': Color(0xFF2E7D32),
      'bgColor': Color(0xFFE8F5E9),
      'read': true,
    },
    {
      'title': 'Discovery Alert',
      'body': 'Your profile is trending in New York! 34 new searches found you.',
      'time': '3 days ago',
      'icon': Icons.trending_up_rounded,
      'color': Color(0xFFC62828),
      'bgColor': Color(0xFFFFEBEE),
      'read': true,
    },
    {
      'title': 'Niyot Pro Available',
      'body': 'Upgrade to Pro and get unlimited bookings, analytics, and priority listings.',
      'time': '1 week ago',
      'icon': Icons.workspace_premium_rounded,
      'color': Color(0xFF880E4F),
      'bgColor': Color(0xFFFCE4EC),
      'read': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final unread = _notifications.where((n) => !(n['read'] as bool)).length;

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
            onPressed: () {},
            child: Text(
              'Mark all read',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFC62828),
              ),
            ),
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 100),
        itemCount: _notifications.length,
        separatorBuilder: (_, __) =>
            Divider(height: 1, color: Colors.grey.shade100),
        itemBuilder: (context, index) {
          final item = _notifications[index];
          final isRead = item['read'] as bool;
          return Container(
            color: isRead ? Colors.white : const Color(0xFFFFF5F5),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 10),
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: item['bgColor'] as Color,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  item['icon'] as IconData,
                  color: item['color'] as Color,
                  size: 22,
                ),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      item['title'] as String,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: isRead
                            ? FontWeight.w600
                            : FontWeight.w700,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                  ),
                  if (!isRead)
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
                    item['body'] as String,
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
                    item['time'] as String,
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
  }
}
