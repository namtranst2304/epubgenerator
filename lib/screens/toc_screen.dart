import 'package:flutter/material.dart';
import '../models/book.dart';
import 'chapter_screen.dart';

class TOCScreen extends StatelessWidget {
  final Book book;
  const TOCScreen({super.key, required this.book});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mục lục')),
      body: ListView.builder(
        itemCount: book.chapters.length,
        itemBuilder: (context, index) {
          final chapter = book.chapters[index];
          return ListTile(
            title: Text(chapter.title),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChapterScreen(chapter: chapter),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
