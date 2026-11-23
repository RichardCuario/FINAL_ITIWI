import 'package:flutter/material.dart';

class PolicySection {
  const PolicySection(this.title, this.body);
  final String title;
  final String body;
}

/// Shared reading layout for the app's terms and compliance documents.
class PolicyDocumentPage extends StatefulWidget {
  const PolicyDocumentPage({
    super.key,
    required this.title,
    required this.heading,
    required this.introduction,
    required this.icon,
    required this.highlights,
    required this.sections,
    this.footer,
  });

  final String title;
  final String heading;
  final String introduction;
  final IconData icon;
  final List<String> highlights;
  final List<PolicySection> sections;
  final Widget? footer;

  @override
  State<PolicyDocumentPage> createState() => _PolicyDocumentPageState();
}

class _PolicyDocumentPageState extends State<PolicyDocumentPage> {
  late List<GlobalKey> _anchors;

  @override
  void initState() {
    super.initState();
    _anchors = List.generate(widget.sections.length, (_) => GlobalKey());
  }

  @override
  void didUpdateWidget(covariant PolicyDocumentPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sections.length != widget.sections.length) {
      _anchors = List.generate(widget.sections.length, (_) => GlobalKey());
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final background = dark ? const Color(0xFF101820) : const Color(0xFFF2F7FC);
    final surface = dark ? const Color(0xFF18232D) : Colors.white;
    final ink = dark ? const Color(0xFFEDF2F6) : const Color(0xFF102B50);
    final muted = dark ? const Color(0xFFABB9C5) : const Color(0xFF566773);
    final accent = dark ? const Color(0xFF91C8F5) : const Color(0xFF165D91);
    final line = dark ? const Color(0xFF30404D) : const Color(0xFFDDE6EF);
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: background,
        foregroundColor: ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      body: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: dark
                            ? const [Color(0xFF172638), Color(0xFF203D59)]
                            : const [Color(0xFFF8FBFF), Color(0xFFDDEEFF)],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(widget.icon, size: 34, color: accent),
                        const SizedBox(height: 16),
                        Text(
                          widget.heading,
                          style: TextStyle(
                            color: ink,
                            fontSize: 30,
                            height: 1.15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.7,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.introduction,
                          style: TextStyle(
                            color: muted,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'At a glance',
                    style: TextStyle(
                      color: ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (final highlight in widget.highlights)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Icon(Icons.circle, size: 7, color: accent),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              highlight,
                              style: TextStyle(color: muted, height: 1.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),
                  PopupMenuButton<int>(
                    tooltip: 'Jump to a section',
                    onSelected: (index) {
                      final target = _anchors[index].currentContext;
                      if (target != null) {
                        Scrollable.ensureVisible(
                          target,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        );
                      }
                    },
                    itemBuilder: (_) => [
                      for (var i = 0; i < widget.sections.length; i++)
                        PopupMenuItem(
                          value: i,
                          child: Text(widget.sections[i].title),
                        ),
                    ],
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: line),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.toc_rounded, color: accent),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Jump to a section',
                              style: TextStyle(
                                color: ink,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Icon(Icons.expand_more, color: accent),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: line),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < widget.sections.length; i++) ...[
                          if (i > 0) Divider(height: 1, color: line),
                          Padding(
                            key: _anchors[i],
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${(i + 1).toString().padLeft(2, '0')}  /',
                                  style: TextStyle(
                                    color: accent,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Semantics(
                                  header: true,
                                  child: Text(
                                    widget.sections[i].title,
                                    style: TextStyle(
                                      color: ink,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SelectableText(
                                  widget.sections[i].body,
                                  style: TextStyle(
                                    color: muted,
                                    height: 1.65,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (widget.footer != null) ...[
                    const SizedBox(height: 20),
                    widget.footer!,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
