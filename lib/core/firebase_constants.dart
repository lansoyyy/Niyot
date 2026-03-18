/// Canonical Firestore collection names and Firebase Storage path helpers.
/// Use these everywhere instead of raw strings to prevent typos and ease
/// future renames.
class FirebaseCollections {
  FirebaseCollections._();

  // Top-level collections
  static const String users = 'users';
  static const String photographers = 'photographers';
  static const String bookings = 'bookings';
  static const String conversations = 'conversations';
  static const String paymentRecords = 'payment_records';
  static const String verificationSubmissions = 'verification_submissions';

  // Subcollections (used with parent doc reference)
  static const String messages = 'messages';
  static const String notifications = 'notifications';
  static const String paymentMethods = 'payment_methods';
  static const String portfolio = 'portfolio';
  static const String reviews = 'reviews';
  static const String availability = 'availability';
}

class FirebaseStoragePaths {
  FirebaseStoragePaths._();

  static String profileImage(String uid) => 'profile_images/$uid.jpg';

  static String portfolioItem(String uid, String itemId) =>
      'portfolio/$uid/$itemId.jpg';

  static String chatAttachment(String conversationId, String fileName) =>
      'chat_attachments/$conversationId/$fileName';

  static String verificationDoc(String uid, String docType) =>
      'verification/$uid/$docType';

  static String paymentProof(String paymentId) =>
      'payment_proofs/$paymentId';
}

/// Booking state values stored in Firestore.
class BookingStatuses {
  BookingStatuses._();
  static const String requested = 'requested';
  static const String confirmed = 'confirmed';
  static const String declined = 'declined';
  static const String inProgress = 'in_progress';
  static const String completed = 'completed';
  static const String cancelled = 'cancelled';
  static const String paymentPending = 'payment_pending';
}

/// Payment state values stored in Firestore.
class PaymentStatuses {
  PaymentStatuses._();
  static const String pending = 'pending';
  static const String completed = 'completed';
  static const String refunded = 'refunded';
  static const String failed = 'failed';
}

/// Notification type values stored in Firestore.
class NotificationTypes {
  NotificationTypes._();
  static const String bookingConfirmed = 'booking_confirmed';
  static const String bookingDeclined = 'booking_declined';
  static const String bookingRequest = 'booking_request';
  static const String newMessage = 'new_message';
  static const String paymentReceived = 'payment_received';
  static const String reviewLeft = 'review_left';
  static const String profileView = 'profile_view';
  static const String system = 'system';
}

/// Verification status values stored in Firestore.
class VerificationStatuses {
  VerificationStatuses._();
  static const String unverified = 'unverified';
  static const String pending = 'pending';
  static const String verified = 'verified';
  static const String rejected = 'rejected';
}
