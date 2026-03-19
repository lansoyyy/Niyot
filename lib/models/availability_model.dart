import 'package:cloud_firestore/cloud_firestore.dart';

class TimeSlotModel {
  final String time;
  final bool isAvailable;
  final String? bookedByBookingId;

  const TimeSlotModel({
    required this.time,
    required this.isAvailable,
    this.bookedByBookingId,
  });

  Map<String, dynamic> toMap() => {
    'time': time,
    'isAvailable': isAvailable,
    'bookedByBookingId': bookedByBookingId,
  };

  factory TimeSlotModel.fromMap(Map<String, dynamic> map) => TimeSlotModel(
    time: map['time'] as String? ?? '',
    isAvailable: map['isAvailable'] as bool? ?? true,
    bookedByBookingId: map['bookedByBookingId'] as String?,
  );

  TimeSlotModel copyWith({bool? isAvailable, String? bookedByBookingId}) =>
      TimeSlotModel(
        time: time,
        isAvailable: isAvailable ?? this.isAvailable,
        bookedByBookingId: bookedByBookingId ?? this.bookedByBookingId,
      );
}

class AvailabilityModel {
  final String photographerId;
  final DateTime date;
  final List<TimeSlotModel> slots;

  /// Document ID format: yyyy-MM-dd
  static String docId(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  const AvailabilityModel({
    required this.photographerId,
    required this.date,
    required this.slots,
  });

  Map<String, dynamic> toMap() => {
    'photographerId': photographerId,
    'date': Timestamp.fromDate(date),
    'slots': slots.map((s) => s.toMap()).toList(),
  };

  factory AvailabilityModel.fromMap(Map<String, dynamic> map) =>
      AvailabilityModel(
        photographerId: map['photographerId'] as String? ?? '',
        date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
        slots: (map['slots'] as List<dynamic>? ?? [])
            .map(
              (s) => TimeSlotModel.fromMap(Map<String, dynamic>.from(s as Map)),
            )
            .toList(),
      );

  /// Returns a default set of time slots for a brand new availability day.
  static List<TimeSlotModel> defaultSlots() => [
    const TimeSlotModel(time: '9:00 AM', isAvailable: true),
    const TimeSlotModel(time: '10:00 AM', isAvailable: true),
    const TimeSlotModel(time: '11:00 AM', isAvailable: true),
    const TimeSlotModel(time: '12:00 PM', isAvailable: true),
    const TimeSlotModel(time: '1:00 PM', isAvailable: true),
    const TimeSlotModel(time: '2:00 PM', isAvailable: true),
    const TimeSlotModel(time: '3:00 PM', isAvailable: true),
    const TimeSlotModel(time: '4:00 PM', isAvailable: true),
  ];
}
