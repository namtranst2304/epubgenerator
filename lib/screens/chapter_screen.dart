import 'package:flutter/material.dart';
import '../models/chapter.dart';

class ChapterScreen extends StatelessWidget {
  final Chapter chapter;

  const ChapterScreen({super.key, required this.chapter});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(chapter.title)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(child: Text(chapter.content)),
      ),
    );
  }
}
