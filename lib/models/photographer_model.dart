import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'service_package_model.dart';

class PhotographerModel {
  final String uid;
  final String name;
  final String? photoUrl;
  final String bio;
  final String locationText;
  final GeoPoint? geoPoint;
  final List<String> specialties;
  final String primarySpecialty;
  final double rating;
  final int reviewCount;
  final int bookingCount;
  final int profileViewCount;
  final int photoCount;
  final bool isAvailable;
  final bool isFeatured;
  final bool isVerified;
  final List<ServicePackageModel> packages;
  final DateTime createdAt;

  const PhotographerModel({
    required this.uid,
    required this.name,
    this.photoUrl,
    required this.bio,
    required this.locationText,
    this.geoPoint,
    required this.specialties,
    required this.primarySpecialty,
    required this.rating,
    required this.reviewCount,
    required this.bookingCount,
    required this.profileViewCount,
    required this.photoCount,
    required this.isAvailable,
    required this.isFeatured,
    required this.isVerified,
    required this.packages,
    required this.createdAt,
  });

  /// Two-letter initials derived from the display name.
  String get initials {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  /// Formatted starting price from cheapest package.
  String get startingPrice {
    if (packages.isEmpty) return '';
    final min = packages.map((p) => p.price).reduce((a, b) => a < b ? a : b);
    return '\$$min';
  }

  /// Deterministic gradient for card/avatar backgrounds when no photo is set.
  List<Color> get gradientColors {
    const pairs = [
      [Color(0xFF8E0000), Color(0xFFC62828)],
      [Color(0xFF4A0000), Color(0xFF880E0E)],
      [Color(0xFF880E4F), Color(0xFFAD1457)],
      [Color(0xFFC62828), Color(0xFF6B0000)],
      [Color(0xFF880E0E), Color(0xFF3D0000)],
      [Color(0xFF6D2533), Color(0xFFC2185B)],
      [Color(0xFF7B1FA2), Color(0xFFC62828)],
    ];
    final hash = uid.codeUnits.fold(0, (sum, c) => sum + c);
    return List<Color>.from(pairs[hash % pairs.length]);
  }

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'name': name,
        'photoUrl': photoUrl,
        'bio': bio,
        'locationText': locationText,
        'geoPoint': geoPoint,
        'specialties': specialties,
        'primarySpecialty': primarySpecialty,
        'rating': rating,
        'reviewCount': reviewCount,
        'bookingCount': bookingCount,
        'profileViewCount': profileViewCount,
        'photoCount': photoCount,
        'isAvailable': isAvailable,
        'isFeatured': isFeatured,
        'isVerified': isVerified,
        'packages': packages.map((p) => p.toMap()).toList(),
        'createdAt': FieldValue.serverTimestamp(),
      };

  factory PhotographerModel.fromMap(String uid, Map<String, dynamic> map) =>
      PhotographerModel(
        uid: uid,
        name: map['name'] as String? ?? '',
        photoUrl: map['photoUrl'] as String?,
        bio: map['bio'] as String? ?? '',
        locationText: map['locationText'] as String? ?? '',
        geoPoint: map['geoPoint'] as GeoPoint?,
        specialties: List<String>.from(map['specialties'] as List? ?? []),
        primarySpecialty: map['primarySpecialty'] as String? ?? '',
        rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
        reviewCount: (map['reviewCount'] as num?)?.toInt() ?? 0,
        bookingCount: (map['bookingCount'] as num?)?.toInt() ?? 0,
        profileViewCount: (map['profileViewCount'] as num?)?.toInt() ?? 0,
        photoCount: (map['photoCount'] as num?)?.toInt() ?? 0,
        isAvailable: map['isAvailable'] as bool? ?? true,
        isFeatured: map['isFeatured'] as bool? ?? false,
        isVerified: map['isVerified'] as bool? ?? false,
        packages: (map['packages'] as List<dynamic>? ?? [])
            .map((p) =>
                ServicePackageModel.fromMap(Map<String, dynamic>.from(p as Map)))
            .toList(),
        createdAt:
            (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );

  PhotographerModel copyWith({
    String? uid,
    String? name,
    String? photoUrl,
    String? bio,
    String? locationText,
    GeoPoint? geoPoint,
    List<String>? specialties,
    String? primarySpecialty,
    double? rating,
    int? reviewCount,
    int? bookingCount,
    int? profileViewCount,
    int? photoCount,
    bool? isAvailable,
    bool? isFeatured,
    bool? isVerified,
    List<ServicePackageModel>? packages,
    DateTime? createdAt,
  }) =>
      PhotographerModel(
        uid: uid ?? this.uid,
        name: name ?? this.name,
        photoUrl: photoUrl ?? this.photoUrl,
        bio: bio ?? this.bio,
        locationText: locationText ?? this.locationText,
        geoPoint: geoPoint ?? this.geoPoint,
        specialties: specialties ?? this.specialties,
        primarySpecialty: primarySpecialty ?? this.primarySpecialty,
        rating: rating ?? this.rating,
        reviewCount: reviewCount ?? this.reviewCount,
        bookingCount: bookingCount ?? this.bookingCount,
        profileViewCount: profileViewCount ?? this.profileViewCount,
        photoCount: photoCount ?? this.photoCount,
        isAvailable: isAvailable ?? this.isAvailable,
        isFeatured: isFeatured ?? this.isFeatured,
        isVerified: isVerified ?? this.isVerified,
        packages: packages ?? this.packages,
        createdAt: createdAt ?? this.createdAt,
      );
}
