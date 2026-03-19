import 'package:cloud_firestore/cloud_firestore.dart';

class ConversationModel {
  final String id;
  final List<String> participantIds;
  final Map<String, String> participantNames;
  final Map<String, String?> participantPhotoUrls;
  final String lastMessage;
  final DateTime lastMessageTime;
  final Map<String, int> unreadCounts;
  final String? bookingId;

  const ConversationModel({
    required this.id,
    required this.participantIds,
    required this.participantNames,
    required this.participantPhotoUrls,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCounts,
    this.bookingId,
  });

  String getOtherUserId(String myId) =>
      participantIds.firstWhere((id) => id != myId, orElse: () => '');

  String getOtherUserName(String myId) =>
      participantNames[getOtherUserId(myId)] ?? '';

  String? getOtherUserPhotoUrl(String myId) =>
      participantPhotoUrls[getOtherUserId(myId)];

  int getUnreadCount(String userId) => unreadCounts[userId] ?? 0;

  String getInitials(String userId) {
    final name = participantNames[userId] ?? '';
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  Map<String, dynamic> toMap() => {
    'participantIds': participantIds,
    'participantNames': participantNames,
    'participantPhotoUrls': participantPhotoUrls.map((k, v) => MapEntry(k, v)),
    'lastMessage': lastMessage,
    'lastMessageTime': FieldValue.serverTimestamp(),
    'unreadCounts': unreadCounts,
    'bookingId': bookingId,
  };

  factory ConversationModel.fromMap(String id, Map<String, dynamic> map) =>
      ConversationModel(
        id: id,
        participantIds: List<String>.from(map['participantIds'] as List? ?? []),
        participantNames: Map<String, String>.from(
          map['participantNames'] as Map? ?? {},
        ),
        participantPhotoUrls: (map['participantPhotoUrls'] as Map? ?? {}).map(
          (k, v) => MapEntry(k.toString(), v as String?),
        ),
        lastMessage: map['lastMessage'] as String? ?? '',
        lastMessageTime:
            (map['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
        unreadCounts: (map['unreadCounts'] as Map? ?? {}).map(
          (k, v) => MapEntry(k.toString(), (v as num).toInt()),
        ),
        bookingId: map['bookingId'] as String?,
      );
}
