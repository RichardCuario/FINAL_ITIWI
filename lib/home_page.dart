import 'dart:async';

import 'package:flutter/material.dart';

import 'barangay_page.dart';
import 'hotline.dart';
import 'news_page.dart';
import 'online_service_page.dart';
import 'profile_page.dart';
import 'report_page.dart';
import 'shared_widgets.dart';
import 'tourist_guide_page.dart';
import 'transparency_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    this.isDarkMode = false,
    this.onToggleDarkMode,
  });

  final bool isDarkMode;
  final ValueChanged<bool>? onToggleDarkMode;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final PageController _promoPageController = PageController();
  Timer? _promoTimer;
  int _currentPromoPage = 0;

  @override
  void initState() {
    super.initState();
    _startPromoAutoScroll();
  }

  @override
  void dispose() {
    _promoTimer?.cancel();
    _promoPageController.dispose();
    super.dispose();
  }

  void _startPromoAutoScroll() {
    _promoTimer?.cancel();
    _promoTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!_promoPageController.hasClients) return;

      final nextPage = (_currentPromoPage + 1) % 3;
      _promoPageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    });
  }

  void _openPage(Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  void _handleBottomNavigation(int index) {
    if (index == _selectedIndex) return;

    if (index == 1) {
      _openPage(const NewsPage());
      return;
    }

    if (index == 2) {
      _openPage(
        ProfilePage(
          isDarkMode: widget.isDarkMode,
          onToggleDarkMode: widget.onToggleDarkMode ?? (_) {},
          onNavigate: _handleBottomNavigation,
        ),
      );
      return;
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  void _showComingSoon(String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label is not available yet.')),
    );
  }

  void _handleDrawerNavigation(int index) {
    if (index == _selectedIndex) return;
    _handleBottomNavigation(index);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor =
        isDark ? const Color(0xFF08142A) : const Color(0xFFEAEAEA);
    final sectionTextColor = isDark ? Colors.white : Colors.black;
    final accentColor =
        isDark ? const Color(0xFF9FD0FF) : const Color(0xFF2196F3);
    final iconBackground =
        isDark ? const Color(0xFF1A2A47) : const Color(0xFFE5E5E5);
    final iconColor = accentColor;

    return Scaffold(
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: false,
      drawer: AdminSidebar(
        userName: 'Admin User',
        userEmail: 'admin@example.com',
        currentIndex: _selectedIndex,
        onNavigationChanged: _handleDrawerNavigation,
      ),
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenHeight = constraints.maxHeight;
            final screenWidth = constraints.maxWidth;
            final compact = screenHeight < 760 || screenWidth < 390;
            final extraCompact = screenHeight < 700 || screenWidth < 360;

            final horizontalPadding = extraCompact
                ? 14.0
                : compact
                    ? 16.0
                    : 20.0;
            final topPadding = extraCompact
                ? 14.0
                : compact
                    ? 16.0
                    : 20.0;
            final headerHeight = (screenHeight * 0.33).clamp(190.0, 255.0);
            final headerGap = extraCompact
                ? 28.0
                : compact
                    ? 38.0
                    : 56.0;
            final titleFontSize = extraCompact
                ? 20.0
                : compact
                    ? 23.0
                    : 27.0;
            final logoSize = extraCompact
                ? 68.0
                : compact
                    ? 78.0
                    : 96.0;
            final sectionTitleSize = extraCompact
                ? 18.0
                : compact
                    ? 20.0
                    : 23.0;
            final gridSpacing = extraCompact
                ? 8.0
                : compact
                    ? 10.0
                    : 12.0;
            final promoHeight = extraCompact
                ? 96.0
                : compact
                    ? 108.0
                    : 120.0;
            final indicatorSpacing = extraCompact ? 6.0 : 10.0;
            final shortcutIconSize = extraCompact
                ? 54.0
                : compact
                    ? 62.0
                    : 76.0;
            final shortcutLabelSize = extraCompact
                ? 11.0
                : compact
                    ? 12.0
                    : 13.0;
            final gridAspectRatio = extraCompact
                ? 1.0
                : compact
                    ? 0.96
                    : 0.92;

            return Column(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: headerHeight,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: Image.asset(
                                'assets/municipal_hall.jpg',
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.black.withValues(alpha: 0.40),
                                      const Color(0xFF0A3D73).withValues(
                                        alpha: 0.32,
                                      ),
                                      const Color(0xFF2196F3).withValues(
                                        alpha: 0.42,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.fromLTRB(
                                horizontalPadding,
                                topPadding,
                                horizontalPadding,
                                0,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Builder(
                                        builder: (buttonContext) =>
                                            _TopActionButton(
                                              icon: Icons.menu_rounded,
                                              compact: compact || extraCompact,
                                              onTap: () {
                                                Scaffold.of(
                                                  buttonContext,
                                                ).openDrawer();
                                              },
                                            ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: _SearchPill(
                                          hintText: 'Search Business Permit',
                                          compact: compact || extraCompact,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      _TopActionButton(
                                        icon: Icons.notifications_none_rounded,
                                        compact: compact || extraCompact,
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: headerGap),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Basta Tiwinhon\nOragon!',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: titleFontSize,
                                            fontWeight: FontWeight.w800,
                                            height: 1.08,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        width: logoSize,
                                        height: logoSize,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white.withValues(
                                              alpha: 0.1,
                                            ),
                                            width: 2.4,
                                          ),
                                          image: const DecorationImage(
                                            image: AssetImage('assets/logo.png'),
                                            fit: BoxFit.cover,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.18,
                                              ),
                                              blurRadius: 14,
                                              offset: const Offset(0, 6),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            horizontalPadding,
                            compact ? 14 : 18,
                            horizontalPadding,
                            0,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'What would you like to do?',
                                style: TextStyle(
                                  color: sectionTextColor,
                                  fontSize: sectionTitleSize,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: compact ? 10 : 14),
                              Expanded(
                                child: GridView.count(
                                  crossAxisCount: 3,
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  crossAxisSpacing: gridSpacing,
                                  mainAxisSpacing: gridSpacing,
                                  childAspectRatio: gridAspectRatio,
                                  children: [
                                    _HomeShortcut(
                                      icon: Icons.account_balance_rounded,
                                      label: 'Barangay',
                                      iconBackground: iconBackground,
                                      iconColor: iconColor,
                                      iconContainerSize: shortcutIconSize,
                                      labelFontSize: shortcutLabelSize,
                                      onTap: () => _openPage(const BarangayPage()),
                                    ),
                                    _HomeShortcut(
                                      icon: Icons.location_on_rounded,
                                      label: 'Tourist Guide',
                                      iconBackground: iconBackground,
                                      iconColor: iconColor,
                                      iconContainerSize: shortcutIconSize,
                                      labelFontSize: shortcutLabelSize,
                                      onTap: () =>
                                          _openPage(const TouristGuidePage()),
                                    ),
                                    _HomeShortcut(
                                      icon: Icons.warning_amber_rounded,
                                      label: 'Emergency',
                                      iconBackground: iconBackground,
                                      iconColor: iconColor,
                                      iconContainerSize: shortcutIconSize,
                                      labelFontSize: shortcutLabelSize,
                                      onTap: () => _openPage(const HotlinePage()),
                                    ),
                                    _HomeShortcut(
                                      icon: Icons.description_rounded,
                                      label: 'Transparency',
                                      iconBackground: iconBackground,
                                      iconColor: iconColor,
                                      iconContainerSize: shortcutIconSize,
                                      labelFontSize: shortcutLabelSize,
                                      onTap: () =>
                                          _openPage(const TransparencyPage()),
                                    ),
                                    _HomeShortcut(
                                      icon: Icons.report_problem_rounded,
                                      label: 'Report',
                                      iconBackground: iconBackground,
                                      iconColor: iconColor,
                                      iconContainerSize: shortcutIconSize,
                                      labelFontSize: shortcutLabelSize,
                                      onTap: () => _openPage(const ReportPage()),
                                    ),
                                    _HomeShortcut(
                                      icon: Icons.language_rounded,
                                      label: 'Online Service',
                                      iconBackground: iconBackground,
                                      iconColor: iconColor,
                                      iconContainerSize: shortcutIconSize,
                                      labelFontSize: shortcutLabelSize,
                                      onTap: () =>
                                          _openPage(const OnlineServicePage()),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: compact ? 8 : 10),
                              SizedBox(
                                height: promoHeight,
                                child: PageView(
                                  controller: _promoPageController,
                                  onPageChanged: (index) {
                                    setState(() {
                                      _currentPromoPage = index;
                                    });
                                  },
                                  children: [
                                    _DestinationPromoCard(
                                      title: "What's Your Next\nDestination?",
                                      description:
                                          "Whether it's a weekend trip or a month-long escape, make it unforgettable.",
                                      imagePath: 'assets/card.jpg',
                                      compact: compact || extraCompact,
                                      onTap: () =>
                                          _openPage(const TouristGuidePage()),
                                    ),
                                    _DestinationPromoCard(
                                      title: 'Discover Tiwi\nHighlights',
                                      description:
                                          'Find scenic spots, hot springs, and beautiful places waiting for your next visit.',
                                      imagePath: 'assets/municipal_hall.jpg',
                                      compact: compact || extraCompact,
                                      onTap: () =>
                                          _openPage(const TouristGuidePage()),
                                    ),
                                    _DestinationPromoCard(
                                      title: 'Plan Your\nAdventure',
                                      description:
                                          'Explore top attractions and local favorites with just a few taps.',
                                      imagePath: 'assets/bg.jpg',
                                      compact: compact || extraCompact,
                                      onTap: () =>
                                          _openPage(const TouristGuidePage()),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: indicatorSpacing),
                              Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: List.generate(
                                    3,
                                    (index) => AnimatedContainer(
                                      duration: const Duration(milliseconds: 250),
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                      ),
                                      width: _currentPromoPage == index ? 18 : 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: _currentPromoPage == index
                                            ? accentColor
                                            : accentColor.withValues(alpha: 0.25),
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: compact ? 10 : 12),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  color: isDark ? const Color(0xFF111827) : Colors.white,
                  child: BottomNavigationBar(
                    currentIndex: _selectedIndex,
                    onTap: _handleBottomNavigation,
                    backgroundColor:
                        isDark ? const Color(0xFF111827) : Colors.white,
                    selectedItemColor: colorScheme.primary,
                    unselectedItemColor: isDark
                        ? Colors.white70
                        : Colors.grey.shade600,
                    type: BottomNavigationBarType.fixed,
                    elevation: 0,
                    items: const [
                      BottomNavigationBarItem(
                        icon: Icon(Icons.home),
                        label: 'Home',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.info),
                        label: 'News',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.person),
                        label: 'Profile',
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TopActionButton extends StatelessWidget {
  const _TopActionButton({
    required this.icon,
    this.compact = false,
    this.onTap,
  });

  final IconData icon;
  final bool compact;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? const Color(0xFF162B4B) : Colors.white,
      elevation: isDark ? 0 : 0,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          width: compact ? 42 : 46,
          height: compact ? 42 : 46,
          child: Icon(
            icon,
            color: isDark ? const Color(0xFFB9DBFF) : const Color(0xFF4F6F8F),
            size: compact ? 22 : 24,
          ),
        ),
      ),
    );
  }
}

class _SearchPill extends StatelessWidget {
  const _SearchPill({
    required this.hintText,
    this.compact = false,
  });

  final String hintText;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: compact ? 42 : 46,
      padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF162B4B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Icon(
            Icons.search_rounded,
            color: isDark ? Colors.white70 : Colors.grey.shade500,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              hintText,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.grey.shade600,
                fontSize: compact ? 13 : 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeShortcut extends StatelessWidget {
  const _HomeShortcut({
    required this.icon,
    required this.label,
    required this.iconBackground,
    required this.iconColor,
    required this.onTap,
    this.iconContainerSize = 76,
    this.labelFontSize = 13,
  });

  final IconData icon;
  final String label;
  final Color iconBackground;
  final Color iconColor;
  final VoidCallback onTap;
  final double iconContainerSize;
  final double labelFontSize;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Column(
        children: [
          Container(
            width: iconContainerSize,
            height: iconContainerSize,
            decoration: BoxDecoration(
              color: iconBackground,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: iconContainerSize * 0.45,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black,
              fontSize: labelFontSize,
              fontWeight: FontWeight.w500,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _DestinationPromoCard extends StatelessWidget {
  const _DestinationPromoCard({
    required this.title,
    required this.description,
    required this.imagePath,
    required this.onTap,
    this.compact = false,
  });

  final String title;
  final String description;
  final String imagePath;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: compact ? 96 : 108,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        image: DecorationImage(
          image: AssetImage(imagePath),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        padding: EdgeInsets.fromLTRB(
          compact ? 12 : 14,
          compact ? 10 : 12,
          compact ? 12 : 14,
          compact ? 10 : 12,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.black.withValues(alpha: 0.18),
              Colors.black.withValues(alpha: 0.42),
            ],
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    width: compact ? 118 : 140,
                    child: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: compact ? 11.5 : 13,
                        fontWeight: FontWeight.w800,
                        height: 1.0,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: compact ? 132 : 160,
                    child: Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: compact ? 7.5 : 8.5,
                        height: 1.2,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: onTap,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF8EC5FF),
                foregroundColor: Colors.white,
                minimumSize: Size(compact ? 82 : 92, compact ? 28 : 32),
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 10 : 12,
                  vertical: 0,
                ),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Explore now!',
                style: TextStyle(
                  fontSize: compact ? 9 : 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
