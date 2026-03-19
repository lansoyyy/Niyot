import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import '../../models/photographer_model.dart';
import '../../models/user_model.dart';
import '../../services/photographer_service.dart';
import '../../services/user_service.dart';
import '../photographer/photographer_profile_screen.dart';

class MapViewScreen extends StatefulWidget {
  const MapViewScreen({
    super.key,
    this.initialCategory,
    this.initialSearchQuery,
    this.availableOnly = false,
  });

  final String? initialCategory;
  final String? initialSearchQuery;
  final bool availableOnly;

  @override
  State<MapViewScreen> createState() => _MapViewScreenState();
}

class _MapViewScreenState extends State<MapViewScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  double _currentZoom = 13.0;
  String _selectedCategory = 'All';
  List<PhotographerModel> _photographers = [];
  PhotographerModel? _selectedPhotographer;
  bool _isLoading = true;
  bool _availableOnly = false;
  String? _preferredLocation;
  LatLng? _initialCenter;

  final List<String> _categories = [
    'All',
    'Portrait',
    'Wedding',
    'Event',
    'Commercial',
    'Fashion',
  ];

  @override
  void initState() {
    super.initState();
    _selectedCategory =
        widget.initialCategory != null &&
            _categories.contains(widget.initialCategory)
        ? widget.initialCategory!
        : 'All';
    _availableOnly = widget.availableOnly;
    if (widget.initialSearchQuery != null &&
        widget.initialSearchQuery!.trim().isNotEmpty) {
      _searchController.text = widget.initialSearchQuery!.trim();
    }
    _searchController.addListener(() {
      if (!mounted) {
        return;
      }
      final selectedPhotographer = _selectedPhotographer;
      if (selectedPhotographer != null &&
          !_filteredPhotographers.any(
            (photographer) => photographer.uid == selectedPhotographer.uid,
          )) {
        setState(() => _selectedPhotographer = null);
        return;
      }
      setState(() {});
    });
    _loadPhotographers();
  }

  Future<void> _loadPhotographers() async {
    try {
      final results = await Future.wait<Object?>([
        PhotographerService().getPhotographers(limit: 100),
        UserService().fetchCurrentUser(),
      ]);
      final photographers = (results[0]! as List<PhotographerModel>)
          .where((photographer) => photographer.geoPoint != null)
          .toList();
      final user = results[1] as UserModel?;
      final preferredLocation = user?.location;
      final initialCenter = _computeMapCenter(
        _prioritizeByPreferredLocation(photographers, preferredLocation),
      );
      if (mounted) {
        setState(() {
          _photographers = photographers;
          _preferredLocation = preferredLocation;
          _initialCenter = initialCenter;
          _isLoading = false;
        });
        if (initialCenter != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _mapController.move(initialCenter, _currentZoom);
            }
          });
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  List<PhotographerModel> get _filteredPhotographers {
    final query = _searchController.text.trim().toLowerCase();
    var filtered = List<PhotographerModel>.from(_photographers);

    if (_selectedCategory != 'All') {
      filtered = filtered
          .where(
            (photographer) =>
                photographer.specialties.any(
                  (specialty) =>
                      specialty.toLowerCase() ==
                      _selectedCategory.toLowerCase(),
                ) ||
                photographer.primarySpecialty.toLowerCase() ==
                    _selectedCategory.toLowerCase(),
          )
          .toList();
    }

    if (_availableOnly) {
      filtered = filtered
          .where((photographer) => photographer.isAvailable)
          .toList();
    }

    if (query.isNotEmpty) {
      filtered = filtered
          .where(
            (photographer) =>
                photographer.name.toLowerCase().contains(query) ||
                photographer.locationText.toLowerCase().contains(query) ||
                photographer.primarySpecialty.toLowerCase().contains(query) ||
                photographer.specialties.any(
                  (specialty) => specialty.toLowerCase().contains(query),
                ),
          )
          .toList();
    }

    return _prioritizeByPreferredLocation(filtered, _preferredLocation);
  }

  List<PhotographerModel> _prioritizeByPreferredLocation(
    List<PhotographerModel> photographers,
    String? preferredLocation,
  ) {
    if (!_hasMeaningfulLocation(preferredLocation)) {
      return photographers;
    }

    final sorted = List<PhotographerModel>.from(photographers)
      ..sort((left, right) {
        final leftMatches = _locationsMatch(
          left.locationText,
          preferredLocation!,
        );
        final rightMatches = _locationsMatch(
          right.locationText,
          preferredLocation,
        );
        if (leftMatches == rightMatches) {
          return 0;
        }
        return leftMatches ? -1 : 1;
      });
    return sorted;
  }

  LatLng? _computeMapCenter(List<PhotographerModel> photographers) {
    if (photographers.isEmpty) {
      return null;
    }

    var totalLatitude = 0.0;
    var totalLongitude = 0.0;

    for (final photographer in photographers) {
      final point = photographer.geoPoint!;
      totalLatitude += point.latitude;
      totalLongitude += point.longitude;
    }

    return LatLng(
      totalLatitude / photographers.length,
      totalLongitude / photographers.length,
    );
  }

  void _recenterMap() {
    final center = _computeMapCenter(
      _selectedPhotographer != null
          ? [_selectedPhotographer!]
          : _filteredPhotographers,
    );
    if (center == null) {
      return;
    }
    _mapController.move(center, _currentZoom);
  }

  bool _hasMeaningfulLocation(String? value) =>
      value != null && value.trim().isNotEmpty;

  bool _locationsMatch(String left, String right) {
    final normalizedLeft = _normalizeLocation(left);
    final normalizedRight = _normalizeLocation(right);
    if (normalizedLeft == null || normalizedRight == null) {
      return false;
    }

    final leftParts = normalizedLeft.split(',').map((part) => part.trim());
    final rightParts = normalizedRight.split(',').map((part) => part.trim());
    return leftParts.any(
          (part) => part.isNotEmpty && normalizedRight.contains(part),
        ) ||
        rightParts.any(
          (part) => part.isNotEmpty && normalizedLeft.contains(part),
        );
  }

  String? _normalizeLocation(String? value) {
    if (value == null) {
      return null;
    }
    final normalized = value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9,\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return normalized.isEmpty ? null : normalized;
  }

  Future<void> _showFilterSheet() async {
    var tempCategory = _selectedCategory;
    var tempAvailableOnly = _availableOnly;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5E7EB),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Map Filters',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _categories.map((category) {
                        final isSelected = category == tempCategory;
                        return ChoiceChip(
                          label: Text(category),
                          selected: isSelected,
                          selectedColor: const Color(0xFFC62828),
                          backgroundColor: const Color(0xFFF5F5F5),
                          labelStyle: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF6B7280),
                          ),
                          side: BorderSide(
                            color: isSelected
                                ? const Color(0xFFC62828)
                                : const Color(0xFFE5E7EB),
                          ),
                          onSelected: (_) {
                            setModalState(() => tempCategory = category);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      activeColor: const Color(0xFFC62828),
                      value: tempAvailableOnly,
                      title: Text(
                        'Available photographers only',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF374151),
                        ),
                      ),
                      onChanged: (value) {
                        setModalState(() => tempAvailableOnly = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(sheetContext).pop();
                          setState(() {
                            _selectedCategory = tempCategory;
                            _availableOnly = tempAvailableOnly;
                            if (_selectedPhotographer != null &&
                                !_filteredPhotographers.any(
                                  (photographer) =>
                                      photographer.uid ==
                                      _selectedPhotographer!.uid,
                                )) {
                              _selectedPhotographer = null;
                            }
                          });
                          _recenterMap();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC62828),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          'Apply Filters',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFC62828)),
        ),
      );
    }

    if (_photographers.isEmpty || _initialCenter == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1A1A1A),
          elevation: 0,
          title: Text(
            'Map View',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A1A),
            ),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'No photographers with saved map coordinates are available yet.',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF6B7280),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _initialCenter!,
              initialZoom: _currentZoom,
              minZoom: 10,
              maxZoom: 18,
              onTap: (tapPosition, point) {
                setState(() => _selectedPhotographer = null);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.algovision.niyot',
              ),
              // Markers
              MarkerLayer(
                markers: _filteredPhotographers.map((photographer) {
                  final gp = photographer.geoPoint!;
                  final position = LatLng(gp.latitude, gp.longitude);
                  final isSelected =
                      _selectedPhotographer?.uid == photographer.uid;
                  return Marker(
                    point: position,
                    width: isSelected ? 60 : 45,
                    height: isSelected ? 60 : 45,
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selectedPhotographer = photographer);
                        _mapController.move(position, 14);
                      },
                      child: _buildMarker(photographer, isSelected),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          // Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.95),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                  stops: const [0.0, 1.0],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                  child: Column(
                    children: [
                      // Search bar
                      Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 14),
                            const Icon(
                              Icons.search_rounded,
                              color: Color(0xFFBDBDBD),
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                onSubmitted: (_) => _recenterMap(),
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: const Color(0xFF1F2937),
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Search name, style, location...',
                                  hintStyle: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: const Color(0xFFBDBDBD),
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: _showFilterSheet,
                              child: Container(
                                margin: const EdgeInsets.all(6),
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFEBEE),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.tune_rounded,
                                  color: Color(0xFFC62828),
                                  size: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Category chips
                      SizedBox(
                        height: 36,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _categories.length,
                          itemBuilder: (context, index) {
                            final category = _categories[index];
                            final isSelected = category == _selectedCategory;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedCategory = category;
                                  if (_selectedPhotographer != null &&
                                      !_filteredPhotographers.any(
                                        (photographer) =>
                                            photographer.uid ==
                                            _selectedPhotographer!.uid,
                                      )) {
                                    _selectedPhotographer = null;
                                  }
                                });
                                _recenterMap();
                              },
                              child: Container(
                                margin: EdgeInsets.only(
                                  right: index < _categories.length - 1 ? 8 : 0,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFFC62828)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: const Color(
                                              0xFFC62828,
                                            ).withValues(alpha: 0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.05,
                                            ),
                                            blurRadius: 4,
                                            offset: const Offset(0, 1),
                                          ),
                                        ],
                                ),
                                child: Text(
                                  category,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? Colors.white
                                        : const Color(0xFF374151),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_filteredPhotographers.isEmpty)
            Positioned(
              left: 16,
              right: 16,
              top: 170,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.search_off_rounded,
                      color: Color(0xFFC62828),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'No photographers match the current map filters.',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF374151),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // Bottom sheet
          if (_selectedPhotographer != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildBottomSheet(_selectedPhotographer!),
            ),
          // Zoom controls
          Positioned(
            right: 16,
            bottom: _selectedPhotographer != null ? 280 : 20,
            child: Column(
              children: [
                _buildZoomButton(
                  icon: Icons.add_rounded,
                  onTap: () {
                    setState(() {
                      _currentZoom = (_currentZoom + 1).clamp(10.0, 18.0);
                      _mapController.move(
                        _mapController.camera.center,
                        _currentZoom,
                      );
                    });
                  },
                ),
                const SizedBox(height: 8),
                _buildZoomButton(
                  icon: Icons.remove_rounded,
                  onTap: () {
                    setState(() {
                      _currentZoom = (_currentZoom - 1).clamp(10.0, 18.0);
                      _mapController.move(
                        _mapController.camera.center,
                        _currentZoom,
                      );
                    });
                  },
                ),
                const SizedBox(height: 8),
                _buildZoomButton(
                  icon: Icons.my_location_rounded,
                  onTap: _recenterMap,
                ),
              ],
            ),
          ),
          // Back button
          Positioned(
            top: 70,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 16,
                  color: Color(0xFF374151),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarker(PhotographerModel photographer, bool isSelected) {
    return Stack(
      alignment: Alignment.center,
      children: [
        if (isSelected)
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFC62828).withValues(alpha: 0.2),
            ),
          ),
        Container(
          width: isSelected ? 50 : 38,
          height: isSelected ? 50 : 38,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: photographer.gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        Text(
          photographer.initials,
          style: GoogleFonts.poppins(
            fontSize: isSelected ? 14 : 11,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        if (!photographer.isAvailable)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: const Color(0xFF9E9E9E),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          )
        else
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBottomSheet(PhotographerModel photographer) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x15000000),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: photographer.gradientColors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          photographer.initials,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            photographer.name,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1A1A1A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5F5F5),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  photographer.primarySpecialty.isNotEmpty
                                      ? photographer.primarySpecialty
                                      : photographer.specialties.isNotEmpty
                                      ? photographer.specialties.first
                                      : '',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF6B7280),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    color: Color(0xFFFFB300),
                                    size: 14,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    '${photographer.rating.toStringAsFixed(1)} (${photographer.reviewCount})',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF374151),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PhotographerProfileScreen(
                              photographer: photographer,
                            ),
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFE5E7EB)),
                          foregroundColor: const Color(0xFF374151),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.person_rounded, size: 18),
                        label: Text(
                          'View Profile',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PhotographerProfileScreen(
                              photographer: photographer,
                            ),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC62828),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Book Now',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZoomButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 20, color: const Color(0xFF374151)),
      ),
    );
  }
}
