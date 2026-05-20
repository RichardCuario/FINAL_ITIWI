import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'auth_page.dart';
import 'barangay_page.dart';
import 'faq_page.dart';
import 'hotline.dart';
import 'online_service_page.dart';
import 'report_page.dart';
import 'tourist_guide_page.dart';
import 'transparency_page.dart';

class AppColors {
  static const Color primary = Color(0xFF2196F3);
  static const Color background = Color(0xFFF5F5F5);
  static const Color cardBackground = Color(0xFFFAFAFA);
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFE53935);
}

class AdminAppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onBackPressed;
  final List<Widget>? actions;
  final Color? backgroundColor;
  final Color? textColor;

  const AdminAppHeader({
    super.key,
    required this.title,
    this.onBackPressed,
    this.actions,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: backgroundColor ?? AppColors.primary,
      elevation: 0,
      leading: onBackPressed != null
          ? IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: onBackPressed,
            )
          : null,
      title: Text(
        title,
        style: TextStyle(
          color: textColor ?? Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: false,
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class AdminSidebar extends StatelessWidget {
  final String userName;
  final String userEmail;
  final int currentIndex;
  final void Function(int) onNavigationChanged;

  const AdminSidebar({
    super.key,
    required this.userName,
    required this.userEmail,
    required this.currentIndex,
    required this.onNavigationChanged,
  });

  User? get _user => FirebaseAuth.instance.currentUser;

  String get _resolvedUserName {
    final displayName = _user?.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }

    final email = _user?.email?.trim() ?? userEmail.trim();
    if (email.isNotEmpty && email.contains('@')) {
      return email.split('@').first;
    }

    final fallback = userName.trim();
    if (fallback.isNotEmpty) {
      return fallback;
    }

    return 'User';
  }

  String get _resolvedUserEmail {
    final email = _user?.email?.trim();
    if (email != null && email.isNotEmpty) {
      return email;
    }

    final fallback = userEmail.trim();
    if (fallback.isNotEmpty) {
      return fallback;
    }

    return 'No email available';
  }

  String? get _resolvedPhotoUrl {
    final value = _user?.photoURL?.trim();
    if (value == null || value.isEmpty) return null;
    return value;
  }

  String get _initial {
    final value = _resolvedUserName.trim();
    if (value.isEmpty) return 'U';
    return value.characters.first.toUpperCase();
  }

  void _closeAndNavigate(BuildContext context, int index) {
    Navigator.pop(context);
    onNavigationChanged(index);
  }

  void _openPage(BuildContext context, Widget page) {
    Navigator.pop(context);
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final drawerBackground = isDark
        ? const Color(0xFF111827)
        : const Color(0xFFF7F7F8);

    return Drawer(
      width: 292,
      backgroundColor: drawerBackground,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A2234) : Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : const Color(0xFFE7E7EA),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.16 : 0.05),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: isDark
                          ? const Color(0xFFDBEAFE)
                          : const Color(0xFFE8EEF9),
                      backgroundImage: _resolvedPhotoUrl != null
                          ? NetworkImage(_resolvedPhotoUrl!)
                          : null,
                      child: _resolvedPhotoUrl == null
                          ? Text(
                              _initial,
                              style: TextStyle(
                                color: isDark
                                    ? const Color(0xFF0F172A)
                                    : const Color(0xFF2B2B2B),
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _resolvedUserName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF222222),
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _resolvedUserEmail,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white70
                                  : const Color(0xFF7A7A7A),
                              fontSize: 12,
                              height: 1.25,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _SidebarTile(
                      icon: Icons.home_outlined,
                      label: 'Home',
                      selected: currentIndex == 0,
                      onTap: () => _closeAndNavigate(context, 0),
                    ),
                    _SidebarTile(
                      icon: Icons.newspaper_outlined,
                      label: 'News',
                      selected: currentIndex == 1,
                      onTap: () => _closeAndNavigate(context, 1),
                    ),
                    _SidebarTile(
                      icon: Icons.location_city_outlined,
                      label: 'Barangay',
                      onTap: () => _openPage(context, const BarangayPage()),
                    ),
                    _SidebarTile(
                      icon: Icons.map_outlined,
                      label: 'Tourist Guide',
                      onTap: () => _openPage(context, const TouristGuidePage()),
                    ),
                    _SidebarTile(
                      icon: Icons.description_outlined,
                      label: 'Transparency',
                      onTap: () => _openPage(context, const TransparencyPage()),
                    ),
                    _SidebarTile(
                      icon: Icons.campaign_outlined,
                      label: 'Report Issue',
                      onTap: () => _openPage(context, const ReportPage()),
                    ),
                    _SidebarTile(
                      icon: Icons.language_outlined,
                      label: 'Online Services',
                      onTap: () => _openPage(
                        context,
                        const OnlineServicePage(),
                      ),
                    ),
                    _SidebarTile(
                      icon: Icons.phone_in_talk_outlined,
                      label: 'Emergency Hotline',
                      onTap: () => _openPage(context, const HotlinePage()),
                    ),
                    _SidebarTile(
                      icon: Icons.person_outline_rounded,
                      label: 'Profile',
                      selected: currentIndex == 2,
                      onTap: () => _closeAndNavigate(context, 2),
                    ),
                    _SidebarTile(
                      icon: Icons.help_outline_rounded,
                      label: 'Help & FAQ',
                      onTap: () => _openPage(context, const FaqPage()),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: Color(0xFFE5E7EB)),
              const SizedBox(height: 16),
              _SidebarFooterTile(
                userName: _resolvedUserName,
                userEmail: _resolvedUserEmail,
                photoUrl: _resolvedPhotoUrl,
                initial: _initial,
                onLogout: () async {
                  Navigator.pop(context);
                  await FirebaseAuth.instance.signOut();
                  if (!context.mounted) return;
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (_) => AuthPage(
                        initialMode: AuthMode.login,
                        isDarkMode:
                            Theme.of(context).brightness == Brightness.dark,
                        onToggleDarkMode: (_) {},
                      ),
                    ),
                    (route) => false,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SidebarTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: selected
            ? (isDark ? const Color(0xFF1F2937) : const Color(0xFFF0F0F1))
            : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        leading: Icon(
          icon,
          size: 21,
          color: selected
              ? (isDark ? Colors.white : const Color(0xFF1F1F1F))
              : (isDark ? Colors.white70 : const Color(0xFF666666)),
        ),
        title: Text(
          label,
          style: TextStyle(
            color: selected
                ? (isDark ? Colors.white : const Color(0xFF1F1F1F))
                : (isDark ? Colors.white : const Color(0xFF222222)),
            fontSize: 15,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        onTap: onTap,
      ),
    );
  }
}

class _SidebarFooterTile extends StatelessWidget {
  const _SidebarFooterTile({
    required this.userName,
    required this.userEmail,
    required this.photoUrl,
    required this.initial,
    required this.onLogout,
  });

  final String userName;
  final String userEmail;
  final String? photoUrl;
  final String initial;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161F31) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFE7E7EA),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: isDark
                ? const Color(0xFFDBEAFE)
                : const Color(0xFFE6EEF9),
            backgroundImage: photoUrl != null ? NetworkImage(photoUrl!) : null,
            child: photoUrl == null
                ? Text(
                    initial,
                    style: TextStyle(
                      color: isDark
                          ? const Color(0xFF0F172A)
                          : const Color(0xFF2B2B2B),
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF222222),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  userEmail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDark ? Colors.white60 : const Color(0xFF7A7A7A),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onLogout,
            icon: Icon(
              Icons.logout_rounded,
              color: isDark ? Colors.white : const Color(0xFF222222),
            ),
            tooltip: 'Logout',
          ),
        ],
      ),
    );
  }
}

class AppSectionCard extends StatelessWidget {
  const AppSectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.borderRadius = const BorderRadius.all(Radius.circular(18)),
    this.backgroundColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final BorderRadius borderRadius;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ??
            (isDark ? const Color(0xFF172033) : AppColors.cardBackground),
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.16 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE6EEF8),
        ),
      ),
      child: child,
    );
  }
}

class RatingStars extends StatelessWidget {
  const RatingStars({
    super.key,
    required this.rating,
    this.maxStars = 5,
    this.size = 18,
    this.activeColor = Colors.amber,
    this.inactiveColor = const Color(0xFFCFD8DC),
  });

  final double rating;
  final int maxStars;
  final double size;
  final Color activeColor;
  final Color inactiveColor;

  @override
  Widget build(BuildContext context) {
    final fullStars = rating.floor();
    final hasHalf = (rating - fullStars) >= 0.5;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxStars, (index) {
        if (index < fullStars) {
          return Icon(Icons.star_rounded, size: size, color: activeColor);
        }
        if (index == fullStars && hasHalf) {
          return Icon(Icons.star_half_rounded, size: size, color: activeColor);
        }
        return Icon(Icons.star_rounded, size: size, color: inactiveColor);
      }),
    );
  }
}
