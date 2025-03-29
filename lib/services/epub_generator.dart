import 'dart:io';
import 'package:epubx/epubx.dart';
import '../models/book.dart';

class EpubGenerator {
  static Future<void> createEpub(Book book) async {
    var epub = EpubBook();
    epub.Title = book.title;

    for (var chapter in book.chapters) {
      var epubChapter = EpubChapter()
        ..Title = chapter.title
        ..HtmlContent = "<h1>${chapter.title}</h1><p>${chapter.content}</p>";
      epub.Chapters?.add(epubChapter);
    }

    var bytes = EpubWriter.writeBook(epub); // Access static method correctly
    if (bytes != null) { // Handle nullable type
      File("/storage/emulated/0/Download/${book.title}.epub").writeAsBytes(bytes);
    } else {
      throw Exception("Failed to generate EPUB bytes.");
    }
  }
}
