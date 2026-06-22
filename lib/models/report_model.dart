import 'package:cloud_firestore/cloud_firestore.dart';

class ReportModel {
  final String id;
  final String reporterId;
  final String reporterName;
  final String reportedUserId;
  final String reportedUserName;
  final String contentType; // 'photographer', 'review', 'message'
  final String? contentId;
  final String reason;
  final String? description;
  final String status; // 'pending', 'reviewed', 'resolved'
  final DateTime createdAt;

  const ReportModel({
    required this.id,
    required this.reporterId,
    required this.reporterName,
    required this.reportedUserId,
    required this.reportedUserName,
    required this.contentType,
    this.contentId,
    required this.reason,
    this.description,
    this.status = 'pending',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'reporterId': reporterId,
        'reporterName': reporterName,
        'reportedUserId': reportedUserId,
        'reportedUserName': reportedUserName,
        'contentType': contentType,
        'contentId': contentId,
        'reason': reason,
        'description': description,
        'status': status,
        'createdAt': FieldValue.serverTimestamp(),
      };

  factory ReportModel.fromMap(String id, Map<String, dynamic> map) =>
      ReportModel(
        id: id,
        reporterId: map['reporterId'] as String? ?? '',
        reporterName: map['reporterName'] as String? ?? '',
        reportedUserId: map['reportedUserId'] as String? ?? '',
        reportedUserName: map['reportedUserName'] as String? ?? '',
        contentType: map['contentType'] as String? ?? '',
        contentId: map['contentId'] as String?,
        reason: map['reason'] as String? ?? '',
        description: map['description'] as String?,
        status: map['status'] as String? ?? 'pending',
        createdAt:
            (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );

  static const List<String> reportReasons = [
    'Inappropriate content',
    'Harassment or bullying',
    'Spam or scam',
    'Fake profile',
    'Hate speech',
    'Violence or threats',
    'Intellectual property violation',
    'Other',
  ];
}
