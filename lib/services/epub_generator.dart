import 'dart:io';
import 'package:epubx/epubx.dart';
import 'package:path_provider/path_provider.dart'; // Import path_provider
import '../models/book.dart';
import '../services/scraper.dart';

class EpubGenerator {
  final Scraper _scraper = Scraper(); // Initialize Scraper

  Future<void> generateEpub(Book book) async {
    try {
      var epub = EpubBook();
      epub.Title = book.title;
      epub.Chapters = [];

      for (var chapter in book.chapters) {
        // Fetch chapter content if not already available
        String content = chapter.content.isNotEmpty
            ? chapter.content
            : await _scraper.fetchChapterContent(chapter.url);

        if (content.isEmpty) {
          print('Chapter "${chapter.title}" has no content.');
          continue; // Skip chapters with no content
        }

        var contentHtml = '<h1>${chapter.title}</h1>$content';
        var epubChapter = EpubChapter()
          ..Title = chapter.title
          ..HtmlContent = contentHtml;
        epub.Chapters!.add(epubChapter);
      }

      if (epub.Chapters!.isEmpty) {
        print('No valid chapters found. Cannot generate ePub.');
        return;
      }

      var bytes = EpubWriter.writeBook(epub);

      if (bytes != null) {
        // Get the directory to save the file
        Directory appDocDir = await getApplicationDocumentsDirectory();
        String filePath = '${appDocDir.path}/${book.title}.epub';

        // Save the file
        File file = File(filePath);
        await file.writeAsBytes(bytes);

        print('ePub file saved at: $filePath');
      } else {
        print('Failed to generate ePub file: bytes is null.');
      }
    } catch (e) {
      print('Lỗi khi tạo ePub: $e');
    }
  }
}
