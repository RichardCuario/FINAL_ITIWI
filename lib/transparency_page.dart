import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'shared_widgets.dart';

class TransparencyPage extends StatelessWidget {
  const TransparencyPage({super.key});

  static final List<_TransparencyItem> _items = [
    _TransparencyItem(
      title: 'Program and Projects',
      icon: Icons.account_balance_wallet_rounded,
      iconColor: const Color(0xFFF3C746),
      builder: (_) => const TransparencyProgramsPage(),
    ),
    _TransparencyItem(
      title: 'Bids and Projects',
      icon: Icons.work_rounded,
      iconColor: const Color(0xFF6F46D9),
      builder: (_) => const TransparencyBidsPage(),
    ),
    _TransparencyItem(
      title: 'Financial Reports',
      icon: Icons.show_chart_rounded,
      iconColor: const Color(0xFF78D8E6),
      builder: (_) => const TransparencyFinancialReportsPage(),
    ),
    _TransparencyItem(
      title: 'Annual Budget',
      icon: Icons.account_balance_rounded,
      iconColor: const Color(0xFFF26A45),
      builder: (_) => const TransparencyAnnualBudgetPage(),
    ),
    _TransparencyItem(
      title: 'Legislative Ordinances',
      icon: Icons.location_city_rounded,
      iconColor: const Color(0xFFF15B3D),
      builder: (_) => const TransparencyLegislativeOrdinancesPage(),
    ),
    _TransparencyItem(
      title: 'Executive Orders',
      icon: Icons.checkroom_rounded,
      iconColor: const Color(0xFFF3C746),
      builder: (_) => const TransparencyExecutiveOrdersPage(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor =
        isDark ? const Color(0xFF08142A) : const Color(0xFFEAEAEA);

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
      backgroundColor: backgroundColor,
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
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Expanded(
                        child: Text(
                          'Transparency',
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
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.08,
                    ),
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return _TransparencyCard(item: item);
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

class TransparencyProgramsPage extends StatelessWidget {
  const TransparencyProgramsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _TransparencyRecordsPage(
      title: 'Program and Projects',
      tableName: 'transparency_programs_projects',
      errorMessage: 'Failed to load program and project records.',
      emptyMessage:
          'The admin panel has not uploaded any published program or project records yet.',
    );
  }
}

class TransparencyBidsPage extends StatelessWidget {
  const TransparencyBidsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _TransparencyRecordsPage(
      title: 'Bids and Projects',
      tableName: 'transparency_bids_projects',
      errorMessage: 'Failed to load bids and project records.',
      emptyMessage:
          'The admin panel has not uploaded any published bids or project records yet.',
    );
  }
}

class TransparencyFinancialReportsPage extends StatelessWidget {
  const TransparencyFinancialReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _TransparencyRecordsPage(
      title: 'Financial Reports',
      tableName: 'transparency_financial_reports',
      errorMessage: 'Failed to load financial report records.',
      emptyMessage:
          'The admin panel has not uploaded any published financial report records yet.',
    );
  }
}

class TransparencyAnnualBudgetPage extends StatelessWidget {
  const TransparencyAnnualBudgetPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _TransparencyRecordsPage(
      title: 'Annual Budget',
      tableName: 'transparency_annual_budget',
      errorMessage: 'Failed to load annual budget records.',
      emptyMessage:
          'The admin panel has not uploaded published annual budget records yet.',
    );
  }
}

class TransparencyLegislativeOrdinancesPage extends StatelessWidget {
  const TransparencyLegislativeOrdinancesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _TransparencyRecordsPage(
      title: 'Legislative Ordinances',
      tableName: 'transparency_legislative_ordinances',
      errorMessage: 'Failed to load legislative ordinance records.',
      emptyMessage:
          'The admin panel has not uploaded published legislative ordinance records yet.',
    );
  }
}

class TransparencyExecutiveOrdersPage extends StatelessWidget {
  const TransparencyExecutiveOrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _TransparencyRecordsPage(
      title: 'Executive Orders',
      tableName: 'transparency_executive_orders',
      errorMessage: 'Failed to load executive order records.',
      emptyMessage:
          'The admin panel has not uploaded published executive order records yet.',
    );
  }
}

class _TransparencyRecordsPage extends StatefulWidget {
  const _TransparencyRecordsPage({
    required this.title,
    required this.tableName,
    required this.errorMessage,
    required this.emptyMessage,
  });

  final String title;
  final String tableName;
  final String errorMessage;
  final String emptyMessage;

  @override
  State<_TransparencyRecordsPage> createState() =>
      _TransparencyRecordsPageState();
}

class _TransparencyRecordsPageState extends State<_TransparencyRecordsPage> {
  static const int _pageSize = 1000;

  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  String? _errorMessage;
  List<TransparencyRecord> _records = const [];

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final rows = await _fetchAllPublishedRecords();

      if (!mounted) return;

      setState(() {
        _records = rows.map(TransparencyRecord.fromMap).toList();
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = widget.errorMessage;
        _isLoading = false;
      });
    }
  }

  Future<List<Map<String, dynamic>>> _fetchAllPublishedRecords() async {
    final rows = <Map<String, dynamic>>[];
    var from = 0;

    while (true) {
      final data = await _supabase
          .from(widget.tableName)
          .select(
            'id,title,description,pdf_url,is_published,display_order,created_at,updated_at',
          )
          .eq('is_published', true)
          .order('display_order', ascending: true)
          .order('created_at', ascending: false)
          .range(from, from + _pageSize - 1);

      final chunk = List<Map<String, dynamic>>.from(
        (data as List).map((item) => Map<String, dynamic>.from(item as Map)),
      );

      rows.addAll(chunk);

      if (chunk.length < _pageSize) {
        break;
      }

      from += _pageSize;
    }

    return rows;
  }

  void _openRecord(TransparencyRecord record) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TransparencyRecordDetailPage(
          title: widget.title,
          record: record,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? Theme.of(context).scaffoldBackgroundColor
        : const Color(0xFFF3F4F6);

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

    Widget content = _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _errorMessage != null
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  _StatusCard(
                    icon: Icons.cloud_off_rounded,
                    title: 'Unable to load data',
                    message: _errorMessage!,
                    actionLabel: 'Try again',
                    onPressed: _loadRecords,
                  ),
                ],
              )
            : _records.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    children: [
                      _StatusCard(
                        icon: Icons.folder_open_rounded,
                        title: 'No records yet',
                        message: widget.emptyMessage,
                        actionLabel: 'Refresh',
                        onPressed: _loadRecords,
                      ),
                    ],
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                    itemCount: _records.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final record = _records[index];
                      return _TransparencyRecordCard(
                        record: record,
                        onTap: () => _openRecord(record),
                      );
                    },
                  );

    return Scaffold(
      backgroundColor: backgroundColor,
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
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          widget.title,
                          style: const TextStyle(
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
                    onRefresh: _loadRecords,
                    child: content,
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

class TransparencyRecordDetailPage extends StatelessWidget {
  const TransparencyRecordDetailPage({
    super.key,
    required this.title,
    required this.record,
  });

  final String title;
  final TransparencyRecord record;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? Theme.of(context).scaffoldBackgroundColor
        : const Color(0xFFF3F4F6);

    final topGradient = isDark
        ? const [
            Color(0xFF0F172A),
            Color(0xFF172554),
            Color(0xFF111827),
          ]
        : const [
            Color(0xFF1E88E5),
            Color(0xFF90CAF9),
            Color(0xFFF3F4F6),
          ];

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          Container(
            height: 170,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: topGradient,
                stops: const [0.0, 0.6, 1.0],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 12, 16, 10),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          record.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
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
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                    children: [
                      AppSectionCard(
                        borderRadius: const BorderRadius.all(
                          Radius.circular(24),
                        ),
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppColors.primary.withValues(
                                            alpha: 0.18,
                                          )
                                        : const Color(0xFFE8F3FF),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Icon(
                                    Icons.description_rounded,
                                    color: isDark
                                        ? Colors.white
                                        : AppColors.primary,
                                    size: 26,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Document Overview',
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w800,
                                          color: isDark
                                              ? Colors.white
                                              : const Color(0xFF111827),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '$title record details and preview',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: isDark
                                              ? Colors.lightBlue[100]
                                              : AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (record.description != null &&
                                record.description!.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Text(
                                record.description!,
                                style: TextStyle(
                                  fontSize: 15,
                                  height: 1.7,
                                  color: isDark
                                      ? Colors.white70
                                      : const Color(0xFF374151),
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                _InfoChip(
                                  icon: Icons.swap_vert_rounded,
                                  label: 'Order ${record.displayOrder}',
                                ),
                                if (record.createdAt != null)
                                  _InfoChip(
                                    icon: Icons.calendar_today_rounded,
                                    label: _formatDate(record.createdAt!),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (record.pdfUrl != null && record.pdfUrl!.isNotEmpty) ...[
                        AppSectionCard(
                          borderRadius: const BorderRadius.all(
                            Radius.circular(24),
                          ),
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 46,
                                    height: 46,
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? AppColors.primary.withValues(
                                              alpha: 0.18,
                                            )
                                          : const Color(0xFFE8F3FF),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Icon(
                                      Icons.picture_as_pdf_rounded,
                                      color: isDark
                                          ? Colors.white
                                          : AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'PDF Preview',
                                          style: TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w800,
                                            color: isDark
                                                ? Colors.white
                                                : const Color(0xFF111827),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Scroll inside the preview or download the file',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: isDark
                                                ? Colors.lightBlue[100]
                                                : AppColors.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _PdfActionBar(
                                pdfUrl: record.pdfUrl!,
                              ),
                              const SizedBox(height: 14),
                              InlinePdfPreview(
                                pdfUrl: record.pdfUrl!,
                              ),
                            ],
                          ),
                        ),
                      ] else
                        const _PreviewUnavailableCard(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime value) {
    final local = value.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final year = local.year.toString();
    return '$month/$day/$year';
  }
}

class TransparencyProgramDetailPage extends StatelessWidget {
  const TransparencyProgramDetailPage({
    super.key,
    required this.record,
  });

  final TransparencyProgramRecord record;

  @override
  Widget build(BuildContext context) {
    return TransparencyRecordDetailPage(
      title: 'Program and Projects',
      record: record,
    );
  }
}

class _TransparencyCard extends StatelessWidget {
  const _TransparencyCard({required this.item});

  final _TransparencyItem item;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          final builder = item.builder;
          if (builder != null) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: builder),
            );
            return;
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${item.plainTitle} is coming soon.')),
          );
        },
        child: Ink(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF262631) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.08),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
            border: Border.all(
              color: isDark ? Colors.white10 : const Color(0xFFE3E6EB),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 36,
                  child: Icon(
                    item.icon,
                    color: item.iconColor,
                    size: 34,
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Text(
                    item.title,
                    maxLines: 3,
                    overflow: TextOverflow.visible,
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF20242C),
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      height: 1.25,
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
}

class _TransparencyRecordCard extends StatelessWidget {
  const _TransparencyRecordCard({
    required this.record,
    required this.onTap,
  });

  final TransparencyRecord record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            gradient: isDark
                ? const LinearGradient(
                    colors: [Color(0xFF172033), Color(0xFF111827)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : const LinearGradient(
                    colors: [Colors.white, Color(0xFFF8FBFF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE3EEF9),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.07),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.primary.withValues(alpha: 0.18)
                            : const Color(0xFFE8F3FF),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.picture_as_pdf_rounded,
                        color: isDark ? Colors.white : AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            record.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Transparency document',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.lightBlue[100]
                                  : AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: isDark ? Colors.white70 : const Color(0xFF6B7280),
                    ),
                  ],
                ),
                if (record.description != null &&
                    record.description!.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(
                    record.description!,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: isDark ? Colors.white70 : const Color(0xFF4B5563),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _InfoChip(
                      icon: Icons.swap_vert_rounded,
                      label: 'Order ${record.displayOrder}',
                    ),
                    if (record.createdAt != null)
                      _InfoChip(
                        icon: Icons.calendar_today_rounded,
                        label: _formatDate(record.createdAt!),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : const Color(0xFFF4F8FD),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : const Color(0xFFE4EDF8),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.touch_app_rounded,
                        size: 18,
                        color: isDark ? Colors.white70 : AppColors.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          record.pdfUrl == null || record.pdfUrl!.isEmpty
                              ? 'No PDF available'
                              : 'Tap to preview and download this document',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.white70
                                : const Color(0xFF374151),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime value) {
    final local = value.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final year = local.year.toString();
    return '$month/$day/$year';
  }
}

class _PdfActionBar extends StatelessWidget {
  const _PdfActionBar({
    required this.pdfUrl,
  });

  final String pdfUrl;

  Future<void> _downloadPdf(BuildContext context) async {
    final uri = Uri.tryParse(pdfUrl);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid PDF link.')),
      );
      return;
    }

    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open download link.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: () => _downloadPdf(context),
        icon: const Icon(Icons.download_rounded),
        label: const Text('Download PDF'),
      ),
    );
  }
}

class InlinePdfPreview extends StatefulWidget {
  const InlinePdfPreview({
    super.key,
    required this.pdfUrl,
  });

  final String pdfUrl;

  @override
  State<InlinePdfPreview> createState() => _InlinePdfPreviewState();
}

class _InlinePdfPreviewState extends State<InlinePdfPreview> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    final previewUrl =
        'https://docs.google.com/gview?embedded=1&url=${Uri.encodeComponent(widget.pdfUrl)}';

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (!mounted) return;
            setState(() {
              _isLoading = true;
              _errorMessage = null;
            });
          },
          onPageFinished: (_) {
            if (!mounted) return;
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (error) {
            if (!mounted) return;
            setState(() {
              _isLoading = false;
              _errorMessage = error.description;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(previewUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 720,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF334155)
              : const Color(0xFFE4EDF8),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: Theme.of(context).brightness == Brightness.dark
                  ? 0.18
                  : 0.06,
            ),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          WebViewWidget(
            controller: _controller,
            gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
              Factory<OneSequenceGestureRecognizer>(
                EagerGestureRecognizer.new,
              ),
            },
          ),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
          if (_errorMessage != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Unable to preview PDF.\n$_errorMessage',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PreviewUnavailableCard extends StatelessWidget {
  const _PreviewUnavailableCard();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB),
        ),
      ),
      child: Text(
        'PDF preview is not available for this record.',
        style: TextStyle(
          fontSize: 14,
          color: isDark ? Colors.white70 : const Color(0xFF4B5563),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isDark ? Colors.white70 : const Color(0xFF4B5563),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : const Color(0xFF4B5563),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF172033) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 52,
            color: isDark ? Colors.white70 : AppColors.primary,
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              color: isDark ? Colors.white70 : const Color(0xFF4B5563),
            ),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: onPressed,
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}

class TransparencyRecord {
  const TransparencyRecord({
    required this.id,
    required this.title,
    required this.description,
    required this.pdfUrl,
    required this.displayOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TransparencyRecord.fromMap(Map<String, dynamic> map) {
    return TransparencyRecord(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString().trim() ?? '',
      description: map['description']?.toString().trim(),
      pdfUrl: map['pdf_url']?.toString().trim(),
      displayOrder: (map['display_order'] as num?)?.toInt() ?? 0,
      createdAt: _parseDate(map['created_at']),
      updatedAt: _parseDate(map['updated_at']),
    );
  }

  final String id;
  final String title;
  final String? description;
  final String? pdfUrl;
  final int displayOrder;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}

class TransparencyProgramRecord extends TransparencyRecord {
  const TransparencyProgramRecord({
    required super.id,
    required super.title,
    required super.description,
    required super.pdfUrl,
    required super.displayOrder,
    required super.createdAt,
    required super.updatedAt,
  });

  factory TransparencyProgramRecord.fromMap(Map<String, dynamic> map) {
    final record = TransparencyRecord.fromMap(map);
    return TransparencyProgramRecord(
      id: record.id,
      title: record.title,
      description: record.description,
      pdfUrl: record.pdfUrl,
      displayOrder: record.displayOrder,
      createdAt: record.createdAt,
      updatedAt: record.updatedAt,
    );
  }
}

class _TransparencyItem {
  const _TransparencyItem({
    required this.title,
    required this.icon,
    required this.iconColor,
    this.builder,
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final WidgetBuilder? builder;

  String get plainTitle => title;
}
