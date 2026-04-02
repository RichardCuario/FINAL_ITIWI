import 'package:flutter/material.dart';
import 'auth_page.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({
    super.key,
    required this.isDarkMode,
    required this.onToggleDarkMode,
  });

  final bool isDarkMode;
  final ValueChanged<bool> onToggleDarkMode;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingItem> _items = const [
    _OnboardingItem(
      imagePath: 'assets/onboarding1.png',
      title: 'Get Started Begin Your Journey with Ease!',
      description:
          'Get started now and begin your journey with ease, unlocking new opportunities and seamless experiences!',
      primaryLabel: 'Get started',
    ),
    _OnboardingItem(
      imagePath: 'assets/onboarding2.png',
      title: 'Discover great places with just a few steps!',
      description:
          'Discover new places with just a few steps! Explore Tiwi like never before.',
      primaryLabel: 'Next',
      secondaryLabel: 'Skip',
    ),
    _OnboardingItem(
      imagePath: 'assets/onboarding3.png',
      title: 'Connect with Your Government Anytime, Anywhere',
      description:
          'Make inquiries, submit documents, and access essential services — all in one app. No lines, no hassle — just easy, secure service.',
      primaryLabel: 'Done',
    ),
  ];

  void _goNext() {
    if (_currentPage == _items.length - 1) {
      _finishOnboarding();
      return;
    }

    _pageController.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
    );
  }

  void _skipToLast() {
    _pageController.animateToPage(
      _items.length - 1,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
    );
  }

  void _finishOnboarding() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => AuthPage(
          isDarkMode: widget.isDarkMode,
          onToggleDarkMode: widget.onToggleDarkMode,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = _items[_currentPage];
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final bottomInset = mediaQuery.padding.bottom;
    final panelHeight = (screenHeight * 0.38).clamp(260.0, 360.0);
    final horizontalPadding = screenHeight < 700 ? 22.0 : 28.0;
    final titleFontSize = screenHeight < 700 ? 17.0 : 19.0;
    final descriptionFontSize = screenHeight < 700 ? 12.0 : 13.0;
    final verticalGap = screenHeight < 700 ? 14.0 : 18.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            Positioned.fill(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _items.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  return _buildImageSection(_items[index].imagePath);
                },
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                constraints: BoxConstraints(
                  minHeight: 260,
                  maxHeight: panelHeight + bottomInset,
                ),
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  18,
                  horizontalPadding,
                  24 + bottomInset,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildIndicators(),
                    SizedBox(height: verticalGap),
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            Text(
                              item.title,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: titleFontSize,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF111111),
                                height: 1.35,
                              ),
                            ),
                            SizedBox(height: verticalGap),
                            Text(
                              item.description,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: descriptionFontSize,
                                color: const Color(0xFF9E9E9E),
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (item.secondaryLabel == null)
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _goNext,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1F86D9),
                            foregroundColor: Colors.white,
                            elevation: 8,
                            shadowColor: const Color(0x331F86D9),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          child: Text(item.primaryLabel),
                        ),
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _skipToLast,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFE8E8E8),
                                  foregroundColor: const Color(0xFF222222),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(28),
                                  ),
                                ),
                                child: Text(item.secondaryLabel!),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: SizedBox(
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _goNext,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1F86D9),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(28),
                                  ),
                                ),
                                child: Text(item.primaryLabel),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection(String imagePath) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          imagePath,
          fit: BoxFit.cover,
        ),
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Color(0x26000000),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _items.length,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: _currentPage == index ? 22 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: _currentPage == index
                ? const Color(0xFF1F86D9)
                : const Color(0xFFB9D7F2),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}

class _OnboardingItem {
  final String imagePath;
  final String title;
  final String description;
  final String primaryLabel;
  final String? secondaryLabel;

  const _OnboardingItem({
    required this.imagePath,
    required this.title,
    required this.description,
    required this.primaryLabel,
    this.secondaryLabel,
  });
}
