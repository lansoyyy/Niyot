import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tracks which bookings the user has opened (read vs unread list styling).
class BookingViewTracker extends ChangeNotifier {
  BookingViewTracker._();

  static final BookingViewTracker instance = BookingViewTracker._();

  final Set<String> _viewedIds = {};
  String? _userId;
  bool _loaded = false;

  bool get isReady => _loaded;

  bool isViewed(String bookingId) => _viewedIds.contains(bookingId);

  Future<void> init(String userId) async {
    if (_userId == userId && _loaded) return;
    _userId = userId;
    _viewedIds.clear();
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_storageKey(userId)) ?? [];
    _viewedIds.addAll(stored);
    _loaded = true;
    notifyListeners();
  }

  Future<void> markViewed(String bookingId) async {
    await markViewedBatch([bookingId]);
  }

  Future<void> markViewedBatch(Iterable<String> bookingIds) async {
    var changed = false;
    for (final id in bookingIds) {
      if (_viewedIds.add(id)) changed = true;
    }
    if (!changed) return;
    notifyListeners();
    final uid = _userId;
    if (uid == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_storageKey(uid), _viewedIds.toList());
  }

  String _storageKey(String userId) => 'viewed_bookings_$userId';
}
