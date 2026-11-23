import 'package:book_app/Component/MongolFonts.dart';
import 'package:book_app/Component/find_ctrls.dart';
import 'package:book_app/core/constants/app_colors.dart';
import 'package:book_app/screens/search_results_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mongol/mongol.dart';

/// Search input page — redesigned 24 Nov 2026 after the user's TestFlight
/// report that search "is not working" (build 8).
///
/// What was wrong with the old layout:
/// * The input was a full-screen [MongolTextField] with `expands: true`.
///   Vertical Mongolian text only occupies as many columns as the content
///   needs, so an empty (or one-word) query rendered as a single tiny
///   column of hint text at the top-left of a giant empty white page —
///   it looked broken and gave no clue where to type.
/// * The outer grey container showed through on the right: the [Row]'s
///   `crossAxisAlignment` defaults to center, so the 50px copy/paste
///   column was only as tall as its two buttons and floated mid-screen
///   on a grey strip.
/// * Nothing said the query must be Mongolian. A Latin query matches
///   nothing in the Z52 book text, so the user saw "No results" and
///   concluded search was broken.
///
/// The new layout: a compact, clearly bordered input card at the top
/// (the field lives inside a visible box), a small toolbar row for
/// paste/clear, a guidance line saying to type in Mongolian with the
/// Zmongol keyboard, the big Search button, and tappable example words
/// (all verified to occur in the bundled books) so the user can see
/// search work with one tap. The search pipeline itself
/// (controller -> [BookSearchService] -> results screen) was verified
/// working in the simulator — only the presentation was broken.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _bookCtrl = FindCtrl.book;
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  // Example words, each verified to occur in the bundled books
  // (counts across all 4 books: Mongol 1107x, Chinggis 2413x, person 7459x).
  static const _kExamples = <String>[
    'ᢌᡭᡪᢊᡱᡱᡭᢐ', // Mongol
    'ᢚᡬᡪᢊᢊᡬᢓ', // Chinggis
    'ᡥᢚᡧ', // person
  ];

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _doSearch([String? query]) {
    final q = (query ?? _controller.text).trim();
    if (q.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SearchResultsScreen(
          query: q,
          books: _bookCtrl.booksList.toList(),
        ),
      ),
    );
  }

  void _searchExample(String word) {
    _controller.text = word;
    _doSearch(word);
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      final text = data!.text!;
      final sel = _controller.selection;
      final old = _controller.text;
      final start = sel.isValid ? sel.start : old.length;
      final end = sel.isValid ? sel.end : old.length;
      _controller.text = old.replaceRange(start, end, text);
      _controller.selection =
          TextSelection.collapsed(offset: start + text.length);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasText = _controller.text.isNotEmpty;
    final bookCount = _bookCtrl.booksList.length;
    final paperColor = isDark ? const Color(0xFF1A2332) : Colors.white;
    final borderColor = isDark ? Colors.white24 : Colors.grey.shade300;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Search Books',
          style: TextStyle(color: Colors.white, fontSize: 17),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: _doSearch,
            tooltip: 'Search',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Input card: a visible box for the vertical query ──────────
            Container(
              height: 208,
              decoration: BoxDecoration(
                color: paperColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // The query field (vertical Mongolian, system keyboard).
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
                      child: MongolTextField(
                        controller: _controller,
                        scrollController: _scrollController,
                        showCursor: true,
                        autofocus: true,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => _doSearch(),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          hintText: 'ᡳᡪᡧ ᡥᡪᡱᢔᡪᡫ…',
                          hintStyle: TextStyle(
                            fontFamily: MongolFonts.z52agolatig,
                            color: Colors.black38,
                            fontSize: 18,
                          ),
                        ),
                        style: TextStyle(
                          fontFamily: _bookCtrl.fontFamily.value.isEmpty
                              ? MongolFonts.z52agolatig
                              : _bookCtrl.fontFamily.value,
                          fontSize: 22,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                  // Toolbar row: paste / clear (horizontal chrome, not content).
                  Container(
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: borderColor)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.paste),
                          tooltip: 'Paste',
                          onPressed: _paste,
                        ),
                        IconButton(
                          icon: const Icon(Icons.clear),
                          tooltip: 'Clear',
                          onPressed: hasText ? _controller.clear : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // ── Guidance: Mongolian input is required ─────────────────────
            Text(
              'Type in Mongolian with your Zmongol keyboard — '
              'searches all $bookCount books.',
              style: TextStyle(
                color: isDark ? Colors.white60 : Colors.black54,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            // ── Search button ─────────────────────────────────────────────
            ElevatedButton.icon(
              onPressed: _doSearch,
              icon: const Icon(Icons.search),
              label: const Text('Search'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 20),
            // ── Try one: tappable example words ───────────────────────────
            Text(
              'Try one:',
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black87,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: _kExamples
                  .map((word) => Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: _ExampleCard(
                          word: word,
                          fontFamily: _bookCtrl.fontFamily.value.isEmpty
                              ? MongolFonts.z52agolatig
                              : _bookCtrl.fontFamily.value,
                          isDark: isDark,
                          onTap: () => _searchExample(word),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── A tappable vertical word card (one example query) ─────────────────────

class _ExampleCard extends StatelessWidget {
  final String word;
  final String fontFamily;
  final bool isDark;
  final VoidCallback onTap;

  const _ExampleCard({
    required this.word,
    required this.fontFamily,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: ValueKey('example-$word'),
      onTap: onTap,
      child: Container(
        width: 64,
        height: 150,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A2332) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.45),
          ),
        ),
        child: Center(
          child: MongolText(
            word,
            style: TextStyle(
              fontFamily: fontFamily,
              fontSize: 18,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}
