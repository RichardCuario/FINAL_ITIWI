import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'content_cache_service.dart';
import 'shared_widgets.dart';

class BarangayPage extends StatefulWidget {
  final VoidCallback? onBack;

  const BarangayPage({super.key, this.onBack});

  @override
  State<BarangayPage> createState() => _BarangayPageState();
}

class _BarangayPageState extends State<BarangayPage> {
  final supabase = Supabase.instance.client;
  final _cacheService = const ContentCacheService();

  List<Map<String, dynamic>> barangays = [];
  List<Map<String, dynamic>> filteredBarangays = [];
  bool isLoading = true;
  String searchQuery = '';
  bool isShowingCachedData = false;
  DateTime? cacheUpdatedAt;

  @override
  void initState() {
    super.initState();
    fetchBarangays();
  }

  Future<void> fetchBarangays() async {
    setState(() => isLoading = true);

    try {
      final data = await supabase
          .from('barangays')
          .select()
          .order('name', ascending: true);

      if (!mounted) return;

      final mapped = List<Map<String, dynamic>>.from(
        (data as List).map((item) => Map<String, dynamic>.from(item as Map)),
      );

      await _cacheService.saveBarangays(mapped);

      setState(() {
        barangays = mapped;
        isShowingCachedData = false;
        cacheUpdatedAt = DateTime.now();
        isLoading = false;
      });

      _applySearch(searchQuery);
    } catch (e) {
      final cached = await _cacheService.getBarangays();

      if (!mounted) return;

      setState(() {
        barangays = cached.items;
        isShowingCachedData = cached.hasData;
        cacheUpdatedAt = cached.updatedAt;
        isLoading = false;
      });

      _applySearch(searchQuery);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            cached.hasData
                ? 'Offline mode: showing previously loaded barangays.'
                : 'Error fetching barangays: $e',
          ),
        ),
      );
    }
  }

  void _applySearch(String query) {
    final normalized = query.trim().toLowerCase();

    if (normalized.isEmpty) {
      filteredBarangays = List<Map<String, dynamic>>.from(barangays);
      return;
    }

    filteredBarangays = barangays.where((item) {
      final name = item['name']?.toString().toLowerCase() ?? '';
      final description = item['description']?.toString().toLowerCase() ?? '';
      final geographicData =
          item['geographic_data']?.toString().toLowerCase() ?? '';
      final officials = item['officials']?.toString().toLowerCase() ?? '';

      return name.contains(normalized) ||
          description.contains(normalized) ||
          geographicData.contains(normalized) ||
          officials.contains(normalized);
    }).toList();
  }

  void searchBarangays(String query) {
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

  Future<void> openBarangayDetail(Map<String, dynamic> barangay) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BarangayDetailPage(barangay: barangay),
      ),
    );
  }

  String _extractShortLocation(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'Tiwi, Albay';

    if (trimmed.toLowerCase().contains('tiwi')) {
      return trimmed;
    }

    return '$trimmed, Tiwi, Albay';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final pageBackground =
        isDark ? theme.scaffoldBackgroundColor : const Color(0xFFF3F4F6);
    final surfaceBackground =
        isDark ? const Color(0xFF111827) : const Color(0xFFF8F8F8);
    final summaryCardColor =
        isDark ? const Color(0xFF1F2937) : Colors.white;
    final summaryIconBackground =
        isDark ? const Color(0xFF243145) : const Color(0xFFEAF4FF);
    final primaryText = isDark ? Colors.white : const Color(0xFF161616);
    final secondaryText =
        isDark ? Colors.white70 : const Color(0xFF6B7280);

    return Scaffold(
      backgroundColor: pageBackground,
      body: RefreshIndicator(
        onRefresh: fetchBarangays,
        color: AppColors.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _BarangayHeroSection(
                onBackPressed:
                    widget.onBack ?? () => Navigator.of(context).maybePop(),
                onSearchChanged: searchBarangays,
              ),
            ),
            SliverToBoxAdapter(
              child: Transform.translate(
                offset: const Offset(0, -28),
                child: Container(
                  decoration: BoxDecoration(
                    color: surfaceBackground,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
                  child: isLoading
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 120),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : filteredBarangays.isEmpty
                          ? _EmptyBarangayState(searchQuery: searchQuery)
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: summaryCardColor,
                                    borderRadius: BorderRadius.circular(18),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.04),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: summaryIconBackground,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.location_city,
                                          color: AppColors.primary,
                                          size: 22,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Available barangays',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: secondaryText,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${filteredBarangays.length} barangays found',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w800,
                                                color: primaryText,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isShowingCachedData)
                                  Container(
                                    width: double.infinity,
                                    margin: const EdgeInsets.only(bottom: 20),
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
                                            'Offline mode: showing cached barangays from ${_formatCacheUpdatedAt()}.',
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
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: filteredBarangays.length,
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        crossAxisSpacing: 18,
                                        mainAxisSpacing: 22,
                                        childAspectRatio: 0.72,
                                      ),
                                  itemBuilder: (context, index) {
                                    final item = filteredBarangays[index];

                                    return _BarangayGridCard(
                                      barangay: item,
                                      subtitle: _extractShortLocation(
                                        item['name']?.toString() ?? '',
                                      ),
                                      onTap: () => openBarangayDetail(item),
                                    );
                                  },
                                ),
                              ],
                            ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BarangayDetailPage extends StatelessWidget {
  final Map<String, dynamic> barangay;

  const BarangayDetailPage({super.key, required this.barangay});

  String _buildAddress(String name, String geographicData) {
    final normalizedGeo = geographicData.trim();
    final lowerGeo = normalizedGeo.toLowerCase();
    final looksLikeDescription =
        normalizedGeo.split(RegExp(r'\s+')).length > 12 ||
        lowerGeo.contains('barangay in the municipality') ||
        lowerGeo.contains('population') ||
        lowerGeo.contains('census');

    final combined =
        !looksLikeDescription && normalizedGeo.isNotEmpty
            ? normalizedGeo
            : name.trim();

    if (combined.isEmpty) {
      return 'Tiwi, Albay';
    }

    final lower = combined.toLowerCase();
    if (lower.contains('tiwi') && lower.contains('albay')) {
      return combined;
    }

    if (lower.contains('tiwi')) {
      return '$combined, Albay';
    }

    return '$combined, Tiwi, Albay';
  }

  double? _readCoordinate(String key) {
    final value = barangay[key];

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '');
  }

  Future<void> _openInMaps(
    BuildContext context,
    String address, {
    double? latitude,
    double? longitude,
  }) async {
    final query =
        latitude != null && longitude != null
            ? '$latitude,$longitude'
            : address;

    final candidates = <Uri>[
      Uri.parse('geo:0,0?q=${Uri.encodeComponent(query)}'),
      Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}',
      ),
      Uri.parse(
        'https://maps.google.com/?q=${Uri.encodeComponent(query)}',
      ),
    ];

    for (final uri in candidates) {
      if (await canLaunchUrl(uri)) {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (launched) {
          return;
        }
      }
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to open map app for: $query',
          ),
        ),
      );
    }
  }

  ImageProvider _buildHeaderImageProvider(Map<String, dynamic> barangay) {
    final imageUrl = barangay['barangay_img']?.toString().trim() ?? '';
    if (imageUrl.isNotEmpty) {
      return NetworkImage(imageUrl);
    }
    return const AssetImage('assets/card.jpg');
  }

  String _formatTitle(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'Barangay Details';
    if (trimmed.toLowerCase().contains('tiwi')) return trimmed;
    return '$trimmed, Tiwi, Albay';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final name = barangay['name']?.toString().trim() ?? 'Barangay';
    final description =
        barangay['description']?.toString().trim().isNotEmpty == true
            ? barangay['description'].toString().trim()
            : 'No history or description available yet.';
    final geographicData =
        barangay['geographic_data']?.toString().trim().isNotEmpty == true
            ? barangay['geographic_data'].toString().trim()
            : 'No geographic data available yet.';
    final officialsData = _BarangayOfficialsData.fromRaw(barangay['officials']);
    final address = _buildAddress(name, geographicData);
    final latitude = _readCoordinate('latitude');
    final longitude = _readCoordinate('longitude');

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF3F4F6),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 310,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: _buildHeaderImageProvider(barangay),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Container(
                  height: 310,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.18),
                        Colors.transparent,
                        AppColors.primary.withOpacity(0.12),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: _CircleIconButton(
                        icon: Icons.arrow_back,
                        onTap: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: -46,
                  child: Center(
                    child: _BarangaySeal(
                      title: name,
                      radius: 56,
                      imageUrl: barangay['logo_url']?.toString(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -4),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF111827) : const Color(0xFFF8F8F8),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 74, 22, 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Text(
                          _formatTitle(name),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF151515),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      _DetailSection(
                        title: 'History',
                        titleColor: isDark ? Colors.white : const Color(0xFF151515),
                        child: Text(
                          description,
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.7,
                            color: isDark ? Colors.white70 : Colors.grey[850],
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      _DetailSection(
                        title: 'Geographic data',
                        titleColor: isDark ? Colors.white : const Color(0xFF151515),
                        child: _GeographicMapSection(
                          address: address,
                          geographicData: geographicData,
                          latitude: latitude,
                          longitude: longitude,
                          onOpenMaps: () => _openInMaps(
                            context,
                            address,
                            latitude: latitude,
                            longitude: longitude,
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      _DetailSection(
                        title: 'Barangay Officials',
                        titleColor: isDark ? Colors.white : const Color(0xFF151515),
                        child: officialsData.structuredRows.isNotEmpty
                            ? _OfficialsTable(rows: officialsData.structuredRows)
                            : officialsData.fallbackLines.isEmpty
                                ? Text(
                                    'No officials listed yet.',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: isDark ? Colors.white70 : Colors.grey[700],
                                    ),
                                  )
                                : Column(
                                    children: officialsData.fallbackLines
                                        .asMap()
                                        .entries
                                        .map(
                                          (entry) => Container(
                                            margin: EdgeInsets.only(
                                              bottom: entry.key ==
                                                      officialsData
                                                              .fallbackLines
                                                              .length -
                                                          1
                                                  ? 0
                                                  : 10,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 14,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isDark ? const Color(0xFF1F2937) : Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              border: Border.all(
                                                color: isDark
                                                    ? Colors.white12
                                                    : Colors.grey.shade300,
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 34,
                                                  height: 34,
                                                  decoration:
                                                      BoxDecoration(
                                                        color: isDark
                                                            ? const Color(0xFF243145)
                                                            : const Color(0xFFEAF4FF),
                                                        shape: BoxShape.circle,
                                                      ),
                                                  child: const Icon(
                                                    Icons.person_outline,
                                                    color: AppColors.primary,
                                                    size: 18,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Text(
                                                    entry.value,
                                                    style: TextStyle(
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: isDark
                                                          ? Colors.white
                                                          : const Color(0xFF232323),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BarangayHeroSection extends StatelessWidget {
  final VoidCallback onBackPressed;
  final ValueChanged<String> onSearchChanged;

  const _BarangayHeroSection({
    required this.onBackPressed,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final searchBackground =
        isDark ? const Color(0xFF1E293B) : Colors.white.withValues(alpha: 0.96);
    final searchBorder =
        isDark ? Colors.white10 : Colors.white.withValues(alpha: 0.45);
    final searchText = isDark ? Colors.white : Colors.black87;
    final searchHint = isDark ? Colors.white60 : Colors.grey[500];

    return Stack(
      children: [
        Container(
          height: 310,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/municipal_hall.jpg'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Container(
          height: 310,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black.withOpacity(0.55),
                AppColors.primary.withOpacity(0.28),
                Colors.transparent,
              ],
              stops: const [0.0, 0.35, 0.85],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CircleIconButton(
                  icon: Icons.arrow_back,
                  onTap: onBackPressed,
                ),
                const SizedBox(height: 26),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: 20),
                        child: Text(
                          'Barangays',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 132,
                      height: 132,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        image: const DecorationImage(
                          image: AssetImage('assets/logo.png'),
                          fit: BoxFit.cover,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.16),
                            blurRadius: 12,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  height: 58,
                  decoration: BoxDecoration(
                    color: searchBackground,
                    borderRadius: BorderRadius.circular(29),
                    border: Border.all(
                      color: searchBorder,
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.10),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: TextField(
                    onChanged: onSearchChanged,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: searchText,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search barangay',
                      hintStyle: TextStyle(color: searchHint),
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.search, color: searchHint),
                      contentPadding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _BarangayGridCard extends StatelessWidget {
  final Map<String, dynamic> barangay;
  final String subtitle;
  final VoidCallback onTap;

  const _BarangayGridCard({
    required this.barangay,
    required this.subtitle,
    required this.onTap,
  });

  String? _getLogoUrl() {
    final raw = barangay['logo_url']?.toString().trim() ?? '';
    return raw.isEmpty ? null : raw;
  }

  String _getInitials(String name) {
    final parts = name
        .split(RegExp(r'\s+'))
        .map((entry) => entry.trim())
        .where((entry) => entry.isNotEmpty)
        .toList();

    if (parts.isEmpty) return 'BR';
    if (parts.length == 1) {
      return parts.first.characters.take(2).toString().toUpperCase();
    }

    return '${parts.first.characters.first}${parts.last.characters.first}'
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final name = barangay['name']?.toString().trim() ?? 'Barangay';

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          _BarangaySeal(
            title: name,
            radius: 58,
            fallbackText: _getInitials(name),
            imageUrl: _getLogoUrl(),
          ),
          const SizedBox(height: 16),
          Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : const Color(0xFF161616),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white70
                  : Colors.grey[700],
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _BarangaySeal extends StatelessWidget {
  final String title;
  final double radius;
  final String? fallbackText;
  final String? imageUrl;

  const _BarangaySeal({
    required this.title,
    required this.radius,
    this.fallbackText,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final initials = fallbackText ??
        title
            .split(RegExp(r'\s+'))
            .where((part) => part.trim().isNotEmpty)
            .take(2)
            .map((part) => part[0].toUpperCase())
            .join();
    final hasImage = imageUrl != null && imageUrl!.trim().isNotEmpty;

    return Container(
      width: radius * 2,
      height: radius * 2,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: const Color(0xFFB7B7B7), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: hasImage
              ? null
              : const LinearGradient(
                  colors: [
                    Color(0xFF123E9B),
                    Color(0xFFF6C33B),
                    Color(0xFF2E7D32),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          image: hasImage
              ? DecorationImage(
                  image: NetworkImage(imageUrl!),
                  fit: BoxFit.cover,
                  onError: (_, __) {},
                )
              : null,
          color: hasImage ? Colors.white : null,
        ),
        child: hasImage
            ? null
            : Center(
                child: Container(
                  width: radius * 1.35,
                  height: radius * 1.35,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: Center(
                    child: Text(
                      initials.isEmpty ? 'BR' : initials,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: radius * 0.33,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class _GeographicMapSection extends StatefulWidget {
  final String address;
  final String geographicData;
  final double? latitude;
  final double? longitude;
  final VoidCallback onOpenMaps;

  const _GeographicMapSection({
    required this.address,
    required this.geographicData,
    required this.latitude,
    required this.longitude,
    required this.onOpenMaps,
  });

  @override
  State<_GeographicMapSection> createState() => _GeographicMapSectionState();
}

class _GeographicMapSectionState extends State<_GeographicMapSection> {
  late final Set<Marker> _markers;

  @override
  void initState() {
    super.initState();
    final markerPosition = LatLng(
      widget.latitude ?? 13.4631300,
      widget.longitude ?? 123.6519000,
    );
    _markers = {
      Marker(
        markerId: const MarkerId('barangay-location'),
        position: markerPosition,
        infoWindow: InfoWindow(title: widget.address),
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasCoordinates = widget.latitude != null && widget.longitude != null;
    final latitude = widget.latitude ?? 13.4631300;
    final longitude = widget.longitude ?? 123.6519000;
    final cameraPosition = CameraPosition(
      target: LatLng(latitude, longitude),
      zoom: hasCoordinates ? 16 : 13,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: isDark ? const Color(0xFF1F2937) : Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.16 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: isDark ? Colors.white10 : const Color(0xFFD7E3F2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 240,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(18),
                  ),
                  color: isDark ? const Color(0xFF243145) : const Color(0xFFEAF4FF),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    GoogleMap(
                      initialCameraPosition: cameraPosition,
                      markers: _markers,
                      myLocationButtonEnabled: false,
                      mapToolbarEnabled: false,
                      zoomControlsEnabled: !kIsWeb,
                      compassEnabled: true,
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withOpacity(0.10),
                            Colors.transparent,
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.center,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 14,
                      left: 14,
                      right: 14,
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF0F172A).withOpacity(0.92)
                                    : Colors.white.withOpacity(0.95),
                                borderRadius: BorderRadius.circular(28),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.10),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.search,
                                    size: 18,
                                    color: isDark ? Colors.white70 : const Color(0xFF5F6368),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      widget.address,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: isDark ? Colors.white : const Color(0xFF202124),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF0F172A).withOpacity(0.92)
                                  : Colors.white.withOpacity(0.95),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.10),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: IconButton(
                              onPressed: widget.onOpenMaps,
                              icon: Icon(
                                Icons.open_in_new,
                                size: 18,
                                color: isDark ? Colors.white : const Color(0xFF202124),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      right: 14,
                      bottom: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF0F172A).withOpacity(0.92)
                              : Colors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          hasCoordinates
                              ? 'Google Maps preview'
                              : 'Google Maps preview (approx.)',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white70 : const Color(0xFF1F2937),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.address,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF111827),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Lat ${latitude.toStringAsFixed(6)}, Lng ${longitude.toStringAsFixed(6)}',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: isDark ? Colors.white60 : const Color(0xFF6B7280),
                      ),
                    ),
                    if (!hasCoordinates) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Using the default Tiwi, Albay coordinates because this barangay has no saved latitude/longitude yet.',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: isDark ? Colors.white60 : const Color(0xFF6B7280),
                          height: 1.4,
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: widget.onOpenMaps,
                            icon: const Icon(Icons.directions_outlined),
                            label: const Text('Directions'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF1A73E8),
                              side: const BorderSide(
                                color: Color(0xFFBFD3F2),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: widget.onOpenMaps,
                            icon: const Icon(Icons.map_outlined),
                            label: const Text('Open Maps'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1A73E8),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
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
        const SizedBox(height: 18),
        Text(
          widget.geographicData,
          style: TextStyle(
            fontSize: 16,
            height: 1.7,
            color: isDark ? Colors.white70 : Colors.grey[850],
          ),
        ),
      ],
    );
  }
}

class _OfficialsTable extends StatelessWidget {
  final List<_OfficialRow> rows;

  const _OfficialsTable({required this.rows});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        border: Border.all(
          color: isDark ? Colors.white24 : const Color(0xFF8E8E8E),
        ),
      ),
      child: Column(
        children: [
          for (var index = 0; index < rows.length; index++) ...[
            _OfficialsTableRow(row: rows[index]),
            if (index != rows.length - 1)
              Divider(
                height: 1,
                thickness: 1,
                color: isDark ? Colors.white12 : Colors.grey.shade200,
              ),
          ],
        ],
      ),
    );
  }
}

class _OfficialsTableRow extends StatelessWidget {
  final _OfficialRow row;

  const _OfficialsTableRow({required this.row});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 150,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: isDark ? Colors.white24 : const Color(0xFF8E8E8E),
                ),
              ),
            ),
            alignment: Alignment.centerLeft,
            child: row.label.isEmpty
                ? const SizedBox.shrink()
                : Text(
                    row.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF2B2B2B),
                    ),
                  ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              child: Text(
                row.value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white70 : const Color(0xFF4B5563),
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BarangayOfficialsData {
  final List<_OfficialRow> structuredRows;
  final List<String> fallbackLines;

  const _BarangayOfficialsData({
    required this.structuredRows,
    required this.fallbackLines,
  });

  factory _BarangayOfficialsData.fromRaw(dynamic raw) {
    if (raw == null) {
      return const _BarangayOfficialsData(
        structuredRows: [],
        fallbackLines: [],
      );
    }

    if (raw is Map) {
      final structuredRows = _buildStructuredRows(raw);
      return _BarangayOfficialsData(
        structuredRows: structuredRows,
        fallbackLines: structuredRows.isEmpty ? _splitPlainText(raw) : [],
      );
    }

    final text = raw.toString().trim();
    if (text.isEmpty) {
      return const _BarangayOfficialsData(
        structuredRows: [],
        fallbackLines: [],
      );
    }

    final decodedMap = _decodeOfficialsMap(text);
    if (decodedMap != null) {
      final structuredRows = _buildStructuredRows(decodedMap);
      return _BarangayOfficialsData(
        structuredRows: structuredRows,
        fallbackLines: structuredRows.isEmpty ? _splitPlainText(text) : [],
      );
    }

    return _BarangayOfficialsData(
      structuredRows: const [],
      fallbackLines: _splitPlainText(text),
    );
  }

  static Map<String, dynamic>? _decodeOfficialsMap(String text) {
    try {
      final decoded = jsonDecode(text);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {}

    final punongMatch = RegExp(
      r'"punong_barangay"\s*:\s*"([^"]*)"',
    ).firstMatch(text);
    final skMatch = RegExp(
      r'"sk_chairman"\s*:\s*"([^"]*)"',
    ).firstMatch(text);
    final secretaryMatch = RegExp(
      r'"barangay_secretary"\s*:\s*"([^"]*)"',
    ).firstMatch(text);
    final treasurerMatch = RegExp(
      r'"barangay_treasurer"\s*:\s*"([^"]*)"',
    ).firstMatch(text);
    final kagawadBlockMatch = RegExp(
      r'"barangay_kagawad"\s*:\s*\[(.*?)\]',
    ).firstMatch(text);

    final kagawads = <String>[];
    if (kagawadBlockMatch != null) {
      final kagawadMatches = RegExp(r'"([^"]+)"').allMatches(
        kagawadBlockMatch.group(1) ?? '',
      );

      for (final match in kagawadMatches) {
        final value = (match.group(1) ?? '').trim();
        if (value.isNotEmpty) {
          kagawads.add(value);
        }
      }
    }

    final map = <String, dynamic>{
      'punong_barangay': punongMatch?.group(1)?.trim() ?? '',
      'barangay_kagawad': kagawads,
      'sk_chairman': skMatch?.group(1)?.trim() ?? '',
      'barangay_secretary': secretaryMatch?.group(1)?.trim() ?? '',
      'barangay_treasurer': treasurerMatch?.group(1)?.trim() ?? '',
    };

    final hasStructuredValue = (map['punong_barangay'] as String).isNotEmpty ||
        kagawads.isNotEmpty ||
        (map['sk_chairman'] as String).isNotEmpty ||
        (map['barangay_secretary'] as String).isNotEmpty ||
        (map['barangay_treasurer'] as String).isNotEmpty;

    return hasStructuredValue ? map : null;
  }

  static List<_OfficialRow> _buildStructuredRows(Map raw) {
    String readString(String key) {
      final value = raw[key];
      if (value == null) return '';
      return value.toString().trim();
    }

    List<String> readList(String key) {
      final value = raw[key];
      if (value is List) {
        return value
            .map((item) => item?.toString().trim() ?? '')
            .where((item) => item.isNotEmpty)
            .toList();
      }
      return [];
    }

    final rows = <_OfficialRow>[];

    void addSingle(String label, String value) {
      if (value.isNotEmpty) {
        rows.add(_OfficialRow(label: label, value: value));
      }
    }

    addSingle('Punong Barangay', readString('punong_barangay'));

    final kagawads = readList('barangay_kagawad');
    for (var index = 0; index < kagawads.length; index++) {
      rows.add(
        _OfficialRow(
          label: index == 0 ? 'Barangay Kagawad' : '',
          value: kagawads[index],
        ),
      );
    }

    addSingle('SK Chairman', readString('sk_chairman'));
    addSingle('Barangay Secretary', readString('barangay_secretary'));
    addSingle('Barangay Treasurer', readString('barangay_treasurer'));

    return rows;
  }

  static List<String> _splitPlainText(dynamic raw) {
    final text = raw?.toString().trim() ?? '';
    if (text.isEmpty) return [];

    return text
        .split(RegExp(r'\r?\n|,'))
        .map((entry) => entry.trim())
        .where((entry) => entry.isNotEmpty)
        .toList();
  }
}

class _OfficialRow {
  final String label;
  final String value;

  const _OfficialRow({
    required this.label,
    required this.value,
  });
}

class _DetailSection extends StatelessWidget {
  final String title;
  final Widget child;
  final Color? titleColor;

  const _DetailSection({
    required this.title,
    required this.child,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: titleColor ?? const Color(0xFF151515),
          ),
        ),
        const SizedBox(height: 14),
        child,
      ],
    );
  }
}

class _EmptyBarangayState extends StatelessWidget {
  final String searchQuery;

  const _EmptyBarangayState({required this.searchQuery});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 110, horizontal: 20),
      child: Column(
        children: [
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF243145)
                  : const Color(0xFFEAF4FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.location_city_outlined,
              color: AppColors.primary,
              size: 44,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            searchQuery.trim().isEmpty
                ? 'No barangays available yet'
                : 'No barangays matched your search',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            searchQuery.trim().isEmpty
                ? 'Barangays added from the admin web panel will appear here.'
                : 'Try another search keyword.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.5,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white70
                  : Colors.grey[700],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIconButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF1E293B).withValues(alpha: 0.92)
          : Colors.white.withValues(alpha: 0.8),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(
            icon,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black87,
          ),
        ),
      ),
    );
  }
}
