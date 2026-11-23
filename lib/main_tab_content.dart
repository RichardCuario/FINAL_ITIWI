import 'package:flutter/material.dart';

/// Keeps visited tabs mounted while the navigation bar stays in place.
class MainTabContent extends StatefulWidget {
  const MainTabContent({
    super.key,
    required this.currentIndex,
    required this.builders,
  });

  final int currentIndex;
  final List<WidgetBuilder> builders;

  @override
  State<MainTabContent> createState() => _MainTabContentState();
}

class _MainTabContentState extends State<MainTabContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
    value: 1,
  );
  late final Animation<double> _opacity = Tween(
    begin: 0.9,
    end: 1.0,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  final Set<int> _visited = {};

  @override
  void didUpdateWidget(covariant MainTabContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      if (MediaQuery.disableAnimationsOf(context)) {
        _controller.value = 1;
      } else {
        _controller.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _visited.add(widget.currentIndex);
    return FadeTransition(
      opacity: _opacity,
      child: IndexedStack(
        index: widget.currentIndex,
        sizing: StackFit.expand,
        children: List.generate(widget.builders.length, (index) {
          return TickerMode(
            enabled: index == widget.currentIndex,
            child: ExcludeFocus(
              excluding: index != widget.currentIndex,
              child: _visited.contains(index)
                  ? RepaintBoundary(
                      child: Builder(builder: widget.builders[index]),
                    )
                  : const SizedBox.shrink(),
            ),
          );
        }),
      ),
    );
  }
}
