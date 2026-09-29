import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VerificationService {
  final _supabase = Supabase.instance.client;

  // Get current user
  firebase_auth.User? get _currentUser =>
      firebase_auth.FirebaseAuth.instance.currentUser;

  /// Check if user is verified
  Future<bool> isUserVerified({String? userId}) async {
    try {
      final uid = userId ?? _currentUser?.uid;
      if (uid == null) return false;

      final response = await _supabase
          .from('identity_verification')
          .select('verification_status')
          .eq('user_id', uid)
          .eq('verification_status', 'verified')
          .maybeSingle();

      return response != null;
    } catch (e) {
      debugPrint('Error checking verification status: $e');
      return false;
    }
  }

  /// Get user's verification data
  Future<Map<String, dynamic>?> getVerificationData(
      {String? userId}) async {
    try {
      final uid = userId ?? _currentUser?.uid;
      if (uid == null) return null;

      return await _supabase
          .from('identity_verification')
          .select()
          .eq('user_id', uid)
          .maybeSingle();
    } catch (e) {
      debugPrint('Error fetching verification data: $e');
      return null;
    }
  }

  /// Get verification status
  Future<String?> getVerificationStatus({String? userId}) async {
    try {
      final uid = userId ?? _currentUser?.uid;
      if (uid == null) return null;

      final response = await _supabase
          .from('identity_verification')
          .select('verification_status')
          .eq('user_id', uid)
          .maybeSingle();

      return response?['verification_status'] as String?;
    } catch (e) {
      debugPrint('Error fetching verification status: $e');
      return null;
    }
  }

  /// Check if user has submitted verification (any status)
  Future<bool> hasSubmittedVerification({String? userId}) async {
    try {
      final uid = userId ?? _currentUser?.uid;
      if (uid == null) return false;

      final response = await _supabase
          .from('identity_verification')
          .select('id')
          .eq('user_id', uid)
          .maybeSingle();

      return response != null;
    } catch (e) {
      debugPrint('Error checking if verification submitted: $e');
      return false;
    }
  }

  /// Get rejection reason if any
  Future<String?> getRejectionReason({String? userId}) async {
    try {
      final uid = userId ?? _currentUser?.uid;
      if (uid == null) return null;

      final response = await _supabase
          .from('identity_verification')
          .select('rejection_reason')
          .eq('user_id', uid)
          .eq('verification_status', 'rejected')
          .maybeSingle();

      return response?['rejection_reason'] as String?;
    } catch (e) {
      debugPrint('Error fetching rejection reason: $e');
      return null;
    }
  }
}
