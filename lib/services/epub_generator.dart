import 'package:epubx/epubx.dart';
import '../models/book.dart';

class EpubGenerator {
  Future<void> generateEpub(Book book) async {
    try {
      var epub = EpubBook();
      epub.Title = book.title;
      epub.Chapters = [];

      for (var chapter in book.chapters) {
        var contentHtml = chapter.content.isNotEmpty
            ? '<h1>${chapter.title}</h1>' + chapter.content
            : '<h1>${chapter.title}</h1><p>Nội dung chưa được tải.</p>';
        var epubChapter = EpubChapter()
          ..Title = chapter.title
          ..HtmlContent = contentHtml;
        epub.Chapters!.add(epubChapter);
      }

      var bytes = EpubWriter.writeBook(epub);

      if (bytes != null) {
        // Sử dụng bytes để lưu file hoặc thực hiện hành động khác
        print('ePub file generated with ${bytes.length} bytes.');
      } else {
        print('Failed to generate ePub file: bytes is null.');
      }
    } catch (e) {
      print('Lỗi khi tạo ePub: $e');
    }
  }
}
