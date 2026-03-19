import 'package:cloud_firestore/cloud_firestore.dart';

class PortfolioItemModel {
  final String id;
  final String photographerId;
  final String imageUrl;
  final String? thumbnailUrl;
  final String? caption;
  final List<String> tags;
  final DateTime createdAt;

  const PortfolioItemModel({
    required this.id,
    required this.photographerId,
    required this.imageUrl,
    this.thumbnailUrl,
    this.caption,
    required this.tags,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'photographerId': photographerId,
    'imageUrl': imageUrl,
    'thumbnailUrl': thumbnailUrl,
    'caption': caption,
    'tags': tags,
    'createdAt': FieldValue.serverTimestamp(),
  };

  factory PortfolioItemModel.fromMap(String id, Map<String, dynamic> map) =>
      PortfolioItemModel(
        id: id,
        photographerId: map['photographerId'] as String? ?? '',
        imageUrl: map['imageUrl'] as String? ?? '',
        thumbnailUrl: map['thumbnailUrl'] as String?,
        caption: map['caption'] as String?,
        tags: List<String>.from(map['tags'] as List? ?? []),
        createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
}
