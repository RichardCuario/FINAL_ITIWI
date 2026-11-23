import 'package:flutter/material.dart';

/// Keeps layout stable while the drawer hides or reveals the floating bar.
class NavigationVisibility extends StatelessWidget {
  const NavigationVisibility({
    super.key,
    required this.visible,
    required this.child,
  });

  final bool visible;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final duration = Duration(
      milliseconds: MediaQuery.disableAnimationsOf(context) ? 0 : 220,
    );
    return IgnorePointer(
      ignoring: !visible,
      child: ExcludeSemantics(
        excluding: !visible,
        child: AnimatedSlide(
          offset: visible ? Offset.zero : const Offset(0, 0.12),
          duration: duration,
          curve: Curves.easeInOutCubic,
          child: AnimatedOpacity(
            opacity: visible ? 1 : 0,
            duration: duration,
            curve: Curves.easeInOutCubic,
            child: RepaintBoundary(child: child),
          ),
        ),
      ),
    );
  }
}

/// Shared floating navigation for the app's three main destinations.
class PremiumBottomNavigation extends StatelessWidget {
  const PremiumBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenSize = MediaQuery.sizeOf(context);
    final isNarrowPhone = screenSize.width < 400;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final duration = Duration(milliseconds: reduceMotion ? 0 : 160);
    const blue = Color(0xFF007AFF);
    final activeColor = isDark ? const Color(0xFF75BAFF) : blue;
    final inactiveColor = isDark
        ? const Color(0xFF9DAEC7)
        : const Color(0xFF647089);

    return SafeArea(
      top: false,
      minimum: EdgeInsets.fromLTRB(20, 6, 20, isNarrowPhone ? 32 : 8),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Material(
            color: isDark ? const Color(0xFF202F48) : Colors.white,
            elevation: 8,
            shadowColor: (isDark ? Colors.black : const Color(0xFF438BD0))
                .withValues(alpha: 0.24),
            surfaceTintColor: Colors.transparent,
            shape: StadiumBorder(
              side: BorderSide(
                color: Colors.white.withValues(alpha: isDark ? 0.10 : 0.95),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: AnimatedAlign(
                      duration: duration,
                      curve: Curves.easeOutCubic,
                      alignment: AlignmentDirectional(currentIndex - 1.0, 1),
                      child: FractionallySizedBox(
                        widthFactor: 1 / 3,
                        child: Center(
                          heightFactor: 1,
                          child: Container(
                            width: 22,
                            height: 3,
                            margin: const EdgeInsets.only(bottom: 3),
                            decoration: BoxDecoration(
                              color: activeColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Row(
                    children: List.generate(3, (index) {
                      final selected = currentIndex == index;
                      final raised = selected && index == 1;
                      final color = selected ? activeColor : inactiveColor;
                      const labels = ['Home', 'News', 'Profile'];
                      final icons = [
                        selected ? Icons.home_rounded : Icons.home_outlined,
                        Icons.article_outlined,
                        selected
                            ? Icons.person_rounded
                            : Icons.person_outline_rounded,
                      ];

                      return Expanded(
                        child: Semantics(
                          selected: selected,
                          button: true,
                          label: labels[index],
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(36),
                              onTap: () {
                                if (index != currentIndex) onTap(index);
                              },
                              excludeFromSemantics: true,
                              child: ExcludeSemantics(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 3,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      AnimatedContainer(
                                        duration: duration,
                                        curve: Curves.easeOutCubic,
                                        transform: Matrix4.translationValues(
                                          0,
                                          raised ? -3 : 0,
                                          0,
                                        ),
                                        width: 34,
                                        height: 34,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: raised
                                                ? [
                                                    const Color(0xFF58BDFF),
                                                    blue,
                                                  ]
                                                : selected
                                                ? [
                                                    activeColor.withValues(
                                                      alpha: 0.19,
                                                    ),
                                                    activeColor.withValues(
                                                      alpha: 0.09,
                                                    ),
                                                  ]
                                                : [
                                                    Colors.transparent,
                                                    Colors.transparent,
                                                  ],
                                          ),
                                          boxShadow: selected
                                              ? [
                                                  BoxShadow(
                                                    color: blue.withValues(
                                                      alpha: raised
                                                          ? 0.32
                                                          : 0.12,
                                                    ),
                                                    blurRadius: 10,
                                                    offset: const Offset(0, 3),
                                                  ),
                                                ]
                                              : [],
                                        ),
                                        child: AnimatedScale(
                                          scale: selected ? 1.06 : 1,
                                          duration: duration,
                                          curve: Curves.easeOutCubic,
                                          child: AnimatedSwitcher(
                                            duration: duration,
                                            switchInCurve: Curves.easeOutCubic,
                                            switchOutCurve: Curves.easeInCubic,
                                            child: Icon(
                                              icons[index],
                                              key: ValueKey(
                                                '$index-$selected-$isDark',
                                              ),
                                              size: 23,
                                              color: raised
                                                  ? Colors.white
                                                  : color,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      AnimatedDefaultTextStyle(
                                        duration: duration,
                                        curve: Curves.easeOutCubic,
                                        style: TextStyle(
                                          color: color,
                                          fontSize: 11,
                                          fontWeight: selected
                                              ? FontWeight.w700
                                              : FontWeight.w600,
                                        ),
                                        child: Text(
                                          labels[index],
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
