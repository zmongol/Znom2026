import 'dart:io';

import 'package:book_app/core/constants/app_colors.dart';
import 'package:book_app/extensions/storage_ext.dart';
import 'package:book_app/models/books/book_model.dart';
import 'package:book_app/services/book_sync_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show AssetManifest, rootBundle;
import 'package:get/get.dart';

import '../Component/find_ctrls.dart';

final _bookCtrl = FindCtrl.book;

/// Reader for image books: scanned PDF pages shown as full-screen images.
///
/// Pages are `<pagePrefix>-p001.jpg` … (see [Book.imagePageFileName]).
/// The Folk Tales book ships inside the app under
/// `assets/pages/<pagePrefix>/` — no download needed. A downloaded copy
/// from the Mini FTP sync (same files, same names) takes display priority
/// when present. Swipe left/right (or Prev/Next / the slider) to turn
/// pages; pinch to zoom. The last-read page is saved with [ReadingProgress]
/// (chapter 0, scroll offset = page index) so the details screen's
/// Continue Reading banner can resume it.
///
/// Zoom is driven by a raw [Listener], NOT by InteractiveViewer:
/// InteractiveViewer's scale recogniser claims every single-finger drag in
/// the gesture arena even with panEnabled false, so a PageView page would
/// never turn (verified: a swipe left the reader stuck on page 1). A
/// Listener does not take part in the arena, so one-finger drags reach the
/// PageView untouched, and two-finger pinches are tracked by hand. While
/// zoomed the PageView is locked (NeverScrollableScrollPhysics) so a drag
/// pans the image instead of turning the page; pinching back to 1.0x
/// unlocks swiping again.
class ImageReadingScreen extends StatefulWidget {
  final Book book;

  const ImageReadingScreen({super.key, required this.book});

  /// Push the image reader for [book] (no-op if it has no pages).
  static void open(BuildContext context, Book book) {
    if (!book.isImageBook || book.pageCount <= 0) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ImageReadingScreen(book: book)),
    );
  }

  @override
  State<ImageReadingScreen> createState() => _ImageReadingScreenState();
}

class _ImageReadingScreenState extends State<ImageReadingScreen> {
  late final PageController _pageCtrl;
  late int _currentPage;
  String _booksDir = '';
  Set<int> _availablePages = {};
  // Pages downloaded over FTP render from file; the rest render from the
  // app assets. _availablePages is the union of both sources.
  Set<int> _downloadedPages = {};
  bool _checking = true;
  String? _error;

  // Zoom state (applies to the page on screen; reset on page change).
  double _scale = 1.0;
  Offset _offset = Offset.zero;
  // Live pointer positions, keyed by pointer id.
  final Map<int, Offset> _pointers = {};
  double _pinchStartDistance = 0;
  double _pinchStartScale = 1.0;

  bool get _isZoomed => _scale > 1.01;

  int get _totalPages => widget.book.pageCount;

  @override
  void initState() {
    super.initState();
    final progress = ReadingProgress.load(widget.book.title);
    final savedPage = progress != null ? progress.$2.round() : 0;
    _currentPage = savedPage.clamp(0, _totalPages - 1);
    _pageCtrl = PageController(initialPage: _currentPage);
    _refreshAvailable();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  /// Re-scan for this book's page files: the downloaded books folder
  /// (FTP sync) plus the pages bundled in the app assets.
  Future<void> _refreshAvailable() async {
    setState(() {
      _checking = true;
      _error = null;
    });
    try {
      final dir = await BookSyncService.getLocalBooksPath();
      final downloaded = <int>{};
      final listing = Directory(dir);
      if (await listing.exists()) {
        await for (final entity in listing.list()) {
          final name = entity.path.split('/').last;
          if (name.startsWith('${widget.book.pagePrefix}-p') &&
              name.endsWith('.jpg')) {
            final numPart = name.substring(
                widget.book.pagePrefix.length + 2, name.length - 4);
            final n = int.tryParse(numPart);
            if (n != null && n >= 1 && n <= _totalPages) downloaded.add(n);
          }
        }
      }
      // Bundled pages live under assets/pages/<pagePrefix>/ — present from
      // the first launch, no download needed.
      final bundled = <int>{};
      try {
        final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
        final dirPrefix = 'assets/pages/${widget.book.pagePrefix}/';
        final filePrefix = '${widget.book.pagePrefix}-p';
        for (final p in manifest.listAssets()) {
          if (!p.startsWith(dirPrefix) || !p.endsWith('.jpg')) continue;
          final name = p.split('/').last;
          if (!name.startsWith(filePrefix)) continue;
          final numPart = name.substring(filePrefix.length, name.length - 4);
          final n = int.tryParse(numPart);
          if (n != null && n >= 1 && n <= _totalPages) bundled.add(n);
        }
      } catch (e) {
        debugPrint('ImageReadingScreen: bundled page scan failed: $e');
      }
      if (!mounted) return;
      setState(() {
        _booksDir = dir;
        _downloadedPages = downloaded;
        _availablePages = {...downloaded, ...bundled};
        _checking = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _checking = false;
      });
    }
  }

  Future<void> _checkForDownloads() async {
    setState(() => _checking = true);
    await BookSyncService.checkForBookUpdates();
    await _refreshAvailable();
    if (!mounted) return;
    Get.snackbar(
      'Library sync',
      _availablePages.isEmpty
          ? 'No pages downloaded yet — is the phone on Tailscale?'
          : '${_availablePages.length} of $_totalPages pages on this device.',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
    );
  }

  void _goToPage(int page) {
    final target = page.clamp(0, _totalPages - 1);
    _pageCtrl.animateToPage(
      target,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _onPageChanged(int page) {
    // A new page always starts unzoomed.
    _scale = 1.0;
    _offset = Offset.zero;
    _pointers.clear();
    _pinchStartDistance = 0;
    setState(() => _currentPage = page);
    ReadingProgress.save(widget.book.title, 0, page.toDouble());
  }

  // --- raw pointer tracking (no gesture arena) -------------------------

  void _pointerDown(PointerDownEvent e) {
    _pointers[e.pointer] = e.position;
    if (_pointers.length == 2) {
      final pts = _pointers.values.toList();
      _pinchStartDistance = (pts[0] - pts[1]).distance;
      _pinchStartScale = _scale;
    }
  }

  void _pointerMove(PointerMoveEvent e) {
    if (!_pointers.containsKey(e.pointer)) return;
    _pointers[e.pointer] = e.position;
    if (_pointers.length == 2) {
      // Pinch: scale from the distance between the two fingers.
      final pts = _pointers.values.toList();
      final dist = (pts[0] - pts[1]).distance;
      if (_pinchStartDistance > 0 && dist > 0) {
        final next =
            (_pinchStartScale * dist / _pinchStartDistance).clamp(1.0, 4.0);
        setState(() {
          _scale = next;
          if (!_isZoomed) _offset = Offset.zero;
        });
      }
    } else if (_pointers.length == 1 && _isZoomed) {
      // Pan the zoomed image; clamp so it cannot be dragged away.
      final size = MediaQuery.of(context).size;
      final maxDx = (size.width * (_scale - 1)) / 2;
      final maxDy = (size.height * (_scale - 1)) / 2;
      setState(() {
        _offset = Offset(
          (_offset.dx + e.delta.dx).clamp(-maxDx, maxDx),
          (_offset.dy + e.delta.dy).clamp(-maxDy, maxDy),
        );
      });
    }
  }

  void _pointerUp(PointerUpEvent e) {
    _pointers.remove(e.pointer);
    if (_pointers.length < 2) _pinchStartDistance = 0;
  }

  void _pointerCancel(PointerCancelEvent e) {
    _pointers.remove(e.pointer);
    if (_pointers.length < 2) _pinchStartDistance = 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Obx(() => Text(widget.book.title,
            style: TextStyle(
                fontFamily: _bookCtrl.fontFamily.value.isEmpty
                    ? null
                    : _bookCtrl.fontFamily.value,
                color: Colors.white))),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Check for downloaded pages',
            onPressed: _checkForDownloads,
          ),
        ],
      ),
      bottomNavigationBar: Container(
        color: Theme.of(context).colorScheme.surface,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            TextButton.icon(
              onPressed:
                  _currentPage > 0 ? () => _goToPage(_currentPage - 1) : null,
              icon: const Icon(Icons.chevron_left),
              label: const Text('Prev'),
            ),
            Expanded(
              // The Slider is sizedByParent: without a fixed height it
              // expands to fill the Scaffold's full height, squeezing the
              // body to zero and covering the AppBar. Pin it to the
              // standard 48pt slider height.
              child: SizedBox(
                height: 48,
                child: Slider(
                  value: _currentPage.toDouble(),
                  min: 0,
                  max: (_totalPages - 1).toDouble(),
                  divisions: _totalPages - 1,
                  label: '${_currentPage + 1}',
                  onChanged: (v) => _goToPage(v.round()),
                ),
              ),
            ),
            Text(
              '${_currentPage + 1} / $_totalPages',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            TextButton.icon(
              onPressed: _currentPage < _totalPages - 1
                  ? () => _goToPage(_currentPage + 1)
                  : null,
              icon: const Icon(Icons.chevron_right),
              label: const Text('Next'),
              iconAlignment: IconAlignment.end,
            ),
          ],
        ),
      ),
      body: _checking
          ? const Center(child: CircularProgressIndicator())
          : _availablePages.isEmpty
              ? _buildEmptyState()
              : PageView.builder(
                  controller: _pageCtrl,
                  // While zoomed the page must not turn under a pan.
                  physics: _isZoomed
                      ? const NeverScrollableScrollPhysics()
                      : const PageScrollPhysics(),
                  itemCount: _totalPages,
                  onPageChanged: _onPageChanged,
                  itemBuilder: (context, index) => _buildPage(index + 1),
                ),
    );
  }

  Widget _buildPage(int pageNumber) {
    if (!_availablePages.contains(pageNumber)) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_download_outlined, size: 48),
              const SizedBox(height: 12),
              Text(
                'Page $pageNumber is still downloading',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '${_availablePages.length} of $_totalPages pages on this device.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    final fileName = Book.imagePageFileName(widget.book.pagePrefix, pageNumber);
    final Widget image;
    if (_downloadedPages.contains(pageNumber)) {
      // FTP copy (identical content) takes display priority.
      image = Image.file(
        File('$_booksDir/$fileName'),
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Center(
          child: Text('Could not open page $pageNumber'),
        ),
      );
    } else {
      // Bundled in the app under assets/pages/<prefix>/.
      image = Image.asset(
        'assets/pages/${widget.book.pagePrefix}/$fileName',
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Center(
          child: Text('Could not open page $pageNumber'),
        ),
      );
    }
    return Listener(
      onPointerDown: _pointerDown,
      onPointerMove: _pointerMove,
      onPointerUp: _pointerUp,
      onPointerCancel: _pointerCancel,
      child: Transform(
        transform: Matrix4.identity()
          ..translate(_offset.dx, _offset.dy)
          ..scale(_scale),
        alignment: Alignment.center,
        child: Center(
          child: image,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.menu_book_rounded,
                size: 56, color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              'Pages not downloaded yet',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _error ??
                  'This book is $_totalPages scanned pages. They download '
                      'from your Mac Mini over Tailscale — check the phone is '
                      'on Tailscale, then try again.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _checkForDownloads,
              icon: const Icon(Icons.download),
              label: const Text('Check for downloads'),
            ),
          ],
        ),
      ),
    );
  }
}
