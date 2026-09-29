import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io' show SocketException;

import 'content_cache_service.dart';
import 'news_page.dart';
import 'shared_widgets.dart';

class HotlinePage extends StatefulWidget {
  const HotlinePage({super.key});

  @override
  State<HotlinePage> createState() => _HotlinePageState();
}

class _HotlinePageState extends State<HotlinePage> {
  final supabase = Supabase.instance.client;
  final _cacheService = const ContentCacheService();

  List<Map<String, dynamic>> hotlines = [];
  bool isLoading = true;
  bool isShowingCachedData = false;
  DateTime? cacheUpdatedAt;

  @override
  void initState() {
    super.initState();
    // Keep the emergency number available immediately, even before cached or
    // remote hotline records have finished loading.
    hotlines = _normalizeHotlines(const []);
    isLoading = false;
    unawaited(_loadCachedHotlinesThenRefresh());
  }

  Future<void> _loadCachedHotlinesThenRefresh() async {
    final cached = await _cacheService.getHotlines();

    if (!mounted) return;

    if (cached.hasData) {
      setState(() {
        hotlines = _normalizeHotlines(cached.items);
        isShowingCachedData = true;
        cacheUpdatedAt = cached.updatedAt;
      });
    }

    // Refresh without replacing the visible emergency contacts with a loader.
    unawaited(fetchHotlines(showLoading: false));
  }

  List<String> _extractPhoneNumbers(Map<String, dynamic> item) {
    final rawNumbers = item['phone_numbers'];
    if (rawNumbers is List) {
      return rawNumbers
          .map((number) => number.toString())
          .where((number) => number.trim().isNotEmpty)
          .toList();
    }

    if (rawNumbers is String && rawNumbers.trim().isNotEmpty) {
      return rawNumbers
          .split(',')
          .map((number) => number.trim())
          .where((number) => number.isNotEmpty)
          .toList();
    }

    final singleNumber = item['hotline_number'] ?? item['phone_number'];
    if (singleNumber is String && singleNumber.trim().isNotEmpty) {
      return [singleNumber.trim()];
    }

    return [];
  }

  String? _extractLogoUrl(Map<String, dynamic> item) {
    final fromKeys = [
      item['logo_url'],
      item['logo'],
      item['image_url'],
      item['image'],
      item['icon_url'],
    ];

    for (final value in fromKeys) {
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }

    return null;
  }

  Future<void> fetchHotlines({bool showLoading = true}) async {
    if (showLoading && mounted) {
      setState(() {
        isLoading = true;
      });
    }

    try {
      final data = await supabase
          .from('hotlines')
          .select()
          .order('created_at', ascending: false);

      final mapped = List<Map<String, dynamic>>.from(
        (data as List).map((item) => Map<String, dynamic>.from(item as Map)),
      );

      final normalized = _normalizeHotlines(mapped);

      if (!mounted) return;

      setState(() {
        hotlines = normalized;
        isShowingCachedData = false;
        cacheUpdatedAt = DateTime.now();
        isLoading = false;
      });

      // Caching must not hold up the screen once fresh contacts are available.
      unawaited(_cacheService.saveHotlines(normalized));
    } catch (e) {
      final cached = await _cacheService.getHotlines();

      final isOfflineError =
          e is SocketException ||
          e.toString().contains('Failed host lookup') ||
          e.toString().contains('SocketException');

      if (!mounted) return;

      setState(() {
        hotlines = _normalizeHotlines(cached.items);
        isShowingCachedData = cached.hasData;
        cacheUpdatedAt = cached.updatedAt;
        isLoading = false;
      });

      // If we have cached data, show an offline notice. If the error is
      // not an offline/network error, surface it. Otherwise, suppress it.
      if (cached.hasData) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Offline mode: showing previously loaded hotlines.'),
          ),
        );
      } else if (!isOfflineError) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Unable to load hotlines: $e')));
      }
    }
  }

  List<Map<String, dynamic>> _normalizeHotlines(
    List<Map<String, dynamic>> items,
  ) {
    final baseList = items.map((item) {
      final category = item['category']?.toString().trim();
      final cleanItem = Map<String, dynamic>.from(item);
      cleanItem['category'] = category != null && category.isNotEmpty
          ? category
          : 'General';
      cleanItem['logo_url'] ??= _extractLogoUrl(cleanItem);
      cleanItem['phone_numbers'] ??= _extractPhoneNumbers(cleanItem);
      cleanItem['name'] ??=
          cleanItem['department'] ?? cleanItem['agency'] ?? 'Hotline';
      cleanItem['description'] ??= cleanItem['details'] ?? 'Emergency contact';
      return cleanItem;
    }).toList();

    final emergencyEntry = {
      'id': 'hardcoded_911',
      'name': '911',
      'category': 'Emergency',
      'phone_numbers': ['911'],
      'description':
          'Immediate emergency response for life-threatening situations.',
      'logo_url': null,
    };

    final cleaned = <Map<String, dynamic>>[];
    final seenIds = <String>{};

    for (final item in [emergencyEntry, ...baseList]) {
      final fallbackKey = [
        item['id']?.toString(),
        item['name']?.toString(),
        item['department']?.toString(),
        item['agency']?.toString(),
        item['phone_numbers'] is List
            ? (item['phone_numbers'] as List).join('|')
            : item['phone_numbers']?.toString(),
        item['hotline_number']?.toString(),
        item['category']?.toString(),
      ].whereType<String>().join('|');
      final id = fallbackKey.isNotEmpty
          ? fallbackKey
          : 'hotline-${cleaned.length}';
      if (seenIds.contains(id)) continue;
      cleaned.add(item);
      seenIds.add(id);
    }

    cleaned.sort((a, b) {
      final aCategory = (a['category'] ?? 'General').toString();
      final bCategory = (b['category'] ?? 'General').toString();
      final aRank = _categoryRank(aCategory);
      final bRank = _categoryRank(bCategory);

      if (aRank != bRank) return aRank.compareTo(bRank);

      final aName = (a['name'] ?? '').toString();
      final bName = (b['name'] ?? '').toString();
      return aName.toLowerCase().compareTo(bName.toLowerCase());
    });

    final emergencyFirst = cleaned.firstWhere(
      (item) =>
          (item['category'] ?? '').toString().toLowerCase() == 'emergency',
      orElse: () => cleaned.first,
    );
    if (emergencyFirst != cleaned.first) {
      cleaned.remove(emergencyFirst);
      cleaned.insert(0, emergencyFirst);
    }

    return cleaned;
  }

  void callNumber(String number) async {
    final Uri url = Uri.parse('tel:$number');
    await launchUrl(url);
  }

  void copyNumber(String number) {
    Clipboard.setData(ClipboardData(text: number));

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Copied $number')));
  }

  String _normalizeCategory(String category) {
    final cleaned = category.trim();
    if (cleaned.isEmpty) return 'General';

    final normalized = cleaned.toLowerCase();
    if (normalized == 'emergency' || normalized == 'emergency services') {
      return 'Emergency';
    }
    if (normalized.contains('fire') && normalized.contains('rescue')) {
      return 'Fire & Rescue';
    }
    if (normalized.contains('law') && normalized.contains('enforcement')) {
      return 'Law Enforcement';
    }
    if (normalized.contains('disaster')) {
      return 'Disaster Management';
    }
    if (normalized.contains('local') && normalized.contains('government')) {
      return 'Local Government';
    }
    if (normalized.contains('public') && normalized.contains('safety')) {
      return 'Public Safety';
    }
    if (normalized.contains('health')) {
      return 'Health';
    }
    if (normalized.contains('social')) {
      return 'Social Services';
    }
    if (normalized.contains('infra')) {
      return 'Infrastructure';
    }
    if (normalized.contains('admin')) {
      return 'Administrative';
    }
    if (normalized.contains('support')) {
      return 'Support';
    }
    return cleaned;
  }

  Map<String, List<Map<String, dynamic>>> _groupHotlinesByCategory() {
    final grouped = <String, List<Map<String, dynamic>>>{};

    for (final hotline in hotlines) {
      final rawCategory = (hotline['category'] ?? 'General').toString();
      final key = _normalizeCategory(rawCategory);
      grouped.putIfAbsent(key, () => <Map<String, dynamic>>[]).add(hotline);
    }

    final ordered = <String, List<Map<String, dynamic>>>{};
    final keys = grouped.keys.toList()
      ..sort((a, b) {
        final aRank = _categoryRank(a);
        final bRank = _categoryRank(b);
        if (aRank != bRank) return aRank.compareTo(bRank);
        return a.toLowerCase().compareTo(b.toLowerCase());
      });

    for (final key in keys) {
      ordered[key] = grouped[key]!;
    }

    return ordered;
  }

  int _categoryRank(String category) {
    final normalized = category.trim();
    final key = normalized.toLowerCase();

    if (key == 'emergency') return 0;
    if (key == 'fire & rescue' || key == 'fire and rescue') return 1;
    if (key == 'law enforcement') return 2;
    if (key == 'public safety') return 3;
    if (key == 'health') return 4;
    if (key == 'disaster management') return 5;
    if (key == 'local government') return 6;
    if (key == 'social services') return 7;
    if (key == 'infrastructure') return 8;
    if (key == 'administrative') return 9;
    if (key == 'support') return 10;
    return 11;
  }

  Widget _buildEmergencyHeroCard(
    Map<String, dynamic> item,
    ThemeData theme,
    bool isDark,
    Color surfaceColor,
    Color secondarySurface,
    Color primaryTextColor,
    Color secondaryTextColor,
  ) {
    final phoneNumbers = _extractPhoneNumbers(item);
    final number = phoneNumbers.isNotEmpty ? phoneNumbers.first : '911';

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF7A5C), Color(0xFFF35A53)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.22),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Center(
              child: Text(
                '24/7',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '911',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 38,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  (item['description'] ?? 'Immediate emergency response')
                      .toString(),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12.6,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            children: [
              _quickActionButton(
                icon: Icons.call_rounded,
                label: 'Call 911',
                onTap: () => callNumber(number),
                background: Colors.white.withValues(alpha: 0.18),
              ),
              const SizedBox(height: 10),
              _quickActionButton(
                icon: Icons.copy_rounded,
                label: 'Copy',
                onTap: () => copyNumber(number),
                background: Colors.white.withValues(alpha: 0.18),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color background,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 88,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection(
    String category,
    List<Map<String, dynamic>> items,
    bool isDark,
    Color surfaceColor,
    Color secondarySurface,
    Color primaryTextColor,
    Color secondaryTextColor,
    Color avatarBackground,
    Color copyButtonBackground,
    Color callButtonBackground,
  ) {
    final displayCategory = category.isEmpty ? 'General' : category;
    final iconColor = displayCategory.toLowerCase() == 'emergency'
        ? Colors.red
        : AppColors.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.warning_amber_rounded, size: 18, color: iconColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  displayCategory.toUpperCase(),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: primaryTextColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        ...items.map((item) {
          final phoneNumbers = _extractPhoneNumbers(item);
          final logoUrl = _extractLogoUrl(item);

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: avatarBackground,
                      child: logoUrl == null
                          ? const Icon(Icons.local_police_rounded, size: 20)
                          : ClipOval(
                              child: Image.network(
                                logoUrl,
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(
                                      Icons.local_police_rounded,
                                      size: 20,
                                    ),
                              ),
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['name'] ?? 'Hotline',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: primaryTextColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item['description']?.toString() ??
                                'Emergency contact',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : const Color(0xFFEAF3FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        displayCategory,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (phoneNumbers.isEmpty)
                  Text(
                    'No phone numbers available',
                    style: TextStyle(fontSize: 13, color: secondaryTextColor),
                  )
                else
                  ...phoneNumbers.map((number) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.04)
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? Colors.white10
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.phone_rounded,
                            color: AppColors.primary,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              number,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: primaryTextColor,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                onPressed: () => copyNumber(number),
                                icon: const Icon(Icons.copy_rounded, size: 18),
                                tooltip: 'Copy',
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 4),
                              IconButton(
                                onPressed: () => callNumber(number),
                                icon: const Icon(Icons.call_rounded, size: 18),
                                tooltip: 'Call',
                                color: AppColors.success,
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          );
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final scaffoldBackground = isDark
        ? const Color(0xFF0B1220)
        : const Color(0xFFEAEAEA);
    final surfaceColor = isDark
        ? const Color(0xFF1F2937)
        : const Color(0xFFF7F7F7);
    final secondarySurface = isDark
        ? const Color(0xFF243145)
        : const Color(0xFFE9EEF6);
    final primaryTextColor = isDark ? Colors.white : Colors.black87;
    final secondaryTextColor = isDark ? Colors.white70 : Colors.black54;
    final emptyIconColor = isDark ? Colors.white24 : Colors.grey[300]!;
    final emptyTextColor = isDark ? Colors.white60 : Colors.grey[500]!;
    final avatarBackground = isDark
        ? const Color(0xFF243145)
        : Colors.grey[200]!;
    final copyButtonBackground = isDark
        ? const Color(0xFF243145)
        : const Color(0xFFF1F5F9);
    final callButtonBackground = isDark
        ? AppColors.success.withValues(alpha: 0.18)
        : AppColors.success.withValues(alpha: 0.12);
    final topGradient = isDark
        ? const [Color(0xFF0F172A), Color(0xFF172554), Color(0xFF111827)]
        : const [Color(0xFF1E88E5), Color(0xFF90CAF9), Color(0xFFEAEAEA)];

    return Scaffold(
      drawer: AdminSidebar(
        userName: 'Admin User',
        userEmail: 'admin@example.com',
        currentIndex: 3,
        onNavigationChanged: (index) {
          if (index == 0) Navigator.pop(context);
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NewsPage()),
            );
          }
        },
      ),
      backgroundColor: scaffoldBackground,
      body: Stack(
        children: [
          Container(
            height: 220,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: topGradient,
                stops: const [0.0, 0.58, 1.0],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 12, 16, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Emergency Hotlines',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: fetchHotlines,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                      children: [
                        if (isShowingCachedData) ...[
                          const OfflineDataBanner(),
                          const SizedBox(height: 16),
                        ],
                        if (isLoading)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 48),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (hotlines.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: surfaceColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.phone_missed,
                                  size: 72,
                                  color: emptyIconColor,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No hotlines available',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: primaryTextColor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Emergency hotline entries will appear here once they are available.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    height: 1.5,
                                    color: emptyTextColor,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          ...() {
                            final grouped = _groupHotlinesByCategory();
                            final emergencyEntry = grouped.entries.firstWhere(
                              (entry) => entry.key.toLowerCase() == 'emergency',
                              orElse: () =>
                                  const MapEntry('', <Map<String, dynamic>>[]),
                            );

                            final emergencyCard =
                                emergencyEntry.key.isNotEmpty &&
                                    emergencyEntry.value.isNotEmpty
                                ? _buildEmergencyHeroCard(
                                    emergencyEntry.value.first,
                                    theme,
                                    isDark,
                                    surfaceColor,
                                    secondarySurface,
                                    primaryTextColor,
                                    secondaryTextColor,
                                  )
                                : null;

                            final categoryEntries = grouped.entries.toList();
                            final emergencyItems = emergencyEntry.value
                                .where(
                                  (item) =>
                                      !(item['name']?.toString() == '911'),
                                )
                                .toList();

                            if (emergencyEntry.key.isNotEmpty) {
                              final emergencyCategoryIndex = categoryEntries
                                  .indexWhere(
                                    (entry) =>
                                        entry.key.toLowerCase() == 'emergency',
                                  );
                              if (emergencyCategoryIndex >= 0) {
                                final emergencySectionValue =
                                    emergencyItems.isNotEmpty
                                    ? [
                                        ...emergencyEntry.value.where(
                                          (item) =>
                                              item['name']?.toString() != '911',
                                        ),
                                      ]
                                    : emergencyEntry.value;
                                categoryEntries[emergencyCategoryIndex] =
                                    MapEntry(
                                      'Emergency',
                                      emergencySectionValue,
                                    );
                              }
                            }

                            final nonEmergencySections = categoryEntries
                                .where(
                                  (entry) =>
                                      entry.key.toLowerCase() != 'emergency',
                                )
                                .toList();

                            final sectionWidgets = <Widget>[];
                            if (emergencyCard != null) {
                              sectionWidgets.add(emergencyCard);
                            }
                            sectionWidgets.addAll(
                              categoryEntries
                                  .where(
                                    (entry) =>
                                        entry.key.toLowerCase() == 'emergency',
                                  )
                                  .map(
                                    (entry) => _buildCategorySection(
                                      entry.key,
                                      entry.value,
                                      isDark,
                                      surfaceColor,
                                      secondarySurface,
                                      primaryTextColor,
                                      secondaryTextColor,
                                      avatarBackground,
                                      copyButtonBackground,
                                      callButtonBackground,
                                    ),
                                  ),
                            );
                            sectionWidgets.addAll(
                              nonEmergencySections.map((entry) {
                                return _buildCategorySection(
                                  entry.key,
                                  entry.value,
                                  isDark,
                                  surfaceColor,
                                  secondarySurface,
                                  primaryTextColor,
                                  secondaryTextColor,
                                  avatarBackground,
                                  copyButtonBackground,
                                  callButtonBackground,
                                );
                              }),
                            );
                            return sectionWidgets;
                          }(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
