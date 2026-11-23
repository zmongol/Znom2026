import 'package:book_app/core/constants/app_colors.dart';
import 'package:book_app/extensions/storage_ext.dart';
import 'package:book_app/models/books/book_chapter_model.dart';
import 'package:book_app/models/books/book_model.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mongol/mongol.dart';

import '../Component/find_ctrls.dart';
import '../widgets/mongol_text_selector.dart';
import 'Donate.dart';
import 'search_screen.dart';

final _bookCtrl = FindCtrl.book;

class ReadingScreen extends StatefulWidget {
  final int chapterIndex;
  final Book book;
  final String? highlightQuery;
  final int? highlightStart;

  const ReadingScreen({
    super.key,
    required this.book,
    required this.chapterIndex,
    this.highlightQuery,
    this.highlightStart,
  });

  @override
  State<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends State<ReadingScreen> {
  late final ScrollController _scrollCtrl;
  late int _currentChapter;
  bool _disposed = false;
  bool _searchMode = false;
  String _searchQuery = '';
  final TextEditingController _searchTextCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentChapter = widget.chapterIndex;

    double initialOffset = 0.0;
    if (widget.highlightStart == null) {
      // Restore saved scroll offset for this chapter if one exists
      final progress = ReadingProgress.load(widget.book.title);
      initialOffset = (progress != null && progress.$1 == _currentChapter)
          ? progress.$2
          : 0.0;
    }

    _scrollCtrl = ScrollController(initialScrollOffset: initialOffset);
    _scrollCtrl.addListener(_onScroll);

    // Scroll to the matched word after the frame renders
    if (widget.highlightStart != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToHighlight();
      });
    }
  }

  void _scrollToHighlight() {
    // Retry until the scroll controller has fully laid out content.
    // iOS navigation animations can delay layout completion.
    if (!mounted || _disposed) return;
    if (!_scrollCtrl.hasClients ||
        _scrollCtrl.position.maxScrollExtent <= 0.0) {
      Future.delayed(const Duration(milliseconds: 100), _scrollToHighlight);
      return;
    }
    final screenHeight = MediaQuery.of(context).size.height;
    final fontSize = _bookCtrl.contentStyle.value.fontSize ?? 22;
    final charsPerCol =
        (screenHeight / (fontSize * 1.35)).floor().clamp(1, 9999);
    final col = widget.highlightStart! ~/ charsPerCol;
    final colWidth = fontSize * 0.65;
    final target =
        (col * colWidth).clamp(0.0, _scrollCtrl.position.maxScrollExtent);
    _scrollCtrl.animateTo(
      target,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
    );
  }

  // Cache for highlight spans — avoid recomputing on every Obx rebuild when
  // content and query haven't changed.
  String _cachedHighlightContent = '';
  String _cachedHighlightQuery = '';
  List<TextSpan> _cachedHighlightSpans = [];

  List<TextSpan> _buildHighlightSpans(String content, String query) {
    if (content == _cachedHighlightContent && query == _cachedHighlightQuery) {
      return _cachedHighlightSpans;
    }
    final spans = <TextSpan>[];
    int start = 0;
    final lower = content.toLowerCase();
    final lowerQ = query.toLowerCase();
    int idx;
    while ((idx = lower.indexOf(lowerQ, start)) != -1) {
      if (idx > start) spans.add(TextSpan(text: content.substring(start, idx)));
      spans.add(TextSpan(
        text: content.substring(idx, idx + query.length),
        style: const TextStyle(
          backgroundColor: Colors.yellow,
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ));
      start = idx + query.length;
    }
    if (start < content.length) {
      spans.add(TextSpan(text: content.substring(start)));
    }
    _cachedHighlightContent = content;
    _cachedHighlightQuery = query;
    _cachedHighlightSpans = spans;
    return spans;
  }

  void _onScroll() {
    ReadingProgress.save(
        widget.book.title, _currentChapter, _scrollCtrl.offset);
  }

  void _goToChapter(int index) {
    if (index < 0 || index >= widget.book.chapters.length) return;
    setState(() {
      _currentChapter = index;
      _searchQuery = '';
      _searchTextCtrl.clear();
      _searchMode = false;
    });
    _scrollCtrl.jumpTo(0.0);
    ReadingProgress.save(widget.book.title, index, 0.0);
  }

  @override
  void dispose() {
    _disposed = true;
    _searchTextCtrl.dispose();
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    BookChapter chapter = widget.book.chapters[_currentChapter];
    final totalChapters = widget.book.chapters.length;
    return Scaffold(
      appBar: _searchMode
          ? AppBar(
              backgroundColor: AppColors.primary,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => setState(() {
                  _searchMode = false;
                  _searchQuery = '';
                  _searchTextCtrl.clear();
                }),
              ),
              title: TextField(
                controller: _searchTextCtrl,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                cursorColor: Colors.white,
                decoration: const InputDecoration(
                  hintText: 'Search in chapter...',
                  hintStyle: TextStyle(color: Colors.white54),
                  border: InputBorder.none,
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
              actions: [
                if (_searchQuery.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white),
                    onPressed: () => setState(() {
                      _searchQuery = '';
                      _searchTextCtrl.clear();
                    }),
                  ),
              ],
            )
          : AppBar(
              title: Obx(() => Text(widget.book.title,
                  style: TextStyle(
                      fontFamily: _bookCtrl.fontFamily.value.isEmpty
                          ? null
                          : _bookCtrl.fontFamily.value,
                      color: Colors.white))),
              backgroundColor: AppColors.primary,
              actions: [
                IconButton(
                  icon: const Icon(Icons.search, color: Colors.white),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SearchScreen()),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.favorite, color: Colors.white),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => Donation()),
                    );
                  },
                ),
                Obx(() {
                  final fontFamily = _bookCtrl.fontFamily.value.isEmpty
                      ? null
                      : _bookCtrl.fontFamily.value;
                  return PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      itemBuilder: (context) => [
                            PopupMenuItem(
                              value: "FontSize",
                              child: Text(
                                "ᡥᡭᡬᢔᡭᡬᡨ ᡭᡧ ᢜᡪᢊᡪᡨ ᡳᡪᢉᡨ",
                                style: TextStyle(fontFamily: fontFamily),
                              ),
                            ),
                            PopupMenuItem(
                              value: "FontFamily",
                              child: Text(
                                "ᢘᡬᡬᡨ ᢔᡭᢑᡬᡪᡪᡳ",
                                style: TextStyle(fontFamily: fontFamily),
                              ),
                            ),
                          ],
                      onSelected: (val) {
                        if (val == "FontSize") {
                          _bookCtrl.changeFontScale();
                        }
                        if (val == "FontFamily") {
                          _bookCtrl.changeFontFamily();
                        }
                      });
                }),
              ],
            ),
      bottomNavigationBar: Container(
        color: Theme.of(context).colorScheme.surface,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: _currentChapter > 0
                  ? () => _goToChapter(_currentChapter - 1)
                  : null,
              icon: const Icon(Icons.chevron_left),
              label: const Text('Prev'),
            ),
            Text(
              '${_currentChapter + 1} / $totalChapters',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            TextButton.icon(
              onPressed: _currentChapter < totalChapters - 1
                  ? () => _goToChapter(_currentChapter + 1)
                  : null,
              icon: const Icon(Icons.chevron_right),
              label: const Text('Next'),
              iconAlignment: IconAlignment.end,
            ),
          ],
        ),
      ),
      body: Padding(
        padding: EdgeInsets.fromLTRB(10, 10, 16, 30),
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(
            dragDevices: {
              PointerDeviceKind.touch,
              PointerDeviceKind.mouse,
              PointerDeviceKind.trackpad,
            },
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: BouncingScrollPhysics(),
            controller: _scrollCtrl,
            child: SizedBox(
              height: context.height,
              child: Obx(
                () {
                  final style = _bookCtrl.contentStyle.value;
                  final activeQuery = _searchQuery.isNotEmpty
                      ? _searchQuery
                      : widget.highlightQuery;
                  final fullText = chapter.content ?? '';
                  if (activeQuery == null || activeQuery.isEmpty) {
                    return MongolTextSelector(
                      text: fullText,
                      child: MongolText(
                        fullText,
                        textAlign: MongolTextAlign.top,
                        style: style,
                      ),
                    );
                  }
                  return MongolTextSelector(
                    text: fullText,
                    child: MongolText.rich(
                      TextSpan(
                        style: style,
                        children: _buildHighlightSpans(fullText, activeQuery),
                      ),
                      textAlign: MongolTextAlign.top,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
