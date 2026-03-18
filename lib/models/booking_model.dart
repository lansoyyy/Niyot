import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/firebase_constants.dart';

enum BookingStatus {
  requested,
  confirmed,
  declined,
  inProgress,
  completed,
  cancelled,
  paymentPending,
}

extension BookingStatusX on BookingStatus {
  String get value {
    switch (this) {
      case BookingStatus.requested:
        return BookingStatuses.requested;
      case BookingStatus.confirmed:
        return BookingStatuses.confirmed;
      case BookingStatus.declined:
        return BookingStatuses.declined;
      case BookingStatus.inProgress:
        return BookingStatuses.inProgress;
      case BookingStatus.completed:
        return BookingStatuses.completed;
      case BookingStatus.cancelled:
        return BookingStatuses.cancelled;
      case BookingStatus.paymentPending:
        return BookingStatuses.paymentPending;
    }
  }

  String get displayName {
    switch (this) {
      case BookingStatus.requested:
        return 'Pending';
      case BookingStatus.confirmed:
        return 'Confirmed';
      case BookingStatus.declined:
        return 'Declined';
      case BookingStatus.inProgress:
        return 'In Progress';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.cancelled:
        return 'Cancelled';
      case BookingStatus.paymentPending:
        return 'Payment Pending';
    }
  }

  static BookingStatus fromValue(String value) {
    switch (value) {
      case BookingStatuses.confirmed:
        return BookingStatus.confirmed;
      case BookingStatuses.declined:
        return BookingStatus.declined;
      case BookingStatuses.inProgress:
        return BookingStatus.inProgress;
      case BookingStatuses.completed:
        return BookingStatus.completed;
      case BookingStatuses.cancelled:
        return BookingStatus.cancelled;
      case BookingStatuses.paymentPending:
        return BookingStatus.paymentPending;
      default:
        return BookingStatus.requested;
    }
  }
}

class BookingModel {
  final String id;
  final String clientId;
  final String clientName;
  final String? clientPhotoUrl;
  final String photographerId;
  final String photographerName;
  final String? photographerPhotoUrl;
  final String packageName;
  final int packagePrice;
  final String packageDuration;
  final DateTime scheduledDate;
  final String scheduledTime;
  final String location;
  final String? notes;
  final BookingStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const BookingModel({
    required this.id,
    required this.clientId,
    required this.clientName,
    this.clientPhotoUrl,
    required this.photographerId,
    required this.photographerName,
    this.photographerPhotoUrl,
    required this.packageName,
    required this.packagePrice,
    required this.packageDuration,
    required this.scheduledDate,
    required this.scheduledTime,
    required this.location,
    this.notes,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  String get clientInitials {
    final parts = clientName.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  String get photographerInitials {
    final parts = photographerName.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  bool get isUpcoming =>
      status == BookingStatus.confirmed &&
      scheduledDate.isAfter(DateTime.now());

  bool get isPast =>
      status == BookingStatus.completed ||
      status == BookingStatus.cancelled ||
      status == BookingStatus.declined;

  Map<String, dynamic> toMap() => {
        'clientId': clientId,
        'clientName': clientName,
        'clientPhotoUrl': clientPhotoUrl,
        'photographerId': photographerId,
        'photographerName': photographerName,
        'photographerPhotoUrl': photographerPhotoUrl,
        'packageName': packageName,
        'packagePrice': packagePrice,
        'packageDuration': packageDuration,
        'scheduledDate': Timestamp.fromDate(scheduledDate),
        'scheduledTime': scheduledTime,
        'location': location,
        'notes': notes,
        'status': status.value,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

  factory BookingModel.fromMap(String id, Map<String, dynamic> map) =>
      BookingModel(
        id: id,
        clientId: map['clientId'] as String? ?? '',
        clientName: map['clientName'] as String? ?? '',
        clientPhotoUrl: map['clientPhotoUrl'] as String?,
        photographerId: map['photographerId'] as String? ?? '',
        photographerName: map['photographerName'] as String? ?? '',
        photographerPhotoUrl: map['photographerPhotoUrl'] as String?,
        packageName: map['packageName'] as String? ?? '',
        packagePrice: (map['packagePrice'] as num?)?.toInt() ?? 0,
        packageDuration: map['packageDuration'] as String? ?? '',
        scheduledDate:
            (map['scheduledDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
        scheduledTime: map['scheduledTime'] as String? ?? '',
        location: map['location'] as String? ?? '',
        notes: map['notes'] as String?,
        status: BookingStatusX.fromValue(map['status'] as String? ?? ''),
        createdAt:
            (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      );

  BookingModel copyWith({BookingStatus? status, DateTime? updatedAt}) =>
      BookingModel(
        id: id,
        clientId: clientId,
        clientName: clientName,
        clientPhotoUrl: clientPhotoUrl,
        photographerId: photographerId,
        photographerName: photographerName,
        photographerPhotoUrl: photographerPhotoUrl,
        packageName: packageName,
        packagePrice: packagePrice,
        packageDuration: packageDuration,
        scheduledDate: scheduledDate,
        scheduledTime: scheduledTime,
        location: location,
        notes: notes,
        status: status ?? this.status,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
