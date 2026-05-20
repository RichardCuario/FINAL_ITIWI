import 'package:flutter/material.dart';

class FaqPage extends StatelessWidget {
  const FaqPage({super.key});

  static const List<_FaqItem> _faqItems = [
    _FaqItem(
      question: 'How do I send a report or concern?',
      answer:
          'Open the Report page, enter the details of your concern, add a clear description and photo if available, then tap submit. Make sure the information is accurate so the report can be reviewed properly.',
      icon: Icons.report_problem_rounded,
      iconColor: Color(0xFFF26A45),
    ),
    _FaqItem(
      question: 'Can I track the report I submitted?',
      answer:
          'Yes. If report tracking is enabled for your account, you can check your submitted reports in the app and see updates once the municipality reviews them.',
      icon: Icons.assignment_rounded,
      iconColor: Color(0xFF1E88E5),
    ),
    _FaqItem(
      question: 'Where can I find emergency hotline numbers?',
      answer:
          'Go to the Hotline page to view important contact numbers such as police, fire, rescue, and other municipal emergency services.',
      icon: Icons.call_rounded,
      iconColor: Color(0xFF6F46D9),
    ),
    _FaqItem(
      question: 'Where can I read the latest announcements or news?',
      answer:
          'Open the News section to read the latest municipal announcements, public advisories, event updates, and other official posts.',
      icon: Icons.campaign_rounded,
      iconColor: Color(0xFF00A889),
    ),
    _FaqItem(
      question: 'What online services can I access in the app?',
      answer:
          'Visit the Online Services page to find available digital services, request links, forms, and other service options provided by the municipality.',
      icon: Icons.public_rounded,
      iconColor: Color(0xFFF3C746),
    ),
    _FaqItem(
      question: 'Do I need to create an account first?',
      answer:
          'Some parts of the app may be available without signing in, but features like personalized access, report history, or service requests may require an account.',
      icon: Icons.person_rounded,
      iconColor: Color(0xFF4CAF50),
    ),
    _FaqItem(
      question: 'Is the information in the app official and updated?',
      answer:
          'The app is designed to show information coming from the municipal government or authorized administrators. Updates depend on the latest content posted by the app managers.',
      icon: Icons.verified_rounded,
      iconColor: Color(0xFF26A69A),
    ),
    _FaqItem(
      question: 'What should I do if something is missing or not working in the app?',
      answer:
          'If a page does not load, information looks incomplete, or a feature is not working, try reopening the app or checking your internet connection. You may also contact your municipality for assistance.',
      icon: Icons.help_outline_rounded,
      iconColor: Color(0xFFEF6C00),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor =
        isDark ? theme.scaffoldBackgroundColor : const Color(0xFFEAEAEA);
    final topGradient = isDark
        ? const [
            Color(0xFF0F172A),
            Color(0xFF172554),
            Color(0xFF111827),
          ]
        : const [
            Color(0xFF1E88E5),
            Color(0xFF90CAF9),
            Color(0xFFEAEAEA),
          ];

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          Container(
            height: 220,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: topGradient,
                stops: const [0.0, 0.6, 1.0],
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 14, 20, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Expanded(
                        child: Text(
                          'Frequently Asked Questions',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                    children: [
                      _FaqIntroCard(isDark: isDark),
                      const SizedBox(height: 16),
                      ..._faqItems.map(
                        (item) => _FaqTile(item: item, isDark: isDark),
                      ),
                    ],
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

class _FaqIntroCard extends StatelessWidget {
  const _FaqIntroCard({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF262631) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE3E6EB),
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF1E88E5).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.help_center_rounded,
              color: Color(0xFF1E88E5),
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Find quick answers about submitting reports, checking hotlines, viewing announcements, using online services, and other common app concerns.',
              style: TextStyle(
                color: isDark ? Colors.white70 : const Color(0xFF4B5563),
                fontSize: 15,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({required this.item, required this.isDark});

  final _FaqItem item;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF262631) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE3E6EB),
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
          childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: item.iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(item.icon, color: item.iconColor, size: 24),
          ),
          iconColor: item.iconColor,
          collapsedIconColor: item.iconColor,
          title: Text(
            item.question,
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF20242C),
              fontSize: 16,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
          children: [
            Text(
              item.answer,
              style: TextStyle(
                color: isDark ? Colors.white70 : const Color(0xFF4B5563),
                fontSize: 14.5,
                height: 1.55,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FaqItem {
  const _FaqItem({
    required this.question,
    required this.answer,
    required this.icon,
    required this.iconColor,
  });

  final String question;
  final String answer;
  final IconData icon;
  final Color iconColor;
}
