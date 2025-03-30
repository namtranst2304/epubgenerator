import 'package:flutter/material.dart';
import '../models/book.dart';
import '../services/scraper.dart';
import '../services/epub_generator.dart';
import 'toc_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final TextEditingController _urlController = TextEditingController();
  String _status = '';
  Book? _book;

  // Hàm lấy dữ liệu truyện và tạo file ePub
  Future<void> _fetchAndGenerateEpub() async {
    String url = _urlController.text.trim();
    if (url.isEmpty) {
      setState(() {
        _status = 'Vui lòng nhập URL!';
      });
      return;
    }
    setState(() {
      _status = 'Đang lấy dữ liệu truyện...';
    });
    try {
      // Sử dụng Scraper để lấy thông tin Book từ URL danh sách chương
      Book? book = await Scraper().fetchBookData(url);
      if (book != null) {
        _book = book;
        setState(() {
          _status = 'Đang tạo file ePub...';
        });
        // Generate EPUB with chapter content
        await EpubGenerator().generateEpub(book);
        setState(() {
          _status = 'Tạo file ePub thành công!';
        });
      } else {
        setState(() {
          _status = 'Không tìm thấy dữ liệu truyện. Vui lòng kiểm tra URL.';
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
      MaterialPageRoute(builder: (context) => TOCScreen(book: _book!)),
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
              onPressed: _fetchAndGenerateEpub,
              child: const Text('Tải truyện & tạo ePub'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _goToTOC,
              child: const Text('Xem nội dung truyện'),
            ),
            const SizedBox(height: 20),
            Text(_status, style: const TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }
}
