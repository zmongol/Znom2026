/// Z52 (Zcode) UI strings for Znom's chrome — Mongolian-first labels,
/// always paired with a small English caption in the UI.
///
/// ⚠️ DRAFTS — added 24 Nov 2026 for the UI redesign. Each string below
/// was drafted in Mongolian Unicode (classical spelling) and converted
/// to Z52 with the mongolian-convert converter; the word-list checker
/// reported 0 known-wrong spellings. They still need the user's own
/// proofread before they can be treated as final — the English gloss in
/// each comment says what the string is meant to say.
///
/// Strings marked "pre-existing" were already in the app before this
/// redesign and are NOT new drafts.
class UiStrings {
  UiStrings._();

  /// DRAFT — "Үргэлжлүүлэн унших" (Continue reading)
  static const String continueReading =
      'ᡥᡭᡬᢞᢋᡭᢑᢛᡬᢑᡪᢋᡭᢑᡭᡧ ᡥᡭᡪᢔᡬᡪᡪᡳ';

  /// DRAFT — "Онцлох номууд" (Featured books)
  static const String featuredBooks = 'ᡥᡭᡪᢚᡪᢑᡪᡪᡪᡳ ᡯᡭᢍ ᡭᡭᡧ';

  /// DRAFT — "Шинэ ном" (New book)
  static const String newBook = 'ᢔᡬᡰᡨ ᡯᡭᢍ';

  /// DRAFT — "Номууд татагдаж байна" (Books are downloading)
  static const String booksDownloading =
      'ᡯᡭᢍ ᡭᡭᡧ ᢘᡪᢙᡪᡪᡪᢙᡪᢛᡳ ᡳᡪᡬᡬᡰᡨ';

  /// DRAFT — "Ном хайх" (Search books)
  static const String searchBooks = 'ᡯᡭᢍ ᡸᡪᡬᡬᡪᡪᡳ';

  /// DRAFT — "Хайлтын дүн" (Search results)
  static const String searchResults = 'ᡸᡪᡬᡬᢑᢙᡧ ᡬᡬᡧ ᢘᡭᡬᡪᡬᡨ';

  /// DRAFT — "Бүлгүүд" (Chapters)
  static const String chapters = 'ᡴᡭᡬᢑᡭᡬᡨ ᡭᡭᡧ';

  /// "Бүлэг" (Chapter) — the same Z52 word the chapter cards already
  /// use; also used to build fallback chapter labels ("ᡴᡭᡬᢑᡭᡬᡨ 3").
  static const String chapter = 'ᡴᡭᡬᢑᡭᡬᡨ';

  /// DRAFT — "Боть" (Volume)
  static const String volume = 'ᡴᡭᢙᡫ';

  /// DRAFT — "Тохируулга" (Settings)
  static const String settings = 'ᢘᡭᢊᡬᢞᡪᡱᡱᡭᢑᢉᡨ';

  /// DRAFT — "Дэвсгэр" (Background / page colour)
  static const String background = 'ᢘᡪᡳᢔᢊᡪᢝ';

  /// DRAFT — "Цагаан" (White)
  static const String bgWhite = 'ᢚᡪᡱᡱᡪᡧ';

  /// DRAFT — "Шаргал" (Sepia / pale warm)
  static const String bgSepia = 'ᢔᡬᢞᡱᡱᡪᢐ';

  /// DRAFT — "Хар" (Dark / black)
  static const String bgDark = 'ᡸᡪᢝᡨ';

  /// DRAFT — "Өмнөх" (Previous)
  static const String prev = 'ᡥᢎᡭᡰᡨ';

  /// DRAFT — "Дараах" (Next)
  static const String next = 'ᢘᡪᢞᡪᢉᡨ';

  /// DRAFT — "Харанхуй горим" (Dark mode)
  static const String darkMode = 'ᡸᡪᢞᡪᡪᢊᡱᡱᡭᡫ ᢈᡭᢞᡬᢍ';

  /// DRAFT — "Тухай" (About)
  static const String about = 'ᢘᡭᡪᡪᡪᡫ';

  // ── Pre-existing strings (already in the app; not new drafts) ─────

  /// Pre-existing — font size label used by the menus.
  static const String fontSize = 'ᡥᡭᡬᢔᡭᡬᡨ ᡭᡧ ᢜᡪᢊᡪᡨ ᡳᡪᢉᡨ';

  /// Pre-existing — font family label used by the menus.
  static const String fontFamily = 'ᢘᡬᡬᡨ ᢔᡭᢑᡬᡪᡪᡳ';

  /// Pre-existing — "read" button label on the book details page.
  static const String read = 'ᡥᡭᡪᢊᢔᡬᡫᡨ';
}
