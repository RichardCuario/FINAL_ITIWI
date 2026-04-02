import 'package:flutter/material.dart';

import 'place_models.dart';
import 'place_service.dart';
import 'shared_widgets.dart';

class TouristGuidePage extends StatefulWidget {
  const TouristGuidePage({super.key});

  @override
  State<TouristGuidePage> createState() => _TouristGuidePageState();
}

class _TouristGuidePageState extends State<TouristGuidePage> {
  final PlaceService _placeService = PlaceService();
  late Future<List<Place>> _placesFuture;

  @override
  void initState() {
    super.initState();
    _placesFuture = _placeService.fetchPlaces();
  }

  Future<void> _refreshPlaces() async {
    final future = _placeService.fetchPlaces();
    setState(() {
      _placesFuture = future;
    });
    await future;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor =
        isDark ? theme.scaffoldBackgroundColor : const Color(0xFFEAEAEA);
    final titleColor = isDark ? Colors.white : Colors.black;
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
            height: 210,
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
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 14, 20, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(
                          Icons.arrow_back_rounded,
                          color: isDark ? Colors.white : Colors.white,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Tourist Guide',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: titleColor == Colors.black
                              ? Colors.white
                              : titleColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _refreshPlaces,
                    child: FutureBuilder<List<Place>>(
                      future: _placesFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState != ConnectionState.done) {
                          return ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                            children: const [
                              SizedBox(height: 180),
                              Center(child: CircularProgressIndicator()),
                            ],
                          );
                        }

                        final places = snapshot.data ?? const <Place>[];
                        if (places.isEmpty) {
                          return ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                            children: [
                              AppSectionCard(
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.travel_explore_rounded,
                                      size: 52,
                                      color: colorScheme.primary,
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
                                      'Pull down to refresh after places and reviews are added in Supabase.',
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }

                        return ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                          itemCount: places.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final place = places[index];
                            return _PlaceListCard(
                              place: place,
                              onTap: () async {
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
                            );
                          },
                        );
                      },
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

class _PlaceListCard extends StatelessWidget {
  const _PlaceListCard({
    required this.place,
    required this.onTap,
  });

  final Place place;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppSectionCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (place.imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(18)),
                child: Image.network(
                  place.imageUrl,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      _ImagePlaceholder(place: place),
                ),
              )
            else
              const _ImagePlaceholder(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.name,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (place.category.isNotEmpty || place.location.isNotEmpty)
                    Text(
                      [
                        if (place.category.isNotEmpty) place.category,
                        if (place.location.isNotEmpty) place.location,
                      ].join(' • '),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[700],
                      ),
                    ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      RatingStars(rating: place.averageRating),
                      const SizedBox(width: 8),
                      Text(
                        '${place.averageRating.toStringAsFixed(1)} (${place.reviewCount} reviews)',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const Spacer(),
                      const Icon(Icons.chevron_right_rounded),
                    ],
                  ),
                  if (place.description.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      place.description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({this.place});

  final Place? place;

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

    return Scaffold(
      appBar: AppBar(title: Text(place.name)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openReviewSheet,
        icon: const Icon(Icons.rate_review_rounded),
        label: const Text('Write Review'),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshReviews,
        child: FutureBuilder<List<PlaceReview>>(
          future: _reviewsFuture,
          builder: (context, snapshot) {
            final reviews = snapshot.data ?? const <PlaceReview>[];
            final average = reviews.isEmpty
                ? place.averageRating
                : reviews.fold<int>(0, (sum, item) => sum + item.rating) /
                    reviews.length;
            final reviewCount =
                reviews.isEmpty ? place.reviewCount : reviews.length;

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                AppSectionCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (place.imageUrl.isNotEmpty)
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(18),
                          ),
                          child: Image.network(
                            place.imageUrl,
                            height: 220,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const _ImagePlaceholder(),
                          ),
                        )
                      else
                        const _ImagePlaceholder(),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              place.name,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (place.category.isNotEmpty ||
                                place.location.isNotEmpty)
                              Text(
                                [
                                  if (place.category.isNotEmpty) place.category,
                                  if (place.location.isNotEmpty)
                                    place.location,
                                ].join(' • '),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[700],
                                ),
                              ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                RatingStars(rating: average, size: 22),
                                const SizedBox(width: 10),
                                Text(
                                  '${average.toStringAsFixed(1)} average • $reviewCount review${reviewCount == 1 ? '' : 's'}',
                                  style: theme.textTheme.titleMedium,
                                ),
                              ],
                            ),
                            if (place.description.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Text(place.description),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Visitor Reviews',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                if (snapshot.connectionState != ConnectionState.done)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (reviews.isEmpty)
                  AppSectionCard(
                    child: const Text(
                      'No reviews yet. Be the first to share your experience.',
                    ),
                  )
                else
                  ...reviews.map(
                    (review) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AppSectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    review.reviewerName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Text(
                                  _formatDate(review.createdAt),
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            RatingStars(
                              rating: review.rating.toDouble(),
                              size: 18,
                            ),
                            if (review.reviewText.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Text(review.reviewText),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  static String _formatDate(DateTime? date) {
    if (date == null) {
      return 'Recently';
    }
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
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

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + viewInsets.bottom),
      child: Form(
        key: _formKey,
        child: Wrap(
          children: [
            Text(
              'Review ${widget.place.name}',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('Your rating'),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: List.generate(5, (index) {
                final star = index + 1;
                return IconButton(
                  onPressed: _submitting
                      ? null
                      : () {
                          setState(() {
                            _selectedRating = star;
                          });
                        },
                  icon: Icon(
                    star <= _selectedRating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: Colors.amber,
                    size: 34,
                  ),
                );
              }),
            ),
            TextFormField(
              controller: _reviewController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Your review',
                hintText: 'Share what visitors should know about this place.',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if ((value ?? '').trim().isEmpty) {
                  return 'Please enter your review.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Submit Review'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
