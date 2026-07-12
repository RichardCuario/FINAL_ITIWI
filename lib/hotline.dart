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
    fetchHotlines();
  }

  Future<void> fetchHotlines() async {
    if (mounted) {
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

      await _cacheService.saveHotlines(mapped);

      if (!mounted) return;

      setState(() {
        hotlines = mapped;
        isShowingCachedData = false;
        cacheUpdatedAt = DateTime.now();
        isLoading = false;
      });
    } catch (e) {
      final cached = await _cacheService.getHotlines();

      final isOfflineError = e is SocketException ||
          e.toString().contains('Failed host lookup') ||
          e.toString().contains('SocketException');

      if (!mounted) return;

      setState(() {
        hotlines = cached.items;
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to load hotlines: $e')),
        );
      }
    }
  }

  void callNumber(String number) async {
    final Uri url = Uri.parse('tel:$number');
    await launchUrl(url);
  }

  void copyNumber(String number) {
    Clipboard.setData(ClipboardData(text: number));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Copied $number')),
    );
  }

  

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final scaffoldBackground =
        isDark ? const Color(0xFF0B1220) : const Color(0xFFEAEAEA);
    final surfaceColor =
        isDark ? const Color(0xFF1F2937) : const Color(0xFFF7F7F7);
    final secondarySurface =
        isDark ? const Color(0xFF243145) : const Color(0xFFE9EEF6);
    final primaryTextColor = isDark ? Colors.white : Colors.black87;
    final secondaryTextColor = isDark ? Colors.white70 : Colors.black54;
    final emptyIconColor = isDark ? Colors.white24 : Colors.grey[300]!;
    final emptyTextColor = isDark ? Colors.white60 : Colors.grey[500]!;
    final avatarBackground =
        isDark ? const Color(0xFF243145) : Colors.grey[200]!;
    final copyButtonBackground =
        isDark ? const Color(0xFF243145) : const Color(0xFFF1F5F9);
    final callButtonBackground = isDark
        ? AppColors.success.withValues(alpha: 0.18)
        : AppColors.success.withValues(alpha: 0.12);
    final topGradient = isDark
        ? const [
            Color(0xFF0F172A),
            Color(0xFF172554),
            Color(0xFF111827),
          ]
        : const [
            Color(0xFF1E88E5),
            Color(0xFF90CAF9),
            Color(0xFFEAEAEA),
          ];

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
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: surfaceColor,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: secondarySurface,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.support_agent_rounded,
                                  color: AppColors.primary,
                                  size: 27,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Quick access to emergency contacts',
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                        color: primaryTextColor,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Reach municipal offices and first responders fast. Tap call to dial instantly or copy a number for later use.',
                                      style: TextStyle(
                                        fontSize: 12.8,
                                        height: 1.45,
                                        color: secondaryTextColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

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
                          ...hotlines.map((item) {
                            final phoneNumbers =
                                (item['phone_numbers'] as List? ?? [])
                                    .map((number) => number.toString())
                                    .where((number) => number.trim().isNotEmpty)
                                    .toList();

                            return Container(
                              margin: const EdgeInsets.only(bottom: 14),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: surfaceColor,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 10,
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
                                        radius: 24,
                                        backgroundImage: item['logo_url'] != null
                                            ? NetworkImage(item['logo_url'])
                                            : null,
                                        backgroundColor: avatarBackground,
                                        child: item['logo_url'] == null
                                            ? const Icon(Icons.image)
                                            : null,
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item['name'] ?? 'Hotline',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 16,
                                                color: primaryTextColor,
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              item['description']?.toString() ??
                                                  'Emergency contact',
                                              style: TextStyle(
                                                fontSize: 12.5,
                                                color: secondaryTextColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  if (phoneNumbers.isEmpty)
                                    Text(
                                      'No phone numbers available',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: secondaryTextColor,
                                      ),
                                    )
                                  else
                                    ...phoneNumbers.map(
                                      (number) => Container(
                                        margin: const EdgeInsets.only(bottom: 12),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? Colors.white.withValues(
                                                  alpha: 0.04,
                                                )
                                              : const Color(0xFFF8FAFC),
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          border: Border.all(
                                            color: isDark
                                                ? Colors.white10
                                                : const Color(0xFFE2E8F0),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 42,
                                              height: 42,
                                              decoration: BoxDecoration(
                                                color: secondarySurface,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: const Icon(
                                                Icons.phone_rounded,
                                                color: AppColors.primary,
                                                size: 20,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                number,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 14.5,
                                                  color: primaryTextColor,
                                                ),
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                Container(
                                                  decoration: BoxDecoration(
                                                    color:
                                                        copyButtonBackground,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  child: IconButton(
                                                    icon: const Icon(
                                                      Icons.copy_rounded,
                                                      color: AppColors.primary,
                                                      size: 20,
                                                    ),
                                                    onPressed: () =>
                                                        copyNumber(number),
                                                    constraints:
                                                        const BoxConstraints(
                                                          minWidth: 42,
                                                          minHeight: 42,
                                                        ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Container(
                                                  decoration: BoxDecoration(
                                                    color:
                                                        callButtonBackground,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  child: IconButton(
                                                    icon: const Icon(
                                                      Icons.call_rounded,
                                                      color:
                                                          AppColors.success,
                                                      size: 20,
                                                    ),
                                                    onPressed: () =>
                                                        callNumber(number),
                                                    constraints:
                                                        const BoxConstraints(
                                                          minWidth: 42,
                                                          minHeight: 42,
                                                        ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          }),
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
