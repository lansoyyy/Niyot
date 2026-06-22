import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/photographer_model.dart';
import '../../services/block_service.dart';
import '../../services/photographer_service.dart';
import '../../widgets/explore/explore_creator_card.dart';
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
  bool _isGridView = false;
  bool _availableOnly = false;
  List<PhotographerModel> _results = [];
  bool _isLoading = true;
  String? _error;
  Timer? _debounceTimer;
  _ExploreSortOption _sortOption = _ExploreSortOption.ratingHighToLow;
  Set<String> _blockedUserIds = <String>{};

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
    _initBlockedUsers();
    _loadData();
    _searchController.addListener(() {
      if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 600), _loadData);
    });
  }

  void _initBlockedUsers() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    BlockService().blockedUserIdsStream(uid).listen((ids) {
      if (mounted) {
        setState(() {
          _blockedUserIds = ids;
        });
        _loadData();
      }
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

    if (_blockedUserIds.isNotEmpty) {
      processed = processed
          .where((photographer) => !_blockedUserIds.contains(photographer.uid))
          .toList();
    }

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
                        : '${_results.length} creators found',
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
              Expanded(
                child: _isGridView ? _buildGrid() : _buildRecommendedList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid() => _buildRecommendedList();

  Widget _buildRecommendedList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      itemCount: _results.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12, top: 4),
            child: Text(
              'RECOMMENDED FOR YOU',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFC62828),
                letterSpacing: 1.2,
              ),
            ),
          );
        }
        return ExploreCreatorCard(photographer: _results[index - 1]);
      },
    );
  }

}
