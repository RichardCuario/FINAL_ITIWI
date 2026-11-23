import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppSplashGate extends StatefulWidget {
  const AppSplashGate({super.key, required this.child});

  final Widget child;

  @override
  State<AppSplashGate> createState() => _AppSplashGateState();
}

class _AppSplashGateState extends State<AppSplashGate>
    with SingleTickerProviderStateMixin {
  static const _background = Color(0xFF102F49);
  late final AnimationController _controller;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 1900),
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed && mounted) {
            setState(() => _finished = true);
          }
        });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_finished) return widget.child;

    final logoEntrance = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.48, curve: Curves.easeOutCubic),
    );
    final titleEntrance = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.20, 0.66, curve: Curves.easeOutCubic),
    );
    final exit = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.84, 1.0, curve: Curves.easeInCubic),
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: _background,
      ),
      child: Scaffold(
        backgroundColor: _background,
        body: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) =>
              Opacity(opacity: 1 - exit.value, child: child),
          child: Stack(
            fit: StackFit.expand,
            children: [
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF102F49), Color(0xFF0A466C)],
                  ),
                ),
              ),
              SafeArea(
                child: Column(
                  children: [
                    const Spacer(),
                    ScaleTransition(
                      scale: Tween<double>(
                        begin: 0.84,
                        end: 1,
                      ).animate(logoEntrance),
                      child: FadeTransition(
                        opacity: logoEntrance,
                        child: Container(
                          width: 144,
                          height: 144,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x44000000),
                                blurRadius: 28,
                                offset: Offset(0, 12),
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Image.asset(
                            'assets/official_logo.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 26),
                    FadeTransition(
                      opacity: titleEntrance,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.25),
                          end: Offset.zero,
                        ).animate(titleEntrance),
                        child: const Column(
                          children: [
                            Text(
                              'iTIWI',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.8,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Digital  •  Transparent  •  Efficient',
                              style: TextStyle(
                                color: Color(0xFFD4E8F5),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, _) {
                        final progress = Curves.easeInOutCubic.transform(
                          (_controller.value / 0.84).clamp(0.0, 1.0),
                        );
                        return SizedBox(
                          width: 96,
                          height: 3,
                          child: Stack(
                            children: [
                              Container(color: const Color(0x55FFFFFF)),
                              FractionallySizedBox(
                                widthFactor: progress,
                                child: Container(
                                  color: const Color(0xFF41C4F3),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 48),
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
