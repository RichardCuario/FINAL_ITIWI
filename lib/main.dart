import 'user_profile_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'dart:async';
import 'app_session_gate.dart';
import 'app_update_prompt.dart';
import 'auth_page.dart';
import 'email_verification_access.dart';
import 'home_page.dart';
import 'news_feed_page.dart';
import 'news_notification_service.dart';
import 'onboarding_page.dart';
import 'onboarding_progress.dart';
import 'user_access_service.dart';

const _defaultSupabaseUrl = 'https://jbhlbukxankrtcwhqoll.supabase.co';
const _defaultSupabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpiaGxidWt4YW5rcnRjd2hxb2xsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ0NzAxODgsImV4cCI6MjA5MDA0NjE4OH0.DebtVdw7bF5nRaXQg8Ta2SsO2Qv42QnGSzoS8hT2vJc';

const _supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: _defaultSupabaseUrl,
);
const _supabaseAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue: _defaultSupabaseAnonKey,
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await Supabase.initialize(
      url: _supabaseUrl,
      anonKey: _supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        autoRefreshToken: false,
        detectSessionInUri: false,
      ),
    );

    final initialUser = FirebaseAuth.instance.currentUser;
    unawaited(
      NewsNotificationService.instance
          .initialize(
            externalUserId:
                initialUser != null && !requiresEmailVerification(initialUser)
                ? initialUser.uid
                : null,
          )
          .catchError((error, stackTrace) {
            debugPrint('Notification service startup skipped: $error');
          }),
    );

    bool hasSeenOnboarding = false;
    try {
      hasSeenOnboarding = await OnboardingProgress.hasSeenOnboarding();
    } catch (error) {
      debugPrint('Could not read onboarding progress: $error');
    }
    runApp(MyApp(hasSeenOnboarding: hasSeenOnboarding));
  } catch (error, stackTrace) {
    debugPrint('App startup failed: $error');
    debugPrintStack(stackTrace: stackTrace);
    runApp(StartupErrorApp(error: error.toString()));
  }
}

class StartupErrorApp extends StatelessWidget {
  final String error;

  const StartupErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hotline App',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFFF3F6FB),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.redAccent,
                ),
                const SizedBox(height: 16),
                const Text(
                  'App failed to start',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  error,
                  style: const TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                const Text(
                  'The app uses the project default Supabase configuration unless you override it with --dart-define values for SUPABASE_URL and SUPABASE_ANON_KEY.',
                  style: TextStyle(color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key, this.hasSeenOnboarding = false});

  final bool hasSeenOnboarding;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  bool _isDarkMode = false;
  late final Stream<User?> _authStateStream;
  User? _currentUser;
  Future<bool>? _accessCheck;
  bool _hasSignedIn = false;

  @override
  void initState() {
    super.initState();
    _currentUser = Firebase.apps.isEmpty
        ? null
        : FirebaseAuth.instance.currentUser;
    _hasSignedIn = widget.hasSeenOnboarding || _currentUser != null;
    _authStateStream = _buildAuthStateStream();
  }

  Stream<User?> _buildAuthStateStream() {
    if (Firebase.apps.isEmpty) {
      return const Stream<User?>.empty();
    }

    // Keep one listener so the initial restored-user event cannot be consumed
    // by a separate subscription before the session gate starts listening.
    return FirebaseAuth.instance.userChanges().map((user) {
      _currentUser = user;
      if (user != null) {
        _hasSignedIn = true;
        unawaited(
          OnboardingProgress.markSeen().catchError((Object error) {
            debugPrint('Could not save onboarding progress: $error');
          }),
        );
      }
      final allowedUser = user != null && !requiresEmailVerification(user)
          ? user
          : null;
      _accessCheck = allowedUser == null
          ? null
          : UserAccessService.isActive(allowedUser);
      NewsNotificationService.instance.syncUser(allowedUser?.uid);
      if (allowedUser != null) {
        _syncUserToDatabase(allowedUser);
      }
      return user;
    });
  }

  Future<void> _syncUserToDatabase(User user) async {
    try {
      // Use email as display name if no displayName is set
      final displayName =
          (user.displayName != null && user.displayName!.isNotEmpty)
          ? user.displayName
          : (user.email ?? 'User');

      await UserProfileService.save({
        'display_name': displayName,
        'photo_url': user.photoURL,
      });

      debugPrint('✅ User synced: $displayName');
    } catch (e) {
      debugPrint('Error syncing user to database: $e');
    }
  }

  ThemeData _buildLightTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF1E88E5),
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFFF3F6FB),
      cardColor: Colors.white,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      drawerTheme: const DrawerThemeData(backgroundColor: Colors.white),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: Colors.grey.shade600,
        type: BottomNavigationBarType.fixed,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        hintStyle: TextStyle(color: Colors.grey.shade500),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.3),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return colorScheme.primary;
          return Colors.grey.shade100;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary.withValues(alpha: 0.45);
          }
          return Colors.grey.shade400;
        }),
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF64B5F6),
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFF0F172A),
      cardColor: const Color(0xFF172033),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF111B2E),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      drawerTheme: const DrawerThemeData(backgroundColor: Color(0xFF111827)),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: const Color(0xFF111827),
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: Colors.white70,
        type: BottomNavigationBarType.fixed,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1B2436),
        hintStyle: const TextStyle(color: Colors.white60),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF334155)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF334155)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.3),
        ),
      ),
      dialogTheme: const DialogThemeData(backgroundColor: Color(0xFF172033)),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return colorScheme.primary;
          return const Color(0xFFE5E7EB);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary.withValues(alpha: 0.4);
          }
          return const Color(0xFF475569);
        }),
      ),
    );
  }

  void _toggleDarkMode(bool value) {
    setState(() {
      _isDarkMode = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hotline App',
      debugShowCheckedModeBanner: false,
      theme: _buildLightTheme(),
      navigatorKey: _navigatorKey,
      builder: (context, child) => AppUpdatePrompt(
        navigatorKey: _navigatorKey,
        child: child ?? const SizedBox.shrink(),
      ),
      darkTheme: _buildDarkTheme(),
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      routes: {
        '/onboarding': (context) => OnboardingPage(
          isDarkMode: _isDarkMode,
          onToggleDarkMode: _toggleDarkMode,
        ),
        '/auth': (context) => AuthPage(
          isDarkMode: _isDarkMode,
          onToggleDarkMode: _toggleDarkMode,
        ),
        '/news': (context) => NewsFeedPage(),
      },
      home: AppSessionGate<User>(
        sessions: _authStateStream,
        initialUser: _currentUser,
        readCurrentUser: Firebase.apps.isEmpty
            ? null
            : () => FirebaseAuth.instance.currentUser,
        signedInBuilder: (context, user) {
          if (requiresEmailVerification(user)) {
            return _EmailVerificationRequiredPage(user: user);
          }
          return FutureBuilder<bool>(
            future: _accessCheck ??= UserAccessService.isActive(user),
            builder: (context, accessSnapshot) {
              if (accessSnapshot.connectionState != ConnectionState.done) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (accessSnapshot.data == false) {
                return const _BlockedAccountPage();
              }

              return HomePage(
                isDarkMode: _isDarkMode,
                onToggleDarkMode: _toggleDarkMode,
              );
            },
          );
        },
        signedOutBuilder: (context) => _hasSignedIn
            ? AuthPage(
                isDarkMode: _isDarkMode,
                onToggleDarkMode: _toggleDarkMode,
              )
            : OnboardingPage(
                isDarkMode: _isDarkMode,
                onToggleDarkMode: _toggleDarkMode,
              ),
      ),
    );
  }
}

class _EmailVerificationRequiredPage extends StatefulWidget {
  const _EmailVerificationRequiredPage({required this.user});

  final User user;

  @override
  State<_EmailVerificationRequiredPage> createState() =>
      _EmailVerificationRequiredPageState();
}

class _EmailVerificationRequiredPageState
    extends State<_EmailVerificationRequiredPage> {
  bool _busy = false;

  void _message(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _checkVerification() async {
    setState(() => _busy = true);
    try {
      await widget.user.reload();
      if (!mounted) return;
      if (FirebaseAuth.instance.currentUser?.emailVerified != true) {
        _message(
          'Your email is not verified yet. Open the link in your inbox, then try again.',
        );
      }
    } catch (_) {
      if (mounted) _message('Could not check verification. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resendVerification() async {
    setState(() => _busy = true);
    try {
      await widget.user.sendEmailVerification();
      if (mounted) _message('Verification email sent. Check your inbox.');
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        _message(error.message ?? 'Could not send verification email.');
      }
    } catch (_) {
      if (mounted) {
        _message('Could not send verification email. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final email = widget.user.email?.trim();

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0D1624)
          : const Color(0xFFF2F6FC),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 28,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(26, 32, 26, 22),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: colors.outlineVariant.withValues(alpha: 0.55),
                        ),
                        boxShadow: isDark
                            ? null
                            : [
                                BoxShadow(
                                  color: const Color(
                                    0xFF274D7D,
                                  ).withValues(alpha: 0.09),
                                  blurRadius: 30,
                                  offset: const Offset(0, 14),
                                ),
                              ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              color: colors.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.mark_email_unread_rounded,
                              size: 42,
                              color: colors.primary,
                            ),
                          ),
                          const SizedBox(height: 22),
                          Text(
                            'CHECK YOUR INBOX',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colors.primary,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Verify your email',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: colors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'We sent a verification link to',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: colors.primary.withValues(alpha: 0.07),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              email == null || email.isEmpty
                                  ? 'your email address'
                                  : email,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: colors.onSurface,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'Open the link in your email, then come back and confirm below.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colors.onSurfaceVariant,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 28),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: _busy ? null : _checkVerification,
                              style: FilledButton.styleFrom(
                                minimumSize: const Size.fromHeight(52),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                              ),
                              icon: _busy
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.check_circle_outline),
                              label: const Text('I have verified my email'),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _busy ? null : _resendVerification,
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(48),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Resend verification email'),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Divider(color: colors.outlineVariant),
                          const SizedBox(height: 4),
                          TextButton(
                            onPressed: _busy
                                ? null
                                : () => FirebaseAuth.instance.signOut(),
                            child: const Text('Sign out'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BlockedAccountPage extends StatelessWidget {
  const _BlockedAccountPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.block_rounded,
                size: 72,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 20),
              const Text(
                'Account blocked',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              const Text(
                'Your account has been blocked by an administrator. Please contact support for assistance.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => FirebaseAuth.instance.signOut(),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Sign out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
