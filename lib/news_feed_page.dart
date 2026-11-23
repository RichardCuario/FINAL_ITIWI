import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'content_cache_service.dart';
import 'news_link_text.dart';
import 'news_category_filter.dart';
import 'shared_widgets.dart';
import 'premium_bottom_navigation.dart';

class NewsFeedPage extends StatefulWidget {
  const NewsFeedPage({super.key});

  @override
  State<NewsFeedPage> createState() => _NewsFeedPageState();
}

class _NewsFeedPageState extends State<NewsFeedPage> {
  bool _isDrawerOpen = false;
  final supabase = Supabase.instance.client;
  final _cacheService = const ContentCacheService();

  List<Map<String, dynamic>> news = [];
  bool isLoading = true;
  String searchQuery = '';
  String? selectedCategory;
  List<Map<String, dynamic>> filteredNews = [];
  bool isShowingCachedData = false;
  DateTime? cacheUpdatedAt;

  @override
  void initState() {
    super.initState();
    fetchNews();
  }

  Future<void> fetchNews() async {
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

    try {
      // Publish any scheduled news that's due
      try {
        await supabase.rpc('publish_scheduled_news');
      } catch (e) {
        // Function may not exist, continue anyway
        debugPrint('Could not call publish_scheduled_news: $e');
      }

      final data = await supabase
          .from('news')
          .select()
          .eq('is_published', true)
          .order('created_at', ascending: false);

      final mapped = List<Map<String, dynamic>>.from(
        (data as List).map((item) => Map<String, dynamic>.from(item as Map)),
      );

      await _cacheService.saveNews(mapped);

      if (!mounted) return;

      setState(() {
        news = mapped;
        isShowingCachedData = false;
        cacheUpdatedAt = DateTime.now();
        isLoading = false;
      });

      _applySearch(searchQuery);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      onDrawerChanged: (isOpen) => setState(() => _isDrawerOpen = isOpen),
      drawer: AdminSidebar(
        userName: 'Admin User',
        userEmail: 'admin@example.com',
        currentIndex: 1,
        onNavigationChanged: (index) {
          Navigator.pop(context);
          if (index == 0) Navigator.popUntil(context, (route) => route.isFirst);
        },
      ),
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text(
          'News Feed',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: fetchNews,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Search Bar Section
                    Container(
                      color: AppColors.cardBackground,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: TextField(
                          onChanged: searchNews,
                          decoration: InputDecoration(
                            hintText: 'Search articles',
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            border: InputBorder.none,
                            prefixIcon: Icon(
                              Icons.search,
                              color: Colors.grey[400],
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 15,
                            ),
                          ),
                        ),
                      ),
                    ),

                    if (news.isNotEmpty)
                      NewsCategoryFilter(
                        items: news,
                        selectedCategory: selectedCategory,
                        resultCount: filteredNews.length,
                        onChanged: filterCategory,
                      ),

                    if (filteredNews.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 80),
                        child: Column(
                          children: [
                            Icon(
                              Icons.newspaper,
                              size: 80,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'No articles found',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Carousel Section
                            if (filteredNews.isNotEmpty)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Featured',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    height: 180,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: filteredNews.length.clamp(
                                        0,
                                        5,
                                      ),
                                      itemBuilder: (context, index) {
                                        final item = filteredNews[index];

                                        return Container(
                                          width: 140,
                                          margin: const EdgeInsets.only(
                                            right: 12,
                                          ),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            color: Colors.grey[200],
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(
                                                  alpha: 0.1,
                                                ),
                                                blurRadius: 6,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Stack(
                                            fit: StackFit.expand,
                                            children: [
                                              ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                child: Image.network(
                                                  item['image_url'] ?? '',
                                                  fit: BoxFit.cover,
                                                  errorBuilder:
                                                      (
                                                        context,
                                                        error,
                                                        stackTrace,
                                                      ) {
                                                        return Container(
                                                          color:
                                                              Colors.grey[300],
                                                          child: const Icon(
                                                            Icons
                                                                .image_not_supported,
                                                            color: Colors.grey,
                                                          ),
                                                        );
                                                      },
                                                ),
                                              ),
                                              Container(
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      Colors.transparent,
                                                      Colors.black.withValues(
                                                        alpha: 0.7,
                                                      ),
                                                    ],
                                                    begin: Alignment.topCenter,
                                                    end: Alignment.bottomCenter,
                                                  ),
                                                ),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.all(
                                                  12,
                                                ),
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.end,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      item['title'] ??
                                                          'Article',
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 30),
                                ],
                              ),

                            // Articles List
                            const Text(
                              'All Articles',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...filteredNews.map((item) {
                              return Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.08,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // IMAGE
                                    ClipRRect(
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(12),
                                      ),
                                      child: Image.network(
                                        item['image_url'] ?? '',
                                        height: 180,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                              return Container(
                                                height: 180,
                                                color: Colors.grey[300],
                                                child: const Icon(
                                                  Icons.image_not_supported,
                                                  color: Colors.grey,
                                                ),
                                              );
                                            },
                                      ),
                                    ),

                                    // CONTENT
                                    Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // DATE
                                          if (item['created_at'] != null)
                                            Text(
                                              item['created_at']
                                                  .toString()
                                                  .substring(0, 10),
                                              style: const TextStyle(
                                                color: AppColors.primary,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),

                                          const SizedBox(height: 6),

                                          // TITLE
                                          Text(
                                            item['title'] ?? '',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 6),

                                          // DESCRIPTION
                                          NewsLinkText(
                                            item['description']?.toString() ??
                                                '',
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[600],
                                              height: 1.4,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

      /// BOTTOM NAV
      bottomNavigationBar: NavigationVisibility(
        visible: !_isDrawerOpen,
        child: PremiumBottomNavigation(
          currentIndex: 1,
          onTap: (index) {
            Navigator.pop(context); // close drawer if open
            Navigator.popUntil(context, (route) => route.isFirst);
          },
        ),
      ),
    );
  }
}
