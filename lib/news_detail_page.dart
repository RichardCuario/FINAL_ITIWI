import 'package:flutter/material.dart';

import 'auto_image_carousel.dart';
import 'news_link_text.dart';
import 'shared_widgets.dart';

class NewsDetailPage extends StatelessWidget {
  final Map<String, dynamic> news;

  const NewsDetailPage({super.key, required this.news});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final scaffoldBackground = isDark
        ? theme.scaffoldBackgroundColor
        : Colors.white;
    final contentBackground = isDark ? const Color(0xFF111827) : Colors.white;
    final titleColor = isDark ? Colors.white : Colors.black87;
    final metaColor = isDark ? Colors.white60 : Colors.grey[600]!;
    final iconMetaColor = isDark ? Colors.white54 : Colors.grey[500]!;
    final dividerColor = isDark ? Colors.white12 : Colors.grey[300]!;
    final bodyColor = isDark ? Colors.white70 : Colors.grey[700]!;
    final imageErrorBackground = isDark
        ? const Color(0xFF243145)
        : Colors.grey[300]!;
    final category = news['category']?.toString().trim().isNotEmpty == true
        ? news['category'].toString()
        : 'General';
    final imageUrl = news['image_url']?.toString().trim() ?? '';
    final gallery = news['image_urls'] is List
        ? (news['image_urls'] as List)
            .map((value) => value?.toString().trim() ?? '')
            .where((value) => value.isNotEmpty)
            .take(5)
            .toList()
        : <String>[];
    if (gallery.isEmpty && imageUrl.isNotEmpty) gallery.add(imageUrl);

    Widget imageFallback(Color background) =>
        ColoredBox(
          color: background,
          child: Center(
            child: Icon(
              Icons.image_not_supported,
              color: Colors.grey[400],
              size: 60,
            ),
          ),
        );

    return Scaffold(
      backgroundColor: scaffoldBackground,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: AspectRatio(
                  aspectRatio: 16 / 10,
                  child: AutoImageCarousel(
                    urls: gallery,
                    placeholder: imageFallback(imageErrorBackground),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  color: contentBackground,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        news['title'] ?? 'Untitled',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: titleColor,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E293B)
                              : const Color(0xFFE8F3FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          category,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? Colors.lightBlue[100]
                                : AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (news['created_at'] != null)
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: iconMetaColor,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatDate(news['created_at']),
                              style: TextStyle(fontSize: 14, color: metaColor),
                            ),
                          ],
                        ),
                      const SizedBox(height: 20),
                      Container(height: 1, color: dividerColor),
                      const SizedBox(height: 20),
                      NewsLinkText(
                        news['description']?.toString() ??
                            'No description available',
                        style: TextStyle(
                          fontSize: 16,
                          color: bodyColor,
                          height: 1.8,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 8,
            left: 12,
            child: Material(
              color: Colors.black45,
              borderRadius: BorderRadius.circular(8),
              child: IconButton(
                tooltip: 'Back',
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}
