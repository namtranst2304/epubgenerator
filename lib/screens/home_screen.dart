import 'package:flutter/material.dart';
import 'toc_screen.dart';
import '../services/scraper.dart';
import '../services/epub_generator.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final TextEditingController _urlController = TextEditingController();
  String _status = "";
  var book;

  Future<void> _downloadBook() async {
    String url = _urlController.text.trim();
    if (url.isEmpty) {
      setState(() {
        _status = "Vui lòng nhập URL!";
      });
      return;
    }

    setState(() {
      _status = "Đang tải truyện...";
    });

    try {
      book = await Scraper.fetchBook(url);
      await EpubGenerator.createEpub(book);
      setState(() {
        _status = "Tạo file ePub thành công!";
      });
    } catch (e) {
      setState(() {
        _status = "Lỗi: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ebook Converter")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: "Nhập link truyện",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _downloadBook,
              child: const Text("Tải truyện & tạo ePub"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (context) => TOCScreen(book: book),
                ));
              },
              child: const Text("Xem nội dung truyện"),
            ),
            const SizedBox(height: 20),
            Text(_status, style: const TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }
}
