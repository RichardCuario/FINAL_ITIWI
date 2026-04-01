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

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          PageView.builder(
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
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 292,
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(28, 18, 28, 28),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
              ),
              child: Column(
                children: [
                  _buildIndicators(),
                  const SizedBox(height: 22),
                  Text(
                    item.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111111),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    item.description,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF9E9E9E),
                      height: 1.5,
                    ),
                  ),
                  const Spacer(),
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
