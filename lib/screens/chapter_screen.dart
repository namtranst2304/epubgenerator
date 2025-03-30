import 'package:flutter/material.dart';
import '../models/chapter.dart';
import '../services/scraper.dart';

class ChapterScreen extends StatefulWidget {
  final Chapter chapter;
  const ChapterScreen({super.key, required this.chapter});

  @override
  ChapterScreenState createState() => ChapterScreenState();
}

class ChapterScreenState extends State<ChapterScreen> {
  final Scraper _scraper = Scraper();
  String _content = "Đang tải...";

  @override
  void initState() {
    super.initState();
    _loadChapterContent();
  }

  Future<void> _loadChapterContent() async {
    String content = await _scraper.fetchChapterContent(widget.chapter.url);
    setState(() {
      _content = content;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.chapter.title)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Text(_content),
        ),
      ),
    );
  }
}
