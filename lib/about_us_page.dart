import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'charter_preview_page.dart';

class AboutUsPage extends StatefulWidget {
  const AboutUsPage({super.key});

  @override
  State<AboutUsPage> createState() => _AboutUsPageState();
}

class _AboutUsPageState extends State<AboutUsPage> {
  late Future<Map<String, dynamic>?> _profile;

  @override
  void initState() {
    super.initState();
    _profile = _load();
  }

  Future<Map<String, dynamic>?> _load() => Supabase.instance.client
      .from('municipal_profile')
      .select(
        'vision,mission,vision_mission,history,history_image_path,geography,geography_image_path,citizens_charter_files,officials',
      )
      .eq('id', 1)
      .maybeSingle();

  void _refresh() => setState(() => _profile = _load());

  Future<void> _openCharterFile(Map file, {required bool download}) async {
    final path = file['path']?.toString() ?? '';
    final name = file['name']?.toString() ?? 'Citizen Charter file';
    if (!path.startsWith('charter/') || path.contains('..')) {
      _showFileError();
      return;
    }
    try {
      final publicUrl = Supabase.instance.client.storage
          .from('municipal-charter')
          .getPublicUrl(path);
      if (!download) {
        if (!mounted) return;
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => CharterPreviewPage(
              name: name,
              url: publicUrl,
              onDownload: () => _openCharterFile(file, download: true),
            ),
          ),
        );
        return;
      }
      final uri = Uri.parse(publicUrl);
      final target = uri.replace(
        queryParameters: {...uri.queryParameters, 'download': name},
      );
      if (!await launchUrl(target, mode: LaunchMode.externalApplication) &&
          mounted) {
        _showFileError();
      }
    } catch (_) {
      if (mounted) _showFileError();
    }
  }

  void _showFileError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Unable to open this Charter file.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final pageColor = dark ? const Color(0xFF101923) : Colors.white;

    return Scaffold(
      backgroundColor: pageColor,
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _profile,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return SafeArea(
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      tooltip: 'Back',
                      onPressed: () => Navigator.maybePop(context),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                  ),
                  const Spacer(),
                  const Text('Could not load About Us.'),
                  TextButton(
                    onPressed: _refresh,
                    child: const Text('Try again'),
                  ),
                  const Spacer(),
                ],
              ),
            );
          }

          final data = snapshot.data ?? <String, dynamic>{};
          final charterFiles = data['citizens_charter_files'] is List
              ? (data['citizens_charter_files'] as List)
                    .whereType<Map>()
                    .toList()
              : <Map>[];
          final savedOfficials = data['officials'] is List
              ? (data['officials'] as List).whereType<Map>().toList()
              : <Map>[];
          bool isMayor(Map official) {
            final position =
                official['position']?.toString().toLowerCase() ?? '';
            return position.contains('mayor') && !position.contains('vice');
          }

          final officials = [
            ...savedOfficials.where(isMayor),
            ...savedOfficials.where((official) => !isMayor(official)),
          ];
          String contentFor(String key) {
            final value = data[key]?.toString().trim() ?? '';
            if (value.isNotEmpty) return value;
            if (key == 'vision') {
              final previous = data['vision_mission']?.toString().trim() ?? '';
              if (previous.isNotEmpty) return previous;
            }
            return 'Information will be available soon.';
          }

          String? imageUrlFor(String key) {
            final path = data['${key}_image_path']?.toString().trim() ?? '';
            if (!path.startsWith('$key/') || path.contains('..')) return null;
            return Supabase.instance.client.storage
                .from('municipal-profile-images')
                .getPublicUrl(path);
          }

          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle.light.copyWith(
              statusBarColor: Colors.transparent,
              systemStatusBarContrastEnforced: false,
            ),
            child: RefreshIndicator(
              onRefresh: () async {
                _refresh();
                await _profile;
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Stack(
                      children: [
                        Image.asset(
                          'assets/optimized/municipal_hall.jpg',
                          width: double.infinity,
                          fit: BoxFit.fitWidth,
                          semanticLabel: 'Tiwi Municipal Hall',
                        ),
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          height: MediaQuery.viewPaddingOf(context).top + 56,
                          child: const IgnorePointer(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [Colors.black54, Colors.transparent],
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: MediaQuery.viewPaddingOf(context).top + 8,
                          left: 12,
                          child: IconButton.filled(
                            tooltip: 'Back',
                            onPressed: () => Navigator.maybePop(context),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black54,
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.arrow_back_rounded),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SafeArea(
                      top: false,
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 800),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _AboutTextSection(
                                  title: 'Vision',
                                  body: contentFor('vision'),
                                ),
                                const _SectionBreak(),
                                _AboutTextSection(
                                  title: 'Mission',
                                  body: contentFor('mission'),
                                ),
                                const _SectionBreak(),
                                _AboutStorySection(
                                  title: 'History of Tiwi',
                                  body: contentFor('history'),
                                  imageUrl: imageUrlFor('history'),
                                  dark: dark,
                                ),
                                const _SectionBreak(),
                                _AboutStorySection(
                                  title: 'Geography',
                                  body: contentFor('geography'),
                                  imageUrl: imageUrlFor('geography'),
                                  dark: dark,
                                ),
                                const _SectionBreak(),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const _SectionHeading(
                                      title: "Citizen's Charter",
                                    ),
                                    const SizedBox(height: 20),
                                    if (charterFiles.isEmpty)
                                      const _AboutEmptyText(
                                        'No Charter files available yet.',
                                      ),
                                    for (final file in charterFiles) ...[
                                      _CharterFileRow(
                                        file: file,
                                        onView: () => _openCharterFile(
                                          file,
                                          download: false,
                                        ),
                                        onDownload: () => _openCharterFile(
                                          file,
                                          download: true,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                    ],
                                  ],
                                ),
                                const _SectionBreak(),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const _SectionHeading(
                                      title:
                                          'Officials of the Municipality of Tiwi',
                                    ),
                                    const SizedBox(height: 20),
                                    if (officials.isEmpty)
                                      const _AboutEmptyText(
                                        'No officials listed yet.',
                                      ),
                                    for (final official in officials) ...[
                                      _OfficialRow(
                                        official: official,
                                        isMayor: isMayor(official),
                                        dark: dark,
                                      ),
                                      const SizedBox(height: 8),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        height: 1.25,
      ),
    ),
  );
}

class _AboutTextSection extends StatelessWidget {
  const _AboutTextSection({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _SectionHeading(title: title),
      const SizedBox(height: 14),
      Text(
        body,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontSize: 15,
          height: 1.7,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    ],
  );
}

class _AboutStorySection extends StatelessWidget {
  const _AboutStorySection({
    required this.title,
    required this.body,
    required this.imageUrl,
    required this.dark,
  });

  final String title;
  final String body;
  final String? imageUrl;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeading(title: title),
        const SizedBox(height: 16),
        if (imageUrl != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              imageUrl!,
              fit: BoxFit.fitWidth,
              width: double.infinity,
              semanticLabel: '$title image',
              errorBuilder: (_, _, _) => ColoredBox(
                color: dark ? const Color(0xFF263644) : const Color(0xFFE9EDF0),
                child: const SizedBox(
                  height: 120,
                  child: Center(
                    child: Icon(Icons.image_not_supported_outlined),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
        ],
        Text(
          body,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            height: 1.7,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}

class _AboutEmptyText extends StatelessWidget {
  const _AboutEmptyText(this.message);
  final String message;

  @override
  Widget build(BuildContext context) => Text(
    message,
    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
  );
}

class _CharterFileRow extends StatelessWidget {
  const _CharterFileRow({
    required this.file,
    required this.onView,
    required this.onDownload,
  });

  final Map file;
  final VoidCallback onView;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final name = file['name']?.toString().trim() ?? 'Charter document';
    final extension = name.contains('.')
        ? name.split('.').last.toUpperCase()
        : 'FILE';
    final fileIcon = switch (extension) {
      'PDF' => Icons.picture_as_pdf_rounded,
      'DOC' || 'DOCX' => Icons.description_rounded,
      'XLS' || 'XLSX' => Icons.table_chart_rounded,
      'PNG' || 'JPG' || 'JPEG' || 'WEBP' => Icons.image_rounded,
      _ => Icons.insert_drive_file_rounded,
    };
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 32,
                child: Icon(
                  fileIcon,
                  color: dark
                      ? const Color(0xFF79C6F3)
                      : const Color(0xFF087BE0),
                  size: 25,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      extension,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: onView,
                icon: const Icon(Icons.visibility_outlined, size: 18),
                label: const Text('Preview'),
              ),
              FilledButton.icon(
                onPressed: onDownload,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF087BE0),
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.download_rounded, size: 18),
                label: const Text('Download'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OfficialRow extends StatelessWidget {
  const _OfficialRow({
    required this.official,
    required this.isMayor,
    required this.dark,
  });

  final Map official;
  final bool isMayor;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: SizedBox(
              width: isMayor ? 78 : 64,
              height: isMayor ? 78 : 64,
              child: _OfficialImage(url: official['image_url']?.toString()),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  official['name']?.toString() ?? '',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  official['position']?.toString() ?? '',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isMayor
                        ? dark
                              ? const Color(0xFF79C6F3)
                              : const Color(0xFF087BE0)
                        : scheme.onSurfaceVariant,
                    fontWeight: isMayor ? FontWeight.w700 : null,
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

class _OfficialImage extends StatelessWidget {
  const _OfficialImage({this.url});
  final String? url;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fallback = ColoredBox(
      color: dark ? const Color(0xFF263746) : const Color(0xFFE6ECEF),
      child: Center(
        child: Icon(
          Icons.person,
          size: 38,
          color: dark ? const Color(0xFF79C6F3) : const Color(0xFF087BE0),
        ),
      ),
    );
    if (url == null || url!.isEmpty) return fallback;
    return Image.network(
      url!,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => fallback,
    );
  }
}

class _SectionBreak extends StatelessWidget {
  const _SectionBreak();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 28),
    child: Divider(
      height: 1,
      color: Theme.of(
        context,
      ).colorScheme.outlineVariant.withValues(alpha: 0.5),
    ),
  );
}
