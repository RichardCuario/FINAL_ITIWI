import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'place_models.dart';

class PlaceService {
  PlaceService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<Place>> fetchPlaces() async {
    try {
      final response = await _client
          .from('places')
          .select(
            'id, name, description, location, short_location, full_address, image_url, category, phone, website_url, latitude, longitude, distance_label, is_featured, is_published',
          )
          .eq('is_published', true)
          .order('name');

      final placeMaps = List<Map<String, dynamic>>.from(response as List);
      final places = placeMaps
          .map(Place.fromMap)
          .where((place) => place.id.isNotEmpty && place.name.isNotEmpty)
          .toList();

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
    } catch (error) {
      // Helps surface Supabase/RLS issues while still keeping the UI stable.
      // ignore: avoid_print
      print('PlaceService.fetchPlaces error: $error');
      return const <Place>[];
    }
  }

  Future<List<PlaceReview>> fetchReviews(String placeId) async {
    try {
      final response = await _client
          .from('place_reviews')
          .select()
          .eq('place_id', placeId)
          .eq('status', 'approved')
          .order('created_at', ascending: false);

      final reviewMaps = List<Map<String, dynamic>>.from(response as List);
      return reviewMaps.map(PlaceReview.fromMap).toList();
    } catch (error) {
      // ignore: avoid_print
      print('PlaceService.fetchReviews error: $error');
      return const <PlaceReview>[];
    }
  }

  Future<void> submitReview({
    required String placeId,
    required int rating,
    required String reviewText,
  }) async {
    final supabaseUser = _client.auth.currentUser;
    final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;

    final normalizedReviewText = reviewText.trim();
    if (normalizedReviewText.isEmpty) {
      throw Exception('Please enter your review.');
    }

    if (rating < 1 || rating > 5) {
      throw Exception('Rating must be between 1 and 5.');
    }

    final metadata = supabaseUser?.userMetadata ?? const <String, dynamic>{};
    final firebaseDisplayName = firebaseUser?.displayName?.trim() ?? '';
    final firebaseEmail = firebaseUser?.email?.trim() ?? '';
    final supabaseEmail = supabaseUser?.email?.trim() ?? '';
    final primaryEmail = firebaseEmail.isNotEmpty ? firebaseEmail : supabaseEmail;
    final emailUsername = primaryEmail.contains('@')
        ? primaryEmail.split('@').first.trim()
        : '';
    final reviewerName =
        (firebaseDisplayName.isNotEmpty
                    ? firebaseDisplayName
                    : null) ??
                (metadata['username']?.toString().trim().isNotEmpty == true
                    ? metadata['username'].toString().trim()
                    : null) ??
                (metadata['user_name']?.toString().trim().isNotEmpty == true
                    ? metadata['user_name'].toString().trim()
                    : null) ??
                (metadata['preferred_username']?.toString().trim().isNotEmpty ==
                        true
                    ? metadata['preferred_username'].toString().trim()
                    : null) ??
                (metadata['display_name']?.toString().trim().isNotEmpty == true
                    ? metadata['display_name'].toString().trim()
                    : null) ??
                (metadata['full_name']?.toString().trim().isNotEmpty == true
                    ? metadata['full_name'].toString().trim()
                    : null) ??
                (metadata['name']?.toString().trim().isNotEmpty == true
                    ? metadata['name'].toString().trim()
                    : null) ??
                (emailUsername.isNotEmpty ? emailUsername : null) ??
                (primaryEmail.isNotEmpty ? primaryEmail : null) ??
                'Anonymous';

    await _client.from('place_reviews').insert({
      'place_id': placeId,
      'user_id': supabaseUser?.id,
      'rating': rating,
      'review_text': normalizedReviewText,
      'status': 'approved',
      'reviewer_name': reviewerName,
    });
  }
}
