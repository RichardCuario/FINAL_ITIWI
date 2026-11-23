import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'content_cache_service.dart';

Uint8List? decodeDataUriToBytes(String source) {
  if (!source.startsWith('data:')) return null;

  final uri = Uri.tryParse(source);
  final data = uri?.data;
  if (data == null) return null;

  return data.contentAsBytes();
}

class HotlinePage extends StatefulWidget {
  const HotlinePage({super.key, this.loadHotlines});

  final Future<List<Map<String, dynamic>>> Function()? loadHotlines;

  @override
  State<HotlinePage> createState() => _HotlinePageState();
}

class _HotlinePageState extends State<HotlinePage> {
  final _cache = const ContentCacheService();
  final _search = TextEditingController();
  List<Map<String, dynamic>> _hotlines = [];
  String? _category;
  bool _refreshing = true;
  bool _refreshFailed = false;

  bool get _dark => Theme.of(context).brightness == Brightness.dark;
  Color get _ink => _dark ? const Color(0xFFF0F4F8) : const Color(0xFF101D49);
  Color get _muted => _dark ? const Color(0xFFACBACA) : const Color(0xFF6B7792);
  Color get _surface => _dark ? const Color(0xFF192735) : Colors.white;
  Color get _line => _dark ? const Color(0xFF314252) : const Color(0xFFE0E7EE);
  Color get _blue => _dark ? const Color(0xFF9ECFFF) : const Color(0xFF0669E8);

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final cached = await _cache.getHotlines();
      if (!mounted) return;
      if (cached.hasData) {
        setState(() {
          _hotlines = _normalize(cached.items);
        });
      }
    } catch (_) {
      // Storage failures must not prevent loading the directory.
    }
    if (mounted) await _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _refreshing = true;
      _refreshFailed = false;
    });
    try {
      final loader = widget.loadHotlines;
      final data =
          await (loader != null
                  ? loader()
                  : Supabase.instance.client
                        .from('hotlines')
                        .select()
                        .order('created_at', ascending: false))
              .timeout(const Duration(seconds: 15));
      final contacts = _normalize(data);
      if (!mounted) return;
      setState(() {
        _hotlines = contacts;
        _refreshing = false;
        if (!_hotlines.any((item) => item['category'] == _category)) {
          _category = null;
        }
      });
      // Saving contacts is best effort; it does not change the fetch result.
      try {
        await _cache.saveHotlines(contacts);
      } catch (_) {}
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _refreshing = false;
        _refreshFailed = true;
      });
    }
  }

  List<String> _numbers(Map<String, dynamic> item) {
    final raw = item['phone_numbers'];
    final values = raw is List
        ? raw
        : raw is String
        ? raw.split(',')
        : const [];
    final numbers = values
        .whereType<String>()
        .map((number) => number.trim())
        .where((number) => number.isNotEmpty)
        .toSet()
        .toList();
    if (numbers.isNotEmpty) return numbers;
    final fallback = item['hotline_number'] ?? item['phone_number'];
    return fallback is String && fallback.trim().isNotEmpty
        ? [fallback.trim()]
        : [];
  }

  String _categoryName(dynamic value) {
    final category = value?.toString().trim() ?? '';
    final key = category.toLowerCase();
    if (key.isEmpty) return 'General';
    if (key.contains('emergency')) return 'Emergency';
    if (key.contains('fire')) return 'Fire & Rescue';
    if (key.contains('police') || key.contains('law enforcement')) {
      return 'Law Enforcement';
    }
    if (key.contains('health') || key.contains('medical')) return 'Health';
    if (key.contains('disaster')) return 'Disaster Management';
    if (key.contains('public safety')) return 'Public Safety';
    if (key.contains('local government')) return 'Local Government';
    return category;
  }

  List<Map<String, dynamic>> _normalize(List<Map<String, dynamic>> items) {
    final seen = <String>{};
    final contacts = <Map<String, dynamic>>[];
    for (final item in items) {
      // 911 has a permanent action, including before the network loads.
      if (item['id'] == 'hardcoded_911') continue;
      final numbers = _numbers(item);
      final name =
          (item['name'] ?? item['department'] ?? item['agency'] ?? 'Hotline')
              .toString()
              .trim();
      if (name == '911' && numbers.length == 1 && numbers.single == '911') {
        continue;
      }
      final key = item['id']?.toString() ?? '$name|${numbers.join('|')}';
      if (!seen.add(key)) continue;
      contacts.add({
        ...item,
        'name': name.isEmpty ? 'Hotline' : name,
        'category': _categoryName(item['category']),
        'description': (item['description'] ?? item['details'] ?? '')
            .toString()
            .trim(),
        'phone_numbers': numbers,
      });
    }
    contacts.sort((a, b) {
      final rank = _rank(a['category']).compareTo(_rank(b['category']));
      if (rank != 0) return rank;
      final category = (a['category'] as String).compareTo(
        b['category'] as String,
      );
      return category != 0
          ? category
          : '${a['name']}'.toLowerCase().compareTo(
              '${b['name']}'.toLowerCase(),
            );
    });
    return contacts;
  }

  int _rank(String category) => switch (category) {
    'Emergency' => 0,
    'Fire & Rescue' => 1,
    'Law Enforcement' => 2,
    'Health' => 3,
    'Disaster Management' => 4,
    'Public Safety' => 5,
    _ => 6,
  };

  IconData _icon(String category) => switch (category) {
    'Emergency' => Icons.emergency_outlined,
    'Fire & Rescue' => Icons.local_fire_department_outlined,
    'Law Enforcement' => Icons.local_police_outlined,
    'Health' => Icons.local_hospital_outlined,
    'Disaster Management' => Icons.flood_outlined,
    'Public Safety' => Icons.health_and_safety_outlined,
    'Local Government' => Icons.account_balance_outlined,
    _ => Icons.support_agent_rounded,
  };

  Future<void> _call(String number) async {
    final dialable = number.replaceAll(RegExp(r'[^0-9+]'), '');
    try {
      if (dialable.isNotEmpty &&
          await launchUrl(Uri(scheme: 'tel', path: dialable))) {
        return;
      }
    } catch (_) {
      // Devices without a dialer still offer a way to use the number.
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Could not open the dialer. You can copy $number instead.',
        ),
        action: SnackBarAction(label: 'Copy', onPressed: () => _copy(number)),
      ),
    );
  }

  Future<void> _copy(String number) async {
    try {
      await Clipboard.setData(ClipboardData(text: number));
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Copied $number')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not copy the number. Please try again.'),
        ),
      );
    }
  }

  void _resetFilters() {
    _search.clear();
    setState(() => _category = null);
  }

  BoxDecoration _cardDecoration() => BoxDecoration(
    color: _surface,
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: _dark ? _line : Colors.white),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: _dark ? 0.10 : 0.035),
        blurRadius: 24,
        offset: const Offset(0, 8),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim().toLowerCase();
    final categories =
        _hotlines.map((item) => item['category'] as String).toSet().toList()
          ..sort((a, b) {
            final rank = _rank(a).compareTo(_rank(b));
            return rank != 0 ? rank : a.compareTo(b);
          });
    final visible = _hotlines.where((item) {
      final text =
          '${item['name']} ${item['description']} ${item['category']} ${_numbers(item).join(' ')}'
              .toLowerCase();
      final digits = query.replaceAll(RegExp(r'\D'), '');
      final phoneMatch =
          digits.isNotEmpty &&
          RegExp(r'^[+\d\s()\-]+$').hasMatch(query) &&
          _numbers(item).any(
            (number) => number.replaceAll(RegExp(r'\D'), '').contains(digits),
          );
      return (_category == null || _category == item['category']) &&
          (text.contains(query) || phoneMatch);
    }).toList();
    final background = _dark
        ? const Color(0xFF101B26)
        : const Color(0xFFF0F5FB);

    return Scaffold(
      backgroundColor: background,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: SafeArea(
          top: false,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: RefreshIndicator(
                onRefresh: () async {
                  if (!_refreshing) await _refresh();
                },
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  slivers: [
                    SliverToBoxAdapter(child: _header(background)),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              controller: _search,
                              onChanged: (_) => setState(() {}),
                              style: TextStyle(color: _ink),
                              textInputAction: TextInputAction.search,
                              onSubmitted: (_) =>
                                  FocusScope.of(context).unfocus(),
                              decoration: InputDecoration(
                                hintText: 'Search name, service or number',
                                hintStyle: TextStyle(
                                  color: _muted,
                                  fontSize: 14,
                                ),
                                prefixIcon: Icon(
                                  Icons.search_rounded,
                                  color: _muted,
                                ),
                                suffixIcon: _search.text.isEmpty
                                    ? null
                                    : IconButton(
                                        tooltip: 'Clear search',
                                        onPressed: () {
                                          _search.clear();
                                          setState(() {});
                                        },
                                        icon: const Icon(Icons.close_rounded),
                                      ),
                                filled: true,
                                fillColor: _surface,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 17,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: _line),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: _line),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: _blue,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            _filterChip(null),
                            ...categories.expand(
                              (category) => [
                                const SizedBox(width: 8),
                                _filterChip(category),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (visible.isEmpty)
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        sliver: SliverToBoxAdapter(
                          child: _emptyState(
                            query.isNotEmpty || _category != null,
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        sliver: SliverList.builder(
                          itemCount: visible.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _contactCard(visible[index]),
                            );
                          },
                        ),
                      ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                      sliver: SliverToBoxAdapter(child: _callGuide()),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(Color background) => Stack(
    children: [
      Positioned.fill(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _dark
                  ? const [Color(0xFF0753B4), Color(0xFF18385A)]
                  : const [Color(0xFF0060E6), Color(0xFF39A5F8)],
            ),
          ),
        ),
      ),
      Positioned.fill(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                const Color(0xFF0061E4).withValues(alpha: 0.95),
                const Color(0xFF0676EA).withValues(alpha: 0.18),
              ],
            ),
          ),
        ),
      ),
      Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        height: 110,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [background.withValues(alpha: 0), background],
            ),
          ),
        ),
      ),
      Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          MediaQuery.paddingOf(context).top + 24,
          16,
          0,
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  tooltip: 'Back',
                  onPressed: () => Navigator.maybePop(context),
                  style: IconButton.styleFrom(
                    foregroundColor: Colors.white,
                    minimumSize: const Size(48, 48),
                  ),
                  icon: const Icon(Icons.arrow_back),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(top: 3),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Emergency Hotlines',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 23,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Get immediate assistance from\nTiwi emergency services.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 26),
            _emergencyCard(),
          ],
        ),
      ),
    ],
  );

  Widget _emergencyCard() => Container(
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFF7478), Color(0xFFE52C42), Color(0xFFFF4653)],
        stops: [0, 0.65, 1],
      ),
      borderRadius: BorderRadius.circular(26),
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.50),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFFEB3A50).withValues(alpha: 0.20),
          blurRadius: 24,
          offset: const Offset(0, 12),
        ),
      ],
    ),
    child: Stack(
      children: [
        Positioned(
          right: 88,
          top: 8,
          child: ExcludeSemantics(
            child: Icon(
              Icons.notifications_active_rounded,
              size: 96,
              color: Colors.white.withValues(alpha: 0.09),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final largeText = MediaQuery.textScalerOf(context).scale(14) > 19;
              final compact = constraints.maxWidth < 310 || largeText;
              final badge = Container(
                width: 58,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(19),
                  border: Border.all(color: const Color(0xFFFFB7BD), width: 4),
                ),
                child: const Icon(
                  Icons.call_rounded,
                  color: Color(0xFFED2942),
                  size: 30,
                ),
              );
              final details = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '911',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      height: 1,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'EMERGENCY HOTLINE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'For immediate assistance in life-threatening situations.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ],
              );
              final call = FilledButton.icon(
                onPressed: () => _call('911'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.20),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 52),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.35)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                icon: const Icon(Icons.call_rounded, size: 21),
                label: const Text(
                  'Call 911',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
              );
              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        badge,
                        const SizedBox(width: 14),
                        Expanded(child: details),
                      ],
                    ),
                    const SizedBox(height: 14),
                    call,
                  ],
                );
              }
              return Row(
                children: [
                  badge,
                  const SizedBox(width: 12),
                  Expanded(child: details),
                  Container(
                    height: 78,
                    width: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                  call,
                ],
              );
            },
          ),
        ),
      ],
    ),
  );

  Color _serviceColor(String category) =>
      ['Emergency', 'Fire & Rescue', 'Health'].contains(category)
      ? (_dark ? const Color(0xFFFF95A2) : const Color(0xFFE32745))
      : _blue;

  Widget _filterChip(String? category) {
    final selected = _category == category;
    final foreground = selected
        ? (_dark ? const Color(0xFF101D49) : Colors.white)
        : _muted;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        selected: selected,
        showCheckmark: false,
        avatar: category == null
            ? null
            : Icon(_icon(category), size: 17, color: foreground),
        label: Text(category ?? 'All services'),
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
        selectedColor: _dark
            ? const Color(0xFF9ECFFF)
            : const Color(0xFF086BEC),
        backgroundColor: _surface,
        side: BorderSide(color: selected ? Colors.transparent : _line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        onSelected: (_) => setState(() => _category = category),
      ),
    );
  }

  Widget _contactCard(Map<String, dynamic> item) {
    final category = item['category'] as String;
    final description = item['description'] as String;
    String? logo;
    for (final key in ['logo_url', 'logo', 'image_url', 'image', 'icon_url']) {
      final value = item[key];
      if (value is String && value.trim().isNotEmpty) {
        logo = value.trim();
        break;
      }
    }
    final color = _serviceColor(category);
    final fallback = Icon(_icon(category), size: 27, color: color);
    final numbers = _numbers(item);
    final location = (item['location'] ?? item['address'] ?? '')
        .toString()
        .trim();
    return Container(
      decoration: _cardDecoration(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: logo == null
                    ? fallback
                    : ClipOval(child: _logoImage(logo, fallback: fallback)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['name'] as String,
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.3,
                        fontWeight: FontWeight.w800,
                        color: _ink,
                      ),
                    ),
                    if (location.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.location_on_rounded,
                              size: 16,
                              color: _muted,
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                location,
                                style: TextStyle(
                                  color: _muted,
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (description.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          description,
                          style: TextStyle(
                            color: _muted,
                            fontSize: 12,
                            height: 1.5,
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.09),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        category,
                        style: TextStyle(
                          color: color,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (numbers.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Text(
                'No phone number listed',
                style: TextStyle(color: _muted, fontSize: 13),
              ),
            )
          else
            ...numbers.map(
              (number) => _phoneRow(number, item['name'] as String),
            ),
        ],
      ),
    );
  }

  Widget _phoneRow(String number, String name) => Container(
    margin: const EdgeInsets.only(top: 12),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: _dark ? const Color(0xFF152D46) : const Color(0xFFF2F8FF),
      border: Border.all(color: _dark ? _line : const Color(0xFFDCEBFF)),
      borderRadius: BorderRadius.circular(16),
    ),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final stacked =
            constraints.maxWidth < 260 ||
            MediaQuery.textScalerOf(context).scale(14) > 20;
        final phone = Text(
          number,
          style: TextStyle(
            color: _ink,
            fontSize: 15,
            fontWeight: FontWeight.w800,
            height: 1.4,
          ),
        );
        final copy = _circleAction(
          tooltip: 'Copy $number',
          icon: Icons.copy_rounded,
          color: _dark ? const Color(0xFF9BCBFF) : const Color(0xFF006AED),
          background: _dark ? const Color(0xFF254666) : const Color(0xFFDCEEFF),
          onPressed: () => _copy(number),
        );
        final call = _circleAction(
          tooltip: 'Call $name at $number',
          icon: Icons.call_rounded,
          color: _dark ? const Color(0xFF94F0CA) : const Color(0xFF008C5E),
          background: _dark ? const Color(0xFF204C40) : const Color(0xFFB6F0D9),
          onPressed: () => _call(number),
        );
        if (stacked) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              phone,
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [copy, const SizedBox(width: 8), call],
              ),
            ],
          );
        }
        return Row(
          children: [
            Icon(Icons.call_rounded, size: 21, color: _blue),
            const SizedBox(width: 10),
            Expanded(child: phone),
            const SizedBox(width: 6),
            copy,
            const SizedBox(width: 6),
            call,
          ],
        );
      },
    ),
  );

  Widget _circleAction({
    required String tooltip,
    required IconData icon,
    required Color color,
    required Color background,
    required VoidCallback onPressed,
  }) => IconButton.filled(
    tooltip: tooltip,
    onPressed: onPressed,
    style: IconButton.styleFrom(
      backgroundColor: background,
      foregroundColor: color,
      minimumSize: const Size(48, 48),
      side: BorderSide(color: _dark ? _line : Colors.white, width: 2),
    ),
    icon: Icon(icon, size: 23),
  );

  Widget _logoImage(String source, {required Widget fallback}) {
    final bytes = decodeDataUriToBytes(source);
    if (bytes != null) {
      return Image.memory(
        bytes,
        fit: BoxFit.contain,
        excludeFromSemantics: true,
        errorBuilder: (context, error, stackTrace) => fallback,
      );
    }

    return Image.network(
      source,
      fit: BoxFit.contain,
      excludeFromSemantics: true,
      errorBuilder: (context, error, stackTrace) => fallback,
    );
  }

  Widget _emptyState(bool filtered) => Container(
    padding: const EdgeInsets.all(24),
    decoration: _cardDecoration(),
    child: Column(
      children: [
        Icon(
          filtered ? Icons.search_off_rounded : Icons.contact_phone_outlined,
          size: 34,
          color: _muted,
        ),
        const SizedBox(height: 12),
        Text(
          filtered
              ? 'No matching contacts'
              : _refreshing
              ? 'Loading local contacts…'
              : _refreshFailed
              ? 'Directory unavailable'
              : 'No local contacts yet',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: _ink,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          filtered
              ? 'Try another name or number, or browse all services.'
              : 'The 911 call button is available above.',
          textAlign: TextAlign.center,
          style: TextStyle(color: _muted, fontSize: 13, height: 1.5),
        ),
        if (filtered)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: TextButton(
              onPressed: _resetFilters,
              child: const Text('Show all contacts'),
            ),
          ),
      ],
    ),
  );

  Widget _callGuide() => Container(
    decoration: BoxDecoration(
      color: _dark ? const Color(0xFF1B2D3D) : const Color(0xFFE8EFF6),
      borderRadius: BorderRadius.circular(18),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    child: Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 16),
        leading: Icon(Icons.info_outline_rounded, color: _blue, size: 22),
        iconColor: _muted,
        collapsedIconColor: _muted,
        title: Text(
          'When you call',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: _ink,
          ),
        ),
        children: [
          Text(
            'Be ready to share your location, what happened, and a number where you can be reached. Follow the operator’s instructions.',
            style: TextStyle(color: _muted, fontSize: 13, height: 1.6),
          ),
          const SizedBox(height: 10),
          Text(
            'Saved contacts can be viewed offline. Calls still need phone service.',
            style: TextStyle(color: _muted, fontSize: 12, height: 1.5),
          ),
        ],
      ),
    ),
  );
}
