class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String category;
  final bool isFeatured;
  final bool isBestSeller;
  final String gender;
  final List<String> colors;
  final List<String> sizes;
  final double averageRating;
  final int reviewCount;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.category,
    required this.isFeatured,
    required this.isBestSeller,
    required this.gender,
    required this.colors,
    required this.sizes,
    this.averageRating = 0.0,
    this.reviewCount = 0,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    // Helper to safely parse price whether it comes as int or double
    double parsePrice(dynamic value) {
      if (value is int) return value.toDouble();
      if (value is double) return value;
      return 0.0;
    }

    return Product(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: parsePrice(json['price']),
      imageUrl: json['imageUrl'] ?? '',
      category: json['category'] ?? '',
      isFeatured: json['isFeatured'] ?? false,
      isBestSeller: json['isBestSeller'] ?? false,
      gender: json['gender'] ?? 'Unisex',
      colors: List<String>.from(json['colors'] ?? []),
      sizes: List<String>.from(json['sizes'] ?? []),
      averageRating: (json['averageRating'] ?? 0).toDouble(),
      reviewCount: json['reviewCount'] ?? 0,
    );
  }
}
