import 'package:flutter/material.dart';

import 'barangay_page.dart';
import 'hotline.dart';
import 'news_page.dart';
import 'profile_page.dart';
import 'report_page.dart';
import 'shared_widgets.dart';
import 'tourist_guide_page.dart';

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
    const backgroundColor = Color(0xFF08142A);
    const accentColor = Color(0xFF9FD0FF);
    const iconBackground = Color(0xFF1A2A47);

    return Scaffold(
      backgroundColor: backgroundColor,
      drawer: AdminSidebar(
        userName: 'Admin User',
        userEmail: 'admin@example.com',
        currentIndex: _selectedIndex,
        onNavigationChanged: _handleDrawerNavigation,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        SizedBox(
                          height: 300,
                          width: double.infinity,
                          child: Image.asset(
                            'assets/municipal_hall.jpg',
                            fit: BoxFit.cover,
                          ),
                        ),
                        Container(
                          height: 300,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.40),
                                const Color(0xFF0A3D73).withValues(alpha: 0.32),
                                const Color(0xFF2196F3).withValues(alpha: 0.42),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Builder(
                                    builder: (buttonContext) => _TopActionButton(
                                      icon: Icons.menu_rounded,
                                      onTap: () {
                                        Scaffold.of(buttonContext).openDrawer();
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  const Expanded(
                                    child: _SearchPill(
                                      hintText: 'Search Business Permit',
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  const _TopActionButton(
                                    icon: Icons.notifications_none_rounded,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 88),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Expanded(
                                    child: Text(
                                      'Basta Tiwinon\nOragon!',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 33,
                                        fontWeight: FontWeight.w800,
                                        height: 1.08,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: 104,
                                    height: 104,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.75),
                                        width: 2.4,
                                      ),
                                      image: const DecorationImage(
                                        image: AssetImage('assets/logo.png'),
                                        fit: BoxFit.cover,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.18),
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
                    Transform.translate(
                      offset: const Offset(0, -2),
                      child: Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: backgroundColor,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(26),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'What would you like to do?',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 26),
                              GridView.count(
                                crossAxisCount: 3,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                crossAxisSpacing: 18,
                                mainAxisSpacing: 24,
                                childAspectRatio: 0.80,
                                children: [
                                  _HomeShortcut(
                                    icon: Icons.account_balance_rounded,
                                    label: 'Barangay',
                                    iconBackground: iconBackground,
                                    iconColor: accentColor,
                                    onTap: () => _openPage(const BarangayPage()),
                                  ),
                                  _HomeShortcut(
                                    icon: Icons.location_on_rounded,
                                    label: 'Tourist Guide',
                                    iconBackground: iconBackground,
                                    iconColor: accentColor,
                                    onTap: () => _openPage(const TouristGuidePage()),
                                  ),
                                  _HomeShortcut(
                                    icon: Icons.warning_amber_rounded,
                                    label: 'Emergency',
                                    iconBackground: iconBackground,
                                    iconColor: accentColor,
                                    onTap: () => _openPage(const HotlinePage()),
                                  ),
                                  _HomeShortcut(
                                    icon: Icons.description_rounded,
                                    label: 'Transparency',
                                    iconBackground: iconBackground,
                                    iconColor: accentColor,
                                    onTap: () => _showComingSoon('Transparency'),
                                  ),
                                  _HomeShortcut(
                                    icon: Icons.report_problem_rounded,
                                    label: 'Report',
                                    iconBackground: iconBackground,
                                    iconColor: accentColor,
                                    onTap: () => _openPage(const ReportPage()),
                                  ),
                                  _HomeShortcut(
                                    icon: Icons.language_rounded,
                                    label: 'Online Service',
                                    iconBackground: iconBackground,
                                    iconColor: accentColor,
                                    onTap: () => _showComingSoon('Online Service'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 28),
                              _DestinationPromoCard(
                                onTap: () => _openPage(const TouristGuidePage()),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            NavigationBar(
              height: 74,
              backgroundColor: const Color(0xFF071227),
              indicatorColor: Colors.white.withValues(alpha: 0.10),
              selectedIndex: _selectedIndex,
              onDestinationSelected: _handleBottomNavigation,
              labelTextStyle: WidgetStateProperty.resolveWith((states) {
                final selected = states.contains(WidgetState.selected);
                return TextStyle(
                  color: selected ? Colors.white : Colors.white70,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 13,
                );
              }),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined, color: Colors.white70),
                  selectedIcon: Icon(Icons.home_rounded, color: Colors.white),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.info_outline_rounded, color: Colors.white70),
                  selectedIcon: Icon(Icons.info_rounded, color: Colors.white),
                  label: 'News',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline_rounded, color: Colors.white70),
                  selectedIcon: Icon(Icons.person_rounded, color: Colors.white),
                  label: 'Profile',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TopActionButton extends StatelessWidget {
  const _TopActionButton({
    required this.icon,
    this.onTap,
  });

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF162B4B),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          width: 62,
          height: 62,
          child: Icon(
            icon,
            color: const Color(0xFFB9DBFF),
            size: 34,
          ),
        ),
      ),
    );
  }
}

class _SearchPill extends StatelessWidget {
  const _SearchPill({required this.hintText});

  final String hintText;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 62,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF162B4B),
        borderRadius: BorderRadius.circular(31),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.search_rounded,
            color: Colors.white70,
            size: 33,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              hintText,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 18,
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
  });

  final IconData icon;
  final String label;
  final Color iconBackground;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Column(
        children: [
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              color: iconBackground,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 42,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
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
  const _DestinationPromoCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 228,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        image: const DecorationImage(
          image: AssetImage('assets/card.jpg'),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(28),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(
              width: 220,
              child: Text(
                "What's Your Next\nDestination?",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  height: 1.05,
                ),
              ),
            ),
            const SizedBox(height: 14),
            const SizedBox(
              width: 280,
              child: Text(
                "Whether it's a weekend trip or a month-long escape, make it unforgettable.",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13.5,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Spacer(),
            FilledButton(
              onPressed: onTap,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF8EC5FF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
              ),
              child: const Text(
                'Explore now!',
                style: TextStyle(
                  fontSize: 16,
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
