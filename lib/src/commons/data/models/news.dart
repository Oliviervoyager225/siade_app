import 'package:siade2/src/core/constants/api_constants.dart';

class Article {
  final int id;
  final String title;
  final String content;
  final String imageUrl;
  final String author;
  final String date;

  Article({
    required this.id,
    required this.title,
    required this.content,
    required this.imageUrl,
    required this.author,
    required this.date,
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    String img = json['image'] ?? '';
    if (img.isNotEmpty && !img.startsWith('http')) {
      img = "${ApiConstants.baseUrl}$img";
    }

    return Article(
      id: json['id'] ?? 0,
      title: json['title'] ?? 'Sans titre',
      content: json['content'] ?? json['text'] ?? '',
      imageUrl: img.isNotEmpty ? img : 'assets/images/default_news.png',
      author: json['author_name'] ?? 'SIADE',
      date: json['created_at'] ?? '',
    );
  }
}

// Keep the old 'New' class for compatibility if needed elsewhere, 
// but we will move towards Article.
class New {
  final String imageUrl;
  final String imageSender;

  New({required this.imageUrl, required this.imageSender});
}

final List<New> news = [
    New(
      imageUrl: 'assets/images/story_1.jpg',
      imageSender: 'assets/images/profile_image.jpg',
    ),
    New(
      imageUrl: 'assets/images/story_2.jpg',
      imageSender: 'assets/images/profile_image.jpg',
    ),
    New(
      imageUrl: 'assets/images/story_3.jpg',
      imageSender: 'assets/images/profile_image.jpg',
    ),
    New(
      imageUrl: 'assets/images/story_4.jpg',
      imageSender: 'assets/images/profile_image.jpg',
    ),
  ];