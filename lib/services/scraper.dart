import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:html/parser.dart' as parser;
import 'package:logging/logging.dart';
import '../models/book.dart';
import '../models/chapter.dart';

final _logger = Logger('Scraper');

class Scraper {
  final Dio _dio = Dio();

  /// Thực hiện GET request và trả về nội dung response (dưới dạng String)
  Future<String> _fetchUrl(String url) async {
    try {
      Response response = await _dio.get(url);
      if (response.statusCode == 200) {
        return response.data.toString();
      } else {
        _logger.severe('Failed to fetch content from $url: ${response.statusCode}');
        return 'Lỗi khi tải nội dung chương.';
      }
    } catch (e) {
      _logger.severe('Error fetching content from $url: $e');
      return 'Lỗi khi tải nội dung chương.';
    }
  }

  /// Fetch content trực tiếp sử dụng Dio
  Future<String> fetchContentDirectly(String url) async {
    return await _fetchUrl(url);
  }

  /// Kiểm tra trạng thái của Selenium service qua endpoint /status
  Future<bool> isSeleniumServiceAvailable() async {
    try {
      Response response = await _dio.get('http://localhost:3000/status'); // Ensure the backend URL is correct
      return response.statusCode == 200;
    } catch (e) {
      _logger.warning('Selenium service is not available: $e');
      return false;
    }
  }

  /// Fetch content qua Selenium proxy, có fallback về fetchContentDirectly nếu Selenium không khả dụng
  Future<String> fetchContentWithSelenium(String url) async {
    if (!await isSeleniumServiceAvailable()) {
      _logger.warning('Selenium service is unavailable. Falling back to direct fetching for URL: $url');
      return fetchContentDirectly(url);
    }

    try {
      Response response = await _dio.post(
        'http://localhost:3000/scrape', // Ensure the backend URL is correct
        data: {'url': url},
      );

      if (response.statusCode == 200 && response.data is Map && response.data['content'] != null) {
        return response.data['content'].toString();
      } else {
        _logger.severe('Failed to fetch content with Selenium for URL $url: ${response.data}');
        return 'Lỗi khi tải nội dung chương.';
      }
    } catch (e) {
      _logger.severe('Error connecting to Selenium service for URL $url: $e');
      return 'Lỗi khi tải nội dung chương.';
    }
  }

  /// Lấy dữ liệu sách từ URL danh sách chương
  Future<Book?> fetchBookData(String url) async {
    _logger.info('Đang lấy dữ liệu sách từ URL: $url');
    try {
      String pageContent = await fetchContentWithSelenium(url);

      // Kiểm tra nội dung trả về có chứa thông báo lỗi không
      if (pageContent.contains('Lỗi khi tải nội dung chương')) {
        _logger.severe('Failed to fetch page content from $url.');
        return null;
      }

      var document = parser.parse(pageContent);

      // Lấy tiêu đề sách từ thẻ h1 có itemProp='name'
      String title = document.querySelector("h1[itemProp='name'] a")?.text.trim() ?? "";
      if (title.isEmpty) {
        _logger.warning('Không tìm thấy tiêu đề sách. Sử dụng tiêu đề mặc định.');
        title = "NoTitle"; // Set default title if not found
      }
      _logger.info('Tiêu đề sách: $title');

      List<Chapter> chapters = [];
      var chapterElements = document.querySelectorAll("div.grow.font-medium.text-base.capitalize a");

      for (var element in chapterElements) {
        String chapterTitle = element.text.trim();
        String chapterUrl = element.attributes['href'] ?? '';
        if (chapterUrl.isEmpty) continue;

        if (!chapterUrl.startsWith('http')) {
          chapterUrl = 'https://cvtruyenchu.com$chapterUrl';
        }

        chapters.add(Chapter(title: chapterTitle, url: chapterUrl, content: ""));
      }

      if (chapters.isEmpty) {
        _logger.warning('Không tìm thấy chương nào trên trang.');
        return null;
      }

      return Book(title: title, chapters: chapters);
    } catch (e) {
      _logger.severe('Lỗi khi lấy dữ liệu sách từ $url: $e');
      return null;
    }
  }

  /// Lấy nội dung chương từ URL
  Future<String> fetchChapterContent(String chapterUrl) async {
    _logger.info('Đang lấy nội dung chương từ URL: $chapterUrl');
    try {
      String pageContent = await fetchContentWithSelenium(chapterUrl);
      var document = parser.parse(pageContent);

      // Tìm thẻ script chứa dữ liệu JSON của Next.js
      var scriptTag = document.querySelector('script#__NEXT_DATA__');
      if (scriptTag == null) {
        _logger.warning('Không tìm thấy thẻ script chứa dữ liệu JSON cho URL: $chapterUrl');
        return 'Không tìm thấy nội dung chương.';
      }

      var jsonData = jsonDecode(scriptTag.text);
      var content = jsonData['props']?['pageProps']?['chapter']?['content'] ?? '';
      if (content.toString().isEmpty) {
        _logger.warning('Nội dung chương trống cho URL: $chapterUrl');
      }
      return content.toString().isNotEmpty ? content.toString() : 'Không tìm thấy nội dung chương.';
    } catch (e) {
      _logger.severe('Lỗi khi lấy nội dung chương từ $chapterUrl: $e');
      return 'Lỗi khi tải nội dung chương.';
    }
  }
}
