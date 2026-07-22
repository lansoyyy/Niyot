import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/app_colors.dart';
import '../../data/philippines_locations.dart';

/// Country (Philippines), searchable province, and searchable city dropdowns.
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
    final cityEnabled = province.isNotEmpty && cities.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Country'),
        SizedBox(height: dense ? 6 : 8),
        _staticField(
          value: PhilippinesLocations.countries.contains(country)
              ? country
              : PhilippinesLocations.countryName,
          icon: Icons.flag_outlined,
        ),
        if (showProvince) ...[
          SizedBox(height: dense ? 14 : 18),
          _label('Province / Region'),
          SizedBox(height: dense ? 6 : 8),
          _SearchableLocationField(
            value: province,
            hint: 'Select province',
            icon: Icons.map_outlined,
            options: PhilippinesLocations.provinces,
            dense: dense,
            onSelected: (selected) {
              onProvinceChanged(selected);
              onCityChanged('');
            },
          ),
        ],
        SizedBox(height: dense ? 14 : 18),
        _label('City / Municipality'),
        SizedBox(height: dense ? 6 : 8),
        if (!cityEnabled)
          _staticField(
            value: '',
            hint: province.isEmpty
                ? 'Select province first'
                : 'No cities for this province',
            icon: Icons.location_city_outlined,
            disabled: true,
          )
        else
          _SearchableLocationField(
            value: cities.contains(city) ? city : '',
            hint: 'Select city',
            icon: Icons.location_city_outlined,
            options: cities,
            dense: dense,
            onSelected: onCityChanged,
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

  Widget _staticField({
    required String value,
    required IconData icon,
    String? hint,
    bool disabled = false,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 12 : 16,
        vertical: dense ? 14 : 18,
      ),
      decoration: BoxDecoration(
        color: disabled ? const Color(0xFFF3F4F6) : const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF9E9E9E), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : (hint ?? ''),
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: value.isNotEmpty
                    ? const Color(0xFF1F2937)
                    : const Color(0xFFBDBDBD),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchableLocationField extends StatelessWidget {
  const _SearchableLocationField({
    required this.value,
    required this.hint,
    required this.icon,
    required this.options,
    required this.onSelected,
    this.dense = false,
  });

  final String value;
  final String hint;
  final IconData icon;
  final List<String> options;
  final ValueChanged<String> onSelected;
  final bool dense;

  Future<void> _openPicker(BuildContext context) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _LocationSearchSheet(
        title: hint,
        options: options,
        initialValue: value,
      ),
    );
    if (selected != null && selected.isNotEmpty) {
      onSelected(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasValue = value.isNotEmpty;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openPicker(context),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: dense ? 12 : 16,
            vertical: dense ? 14 : 18,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFFAFAFA),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF9E9E9E), size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  hasValue ? value : hint,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: hasValue
                        ? const Color(0xFF1F2937)
                        : const Color(0xFFBDBDBD),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Color(0xFF9E9E9E),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocationSearchSheet extends StatefulWidget {
  const _LocationSearchSheet({
    required this.title,
    required this.options,
    required this.initialValue,
  });

  final String title;
  final List<String> options;
  final String initialValue;

  @override
  State<_LocationSearchSheet> createState() => _LocationSearchSheetState();
}

class _LocationSearchSheetState extends State<_LocationSearchSheet> {
  late final TextEditingController _searchController;
  late List<String> _filtered;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _filtered = List<String>.from(widget.options);
    _searchController.addListener(_onQueryChanged);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onQueryChanged)
      ..dispose();
    super.dispose();
  }

  void _onQueryChanged() {
    final q = _searchController.text.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filtered = List<String>.from(widget.options);
      } else {
        _filtered = widget.options
            .where((o) => o.toLowerCase().contains(q))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.72,
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1A1A),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  style: GoogleFonts.poppins(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search…',
                    hintStyle: GoogleFonts.poppins(
                      fontSize: 14,
                      color: const Color(0xFFBDBDBD),
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: Color(0xFF9E9E9E),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF5F5F5),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _filtered.isEmpty
                    ? Center(
                        child: Text(
                          'No matches found',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: const Color(0xFF9E9E9E),
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filtered.length,
                        itemBuilder: (context, index) {
                          final option = _filtered[index];
                          final selected = option == widget.initialValue;
                          return ListTile(
                            dense: true,
                            title: _HighlightedText(
                              text: option,
                              query: _searchController.text.trim(),
                            ),
                            trailing: selected
                                ? const Icon(
                                    Icons.check_rounded,
                                    color: AppColors.primary,
                                    size: 20,
                                  )
                                : null,
                            onTap: () => Navigator.of(context).pop(option),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HighlightedText extends StatelessWidget {
  const _HighlightedText({required this.text, required this.query});

  final String text;
  final String query;

  @override
  Widget build(BuildContext context) {
    final baseStyle = GoogleFonts.poppins(
      fontSize: 14,
      color: const Color(0xFF1F2937),
    );
    final highlightStyle = GoogleFonts.poppins(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      color: AppColors.primary,
    );

    if (query.isEmpty) {
      return Text(text, style: baseStyle);
    }

    final lower = text.toLowerCase();
    final q = query.toLowerCase();
    final matchIndex = lower.indexOf(q);
    if (matchIndex < 0) {
      return Text(text, style: baseStyle);
    }

    final before = text.substring(0, matchIndex);
    final match = text.substring(matchIndex, matchIndex + q.length);
    final after = text.substring(matchIndex + q.length);

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: before, style: baseStyle),
          TextSpan(text: match, style: highlightStyle),
          TextSpan(text: after, style: baseStyle),
        ],
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
