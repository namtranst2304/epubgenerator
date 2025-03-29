import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:html/parser.dart';
import '../models/book.dart';
import '../models/chapter.dart';

class Scraper {
  static Future<Book> fetchBook(String url) async {
    // Lấy HTML của trang mục lục với User-Agent giả lập trình duyệt
    var response = await Dio().get(url, options: Options(
      headers: {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'},
    ));
    var document = parse(response.data);

    // Trích xuất tiêu đề truyện từ <h1 itemProp="name"><a>...</a></h1>
    String title = document.querySelector("h1[itemProp='name'] a")?.text.trim() ?? "Không có tiêu đề";

    List<Chapter> chapters = [];

    // Tìm script có id __NEXT_DATA__ để lấy dữ liệu JSON
    var nextDataScript = document.querySelector("#__NEXT_DATA__");
    if (nextDataScript != null) {
      try {
        var jsonData = jsonDecode(nextDataScript.text);
        // Lấy danh sách các chương từ "latestList" trong JSON (chỉ là danh sách các chương mới nhất)
        List<dynamic> latestList = jsonData["props"]["pageProps"]["latestList"];
        for (var chap in latestList) {
          String chapterTitle = chap["name"] ?? "";
          String chapterSlug = chap["slug"] ?? "";
          // Sinh URL đầy đủ cho chương
          String chapterUrl = "https://cvtruyenchu.com/truyen/bi-thuat-chi-chu/" + chapterSlug;
          print("Đang tải chương: $chapterTitle");
          print("Chapter URL: $chapterUrl");

          try {
            var chapResponse = await Dio().get(chapterUrl, options: Options(
              headers: {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'},
            ));
            var chapDoc = parse(chapResponse.data);
            // Thử lấy nội dung chương từ selector ".chapter-content" hoặc ".html-content"
            String content = chapDoc.querySelector(".chapter-content")?.innerHtml.trim() ?? "";
            if (content.isEmpty) {
              content = chapDoc.querySelector(".html-content")?.innerHtml.trim() ?? "";
            }
            if (content.isEmpty) {
              print("Không lấy được nội dung cho chương: $chapterTitle");
            }
            chapters.add(Chapter(title: chapterTitle, content: content));
          } catch (e) {
            print("Lỗi tải chương '$chapterTitle': $e");
          }
        }
      } catch (e) {
        print("Lỗi khi phân tích JSON __NEXT_DATA__: $e");
      }
    } else {
      // Nếu không có JSON, sử dụng fallback (ví dụ: dùng các span có class "page-book-detail_chapterLink__0VTaF")
      var chapterElements = document.querySelectorAll("span.page-book-detail_chapterLink__0VTaF");
      if (chapterElements.isEmpty) {
        print("Không tìm thấy danh sách chương với selector span.page-book-detail_chapterLink__0VTaF");
      }
      for (var chapterElement in chapterElements) {
        String chapterTitle = chapterElement.text.trim();
        String chapterSlug = generateChapterSlug(chapterTitle);
        String chapterUrl = "https://cvtruyenchu.com/truyen/bi-thuat-chi-chu/" + chapterSlug;
        print("Đang tải chương: $chapterTitle");
        print("Chapter URL: $chapterUrl");
        try {
          var chapResponse = await Dio().get(chapterUrl, options: Options(
            headers: {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'},
          ));
          var chapDoc = parse(chapResponse.data);
          String content = chapDoc.querySelector(".chapter-content")?.innerHtml.trim() ?? "";
          if (content.isEmpty) {
            content = chapDoc.querySelector(".html-content")?.innerHtml.trim() ?? "";
          }
          if (content.isEmpty) {
            print("Không lấy được nội dung cho chương: $chapterTitle");
          }
          chapters.add(Chapter(title: chapterTitle, content: content));
        } catch (e) {
          print("Lỗi tải chương '$chapterTitle': $e");
        }
      }
    }

    return Book(title: title, chapters: chapters);
  }

  static String generateChapterSlug(String chapterTitle) {
    // Nếu tiêu đề bắt đầu bằng "Chương ", loại bỏ phần này
    String title = chapterTitle;
    if (title.startsWith("Chương ")) {
      title = title.substring(7);
    }
    // Loại bỏ nội dung trong ngoặc và dấu hai chấm
    title = title.replaceAll(RegExp(r"\(.*?\)"), "").replaceAll(":", "").trim();
    // Chuyển thành chữ thường, thay khoảng trắng bằng dấu gạch ngang
    title = title.toLowerCase().replaceAll(" ", "-");
    // Loại bỏ nhiều dấu gạch ngang liên tiếp
    title = title.replaceAll(RegExp(r"-+"), "-");
    return "chuong-" + title;
  }
}
