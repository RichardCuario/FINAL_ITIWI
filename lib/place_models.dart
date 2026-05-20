class Place {
  const Place({
    required this.id,
    required this.name,
    required this.description,
    required this.location,
    required this.shortLocation,
    required this.fullAddress,
    required this.imageUrl,
    required this.category,
    required this.phone,
    required this.websiteUrl,
    required this.latitude,
    required this.longitude,
    required this.distanceLabel,
    required this.isFeatured,
    required this.averageRating,
    required this.reviewCount,
  });

  final String id;
  final String name;
  final String description;
  final String location;
  final String shortLocation;
  final String fullAddress;
  final String imageUrl;
  final String category;
  final String phone;
  final String websiteUrl;
  final double? latitude;
  final double? longitude;
  final String distanceLabel;
  final bool isFeatured;
  final double averageRating;
  final int reviewCount;

  factory Place.fromMap(Map<String, dynamic> map) {
    return Place(
      id: (map['id'] ?? '').toString(),
      name: (map['name'] ?? map['title'] ?? 'Unknown place').toString(),
      description: (map['description'] ?? '').toString(),
      location: (map['location'] ??
              map['short_location'] ??
              map['full_address'] ??
              map['barangay'] ??
              '')
          .toString(),
      shortLocation: (map['short_location'] ?? '').toString(),
      fullAddress: (map['full_address'] ?? '').toString(),
      imageUrl: (map['image_url'] ?? map['imageUrl'] ?? '').toString(),
      category: (map['category'] ?? '').toString(),
      phone: (map['phone'] ?? '').toString(),
      websiteUrl: (map['website_url'] ?? map['websiteUrl'] ?? '').toString(),
      latitude: _toNullableDouble(map['latitude']),
      longitude: _toNullableDouble(map['longitude']),
      distanceLabel: (map['distance_label'] ?? '').toString(),
      isFeatured: map['is_featured'] == true,
      averageRating: _toDouble(
        map['average_rating'] ?? map['avg_rating'] ?? map['rating'] ?? 0,
      ),
      reviewCount: _toInt(map['review_count'] ?? map['ratings_count'] ?? 0),
    );
  }

  Place copyWith({
    String? id,
    String? name,
    String? description,
    String? location,
    String? shortLocation,
    String? fullAddress,
    String? imageUrl,
    String? category,
    String? phone,
    String? websiteUrl,
    double? latitude,
    double? longitude,
    String? distanceLabel,
    bool? isFeatured,
    double? averageRating,
    int? reviewCount,
  }) {
    return Place(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      location: location ?? this.location,
      shortLocation: shortLocation ?? this.shortLocation,
      fullAddress: fullAddress ?? this.fullAddress,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      phone: phone ?? this.phone,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      distanceLabel: distanceLabel ?? this.distanceLabel,
      isFeatured: isFeatured ?? this.isFeatured,
      averageRating: averageRating ?? this.averageRating,
      reviewCount: reviewCount ?? this.reviewCount,
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double? _toNullableDouble(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) {
      return null;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value.toString());
  }

  static int _toInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class PlaceReview {
  const PlaceReview({
    required this.id,
    required this.placeId,
    required this.rating,
    required this.reviewText,
    required this.reviewerName,
    required this.createdAt,
  });

  final String id;
  final String placeId;
  final int rating;
  final String reviewText;
  final String reviewerName;
  final DateTime? createdAt;

  factory PlaceReview.fromMap(Map<String, dynamic> map) {
    return PlaceReview(
      id: (map['id'] ?? '').toString(),
      placeId: (map['place_id'] ?? '').toString(),
      rating: Place._toInt(map['rating']),
      reviewText: (map['review'] ?? map['review_text'] ?? map['comment'] ?? '').toString(),
      reviewerName: (map['reviewer_name'] ?? map['user_name'] ?? map['full_name'] ?? 'Anonymous').toString(),
      createdAt: DateTime.tryParse((map['created_at'] ?? '').toString()),
    );
  }
}
