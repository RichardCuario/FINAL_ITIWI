import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'content_cache_service.dart';
import 'news_detail_page.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ContentCacheService _cacheService = const ContentCacheService();

  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  bool _isShowingCachedData = false;
  DateTime? _cacheUpdatedAt;

  String? _buildNewsMarker(List<Map<String, dynamic>> items) {
    if (items.isEmpty) return null;

    final latest = items.first;
    final id = latest['id']?.toString() ?? '';
    final createdAt = latest['created_at']?.toString() ?? '';
    final updatedAt = latest['updated_at']?.toString() ?? '';

    return '$id|$createdAt|$updatedAt';
  }

  Future<List<Map<String, dynamic>>> _filterDismissedNotifications(
    List<Map<String, dynamic>> items,
  ) async {
    final latestMarker = _buildNewsMarker(items);
    if (latestMarker == null) {
      return items;
    }

    final dismissedMarker = await _cacheService.getDismissedNewsMarker();
    if (dismissedMarker == latestMarker) {
      return [];
    }

    return items;
  }

  Future<List<Map<String, dynamic>>> _buildCombinedNotifications(
    List<Map<String, dynamic>> newsItems,
  ) async {
    final visibleNews = await _filterDismissedNotifications(newsItems);
    final reportNotifications = await _cacheService.getReportNotifications();

    final combined = [
      ...reportNotifications,
      ...visibleNews.map(
        (item) => {
          ...item,
          'type': 'news',
        },
      ),
    ];

    combined.sort((a, b) {
      final aDate =
          DateTime.tryParse(a['created_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final bDate =
          DateTime.tryParse(b['created_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);

      return bDate.compareTo(aDate);
    });

    return combined;
  }

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final data = await _supabase
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
        await _cacheService.markNewsAsSeen(latestMarker);
      }

      final combinedNotifications = await _buildCombinedNotifications(mapped);

      if (!mounted) return;

      setState(() {
        _notifications = combinedNotifications;
        _isShowingCachedData = false;
        _cacheUpdatedAt = DateTime.now();
        _isLoading = false;
      });
    } catch (_) {
      final cached = await _cacheService.getNews();
      final latestMarker = _buildNewsMarker(cached.items);

      if (latestMarker != null) {
        await _cacheService.markNewsAsSeen(latestMarker);
      }

      final combinedNotifications = await _buildCombinedNotifications(
        cached.items,
      );

      if (!mounted) return;

      setState(() {
        _notifications = combinedNotifications;
        _isShowingCachedData = cached.hasData;
        _cacheUpdatedAt = cached.updatedAt;
        _isLoading = false;
      });
    }
  }

  String _formatDate(dynamic value) {
    final raw = value?.toString();
    if (raw == null || raw.isEmpty) return 'Recent update';

    final parsed = DateTime.tryParse(raw)?.toLocal();
    if (parsed == null) return 'Recent update';

    final month = parsed.month.toString().padLeft(2, '0');
    final day = parsed.day.toString().padLeft(2, '0');
    final year = parsed.year.toString();
    final hour = parsed.hour.toString().padLeft(2, '0');
    final minute = parsed.minute.toString().padLeft(2, '0');

    return '$month/$day/$year • $hour:$minute';
  }

  String _formatCacheUpdatedAt() {
    final value = _cacheUpdatedAt;
    if (value == null) {
      return 'previous session';
    }

    final local = value.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');

    return '$month/$day/${local.year} $hour:$minute';
  }

  void _openNewsDetail(Map<String, dynamic> item) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => NewsDetailPage(news: item)),
    );
  }

  Future<void> _clearAllNotifications() async {
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final isDark = Theme.of(dialogContext).brightness == Brightness.dark;

        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF172033) : Colors.white,
          title: const Text('Clear all notifications?'),
          content: const Text(
            'This will remove all notifications from the notification page.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Clear all'),
            ),
          ],
        );
      },
    );

    if (shouldClear != true) return;

    final currentMarker = _buildNewsMarker(_notifications);
    if (currentMarker != null) {
      await _cacheService.saveDismissedNewsMarker(currentMarker);
    }

    await _cacheService.clearNewsCache();
    await _cacheService.saveReportNotifications(const []);

    if (!mounted) return;

    setState(() {
      _notifications = [];
      _isShowingCachedData = false;
      _cacheUpdatedAt = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All notifications cleared.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final pageBackground =
        isDark ? const Color(0xFF0B1220) : const Color(0xFFEAEAEA);
    final cardBackground = isDark ? const Color(0xFF172033) : Colors.white;
    final mutedText =
        isDark ? Colors.white70 : const Color(0xFF667085);
    final primaryText =
        isDark ? Colors.white : const Color(0xFF111827);

    return Scaffold(
      backgroundColor: pageBackground,
      body: Stack(
        children: [
          Container(
            height: 185,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF1E88E5),
                  Color(0xFF90CAF9),
                  Color(0xFFEAEAEA),
                ],
                stops: [0.0, 0.62, 1.0],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 16, 8),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Expanded(
                        child: Text(
                          'Notifications',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (_notifications.isNotEmpty)
                        TextButton(
                          onPressed: _clearAllNotifications,
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                          ),
                          child: const Text(
                            'Clear all',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        )
                      else
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.notifications_active_rounded,
                            color: Colors.white,
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : RefreshIndicator(
                          onRefresh: _loadNotifications,
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                            children: [
                              if (_isShowingCachedData)
                                Container(
                                  margin: const EdgeInsets.only(bottom: 16),
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
                                          'Offline mode: showing cached notifications from ${_formatCacheUpdatedAt()}.',
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
                              Text(
                                'Recent updates',
                                style: TextStyle(
                                  color: primaryText,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Tap a notification to open the full announcement.',
                                style: TextStyle(
                                  color: mutedText,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (_notifications.isEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 28,
                                  ),
                                  decoration: BoxDecoration(
                                    color: cardBackground,
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.notifications_none_rounded,
                                        size: 62,
                                        color: isDark
                                            ? Colors.white24
                                            : Colors.grey.shade400,
                                      ),
                                      const SizedBox(height: 14),
                                      Text(
                                        'No notifications yet',
                                        style: TextStyle(
                                          color: primaryText,
                                          fontSize: 17,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'New municipal announcements will appear here.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: mutedText,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                ..._notifications.map((item) {
                                  final title =
                                      item['title']?.toString().trim().isNotEmpty ==
                                              true
                                          ? item['title'].toString().trim()
                                          : 'Untitled notification';
                                  final description =
                                      item['description']
                                                  ?.toString()
                                                  .trim()
                                                  .isNotEmpty ==
                                              true
                                          ? item['description']
                                              .toString()
                                              .trim()
                                          : 'Tap to view the latest update.';
                                  final imageUrl = item['image_url']?.toString();
                                  final type =
                                      item['type']?.toString() ?? 'news';
                                  final isReportStatus =
                                      type == 'report_status';
                                  final isOnlineServiceStatus =
                                      type == 'online_service_status';
                                  final isActionableNews =
                                      !isReportStatus && !isOnlineServiceStatus;

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 14),
                                    decoration: BoxDecoration(
                                      color: cardBackground,
                                      borderRadius: BorderRadius.circular(18),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: isDark ? 0.22 : 0.08,
                                          ),
                                          blurRadius: 10,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(18),
                                      onTap: isActionableNews
                                          ? () => _openNewsDetail(item)
                                          : null,
                                      child: Padding(
                                        padding: const EdgeInsets.all(14),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              width: 52,
                                              height: 52,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFE3F2FD),
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                              clipBehavior: Clip.antiAlias,
                                              child: imageUrl != null &&
                                                      imageUrl.isNotEmpty
                                                  ? Image.network(
                                                      imageUrl,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (
                                                        context,
                                                        error,
                                                        stackTrace,
                                                      ) {
                                                        return Icon(
                                                          isReportStatus
                                                              ? Icons
                                                                    .assignment_turned_in_rounded
                                                              : isOnlineServiceStatus
                                                              ? Icons
                                                                    .description_rounded
                                                              : Icons
                                                                    .campaign_rounded,
                                                          color: const Color(
                                                            0xFF1E88E5,
                                                          ),
                                                        );
                                                      },
                                                    )
                                                  : Icon(
                                                      isReportStatus
                                                          ? Icons
                                                                .assignment_turned_in_rounded
                                                          : isOnlineServiceStatus
                                                          ? Icons
                                                                .description_rounded
                                                          : Icons
                                                                .campaign_rounded,
                                                      color: const Color(
                                                        0xFF1E88E5,
                                                      ),
                                                    ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    title,
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      color: primaryText,
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Text(
                                                    description,
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      color: mutedText,
                                                      fontSize: 13,
                                                      height: 1.35,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 10),
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons.access_time_rounded,
                                                        size: 15,
                                                        color: mutedText,
                                                      ),
                                                      const SizedBox(width: 5),
                                                      Expanded(
                                                        child: Text(
                                                          _formatDate(
                                                            item['created_at'],
                                                          ),
                                                          style: TextStyle(
                                                            color: mutedText,
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                        ),
                                                      ),
                                                      if (isActionableNews)
                                                        const Icon(
                                                          Icons
                                                              .chevron_right_rounded,
                                                          color: Color(
                                                            0xFF1E88E5,
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
