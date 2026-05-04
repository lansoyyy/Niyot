import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/portfolio_item_model.dart';
import '../../services/photographer_service.dart';

class ManagePortfolioScreen extends StatefulWidget {
  const ManagePortfolioScreen({super.key, required this.photographerId});

  final String photographerId;

  @override
  State<ManagePortfolioScreen> createState() => _ManagePortfolioScreenState();
}

class _ManagePortfolioScreenState extends State<ManagePortfolioScreen> {
  List<PortfolioItemModel> _items = [];
  bool _isLoading = true;
  bool _isUploading = false;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    try {
      final items =
          await PhotographerService().getPortfolio(widget.photographerId);
      if (mounted) {
        setState(() {
          _items = items;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  static const int _kMaxPhotos = 20;
  static const int _kBatchSize = 5;

  Future<void> _pickAndUploadBatch() async {
    final remaining = _kMaxPhotos - _items.length;
    if (remaining <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Portfolio limit reached (20 photos max)',
              style: GoogleFonts.poppins(fontSize: 13)),
          backgroundColor: const Color(0xFFC62828),
        ));
      }
      return;
    }

    List<XFile> picked;
    try {
      picked = await _picker.pickMultiImage(imageQuality: 85);
    } catch (_) {
      return;
    }
    if (picked.isEmpty || !mounted) return;

    final batchLimit = remaining.clamp(0, _kBatchSize);
    if (picked.length > batchLimit) picked = picked.take(batchLimit).toList();

    final title = await _showBatchTitleDialog(picked.length);
    if (!mounted) return;

    setState(() => _isUploading = true);

    int uploadedCount = 0;
    final List<PortfolioItemModel> newItems = [];
    for (final xfile in picked) {
      try {
        final item = await PhotographerService().addPortfolioItem(
          widget.photographerId,
          File(xfile.path),
          caption: title != null && title.trim().isNotEmpty ? title.trim() : null,
        );
        newItems.add(item);
        uploadedCount++;
      } catch (_) {
        // skip failed individual upload
      }
    }

    if (mounted) {
      setState(() {
        _items.insertAll(0, newItems);
        _isUploading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          uploadedCount > 0
              ? '$uploadedCount photo${uploadedCount == 1 ? '' : 's'} added to your portfolio.'
              : 'Upload failed. Please try again.',
          style: GoogleFonts.poppins(fontSize: 13),
        ),
        backgroundColor: uploadedCount > 0 ? Colors.green.shade700 : Colors.red.shade700,
      ));
    }
  }

  Future<String?> _showBatchTitleDialog(int count) {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Title for $count photo${count == 1 ? '' : 's'}',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'All $count photo${count == 1 ? 's' : 's'} will share this title.',
              style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF7A7A7A)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              autofocus: true,
              maxLength: 100,
              style: GoogleFonts.poppins(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'e.g. Golden Hour, Wedding Prep...',
                hintStyle: GoogleFonts.poppins(
                  fontSize: 13,
                  color: const Color(0xFFBDBDBD),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFC62828)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: Text('Skip', style: GoogleFonts.poppins(color: const Color(0xFF9E9E9E))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(ctrl.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC62828),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Upload', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _viewPhoto(int index) {
    Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => PhotoViewerScreen(items: _items, initialIndex: index),
    ));
  }

  Future<void> _deleteItem(PortfolioItemModel item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Photo',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        content: Text(
          'Remove this photo from your portfolio? This cannot be undone.',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: const Color(0xFF7A7A7A),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: const Color(0xFF9E9E9E)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      await PhotographerService()
          .deletePortfolioItem(widget.photographerId, item.id);
      if (mounted) {
        setState(() => _items.removeWhere((i) => i.id == item.id));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Photo removed.',
              style: GoogleFonts.poppins(fontSize: 13),
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to delete photo. Please try again.',
              style: GoogleFonts.poppins(fontSize: 13),
            ),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final usedCount = _items.length;
    final pct = (usedCount / _kMaxPhotos * 100).round();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 16,
              color: Color(0xFF374151),
            ),
          ),
        ),
        title: Text(
          'My Portfolio',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFC62828),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Save',
                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Usage progress bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$usedCount of $_kMaxPhotos photos used',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF7A7A7A),
                      ),
                    ),
                    Text(
                      '$pct%',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF7A7A7A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: usedCount / _kMaxPhotos,
                    minHeight: 4,
                    backgroundColor: const Color(0xFFE5E7EB),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFC62828)),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFC62828)))
                : _items.isEmpty
                    ? _buildEmptyState()
                    : _buildGrid(),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
            20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: (_isUploading || _items.length >= _kMaxPhotos)
                ? null
                : _pickAndUploadBatch,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC62828),
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFFBDBDBD),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: _isUploading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.add_photo_alternate_rounded, size: 18),
            label: Text(
              _isUploading ? 'Uploading...' : 'Upload Photos',
              style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.photo_camera_outlined,
              size: 36,
              color: Color(0xFFBDBDBD),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Your portfolio is empty',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Upload your best work to start attracting clients.\nProfiles with 5+ photos get 5x more views.',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: const Color(0xFF7A7A7A),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _pickAndUploadBatch,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC62828),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                'Upload Your First Photos',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Upload up to 5 photos per batch • JPG, PNG, HEIC',
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: const Color(0xFFBDBDBD),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
      ),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = _items[index];
        return GestureDetector(
          onTap: () => _viewPhoto(index),
          onLongPress: () => _deleteItem(item),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              fit: StackFit.expand,
              children: [
                item.imageUrl.isNotEmpty
                    ? Image.network(
                        item.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder(index),
                      )
                    : _placeholder(index),
                // Title gradient overlay
                if (item.caption != null && item.caption!.isNotEmpty)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.72),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Text(
                        item.caption!,
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                // Delete button
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () => _deleteItem(item),
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 13,
                        color: Colors.white,
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
  }

  Widget _placeholder(int index) {
    const pairs = [
      [Color(0xFF8E0000), Color(0xFFC62828)],
      [Color(0xFF880E4F), Color(0xFFAD1457)],
      [Color(0xFF4A0000), Color(0xFFBF360C)],
    ];
    final pair = pairs[index % pairs.length];
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [pair[0], pair[1]]),
      ),
      child: Center(
        child: Icon(
          Icons.photo_camera_rounded,
          color: Colors.white.withValues(alpha: 0.35),
          size: 24,
        ),
      ),
    );
  }
}

// ─── Photo Viewer Screen ──────────────────────────────────────────────────────

class PhotoViewerScreen extends StatefulWidget {
  const PhotoViewerScreen({
    super.key,
    required this.items,
    required this.initialIndex,
  });

  final List<PortfolioItemModel> items;
  final int initialIndex;

  @override
  State<PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends State<PhotoViewerScreen> {
  late int _current;
  late PageController _pageCtrl;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _pageCtrl = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.items[_current];
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          '${_current + 1} / ${widget.items.length}',
          style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageCtrl,
            itemCount: widget.items.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (_, index) {
              final it = widget.items[index];
              return InteractiveViewer(
                minScale: 0.8,
                maxScale: 4.0,
                child: Center(
                  child: it.imageUrl.isNotEmpty
                      ? Image.network(it.imageUrl, fit: BoxFit.contain)
                      : const Icon(
                          Icons.photo_camera_rounded,
                          color: Colors.white54,
                          size: 64,
                        ),
                ),
              );
            },
          ),
          if (item.caption != null && item.caption!.isNotEmpty)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.fromLTRB(
                    20, 24, 20, MediaQuery.of(context).padding.bottom + 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Text(
                  item.caption!,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
