import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/firebase_constants.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String? photoUrl;
  final String role; // 'photographer' or 'client'
  final String? phone;
  final String? bio;
  final String? location;
  final bool isProfileComplete;
  final String verificationStatus; // see VerificationStatuses
  final Map<String, bool> notificationPreferences;
  final DateTime createdAt;
  final DateTime? lastActiveAt;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.photoUrl,
    required this.role,
    this.phone,
    this.bio,
    this.location,
    this.isProfileComplete = false,
    this.verificationStatus = VerificationStatuses.unverified,
    this.notificationPreferences = const {
      'push': true,
      'email': true,
      'sms': false,
    },
    required this.createdAt,
    this.lastActiveAt,
  });

  bool get isPhotographer => role == 'photographer';
  bool get isClient => role == 'client';
  bool get isVerified => verificationStatus == VerificationStatuses.verified;

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'name': name,
        'email': email,
        'photoUrl': photoUrl,
        'role': role,
        'phone': phone,
        'bio': bio,
        'location': location,
        'isProfileComplete': isProfileComplete,
        'verificationStatus': verificationStatus,
        'notificationPreferences': notificationPreferences,
        'createdAt': FieldValue.serverTimestamp(),
        'lastActiveAt': FieldValue.serverTimestamp(),
      };

  factory UserModel.fromMap(String uid, Map<String, dynamic> map) => UserModel(
        uid: uid,
        name: map['name'] as String? ?? '',
        email: map['email'] as String? ?? '',
        photoUrl: map['photoUrl'] as String?,
        role: map['role'] as String? ?? 'client',
        phone: map['phone'] as String?,
        bio: map['bio'] as String?,
        location: map['location'] as String?,
        isProfileComplete: map['isProfileComplete'] as bool? ?? false,
        verificationStatus: map['verificationStatus'] as String? ??
            VerificationStatuses.unverified,
        notificationPreferences: (map['notificationPreferences'] as Map? ?? {
          'push': true,
          'email': true,
          'sms': false,
        }).map((k, v) => MapEntry(k.toString(), v as bool? ?? false)),
        createdAt:
            (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        lastActiveAt: (map['lastActiveAt'] as Timestamp?)?.toDate(),
      );

  UserModel copyWith({
    String? name,
    String? email,
    String? photoUrl,
    String? role,
    String? phone,
    String? bio,
    String? location,
    bool? isProfileComplete,
    String? verificationStatus,
    Map<String, bool>? notificationPreferences,
  }) =>
      UserModel(
        uid: uid,
        name: name ?? this.name,
        email: email ?? this.email,
        photoUrl: photoUrl ?? this.photoUrl,
        role: role ?? this.role,
        phone: phone ?? this.phone,
        bio: bio ?? this.bio,
        location: location ?? this.location,
        isProfileComplete: isProfileComplete ?? this.isProfileComplete,
        verificationStatus: verificationStatus ?? this.verificationStatus,
        notificationPreferences:
            notificationPreferences ?? this.notificationPreferences,
        createdAt: createdAt,
        lastActiveAt: lastActiveAt,
      );
}
