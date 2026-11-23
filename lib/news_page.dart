import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'content_cache_service.dart';
import 'news_detail_page.dart';
import 'news_link_text.dart';
import 'shared_widgets.dart';
import 'premium_bottom_navigation.dart';

class NewsPage extends StatefulWidget {
  final VoidCallback? onBack;
  final bool embedded;

  final ValueChanged<int>? onNavigate;
  final ValueChanged<bool>? onDrawerChanged;

  const NewsPage({
    super.key,
    this.onBack,
    this.onNavigate,
    this.onDrawerChanged,
    this.embedded = false,
  });

  @override
  State<NewsPage> createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  bool _isDrawerOpen = false;
  final supabase = Supabase.instance.client;
  final _cacheService = const ContentCacheService();

  List<Map<String, dynamic>> news = [];
  List<Map<String, dynamic>> filteredNews = [];
  String searchQuery = '';
  String? selectedCategory;
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
    if (index == 1) return;
    if (widget.onNavigate != null) {
      if (!widget.embedded) Navigator.of(context).pop();
      widget.onNavigate!(index);
    } else if (index == 0) {
      Navigator.of(context).pop();
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
          .select('id,title,description,category,image_url,image_urls,created_at')
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
    final normalizedQuery = query.trim().toLowerCase();
    if (selectedCategory != null &&
        !news.any((item) => _newsCategory(item) == selectedCategory)) {
      selectedCategory = null;
    }

    filteredNews = news.where((item) {
      final title = item['title']?.toString().toLowerCase() ?? '';
      final description = item['description']?.toString().toLowerCase() ?? '';
      final category = _newsCategory(item);

      return (selectedCategory == null || category == selectedCategory) &&
          (normalizedQuery.isEmpty ||
              title.contains(normalizedQuery) ||
              description.contains(normalizedQuery) ||
              category.toLowerCase().contains(normalizedQuery));
    }).toList();
  }

  String _newsCategory(Map<String, dynamic> item) {
    final category = item['category']?.toString().trim() ?? '';
    return category.isEmpty ? 'General' : category;
  }

  void searchNews(String query) {
    setState(() {
      searchQuery = query;
      _applySearch(query);
    });
  }

  void filterCategory(String? category) {
    setState(() {
      selectedCategory = category;
      _applySearch(searchQuery);
    });
  }

  Widget _buildCategoryMenu() {
    final categories = news.map(_newsCategory).toSet().toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    final hasFilter = selectedCategory != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopupMenuButton<String>(
      tooltip: 'Filter news by category',
      enabled: categories.isNotEmpty,
      position: PopupMenuPosition.under,
      offset: const Offset(0, 8),
      constraints: const BoxConstraints(minWidth: 195, maxWidth: 220),
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      elevation: 12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onSelected: (value) => filterCategory(value == '__all__' ? null : value),
      itemBuilder: (context) => [
        _categoryMenuItem('All categories', '__all__', !hasFilter),
        for (final category in categories)
          _categoryMenuItem(category, category, selectedCategory == category),
      ],
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E3A5F) : const Color(0xFFEAF4FF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFB8DCFF)),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(
              Icons.tune_rounded,
              color: Color(0xFF1683F8),
              size: 22,
            ),
            if (hasFilter)
              Positioned(
                top: 7,
                right: 7,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1683F8),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _categoryIcon(String label) {
    final category = label.toLowerCase();
    if (category.contains('announcement')) {
      return Icons.campaign_rounded;
    }
    if (category.contains('event')) {
      return Icons.calendar_month_rounded;
    }
    if (category.contains('update')) {
      return Icons.refresh_rounded;
    }
    if (category.contains('other')) {
      return Icons.description_rounded;
    }
    if (category == 'all categories') {
      return Icons.grid_view_rounded;
    }
    return Icons.local_offer_outlined;
  }

  Color _categoryColor(String label) {
    final category = label.toLowerCase();
    if (category.contains('announcement')) {
      return const Color(0xFFFF6B2C);
    }
    if (category.contains('update')) {
      return const Color(0xFF16B75D);
    }
    if (category.contains('other')) {
      return const Color(0xFF8B5CF6);
    }
    return const Color(0xFF1683F8);
  }

  PopupMenuItem<String> _categoryMenuItem(
    String label,
    String value,
    bool selected,
  ) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return PopupMenuItem<String>(
      value: value,
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: selected
              ? (isDark ? const Color(0xFF1E3A5F) : const Color(0xFFEAF4FF))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          children: [
            Icon(_categoryIcon(label), size: 17, color: _categoryColor(label)),
            const SizedBox(width: 11),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? const Color(0xFF0877E8) : colors.onSurface,
                ),
              ),
            ),
            if (selected)
              const Icon(
                Icons.check_circle_rounded,
                size: 17,
                color: Color(0xFF1683F8),
              ),
          ],
        ),
      ),
    );
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
      extendBody: true,
      onDrawerChanged: (isOpen) {
        setState(() => _isDrawerOpen = isOpen);
        widget.onDrawerChanged?.call(isOpen);
      },
      bottomNavigationBar: widget.embedded || widget.onNavigate == null
          ? null
          : NavigationVisibility(
              visible: !_isDrawerOpen,
              child: PremiumBottomNavigation(
                currentIndex: 1,
                onTap: _handleNavigation,
              ),
            ),
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
            bottom: false,
            child: Builder(
              builder: (context) => Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 12, 16, 8),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed:
                              widget.onBack ??
                              () => Navigator.of(context).pop(),
                          icon: const Icon(
                            Icons.arrow_back,
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
                        _buildCategoryMenu(),
                      ],
                    ),
                  ),
                  Expanded(
                    child: isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : SingleChildScrollView(
                            padding: EdgeInsets.only(
                              top: 6,
                              bottom:
                                  24 +
                                  MediaQuery.paddingOf(context).bottom +
                                  (widget.embedded ? 96 : 0),
                            ),
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
                                            itemCount: filteredNews.length
                                                .clamp(0, 3),
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
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
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
                                                        CrossAxisAlignment
                                                            .start,
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
                                                                    isDark:
                                                                        isDark,
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
                                                      NewsDetailPage(
                                                        news: item,
                                                      ),
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
                                                            top:
                                                                Radius.circular(
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
                                                    padding:
                                                        const EdgeInsets.all(
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
                                                        const SizedBox(
                                                          height: 8,
                                                        ),
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
                                                        const SizedBox(
                                                          height: 8,
                                                        ),
                                                        NewsLinkText(
                                                          item['description']
                                                                  ?.toString() ??
                                                              'No description',
                                                          maxLines: 3,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style: TextStyle(
                                                            fontSize: 14,
                                                            color:
                                                                secondaryText,
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
          ),
        ],
      ),
    );
  }
}
