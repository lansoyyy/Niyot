/// Philippine administrative divisions for dropdowns (country fixed to PH).
/// Cities/municipalities are grouped by province or highly urbanized city (HUC).
class PhilippinesLocations {
  PhilippinesLocations._();

  static const String countryName = 'Philippines';

  static const List<String> countries = [countryName];

  /// Maps province / HUC name → cities / municipalities for dropdowns.
  static const Map<String, List<String>> citiesByProvince = {
    'Metro Manila': [
      'Manila',
      'Quezon City',
      'Caloocan',
      'Las Piñas',
      'Makati',
      'Malabon',
      'Mandaluyong',
      'Marikina',
      'Muntinlupa',
      'Navotas',
      'Parañaque',
      'Pasay',
      'Pasig',
      'San Juan',
      'Taguig',
      'Valenzuela',
      'Pateros',
    ],
    'Rizal': [
      'Antipolo',
      'Angono',
      'Binangonan',
      'Cainta',
      'Rodriguez (Montalban)',
      'San Mateo',
      'Taytay',
      'Teresa',
    ],
    'Bulacan': [
      'Malolos',
      'Meycauayan',
      'San Jose del Monte',
      'Marilao',
      'Santa Maria',
      'Bocaue',
      'Angat',
    ],
    'Cavite': [
      'Bacoor',
      'Imus',
      'Dasmariñas',
      'Tagaytay',
      'General Trias',
      'Trece Martires',
      'Silang',
      'Tanza',
    ],
    'Laguna': [
      'Calamba',
      'San Pedro',
      'Biñan',
      'Santa Rosa',
      'Cabuyao',
      'Los Baños',
      'San Pablo',
    ],
    'Batangas': [
      'Batangas City',
      'Lipa',
      'Tanauan',
      'Nasugbu',
      'Santo Tomas',
    ],
    'Pampanga': [
      'Angeles',
      'San Fernando',
      'Mabalacat',
      'Apalit',
      'Mexico',
    ],
    'Cebu': [
      'Cebu City',
      'Lapu-Lapu',
      'Mandaue',
      'Talisay',
      'Toledo',
    ],
    'Davao del Sur': [
      'Davao City',
      'Digos',
      'Santa Cruz',
    ],
    'Ilocos Norte': [
      'Laoag',
      'Batac',
      'Pagudpud',
    ],
    'Isabela': [
      'Ilagan',
      'Santiago',
      'Cauayan',
    ],
    'Bicol (Camarines Sur)': [
      'Naga',
      'Iriga',
    ],
    'Negros Occidental': [
      'Bacolod',
      'Silay',
      'Talisay',
    ],
    'Zamboanga del Sur': [
      'Pagadian',
      'Zamboanga City',
    ],
    'Other / Not listed': ['Other'],
  };

  static List<String> get provinces {
    final keys = citiesByProvince.keys.toList();
    keys.sort((a, b) {
      if (a == 'Other / Not listed') return 1;
      if (b == 'Other / Not listed') return -1;
      return a.compareTo(b);
    });
    return keys;
  }

  static List<String> citiesForProvince(String? province) {
    if (province == null || province.isEmpty) return const [];
    return List<String>.from(citiesByProvince[province] ?? const []);
  }

  /// All city strings for venue autocomplete suggestions.
  static List<String> get allCityNames {
    final set = <String>{};
    for (final list in citiesByProvince.values) {
      set.addAll(list);
    }
    return set.toList()..sort();
  }

  static List<String> venueSuggestionsForQuery(String query, {int limit = 12}) {
    final q = query.trim().toLowerCase();
    if (q.length < 2) return const [];
    final out = <String>[];
    for (final name in allCityNames) {
      if (name.toLowerCase().contains(q)) {
        out.add(name);
        if (out.length >= limit) break;
      }
    }
    return out;
  }

  /// Builds a storage-friendly location line used elsewhere in the app.
  static String composeLocation({
    required String city,
    required String province,
    required String country,
  }) {
    final parts = [city.trim(), province.trim(), country.trim()]
        .where((s) => s.isNotEmpty)
        .toList();
    return parts.join(', ');
  }
}
