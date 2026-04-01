import 'package:supabase_flutter/supabase_flutter.dart';

import 'place_models.dart';

class PlaceService {
  PlaceService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<Place>> fetchPlaces() async {
    try {
      final response = await _client.from('places').select();
      final placeMaps = List<Map<String, dynamic>>.from(response as List);
      final places = placeMaps.map(Place.fromMap).toList();

      final enrichedPlaces = await Future.wait(
        places.map((place) async {
          final reviews = await fetchReviews(place.id);
          if (reviews.isEmpty) {
            return place;
          }

          final average = reviews.fold<int>(0, (sum, item) => sum + item.rating) / reviews.length;
          return place.copyWith(
            averageRating: average,
            reviewCount: reviews.length,
          );
        }),
      );

      enrichedPlaces.sort((a, b) => a.name.compareTo(b.name));
      return enrichedPlaces;
    } catch (_) {
      return const <Place>[];
    }
  }

  Future<List<PlaceReview>> fetchReviews(String placeId) async {
    try {
      final response = await _client
          .from('place_reviews')
          .select()
          .eq('place_id', placeId)
          .order('created_at', ascending: false);

      final reviewMaps = List<Map<String, dynamic>>.from(response as List);
      return reviewMaps.map(PlaceReview.fromMap).toList();
    } catch (_) {
      return const <PlaceReview>[];
    }
  }

  Future<void> submitReview({
    required String placeId,
    required int rating,
    required String reviewText,
  }) async {
    final user = _client.auth.currentUser;

    await _client.from('place_reviews').insert({
      'place_id': placeId,
      'rating': rating,
      'review': reviewText.trim(),
      'reviewer_name': user?.email ?? user?.userMetadata?['full_name'] ?? 'Anonymous',
      if (user != null) 'user_id': user.id,
    });
  }
}