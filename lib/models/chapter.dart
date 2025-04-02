class Chapter {
  final String title;
  final String url;
  String content; // Remove 'final' to make it mutable

  Chapter({required this.title, required this.url, this.content = ''});
}
