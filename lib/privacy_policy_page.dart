import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  static const List<_PolicySection> _sections = [
    _PolicySection(
      title: 'Information We Collect',
      body:
          'The app may collect account details such as your name, email address, and profile information when you register or update your account. It may also collect the content you submit, including reports, service requests, feedback, and other information you voluntarily provide while using the app.',
      icon: Icons.badge_outlined,
      iconColor: Color(0xFF1E88E5),
    ),
    _PolicySection(
      title: 'How We Use Your Information',
      body:
          'Your information is used to provide municipal services, manage your account, respond to reports and concerns, improve app features, and send relevant notifications or updates related to official services and announcements.',
      icon: Icons.settings_suggest_outlined,
      iconColor: Color(0xFF00A889),
    ),
    _PolicySection(
      title: 'Reports, Requests, and Uploaded Content',
      body:
          'When you submit reports, requests, images, or supporting documents, the information may be reviewed by authorized personnel for verification, response, recordkeeping, and service delivery purposes. Please avoid submitting unnecessary sensitive personal information.',
      icon: Icons.upload_file_outlined,
      iconColor: Color(0xFFF26A45),
    ),
    _PolicySection(
      title: 'Data Sharing',
      body:
          'Your information is only shared with authorized municipal staff, service administrators, and systems involved in processing official requests and maintaining the app. Information is not intended to be sold for commercial purposes.',
      icon: Icons.share_outlined,
      iconColor: Color(0xFF6F46D9),
    ),
    _PolicySection(
      title: 'Data Protection',
      body:
          'Reasonable administrative and technical measures are used to help protect your information from unauthorized access, misuse, loss, or disclosure. However, no digital platform can guarantee complete security at all times.',
      icon: Icons.shield_outlined,
      iconColor: Color(0xFF4CAF50),
    ),
    _PolicySection(
      title: 'Your Choices',
      body:
          'You may review and update some account information from your profile settings. If you no longer want to use the app, you may stop using the service and contact the municipality for account-related concerns, corrections, or data inquiries when applicable.',
      icon: Icons.manage_accounts_outlined,
      iconColor: Color(0xFFF3C746),
    ),
    _PolicySection(
      title: 'Policy Updates',
      body:
          'This privacy policy may be updated from time to time to reflect changes in services, legal requirements, or platform improvements. Continued use of the app after updates means you acknowledge the latest version shown in the application.',
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
                          'Privacy Policy',
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
                      _PrivacyIntroCard(isDark: isDark),
                      const SizedBox(height: 16),
                      ..._sections.map(
                        (section) => _PolicySectionCard(
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

class _PrivacyIntroCard extends StatelessWidget {
  const _PrivacyIntroCard({required this.isDark});

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
              Icons.privacy_tip_outlined,
              color: Color(0xFF1E88E5),
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'This page explains how information submitted through the app may be collected, used, protected, and managed in relation to municipal services and official digital transactions.',
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

class _PolicySectionCard extends StatelessWidget {
  const _PolicySectionCard({
    required this.section,
    required this.isDark,
  });

  final _PolicySection section;
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

class _PolicySection {
  const _PolicySection({
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
