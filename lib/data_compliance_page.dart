import 'package:flutter/material.dart';

class DataCompliancePage extends StatelessWidget {
  const DataCompliancePage({super.key});

  static const List<_ComplianceSection> _sections = [
    _ComplianceSection(
      title: 'Lawful Collection and Processing',
      body:
          'Personal data collected through the app is intended to support legitimate municipal functions such as account management, report handling, service delivery, communication, and public information access. Data is processed only for appropriate and service-related purposes.',
      icon: Icons.fact_check_outlined,
      iconColor: Color(0xFF1E88E5),
    ),
    _ComplianceSection(
      title: 'Purpose Limitation',
      body:
          'Information submitted by users is used only for the specific government services, concerns, requests, or official transactions for which it was provided. Data should not be processed in a manner inconsistent with those stated purposes unless otherwise required by law or regulation.',
      icon: Icons.track_changes_outlined,
      iconColor: Color(0xFF00A889),
    ),
    _ComplianceSection(
      title: 'Data Minimization',
      body:
          'Only information reasonably necessary to perform app features and municipal services should be collected or requested. Users are encouraged to avoid submitting excessive confidential or sensitive information when it is not needed for the transaction.',
      icon: Icons.filter_alt_outlined,
      iconColor: Color(0xFFF26A45),
    ),
    _ComplianceSection(
      title: 'Storage and Protection',
      body:
          'Administrative, organizational, and technical safeguards are used to help protect stored records and submissions against unauthorized access, disclosure, alteration, or loss. Access is intended to be limited to authorized personnel and systems involved in official processing.',
      icon: Icons.storage_outlined,
      iconColor: Color(0xFF6F46D9),
    ),
    _ComplianceSection(
      title: 'User Rights and Requests',
      body:
          'Where applicable, users may request assistance related to their personal information, including correction of inaccurate account details or inquiries about submitted data. Such requests remain subject to verification, legal obligations, and municipal procedures.',
      icon: Icons.verified_user_outlined,
      iconColor: Color(0xFF4CAF50),
    ),
    _ComplianceSection(
      title: 'Retention and Disposal',
      body:
          'Records may be retained only for as long as necessary to fulfill service requirements, legal obligations, administrative processes, or public recordkeeping duties. When no longer required, records should be disposed of or managed according to appropriate retention policies.',
      icon: Icons.delete_sweep_outlined,
      iconColor: Color(0xFFF3C746),
    ),
    _ComplianceSection(
      title: 'Ongoing Compliance Review',
      body:
          'Data handling practices may be reviewed and updated to reflect operational improvements, legal requirements, and responsible digital governance. Continued use of the app means you acknowledge the current compliance information presented in the application.',
      icon: Icons.policy_outlined,
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
                          'Data & Compliance',
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
                      _ComplianceIntroCard(isDark: isDark),
                      const SizedBox(height: 16),
                      ..._sections.map(
                        (section) => _ComplianceSectionCard(
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

class _ComplianceIntroCard extends StatelessWidget {
  const _ComplianceIntroCard({required this.isDark});

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
              Icons.security_rounded,
              color: Color(0xFF1E88E5),
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'This page outlines how the app supports responsible handling of personal data, municipal recordkeeping, protection measures, and service-related compliance expectations.',
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

class _ComplianceSectionCard extends StatelessWidget {
  const _ComplianceSectionCard({
    required this.section,
    required this.isDark,
  });

  final _ComplianceSection section;
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

class _ComplianceSection {
  const _ComplianceSection({
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
