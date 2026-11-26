import 'package:book_app/models/books/book_chapter_model.dart';

class Book {
  Book({
    this.title = '',
    this.image = '',
    this.auth = '',
    this.content = '',
    this.rating = 0,
    this.chapters = const [],
    this.isImageBook = false,
    this.pageCount = 0,
    this.pagePrefix = '',
  });

  String title;
  String image;
  String auth;
  String content;
  double rating;
  List<BookChapter> chapters;

  /// Base name of the server file this book was loaded from
  /// (e.g. "TonggalagTamir.json") — the charging catalogue keys on it.
  /// Set by the loader; empty for books built any other way.
  String sourceFile = '';

  /// True when the book is a scanned PDF shown as page images instead of
  /// text chapters (book JSON `"type": "image"`).
  bool isImageBook;

  /// Number of page images for an image book (0 for text books).
  int pageCount;

  /// File-name prefix of the page images, e.g. `folktales-1979`
  /// (pages are `<prefix>-p001.jpg` … in the downloaded books folder).
  String pagePrefix;

  static List<Book> fetchList(dynamic data) {
    if (data == null) return [];
    try {
      return List<Book>.from((data as List<dynamic>).map((e) => Book.fetch(e)))
          .toList();
    } catch (e) {
      return [];
    }
  }

//fetch
  static Book fetch(List<dynamic> data) {
    if (data.isEmpty) return Book();
    try {
      Book book = Book.fromJson(data[0] as Map<String, dynamic>);
      return book..chapters = BookChapter.fetchList(data);
    } catch (e) {
      print("Book:fetch err=>$e");
      return Book();
    }
  }

  factory Book.fromJson(Map<String, dynamic> json) => Book(
        title: stripMarkup(json["title"]?.toString()),
        image: json["image"] ?? "",
        auth: stripMarkup(json["auth"]?.toString()),
        content: json["content"] ?? "",
        rating: (json["rating"] is num)
            ? (json["rating"] as num).toDouble()
            : double.tryParse('${json["rating"]}') ?? 0,
        isImageBook: json["type"] == "image",
        pageCount: (json["pageCount"] is num)
            ? (json["pageCount"] as num).toInt()
            : int.tryParse('${json["pageCount"]}') ?? 0,
        pagePrefix: json["pagePrefix"] ?? "",
      );

  /// File name of the [pageNumber]th page (1-based) of an image book,
  /// e.g. `folktales-1979-p001.jpg`.
  static String imagePageFileName(String prefix, int pageNumber) =>
      '$prefix-p${pageNumber.toString().padLeft(3, '0')}.jpg';

  // Helper to get local image path
  String? localImagePath;
  void setLocalImagePath(String path) {
    localImagePath = path;
  }
}
