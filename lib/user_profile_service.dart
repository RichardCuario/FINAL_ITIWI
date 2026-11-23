import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';

/// Citizen profile access goes through the API, which verifies Firebase identity.
class UserProfileService {
  static const _backendUrl = String.fromEnvironment(
    'PROFILE_BACKEND_URL',
    defaultValue: 'https://itiwi-admin.vercel.app',
  );

  static Future<Map<String, dynamic>?> read() => _request('GET');

  static Future<void> save(Map<String, dynamic> fields) async {
    await _request('PATCH', fields);
  }

  static Future<Map<String, dynamic>?> _request(
    String method, [
    Map<String, dynamic>? fields,
  ]) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('Please sign in again.');
    final token = await user.getIdToken();
    if (token == null) throw StateError('Please sign in again.');
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 15);
    try {
      final request = await client
          .openUrl(method, Uri.parse('$_backendUrl/api/profile'))
          .timeout(const Duration(seconds: 20));
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      if (fields != null) {
        request.headers.contentType = ContentType.json;
        request.write(jsonEncode(fields));
      }
      final response = await request.close().timeout(
        const Duration(seconds: 20),
      );
      final body = await response
          .transform(utf8.decoder)
          .join()
          .timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) {
        throw StateError('Profile request failed. Please try again.');
      }
      final result = jsonDecode(body) as Map<String, dynamic>;
      return result['profile'] == null
          ? null
          : Map<String, dynamic>.from(result['profile'] as Map);
    } finally {
      client.close(force: true);
    }
  }
}
