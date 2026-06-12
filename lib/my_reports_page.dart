import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'content_cache_service.dart';
import 'shared_widgets.dart';

class MyReportsPage extends StatefulWidget {
  final VoidCallback? onBack;

  const MyReportsPage({super.key, this.onBack});

  @override
  State<MyReportsPage> createState() => _MyReportsPageState();
}

class _MyReportsPageState extends State<MyReportsPage> {
  final _supabase = Supabase.instance.client;
  final _cacheService = const ContentCacheService();
  late Future<List<Map<String, dynamic>>> _reportsFuture;
  List<Map<String, dynamic>> _reports = const [];
  bool _isMutatingReport = false;

  firebase_auth.User? get _currentUser =>
      firebase_auth.FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _reportsFuture = _loadReports();
  }

  void _refreshReports() {
    setState(() {
      _reportsFuture = _loadReports();
    });
  }

  void _removeReportFromList(String reportId) {
    setState(() {
      _reports = _reports
          .where((report) => report['id']?.toString() != reportId)
          .toList();
      _reportsFuture = Future.value(_reports);
    });
  }

  String _normalizeReportStatus(String status) {
    final normalized = status.trim().toLowerCase();

    switch (normalized) {
      case 'reviewing':
      case 'processing':
      case 'in progress':
        return 'under review';
      case 'under review':
        return 'under review';
      case 'pending':
        return 'pending';
      case 'approved':
      case 'resolved':
        return 'approved';
      case 'rejected':
        return 'rejected';
      default:
        return normalized.isEmpty ? 'pending' : normalized;
    }
  }

  String _buildReportNotificationTitle(String status) {
    switch (_normalizeReportStatus(status)) {
      case 'approved':
        return 'Your report was approved';
      case 'rejected':
        return 'Your report was rejected';
      default:
        return 'Your report is under review';
    }
  }

  String _buildReportNotificationDescription(Map<String, dynamic> report) {
    final status = report['status']?.toString() ?? '';
    final normalizedStatus = _normalizeReportStatus(status);
    final message = report['message']?.toString().trim() ?? '';
    final trimmedMessage = message.isEmpty ? 'your submitted report' : message;

    if (normalizedStatus == 'rejected') {
      final reason = report['rejection_reason']?.toString().trim() ?? '';
      if (reason.isNotEmpty) {
        return 'Admin updated "$trimmedMessage" to rejected. Reason: $reason';
      }
      return 'Admin updated "$trimmedMessage" to rejected.';
    }

    if (normalizedStatus == 'approved') {
      return 'Admin approved "$trimmedMessage".';
    }

    return 'Admin updated "$trimmedMessage" to under review.';
  }

  Future<void> _syncReportStatusNotifications(
    List<Map<String, dynamic>> reports,
  ) async {
    final previousSnapshot = await _cacheService.getReportStatusSnapshot();
    final existingNotifications = await _cacheService.getReportNotifications();
    final updatedNotifications = List<Map<String, dynamic>>.from(
      existingNotifications,
    );

    final nextSnapshot = <String, dynamic>{};

    for (final report in reports) {
      final reportId = report['id']?.toString();
      if (reportId == null || reportId.isEmpty) {
        continue;
      }

      final status = report['status']?.toString() ?? '';
      final updatedAt = report['updated_at']?.toString() ?? '';
      final normalizedStatus = _normalizeReportStatus(status);

      nextSnapshot[reportId] = {
        'status': normalizedStatus,
        'updated_at': updatedAt,
      };

      final previous = previousSnapshot[reportId];
      if (previous is! Map) {
        continue;
      }

      final previousStatus = previous['status']?.toString() ?? '';
      final previousUpdatedAt = previous['updated_at']?.toString() ?? '';

      final didChange =
          previousStatus != normalizedStatus || previousUpdatedAt != updatedAt;

      if (!didChange) {
        continue;
      }

      updatedNotifications.removeWhere(
        (item) => item['id']?.toString() == 'report_$reportId',
      );

      updatedNotifications.insert(0, {
        'id': 'report_$reportId',
        'type': 'report_status',
        'title': _buildReportNotificationTitle(status),
        'description': _buildReportNotificationDescription(report),
        'created_at': updatedAt.isNotEmpty
            ? updatedAt
            : DateTime.now().toIso8601String(),
        'report_id': reportId,
        'report_status': normalizedStatus,
        'rejection_reason': report['rejection_reason'],
      });
    }

    await _cacheService.saveReportStatusSnapshot(nextSnapshot);
    await _cacheService.saveReportNotifications(updatedNotifications);
  }

  Future<List<Map<String, dynamic>>> _loadReports() async {
    final user = _currentUser;
    if (user == null) {
      return [];
    }

    try {
      final response = await _supabase
          .from('reports')
          .select(
            'id, message, image_urls, status, rejection_reason, created_at, updated_at, user_id',
          )
          .eq('user_id', user.uid)
          .order('created_at', ascending: false);

      final reports = (response as List)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();

      await _fetchUserDisplayNames(reports);
      await _syncReportStatusNotifications(reports);
      _reports = reports;

      return reports;
    } on PostgrestException catch (error) {
      final detailsText = error.details?.toString() ?? '';
      if (!(error.message.contains('rejection_reason') ||
          detailsText.contains('rejection_reason'))) {
        rethrow;
      }

      final fallbackResponse = await _supabase
          .from('reports')
          .select('id, message, image_urls, status, created_at, updated_at, user_id')
          .eq('user_id', user.uid)
          .order('created_at', ascending: false);

      final reports = (fallbackResponse as List)
          .map(
            (item) => {
              ...Map<String, dynamic>.from(item as Map),
              'rejection_reason': null,
            },
          )
          .toList();

      await _fetchUserDisplayNames(reports);
      await _syncReportStatusNotifications(reports);
      _reports = reports;

      return reports;
    }
  }

  Future<void> _fetchUserDisplayNames(List<Map<String, dynamic>> reports) async {
    final userIds = <String>{};
    for (final report in reports) {
      final userId = report['user_id']?.toString();
      if (userId != null && userId.isNotEmpty) {
        userIds.add(userId);
      }
    }

    if (userIds.isEmpty) return;

    try {
      final userResponse = await _supabase
          .from('users')
          .select('id, display_name, email')
          .inFilter('id', userIds.toList());

      final userMap = <String, String>{};
      for (final user in userResponse as List) {
        final id = user['id']?.toString();
        final displayName = user['display_name']?.toString();
        final email = user['email']?.toString();
        if (id != null) {
          // Use display_name if available, otherwise use email
          userMap[id] = (displayName != null && displayName.isNotEmpty) ? displayName : (email ?? 'Anonymous');
        }
      }

      for (final report in reports) {
        final userId = report['user_id']?.toString();
        if (userId != null && userMap.containsKey(userId)) {
          report['reporter_name'] = userMap[userId];
        }
      }
    } catch (e) {
      if (kDebugMode) print('Error fetching user display names: $e');
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'resolved':
        return const Color(0xFF16A34A);
      case 'reviewing':
      case 'processing':
      case 'in progress':
      case 'under review':
        return const Color(0xFFF59E0B);
      case 'pending':
        return const Color(0xFF3B82F6);
      case 'rejected':
        return const Color(0xFFDC2626);
      default:
        return AppColors.primary;
    }
  }

  String _statusLabel(String status) {
    final normalized = status.trim().toLowerCase();

    switch (normalized) {
      case 'pending':
        return 'Pending';
      case 'reviewing':
      case 'processing':
      case 'in progress':
      case 'under review':
        return 'Under review';
      case 'approved':
      case 'resolved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      default:
        if (status.isEmpty) return 'Pending';
        return status[0].toUpperCase() + status.substring(1);
    }
  }

  List<_ReportTimelineStep> _buildTimelineSteps(Map<String, dynamic> report) {
    final status = (report['status']?.toString() ?? '').trim().toLowerCase();
    final createdAt = report['created_at']?.toString();
    final updatedAt = report['updated_at']?.toString();

    final reviewReached = status != 'pending';
    final resolvedReached = status == 'approved' || status == 'resolved' || status == 'rejected';

    return [
      _ReportTimelineStep(
        title: status == 'rejected' ? 'Rejected' : 'Approved',
        description: status == 'rejected'
            ? 'Your report was reviewed and rejected by the hotline team. See the reason below.'
            : 'Your report was approved',
        date: resolvedReached ? updatedAt : null,
        isReached: resolvedReached,
        isDone: status == 'approved' || status == 'resolved',
      ),
      _ReportTimelineStep(
        title: 'Under review',
        description: 'Your report is under review',
        date: reviewReached ? createdAt : null,
        isReached: reviewReached,
        isDone: resolvedReached,
      ),
      _ReportTimelineStep(
        title: 'Pending',
        description: 'Your report has been submitted',
        date: createdAt,
        isReached: true,
        isDone: reviewReached,
      ),
    ];
  }

  String _formatDate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Unknown date';
    }

    final parsed = DateTime.tryParse(value)?.toLocal();
    if (parsed == null) {
      return value;
    }

    final monthNames = const [
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

    final month = monthNames[parsed.month - 1];
    final hour = parsed.hour == 0
        ? 12
        : parsed.hour > 12
            ? parsed.hour - 12
            : parsed.hour;
    final minute = parsed.minute.toString().padLeft(2, '0');
    final period = parsed.hour >= 12 ? 'PM' : 'AM';

    return '$month ${parsed.day}, ${parsed.year} • $hour:$minute $period';
  }

  String _formatTimelineDate(String? value) {
    final formatted = _formatDate(value);
    if (formatted == 'Unknown date') {
      return formatted;
    }

    final withoutYear = formatted.replaceFirst(', ${DateTime.now().year}', '');
    return withoutYear.replaceFirst(' • ', '\n');
  }

  bool _canManageReport(String status) {
    final normalized = _normalizeReportStatus(status);
    return normalized != 'approved' && normalized != 'rejected';
  }

  Future<void> _editReport(Map<String, dynamic> report) async {
    final user = _currentUser;
    if (user == null || _isMutatingReport) {
      return;
    }

    final controller = TextEditingController(
      text: report['message']?.toString().trim() ?? '',
    );
    final formKey = GlobalKey<FormState>();
    final reportId = report['id']?.toString();

    String? draftMessage;
    final didSubmit = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        final isDark = theme.brightness == Brightness.dark;
        final titleColor = isDark ? Colors.white : const Color(0xFF111827);
        final subtitleColor = isDark ? Colors.white70 : const Color(0xFF64748B);
        final fillColor =
            isDark ? const Color(0xFF111827) : const Color(0xFFF8FAFC);
        final borderColor = isDark
            ? Colors.white.withValues(alpha: 0.10)
            : const Color(0xFFD6DCE5);

        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF172033) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: Text(
            'Edit report',
            style: TextStyle(
              color: titleColor,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              maxLines: 6,
              minLines: 5,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your report message.';
                }
                if (value.trim().length < 10) {
                  return 'Please provide a little more detail.';
                }
                return null;
              },
              style: TextStyle(color: titleColor, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Update your report details here...',
                hintStyle: TextStyle(color: subtitleColor, fontSize: 13),
                filled: true,
                fillColor: fillColor,
                contentPadding: const EdgeInsets.all(16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 1.4,
                  ),
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) {
                  return;
                }
                draftMessage = controller.text.trim();
                Navigator.of(dialogContext).pop(true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Save',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );

    await Future<void>.delayed(const Duration(milliseconds: 10));
    final updatedMessage = draftMessage;

    controller.dispose();

    if (!mounted ||
        didSubmit != true ||
        updatedMessage == null ||
        updatedMessage == (report['message']?.toString().trim() ?? '') ||
        reportId == null) {
      return;
    }

    setState(() {
      _isMutatingReport = true;
    });

    try {
      await _supabase
          .from('reports')
          .update({'message': updatedMessage})
          .eq('id', reportId)
          .eq('user_id', user.uid);

      if (!mounted) return;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report updated successfully.')),
        );
        _refreshReports();
      });
    } catch (e) {
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to update report: $e')),
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _isMutatingReport = false;
        });
      }
    }
  }

  Future<void> _deleteReport(Map<String, dynamic> report) async {
    final user = _currentUser;
    if (user == null || _isMutatingReport) {
      return;
    }

    final reportId = report['id']?.toString();
    final message = report['message']?.toString().trim() ?? 'this report';

    if (reportId == null) {
      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Delete report?',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Text(
          'This will permanently remove "$message" from your submitted reports.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Delete',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (shouldDelete != true || !mounted) {
      return;
    }

    setState(() {
      _isMutatingReport = true;
    });

    try {
      final deletedRows = await _supabase
          .from('reports')
          .delete()
          .eq('id', reportId)
          .eq('user_id', user.uid)
          .select('id');

      if ((deletedRows as List).isEmpty) {
        throw Exception(
          'Delete was not allowed by the database. Add a delete policy for reports in Supabase.',
        );
      }

      final imageUrls = (report['image_urls'] as List?) ?? const [];
      for (final imageUrl in imageUrls) {
        final url = imageUrl?.toString() ?? '';
        final marker = '/object/public/report-images/';
        final markerIndex = url.indexOf(marker);
        if (markerIndex == -1) {
          continue;
        }
        final path = url.substring(markerIndex + marker.length);
        if (path.isEmpty) {
          continue;
        }
        await _supabase.storage.from('report-images').remove([path]);
      }

      if (!mounted) return;

      _removeReportFromList(reportId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report deleted successfully.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to delete report: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isMutatingReport = false;
        });
      }
    }
  }

  void _showRejectionReasonDialog(String rejectionReason) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final reasonText = rejectionReason.trim().isEmpty
        ? 'The rejection reason is not available yet.'
        : rejectionReason.trim();

    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? const [Color(0xFF172033), Color(0xFF111827)]
                  : const [Color(0xFFF8FBFF), Color(0xFFFFFFFF)],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.32 : 0.14),
                blurRadius: 28,
                offset: const Offset(0, 16),
              ),
            ],
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : const Color(0xFFD9E7FF),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFDC2626).withValues(
                          alpha: isDark ? 0.22 : 0.12,
                        ),
                      ),
                      child: const Icon(
                        Icons.gpp_bad_rounded,
                        color: Color(0xFFDC2626),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'Why your report was rejected',
                        style: TextStyle(
                          color: isDark ? Colors.white : const Color(0xFF111827),
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'This decision was provided by the admin team based on their review of your submission.',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : const Color(0xFF64748B),
                    fontSize: 13.5,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0F172A)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB).withValues(
                            alpha: isDark ? 0.22 : 0.10,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.info_outline_rounded,
                          size: 18,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          reasonText,
                          style: TextStyle(
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF1E293B),
                            fontSize: 15.5,
                            fontWeight: FontWeight.w600,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Got it',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
        isDark ? const Color(0xFF243145) : const Color(0xFFE5E5E5);
    final titleColor = isDark ? Colors.white : Colors.black;
    final subtitleColor = isDark ? Colors.white70 : Colors.black54;
    final borderColor = isDark ? Colors.white10 : const Color(0xFFD6DCE5);
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
            height: 240,
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
                  padding: const EdgeInsets.fromLTRB(10, 12, 18, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed:
                            widget.onBack ?? () => Navigator.of(context).maybePop(),
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Expanded(
                        child: Text(
                          'My Reports',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: _reportsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'Unable to load your reports.',
                              style: TextStyle(
                                color: titleColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }

                      final reports = snapshot.data ?? _reports;

                      if (_currentUser == null) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'Please sign in to view your reports.',
                              style: TextStyle(
                                color: titleColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }

                      return RefreshIndicator(
                        onRefresh: () async {
                          _refreshReports();
                          await _reportsFuture;
                        },
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                          children: [
                            Container(
                              width: double.infinity,
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
                                      Icons.fact_check_outlined,
                                      color: AppColors.primary,
                                      size: 26,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Track your submitted reports',
                                          style: TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w700,
                                            color: titleColor,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'View the status of every report you submitted and check when it was last updated.',
                                          style: TextStyle(
                                            fontSize: 12.8,
                                            height: 1.45,
                                            color: subtitleColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (reports.isEmpty)
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: surfaceColor,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: borderColor),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.inbox_outlined,
                                      size: 44,
                                      color: subtitleColor,
                                    ),
                                    const SizedBox(height: 14),
                                    Text(
                                      'No reports yet',
                                      style: TextStyle(
                                        color: titleColor,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Once you submit a report, it will appear here together with its current status.',
                                      style: TextStyle(
                                        color: subtitleColor,
                                        fontSize: 13,
                                        height: 1.45,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              )
                            else
                              ...reports.map((report) {
                                final message =
                                    report['message']?.toString().trim().isNotEmpty ==
                                            true
                                        ? report['message'].toString().trim()
                                        : 'No message provided';
                                final status =
                                    report['status']?.toString().trim() ?? 'pending';
                                final createdAt =
                                    _formatDate(report['created_at']?.toString());
                                final updatedAt =
                                    _formatDate(report['updated_at']?.toString());
                                final imageUrls =
                                    (report['image_urls'] as List?) ?? const [];
                                final timelineSteps = _buildTimelineSteps(report);
                                final rejectionReason =
                                    report['rejection_reason']
                                            ?.toString()
                                            .trim() ??
                                        '';
                                final canManageReport = _canManageReport(status);

                                final reporterName =
                                    report['reporter_name']?.toString().trim() ?? 'Anonymous';

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 14),
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
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  reporterName,
                                                  style: TextStyle(
                                                    color: titleColor,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  createdAt,
                                                  style: TextStyle(
                                                    color: subtitleColor,
                                                    fontSize: 12.5,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 7,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _statusColor(status)
                                                  .withValues(alpha: 0.12),
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                            ),
                                            child: Text(
                                              _statusLabel(status),
                                              style: TextStyle(
                                                color: _statusColor(status),
                                                fontWeight: FontWeight.w700,
                                                fontSize: 12.5,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 14),
                                      Text(
                                        message,
                                        style: TextStyle(
                                          color: titleColor,
                                          fontSize: 14.5,
                                          height: 1.45,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (imageUrls.isNotEmpty) ...[
                                        const SizedBox(height: 16),
                                        Text(
                                          'Attachments',
                                          style: TextStyle(
                                            color: titleColor,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        SizedBox(
                                          height: 120,
                                          child: ListView.separated(
                                            scrollDirection: Axis.horizontal,
                                            itemCount: imageUrls.length,
                                            separatorBuilder: (context, index) =>
                                                const SizedBox(width: 10),
                                            itemBuilder: (context, index) {
                                              final imageUrl =
                                                  imageUrls[index]?.toString() ?? '';
                                              return GestureDetector(
                                                onTap: () {
                                                  showDialog(
                                                    context: context,
                                                    builder: (dialogContext) =>
                                                        Dialog(
                                                      backgroundColor:
                                                          Colors.transparent,
                                                      child: GestureDetector(
                                                        onTap: () =>
                                                            Navigator.pop(
                                                              dialogContext,
                                                            ),
                                                        child: Container(
                                                          decoration:
                                                              BoxDecoration(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(20),
                                                          ),
                                                          child: ClipRRect(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(20),
                                                            child: Image.network(
                                                              imageUrl,
                                                              fit: BoxFit.contain,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                },
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(16),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.black
                                                            .withValues(
                                                              alpha: 0.10,
                                                            ),
                                                        blurRadius: 8,
                                                        offset: const Offset(0, 3),
                                                      ),
                                                    ],
                                                  ),
                                                  child: ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(16),
                                                    child: Image.network(
                                                      imageUrl,
                                                      width: 120,
                                                      height: 120,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                      if (canManageReport) ...[
                                        const SizedBox(height: 16),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: OutlinedButton.icon(
                                                onPressed: _isMutatingReport
                                                    ? null
                                                    : () => _editReport(report),
                                                icon: const Icon(
                                                  Icons.edit_outlined,
                                                  size: 18,
                                                ),
                                                label: const Text('Edit'),
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor:
                                                      AppColors.primary,
                                                  side: BorderSide(
                                                    color: AppColors.primary
                                                        .withValues(alpha: 0.25),
                                                  ),
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 12,
                                                      ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(14),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: OutlinedButton.icon(
                                                onPressed: _isMutatingReport
                                                    ? null
                                                    : () => _deleteReport(report),
                                                icon: const Icon(
                                                  Icons.delete_outline_rounded,
                                                  size: 18,
                                                ),
                                                label: const Text('Delete'),
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor:
                                                      const Color(0xFFDC2626),
                                                  side: const BorderSide(
                                                    color: Color(0xFFFCA5A5),
                                                  ),
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 12,
                                                      ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(14),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                      const SizedBox(height: 14),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.photo_library_outlined,
                                            size: 18,
                                            color: subtitleColor,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '${imageUrls.length} attachment${imageUrls.length == 1 ? '' : 's'}',
                                            style: TextStyle(
                                              color: subtitleColor,
                                              fontSize: 12.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.update_rounded,
                                            size: 18,
                                            color: subtitleColor,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Last updated: $updatedAt',
                                              style: TextStyle(
                                                color: subtitleColor,
                                                fontSize: 12.5,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 18),
                                      Text(
                                        'Progress of the report',
                                        style: TextStyle(
                                          color: titleColor,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 18,
                                          vertical: 22,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? const Color(0xFF111827)
                                              : const Color(0xFFF3F3F3),
                                          borderRadius: BorderRadius.circular(18),
                                        ),
                                        child: Column(
                                          children: [
                                            ...List.generate(
                                              timelineSteps.length,
                                              (index) => _ReportTimelineItem(
                                                step: timelineSteps[index],
                                                isLast:
                                                    index == timelineSteps.length - 1,
                                                titleColor: titleColor,
                                                subtitleColor: subtitleColor,
                                                formattedDate:
                                                    _formatTimelineDate(
                                                  timelineSteps[index].date,
                                                ),
                                              ),
                                            ),
                                            if (status.toLowerCase() ==
                                                'rejected') ...[
                                              const SizedBox(height: 10),
                                              SizedBox(
                                                width: double.infinity,
                                                child: OutlinedButton.icon(
                                                  onPressed: () =>
                                                      _showRejectionReasonDialog(
                                                    rejectionReason,
                                                  ),
                                                  icon: const Icon(
                                                    Icons.info_outline_rounded,
                                                  ),
                                                  label: const Text(
                                                    'See why your report is rejected',
                                                  ),
                                                  style: OutlinedButton.styleFrom(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 16,
                                                          vertical: 14,
                                                        ),
                                                    foregroundColor:
                                                        const Color(0xFFDC2626),
                                                    side: const BorderSide(
                                                      color: Color(0xFFFCA5A5),
                                                    ),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(14),
                                                    ),
                                                    backgroundColor: isDark
                                                        ? const Color(0xFF2A1616)
                                                        : const Color(0xFFFFF7F7),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                          ],
                        ),
                      );
                    },
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

class _ReportTimelineStep {
  final String title;
  final String description;
  final String? date;
  final bool isReached;
  final bool isDone;

  const _ReportTimelineStep({
    required this.title,
    required this.description,
    required this.date,
    required this.isReached,
    required this.isDone,
  });
}

class _ReportTimelineItem extends StatelessWidget {
  final _ReportTimelineStep step;
  final bool isLast;
  final Color titleColor;
  final Color subtitleColor;
  final String formattedDate;

  const _ReportTimelineItem({
    required this.step,
    required this.isLast,
    required this.titleColor,
    required this.subtitleColor,
    required this.formattedDate,
  });

  @override
  Widget build(BuildContext context) {
    final lineColor = step.isReached ? AppColors.primary : const Color(0xFFB0B0B0);
    final iconColor = step.isReached ? AppColors.primary : const Color(0xFFB0B0B0);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 74,
            child: step.date == null
                ? const SizedBox.shrink()
                : Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 28),
                      child: Text(
                        formattedDate,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: titleColor,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 14),
          SizedBox(
            width: 18,
            child: Column(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: iconColor, width: 2),
                    color: Colors.white,
                  ),
                  child: step.isDone
                      ? Icon(Icons.check, size: 10, color: iconColor)
                      : null,
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 4,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      decoration: BoxDecoration(
                        color: lineColor,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 24, bottom: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.title,
                    style: TextStyle(
                      color: titleColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (step.isReached) ...[
                    const SizedBox(height: 4),
                    Text(
                      step.description,
                      style: TextStyle(
                        color: subtitleColor,
                        fontSize: 12.8,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
