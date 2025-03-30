import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:html/parser.dart' as parser;
import 'package:logging/logging.dart';
import '../models/book.dart';
import '../models/chapter.dart';

final _logger = Logger('Scraper');

class Scraper {
  final Dio _dio = Dio();

  /// Fetch content directly using Dio
  Future<String> fetchContentDirectly(String url) async {
    try {
      var response = await _dio.get(url);

      if (response.statusCode == 200) {
        return response.data;
      } else {
        print('Failed to fetch content: ${response.statusCode}');
        _logger.severe('Failed to fetch content: ${response.statusCode}');
        return 'Lỗi khi tải nội dung chương.';
      }
    } catch (e) {
      print('Error fetching content: $e');
      _logger.severe('Error fetching content: $e');
      return 'Lỗi khi tải nội dung chương.';
    }
  }

  /// Fetch content using Puppeteer proxy
  Future<String> fetchContentWithPuppeteer(String url) async {
    try {
      var response = await _dio.post(
        'http://localhost:3000/scrape', // Puppeteer service endpoint
        data: {'url': url},
      );

      if (response.statusCode == 200) {
        return response.data['content'];
      } else {
        print('Puppeteer service returned error: ${response.data}');
        _logger.severe('Failed to fetch content with Puppeteer: ${response.data}');
        return 'Lỗi khi tải nội dung chương.';
      }
    } catch (e) {
      print('Error connecting to Puppeteer service: $e');
      _logger.severe('Error connecting to Puppeteer service: $e');
      return 'Lỗi khi tải nội dung chương.';
    }
  }

  /// Lấy dữ liệu sách từ URL danh sách chương
  Future<Book?> fetchBookData(String url) async {
    try {
      print('Đang lấy dữ liệu sách từ URL: $url'); // Log URL đầu vào
      String pageContent = await fetchContentWithPuppeteer(url); // Use Puppeteer proxy

      // Log nội dung trang đã lấy để kiểm tra
      print('Nội dung trang sách đã lấy: $pageContent');

      var document = parser.parse(pageContent);

      String title = document.querySelector("h1[itemProp='name'] a")?.text.trim() ?? "Không có tiêu đề";
      print('Tiêu đề sách: $title'); // Log tiêu đề sách

      List<Chapter> chapters = [];
      var chapterElements = document.querySelectorAll("div.grow.font-medium.text-base.capitalize a");

      for (var element in chapterElements) {
        String chapterTitle = element.text.trim();
        String chapterUrl = element.attributes['href'] ?? '';
        print('URL chương gốc: $chapterUrl'); // Log URL chương gốc

        if (chapterUrl.isEmpty) continue;

        // Đảm bảo URL chương là tuyệt đối
        if (!chapterUrl.startsWith('http')) {
          chapterUrl = 'https://cvtruyenchu.com$chapterUrl';
        }
        print('URL chương đã định dạng: $chapterUrl'); // Log URL chương đã định dạng

        chapters.add(Chapter(title: chapterTitle, url: chapterUrl, content: ""));
      }

      if (chapters.isEmpty) {
        print('Không tìm thấy chương nào trên trang.');
        return null;
      }

      return Book(title: title, chapters: chapters);
    } catch (e) {
      _logger.severe('Lỗi khi lấy dữ liệu sách: $e');
      return null;
    }
  }

  /// Lấy nội dung chương
  Future<String> fetchChapterContent(String chapterUrl) async {
    try {
      print('Đang lấy nội dung chương từ URL: $chapterUrl'); // Log URL chương
      String pageContent = await fetchContentWithPuppeteer(chapterUrl); // Use Puppeteer proxy

      // Log nội dung trang đã lấy để kiểm tra
      print('Nội dung trang chương đã lấy: $pageContent');

      var document = parser.parse(pageContent);

      var scriptTag = document.querySelector('script#__NEXT_DATA__');
      if (scriptTag == null) {
        print('Không tìm thấy thẻ script cho URL: $chapterUrl'); // Log nếu không tìm thấy thẻ script
        return 'Không tìm thấy nội dung chương.';
      }

      var jsonData = jsonDecode(scriptTag.text);
      var content = jsonData['props']['pageProps']['chapter']['content'] ?? '';

      if (content.isEmpty) {
        print('Nội dung chương trống cho URL: $chapterUrl');
      }

      return content.isNotEmpty ? content : 'Không tìm thấy nội dung chương.';
    } catch (e) {
      _logger.severe('Lỗi khi lấy nội dung chương từ $chapterUrl: $e');
      return 'Lỗi khi tải nội dung chương.';
    }
  }
}
