/// Consistent two-character initials for avatars (first + last name, or first
/// two letters of a single name).
class ProfileInitials {
  ProfileInitials._();

  static String fromName(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      final w = parts[0];
      if (w.length >= 2) {
        return '${w[0]}${w[1]}'.toUpperCase();
      }
      return w[0].toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}
