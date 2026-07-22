"""Extract province -> cities map from juan_million app_constants.dart."""
from __future__ import annotations

import re
from collections import defaultdict
from pathlib import Path

SRC = Path(r"D:\AV\juan_million\lib\utlis\app_constants.dart")
OUT = Path(r"D:\Flutter Projects\niyot\lib\data\philippines_locations.dart")

NCR_ALIASES = {
    "NATIONAL CAPITAL REGION - MANILA",
    "NATIONAL CAPITAL REGION - FIRST DISTRICT",
    "NATIONAL CAPITAL REGION - SECOND DISTRICT",
    "NATIONAL CAPITAL REGION - THIRD DISTRICT",
    "NATIONAL CAPITAL REGION - FOURTH DISTRICT",
    "CITY OF MANILA",
    "TAGUIG - PATEROS",
}


def title_case(name: str) -> str:
    # Keep acronyms / special tokens readable
    small = {"OF", "DEL", "DE", "LA", "LAS", "LOS", "Y", "AND", "THE"}
    parts = []
    for raw in name.replace("_", " ").split():
        upper = raw.upper()
        if upper in {"NCR", "HUC", "IRR"}:
            parts.append(upper)
        elif upper in small and parts:
            parts.append(upper.lower())
        else:
            # Handle hyphenated names
            segs = []
            for seg in raw.split("-"):
                if not seg:
                    continue
                segs.append(seg[:1].upper() + seg[1:].lower() if len(seg) > 1 else seg.upper())
            parts.append("-".join(segs))
    return " ".join(parts)


def normalize_province(name: str) -> str:
    n = name.strip().upper()
    if n in NCR_ALIASES or "NATIONAL CAPITAL" in n or n.startswith("NCR"):
        return "Metro Manila"
    if n in {"TAGUIG - PATEROS", "TAGUIG-PATEROS"}:
        return "Metro Manila"
    return title_case(n)


def main() -> None:
    text = SRC.read_text(encoding="utf-8")
    munis = re.findall(
        r'Municipality\(\s*id:\s*"([^"]+)",\s*name:\s*"([^"]+)",\s*provinceName:\s*"([^"]+)"',
        text,
    )
    by_prov: dict[str, set[str]] = defaultdict(set)
    for _id, city_name, prov_name in munis:
        prov = normalize_province(prov_name)
        city = title_case(city_name)
        by_prov[prov].add(city)

    # Ensure Metro Manila common cities if missing
    by_prov["Metro Manila"].update(
        {
            "Manila",
            "Quezon City",
            "Caloocan",
            "Las Piñas",
            "Makati",
            "Malabon",
            "Mandaluyong",
            "Marikina",
            "Muntinlupa",
            "Navotas",
            "Parañaque",
            "Pasay",
            "Pasig",
            "San Juan",
            "Taguig",
            "Valenzuela",
            "Pateros",
        }
    )
    by_prov["Other / Not listed"].add("Other")

    sorted_provs = sorted(by_prov.keys(), key=lambda p: (p == "Other / Not listed", p))
    print(f"provinces={len(sorted_provs)} cities={sum(len(by_prov[p]) for p in sorted_provs)}")

    lines: list[str] = []
    lines.append('/// Philippine administrative divisions for dropdowns (country fixed to PH).')
    lines.append('/// Generated from juan_million PSGC municipality data (province → cities).')
    lines.append('class PhilippinesLocations {')
    lines.append('  PhilippinesLocations._();')
    lines.append('')
    lines.append("  static const String countryName = 'Philippines';")
    lines.append('')
    lines.append('  static const List<String> countries = [countryName];')
    lines.append('')
    lines.append('  /// Maps province / HUC name → cities / municipalities for dropdowns.')
    lines.append('  static const Map<String, List<String>> citiesByProvince = {')
    for prov in sorted_provs:
        cities = sorted(by_prov[prov])
        lines.append(f"    '{_escape(prov)}': [")
        for city in cities:
            lines.append(f"      '{_escape(city)}',")
        lines.append('    ],')
    lines.append('  };')
    lines.append('')
    lines.append('  static List<String> get provinces {')
    lines.append('    final keys = citiesByProvince.keys.toList();')
    lines.append('    keys.sort((a, b) {')
    lines.append("      if (a == 'Other / Not listed') return 1;")
    lines.append("      if (b == 'Other / Not listed') return -1;")
    lines.append('      return a.compareTo(b);')
    lines.append('    });')
    lines.append('    return keys;')
    lines.append('  }')
    lines.append('')
    lines.append('  static List<String> citiesForProvince(String province) {')
    lines.append('    if (province.isEmpty) return const [];')
    lines.append('    return List<String>.from(citiesByProvince[province] ?? const []);')
    lines.append('  }')
    lines.append('')
    lines.append('  static List<String> get allCityNames {')
    lines.append('    final set = <String>{};')
    lines.append('    for (final cities in citiesByProvince.values) {')
    lines.append('      set.addAll(cities);')
    lines.append('    }')
    lines.append('    return set.toList()..sort();')
    lines.append('  }')
    lines.append('')
    lines.append('  static List<String> venueSuggestionsForQuery(String query, {int limit = 8}) {')
    lines.append('    final q = query.trim().toLowerCase();')
    lines.append('    if (q.length < 2) return const [];')
    lines.append('    final matches = <String>[];')
    lines.append('    for (final city in allCityNames) {')
    lines.append('      if (city.toLowerCase().contains(q)) {')
    lines.append('        matches.add(city);')
    lines.append('        if (matches.length >= limit) break;')
    lines.append('      }')
    lines.append('    }')
    lines.append('    return matches;')
    lines.append('  }')
    lines.append('')
    lines.append('  static String composeLocation({')
    lines.append('    required String city,')
    lines.append('    required String province,')
    lines.append('    String country = countryName,')
    lines.append('  }) {')
    lines.append('    final parts = [city, province, country]')
    lines.append("        .map((e) => e.trim())")
    lines.append("        .where((e) => e.isNotEmpty)")
    lines.append('        .toList();')
    lines.append("    return parts.join(', ');")
    lines.append('  }')
    lines.append('}')
    lines.append('')

    OUT.write_text('\n'.join(lines), encoding='utf-8')
    print(f'wrote {OUT}')


def _escape(s: str) -> str:
    return s.replace("\\", "\\\\").replace("'", "\\'")


if __name__ == "__main__":
    main()
