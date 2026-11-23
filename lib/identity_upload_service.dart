import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'upload_image_service.dart';

class IdentityUploadService {
  final _supabase = Supabase.instance.client;
  static const String _bucketId = 'identity-uploads';

  firebase_auth.User? get _currentUser =>
      firebase_auth.FirebaseAuth.instance.currentUser;

  Future<String> _uploadPhoto(File file, String uid, String label) async {
    UploadImageService.validateInputSize(await file.length());
    final image = await UploadImageService.prepare(
      await file.readAsBytes(),
      identityDocument: true,
    );
    final path =
        '$uid/${label}_${DateTime.now().millisecondsSinceEpoch}.${image.extension}';
    await _supabase.storage
        .from(_bucketId)
        .uploadBinary(
          path,
          image.bytes,
          fileOptions: FileOptions(
            cacheControl: '3600',
            contentType: image.contentType,
            upsert: false,
          ),
        );
    return _supabase.storage.from(_bucketId).getPublicUrl(path);
  }

  /// Upload ID front photo
  Future<String?> uploadIdFrontPhoto({
    required File imageFile,
    String? userId,
  }) async {
    try {
      final uid = userId ?? _currentUser?.uid;
      if (uid == null) throw Exception('User not authenticated');

      return await _uploadPhoto(imageFile, uid, 'id_front');
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

      return await _uploadPhoto(imageFile, uid, 'id_back');
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

      return await _uploadPhoto(imageFile, uid, 'selfie');
    } catch (e) {
      debugPrint('Error uploading selfie photo: $e');
      rethrow;
    }
  }

  /// Delete uploaded file
  Future<void> deleteFile({required String fileUrl, String? userId}) async {
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
