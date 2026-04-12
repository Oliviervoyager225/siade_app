import 'package:siade2/src/core/constants/api_constants.dart';

class CatererMedia {
  final int id;
  final String? title;
  final String? file;
  final String? mediaType;

  CatererMedia({required this.id, this.title, this.file, this.mediaType});

  factory CatererMedia.fromJson(Map<String, dynamic> json) {
    String? file = json['file'] as String?;
    if (file != null && file.isNotEmpty && !file.startsWith('http')) {
      file = '${ApiConstants.baseUrl}$file';
    }
    return CatererMedia(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String?,
      file: file,
      mediaType: json['media_type'] as String?,
    );
  }
}

class Dish {
  final int id;
  final String name;
  final String description;
  final String price;
  final String? date;
  final String? availabilitySchedule;
  final String? photoUrl;
  final bool isActive;

  Dish({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.date,
    this.availabilitySchedule,
    this.photoUrl,
    this.isActive = true,
  });

  bool get isMatin {
    final s = (availabilitySchedule ?? '').toLowerCase();
    return s.contains('matin') || s.contains('morning') || s.contains('midi');
  }

  bool get isSoir {
    final s = (availabilitySchedule ?? '').toLowerCase();
    return s.contains('soir') || s.contains('evening') || s.contains('dinner');
  }

  factory Dish.fromJson(Map<String, dynamic> json) {
    String? photo = json['photo'] as String?;
    if (photo != null && photo.isNotEmpty && !photo.startsWith('http')) {
      photo = '${ApiConstants.baseUrl}$photo';
    }
    return Dish(
      id: json['id'] as int? ?? 0,
      name: (json['name'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      price: (json['price'] ?? '').toString(),
      date: json['date'] as String?,
      availabilitySchedule: json['availability_schedule'] as String?,
      photoUrl: photo?.isNotEmpty == true ? photo : null,
      isActive: (json['is_active'] as bool?) ?? true,
    );
  }
}

class Caterer {
  final int id;
  final String name;
  final String description;
  final String? logoUrl;
  final String? cuisineType;
  final String? websiteUrl;
  final String? menu;
  final String? contactEmail;
  final String? contactPhone;
  final String? slug;
  final bool isActive;
  final List<CatererMedia> gallery;
  final List<Dish> dishes;

  Caterer({
    required this.id,
    required this.name,
    required this.description,
    this.logoUrl,
    this.cuisineType,
    this.websiteUrl,
    this.menu,
    this.contactEmail,
    this.contactPhone,
    this.slug,
    this.isActive = true,
    this.gallery = const [],
    this.dishes = const [],
  });

  List<Dish> get matinDishes => dishes.where((d) => d.isMatin).toList();
  List<Dish> get soirDishes => dishes.where((d) => d.isSoir).toList();
  List<Dish> get activeDishes => dishes.where((d) => d.isActive).toList();

  factory Caterer.fromJson(Map<String, dynamic> json) {
    String? logo = json['logo'] as String?;
    if (logo != null && logo.isNotEmpty && !logo.startsWith('http')) {
      logo = '${ApiConstants.baseUrl}$logo';
    }

    String? menu = json['menu'] as String?;
    if (menu != null && menu.isNotEmpty && !menu.startsWith('http')) {
      menu = '${ApiConstants.baseUrl}$menu';
    }

    final galleryRaw = json['gallery'] as List<dynamic>? ?? [];
    final dishesRaw = json['dishes'] as List<dynamic>? ?? [];

    return Caterer(
      id: json['id'] as int? ?? 0,
      name: (json['name'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      logoUrl: (logo != null && logo.isNotEmpty) ? logo : null,
      cuisineType: json['cuisine_type'] as String?,
      websiteUrl: json['website_url'] as String?,
      menu: (menu != null && menu.isNotEmpty) ? menu : null,
      contactEmail: json['contact_email'] as String?,
      contactPhone: json['contact_phone'] as String?,
      slug: json['slug'] as String?,
      isActive: (json['is_active'] as bool?) ?? true,
      gallery: galleryRaw.map((g) => CatererMedia.fromJson(g as Map<String, dynamic>)).toList(),
      dishes: dishesRaw.map((d) => Dish.fromJson(d as Map<String, dynamic>)).toList(),
    );
  }
}
