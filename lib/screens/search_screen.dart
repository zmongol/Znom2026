import 'package:book_app/Component/MongolFonts.dart';
import 'package:book_app/Component/find_ctrls.dart';
import 'package:book_app/core/constants/app_colors.dart';
import 'package:book_app/screens/search_results_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mongol/mongol.dart';

/// Search input page — a plain text field using the system keyboard.
/// Type with the system keyboard or the installed Zmongol IME; the query is
/// matched against the books' Z52 text by [BookSearchService].
/// (The flagship's editor keyboard, candidate bar and word suggestions are
/// intentionally NOT ported — this app ships without the editor.)
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _bookCtrl = FindCtrl.book;
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

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

  void _doSearch() {
    final query = _controller.text.trim();
    if (query.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SearchResultsScreen(
          query: query,
          books: _bookCtrl.booksList.toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Search Books',
          style: TextStyle(color: Colors.white, fontSize: 17),
        ),
        actions: [
          if (_controller.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, color: Colors.white),
              onPressed: _controller.clear,
              tooltip: 'Clear',
            ),
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: _doSearch,
            tooltip: 'Search',
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Text area + side buttons ──────────────────────────────────
          Expanded(
            child: Container(
              color: Colors.grey.shade400,
              child: Row(
                children: [
                  // White paper text area (vertical Mongolian, system keyboard)
                  Expanded(
                    child: Container(
                      color: isDark ? const Color(0xFF1A2332) : Colors.white,
                      padding: const EdgeInsets.all(4),
                      child: MongolTextField(
                        controller: _controller,
                        scrollController: _scrollController,
                        showCursor: true,
                        expands: true,
                        maxLines: null,
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
                  // Thin divider
                  Container(
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(
                          color: Colors.grey.shade300,
                          width: 1 / MediaQuery.of(context).devicePixelRatio,
                        ),
                      ),
                    ),
                  ),
                  // Side buttons column
                  Container(
                    width: 50,
                    color: isDark ? const Color(0xFF1A2332) : Colors.white,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Copy typed text
                        IconButton(
                          icon: const Icon(Icons.copy),
                          tooltip: 'Copy',
                          onPressed: () {
                            final text = _controller.text;
                            if (text.isNotEmpty) {
                              Clipboard.setData(ClipboardData(text: text));
                            }
                          },
                        ),
                        // Paste from clipboard
                        IconButton(
                          icon: const Icon(Icons.paste),
                          tooltip: 'Paste',
                          onPressed: () async {
                            final data =
                                await Clipboard.getData(Clipboard.kTextPlain);
                            if (data?.text != null) {
                              final text = data!.text!;
                              final sel = _controller.selection;
                              final old = _controller.text;
                              final start =
                                  sel.isValid ? sel.start : old.length;
                              final end = sel.isValid ? sel.end : old.length;
                              _controller.text =
                                  old.replaceRange(start, end, text);
                              _controller.selection = TextSelection.collapsed(
                                  offset: start + text.length);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // ── Search button (system keyboards have no Mongolian search key)
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _doSearch,
                  icon: const Icon(Icons.search),
                  label: const Text('Search'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
