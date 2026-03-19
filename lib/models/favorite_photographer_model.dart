import 'package:cloud_firestore/cloud_firestore.dart';

class FavoritePhotographerModel {
  final String photographerId;
  final String name;
  final String? photoUrl;
  final String primarySpecialty;
  final String locationText;
  final DateTime createdAt;

  const FavoritePhotographerModel({
    required this.photographerId,
    required this.name,
    this.photoUrl,
    required this.primarySpecialty,
    required this.locationText,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'photographerId': photographerId,
    'name': name,
    'photoUrl': photoUrl,
    'primarySpecialty': primarySpecialty,
    'locationText': locationText,
    'createdAt': FieldValue.serverTimestamp(),
  };

  factory FavoritePhotographerModel.fromMap(
    String photographerId,
    Map<String, dynamic> map,
  ) {
    return FavoritePhotographerModel(
      photographerId: photographerId,
      name: map['name'] as String? ?? '',
      photoUrl: map['photoUrl'] as String?,
      primarySpecialty: map['primarySpecialty'] as String? ?? '',
      locationText: map['locationText'] as String? ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
