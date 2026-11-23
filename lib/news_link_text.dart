import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Displays news copy as plain text while making web addresses tappable.
class NewsLinkText extends StatefulWidget {
  const NewsLinkText(
    this.text, {
    super.key,
    required this.style,
    this.maxLines,
    this.overflow,
  });

  final String text;
  final TextStyle style;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  State<NewsLinkText> createState() => _NewsLinkTextState();
}

class _NewsLinkTextState extends State<NewsLinkText> {
  static final _urlPattern = RegExp(
    r'(?:https?://|www\.)[^\s<>]+',
    caseSensitive: false,
  );
  final List<(int, int, TapGestureRecognizer)> _links = [];

  @override
  void initState() {
    super.initState();
    _findLinks();
  }

  @override
  void didUpdateWidget(covariant NewsLinkText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _disposeLinks();
      _findLinks();
    }
  }

  void _findLinks() {
    for (final match in _urlPattern.allMatches(widget.text)) {
      final matched = match.group(0)!;
      final address = matched.replaceFirst(RegExp(r'[.,;:!?\]\)}]+$'), '');
      final uri = Uri.tryParse(
        address.startsWith(RegExp(r'www\.', caseSensitive: false))
            ? 'https://$address'
            : address,
      );
      if (uri == null ||
          (uri.scheme != 'http' && uri.scheme != 'https') ||
          uri.host.isEmpty) {
        continue;
      }
      final recognizer = TapGestureRecognizer()..onTap = () => _openLink(uri);
      _links.add((match.start, match.start + address.length, recognizer));
    }
  }

  Future<void> _openLink(Uri uri) async {
    try {
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
    } catch (_) {
      // Show the same feedback when no browser can handle the address.
    }
    if (mounted) {
      ScaffoldMessenger.maybeOf(
        context,
      )?.showSnackBar(const SnackBar(content: Text('Unable to open link.')));
    }
  }

  void _disposeLinks() {
    for (final (_, _, recognizer) in _links) {
      recognizer.dispose();
    }
    _links.clear();
  }

  @override
  void dispose() {
    _disposeLinks();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spans = <TextSpan>[];
    var start = 0;
    for (final (linkStart, linkEnd, recognizer) in _links) {
      if (linkStart > start) {
        spans.add(TextSpan(text: widget.text.substring(start, linkStart)));
      }
      spans.add(
        TextSpan(
          text: widget.text.substring(linkStart, linkEnd),
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            decoration: TextDecoration.underline,
          ),
          recognizer: recognizer,
        ),
      );
      start = linkEnd;
    }
    if (start < widget.text.length) {
      spans.add(TextSpan(text: widget.text.substring(start)));
    }

    return Text.rich(
      TextSpan(children: spans),
      style: widget.style,
      maxLines: widget.maxLines,
      overflow: widget.overflow,
    );
  }
}
