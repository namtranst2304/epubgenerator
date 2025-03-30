import 'package:flutter/material.dart';
import '../models/chapter.dart';

class Chapter {
  final String title;
  final String url;
  final String content;

  Chapter({required this.title, required this.url, required this.content});
}

class ChapterScreen extends StatelessWidget {
  final Chapter chapter;
  const ChapterScreen({super.key, required this.chapter});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(chapter.title)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Text(chapter.content.isNotEmpty
              ? chapter.content
              : 'Nội dung chương chưa được tải. URL: ${chapter.url}'),
        ),
      ),
    );
  }
}
