import 'package:book_app/models/books/book_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('image page file names are zero-padded to 3 digits', () {
    expect(Book.imagePageFileName('folktales-1979', 1),
        'folktales-1979-p001.jpg');
    expect(Book.imagePageFileName('folktales-1979', 27),
        'folktales-1979-p027.jpg');
    expect(Book.imagePageFileName('folktales-1979', 274),
        'folktales-1979-p274.jpg');
  });

  test('image book JSON parses', () {
    final book = Book.fromJson({
      'title': 'test title',
      'image': 'folktales-1979.jpg',
      'auth': 'test author',
      'content': 'test description',
      'rating': 4.9,
      'type': 'image',
      'pageCount': 274,
      'pagePrefix': 'folktales-1979',
    });
    expect(book.isImageBook, isTrue);
    expect(book.pageCount, 274);
    expect(book.pagePrefix, 'folktales-1979');
    expect(book.title, 'test title');
  });

  test('text book JSON stays a text book', () {
    final book = Book.fromJson({
      'title': 'test',
      'rating': 4,
    });
    expect(book.isImageBook, isFalse);
    expect(book.pageCount, 0);
    expect(book.pagePrefix, isEmpty);
  });

  test('Book.fetch of an image-book items list yields one chapter', () {
    final book = Book.fetch([
      {
        'title': 'test title',
        'image': 'folktales-1979.jpg',
        'auth': 'test author',
        'content': 'test description',
        'rating': 4.9,
        'type': 'image',
        'pageCount': 274,
        'pagePrefix': 'folktales-1979',
      }
    ]);
    expect(book.isImageBook, isTrue);
    expect(book.pageCount, 274);
    expect(book.chapters, hasLength(1));
  });
}
