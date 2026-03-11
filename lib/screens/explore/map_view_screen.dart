import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';

class MapViewScreen extends StatefulWidget {
  const MapViewScreen({super.key});

  @override
  State<MapViewScreen> createState() => _MapViewScreenState();
}

class _MapViewScreenState extends State<MapViewScreen> {
  final MapController _mapController = MapController();
  double _currentZoom = 13.0;
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Portrait',
    'Wedding',
    'Event',
    'Commercial',
    'Fashion',
  ];

  // Sample photographer locations
  final List<Map<String, dynamic>> _photographers = [
    {
      'id': '1',
      'name': 'Sofia Reyes',
      'specialty': 'Wedding',
      'rating': 4.9,
      'reviews': 142,
      'price': '\$350/hr',
      'initials': 'SR',
      'gradient': [const Color(0xFF8E0000), const Color(0xFFC62828)],
      'position': const LatLng(40.7128, -74.0060), // New York
      'available': true,
    },
    {
      'id': '2',
      'name': 'Marcus Chen',
      'specialty': 'Commercial',
      'rating': 4.8,
      'reviews': 98,
      'price': '\$420/hr',
      'initials': 'MC',
      'gradient': [const Color(0xFF4A0000), const Color(0xFF880E0E)],
      'position': const LatLng(40.7589, -73.9851), // Manhattan
      'available': true,
    },
    {
      'id': '3',
      'name': 'Ava Thompson',
      'specialty': 'Portrait',
      'rating': 5.0,
      'reviews': 211,
      'price': '\$280/hr',
      'initials': 'AT',
      'gradient': [const Color(0xFF880E4F), const Color(0xFFAD1457)],
      'position': const LatLng(40.7484, -73.9857), // Midtown
      'available': false,
    },
    {
      'id': '4',
      'name': 'Liam Park',
      'specialty': 'Event',
      'rating': 4.7,
      'reviews': 67,
      'price': '\$200/hr',
      'initials': 'LP',
      'gradient': [const Color(0xFFC62828), const Color(0xFF6B0000)],
      'position': const LatLng(40.7282, -73.7949), // Queens
      'available': true,
    },
    {
      'id': '5',
      'name': 'Isabella Cruz',
      'specialty': 'Portrait',
      'rating': 4.9,
      'reviews': 189,
      'price': '\$320/hr',
      'initials': 'IC',
      'gradient': [const Color(0xFFAD1457), const Color(0xFF560027)],
      'position': const LatLng(40.6892, -74.0445), // Brooklyn
      'available': true,
    },
  ];

  Map<String, dynamic>? _selectedPhotographer;

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredPhotographers {
    if (_selectedCategory == 'All') return _photographers;
    return _photographers
        .where((p) => p['specialty'] == _selectedCategory)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(40.7128, -74.0060),
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
                userAgentPackageName: 'com.example.niyot',
              ),
              // Markers
              MarkerLayer(
                markers: _filteredPhotographers.map((photographer) {
                  final isSelected =
                      _selectedPhotographer?['id'] == photographer['id'];
                  return Marker(
                    point: photographer['position'] as LatLng,
                    width: isSelected ? 60 : 45,
                    height: isSelected ? 60 : 45,
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selectedPhotographer = photographer);
                        _mapController.move(
                          photographer['position'] as LatLng,
                          14,
                        );
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
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: const Color(0xFF1F2937),
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Search location...',
                                  hintStyle: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: const Color(0xFFBDBDBD),
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                              ),
                            ),
                            Container(
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
                                setState(() => _selectedCategory = category);
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
                  onTap: () {
                    _mapController.move(const LatLng(40.7128, -74.0060), 13);
                  },
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

  Widget _buildMarker(Map<String, dynamic> photographer, bool isSelected) {
    final available = photographer['available'] as bool;
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer glow
        if (isSelected)
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFC62828).withValues(alpha: 0.2),
            ),
          ),
        // Marker background
        Container(
          width: isSelected ? 50 : 38,
          height: isSelected ? 50 : 38,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: List<Color>.from(photographer['gradient'] as List),
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
        // Initials
        Text(
          photographer['initials'] as String,
          style: GoogleFonts.poppins(
            fontSize: isSelected ? 14 : 11,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        // Availability indicator
        if (!available)
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

  Widget _buildBottomSheet(Map<String, dynamic> photographer) {
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
          // Handle
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
                          colors: List<Color>.from(
                            photographer['gradient'] as List,
                          ),
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          photographer['initials'] as String,
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
                            photographer['name'] as String,
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
                                  photographer['specialty'] as String,
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
                                    '${photographer['rating']} (${photographer['reviews']})',
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
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFE5E7EB)),
                          foregroundColor: const Color(0xFF374151),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.message_rounded, size: 18),
                        label: Text(
                          'Message',
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
                        onPressed: () {},
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
