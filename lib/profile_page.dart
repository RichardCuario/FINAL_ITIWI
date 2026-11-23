import 'user_profile_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'account_form_page.dart';
import 'about_us_page.dart';
import 'data_compliance_page.dart';
import 'faq_page.dart';
import 'privacy_policy_page.dart';
import 'premium_bottom_navigation.dart';
import 'terms_of_use_page.dart';

class ProfilePage extends StatefulWidget {
  final bool embedded;
  final bool isDarkMode;
  final ValueChanged<bool> onToggleDarkMode;
  final ValueChanged<int> onNavigate;

  const ProfilePage({
    super.key,
    this.embedded = false,
    required this.isDarkMode,
    required this.onToggleDarkMode,
    required this.onNavigate,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late bool _isDarkMode;
  String _phone = '';
  String _address = '';
  String? _profilePhotoUrl;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.isDarkMode;
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = _user;
      if (user == null) return;

      final response = await UserProfileService.read();

      if (response != null && mounted) {
        setState(() {
          _phone = response['phone'] as String? ?? '';
          _address = response['address'] as String? ?? '';
          _profilePhotoUrl = (response['photo_url'] as String?)?.trim();
        });
      }
    } catch (_) {
      // Silently fail — fields will remain as empty strings
    }
  }

  @override
  void didUpdateWidget(covariant ProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isDarkMode != widget.isDarkMode) {
      _isDarkMode = widget.isDarkMode;
    }
  }

  void _handleBottomNavigation(int index) {
    if (index == 2) return;
    if (widget.embedded) {
      widget.onNavigate(index);
      return;
    }

    if (index == 0) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }

    Navigator.of(context).pop();
    widget.onNavigate(index);
  }

  User? get _user => _auth.currentUser;

  String get _username {
    final displayName = _user?.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }

    final email = _user?.email ?? '';
    if (email.contains('@')) {
      return email.split('@').first;
    }

    return 'User';
  }

  String? get _photoUrl {
    final value =
        _user?.photoURL?.trim() ??
        _user?.providerData
            .map((provider) => provider.photoURL?.trim())
            .firstWhere(
              (photoUrl) => photoUrl != null && photoUrl.isNotEmpty,
              orElse: () => null,
            ) ??
        _profilePhotoUrl?.trim();
    if (value == null || value.isEmpty) return null;
    return value;
  }

  String get _initial {
    final username = _username.trim();
    if (username.isEmpty) return 'U';
    return username.characters.first.toUpperCase();
  }

  Future<void> _showEditProfileDialog() async {
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (_) => AccountFormPage(
        username: _username,
        phone: _phone,
        address: _address,
        onSave: (values) async {
          final user = _user;
          if (user == null) {
            throw 'Please sign in again to update your profile.';
          }
          try {
            if (values.username != user.displayName?.trim()) {
              await user.updateDisplayName(values.username);
            }
            await UserProfileService.save({
              'display_name': values.username,
              'phone': values.phone,
              'address': values.address,
            });
            await user.reload();
            if (mounted) {
              setState(() {
                _phone = values.phone;
                _address = values.address;
              });
            }
            return 'Profile updated.';
          } on FirebaseAuthException catch (error) {
            throw _accountError(error);
          } catch (_) {
            throw 'Some changes may have saved, but we couldn’t finish updating your profile. Please try again.';
          }
        },
      ),
    );
    if (!mounted || result == null) return;
    _showMessage(result);
  }

  Future<void> _showChangePasswordDialog() async {
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (_) => AccountFormPage(
        isPassword: true,
        onSave: (values) async {
          final user = _user;
          if (user == null) {
            throw 'Please sign in again to change your password.';
          }
          try {
            await user.updatePassword(values.password);
            return 'Password updated successfully.';
          } on FirebaseAuthException catch (error) {
            throw _accountError(error);
          }
        },
      ),
    );
    if (!mounted || result == null) return;
    _showMessage(result);
  }

  String _accountError(FirebaseAuthException error) {
    if (error.code == 'requires-recent-login') {
      return 'Please sign out and sign in again, then retry this change.';
    }
    return error.message ?? 'Could not save your changes. Please try again.';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colors = theme.colorScheme;

    return Scaffold(
      extendBody: true,
      backgroundColor: isDark
          ? const Color(0xFF101827)
          : const Color(0xFFF5F8FC),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
        ),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 320 + MediaQuery.paddingOf(context).top,
              child: CustomPaint(
                foregroundPainter: _ProfileWavesPainter(isDark: isDark),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: isDark
                          ? const [
                              Color(0xFF153454),
                              Color(0xFF11243A),
                              Color(0xFF101827),
                            ]
                          : const [
                              Color(0xFF087BFA),
                              Color(0xFF91D2FF),
                              Color(0xFFF5F8FC),
                            ],
                      stops: const [0, 0.42, 1],
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              bottom: false,
              child: Builder(
                builder: (context) => Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        20,
                        8,
                        20,
                        12 +
                            MediaQuery.paddingOf(context).bottom +
                            (widget.embedded ? 96 : 0),
                      ),
                      child: CustomScrollView(
                        physics: const NeverScrollableScrollPhysics(),
                        slivers: [
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildProfileHeader(context),
                                const SizedBox(height: 8),
                                Expanded(
                                  flex: 2,
                                  child: _buildSectionCard(
                                    context: context,
                                    title: 'Account & preferences',
                                    children: [
                                      _ProfileOptionTile(
                                        icon: Icons.lock_outline_rounded,
                                        title: 'Change password',
                                        onTap: _showChangePasswordDialog,
                                      ),
                                      _ProfileOptionTile(
                                        icon: Icons.dark_mode_outlined,
                                        title: 'Dark mode',
                                        trailing: Switch(
                                          value: _isDarkMode,
                                          activeThumbColor: colors.onPrimary,
                                          activeTrackColor: colors.primary,
                                          onChanged: (value) {
                                            setState(() => _isDarkMode = value);
                                            widget.onToggleDarkMode(value);
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Expanded(
                                  flex: 5,
                                  child: _buildSectionCard(
                                    context: context,
                                    title: 'Support & information',
                                    children: [
                                      _ProfileOptionTile(
                                        icon: Icons.info_outline_rounded,
                                        title: 'About us',
                                        onTap: () =>
                                            _openPage(const AboutUsPage()),
                                      ),
                                      _ProfileOptionTile(
                                        icon: Icons.help_outline_rounded,
                                        title: 'FAQs',
                                        onTap: () => _openPage(const FaqPage()),
                                      ),
                                      _ProfileOptionTile(
                                        icon: Icons.privacy_tip_outlined,
                                        title: 'Privacy policy',
                                        onTap: () => _openPage(
                                          const PrivacyPolicyPage(),
                                        ),
                                      ),
                                      _ProfileOptionTile(
                                        icon: Icons.description_outlined,
                                        title: 'Terms of use',
                                        onTap: () =>
                                            _openPage(const TermsOfUsePage()),
                                      ),
                                      _ProfileOptionTile(
                                        icon: Icons.shield_outlined,
                                        title: 'Data & compliance',
                                        onTap: () => _openPage(
                                          const DataCompliancePage(),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: widget.embedded
          ? null
          : PremiumBottomNavigation(
              currentIndex: 2,
              onTap: _handleBottomNavigation,
            ),
    );
  }

  void _openPage(Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  Widget _buildProfileHeader(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colors = theme.colorScheme;
    final photoUrl = _photoUrl;
    final avatarSize = MediaQuery.sizeOf(context).height < 700 ? 88.0 : 100.0;
    final initial = Center(
      child: Text(
        _initial,
        style: TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w600,
          color: colors.primary,
        ),
      ),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          Tooltip(
            message: 'Edit profile',
            child: Semantics(
              label: 'Edit profile',
              button: true,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _showEditProfileDialog,
                  customBorder: const CircleBorder(),
                  child: Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.24),
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF005CC7,
                              ).withValues(alpha: 0.18),
                              blurRadius: 22,
                              spreadRadius: 3,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Container(
                            width: avatarSize,
                            height: avatarSize,
                            color: isDark
                                ? const Color(0xFF293D58)
                                : const Color(0xFFDCEAF9),
                            child: photoUrl == null
                                ? initial
                                : Image.network(
                                    photoUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, error, stackTrace) =>
                                        initial,
                                  ),
                          ),
                        ),
                      ),
                      const Positioned(
                        right: 2,
                        bottom: 2,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.fromBorderSide(
                              BorderSide(color: Color(0xFF1976D2), width: 1.5),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x33000000),
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: SizedBox(
                            width: 32,
                            height: 32,
                            child: Icon(
                              Icons.edit_rounded,
                              color: Color(0xFF1976D2),
                              size: 19,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _username,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required BuildContext context,
    required String title,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 5),
          child: Text(
            title,
            style: theme.textTheme.labelLarge?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ),
        Expanded(
          child: Material(
            color: theme.brightness == Brightness.dark
                ? const Color(0xFF172033)
                : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: colors.outlineVariant.withValues(alpha: 0.35),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var index = 0; index < children.length; index++) ...[
                  if (index > 0)
                    Divider(
                      height: 1,
                      indent: 66,
                      endIndent: 18,
                      color: colors.outlineVariant.withValues(alpha: 0.35),
                    ),
                  Expanded(child: children[index]),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileWavesPainter extends CustomPainter {
  final bool isDark;

  const _ProfileWavesPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: isDark ? 0.04 : 0.18);
    final upperWave = Path()
      ..moveTo(width * 0.92, 0)
      ..cubicTo(
        width * 0.88,
        height * 0.42,
        width * 0.54,
        height * 0.5,
        width * 0.12,
        height * 0.4,
      )
      ..cubicTo(
        width * 0.2,
        height * 0.14,
        width * 0.04,
        height * 0.07,
        0,
        height * 0.15,
      )
      ..lineTo(0, height * 0.57)
      ..cubicTo(
        width * 0.45,
        height * 0.27,
        width * 0.65,
        height * 0.66,
        width,
        height * 0.25,
      )
      ..lineTo(width, 0)
      ..close();
    canvas.drawPath(upperWave, paint);
    paint.color = Colors.white.withValues(alpha: isDark ? 0.04 : 0.32);
    final lowerWave = Path()
      ..moveTo(0, height * 0.3)
      ..cubicTo(
        width * 0.26,
        height * 0.22,
        width * 0.57,
        height * 0.57,
        width,
        height * 0.38,
      )
      ..lineTo(width, height * 0.66)
      ..cubicTo(
        width * 0.55,
        height * 0.44,
        width * 0.28,
        height * 0.28,
        0,
        height * 0.62,
      )
      ..close();
    canvas.drawPath(lowerWave, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ProfileWavesPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}

class _ProfileOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _ProfileOptionTile({
    required this.icon,
    required this.title,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: colors.primary, size: 20),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: colors.onSurface,
                ),
              ),
            ),
            const SizedBox(width: 12),
            trailing ??
                Icon(
                  Icons.chevron_right_rounded,
                  color: colors.onSurfaceVariant.withValues(alpha: 0.65),
                  size: 20,
                ),
          ],
        ),
      ),
    );
  }
}
