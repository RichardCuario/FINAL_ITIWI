import 'package:flutter/material.dart';

import 'package:url_launcher/url_launcher.dart';

class FaqPage extends StatefulWidget {
  const FaqPage({super.key});
  @override
  State<FaqPage> createState() => _FaqPageState();
}

class _FaqPageState extends State<FaqPage> {
  final _search = TextEditingController();
  String _topic = 'All';
  static const _topics = [
    'All',
    'Reports',
    'Account',
    'Services',
    'Using iTIWI',
  ];
  static const _items = [
    _FaqItem(
      'Reports',
      'How do I submit a concern?',
      'Open Report, choose a category, and describe what happened and where. You can attach photos before submitting. You need to sign in and complete identity verification to send a report.',
    ),
    _FaqItem(
      'Reports',
      'Where can I check my report’s status?',
      'Open My Reports to view your submitted concerns, their current status, and any review message from the municipality. Check your connection if a recent update has not appeared.',
    ),
    _FaqItem(
      'Reports',
      'How many photos can I attach?',
      'You can attach up to 5 photos to a report. Choose clear JPEG, PNG, or WebP images. The app compresses them before uploading and asks you to choose a smaller photo if it still exceeds 2 MB.',
    ),
    _FaqItem(
      'Reports',
      'What details should I include?',
      'Include the barangay, a nearby landmark, when the issue happened, and a short explanation. Use photos that show the concern clearly. Avoid including unrelated personal information.',
    ),
    _FaqItem(
      'Reports',
      'Can I use a report for an emergency?',
      'For an urgent situation, open Hotlines and call the appropriate emergency service. Reports are reviewed by staff and are not a live emergency-response channel.',
    ),
    _FaqItem(
      'Account',
      'Why am I asked to verify my identity?',
      'Reports and online service requests require a verified account. Follow the instructions on the Identity Verification page. Identity documents are captured through Didit, and the app uses the verification result to check access.',
    ),
    _FaqItem(
      'Account',
      'What if identity verification is not complete?',
      'Return to Identity Verification and check the displayed status and instructions. If you have not finished the verification steps, complete them before trying to submit a report or request.',
    ),
    _FaqItem(
      'Account',
      'How do I reset my password?',
      'On the sign-in page, use the forgot-password option and enter the email address for your account. Check your inbox and spam folder for the reset email. If you use Google sign-in, manage your password through your Google account.',
    ),
    _FaqItem(
      'Account',
      'Where can I read about my personal data?',
      'Open Privacy Policy and Data & Compliance from the app menu or your profile. These pages explain how information is used and how to raise questions about your data.',
    ),
    _FaqItem(
      'Services',
      'Which document services are available?',
      'Online Services includes appointment forms for birth, marriage, and death certificates, and CENODEATH (Certificate of No Death). Open a service to see its form and instructions.',
    ),
    _FaqItem(
      'Services',
      'Does submitting a request mean it is approved?',
      'A submitted request still needs to be reviewed. Check its status and any instructions from the office. Do not assume a document is ready for collection just because the form was submitted.',
    ),
    _FaqItem(
      'Services',
      'Where can I find barangay information?',
      'Open Barangay and select a barangay to see its available description, officials, and location information. Details depend on what the municipality has published.',
    ),
    _FaqItem(
      'Services',
      'Where can I find public documents?',
      'Open Transparency to browse the published records and documents. An internet connection may be needed to open a document or load the latest entries.',
    ),
    _FaqItem(
      'Using iTIWI',
      'Can I use the app without internet?',
      'Some pages can show information saved from an earlier visit. It may not be the latest version. Connect to the internet to refresh content, submit reports or requests, and open online documents.',
    ),
    _FaqItem(
      'Using iTIWI',
      'Why am I not receiving notifications?',
      'Check that notifications are allowed for iTIWI in your phone’s settings and that your device has an internet connection. You can also open News and Notifications in the app to check for updates.',
    ),
    _FaqItem(
      'Using iTIWI',
      'What happens when I clear notifications?',
      'Clear all removes the items from your notification list. It does not delete the published news or the reports you submitted. You can still find those in News and My Reports.',
    ),
    _FaqItem(
      'Using iTIWI',
      'What should I do if a page will not load?',
      'Check your internet connection, reopen the page, and try again. If the issue continues, note the page name and any error message so you can describe the problem when contacting the municipality.',
    ),
  ];

  Future<void> _contactSupport() async {
    try {
      final opened = await launchUrl(
        Uri(scheme: 'mailto', path: 'itiwiapp@gmail.com'),
        mode: LaunchMode.externalApplication,
      );
      if (opened) return;
    } catch (_) {
      // Show the address if no email app can handle the request.
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Unable to open email. Please email itiwiapp@gmail.com.'),
      ),
    );
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final background = dark ? const Color(0xFF101820) : const Color(0xFFF2F7FC);
    final surface = dark ? const Color(0xFF18232D) : Colors.white;
    final ink = dark ? const Color(0xFFEDF2F6) : const Color(0xFF182B3A);
    final secondary = dark ? const Color(0xFFABB9C5) : const Color(0xFF566773);
    final line = dark ? const Color(0xFF30404D) : const Color(0xFFDDE3E8);
    final accent = dark ? const Color(0xFF91C8F5) : const Color(0xFF165D91);
    final accentSurface = dark
        ? const Color(0xFF20364B)
        : const Color(0xFFE4EFFA);
    final headerColor = dark
        ? const Color(0xFF173751)
        : const Color(0xFF185D91);
    final query = _search.text.trim().toLowerCase();
    final visible = _items
        .where(
          (item) =>
              (_topic == 'All' || item.topic == _topic) &&
              '${item.question} ${item.answer} ${item.topic}'
                  .toLowerCase()
                  .contains(query),
        )
        .toList();
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text('Help & FAQ'),
        backgroundColor: Colors.transparent,
        foregroundColor: dark ? Colors.white : Colors.black,
        toolbarHeight: 40,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      body: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 36),
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: dark
                          ? const [Color(0xFF123A66), Color(0xFF1E5FA6)]
                          : const [Color(0xFF0F5FC5), Color(0xFF0B7DE6)],
                    ),
                  ),
                  child: Column(
                    children: [
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final largeText =
                              MediaQuery.textScalerOf(context).scale(14) > 20;
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'HELP & FAQ',
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.8),
                                          fontSize: 10,
                                          letterSpacing: 2.2,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'How can we help?',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 23,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: -0.7,
                                          height: 1.15,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'A quick guide to reports, requests, and your account.',
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.82),
                                          fontSize: 12,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (!largeText)
                                Image.asset(
                                  'assets/optimized/faq_support.png',
                                  width: constraints.maxWidth * 0.36,
                                  height: 130,
                                  fit: BoxFit.contain,
                                  alignment: Alignment.bottomCenter,
                                  excludeFromSemantics: true,
                                ),
                            ],
                          );
                        },
                      ),
                      TextField(
                        controller: _search,
                        onChanged: (_) => setState(() {}),
                        style: TextStyle(color: ink),
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          hintText: 'Search questions, topics, or keywords...',
                          hintStyle: TextStyle(color: secondary, fontSize: 12),
                          prefixIcon: Icon(Icons.search_rounded, color: accent),
                          suffixIcon: _search.text.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'Clear search',
                                  icon: Icon(
                                    Icons.close_rounded,
                                    color: secondary,
                                  ),
                                  onPressed: () => setState(_search.clear),
                                ),
                          filled: true,
                          fillColor: surface,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 17,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: line),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: accent, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _topics.map((topic) {
                      final selected = topic == _topic;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Semantics(
                          selected: selected,
                          child: Container(
                            decoration: BoxDecoration(
                              color: selected ? headerColor : accentSurface,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: TextButton(
                              style: TextButton.styleFrom(
                                foregroundColor: selected
                                    ? Colors.white
                                    : accent,
                                minimumSize: const Size(48, 48),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                ),
                              ),
                              onPressed: () => setState(() => _topic = topic),
                              child: Text(
                                topic,
                                style: TextStyle(
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  query.isEmpty
                      ? '${visible.length} ${visible.length == 1 ? 'question' : 'questions'}'
                      : '${visible.length} ${visible.length == 1 ? 'result' : 'results'}',
                  style: TextStyle(color: secondary, fontSize: 13),
                ),
                const SizedBox(height: 12),
                if (visible.isEmpty) ...[
                  const SizedBox(height: 28),
                  Text(
                    'No matching questions',
                    style: TextStyle(
                      color: ink,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Try a shorter search, such as “photo” or “password”, or look in another topic.',
                    style: TextStyle(color: secondary, height: 1.5),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () => setState(() {
                        _search.clear();
                        _topic = 'All';
                      }),
                      style: TextButton.styleFrom(foregroundColor: accent),
                      child: const Text('Show all questions'),
                    ),
                  ),
                ] else
                  Material(
                    color: surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: line),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        for (var i = 0; i < visible.length; i++) ...[
                          if (i > 0)
                            Divider(
                              height: 1,
                              indent: 20,
                              endIndent: 20,
                              color: line,
                            ),
                          ExpansionTile(
                            key: ValueKey(visible[i].question),
                            backgroundColor: accentSurface,
                            tilePadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 7,
                            ),
                            childrenPadding: const EdgeInsets.fromLTRB(
                              20,
                              0,
                              20,
                              22,
                            ),
                            expandedCrossAxisAlignment:
                                CrossAxisAlignment.start,
                            shape: const Border(),
                            collapsedShape: const Border(),
                            iconColor: accent,
                            collapsedIconColor: accent,
                            title: Text(
                              visible[i].question,
                              style: TextStyle(
                                color: ink,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                height: 1.4,
                              ),
                            ),
                            children: [
                              SizedBox(
                                width: double.infinity,
                                child: Text(
                                  visible[i].answer,
                                  style: TextStyle(
                                    color: secondary,
                                    fontSize: 14,
                                    height: 1.65,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: dark
                        ? const Color(0xFF20364B)
                        : const Color(0xFFE3EFFF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final stacked =
                          constraints.maxWidth < 320 ||
                          MediaQuery.textScalerOf(context).scale(12) > 16;
                      final message = Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: dark
                                  ? const Color(0xFF2C4D70)
                                  : const Color(0xFFCEE3FD),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.headset_mic_rounded,
                              color: dark ? accent : const Color(0xFF1271D5),
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Still need help?',
                                  style: TextStyle(
                                    color: dark ? ink : const Color(0xFF102B50),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Contact our support team or visit the Municipality of Tiwi.',
                                  style: TextStyle(
                                    color: secondary,
                                    fontSize: 11,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                      final contactButton = FilledButton(
                        onPressed: _contactSupport,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF1768C3),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 48),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Contact Us', style: TextStyle(fontSize: 11)),
                            SizedBox(width: 6),
                            Icon(Icons.chevron_right_rounded, size: 20),
                          ],
                        ),
                      );
                      if (stacked) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            message,
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: contactButton,
                            ),
                          ],
                        );
                      }
                      return Row(
                        children: [
                          Expanded(child: message),
                          const SizedBox(width: 12),
                          contactButton,
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FaqItem {
  const _FaqItem(this.topic, this.question, this.answer);
  final String topic;
  final String question;
  final String answer;
}
