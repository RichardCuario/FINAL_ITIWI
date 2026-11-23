import 'package:firebase_auth/firebase_auth.dart';

/// Email/password accounts must verify their address before entering the app.
/// Social providers have their own identity checks.
bool requiresEmailVerification(User user) {
  if (user.emailVerified) return false;
  final providers = user.providerData.map((provider) => provider.providerId).toList();
  return providers.isEmpty || providers.contains('password');
}
