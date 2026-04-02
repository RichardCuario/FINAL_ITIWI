import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'auth_page.dart';
import 'barangay_page.dart';
import 'hotline.dart';

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final drawerBackground = isDark
        ? const Color(0xFF111827)
        : const Color(0xFFF3F7FD);

    return Drawer(
      width: 270,
      backgroundColor: drawerBackground,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? const [Color(0xFF102A43), Color(0xFF1E3A5F)]
                      : const [Color(0xFF0D47A1), AppColors.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: isDark
                        ? const Color(0xFFDBEAFE)
                        : Colors.white,
                    backgroundImage: _resolvedPhotoUrl != null
                        ? NetworkImage(_resolvedPhotoUrl!)
                        : null,
                    child: _resolvedPhotoUrl == null
                        ? Text(
                            _initial,
                            style: TextStyle(
                              color: isDark
                                  ? const Color(0xFF0F172A)
                                  : AppColors.primary,
                              fontSize: 24,
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
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _resolvedUserEmail,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _SidebarTile(
                    icon: Icons.home_rounded,
                    label: 'Home',
                    selected: currentIndex == 0,
                    onTap: () => _closeAndNavigate(context, 0),
                  ),
                  _SidebarTile(
                    icon: Icons.newspaper_rounded,
                    label: 'News',
                    selected: currentIndex == 1,
                    onTap: () => _closeAndNavigate(context, 1),
                  ),
                  _SidebarTile(
                    icon: Icons.location_city_rounded,
                    label: 'Barangay',
                    selected: false,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BarangayPage(
                            onBack: () {
                              Navigator.of(context).pop();
                            },
                          ),
                        ),
                      );
                    },
                  ),
                  _SidebarTile(
                    icon: Icons.person_rounded,
                    label: 'Profile',
                    selected: currentIndex == 2,
                    onTap: () => _closeAndNavigate(context, 2),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 14, 8, 10),
                    child: Divider(
                      height: 1,
                      color: isDark ? Colors.white12 : Colors.black12,
                    ),
                  ),
                  _SidebarTile(
                    icon: Icons.phone_rounded,
                    label: 'Emergency Hotline',
                    iconColor: AppColors.success,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const HotlinePage()),
                      );
                    },
                  ),
                  _SidebarTile(
                    icon: Icons.logout_rounded,
                    label: 'Logout',
                    iconColor: AppColors.error,
                    onTap: () async {
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
          ],
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
  final Color? iconColor;

  const _SidebarTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeColor = iconColor ?? AppColors.primary;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        gradient: selected
            ? LinearGradient(
                colors: isDark
                    ? const [Color(0xFF0D47A1), Color(0xFF42A5F5)]
                    : const [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: selected
            ? null
            : (isDark ? const Color(0xFF172033) : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected
              ? activeColor.withValues(alpha: isDark ? 0.30 : 0.18)
              : (isDark ? Colors.white10 : const Color(0xFFE6EEF8)),
        ),
        boxShadow: [
          BoxShadow(
            color: selected
                ? AppColors.primary.withValues(alpha: isDark ? 0.20 : 0.12)
                : Colors.black.withValues(alpha: isDark ? 0.08 : 0.04),
            blurRadius: selected ? 14 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: selected
              ? (isDark ? Colors.white : AppColors.primary)
              : (iconColor ?? (isDark ? Colors.white70 : Colors.black54)),
        ),
        title: Text(
          label,
          style: TextStyle(
            color: selected
                ? (isDark ? Colors.white : AppColors.primary)
                : (isDark ? Colors.white : Colors.black87),
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        onTap: onTap,
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
