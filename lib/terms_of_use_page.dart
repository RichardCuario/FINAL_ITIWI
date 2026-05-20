import 'package:flutter/material.dart';

class TermsOfUsePage extends StatelessWidget {
  const TermsOfUsePage({super.key});

  static const List<_TermsSection> _sections = [
    _TermsSection(
      title: 'Acceptance of Terms',
      body:
          'By accessing and using this app, you agree to follow these terms of use and all applicable rules related to municipal services provided through the platform. If you do not agree with these terms, you should discontinue use of the app.',
      icon: Icons.check_circle_outline,
      iconColor: Color(0xFF1E88E5),
    ),
    _TermsSection(
      title: 'Proper Use of the App',
      body:
          'You agree to use the app only for lawful purposes, including submitting legitimate reports, viewing official information, and accessing available municipal services. You must not misuse the platform, attempt unauthorized access, or submit false, harmful, or misleading content.',
      icon: Icons.rule_folder_outlined,
      iconColor: Color(0xFF00A889),
    ),
    _TermsSection(
      title: 'User Accounts',
      body:
          'Some features may require an account. You are responsible for maintaining the confidentiality of your account information and for activities conducted through your account. You should keep your login details secure and notify the appropriate administrator if you suspect unauthorized access.',
      icon: Icons.manage_accounts_outlined,
      iconColor: Color(0xFF6F46D9),
    ),
    _TermsSection(
      title: 'Submitted Content',
      body:
          'Any information, images, documents, or reports you submit should be accurate, respectful, and relevant to the service being requested. Content that is abusive, fraudulent, offensive, or unrelated to municipal transactions may be removed or rejected.',
      icon: Icons.file_present_outlined,
      iconColor: Color(0xFFF26A45),
    ),
    _TermsSection(
      title: 'Service Availability',
      body:
          'The municipality may update, suspend, limit, or improve app features at any time to maintain service quality, security, or compliance. Availability of certain services may depend on administrative schedules, connectivity, and system maintenance.',
      icon: Icons.miscellaneous_services_outlined,
      iconColor: Color(0xFF4CAF50),
    ),
    _TermsSection(
      title: 'Limitation of Responsibility',
      body:
          'While reasonable effort is made to keep the app functional and information up to date, the app is provided as available. Delays, technical interruptions, or unintentional inaccuracies may still occur, and use of the platform remains subject to operational limitations.',
      icon: Icons.info_outline,
      iconColor: Color(0xFFF3C746),
    ),
    _TermsSection(
      title: 'Changes to the Terms',
      body:
          'These terms may be revised from time to time. Continued use of the app after updates means you accept the revised terms currently displayed in the application.',
      icon: Icons.update_outlined,
      iconColor: Color(0xFF26A69A),
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
                          'Terms of Use',
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
                      _TermsIntroCard(isDark: isDark),
                      const SizedBox(height: 16),
                      ..._sections.map(
                        (section) => _TermsSectionCard(
                          section: section,
                          isDark: isDark,
                        ),
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

class _TermsIntroCard extends StatelessWidget {
  const _TermsIntroCard({required this.isDark});

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
              Icons.gavel_rounded,
              color: Color(0xFF1E88E5),
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'These terms explain the rules for using the app, submitting content, accessing municipal services, and understanding the responsibilities connected with your use of the platform.',
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

class _TermsSectionCard extends StatelessWidget {
  const _TermsSectionCard({
    required this.section,
    required this.isDark,
  });

  final _TermsSection section;
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
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: section.iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(section.icon, color: section.iconColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  section.title,
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF20242C),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  section.body,
                  style: TextStyle(
                    color: isDark ? Colors.white70 : const Color(0xFF4B5563),
                    fontSize: 14.5,
                    height: 1.55,
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

class _TermsSection {
  const _TermsSection({
    required this.title,
    required this.body,
    required this.icon,
    required this.iconColor,
  });

  final String title;
  final String body;
  final IconData icon;
  final Color iconColor;
}
