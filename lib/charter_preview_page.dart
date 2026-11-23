import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class CharterPreviewPage extends StatefulWidget {
  const CharterPreviewPage({
    super.key,
    required this.name,
    required this.url,
    required this.onDownload,
  });

  final String name;
  final String url;
  final VoidCallback onDownload;

  @override
  State<CharterPreviewPage> createState() => _CharterPreviewPageState();
}

class _CharterPreviewPageState extends State<CharterPreviewPage> {
  WebViewController? _webController;
  bool _loading = true;
  String? _error;

  bool get _isImage {
    final extension = widget.name.split('.').last.toLowerCase();
    return ['png', 'jpg', 'jpeg', 'webp'].contains(extension);
  }

  @override
  void initState() {
    super.initState();
    if (_isImage) return;
    _loadDocument();
  }

  void _loadDocument() {
    final previewUrl = Uri.https('docs.google.com', '/gview', {
      'embedded': '1',
      'url': widget.url,
    });
    if (_webController != null) {
      setState(() {
        _loading = true;
        _error = null;
      });
      _webController!.loadRequest(previewUrl);
      return;
    }
    _webController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (!mounted) return;
            setState(() {
              _loading = true;
              _error = null;
            });
          },
          onPageFinished: (_) {
            if (!mounted) return;
            setState(() => _loading = false);
          },
          onWebResourceError: (error) {
            if (!mounted || error.isForMainFrame == false) return;
            setState(() {
              _loading = false;
              _error = error.description;
            });
          },
        ),
      )
      ..loadRequest(previewUrl);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: 'Download file',
            onPressed: widget.onDownload,
            icon: const Icon(Icons.download_rounded),
          ),
        ],
      ),
      body: _isImage
          ? InteractiveViewer(
              minScale: 1,
              maxScale: 4,
              child: Center(
                child: Image.network(
                  widget.url,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Center(
                    child: Text('Unable to preview this image.'),
                  ),
                ),
              ),
            )
          : Stack(
              children: [
                if (_webController != null)
                  WebViewWidget(controller: _webController!),
                if (_loading) const Center(child: CircularProgressIndicator()),
                if (_error != null)
                  ColoredBox(
                    color: scheme.surface,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.preview_outlined, size: 48),
                            const SizedBox(height: 12),
                            const Text(
                              'Unable to preview this file.',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton(
                              onPressed: _loadDocument,
                              child: const Text('Try again'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
