import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'place_models.dart';
import 'place_service.dart';
import 'auto_image_carousel.dart';
import 'content_cache_service.dart';
import 'shared_widgets.dart';

class TouristGuidePage extends StatefulWidget {
  const TouristGuidePage({super.key});

  @override
  State<TouristGuidePage> createState() => _TouristGuidePageState();
}

class _TouristGuidePageState extends State<TouristGuidePage> {
  final PlaceService _placeService = PlaceService();
  final ContentCacheService _cacheService = const ContentCacheService();
  late Future<List<Place>> _placesFuture;
  List<Place> _cachedPlaces = const [];
  bool _isShowingCachedData = false;

  static const List<String> _sectionOrder = [
    'Tiwi Resorts Near You',
    'Prayer Space Nearby',
    'Popular Tourist Spot',
    'More Places to Explore',
  ];

  @override
  void initState() {
    super.initState();
    _placesFuture = _loadCachedPlacesThenRefresh();
  }

  Future<List<Place>> _loadCachedPlacesThenRefresh() async {
    final cached = await _cacheService.getPlaces();
    final cachedPlaces = cached.items.map(Place.fromMap).toList();

    if (cachedPlaces.isNotEmpty) {
      _cachedPlaces = cachedPlaces;
      _isShowingCachedData = true;
      if (mounted) {
        unawaited(_refreshPlaces());
      }
      return cachedPlaces;
    }

    return _fetchAndCachePlaces();
  }

  Future<List<Place>> _fetchAndCachePlaces() async {
    final places = await _placeService.fetchPlaces(rethrowOnError: true);
    unawaited(
      _cacheService.savePlaces(places.map((place) => place.toMap()).toList()),
    );
    if (mounted) {
      setState(() {
        _cachedPlaces = places;
        _isShowingCachedData = false;
      });
    }
    return places;
  }

  Future<void> _refreshPlaces() async {
    final future = _fetchAndCachePlaces();
    setState(() {
      _placesFuture = future;
    });
    try {
      await future;
    } catch (_) {
      // The FutureBuilder renders the offline state while preserving cached
      // places, when available.
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark
        ? theme.scaffoldBackgroundColor
        : const Color(0xFFF3F4F6);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: FutureBuilder<List<Place>>(
        future: _placesFuture,
        builder: (context, snapshot) {
          final places = snapshot.data ?? _cachedPlaces;
          final groupedPlaces = _groupPlaces(places);
          final visibleSections = _sectionOrder
              .where((section) => (groupedPlaces[section] ?? []).isNotEmpty)
              .toList();

          return RefreshIndicator(
            onRefresh: _refreshPlaces,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              children: [
                _TouristGuideHeader(
                  places: places,
                  onPlaceTap: _openSearchedPlace,
                ),
                if (_isShowingCachedData && places.isNotEmpty)
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: OfflineDataBanner(),
                  ),
                if (snapshot.connectionState != ConnectionState.done &&
                    places.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (snapshot.hasError && places.isEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    child: AppSectionCard(
                      child: Column(
                        children: [
                          Icon(
                            Icons.cloud_off_rounded,
                            size: 52,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'You are offline',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Connect to the internet to load tourist spots for the first time.',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                else if (places.isEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    child: AppSectionCard(
                      child: Column(
                        children: [
                          Icon(
                            Icons.travel_explore_rounded,
                            size: 52,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'No tourist spots available yet.',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Pull down to refresh and check again later.',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                else ...[
                  for (final section in visibleSections)
                    _CategorySection(
                      title: section,
                      places: groupedPlaces[section]!,
                      onPlaceTap: (place) async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => PlaceDetailPage(
                              place: place,
                              placeService: _placeService,
                            ),
                          ),
                        );
                        if (mounted) {
                          await _refreshPlaces();
                        }
                      },
                      onViewAll: () => _openCategorySheet(
                        context: context,
                        title: section,
                        places: groupedPlaces[section]!,
                      ),
                    ),
                  const SizedBox(height: 24),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _openSearchedPlace(Place place) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            PlaceDetailPage(place: place, placeService: _placeService),
      ),
    );
    if (mounted) await _refreshPlaces();
  }

  void _openCategorySheet({
    required BuildContext context,
    required String title,
    required List<Place> places,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _CategoryPlacesSheet(
        title: title,
        places: places,
        onPlaceTap: (place) async {
          Navigator.of(context).pop();
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) =>
                  PlaceDetailPage(place: place, placeService: _placeService),
            ),
          );
          if (mounted) {
            await _refreshPlaces();
          }
        },
      ),
    );
  }

  Map<String, List<Place>> _groupPlaces(List<Place> places) {
    final grouped = {for (final section in _sectionOrder) section: <Place>[]};

    for (final place in places) {
      final section = _resolveSection(place);
      grouped.putIfAbsent(section, () => <Place>[]).add(place);
    }

    for (final entry in grouped.entries) {
      entry.value.sort(_sortPlaces);
    }

    return grouped;
  }

  String _resolveSection(Place place) {
    final category = place.category.toLowerCase();
    final name = place.name.toLowerCase();
    final description = place.description.toLowerCase();
    final location = [
      place.location,
      place.shortLocation,
      place.fullAddress,
    ].join(' ').toLowerCase();

    bool containsAny(List<String> terms) {
      return terms.any(
        (term) =>
            category.contains(term) ||
            name.contains(term) ||
            description.contains(term) ||
            location.contains(term),
      );
    }

    if (containsAny([
      'resort',
      'beach resort',
      'spring resort',
      'pool',
      'hotel',
      'accommodation',
      'staycation',
    ])) {
      return 'Tiwi Resorts Near You';
    }

    if (containsAny([
      'church',
      'chapel',
      'prayer',
      'religious',
      'shrine',
      'cathedral',
      'faith',
    ])) {
      return 'Prayer Space Nearby';
    }

    if (containsAny([
      'island',
      'beach',
      'falls',
      'tourist',
      'spot',
      'landmark',
      'view deck',
      'park',
      'nature',
      'heritage',
      'museum',
      'cove',
    ])) {
      return 'Popular Tourist Spot';
    }

    return 'More Places to Explore';
  }

  int _sortPlaces(Place a, Place b) {
    final featuredCompare = (b.isFeatured ? 1 : 0).compareTo(
      a.isFeatured ? 1 : 0,
    );
    if (featuredCompare != 0) {
      return featuredCompare;
    }

    final ratingCompare = b.averageRating.compareTo(a.averageRating);
    if (ratingCompare != 0) {
      return ratingCompare;
    }

    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  }
}

class _TouristGuideHeader extends StatefulWidget {
  const _TouristGuideHeader({required this.places, required this.onPlaceTap});

  final List<Place> places;
  final ValueChanged<Place> onPlaceTap;

  @override
  State<_TouristGuideHeader> createState() => _TouristGuideHeaderState();
}

class _TouristGuideHeaderState extends State<_TouristGuideHeader> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Place> get _results {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return const [];
    final words = query.split(RegExp(r'\s+'));
    return widget.places.where((place) {
      final haystack = [
        place.name,
        place.category,
        place.location,
        place.shortLocation,
        place.fullAddress,
      ].join(' ').toLowerCase();
      return words.every(haystack.contains);
    }).toList()..sort((a, b) {
      final aStarts = a.name.toLowerCase().startsWith(query);
      final bStarts = b.name.toLowerCase().startsWith(query);
      if (aStarts != bStarts) return aStarts ? -1 : 1;
      return a.name.compareTo(b.name);
    });
  }

  void _selectPlace(Place place) {
    FocusScope.of(context).unfocus();
    _searchController.clear();
    setState(() => _query = '');
    widget.onPlaceTap(place);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? const [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF111827)]
              : const [Color(0xFF4FA9F5), Color(0xFF7CBDF6), Color(0xFFF3F4F6)],
          stops: const [0.0, 0.62, 1.0],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                const SizedBox(width: 10),
                Text(
                  'Tourist Guide',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: RichText(
                      text: TextSpan(
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF111827),
                        ),
                        children: const [
                          TextSpan(text: 'Discover '),
                          TextSpan(
                            text: 'Tiwi',
                            style: TextStyle(color: Color(0xFF1677E6)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 300),
                      child: Column(
                        children: [
                          Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1F2937)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white12
                                    : const Color(0xFFD1D5DB),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.search_rounded,
                                  size: 22,
                                  color: isDark
                                      ? Colors.white60
                                      : const Color(0xFF9CA3AF),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    controller: _searchController,
                                    onChanged: (value) =>
                                        setState(() => _query = value),
                                    textInputAction: TextInputAction.search,
                                    cursorColor: isDark
                                        ? Colors.white70
                                        : const Color(0xFF4F6F8F),
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                    decoration: InputDecoration(
                                      isCollapsed: true,
                                      contentPadding: EdgeInsets.zero,
                                      hintText: 'Search places',
                                      hintStyle: TextStyle(
                                        fontSize: 14,
                                        color: isDark
                                            ? Colors.white60
                                            : const Color(0xFF9CA3AF),
                                      ),
                                      filled: false,
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                    ),
                                  ),
                                ),
                                if (_query.isNotEmpty)
                                  IconButton(
                                    tooltip: 'Clear search',
                                    icon: const Icon(
                                      Icons.close_rounded,
                                      size: 18,
                                    ),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _query = '');
                                    },
                                  ),
                              ],
                            ),
                          ),
                          if (_query.trim().isNotEmpty) ...[
                            const SizedBox(height: 8),
                            _TouristSearchResults(
                              results: _results,
                              query: _query.trim(),
                              onSelected: _selectPlace,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({
    required this.title,
    required this.places,
    required this.onPlaceTap,
    required this.onViewAll,
  });

  final String title;
  final List<Place> places;
  final ValueChanged<Place> onPlaceTap;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              TextButton(onPressed: onViewAll, child: const Text('View all')),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 188,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: places.length,
              separatorBuilder: (context, index) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                final place = places[index];
                return _CategoryPlaceCard(
                  place: place,
                  onTap: () => onPlaceTap(place),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryPlaceCard extends StatelessWidget {
  const _CategoryPlaceCard({required this.place, required this.onTap});

  final Place place;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width * 0.64;
    final distanceText = place.distanceLabel.trim().isNotEmpty
        ? place.distanceLabel.trim()
        : 'Explore';

    return SizedBox(
      width: width.clamp(220.0, 270.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            fit: StackFit.expand,
            children: [
              place.imageUrl.isNotEmpty
                  ? Image.network(
                      place.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const _CategoryImagePlaceholder(),
                    )
                  : const _CategoryImagePlaceholder(),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.04),
                      Colors.black.withValues(alpha: 0.18),
                      Colors.black.withValues(alpha: 0.72),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 14,
                right: 14,
                bottom: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        distanceText,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (place.isFeatured)
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'Featured',
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
        ),
      ),
    );
  }
}

class _CategoryImagePlaceholder extends StatelessWidget {
  const _CategoryImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF7CC6FF), Color(0xFF0B79D0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.image_outlined, color: Colors.white, size: 46),
      ),
    );
  }
}

class _CategoryPlacesSheet extends StatelessWidget {
  const _CategoryPlacesSheet({
    required this.title,
    required this.places,
    required this.onPlaceTap,
  });

  final String title;
  final List<Place> places;
  final ValueChanged<Place> onPlaceTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: places.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final place = places[index];
                  return _PlaceListTileCard(
                    place: place,
                    onTap: () => onPlaceTap(place),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TouristSearchResults extends StatelessWidget {
  const _TouristSearchResults({
    required this.results,
    required this.query,
    required this.onSelected,
  });

  final List<Place> results;
  final String query;
  final ValueChanged<Place> onSelected;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dividerColor = isDark ? Colors.white12 : const Color(0xFFE3E3E3);
    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.24 : 0.12),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: results.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              child: Text('No places found for "$query"'),
            )
          : ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: results.length,
              separatorBuilder: (_, _) => Divider(
                height: 1,
                color: dividerColor,
                indent: 16,
                endIndent: 16,
              ),
              itemBuilder: (context, index) {
                final place = results[index];
                final subtitle = [
                  if (place.category.trim().isNotEmpty) place.category.trim(),
                  if (place._headerLocation.isNotEmpty) place._headerLocation,
                ].join(' • ');
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onSelected(place),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.place_outlined,
                            size: 22,
                            color: isDark
                                ? Colors.white70
                                : const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  place.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (subtitle.isNotEmpty)
                                  Text(
                                    subtitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? Colors.white60
                                          : const Color(0xFF64748B),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _PlaceListTileCard extends StatelessWidget {
  const _PlaceListTileCard({required this.place, required this.onTap});

  final Place place;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final subtitle = [
      if (place.category.trim().isNotEmpty) place.category.trim(),
      if (place._headerLocation.isNotEmpty) place._headerLocation,
    ].join(' • ');

    return AppSectionCard(
      padding: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 58,
            height: 58,
            child: place.imageUrl.isNotEmpty
                ? Image.network(
                    place.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const _CategoryImagePlaceholder(),
                  )
                : const _CategoryImagePlaceholder(),
          ),
        ),
        title: Text(
          place.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: subtitle.isEmpty ? null : Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}

extension on Place {
  String get _headerLocation {
    if (shortLocation.trim().isNotEmpty) {
      return shortLocation.trim();
    }
    if (location.trim().isNotEmpty) {
      return location.trim();
    }
    if (fullAddress.trim().isNotEmpty) {
      return fullAddress.trim();
    }
    return 'Tiwi, Albay';
  }
}

class PlaceDetailPage extends StatefulWidget {
  const PlaceDetailPage({
    super.key,
    required this.place,
    required this.placeService,
  });

  final Place place;
  final PlaceService placeService;

  @override
  State<PlaceDetailPage> createState() => _PlaceDetailPageState();
}

class _PlaceDetailPageState extends State<PlaceDetailPage> {
  late Future<List<PlaceReview>> _reviewsFuture;

  @override
  void initState() {
    super.initState();
    _reviewsFuture = widget.placeService.fetchReviews(widget.place.id);
  }

  Future<void> _refreshReviews() async {
    final future = widget.placeService.fetchReviews(widget.place.id);
    setState(() {
      _reviewsFuture = future;
    });
    await future;
  }

  Future<void> _openReviewSheet() async {
    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => ReviewFormSheet(
        place: widget.place,
        placeService: widget.placeService,
      ),
    );

    if (submitted == true && mounted) {
      await _refreshReviews();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review submitted successfully.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final place = widget.place;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark
        ? theme.scaffoldBackgroundColor
        : const Color(0xFFF3F6FB);
    final softTextColor = isDark ? Colors.white70 : const Color(0xFF5F6F85);
    return Scaffold(
      backgroundColor: backgroundColor,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: RefreshIndicator(
          edgeOffset: MediaQuery.paddingOf(context).top,
          onRefresh: _refreshReviews,
          child: FutureBuilder<List<PlaceReview>>(
            future: _reviewsFuture,
            builder: (context, snapshot) {
              final reviews = snapshot.data ?? const <PlaceReview>[];
              final average = reviews.isEmpty
                  ? place.averageRating
                  : reviews.fold<int>(0, (sum, item) => sum + item.rating) /
                        reviews.length;
              final reviewCount = reviews.isEmpty
                  ? place.reviewCount
                  : reviews.length;
              final ratingCounts = <int, int>{
                for (var rating = 1; rating <= 5; rating++)
                  rating: reviews
                      .where((review) => review.rating == rating)
                      .length,
              };
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                children: [
                  _buildPhotoHeader(average, reviewCount),
                  _buildPlaceInformation(),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      20,
                      16,
                      32 + MediaQuery.paddingOf(context).bottom,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (reviews.isNotEmpty) ...[
                          _RatingSummary(
                            average: average,
                            reviewCount: reviewCount,
                            ratingCounts: ratingCounts,
                            theme: theme,
                            isDark: isDark,
                            softTextColor: softTextColor,
                            margin: EdgeInsets.zero,
                          ),
                          const SizedBox(height: 14),
                        ],
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: isDark
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xFF172033),
                                      Color(0xFF111827),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : const LinearGradient(
                                    colors: [
                                      Color(0xFFFFFFFF),
                                      Color(0xFFF3F8FF),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white10
                                  : const Color(0xFFD8E7F8),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 14,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.08)
                                      : const Color(0xFFDDEBFF),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(
                                  Icons.forum_rounded,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF1E88E5),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Reviews from visitors',
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                            color: colorScheme.onSurface,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$reviewCount review${reviewCount == 1 ? '' : 's'} from guests and visitors',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: softTextColor,
                                            height: 1.35,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _openReviewSheet,
                            icon: const Icon(
                              Icons.rate_review_rounded,
                              size: 18,
                            ),
                            label: const Text('Write a review'),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(46),
                              backgroundColor: const Color(0xFF0B4C8C),
                              foregroundColor: Colors.white,
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                              shape: const StadiumBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        if (snapshot.connectionState != ConnectionState.done)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (reviews.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF111827)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white10
                                    : const Color(0xFFE2E8F0),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 14,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Container(
                                  width: 62,
                                  height: 62,
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.06)
                                        : const Color(0xFFDDEBFF),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Icon(
                                    Icons.rate_review_rounded,
                                    size: 28,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF1E88E5),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No reviews yet',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Be the first to share your experience about this place.',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: softTextColor,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else ...[
                          if (reviews.length > 2)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: SizedBox(
                                width: double.infinity,
                                child: FilledButton.tonalIcon(
                                  onPressed: () => _showAllReviewsModal(
                                    context: context,
                                    reviews: reviews,
                                    theme: theme,
                                    isDark: isDark,
                                    softTextColor: softTextColor,
                                  ),
                                  icon: const Icon(Icons.reviews_rounded),
                                  label: Text(
                                    'View all ${reviews.length} reviews',
                                  ),
                                ),
                              ),
                            ),
                          ...reviews
                              .take(2)
                              .map(
                                (review) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _ReviewCard(
                                    review: review,
                                    theme: theme,
                                    isDark: isDark,
                                    softTextColor: softTextColor,
                                    onTap: () => _showReviewDetailModal(
                                      context: context,
                                      review: review,
                                      placeName: place.name,
                                      theme: theme,
                                      isDark: isDark,
                                      softTextColor: softTextColor,
                                    ),
                                  ),
                                ),
                              ),
                        ],
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoHeader(double average, int reviewCount) {
    final place = widget.place;
    final address = _buildLocationText(place);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final sheet = dark ? const Color(0xFF15202E) : Colors.white;
    final category = place.category.isEmpty ? 'Tourist spot' : place.category;
    final ratingText = reviewCount > 0 ? average.toStringAsFixed(1) : 'New';

    return Stack(
      children: [
        Positioned.fill(
          child: AutoImageCarousel(
            urls: place.imageUrls,
            placeholder: const _ImagePlaceholder(),
            indicatorBottom: 32,
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.18),
                    Colors.black.withValues(alpha: 0.04),
                    Colors.black.withValues(alpha: 0.74),
                  ],
                  stops: const [0.0, 0.38, 1.0],
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            18,
            MediaQuery.paddingOf(context).top + 12,
            18,
            44,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF234B53).withValues(alpha: 0.75),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.18),
                        width: 1,
                      ),
                    ),
                    child: IconButton(
                      tooltip: 'Back',
                      onPressed: () => Navigator.maybePop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 44,
                        minHeight: 44,
                      ),
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
              const SizedBox(height: 42),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.52),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _placeCategoryIcon(category),
                          color: Colors.white,
                          size: 17,
                        ),
                        const SizedBox(width: 7),
                        Text(
                          category,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                place.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  height: 1.08,
                  letterSpacing: -0.4,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (address.isNotEmpty) ...[
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        address,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 12,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: Color(0xFFFFC400),
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          ratingText,
                          style: const TextStyle(
                            color: Color(0xFF101727),
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (place.distanceLabel.isNotEmpty)
                    _photoBadge(Icons.route_rounded, place.distanceLabel),
                  if (place.isFeatured)
                    _photoBadge(Icons.workspace_premium_rounded, 'Featured'),
                ],
              ),
            ],
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 24,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: sheet,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _photoBadge(
    IconData icon,
    String label, {
    Color iconColor = const Color(0xFF0077BD),
  }) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: 12,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: iconColor, size: 19),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF101727),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );

  IconData _placeCategoryIcon(String category) {
    final value = category.toLowerCase();
    if (value.contains('resort') || value.contains('beach')) {
      return Icons.beach_access_rounded;
    }
    if (value.contains('food') || value.contains('restaurant')) {
      return Icons.restaurant_rounded;
    }
    if (value.contains('church') || value.contains('heritage')) {
      return Icons.account_balance_rounded;
    }
    if (value.contains('mountain') || value.contains('nature')) {
      return Icons.landscape_rounded;
    }
    return Icons.explore_rounded;
  }

  Widget _buildPlaceInformation() {
    final place = widget.place;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final address = _buildLocationText(place);
    final coordinates = _buildCoordinatesText(place);
    final bodyStyle = TextStyle(
      color: dark ? const Color(0xFFB5C0D1) : const Color(0xFF647087),
      fontSize: 14,
      height: 1.55,
    );
    return Container(
      color: dark ? const Color(0xFF15202E) : Colors.white,
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PlaceDetailSection(
            icon: Icons.article_rounded,
            title: 'Overview',
            child: Text(
              [
                if (place.category.isNotEmpty) place.category,
                if (address.isNotEmpty) address,
              ].join(' · '),
              style: bodyStyle,
            ),
          ),
          if (place.description.isNotEmpty) ...[
            const SizedBox(height: 20),
            _PlaceDetailSection(
              icon: Icons.eco_rounded,
              title: 'About this place',
              teal: true,
              child: Text(place.description, style: bodyStyle),
            ),
          ],
          if (_hasPlaceMapData(place)) ...[
            const SizedBox(height: 22),
            _PlaceMapSection(place: place),
          ],
          if (address.isNotEmpty ||
              place.phone.isNotEmpty ||
              place.websiteUrl.isNotEmpty ||
              coordinates.isNotEmpty ||
              place.isFeatured) ...[
            const SizedBox(height: 22),
            const _PlaceDetailSection(
              icon: Icons.call_rounded,
              title: 'Contact & details',
              teal: true,
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: dark ? const Color(0xFF1C2B3D) : const Color(0xFFF5F8FC),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: dark ? Colors.white10 : const Color(0xFFECF2F8),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (address.isNotEmpty)
                    _InfoRow(
                      icon: Icons.location_on_rounded,
                      label: 'Address',
                      value: address,
                    ),
                  if (place.phone.isNotEmpty)
                    _InfoRow(
                      icon: Icons.call_rounded,
                      label: 'Phone',
                      value: place.phone,
                    ),
                  if (place.websiteUrl.isNotEmpty)
                    _InfoRow(
                      icon: Icons.language_rounded,
                      label: 'Website',
                      value: place.websiteUrl,
                      compact: false,
                    ),
                  if (coordinates.isNotEmpty)
                    _InfoRow(
                      icon: Icons.map_outlined,
                      label: 'Coordinates',
                      value: coordinates,
                    ),
                  if (place.isFeatured) const _FeatureBadge(),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _buildLocationText(Place place) {
    if (place.fullAddress.trim().isNotEmpty) {
      return place.fullAddress.trim();
    }
    if (place.location.trim().isNotEmpty) {
      return place.location.trim();
    }
    return place.shortLocation.trim();
  }

  String _buildCoordinatesText(Place place) {
    final latitude = place.latitude;
    final longitude = place.longitude;

    if (latitude == null || longitude == null) {
      return '';
    }

    return '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
  }

  bool _hasPlaceMapData(Place place) {
    return place.latitude != null ||
        place.longitude != null ||
        place.fullAddress.trim().isNotEmpty ||
        place.location.trim().isNotEmpty ||
        place.shortLocation.trim().isNotEmpty;
  }

  static String _formatDate(DateTime? date) {
    if (date == null) {
      return 'Recently';
    }
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String _maskReviewerName(String name) {
    final trimmed = name.trim();
    return trimmed.isEmpty ? 'Anonymous' : trimmed;
  }

  String _reviewInitial(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return 'A';
    }

    final normalized = trimmed.toLowerCase();
    if (normalized == 'anonymous' || normalized == 'anonymous reviewer') {
      return 'A';
    }

    if (trimmed.contains('@')) {
      return trimmed[0].toUpperCase();
    }

    final words = trimmed
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();

    if (words.isEmpty) {
      return 'A';
    }

    return words.first[0].toUpperCase();
  }

  void _showReviewDetailModal({
    required BuildContext context,
    required PlaceReview review,
    required String placeName,
    required ThemeData theme,
    required bool isDark,
    required Color softTextColor,
  }) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: isDark ? const Color(0xFF111827) : Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Review',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: softTextColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            placeName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ReviewerAvatar(
                      photoUrl: review.reviewerPhotoUrl,
                      initial: _reviewInitial(review.reviewerName),
                      size: 56,
                      borderRadius: 16,
                      isDark: isDark,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _maskReviewerName(review.reviewerName),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.06)
                                  : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white10
                                    : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Text(
                              _formatDate(review.createdAt),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: softTextColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1F3A5F)
                            : const Color(0xFFDDEBFF),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Color(0xFFF4B400),
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            review.rating.toString(),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF163B63),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                RatingStars(rating: review.rating.toDouble(), size: 20),
                if (review.reviewText.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.04)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? Colors.white10
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Text(
                      review.reviewText,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.7,
                        color: isDark
                            ? Colors.white70
                            : const Color(0xFF3E4C59),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAllReviewsModal({
    required BuildContext context,
    required List<PlaceReview> reviews,
    required ThemeData theme,
    required bool isDark,
    required Color softTextColor,
  }) {
    final average = reviews.isEmpty
        ? 0.0
        : reviews.fold<int>(0, (total, review) => total + review.rating) /
              reviews.length;
    final ratingCounts = <int, int>{
      for (var rating = 1; rating <= 5; rating++)
        rating: reviews.where((review) => review.rating == rating).length,
    };

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => FractionallySizedBox(
        heightFactor: 0.88,
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF111827) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 12, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'All reviews',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${reviews.length} visitor review${reviews.length == 1 ? '' : 's'}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: softTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton.filledTonal(
                      tooltip: 'Close reviews',
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              if (reviews.isNotEmpty)
                _RatingSummary(
                  average: average,
                  reviewCount: reviews.length,
                  ratingCounts: ratingCounts,
                  theme: theme,
                  isDark: isDark,
                  softTextColor: softTextColor,
                ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                  itemCount: reviews.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final review = reviews[index];
                    return _ReviewCard(
                      review: review,
                      theme: theme,
                      isDark: isDark,
                      softTextColor: softTextColor,
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        _showReviewDetailModal(
                          context: context,
                          review: review,
                          placeName: widget.place.name,
                          theme: theme,
                          isDark: isDark,
                          softTextColor: softTextColor,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RatingSummary extends StatelessWidget {
  const _RatingSummary({
    required this.average,
    required this.reviewCount,
    required this.ratingCounts,
    required this.theme,
    required this.isDark,
    required this.softTextColor,
    this.margin = const EdgeInsets.fromLTRB(20, 0, 20, 16),
  });

  final double average;
  final int reviewCount;
  final Map<int, int> ratingCounts;
  final ThemeData theme;
  final bool isDark;
  final Color softTextColor;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final surfaceColor = isDark
        ? const Color(0xFF172554)
        : const Color(0xFFEFF6FF);
    final primaryText = isDark ? Colors.white : const Color(0xFF163B63);
    final trackColor = isDark ? Colors.white24 : const Color(0xFFD7E3F2);

    return Container(
      width: double.infinity,
      margin: margin,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 66,
            child: Column(
              children: [
                Text(
                  average.toStringAsFixed(1),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: primaryText,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Icon(
                  Icons.star_rounded,
                  color: Color(0xFFF4B400),
                  size: 20,
                ),
                const SizedBox(height: 2),
                Text(
                  'out of 5',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: softTextColor,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 76,
            color: isDark ? Colors.white12 : const Color(0xFFD3E1F0),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              children: [
                for (var rating = 5; rating >= 1; rating--)
                  Padding(
                    padding: EdgeInsets.only(bottom: rating == 1 ? 0 : 6),
                    child: _RatingDistributionRow(
                      rating: rating,
                      count: ratingCounts[rating] ?? 0,
                      total: reviewCount,
                      fillColor: const Color(0xFF0AA88A),
                      trackColor: trackColor,
                      textColor: softTextColor,
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

class _RatingDistributionRow extends StatelessWidget {
  const _RatingDistributionRow({
    required this.rating,
    required this.count,
    required this.total,
    required this.fillColor,
    required this.trackColor,
    required this.textColor,
  });

  final int rating;
  final int count;
  final int total;
  final Color fillColor;
  final Color trackColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : count / total;
    final percentage = (progress * 100).round();

    return Row(
      children: [
        SizedBox(
          width: 21,
          child: Text(
            '$rating★',
            style: TextStyle(
              color: textColor,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              color: fillColor,
              backgroundColor: trackColor,
            ),
          ),
        ),
        const SizedBox(width: 7),
        SizedBox(
          width: 28,
          child: Text(
            '$percentage%',
            textAlign: TextAlign.right,
            style: TextStyle(
              color: textColor,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        gradient: LinearGradient(
          colors: [Color(0xFFB3E5FC), Color(0xFF81D4FA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Icon(
        Icons.landscape_rounded,
        size: 64,
        color: Colors.white.withValues(alpha: 0.9),
      ),
    );
  }
}

class _PlaceDetailSection extends StatelessWidget {
  const _PlaceDetailSection({
    required this.icon,
    required this.title,
    this.teal = false,
    this.child,
  });
  final IconData icon;
  final String title;
  final bool teal;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(11),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: teal
                  ? const [Color(0xFF10BEAE), Color(0xFF009D8C)]
                  : const [Color(0xFF00A9DF), Color(0xFF007DBD)],
            ),
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  title,
                  style: TextStyle(
                    color: dark ? Colors.white : const Color(0xFF101727),
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
              ),
              if (child != null) ...[const SizedBox(height: 6), child!],
            ],
          ),
        ),
      ],
    );
  }
}

class _PlaceMapSection extends StatefulWidget {
  const _PlaceMapSection({required this.place});

  final Place place;

  @override
  State<_PlaceMapSection> createState() => _PlaceMapSectionState();
}

class _PlaceMapSectionState extends State<_PlaceMapSection> {
  late final Set<Marker> _markers;

  @override
  void initState() {
    super.initState();
    final position = LatLng(
      widget.place.latitude ?? 13.4631300,
      widget.place.longitude ?? 123.6519000,
    );
    _markers = {
      Marker(
        markerId: MarkerId(widget.place.id),
        position: position,
        infoWindow: InfoWindow(title: widget.place.name),
      ),
    };
  }

  String get _mapAddress {
    final fullAddress = widget.place.fullAddress.trim();
    if (fullAddress.isNotEmpty) {
      return fullAddress;
    }

    final location = widget.place.location.trim();
    if (location.isNotEmpty) {
      return location;
    }

    final shortLocation = widget.place.shortLocation.trim();
    if (shortLocation.isNotEmpty) {
      return shortLocation;
    }

    return '${widget.place.name}, Tiwi, Albay';
  }

  bool get _hasCoordinates =>
      widget.place.latitude != null && widget.place.longitude != null;

  String get _destination => _hasCoordinates
      ? '${widget.place.latitude},${widget.place.longitude}'
      : _mapAddress;

  Future<void> _launchMaps({bool directions = false}) async {
    final web = Uri.https(
      'www.google.com',
      directions ? '/maps/dir/' : '/maps/search/',
      {
        'api': '1',
        if (directions) 'destination': _destination else 'query': _destination,
      },
    );
    final candidates = <Uri>[
      if (!directions)
        Uri.parse('geo:0,0?q=${Uri.encodeComponent(_destination)}'),
      web,
    ];
    for (final uri in candidates) {
      try {
        if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
      } catch (_) {
        // Try the web URL if the device has no native maps handler.
      }
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Unable to open map for $_mapAddress')),
    );
  }

  static const _previewStyle = '''[
    {"featureType":"water","elementType":"geometry","stylers":[{"color":"#82d9f5"}]},
    {"featureType":"landscape","elementType":"geometry","stylers":[{"color":"#cdf7e5"}]},
    {"featureType":"road","elementType":"geometry","stylers":[{"color":"#f4fafc"}]},
    {"featureType":"poi","elementType":"geometry","stylers":[{"color":"#b7efcf"}]}
  ]''';

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final cameraPosition = CameraPosition(
      target: LatLng(
        widget.place.latitude ?? 13.4631300,
        widget.place.longitude ?? 123.6519000,
      ),
      zoom: _hasCoordinates ? 16 : 13,
    );
    final directions = FilledButton.icon(
      onPressed: () => _launchMaps(directions: true),
      icon: const Icon(Icons.directions_rounded, size: 20),
      label: const Text('Directions'),
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF0478C6),
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 50),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
    final openMaps = FilledButton.icon(
      onPressed: _launchMaps,
      icon: const Icon(Icons.map_outlined, size: 20),
      label: const Text('Open Maps'),
      style: FilledButton.styleFrom(
        backgroundColor: dark
            ? const Color(0xFF213D57)
            : const Color(0xFFE4F2FF),
        foregroundColor: dark
            ? const Color(0xFF9DD5FF)
            : const Color(0xFF0071C5),
        minimumSize: const Size(0, 50),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _PlaceDetailSection(
          icon: Icons.location_on_rounded,
          title: 'Location & directions',
        ),
        const SizedBox(height: 12),
        Container(
          height: 210,
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: const Color(0xFFCDF7E5),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              GoogleMap(
                initialCameraPosition: cameraPosition,
                markers: _hasCoordinates ? _markers : const <Marker>{},
                style: _previewStyle,
                myLocationButtonEnabled: false,
                mapToolbarEnabled: false,
                zoomControlsEnabled: !kIsWeb,
                compassEnabled: false,
              ),
              Positioned(
                top: 10,
                left: 10,
                right: 10,
                child: Row(
                  children: [
                    Expanded(
                      child: Material(
                        color: Colors.white,
                        elevation: 3,
                        shadowColor: Colors.black26,
                        borderRadius: BorderRadius.circular(28),
                        child: InkWell(
                          onTap: _launchMaps,
                          borderRadius: BorderRadius.circular(28),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 13,
                              vertical: 14,
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.search_rounded,
                                  size: 19,
                                  color: Color(0xFF24364C),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _mapAddress,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFF101727),
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      tooltip: 'Open map in another app',
                      onPressed: _launchMaps,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF20334B),
                        minimumSize: const Size(48, 48),
                      ),
                      icon: const Icon(Icons.open_in_new_rounded, size: 20),
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 10,
                bottom: 10,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 210),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _hasCoordinates
                        ? 'Google Maps preview'
                        : 'Approximate area · Tiwi',
                    style: const TextStyle(
                      color: Color(0xFF17243B),
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 300 ||
                MediaQuery.textScalerOf(context).scale(14) > 20) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [directions, const SizedBox(height: 8), openMaps],
              );
            }
            return Row(
              children: [
                Expanded(child: directions),
                const SizedBox(width: 8),
                Expanded(child: openMaps),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.compact = true,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: compact
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFF0780CB).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 18,
              color: theme.brightness == Brightness.dark
                  ? const Color(0xFF92D0FF)
                  : const Color(0xFF0075BD),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    height: 1.35,
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

class _FeatureBadge extends StatelessWidget {
  const _FeatureBadge();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? const Color(0xFF213D57)
            : const Color(0xFF0075BD).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star_rounded,
            size: 18,
            color: theme.brightness == Brightness.dark
                ? const Color(0xFF92D0FF)
                : const Color(0xFF0075BD),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'Featured place',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.brightness == Brightness.dark
                    ? const Color(0xFF92D0FF)
                    : const Color(0xFF0075BD),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.review,
    required this.theme,
    required this.isDark,
    required this.softTextColor,
    required this.onTap,
  });

  final PlaceReview review;
  final ThemeData theme;
  final bool isDark;
  final Color softTextColor;
  final VoidCallback onTap;

  String _maskReviewerName(String name) {
    final trimmed = name.trim();
    return trimmed.isEmpty ? 'Anonymous' : trimmed;
  }

  String _reviewInitial(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'A';

    final normalized = trimmed.toLowerCase();
    if (normalized == 'anonymous' || normalized == 'anonymous reviewer') {
      return 'A';
    }

    if (trimmed.contains('@')) return trimmed[0].toUpperCase();

    final words = trimmed
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    return words.isEmpty ? 'A' : words.first[0].toUpperCase();
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Recently';
    const months = [
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
  }

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ReviewerAvatar(
                    photoUrl: review.reviewerPhotoUrl,
                    initial: _reviewInitial(review.reviewerName),
                    size: 44,
                    borderRadius: 12,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _maskReviewerName(review.reviewerName),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(review.createdAt),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: softTextColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _RatingBadge(rating: review.rating, isDark: isDark),
                ],
              ),
              const SizedBox(height: 12),
              RatingStars(
                rating: review.rating.toDouble(),
                size: 17,
                activeColor: const Color(0xFFF4B400),
                inactiveColor: isDark
                    ? Colors.white24
                    : const Color(0xFFCBD5E1),
              ),
              if (review.reviewText.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  review.reviewText,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark ? Colors.white70 : const Color(0xFF3E4C59),
                    height: 1.5,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewerAvatar extends StatelessWidget {
  const _ReviewerAvatar({
    required this.photoUrl,
    required this.initial,
    required this.size,
    required this.borderRadius,
    required this.isDark,
  });

  final String photoUrl;
  final String initial;
  final double size;
  final double borderRadius;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    final fallback = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: isDark
            ? const LinearGradient(
                colors: [Color(0xFF334155), Color(0xFF1E293B)],
              )
            : const LinearGradient(
                colors: [Color(0xFF90CAF9), Color(0xFF1E88E5)],
              ),
        borderRadius: radius,
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.36,
        ),
      ),
    );

    if (photoUrl.trim().isEmpty) return fallback;

    return ClipRRect(
      borderRadius: radius,
      child: Image.network(
        photoUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => fallback,
      ),
    );
  }
}

class _RatingBadge extends StatelessWidget {
  const _RatingBadge({required this.rating, required this.isDark});

  final int rating;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F3A5F) : const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 16, color: Color(0xFFF4B400)),
          const SizedBox(width: 3),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF163B63),
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class ReviewFormSheet extends StatefulWidget {
  const ReviewFormSheet({
    super.key,
    required this.place,
    required this.placeService,
  });

  final Place place;
  final PlaceService placeService;

  @override
  State<ReviewFormSheet> createState() => _ReviewFormSheetState();
}

class _ReviewFormSheetState extends State<ReviewFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _reviewController = TextEditingController();
  int _selectedRating = 5;
  bool _submitting = false;

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  String get _ratingLabel {
    switch (_selectedRating) {
      case 5:
        return 'Excellent';
      case 4:
        return 'Very good';
      case 3:
        return 'Good';
      case 2:
        return 'Fair';
      default:
        return 'Needs improvement';
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _submitting = true;
    });

    try {
      await widget.placeService.submitReview(
        placeId: widget.place.id,
        rating: _selectedRating,
        reviewText: _reviewController.text,
      );

      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to submit review: $error')),
      );
      setState(() {
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 14, 16, 14 + viewInsets.bottom),
        child: Form(
          key: _formKey,
          child: Wrap(
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : const Color(0xFFD1D5DB),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF172554)
                      : const Color(0xFF0B4C8C),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.rate_review_rounded,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Write a review',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.place.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.88),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Close review form',
                          onPressed: _submitting
                              ? null
                              : () => Navigator.of(context).pop(),
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF111827) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your rating',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Choose a rating that reflects your visit.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? Colors.white60
                            : const Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.04)
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? Colors.white10
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                _ratingLabel,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF3D6),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  '$_selectedRating out of 5',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFFB45309),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: List.generate(5, (index) {
                              final star = index + 1;
                              final selected = star <= _selectedRating;
                              return Semantics(
                                button: true,
                                label: '$star star${star == 1 ? '' : 's'}',
                                selected: selected,
                                child: IconButton(
                                  tooltip: '$star star${star == 1 ? '' : 's'}',
                                  onPressed: _submitting
                                      ? null
                                      : () => setState(() {
                                          _selectedRating = star;
                                        }),
                                  icon: Icon(
                                    selected
                                        ? Icons.star_rounded
                                        : Icons.star_outline_rounded,
                                    color: const Color(0xFFF4B400),
                                    size: 30,
                                  ),
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _reviewController,
                      maxLines: 4,
                      minLines: 3,
                      maxLength: 500,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        labelText: 'Tell us about your visit',
                        hintText:
                            'What did you enjoy? What should other visitors know?',
                        alignLabelWithHint: true,
                        filled: true,
                        fillColor: isDark
                            ? Colors.white.withValues(alpha: 0.04)
                            : const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color(0xFFE2E8F0),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: isDark
                                ? Colors.white10
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color(0xFF1E88E5),
                            width: 1.4,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if ((value ?? '').trim().isEmpty) {
                          return 'Please enter your review.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _submitting ? null : _submit,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: const Color(0xFF0B4C8C),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _submitting
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Publish review',
                                style: TextStyle(fontWeight: FontWeight.w700),
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
    );
  }
}
