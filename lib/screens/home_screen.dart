import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';
import 'package:flutter/foundation.dart'; // For platform checks
import 'dart:html' as html; // For web download
import '../models/book.dart';
import '../services/scraper.dart';
import 'toc_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final TextEditingController _urlController = TextEditingController();
  String _status = '';
  final Scraper _scraper = Scraper();
  Book? _book;

  Future<void> _fetchAndGenerateFile(String type) async {
    String url = _urlController.text.trim();
    if (url.isEmpty) {
      setState(() {
        _status = 'Vui lòng nhập URL!';
      });
      return;
    }

    setState(() {
      _status = 'Đang tải truyện và tạo file $type...';
    });

    try {
      // Fetch book data
      _book = await _scraper.fetchBookData(url);
      if (_book == null) {
        setState(() {
          _status = 'Không tìm thấy dữ liệu truyện. Vui lòng kiểm tra URL.';
        });
        return;
      }

      // Fetch content for each chapter
      bool isFirstFetch = true; // Track if this is the first fetch
      int currentIndex = 0; // Start from the first chapter

      while (currentIndex < _book!.chapters.length) {
        var chapter = _book!.chapters[currentIndex];

        if (chapter.content.isEmpty) {
          // Apply a 10-second delay only after the first fetch
          if (isFirstFetch) {
            await Future.delayed(const Duration(seconds: 10)); // Delay for 10 seconds
            isFirstFetch = false; // Mark the first fetch as completed
            currentIndex = 0; // Restart fetching from the first chapter
            continue;
          }

          // Fetch chapter content
          chapter.content = await _scraper.fetchChapterContent(chapter.url);

          // Preserve original HTML structure (no additional formatting)
          // No further processing is applied to the content
        }

        // Move to the next chapter
        currentIndex++;
      }

      // Generate file
      final response = await http.post(
        Uri.parse('http://localhost:3000/generate-$type'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': type == 'epub' ? 'GenEpub' : 'GenWord',
          'chapters': _book!.chapters.map((c) => {
            'title': c.title,
            'url': c.url,
            'content': c.content, // Preserve original HTML content
          }).toList(),
        }),
      );

      if (response.statusCode == 200) {
        final filePath = jsonDecode(response.body)['filePath'];
        final fileName = filePath.split('/').last;

        // Fetch the file from the backend
        final downloadResponse = await http.get(Uri.parse('http://localhost:3000/download?filePath=$filePath'));

        if (kIsWeb) {
          // Provide a download link for the file
          final blob = html.Blob([downloadResponse.bodyBytes]);
          final url = html.Url.createObjectUrlFromBlob(blob);
          final anchor = html.AnchorElement(href: url)
            ..target = 'blank'
            ..download = fileName;
          anchor.click();
          html.Url.revokeObjectUrl(url);

          setState(() {
            _status = 'Tạo file $type thành công! File đã sẵn sàng để tải xuống.';
          });
        } else {
          // Save the file locally (only if not running on web)
          final directory = await getApplicationDocumentsDirectory();
          final localFile = File('${directory.path}/$fileName');
          await localFile.writeAsBytes(downloadResponse.bodyBytes);

          setState(() {
            _status = 'Tạo file $type thành công! Lưu tại: ${localFile.path}';
          });

          // Allow the user to share or download the file
          Share.shareXFiles([XFile(localFile.path)], text: 'Tải xuống file $type: $fileName');
        }
      } else {
        setState(() {
          _status = 'Lỗi khi tạo file $type: ${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Lỗi: $e';
      });
    }
  }

  // Chuyển sang màn hình danh sách chương
  void _goToTOC() {
    if (_book == null) {
      setState(() {
        _status = 'Chưa có dữ liệu truyện để xem.';
      });
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TOCScreen(book: _book!)), // Pass _book instead of _scraper
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Epub Generator')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText:
                    'Nhập URL danh sách chương (ví dụ: https://cvtruyenchu.com/truyen/bi-thuat-chi-chu/danh-sach-chuong?page=2)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => _fetchAndGenerateFile('epub'),
              child: const Text('Tải truyện và tạo file EPUB'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _goToTOC,
              child: const Text('Xem nội dung truyện'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => _fetchAndGenerateFile('word'),
              child: const Text('Tải truyện và tạo file Word'),
            ),
            const SizedBox(height: 20),
            Text(_status, style: const TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }
}
