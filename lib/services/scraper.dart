import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:html/parser.dart' as parser;
import '../models/book.dart';
import '../models/chapter.dart';

class Scraper {
  final Dio _dio = Dio();

  /// Lấy dữ liệu truyện từ URL danh sách chương
  Future<Book?> fetchBookData(String url) async {
    try {
      // Tải HTML trang danh sách chương với header User-Agent
      var response = await _dio.get(url, options: Options(
        headers: {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'},
      ));
      var document = parser.parse(response.data);

      // Lấy tiêu đề truyện
      String title = document
              .querySelector("h1[itemProp='name'] a")
              ?.text
              .trim() ??
          "Không có tiêu đề";

      List<Chapter> chapters = [];

      // Lấy danh sách chương
      var chapterElements = document.querySelectorAll("div.grow.font-medium.text-base.capitalize a");
      if (chapterElements.isEmpty) {
        print('Không tìm thấy danh sách chương với selector div.grow.font-medium.text-base.capitalize a');
      }
      for (var element in chapterElements) {
        String chapterTitle = element.text.trim();
        String chapterUrl = element.attributes['href'] ?? '';
        if (chapterUrl.isEmpty) continue;

        // Nếu URL là tương đối, ghép với domain
        if (!chapterUrl.startsWith('http')) {
          chapterUrl = 'https://cvtruyenchu.com' + chapterUrl;
        }

        // Tải nội dung chương
        String content = await _fetchChapterContent(chapterUrl);

        chapters.add(Chapter(title: chapterTitle, url: chapterUrl, content: content));
      }

      return Book(title: title, chapters: chapters);
    } catch (e) {
      print('Lỗi khi tải dữ liệu truyện: $e');
      return null;
    }
  }

  /// Hàm tải nội dung chương từ URL
  Future<String> _fetchChapterContent(String chapterUrl) async {
    try {
      var response = await _dio.get(chapterUrl, options: Options(
        headers: {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'},
      ));
      var document = parser.parse(response.data);

      // Tìm thẻ <script> chứa JSON
      var scriptTag = document.querySelector('script#__NEXT_DATA__');
      if (scriptTag == null) {
        return 'Không tìm thấy nội dung chương.';
      }

      // Parse JSON từ nội dung thẻ <script>
      var jsonData = jsonDecode(scriptTag.text ?? '');
      var content = jsonData['props']['pageProps']['chapter']['content'] ?? '';

      // Trả về nội dung chương
      return content.isNotEmpty ? content : 'Không tìm thấy nội dung chương.';
    } catch (e) {
      print('Lỗi khi tải nội dung chương từ $chapterUrl: $e');
      return 'Lỗi khi tải nội dung chương.';
    }
  }
}
