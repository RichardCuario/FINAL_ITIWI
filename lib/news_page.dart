import 'dart:async';
import 'dart:io';

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
  int currentIndex = 1;

  bool _isNetworkError(Object error) {
    return error is SocketException ||
        error is HttpException ||
        error is HandshakeException ||
        error is TimeoutException ||
        error.toString().contains('SocketException') ||
        error.toString().contains('Failed host lookup');
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
    unawaited(_loadCachedNewsThenRefresh());
  }

  Future<void> _loadCachedNewsThenRefresh() async {
    final cached = await _cacheService.getNews();

    if (!mounted) return;

    if (cached.hasData) {
      setState(() {
        news = cached.items;
        isShowingCachedData = true;
        cacheUpdatedAt = cached.updatedAt;
        isLoading = false;
        _applySearch(searchQuery);
      });
    }

    unawaited(fetchNews(showLoading: !cached.hasData));
  }

  Future<void> _publishScheduledNews() async {
    try {
      await supabase.rpc('publish_scheduled_news');
    } catch (error) {
      // The function may not be installed in every deployment.
      debugPrint('Could not call publish_scheduled_news: $error');
    }
  }

  Future<void> fetchNews({bool showLoading = true}) async {
    if (showLoading && mounted) {
      setState(() {
        isLoading = true;
      });
    }

    try {
      // Cached news is already visible on repeat visits, so wait for due
      // scheduled articles to be published before reading the fresh list.
      await _publishScheduledNews();

      final data = await supabase
          .from('news')
          .select(
            'id,title,description,category,image_url,created_at',
          )
          .eq('is_published', true)
          .order('created_at', ascending: false);

      final mapped = List<Map<String, dynamic>>.from(
        (data as List).map((item) => Map<String, dynamic>.from(item as Map)),
      );

      if (!mounted) return;

      setState(() {
        news = mapped;
        isShowingCachedData = false;
        cacheUpdatedAt = DateTime.now();
        isLoading = false;
        _applySearch(searchQuery);
      });

      // Persist fresh news after it is visible to the user.
      unawaited(_cacheService.saveNews(mapped));
    } catch (e) {
      final cached = await _cacheService.getNews();

      if (!mounted) return;

      setState(() {
        news = cached.items;
        isShowingCachedData = cached.hasData;
        cacheUpdatedAt = cached.updatedAt;
        isLoading = false;
        _applySearch(searchQuery);
      });

      if (!mounted) return;

      if (cached.hasData && showLoading) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No Internet Connection')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isNetworkError(e)
                  ? 'No Internet Connection'
                  : 'Unable to load news: $e',
            ),
          ),
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
      final category = item['category']?.toString().toLowerCase() ?? '';

      return title.contains(normalizedQuery) ||
          description.contains(normalizedQuery) ||
          category.contains(normalizedQuery);
    }).toList();
  }

  void searchNews(String query) {
    setState(() {
      searchQuery = query;
      _applySearch(query);
    });
  }

  Widget _newsImagePlaceholder({required double height, required bool isDark}) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF1E3A5F), Color(0xFF172033)]
              : const [Color(0xFFE0F2FE), Color(0xFFBFDBFE)],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Center(
        child: Icon(
          Icons.newspaper_rounded,
          size: height <= 100 ? 34 : 56,
          color: isDark
              ? const Color(0xFF93C5FD)
              : const Color(0xFF3B82F6).withValues(alpha: 0.7),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final pageBackground = isDark
        ? const Color(0xFF0B1220)
        : const Color(0xFFEAEAEA);
    final inputBackground = isDark
        ? const Color(0xFF0F172A)
        : AppColors.background;
    final cardBackground = theme.cardColor;
    final primaryText =
        theme.textTheme.bodyLarge?.color ?? colorScheme.onSurface;
    final secondaryText =
        theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.72) ??
        colorScheme.onSurface.withValues(alpha: 0.72);
    final topGradient = isDark
        ? const [Color(0xFF0F172A), Color(0xFF172554), Color(0xFF111827)]
        : const [Color(0xFF1E88E5), Color(0xFF90CAF9), Color(0xFFEAEAEA)];

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
                              if (isShowingCachedData)
                                const Padding(
                                  padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                                  child: OfflineDataBanner(),
                                ),
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
                                          itemCount: filteredNews.length.clamp(
                                            0,
                                            3,
                                          ),
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
                                                          errorBuilder:
                                                              (
                                                                context,
                                                                error,
                                                                stackTrace,
                                                              ) {
                                                                return _newsImagePlaceholder(
                                                                  height: 100,
                                                                  isDark: isDark,
                                                                );
                                                              },
                                                        ),
                                                      )
                                                    else
                                                      _newsImagePlaceholder(
                                                        height: 100,
                                                        isDark: isDark,
                                                      ),
                                                    Expanded(
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets.all(
                                                              10,
                                                            ),
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(
                                                              item['category'] ??
                                                                  'General',
                                                              maxLines: 1,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              style: TextStyle(
                                                                fontSize: 11,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                color: isDark
                                                                    ? Colors
                                                                          .lightBlue[100]
                                                                    : AppColors
                                                                          .primary,
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                              height: 6,
                                                            ),
                                                            Text(
                                                              item['title'] ??
                                                                  'Untitled',
                                                              maxLines: 2,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              style: TextStyle(
                                                                fontSize: 12,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color:
                                                                    primaryText,
                                                              ),
                                                            ),
                                                          ],
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
                                                      errorBuilder:
                                                          (
                                                            context,
                                                            error,
                                                            stackTrace,
                                                          ) {
                                                            return _newsImagePlaceholder(
                                                              height: 200,
                                                              isDark: isDark,
                                                            );
                                                          },
                                                    ),
                                                  ),
                                                Padding(
                                                  padding: const EdgeInsets.all(
                                                    16,
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        item['category'] ??
                                                            'General',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: isDark
                                                              ? Colors
                                                                    .lightBlue[100]
                                                              : AppColors
                                                                    .primary,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 8),
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
