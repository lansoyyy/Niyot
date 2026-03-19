import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/firebase_constants.dart';

class VerificationSubmissionModel {
  final String id;
  final String userId;
  final String legalName;
  final String governmentIdNumber;
  final List<VerificationDocumentModel> documents;
  final String status; // see VerificationStatuses
  final String? rejectionReason;
  final DateTime submittedAt;
  final DateTime? reviewedAt;

  const VerificationSubmissionModel({
    required this.id,
    required this.userId,
    required this.legalName,
    required this.governmentIdNumber,
    required this.documents,
    required this.status,
    this.rejectionReason,
    required this.submittedAt,
    this.reviewedAt,
  });

  bool get isPending => status == VerificationStatuses.pending;
  bool get isVerified => status == VerificationStatuses.verified;
  bool get isRejected => status == VerificationStatuses.rejected;

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'legalName': legalName,
    'governmentIdNumber': governmentIdNumber,
    'documents': documents.map((d) => d.toMap()).toList(),
    'status': status,
    'rejectionReason': rejectionReason,
    'submittedAt': FieldValue.serverTimestamp(),
    'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
  };

  factory VerificationSubmissionModel.fromMap(
    String id,
    Map<String, dynamic> map,
  ) => VerificationSubmissionModel(
    id: id,
    userId: map['userId'] as String? ?? '',
    legalName: map['legalName'] as String? ?? '',
    governmentIdNumber: map['governmentIdNumber'] as String? ?? '',
    documents: (map['documents'] as List<dynamic>? ?? [])
        .map(
          (d) => VerificationDocumentModel.fromMap(
            Map<String, dynamic>.from(d as Map),
          ),
        )
        .toList(),
    status: map['status'] as String? ?? VerificationStatuses.unverified,
    rejectionReason: map['rejectionReason'] as String?,
    submittedAt: (map['submittedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    reviewedAt: (map['reviewedAt'] as Timestamp?)?.toDate(),
  );
}

class VerificationDocumentModel {
  final String type; // 'government_id' | 'portfolio_license' | 'address_proof'
  final String url;
  final DateTime uploadedAt;

  const VerificationDocumentModel({
    required this.type,
    required this.url,
    required this.uploadedAt,
  });

  Map<String, dynamic> toMap() => {
    'type': type,
    'url': url,
    'uploadedAt': Timestamp.fromDate(uploadedAt),
  };

  factory VerificationDocumentModel.fromMap(Map<String, dynamic> map) =>
      VerificationDocumentModel(
        type: map['type'] as String? ?? '',
        url: map['url'] as String? ?? '',
        uploadedAt:
            (map['uploadedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
}
