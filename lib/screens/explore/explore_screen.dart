import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/photographer_model.dart';
import '../../services/photographer_service.dart';
import '../photographer/photographer_profile_screen.dart';
import 'map_view_screen.dart';

enum _ExploreSortOption {
  ratingHighToLow,
  mostReviewed,
  priceLowToHigh,
  priceHighToLow,
}

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({
    super.key,
    this.initialCategory,
    this.initialSearchQuery,
  });

  final String? initialCategory;
  final String? initialSearchQuery;

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  int _selectedFilter = 0;
  bool _isGridView = true;
  bool _availableOnly = false;
  List<PhotographerModel> _results = [];
  bool _isLoading = true;
  String? _error;
  Timer? _debounceTimer;
  _ExploreSortOption _sortOption = _ExploreSortOption.ratingHighToLow;

  final List<String> _filters = [
    'All',
    'Portrait',
    'Wedding',
    'Event',
    'Commercial',
    'Fashion',
    'Travel',
    'Newborn',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialCategory != null) {
      final initialIndex = _filters.indexOf(widget.initialCategory!);
      if (initialIndex >= 0) {
        _selectedFilter = initialIndex;
      }
    }
    if (widget.initialSearchQuery != null &&
        widget.initialSearchQuery!.trim().isNotEmpty) {
      _searchController.text = widget.initialSearchQuery!.trim();
    }
    _loadData();
    _searchController.addListener(() {
      if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 600), _loadData);
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final category = _selectedFilter == 0 ? null : _filters[_selectedFilter];
      final query = _searchController.text.trim().isEmpty
          ? null
          : _searchController.text.trim();
      final results = await PhotographerService().getPhotographers(
        category: category,
        searchQuery: query,
        limit: 60,
      );
      final processedResults = _applyClientSideFilters(results);
      if (mounted) {
        setState(() {
          _results = processedResults;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  List<PhotographerModel> _applyClientSideFilters(
    List<PhotographerModel> photographers,
  ) {
    var processed = List<PhotographerModel>.from(photographers);

    if (_availableOnly) {
      processed = processed
          .where((photographer) => photographer.isAvailable)
          .toList();
    }

    processed.sort((left, right) {
      switch (_sortOption) {
        case _ExploreSortOption.ratingHighToLow:
          return right.rating.compareTo(left.rating);
        case _ExploreSortOption.mostReviewed:
          return right.reviewCount.compareTo(left.reviewCount);
        case _ExploreSortOption.priceLowToHigh:
          return _startingPriceValue(
            left,
          ).compareTo(_startingPriceValue(right));
        case _ExploreSortOption.priceHighToLow:
          return _startingPriceValue(
            right,
          ).compareTo(_startingPriceValue(left));
      }
    });

    return processed;
  }

  int _startingPriceValue(PhotographerModel photographer) {
    final numericValue = photographer.startingPrice.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );
    return int.tryParse(numericValue) ?? 0;
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  String get _sortLabel {
    switch (_sortOption) {
      case _ExploreSortOption.ratingHighToLow:
        return 'Top rated';
      case _ExploreSortOption.mostReviewed:
        return 'Most reviewed';
      case _ExploreSortOption.priceLowToHigh:
        return 'Lowest price';
      case _ExploreSortOption.priceHighToLow:
        return 'Highest price';
    }
  }

  Future<void> _showSortSheet() async {
    final selectedOption = await showModalBottomSheet<_ExploreSortOption>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
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
                  'Sort Results',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 12),
                ..._ExploreSortOption.values.map((option) {
                  return RadioListTile<_ExploreSortOption>(
                    value: option,
                    groupValue: _sortOption,
                    activeColor: const Color(0xFFC62828),
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      _labelForSortOption(option),
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF374151),
                      ),
                    ),
                    onChanged: (value) {
                      Navigator.of(sheetContext).pop(value);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );

    if (selectedOption == null || selectedOption == _sortOption) {
      return;
    }

    setState(() => _sortOption = selectedOption);
    await _loadData();
  }

  Future<void> _showFilterSheet() async {
    var tempFilter = _selectedFilter;
    var tempAvailableOnly = _availableOnly;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
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
                      'Filter Results',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Category',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(_filters.length, (index) {
                        final isSelected = index == tempFilter;
                        return ChoiceChip(
                          label: Text(_filters[index]),
                          selected: isSelected,
                          labelStyle: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF6B7280),
                          ),
                          selectedColor: const Color(0xFFC62828),
                          backgroundColor: const Color(0xFFF5F5F5),
                          side: BorderSide(
                            color: isSelected
                                ? const Color(0xFFC62828)
                                : const Color(0xFFE5E7EB),
                          ),
                          onSelected: (_) {
                            setModalState(() => tempFilter = index);
                          },
                        );
                      }),
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
                            _selectedFilter = tempFilter;
                            _availableOnly = tempAvailableOnly;
                          });
                          _loadData();
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

  String _labelForSortOption(_ExploreSortOption option) {
    switch (option) {
      case _ExploreSortOption.ratingHighToLow:
        return 'Top rated';
      case _ExploreSortOption.mostReviewed:
        return 'Most reviewed';
      case _ExploreSortOption.priceLowToHigh:
        return 'Price: low to high';
      case _ExploreSortOption.priceHighToLow:
        return 'Price: high to low';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: SafeArea(
        child: Column(
          children: [
            // Search header
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Explore',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Search bar
                  Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(14),
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
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: const Color(0xFF1F2937),
                            ),
                            decoration: InputDecoration(
                              hintText: 'Search by name, style, location...',
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
                            width: 36,
                            height: 36,
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
                  // Filter tab row + view toggle
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 36,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _filters.length,
                            itemBuilder: (context, index) {
                              final selected = _selectedFilter == index;
                              return GestureDetector(
                                onTap: () {
                                  setState(() => _selectedFilter = index);
                                  _loadData();
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? const Color(0xFFC62828)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: selected
                                          ? const Color(0xFFC62828)
                                          : const Color(0xFFE0E0E0),
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      _filters[index],
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: selected
                                            ? Colors.white
                                            : const Color(0xFF7A7A7A),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => setState(() => _isGridView = !_isGridView),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEBEE),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            _isGridView
                                ? Icons.view_list_rounded
                                : Icons.grid_view_rounded,
                            color: const Color(0xFFC62828),
                            size: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => MapViewScreen(
                                initialCategory: _selectedFilter == 0
                                    ? null
                                    : _filters[_selectedFilter],
                                initialSearchQuery: _searchController.text
                                    .trim(),
                                availableOnly: _availableOnly,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE3F2FD),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.map_rounded,
                            color: Color(0xFF1976D2),
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            // Results count
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isLoading
                        ? 'Searching...'
                        : '${_results.length} photographers found',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF7A7A7A),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _showSortSheet,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const Icon(
                      Icons.sort_rounded,
                      size: 16,
                      color: Color(0xFFC62828),
                    ),
                    label: Text(
                      _sortLabel,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFC62828),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Results
            if (_isLoading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFFC62828)),
                ),
              )
            else if (_error != null)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Color(0xFFBDBDBD),
                        size: 48,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC62828),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            else if (_results.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.search_off_rounded,
                        color: Color(0xFFBDBDBD),
                        size: 48,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No photographers found.',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF9E9E9E),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(child: _isGridView ? _buildGrid() : _buildList()),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.72,
      ),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final item = _results[index];
        return GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PhotographerProfileScreen(photographer: item),
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 130,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: item.gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(18),
                    ),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: _initialsAvatar(
                          item.initials,
                          56,
                          item.photoUrl,
                        ),
                      ),
                      if (item.isAvailable)
                        Positioned(
                          top: 10,
                          left: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Available',
                              style: GoogleFonts.poppins(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: Colors.yellowAccent,
                                size: 11,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                item.rating.toStringAsFixed(1),
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1A1A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        item.primarySpecialty.isNotEmpty
                            ? item.primarySpecialty
                            : item.specialties.isNotEmpty
                            ? item.specialties.first
                            : '',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: const Color(0xFF9E9E9E),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.startingPrice,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFC62828),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final item = _results[index];
        return GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PhotographerProfileScreen(photographer: item),
            ),
          ),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x08000000),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: item.gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: _initialsAvatar(item.initials, 36, item.photoUrl),
                  ),
                ),
                const SizedBox(width: 14),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            item.name,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1A1A1A),
                            ),
                          ),
                          Text(
                            item.startingPrice,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFC62828),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.primarySpecialty.isNotEmpty
                            ? item.primarySpecialty
                            : item.specialties.isNotEmpty
                            ? item.specialties.first
                            : '',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF9E9E9E),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Color(0xFFFFB300),
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${item.rating.toStringAsFixed(1)} (${item.reviewCount})',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: const Color(0xFF7A7A7A),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.location_on_outlined,
                            size: 12,
                            color: Color(0xFFBDBDBD),
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              item.locationText,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: const Color(0xFFBDBDBD),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (item.isAvailable)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Available',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green.shade700,
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
          ),
        );
      },
    );
  }

  Widget _initialsAvatar(String initials, double size, String? photoUrl) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.2),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.5),
          width: 2,
        ),
        image: photoUrl != null
            ? DecorationImage(image: NetworkImage(photoUrl), fit: BoxFit.cover)
            : null,
      ),
      child: photoUrl == null
          ? Center(
              child: Text(
                initials,
                style: GoogleFonts.poppins(
                  fontSize: size * 0.3,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            )
          : null,
    );
  }
}
