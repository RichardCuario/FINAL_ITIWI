import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

class IdentityUploadService {
  final _supabase = Supabase.instance.client;
  static const String _bucketId = 'identity-uploads';

  firebase_auth.User? get _currentUser =>
      firebase_auth.FirebaseAuth.instance.currentUser;

  /// Upload ID front photo
  Future<String?> uploadIdFrontPhoto({
    required File imageFile,
    String? userId,
  }) async {
    try {
      final uid = userId ?? _currentUser?.uid;
      if (uid == null) throw Exception('User not authenticated');

      final fileName =
          '$uid/id_front_${DateTime.now().millisecondsSinceEpoch}.jpg';

      await _supabase.storage
          .from(_bucketId)
          .upload(fileName, imageFile, fileOptions: const FileOptions(
            cacheControl: '3600',
            upsert: false,
          ));

      // Get public URL
      final publicUrl =
          _supabase.storage.from(_bucketId).getPublicUrl(fileName);

      return publicUrl;
    } catch (e) {
      debugPrint('Error uploading ID front photo: $e');
      rethrow;
    }
  }

  /// Upload ID back photo
  Future<String?> uploadIdBackPhoto({
    required File imageFile,
    String? userId,
  }) async {
    try {
      final uid = userId ?? _currentUser?.uid;
      if (uid == null) throw Exception('User not authenticated');

      final fileName =
          '$uid/id_back_${DateTime.now().millisecondsSinceEpoch}.jpg';

      await _supabase.storage
          .from(_bucketId)
          .upload(fileName, imageFile, fileOptions: const FileOptions(
            cacheControl: '3600',
            upsert: false,
          ));

      // Get public URL
      final publicUrl =
          _supabase.storage.from(_bucketId).getPublicUrl(fileName);

      return publicUrl;
    } catch (e) {
      debugPrint('Error uploading ID back photo: $e');
      rethrow;
    }
  }

  /// Upload selfie photo
  Future<String?> uploadSelfiePhoto({
    required File imageFile,
    String? userId,
  }) async {
    try {
      final uid = userId ?? _currentUser?.uid;
      if (uid == null) throw Exception('User not authenticated');

      final fileName =
          '$uid/selfie_${DateTime.now().millisecondsSinceEpoch}.jpg';

      await _supabase.storage
          .from(_bucketId)
          .upload(fileName, imageFile, fileOptions: const FileOptions(
            cacheControl: '3600',
            upsert: false,
          ));

      // Get public URL
      final publicUrl =
          _supabase.storage.from(_bucketId).getPublicUrl(fileName);

      return publicUrl;
    } catch (e) {
      debugPrint('Error uploading selfie photo: $e');
      rethrow;
    }
  }

  /// Delete uploaded file
  Future<void> deleteFile({
    required String fileUrl,
    String? userId,
  }) async {
    try {
      final uid = userId ?? _currentUser?.uid;
      if (uid == null) throw Exception('User not authenticated');

      // Extract file path from URL
      final filePath = fileUrl.split('identity-uploads/').last;

      await _supabase.storage.from(_bucketId).remove([filePath]);
    } catch (e) {
      debugPrint('Error deleting file: $e');
      rethrow;
    }
  }

  /// Update verification with photo URLs
  Future<void> updateVerificationWithPhotos({
    required String verificationId,
    String? idFrontPhotoUrl,
    String? idBackPhotoUrl,
    String? selfiePhotoUrl,
    String? userId,
  }) async {
    try {
      final uid = userId ?? _currentUser?.uid;
      if (uid == null) throw Exception('User not authenticated');

      final updates = <String, dynamic>{};

      if (idFrontPhotoUrl != null) {
        updates['id_front_photo_url'] = idFrontPhotoUrl;
      }
      if (idBackPhotoUrl != null) {
        updates['id_back_photo_url'] = idBackPhotoUrl;
      }
      if (selfiePhotoUrl != null) {
        updates['selfie_photo_url'] = selfiePhotoUrl;
      }

      updates['updated_at'] = DateTime.now().toIso8601String();

      await Supabase.instance.client
          .from('identity_verification')
          .update(updates)
          .eq('id', verificationId)
          .eq('user_id', uid);
    } catch (e) {
      debugPrint('Error updating verification with photos: $e');
      rethrow;
    }
  }
}
