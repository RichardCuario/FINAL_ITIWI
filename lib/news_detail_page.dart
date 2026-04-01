import 'package:flutter/material.dart';

class NewsDetailPage extends StatelessWidget {
  final Map<String, dynamic> news;

  const NewsDetailPage({super.key, required this.news});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final scaffoldBackground =
        isDark ? theme.scaffoldBackgroundColor : Colors.white;
    final contentBackground = isDark ? const Color(0xFF111827) : Colors.white;
    final titleColor = isDark ? Colors.white : Colors.black87;
    final metaColor = isDark ? Colors.white60 : Colors.grey[600]!;
    final iconMetaColor = isDark ? Colors.white54 : Colors.grey[500]!;
    final dividerColor = isDark ? Colors.white12 : Colors.grey[300]!;
    final bodyColor = isDark ? Colors.white70 : Colors.grey[700]!;
    final imagePlaceholder =
        isDark ? const Color(0xFF1F2937) : Colors.grey[200]!;
    final imageErrorBackground =
        isDark ? const Color(0xFF243145) : Colors.grey[300]!;
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
      backgroundColor: scaffoldBackground,
      body: Stack(
        children: [
          Container(
            height: 110,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: topGradient,
                stops: const [0.0, 0.7, 1.0],
              ),
            ),
          ),
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 0,
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: news['image_url'] != null
                    ? Image.network(
                        news['image_url'],
                        height: 300,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 300,
                            color: imageErrorBackground,
                            child: const Icon(
                              Icons.image_not_supported,
                              color: Colors.grey,
                              size: 60,
                            ),
                          );
                        },
                      )
                    : Container(
                        height: 300,
                        color: imagePlaceholder,
                        child: Icon(
                          Icons.image_not_supported,
                          color: Colors.grey[400],
                          size: 60,
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
                              style: TextStyle(
                                fontSize: 14,
                                color: metaColor,
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 20),
                      Container(
                        height: 1,
                        color: dividerColor,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        news['description'] ?? 'No description available',
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
