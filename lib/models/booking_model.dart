import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/firebase_constants.dart';
import '../core/profile_initials.dart';

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
  final String? rescheduleNotes;
  final DateTime? rescheduledAt;
  final String? rescheduleRequestedBy;
  final DateTime? previousScheduledDate;
  final String? previousScheduledTime;
  final DateTime? confirmedAt;
  final String? cancelledBy;
  final String? cancellationReason;
  final String? reviewId;
  final DateTime? reviewedAt;
  final String? deliveryLink;
  final String? deliveryNote;
  final DateTime? deliveredAt;
  final DateTime? expiresAt;
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
    this.rescheduleNotes,
    this.rescheduledAt,
    this.rescheduleRequestedBy,
    this.previousScheduledDate,
    this.previousScheduledTime,
    this.confirmedAt,
    this.cancelledBy,
    this.cancellationReason,
    this.reviewId,
    this.reviewedAt,
    this.deliveryLink,
    this.deliveryNote,
    this.deliveredAt,
    this.expiresAt,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  String get clientInitials => ProfileInitials.fromName(clientName);

  String get photographerInitials =>
      ProfileInitials.fromName(photographerName);

  /// Calendar day of the shoot (time stripped).
  DateTime get scheduledDay =>
      DateTime(scheduledDate.year, scheduledDate.month, scheduledDate.day);

  /// Best-effort session start on [scheduledDay] using [scheduledTime] (e.g. "2:00 PM").
  /// Falls back to end-of-day when the label cannot be parsed so same-day bookings
  /// still behave sensibly in lists.
  DateTime get scheduledSessionStart {
    final day = scheduledDay;
    final parsed = _parseClockOnDay(day, scheduledTime);
    if (parsed != null) return parsed;
    return DateTime(day.year, day.month, day.day, 23, 59, 59);
  }

  /// Confirmed booking waiting for the other party to approve a new date/time.
  bool get isReschedulePending =>
      status == BookingStatus.requested &&
      previousScheduledDate != null &&
      rescheduleRequestedBy != null;

  /// Label for status chips — shows reschedule state instead of generic "Pending".
  String get statusBadgeLabel {
    if (isReschedulePending) return 'Reschedule Request';
    if (status == BookingStatus.inProgress &&
        deliveryLink != null &&
        deliveryLink!.isNotEmpty) {
      return 'Photos Delivered';
    }
    return status.displayName;
  }

  /// Confirmed shoots still in the future (Upcoming tab).
  /// Reschedule-pending bookings appear in the Requested tab instead.
  bool get isUpcoming {
    if (!scheduledSessionStart.isAfter(DateTime.now())) return false;
    return status == BookingStatus.confirmed;
  }

  bool get isPast =>
      status == BookingStatus.completed ||
      status == BookingStatus.cancelled ||
      status == BookingStatus.declined;

  bool get isActive =>
      status == BookingStatus.inProgress ||
      (status == BookingStatus.confirmed &&
          !scheduledSessionStart.isAfter(DateTime.now()));

  bool get hasReview => reviewId != null && reviewId!.isNotEmpty;

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
    'rescheduleNotes': rescheduleNotes,
    'rescheduledAt': rescheduledAt != null
        ? Timestamp.fromDate(rescheduledAt!)
        : null,
    'rescheduleRequestedBy': rescheduleRequestedBy,
    'previousScheduledDate': previousScheduledDate != null
        ? Timestamp.fromDate(previousScheduledDate!)
        : null,
    'previousScheduledTime': previousScheduledTime,
    'confirmedAt': confirmedAt != null
        ? Timestamp.fromDate(confirmedAt!)
        : null,
    'cancelledBy': cancelledBy,
    'cancellationReason': cancellationReason,
    'reviewId': reviewId,
    'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
    'deliveryLink': deliveryLink,
    'deliveryNote': deliveryNote,
    'deliveredAt': deliveredAt != null ? Timestamp.fromDate(deliveredAt!) : null,
    'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
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
        rescheduleNotes: map['rescheduleNotes'] as String?,
        rescheduledAt: (map['rescheduledAt'] as Timestamp?)?.toDate(),
        rescheduleRequestedBy: map['rescheduleRequestedBy'] as String?,
        previousScheduledDate:
            (map['previousScheduledDate'] as Timestamp?)?.toDate(),
        previousScheduledTime: map['previousScheduledTime'] as String?,
        confirmedAt: (map['confirmedAt'] as Timestamp?)?.toDate(),
        cancelledBy: map['cancelledBy'] as String?,
        cancellationReason: map['cancellationReason'] as String?,
        reviewId: map['reviewId'] as String?,
        reviewedAt: (map['reviewedAt'] as Timestamp?)?.toDate(),
        deliveryLink: map['deliveryLink'] as String?,
        deliveryNote: map['deliveryNote'] as String?,
        deliveredAt: (map['deliveredAt'] as Timestamp?)?.toDate(),
        expiresAt: (map['expiresAt'] as Timestamp?)?.toDate(),
        status: BookingStatusX.fromValue(map['status'] as String? ?? ''),
        createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      );

  /// Parses strings like "9:00 AM" / "12:30 PM" on [day]; returns null if unknown.
  static DateTime? _parseClockOnDay(DateTime day, String label) {
    final m = RegExp(
      r'^(\d{1,2}):(\d{2})\s*(AM|PM)$',
      caseSensitive: false,
    ).firstMatch(label.trim());
    if (m == null) return null;
    var hour = int.tryParse(m.group(1)!) ?? 0;
    final minute = int.tryParse(m.group(2)!) ?? 0;
    final ap = m.group(3)!.toUpperCase();
    if (ap == 'PM' && hour < 12) hour += 12;
    if (ap == 'AM' && hour == 12) hour = 0;
    return DateTime(day.year, day.month, day.day, hour, minute);
  }

  BookingModel copyWith({
    BookingStatus? status,
    DateTime? scheduledDate,
    String? scheduledTime,
    DateTime? updatedAt,
    String? notes,
    String? rescheduleNotes,
    DateTime? rescheduledAt,
    String? rescheduleRequestedBy,
    DateTime? previousScheduledDate,
    String? previousScheduledTime,
    DateTime? confirmedAt,
    String? cancelledBy,
    String? cancellationReason,
    String? reviewId,
    DateTime? reviewedAt,
    String? deliveryLink,
    String? deliveryNote,
    DateTime? deliveredAt,
    DateTime? expiresAt,
  }) => BookingModel(
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
    scheduledDate: scheduledDate ?? this.scheduledDate,
    scheduledTime: scheduledTime ?? this.scheduledTime,
    location: location,
    notes: notes ?? this.notes,
    rescheduleNotes: rescheduleNotes ?? this.rescheduleNotes,
    rescheduledAt: rescheduledAt ?? this.rescheduledAt,
    rescheduleRequestedBy: rescheduleRequestedBy ?? this.rescheduleRequestedBy,
    previousScheduledDate:
        previousScheduledDate ?? this.previousScheduledDate,
    previousScheduledTime:
        previousScheduledTime ?? this.previousScheduledTime,
    confirmedAt: confirmedAt ?? this.confirmedAt,
    cancelledBy: cancelledBy ?? this.cancelledBy,
    cancellationReason: cancellationReason ?? this.cancellationReason,
    reviewId: reviewId ?? this.reviewId,
    reviewedAt: reviewedAt ?? this.reviewedAt,
    deliveryLink: deliveryLink ?? this.deliveryLink,
    deliveryNote: deliveryNote ?? this.deliveryNote,
    deliveredAt: deliveredAt ?? this.deliveredAt,
    expiresAt: expiresAt ?? this.expiresAt,
    status: status ?? this.status,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
