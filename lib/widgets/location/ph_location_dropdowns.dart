import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/philippines_locations.dart';

/// Country (Philippines), province/HUC, and city dropdowns for forms.
class PhLocationDropdowns extends StatelessWidget {
  const PhLocationDropdowns({
    super.key,
    required this.country,
    required this.province,
    required this.city,
    required this.onCountryChanged,
    required this.onProvinceChanged,
    required this.onCityChanged,
    this.dense = false,
    this.showProvince = true,
  });

  final String country;
  final String province;
  final String city;
  final ValueChanged<String> onCountryChanged;
  final ValueChanged<String> onProvinceChanged;
  final ValueChanged<String> onCityChanged;
  final bool dense;
  final bool showProvince;

  @override
  Widget build(BuildContext context) {
    final cities = PhilippinesLocations.citiesForProvince(province);
    final safeCity = cities.contains(city) ? city : (cities.isNotEmpty ? cities.first : '');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Country'),
        SizedBox(height: dense ? 6 : 8),
        _dropdown<String>(
          value: PhilippinesLocations.countries.contains(country)
              ? country
              : PhilippinesLocations.countryName,
          items: PhilippinesLocations.countries
              .map(
                (c) => DropdownMenuItem(
                  value: c,
                  child: Text(c, style: GoogleFonts.poppins(fontSize: 14)),
                ),
              )
              .toList(),
          onChanged: (v) {
            if (v != null) onCountryChanged(v);
          },
          icon: Icons.flag_outlined,
        ),
        if (showProvince) ...[
          SizedBox(height: dense ? 14 : 18),
          _label('Province / Region'),
          SizedBox(height: dense ? 6 : 8),
          _dropdown<String>(
            value: province.isNotEmpty &&
                    PhilippinesLocations.provinces.contains(province)
                ? province
                : null,
            hint: 'Select province',
            items: PhilippinesLocations.provinces
                .map(
                  (p) => DropdownMenuItem(
                    value: p,
                    child: Text(p, style: GoogleFonts.poppins(fontSize: 14)),
                  ),
                )
                .toList(),
            onChanged: (v) {
              if (v != null) {
                onProvinceChanged(v);
                final next = PhilippinesLocations.citiesForProvince(v);
                if (next.isNotEmpty) onCityChanged(next.first);
              }
            },
            icon: Icons.map_outlined,
          ),
        ],
        SizedBox(height: dense ? 14 : 18),
        _label('City / Municipality'),
        SizedBox(height: dense ? 6 : 8),
        if (province.isEmpty || cities.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.location_city_outlined,
                  color: Color(0xFF9E9E9E),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    province.isEmpty
                        ? 'Select province first'
                        : 'No preset cities — pick Other',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: const Color(0xFFBDBDBD),
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          _dropdown<String>(
            value: safeCity.isNotEmpty ? safeCity : null,
            hint: 'Select city',
            items: cities
                .map(
                  (c) => DropdownMenuItem(
                    value: c,
                    child: Text(c, style: GoogleFonts.poppins(fontSize: 14)),
                  ),
                )
                .toList(),
            onChanged: (v) {
              if (v != null) onCityChanged(v);
            },
            icon: Icons.location_city_outlined,
          ),
      ],
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF374151),
      ),
    );
  }

  Widget _dropdown<T>({
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?)? onChanged,
    required IconData icon,
    String? hint,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      padding: EdgeInsets.symmetric(horizontal: dense ? 4 : 8),
      child: DropdownButtonFormField<T>(
        value: value,
        isExpanded: true,
        hint: hint != null
            ? Text(hint, style: GoogleFonts.poppins(fontSize: 14))
            : null,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: const Color(0xFF9E9E9E), size: 20),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: dense ? 4 : 8,
            vertical: dense ? 12 : 16,
          ),
        ),
        dropdownColor: Colors.white,
        style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF1F2937)),
        items: items,
        onChanged: onChanged,
      ),
    );
  }
}

/// Venue / street address with lightweight suggestions (typing filters PH cities).
class VenueAddressField extends StatefulWidget {
  const VenueAddressField({
    super.key,
    required this.controller,
    this.hint = 'Street, building, landmark…',
  });

  final TextEditingController controller;
  final String hint;

  @override
  State<VenueAddressField> createState() => _VenueAddressFieldState();
}

class _VenueAddressFieldState extends State<VenueAddressField> {
  List<String> _suggestions = const [];

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onText);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onText);
    super.dispose();
  }

  void _onText() {
    final q = widget.controller.text;
    setState(() {
      _suggestions = PhilippinesLocations.venueSuggestionsForQuery(q);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: TextField(
            controller: widget.controller,
            maxLines: 2,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF1F2937),
            ),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: GoogleFonts.poppins(
                fontSize: 13,
                color: const Color(0xFFBDBDBD),
              ),
              prefixIcon: const Icon(
                Icons.place_rounded,
                color: Color(0xFF9E9E9E),
                size: 20,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
        if (_suggestions.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'Suggestions — tap to insert',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF9E9E9E),
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _suggestions
                .map(
                  (s) => ActionChip(
                    label: Text(
                      s,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF374151),
                      ),
                    ),
                    backgroundColor: const Color(0xFFF5F5F5),
                    side: const BorderSide(color: Color(0xFFE5E7EB)),
                    onPressed: () {
                      final cur = widget.controller.text.trim();
                      widget.controller.text = cur.isEmpty ? s : '$cur, $s';
                      widget.controller.selection = TextSelection.collapsed(
                        offset: widget.controller.text.length,
                      );
                      setState(() => _suggestions = []);
                    },
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }
}
