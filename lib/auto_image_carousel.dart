import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AutoImageCarousel extends StatefulWidget {
  const AutoImageCarousel({
    super.key,
    required this.urls,
    required this.placeholder,
    this.interval = const Duration(seconds: 4),
    this.indicatorBottom = 12,
  });

  final List<String> urls;
  final Widget placeholder;
  final Duration interval;
  final double indicatorBottom;

  @override
  State<AutoImageCarousel> createState() => _AutoImageCarouselState();
}

class _AutoImageCarouselState extends State<AutoImageCarousel> {
  final PageController _controller = PageController();
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant AutoImageCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (listEquals(oldWidget.urls, widget.urls) &&
        oldWidget.interval == widget.interval) {
      return;
    }
    _timer?.cancel();
    _index = 0;
    if (_controller.hasClients) _controller.jumpToPage(0);
    _startTimer();
  }

  void _startTimer() {
    if (widget.urls.length < 2) return;
    _timer = Timer.periodic(widget.interval, (_) {
      if (!mounted || !_controller.hasClients) return;
      _controller.animateToPage(
        (_index + 1) % widget.urls.length,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.urls.isEmpty) return widget.placeholder;
    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          controller: _controller,
          itemCount: widget.urls.length,
          onPageChanged: (index) => setState(() => _index = index),
          itemBuilder: (context, index) => Semantics(
            button: true,
            label: 'View image ${index + 1} full screen',
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => _FullScreenImageGallery(
                    urls: widget.urls,
                    initialIndex: index,
                  ),
                ),
              ),
              child: Image.network(
                widget.urls[index],
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                cacheWidth: 1200,
                errorBuilder: (_, _, _) => widget.placeholder,
              ),
            ),
          ),
        ),
        if (widget.urls.length > 1)
          Positioned(
            bottom: widget.indicatorBottom,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < widget.urls.length; i++)
                  Container(
                    width: i == _index ? 16 : 7,
                    height: 7,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: i == _index ? Colors.white : Colors.white70,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: const [
                        BoxShadow(color: Colors.black45, blurRadius: 3),
                      ],
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _FullScreenImageGallery extends StatefulWidget {
  const _FullScreenImageGallery({
    required this.urls,
    required this.initialIndex,
  });

  final List<String> urls;
  final int initialIndex;

  @override
  State<_FullScreenImageGallery> createState() =>
      _FullScreenImageGalleryState();
}

class _FullScreenImageGalleryState extends State<_FullScreenImageGallery> {
  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _controller = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: widget.urls.length,
              onPageChanged: (index) => setState(() => _index = index),
              itemBuilder: (context, index) => Center(
                child: Image.network(
                  widget.urls[index],
                  fit: BoxFit.contain,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (_, _, _) => const Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white70,
                    size: 64,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              left: 8,
              child: IconButton(
                tooltip: 'Close image',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ),
            if (widget.urls.length > 1)
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    '${_index + 1} / ${widget.urls.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
