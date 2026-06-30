import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'barangay_page.dart';
import 'content_cache_service.dart';
import 'faq_page.dart';
import 'hotline.dart';
import 'news_page.dart';
import 'notification_page.dart';
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
  final TextEditingController _searchController = TextEditingController();
  final ContentCacheService _cacheService = const ContentCacheService();
  Timer? _promoTimer;
  int _currentPromoPage = 0;
  List<Map<String, dynamic>> _barangays = [];
  bool _hasUnreadNotifications = false;

  @override
  void initState() {
    super.initState();
    _startPromoAutoScroll();
    _loadBarangays();
    _loadUnreadNotifications();
  }

  @override
  void dispose() {
    _promoTimer?.cancel();
    _promoPageController.dispose();
    _searchController.dispose();
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

  Future<void> _loadBarangays() async {
    try {
      final data = await Supabase.instance.client
          .from('barangays')
          .select()
          .order('name', ascending: true);

      final mapped = List<Map<String, dynamic>>.from(
        (data as List).map((item) => Map<String, dynamic>.from(item as Map)),
      );

      await _cacheService.saveBarangays(mapped);

      if (!mounted) return;
      setState(() {
        _barangays = mapped;
      });
    } catch (_) {
      final cached = await _cacheService.getBarangays();
      if (!mounted) return;
      setState(() {
        _barangays = cached.items;
      });
    }
  }

  Future<void> _loadUnreadNotifications() async {
    final cachedNews = await _cacheService.getNews();
    final latestNews = cachedNews.items.isNotEmpty ? cachedNews.items.first : null;
    final latestNewsMarker = latestNews == null
        ? null
        : '${latestNews['id']?.toString() ?? ''}|${latestNews['created_at']?.toString() ?? ''}|${latestNews['updated_at']?.toString() ?? ''}';
    final seenNewsMarker = await _cacheService.getSeenNewsMarker();
    final dismissedNewsIds = await _cacheService.getDismissedNewsIds();
    final reportNotifications = await _cacheService.getReportNotifications();

    final hasUnreadNews =
        latestNewsMarker != null &&
        latestNewsMarker != seenNewsMarker &&
        !dismissedNewsIds.contains(
          latestNewsMarker.split('|').first,
        );

    final hasUnreadReports = reportNotifications.isNotEmpty;

    if (!mounted) return;

    setState(() {
      _hasUnreadNotifications = hasUnreadNews || hasUnreadReports;
    });
  }

  void _openPage(Widget page) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => page)).then((_) {
      _loadUnreadNotifications();
    });
  }

  void _openOnlineServicePage({
    OnlineServiceTarget initialTarget = OnlineServiceTarget.none,
  }) {
    if (initialTarget == OnlineServiceTarget.none) {
      _openPage(const OnlineServicePage());
      return;
    }

    OnlineServicePage.openTarget(context, initialTarget);
  }

  void _openSpecificBarangay(Map<String, dynamic> barangay) {
    _openPage(BarangayDetailPage(barangay: barangay));
  }

  List<_SearchDestination> get _baseSearchDestinations => [
        _SearchDestination(
          title: 'Barangay',
          subtitle: 'Find barangay information and local updates',
          keywords: const ['barangay', 'local', 'community', 'village'],
          icon: Icons.account_balance_rounded,
          onTap: () => _openPage(const BarangayPage()),
        ),
        _SearchDestination(
          title: 'Tourist Guide',
          subtitle: 'Explore attractions, destinations, and local spots',
          keywords: const ['tourist', 'travel', 'destination', 'spots'],
          icon: Icons.location_on_rounded,
          onTap: () => _openPage(const TouristGuidePage()),
        ),
        _SearchDestination(
          title: 'Emergency Hotline',
          subtitle: 'View police, fire, rescue, and emergency numbers',
          keywords: const ['emergency', 'hotline', 'call', 'rescue', 'police'],
          icon: Icons.warning_amber_rounded,
          onTap: () => _openPage(const HotlinePage()),
        ),
        _SearchDestination(
          title: 'Transparency',
          subtitle: 'Access public documents and transparency records',
          keywords: const [
            'transparency',
            'documents',
            'records',
            'budget',
            'ordinance',
            'bids',
            'financial reports',
            'executive order',
            'programs',
          ],
          icon: Icons.description_rounded,
          onTap: () => _openPage(const TransparencyPage()),
        ),
        _SearchDestination(
          title: 'Report',
          subtitle: 'Submit a concern or incident report',
          keywords: const ['report', 'concern', 'complaint', 'issue'],
          icon: Icons.report_problem_rounded,
          onTap: () => _openPage(const ReportPage()),
        ),
        _SearchDestination(
          title: 'Online Service',
          subtitle: 'Open available digital municipal services',
          keywords: const ['service', 'online', 'permit', 'request', 'form'],
          icon: Icons.language_rounded,
          onTap: _openOnlineServicePage,
        ),
        _SearchDestination(
          title: 'Birth Certificate',
          subtitle: 'Open the online birth certificate appointment service',
          keywords: const [
            'birthcertificate',
            'birth certificate',
            'psa',
            'certificate of live birth',
            'appointment',
            'document request',
          ],
          icon: Icons.child_friendly_rounded,
          onTap: () => _openOnlineServicePage(
            initialTarget: OnlineServiceTarget.birthCertificate,
          ),
        ),
        _SearchDestination(
          title: 'Marriage Certificate',
          subtitle: 'Open the online marriage certificate appointment service',
          keywords: const [
            'marriagecertificate',
            'marriage certificate',
            'wedding certificate',
            'appointment',
            'document request',
          ],
          icon: Icons.favorite_rounded,
          onTap: () => _openOnlineServicePage(
            initialTarget: OnlineServiceTarget.marriageCertificate,
          ),
        ),
        _SearchDestination(
          title: 'Death Certificate',
          subtitle: 'Open the online death certificate appointment service',
          keywords: const [
            'deathcertificate',
            'death certificate',
            'certificate of death',
            'appointment',
            'document request',
          ],
          icon: Icons.local_florist_rounded,
          onTap: () => _openOnlineServicePage(
            initialTarget: OnlineServiceTarget.deathCertificate,
          ),
        ),
        _SearchDestination(
          title: 'CENOMAR',
          subtitle: 'Open the online CENOMAR appointment service',
          keywords: const [
            'cenomar',
            'certificate of no marriage record',
            'single status',
            'appointment',
          ],
          icon: Icons.verified_user_rounded,
          onTap: () => _openOnlineServicePage(
            initialTarget: OnlineServiceTarget.cenomar,
          ),
        ),
        _SearchDestination(
          title: 'CENODEATH',
          subtitle: 'Open the online CENODEATH appointment service',
          keywords: const [
            'cenodeath',
            'certificate of no death',
            'appointment',
          ],
          icon: Icons.fact_check_rounded,
          onTap: () => _openOnlineServicePage(
            initialTarget: OnlineServiceTarget.cenodeath,
          ),
        ),
        _SearchDestination(
          title: 'Tiwi Gymnasium',
          subtitle: 'Open the facility borrowing request page',
          keywords: const [
            'gymnasium',
            'tiwi gym',
            'facility',
            'borrow',
            'reservation',
          ],
          icon: Icons.apartment_rounded,
          onTap: () => _openOnlineServicePage(
            initialTarget: OnlineServiceTarget.tiwiGymnasium,
          ),
        ),
        _SearchDestination(
          title: 'Libjo Facilities',
          subtitle: 'Open the facility borrowing request page',
          keywords: const [
            'libjo',
            'facility',
            'borrow',
            'reservation',
            'venue',
          ],
          icon: Icons.location_city_rounded,
          onTap: () => _openOnlineServicePage(
            initialTarget: OnlineServiceTarget.libjoFacilities,
          ),
        ),
        _SearchDestination(
          title: 'News',
          subtitle: 'Read the latest municipal announcements and updates',
          keywords: const ['news', 'announcement', 'updates', 'advisory'],
          icon: Icons.campaign_rounded,
          onTap: () => _openPage(const NewsPage()),
        ),
        _SearchDestination(
          title: 'Profile',
          subtitle: 'View account details, settings, and preferences',
          keywords: const ['profile', 'account', 'settings', 'user'],
          icon: Icons.person_rounded,
          onTap: () => _openPage(
            ProfilePage(
              isDarkMode: widget.isDarkMode,
              onToggleDarkMode: widget.onToggleDarkMode ?? (_) {},
              onNavigate: _handleBottomNavigation,
            ),
          ),
        ),
        _SearchDestination(
          title: 'FAQs',
          subtitle: 'Read common questions and app help information',
          keywords: const ['faq', 'help', 'questions', 'support'],
          icon: Icons.help_center_rounded,
          onTap: () => _openPage(const FaqPage()),
        ),
      ];

  List<_SearchDestination> get _barangaySearchDestinations => _barangays
      .map(
        (barangay) => _SearchDestination(
          title: barangay['name']?.toString().trim().isNotEmpty == true
              ? barangay['name'].toString().trim()
              : 'Barangay',
          subtitle: 'Open barangay details page',
          keywords: [
            'barangay',
            barangay['name']?.toString() ?? '',
            barangay['description']?.toString() ?? '',
            barangay['geographic_data']?.toString() ?? '',
            barangay['officials']?.toString() ?? '',
          ],
          icon: Icons.location_city_rounded,
          onTap: () => _openSpecificBarangay(barangay),
        ),
      )
      .toList();

  List<_SearchDestination> get _searchDestinations => [
        ..._baseSearchDestinations,
        ..._barangaySearchDestinations,
      ];

  List<_SearchDestination> get _filteredSearchDestinations {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return const [];

    final seen = <String>{};
    final matches = _searchDestinations.where((item) => item.matches(query));

    return matches.where((item) {
      final key = '${item.title}|${item.subtitle}'.toLowerCase();
      if (seen.contains(key)) {
        return false;
      }
      seen.add(key);
      return true;
    }).toList();
  }

  void _handleSearchSelection(_SearchDestination destination) {
    FocusScope.of(context).unfocus();
    _searchController.clear();
    setState(() {});
    destination.onTap();
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

            return Stack(
              clipBehavior: Clip.none,
              children: [
                Column(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: headerHeight,
                            child: Stack(
                              clipBehavior: Clip.none,
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
                                            Scaffold.of(buttonContext)
                                                .openDrawer();
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: _SearchPill(
                                          hintText:
                                              'Search services, certificates, barangays...',
                                          compact: compact || extraCompact,
                                          controller: _searchController,
                                          onChanged: (_) => setState(() {}),
                                          onClear: () {
                                            _searchController.clear();
                                            setState(() {});
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      _TopActionButton(
                                        icon: Icons.notifications_none_rounded,
                                        compact: compact || extraCompact,
                                        showBadge: _hasUnreadNotifications,
                                        onTap: () =>
                                            _openPage(const NotificationPage()),
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
                                      physics:
                                          const NeverScrollableScrollPhysics(),
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
                                          onTap: () =>
                                              _openPage(const BarangayPage()),
                                        ),
                                        _HomeShortcut(
                                          icon: Icons.location_on_rounded,
                                          label: 'Tourist Guide',
                                          iconBackground: iconBackground,
                                          iconColor: iconColor,
                                          iconContainerSize: shortcutIconSize,
                                          labelFontSize: shortcutLabelSize,
                                          onTap: () => _openPage(
                                            const TouristGuidePage(),
                                          ),
                                        ),
                                        _HomeShortcut(
                                          icon: Icons.warning_amber_rounded,
                                          label: 'Emergency',
                                          iconBackground: iconBackground,
                                          iconColor: iconColor,
                                          iconContainerSize: shortcutIconSize,
                                          labelFontSize: shortcutLabelSize,
                                          onTap: () =>
                                              _openPage(const HotlinePage()),
                                        ),
                                        _HomeShortcut(
                                          icon: Icons.description_rounded,
                                          label: 'Transparency',
                                          iconBackground: iconBackground,
                                          iconColor: iconColor,
                                          iconContainerSize: shortcutIconSize,
                                          labelFontSize: shortcutLabelSize,
                                          onTap: () => _openPage(
                                            const TransparencyPage(),
                                          ),
                                        ),
                                        _HomeShortcut(
                                          icon: Icons.report_problem_rounded,
                                          label: 'Report',
                                          iconBackground: iconBackground,
                                          iconColor: iconColor,
                                          iconContainerSize: shortcutIconSize,
                                          labelFontSize: shortcutLabelSize,
                                          onTap: () =>
                                              _openPage(const ReportPage()),
                                        ),
                                        _HomeShortcut(
                                          icon: Icons.language_rounded,
                                          label: 'Online Service',
                                          iconBackground: iconBackground,
                                          iconColor: iconColor,
                                          iconContainerSize: shortcutIconSize,
                                          labelFontSize: shortcutLabelSize,
                                          onTap: () => _openPage(
                                            const OnlineServicePage(),
                                          ),
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
                                          title:
                                              "What's Your Next\nDestination?",
                                          description:
                                              "Whether it's a weekend trip or a month-long escape, make it unforgettable.",
                                          imagePath: 'assets/card.jpg',
                                          compact: compact || extraCompact,
                                          onTap: () => _openPage(
                                            const TouristGuidePage(),
                                          ),
                                        ),
                                        _DestinationPromoCard(
                                          title: 'Discover Tiwi\nHighlights',
                                          description:
                                              'Find scenic spots, hot springs, and beautiful places waiting for your next visit.',
                                          imagePath:
                                              'assets/municipal_hall.jpg',
                                          compact: compact || extraCompact,
                                          onTap: () => _openPage(
                                            const TouristGuidePage(),
                                          ),
                                        ),
                                        _DestinationPromoCard(
                                          title: 'Plan Your\nAdventure',
                                          description:
                                              'Explore top attractions and local favorites with just a few taps.',
                                          imagePath: 'assets/bg.jpg',
                                          compact: compact || extraCompact,
                                          onTap: () => _openPage(
                                            const TouristGuidePage(),
                                          ),
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
                                          duration: const Duration(
                                            milliseconds: 250,
                                          ),
                                          margin: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                          ),
                                          width: _currentPromoPage == index
                                              ? 18
                                              : 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: _currentPromoPage == index
                                                ? accentColor
                                                : accentColor.withValues(
                                                    alpha: 0.25,
                                                  ),
                                            borderRadius:
                                                BorderRadius.circular(999),
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
                ),
                if (_searchController.text.trim().isNotEmpty)
                  Positioned(
                    top: topPadding + (compact || extraCompact ? 52 : 56),
                    left: horizontalPadding + (compact || extraCompact ? 50 : 54),
                    right:
                        horizontalPadding + (compact || extraCompact ? 50 : 54),
                    child: _InlineSearchResults(
                      results: _filteredSearchDestinations,
                      query: _searchController.text.trim(),
                      onSelected: _handleSearchSelection,
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
    this.showBadge = false,
    this.onTap,
  });

  final IconData icon;
  final bool compact;
  final bool showBadge;
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
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Center(
                child: Icon(
                  icon,
                  color: isDark
                      ? const Color(0xFFB9DBFF)
                      : const Color(0xFF4F6F8F),
                  size: compact ? 22 : 24,
                ),
              ),
              if (showBadge)
                Positioned(
                  top: compact ? 9 : 8,
                  right: compact ? 9 : 8,
                  child: Container(
                    width: compact ? 10 : 11,
                    height: compact ? 10 : 11,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF3B30),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? const Color(0xFF162B4B) : Colors.white,
                        width: 1.4,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchPill extends StatelessWidget {
  const _SearchPill({
    required this.hintText,
    required this.controller,
    this.compact = false,
    this.onChanged,
    this.onClear,
  });

  final String hintText;
  final TextEditingController controller;
  final bool compact;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: compact ? 42 : 46,
      alignment: Alignment.center,
      clipBehavior: Clip.antiAlias,
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
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              textAlignVertical: TextAlignVertical.center,
              cursorColor: isDark ? Colors.white70 : const Color(0xFF4F6F8F),
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: compact ? 13 : 14,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                isDense: true,
                isCollapsed: true,
                contentPadding: EdgeInsets.zero,
                hintText: hintText,
                hintStyle: TextStyle(
                  color: isDark ? Colors.white70 : Colors.grey.shade600,
                  fontSize: compact ? 13 : 14,
                  fontWeight: FontWeight.w500,
                ),
                filled: false,
                fillColor: Colors.transparent,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
              ),
            ),
          ),
          if (controller.text.isNotEmpty) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onClear,
              child: Icon(
                Icons.close_rounded,
                color: isDark ? Colors.white70 : Colors.grey.shade500,
                size: 20,
              ),
            ),
          ],
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

class _SearchDestination {
  const _SearchDestination({
    required this.title,
    required this.subtitle,
    required this.keywords,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final List<String> keywords;
  final IconData icon;
  final VoidCallback onTap;

  bool matches(String value) {
    final query = value.trim().toLowerCase();
    if (query.isEmpty) return true;

    bool startsWithQuery(String text) {
      final normalized = text.trim().toLowerCase();
      if (normalized.isEmpty) return false;

      return normalized.startsWith(query);
    }

    return startsWithQuery(title);
  }
}

class _InlineSearchResults extends StatelessWidget {
  const _InlineSearchResults({
    required this.results,
    required this.query,
    required this.onSelected,
  });

  final List<_SearchDestination> results;
  final String query;
  final ValueChanged<_SearchDestination> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final panelColor = isDark ? const Color(0xFF111827) : const Color(0xFFF8F8F8);
    final dividerColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFFE3E3E3);
    final primaryText = isDark ? Colors.white : const Color(0xFF111111);
    final secondaryText = isDark ? Colors.white60 : const Color(0xFF7A7A7A);

    return Material(
      color: Colors.transparent,
      elevation: 0,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 300),
        decoration: BoxDecoration(
          color: panelColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: dividerColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.24 : 0.12),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: results.isEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 18,
                ),
                child: Text(
                  'No results for "$query"',
                  style: TextStyle(
                    color: secondaryText,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                shrinkWrap: true,
                itemCount: results.length,
                separatorBuilder: (_, _) => Divider(
                  height: 1,
                  thickness: 1,
                  color: dividerColor,
                  indent: 16,
                  endIndent: 16,
                ),
                itemBuilder: (context, index) {
                  final item = results[index];
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => onSelected(item),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white24
                                      : const Color(0xFFD0D0D0),
                                ),
                              ),
                              child: Icon(
                                Icons.place_outlined,
                                size: 16,
                                color: secondaryText,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                item.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: primaryText,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
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
