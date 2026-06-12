import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'content_cache_service.dart';
import 'news_detail_page.dart';
import 'shared_widgets.dart';

class NewsPage extends StatefulWidget {
  final VoidCallback? onBack;

  const NewsPage({super.key, this.onBack});

  @override
  State<NewsPage> createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  final supabase = Supabase.instance.client;
  final _cacheService = const ContentCacheService();

  List<Map<String, dynamic>> news = [];
  List<Map<String, dynamic>> filteredNews = [];
  String searchQuery = '';
  bool isLoading = true;
  bool isShowingCachedData = false;
  DateTime? cacheUpdatedAt;
  bool hasUnreadNews = false;

  int currentIndex = 1;

  String? _buildNewsMarker(List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      return null;
    }

    final latest = items.first;
    final id = latest['id']?.toString() ?? '';
    final createdAt = latest['created_at']?.toString() ?? '';
    final updatedAt = latest['updated_at']?.toString() ?? '';

    return '$id|$createdAt|$updatedAt';
  }

  Future<void> _markCurrentNewsAsSeen(List<Map<String, dynamic>> items) async {
    final marker = _buildNewsMarker(items);
    if (marker == null) return;
    await _cacheService.markNewsAsSeen(marker);

    if (!mounted) return;
    setState(() {
      hasUnreadNews = false;
    });
  }

  Future<void> _refreshUnreadNewsIndicator([
    List<Map<String, dynamic>>? items,
  ]) async {
    final latestMarker = items != null
        ? _buildNewsMarker(items)
        : await _cacheService.getLatestNewsMarker();
    final seenMarker = await _cacheService.getSeenNewsMarker();

    if (!mounted) return;

    setState(() {
      hasUnreadNews =
          latestMarker != null &&
          latestMarker.isNotEmpty &&
          latestMarker != seenMarker;
    });
  }

  void _handleNavigation(int index) {
    setState(() {
      currentIndex = index;
    });

    if (index == 0) {
      Navigator.pop(context);
    }
  }

  @override
  void initState() {
    super.initState();
    fetchNews();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _refreshUnreadNewsIndicator();
    });
  }

  Future<void> fetchNews() async {
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

    try {
      final data = await supabase
          .from('news')
          .select()
          .order('created_at', ascending: false);

      final mapped = List<Map<String, dynamic>>.from(
        (data as List).map((item) => Map<String, dynamic>.from(item as Map)),
      );

      await _cacheService.saveNews(mapped);

      final latestMarker = _buildNewsMarker(mapped);
      if (latestMarker != null) {
        await _cacheService.saveLatestNewsMarker(latestMarker);
      }

      if (!mounted) return;

      setState(() {
        news = mapped;
        isShowingCachedData = false;
        cacheUpdatedAt = DateTime.now();
        isLoading = false;
      });

      _applySearch(searchQuery);
      await _refreshUnreadNewsIndicator(mapped);
      await _markCurrentNewsAsSeen(mapped);
    } catch (e) {
      final cached = await _cacheService.getNews();

      if (!mounted) return;

      setState(() {
        news = cached.items;
        isShowingCachedData = cached.hasData;
        cacheUpdatedAt = cached.updatedAt;
        isLoading = false;
      });

      _applySearch(searchQuery);
      await _refreshUnreadNewsIndicator(cached.items);
      await _markCurrentNewsAsSeen(cached.items);

      if (!mounted) return;

      if (cached.hasData) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'You are offline. Showing previously loaded news.',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to load news: $e')),
        );
      }
    }
  }

  void _applySearch(String query) {
    final normalizedQuery = query.toLowerCase();

    if (normalizedQuery.isEmpty) {
      filteredNews = List<Map<String, dynamic>>.from(news);
      return;
    }

    filteredNews = news.where((item) {
      final title = item['title']?.toString().toLowerCase() ?? '';
      final description = item['description']?.toString().toLowerCase() ?? '';

      return title.contains(normalizedQuery) ||
          description.contains(normalizedQuery);
    }).toList();
  }

  void searchNews(String query) {
    setState(() {
      searchQuery = query;
      _applySearch(query);
    });
  }

  String _formatCacheUpdatedAt() {
    final value = cacheUpdatedAt;
    if (value == null) {
      return 'previous session';
    }

    final local = value.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');

    return '$month/$day ${local.year} $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final pageBackground =
        isDark ? const Color(0xFF0B1220) : const Color(0xFFEAEAEA);
    final inputBackground =
        isDark ? const Color(0xFF0F172A) : AppColors.background;
    final cardBackground = theme.cardColor;
    final primaryText =
        theme.textTheme.bodyLarge?.color ?? colorScheme.onSurface;
    final secondaryText =
        theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.72) ??
            colorScheme.onSurface.withValues(alpha: 0.72);
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
      backgroundColor: pageBackground,
      drawer: AdminSidebar(
        userName: 'Admin User',
        userEmail: 'admin@example.com',
        currentIndex: currentIndex,
        onNavigationChanged: _handleNavigation,
      ),
      body: Stack(
        children: [
          Container(
            height: 180,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: topGradient,
                stops: const [0.0, 0.62, 1.0],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 12, 16, 8),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed:
                            widget.onBack ?? () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Expanded(
                        child: Text(
                          'Latest Updates',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.notifications_outlined,
                              color: Colors.white,
                            ),
                          ),
                          if (hasUnreadNews)
                            Positioned(
                              right: -4,
                              top: -4,
                              child: Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF3B4D),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: const Text(
                                  '1',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                          padding: const EdgeInsets.only(top: 6, bottom: 24),
                          child: Column(
                            children: [
                              Container(
                                color: Colors.transparent,
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  8,
                                  16,
                                  20,
                                ),
                                child: Container(
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: inputBackground,
                                    borderRadius: BorderRadius.circular(25),
                                    border: Border.all(
                                      color: isDark
                                          ? Colors.white12
                                          : Colors.grey[300]!,
                                    ),
                                  ),
                                  child: TextField(
                                    onChanged: searchNews,
                                    decoration: InputDecoration(
                                      hintText: 'Search latest updates',
                                      hintStyle: TextStyle(
                                        color: isDark
                                            ? Colors.white54
                                            : Colors.grey[400],
                                      ),
                                      border: InputBorder.none,
                                      prefixIcon: Icon(
                                        Icons.search,
                                        color: isDark
                                            ? Colors.white54
                                            : Colors.grey[400],
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            vertical: 15,
                                          ),
                                    ),
                                  ),
                                ),
                              ),
                              if (isShowingCachedData)
                                Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.fromLTRB(
                                    16,
                                    0,
                                    16,
                                    0,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF3A2F12)
                                        : const Color(0xFFFFF4D6),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isDark
                                          ? const Color(0xFF8C6D1F)
                                          : const Color(0xFFE0BE63),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.offline_bolt_rounded,
                                        color: isDark
                                            ? const Color(0xFFFFD54F)
                                            : const Color(0xFF8A6200),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'Offline mode: showing cached news from ${_formatCacheUpdatedAt()}.',
                                          style: TextStyle(
                                            color: isDark
                                                ? const Color(0xFFFFECB3)
                                                : const Color(0xFF6B4F00),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              const SizedBox(height: 20),
                              if (filteredNews.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Top news',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: primaryText,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      SizedBox(
                                        height: 180,
                                        child: ListView.builder(
                                          scrollDirection: Axis.horizontal,
                                          itemCount:
                                              filteredNews.length.clamp(0, 3),
                                          itemBuilder: (context, index) {
                                            final item = filteredNews[index];
                                            return GestureDetector(
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        NewsDetailPage(
                                                          news: item,
                                                        ),
                                                  ),
                                                );
                                              },
                                              child: Container(
                                                width: 140,
                                                margin: const EdgeInsets.only(
                                                  right: 12,
                                                ),
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  color: cardBackground,
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black
                                                          .withValues(
                                                            alpha: isDark
                                                                ? 0.24
                                                                : 0.10,
                                                          ),
                                                      blurRadius: 6,
                                                      offset: const Offset(
                                                        0,
                                                        2,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    if (item['image_url'] !=
                                                        null)
                                                      ClipRRect(
                                                        borderRadius:
                                                            const BorderRadius.vertical(
                                                              top:
                                                                  Radius.circular(
                                                                    12,
                                                                  ),
                                                            ),
                                                        child: Image.network(
                                                          item['image_url'],
                                                          height: 100,
                                                          width:
                                                              double.infinity,
                                                          fit: BoxFit.cover,
                                                          errorBuilder: (
                                                            context,
                                                            error,
                                                            stackTrace,
                                                          ) {
                                                            return Container(
                                                              height: 100,
                                                              color: isDark
                                                                  ? const Color(
                                                                      0xFF243145,
                                                                    )
                                                                  : Colors
                                                                        .grey[300],
                                                              child: const Icon(
                                                                Icons
                                                                    .image_not_supported,
                                                                color:
                                                                    Colors.grey,
                                                              ),
                                                            );
                                                          },
                                                        ),
                                                      )
                                                    else
                                                      Container(
                                                        height: 100,
                                                        decoration: BoxDecoration(
                                                          color: isDark
                                                              ? const Color(
                                                                  0xFF243145,
                                                                )
                                                              : Colors
                                                                    .grey[200],
                                                          borderRadius:
                                                              const BorderRadius.vertical(
                                                                top:
                                                                    Radius.circular(
                                                                      12,
                                                                    ),
                                                              ),
                                                        ),
                                                        child: Icon(
                                                          Icons
                                                              .image_not_supported,
                                                          color:
                                                              Colors.grey[400],
                                                        ),
                                                      ),
                                                    Expanded(
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets.all(
                                                              10,
                                                            ),
                                                        child: Text(
                                                          item['title'] ??
                                                              'Untitled',
                                                          maxLines: 2,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: primaryText,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              const SizedBox(height: 30),
                              if (filteredNews.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Latest',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: secondaryText,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      ...filteredNews.map((item) {
                                        return GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    NewsDetailPage(news: item),
                                              ),
                                            );
                                          },
                                          child: Container(
                                            margin: const EdgeInsets.only(
                                              bottom: 20,
                                            ),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              color: cardBackground,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withValues(
                                                        alpha: isDark
                                                            ? 0.22
                                                            : 0.08,
                                                      ),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                if (item['image_url'] != null)
                                                  ClipRRect(
                                                    borderRadius:
                                                        const BorderRadius.vertical(
                                                          top: Radius.circular(
                                                            12,
                                                          ),
                                                        ),
                                                    child: Image.network(
                                                      item['image_url'],
                                                      height: 200,
                                                      width: double.infinity,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (
                                                        context,
                                                        error,
                                                        stackTrace,
                                                      ) {
                                                        return Container(
                                                          height: 200,
                                                          color: isDark
                                                              ? const Color(
                                                                  0xFF243145,
                                                                )
                                                              : Colors
                                                                    .grey[300],
                                                          child: const Icon(
                                                            Icons
                                                                .image_not_supported,
                                                            color: Colors.grey,
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.all(16),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        item['title'] ??
                                                            'Untitled',
                                                        style: TextStyle(
                                                          fontSize: 18,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: primaryText,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Text(
                                                        item['description'] ??
                                                            'No description',
                                                        maxLines: 3,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          color: secondaryText,
                                                          height: 1.5,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }),
                                    ],
                                  ),
                                )
                              else
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 80,
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.newspaper,
                                          size: 80,
                                          color: isDark
                                              ? Colors.white24
                                              : Colors.grey[300],
                                        ),
                                        const SizedBox(height: 20),
                                        Text(
                                          'No news found',
                                          style: TextStyle(
                                            fontSize: 18,
                                            color: secondaryText,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
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
