import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

class UserAccessService {
  const UserAccessService._();

  static Future<bool> isActive(User user) async {
    try {
      final result = await Supabase.instance.client.rpc(
        'is_user_active',
        params: {'p_user_id': user.uid},
      ).timeout(const Duration(seconds: 5));

      return result != false;
    } catch (_) {
      // Keep authentication available if the status check is temporarily unavailable.
      return true;
    }
  }
}
