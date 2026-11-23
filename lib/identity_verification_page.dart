import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'didit_verification_webview.dart';
import 'identity_verification_theme.dart';
import 'online_service_page.dart';
import 'report_page.dart';

class IdentityVerificationPage extends StatefulWidget {
  final VoidCallback? onBack;
  const IdentityVerificationPage({super.key, this.onBack});
  @override
  State<IdentityVerificationPage> createState() => _IdentityVerificationPageState();
}

class _IdentityVerificationPageState extends State<IdentityVerificationPage> with WidgetsBindingObserver {
  static const _backendUrl = String.fromEnvironment('DIDIT_BACKEND_URL', defaultValue: 'https://itiwi-admin.vercel.app');
  final _supabase = Supabase.instance.client;
  Map<String, dynamic>? _verification;
  bool _isLoading = true;
  bool _isStarting = false;
  firebase_auth.User? get _currentUser => firebase_auth.FirebaseAuth.instance.currentUser;

  @override
  void initState() { super.initState(); WidgetsBinding.instance.addObserver(this); _loadStatus(); }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) { if (state == AppLifecycleState.resumed) _loadStatus(); }
  @override
  void dispose() { WidgetsBinding.instance.removeObserver(this); super.dispose(); }

  Future<void> _loadStatus() async {
    final user = _currentUser;
    if (user == null) return;
    try {
      final result = await _supabase.from('identity_verification').select('verification_status, rejection_reason, didit_status, updated_at').eq('user_id', user.uid).maybeSingle();
      if (mounted) setState(() { _verification = result; _isLoading = false; });
    } catch (error) {
      debugPrint('Didit status load failed: $error');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _startVerification() async {
    final user = _currentUser;
    if (user == null) { _showMessage('Please sign in before verifying your identity.'); return; }
    if (_backendUrl.trim().isEmpty) { _showMessage('Identity verification is not configured yet.'); return; }
    final accepted = await _showConsent();
    if (accepted != true || !mounted) return;
    setState(() => _isStarting = true);
    HttpClient? client;
    try {
      final token = await user.getIdToken();
      if (token == null || token.isEmpty) throw const _VerificationException('Please sign in again and retry.');
      client = HttpClient();
      final baseUrl = _backendUrl.replaceFirst(RegExp(r'/+$'), '');
      final request = await client.postUrl(Uri.parse('$baseUrl/api/identity-verification/session'));
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      request.headers.contentType = ContentType.json;
      request.write('{}');
      final response = await request.close();
      final body = await utf8.decoder.bind(response).join();
      final json = body.isEmpty ? <String, dynamic>{} : jsonDecode(body) as Map<String, dynamic>;
      if (response.statusCode < 200 || response.statusCode >= 300) throw _VerificationException(json['message']?.toString() ?? 'Could not start identity verification.');
      final url = json['url']?.toString();
      if (url == null || Uri.tryParse(url)?.host != 'verify.didit.me') {
        throw const _VerificationException('The verification link was unavailable.');
      }
      if (!mounted) return;
      final completed = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => DiditVerificationWebView(sessionUrl: url)),
      );
      if (mounted) {
        if (completed == true) {
          _showMessage('Verification submitted. Your status will update when a decision is available.', success: true);
        }
        await _loadStatus();
      }
    } on _VerificationException catch (error) {
      if (mounted) _showMessage(error.message);
    } on SocketException {
      if (mounted) _showMessage('No internet connection. Please try again.');
    } on FormatException {
      if (mounted) _showMessage('The verification service returned an invalid response.');
    } catch (error) {
      debugPrint('Didit verification start failed: $error');
      if (mounted) _showMessage('Could not start identity verification. Please try again.');
    } finally {
      client?.close(force: true);
      if (mounted) setState(() => _isStarting = false);
    }
  }

  Future<bool?> _showConsent() => showDialog<bool>(
    context: context,
    barrierColor: const Color(0xFF081B3A).withValues(alpha: .52),
    builder: (dialogContext) {
      final theme = Theme.of(dialogContext);
      final colors = theme.colorScheme;
      const vibrantBlue = Color(0xFF2563EB);
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 18),
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 360),
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.white.withValues(alpha: .75)),
            ),
            child: Stack(children: [
              Positioned(
                right: -68,
                bottom: -80,
                child: Container(width: 235, height: 155, decoration: BoxDecoration(color: vibrantBlue.withValues(alpha: .10), borderRadius: BorderRadius.circular(100))),
              ),
              Positioned(
                left: -60,
                bottom: -100,
                child: Container(width: 195, height: 130, decoration: BoxDecoration(color: vibrantBlue.withValues(alpha: .08), borderRadius: BorderRadius.circular(100))),
              ),
              Column(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 32, height: 4, decoration: BoxDecoration(color: vibrantBlue.withValues(alpha: .28), borderRadius: BorderRadius.circular(99))),
                const SizedBox(height: 15),
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(color: vibrantBlue.withValues(alpha: .12), shape: BoxShape.circle),
                  child: const Icon(Icons.shield_outlined, color: vibrantBlue, size: 27),
                ),
                const SizedBox(height: 12),
                Text('Before you continue', textAlign: TextAlign.center, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: const Color(0xFF102B5C))),
                const SizedBox(height: 10),
                Text(
                  'You will be asked for an identity document and a selfie. Your information will be processed securely to verify your identity.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF4B6592), height: 1.42),
                ),
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(child: TextButton(onPressed: () => Navigator.pop(dialogContext, false), style: TextButton.styleFrom(minimumSize: const Size.fromHeight(46), backgroundColor: vibrantBlue.withValues(alpha: .10), foregroundColor: vibrantBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), textStyle: const TextStyle(fontWeight: FontWeight.w700)), child: const Text('Cancel'))),
                  const SizedBox(width: 9),
                  Expanded(child: FilledButton(onPressed: () => Navigator.pop(dialogContext, true), style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(46), backgroundColor: vibrantBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), textStyle: const TextStyle(fontWeight: FontWeight.w700)), child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text('Continue'), SizedBox(width: 7), Icon(Icons.arrow_forward_rounded, size: 17)]))),
                ]),
              ]),
            ]),
          ),
        ),
      );
    },
  );

  void _showMessage(String message, {bool success = false}) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: success ? Colors.green.shade700 : null));
  String get _status => _verification?['verification_status']?.toString() ?? 'not_started';
  bool get _isVerified => _status == 'verified';
  String get _statusTitle => switch (_status) {
    'verified' => 'Identity verified', 'rejected' => 'Verification declined', 'pending_review' => 'Verification under review', 'in_progress' => 'Verification in progress', 'abandoned' => 'Verification not completed', 'expired' => 'Verification expired', _ => 'Not started',
  };
  String get _statusDescription => switch (_status) {
    'verified' => 'Your identity has been approved. You can access verification-based services.',
    'rejected' => _verification?['rejection_reason']?.toString() ?? 'Your identity verification was not approved.',
    'pending_review' => 'Your submission is under review. This page will update when a decision is available.',
    'in_progress' => 'Continue or complete your identity verification. Your status will update automatically.',
    'abandoned' => 'The verification was not completed. You can start a new one when ready.', 'expired' => 'This verification session expired. Please start a new one.',
    _ => 'Verify your identity securely to access protected iTIWI services.',
  };
  IconData get _statusIcon => switch (_status) {
    'verified' => Icons.verified_rounded, 'rejected' => Icons.cancel_rounded, 'pending_review' => Icons.hourglass_top_rounded, 'in_progress' => Icons.pending_rounded, _ => Icons.badge_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final identityBlue = identityVerificationBlue(theme.brightness);
    final statusColor = switch (_status) {
      'verified' => const Color(0xFF16A34A), 'rejected' => colors.error, 'pending_review' || 'in_progress' => const Color(0xFFF59E0B), _ => colors.primary,
    };
    final statusSurface = isDark
        ? Color.lerp(theme.cardColor, statusColor, .16)!
        : Color.lerp(colors.surface, statusColor, .09)!;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: colors.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: Text('Identity Verification', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: IconButton(
          style: IconButton.styleFrom(backgroundColor: colors.surfaceContainerHighest.withValues(alpha: .55)),
          icon: const Icon(Icons.arrow_back, size: 20),
          onPressed: widget.onBack ?? () => Navigator.maybePop(context),
          ),
        ),
      ),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : RefreshIndicator(
        onRefresh: _loadStatus,
        child: ListView(padding: const EdgeInsets.fromLTRB(10, 12, 10, 28), children: [
          Container(
            height: _isVerified ? 196 : 202,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color.lerp(statusSurface, identityBlue, .10)!, Color.lerp(statusSurface, identityBlue, .22)!],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Stack(children: [
              Positioned(
                right: -36, top: -52,
                child: Container(width: 190, height: 190, decoration: BoxDecoration(color: Colors.white.withValues(alpha: isDark ? .04 : .36), shape: BoxShape.circle)),
              ),
              Positioned(
                right: 8, top: 39,
                child: Transform.rotate(
                  angle: -.22,
                  child: Container(
                    width: 100, height: 66,
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: .78), borderRadius: BorderRadius.circular(10), boxShadow: [BoxShadow(color: colors.primary.withValues(alpha: .16), blurRadius: 15, offset: const Offset(0, 7))]),
                    child: Row(children: [
                      const SizedBox(width: 10),
                      CircleAvatar(radius: 14, backgroundColor: identityBlue.withValues(alpha: .18), child: Icon(Icons.person_rounded, color: identityBlue, size: 18)),
                      const SizedBox(width: 8),
                      Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [Container(height: 5, width: 38, color: identityBlue.withValues(alpha: .35)), const SizedBox(height: 7), Container(height: 4, width: 28, color: identityBlue.withValues(alpha: .20))])),
                    ]),
                  ),
                ),
              ),
              if (_isVerified) Positioned(right: 2, top: 84, child: CircleAvatar(radius: 18, backgroundColor: const Color(0xFF34B887), child: const Icon(Icons.check_rounded, color: Colors.white, size: 22))),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(width: 48, height: 48, decoration: BoxDecoration(color: _isVerified ? const Color(0xFF34B887) : identityBlue, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: identityBlue.withValues(alpha: .28), blurRadius: 14, offset: const Offset(0, 6))]), child: Icon(_statusIcon, color: Colors.white, size: 27)),
                const Spacer(),
                SizedBox(width: MediaQuery.sizeOf(context).width * .58, child: Text(_statusTitle, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: _isVerified ? const Color(0xFF159C69) : colors.onSurface))),
                const SizedBox(height: 5),
                SizedBox(width: MediaQuery.sizeOf(context).width * .58, child: Text(_statusDescription, maxLines: _isVerified ? 3 : 3, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant, height: 1.35))),
              ]),
              if (!_isVerified) Positioned(right: 0, top: 0, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5), decoration: BoxDecoration(color: identityBlue.withValues(alpha: .12), borderRadius: BorderRadius.circular(99)), child: Text('🔒  SECURE SETUP', style: theme.textTheme.labelSmall?.copyWith(color: identityBlue, fontWeight: FontWeight.w800, fontSize: 8, letterSpacing: .5)))),
            ]),
          ),
          if (_isVerified) ...[
            const SizedBox(height: 20),
            _VerifiedActions(
              onReport: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const ReportPage()),
              ),
              onOnlineServices: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const OnlineServicePage()),
              ),
            ),
          ],
          const SizedBox(height: 20),
          Row(children: [
            Text('How it works', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const Spacer(),
            Icon(Icons.auto_awesome_rounded, color: identityBlue, size: 20),
          ]),
          const SizedBox(height: 6),
          Text('A quick, secure identity verification process.', style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant)),
          const SizedBox(height: 12),
          _Step(number: '1', title: 'Start securely', text: 'Open a protected verification session.', icon: Icons.lock_open_rounded, color: identityBlue, isLast: false),
          _Step(number: '2', title: 'Verify your identity', text: 'Follow the ID and selfie instructions.', icon: Icons.badge_outlined, color: identityBlue, isLast: false),
          _Step(number: '3', title: 'Get your result', text: 'Your status updates automatically when ready.', icon: Icons.verified_outlined, color: identityBlue, isLast: true),
          const SizedBox(height: 18),
          if (!_isVerified) FilledButton.icon(
            onPressed: _isStarting ? null : _startVerification,
            icon: _isStarting ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.verified_user_rounded),
            label: Text(_isStarting ? 'Starting secure verification...' : 'Verify with iTIWI'),
            style: FilledButton.styleFrom(backgroundColor: identityBlue, minimumSize: const Size.fromHeight(58), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)), textStyle: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: colors.surfaceContainerHighest.withValues(alpha: isDark ? .42 : .55), borderRadius: BorderRadius.circular(20)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(width: 32, height: 32, decoration: BoxDecoration(color: identityBlue.withValues(alpha: .12), borderRadius: BorderRadius.circular(10)), child: Icon(Icons.lock_outline_rounded, size: 18, color: identityBlue)), const SizedBox(width: 12),
              Expanded(child: Text('Your identity document and selfie are captured during verification. iTIWI receives the verification result; you do not need to upload document photos here.', style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant, height: 1.45))),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _VerifiedActions extends StatelessWidget {
  final VoidCallback onReport;
  final VoidCallback onOnlineServices;

  const _VerifiedActions({
    required this.onReport,
    required this.onOnlineServices,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    const vibrantBlue = Color(0xFF2563EB);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: vibrantBlue.withValues(
          alpha: theme.brightness == Brightness.dark ? .34 : .55,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.rocket_launch_rounded, color: vibrantBlue, size: 20),
          const SizedBox(width: 9),
          Text(
            'You are ready to continue',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ]),
        const SizedBox(height: 5),
        Text(
          'Your verified account can now access reports and online services.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.onSurfaceVariant,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: onReport,
          icon: const Icon(Icons.report_outlined),
          label: const Text('Continue to Report'),
          style: FilledButton.styleFrom(
            backgroundColor: vibrantBlue,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: onOnlineServices,
          icon: const Icon(Icons.grid_view_rounded),
          label: const Text('Continue to Online Service'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ]),
    );
  }
}

class _Step extends StatelessWidget {
  final String number;
  final String title;
  final String text;
  final IconData icon;
  final Color color;
  final bool isLast;
  const _Step({required this.number, required this.title, required this.text, required this.icon, required this.color, required this.isLast});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Column(children: [
        Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withValues(alpha: .12), borderRadius: BorderRadius.circular(13)), child: Icon(icon, size: 21, color: color)),
        if (!isLast) Container(width: 2, height: 30, color: color.withValues(alpha: .22)),
      ]),
      const SizedBox(width: 14),
      Expanded(child: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('$number  $title', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 3),
          Text(text, style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.4, color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ]),
      )),
    ]),
  );
}

class _VerificationException implements Exception {
  final String message;
  const _VerificationException(this.message);
}
