/// Strips raw markup tags (e.g. a stray "<title>…</title>" left in a
/// book's metadata by an export tool) from a display string, so raw
/// tags can never reach the UI. Book content itself is NOT sanitised.
String stripMarkup(String? value) {
  if (value == null) return '';
  return value.replaceAll(RegExp(r'<[^>]*>'), '').trim();
}

class BookChapter {
  BookChapter({
    this.title = '',
    this.image = '',
    this.auth = '',
    this.rating = 0,
    this.chapterNumber = 0,
    this.chapterTitle = '',
    this.content = '',
    this.releasedate = '',
  });

  String? title;
  String? image;
  String? auth;
  double? rating;
  int? chapterNumber;
  String? chapterTitle;
  String? content;
  String? releasedate;

  // Lazily-computed lowercase cache — avoids repeated toLowerCase() per search
  String? _lowerContent;
  String get lowerContent => _lowerContent ??= (content ?? '').toLowerCase();

//fetchList
  static List<BookChapter> fetchList(dynamic data) {
    if (data == null) return [];
    try {
      return List<BookChapter>.from(
          (data as List<dynamic>).map((e) => BookChapter.fromJson(e))).toList();
    } catch (e) {
      return [];
    }
  }

  factory BookChapter.fromJson(Map<String, dynamic> json) => BookChapter(
        title: stripMarkup(json["title"]?.toString()),
        image: json["image"] ?? "",
        auth: stripMarkup(json["auth"]?.toString()),
        rating: (json["rating"] is num)
            ? (json["rating"] as num).toDouble()
            : double.tryParse('${json["rating"]}') ?? 0,
        chapterNumber: json["chapterNumber"] ?? 0,
        chapterTitle: stripMarkup(json["chapterTitle"]?.toString()),
        content: json["content"] ?? "",
        releasedate: json["release_date"] ?? "",
      );
}
