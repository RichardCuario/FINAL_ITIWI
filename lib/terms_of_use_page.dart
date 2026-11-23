import 'package:flutter/material.dart';
import 'policy_document_page.dart';
import 'privacy_policy_page.dart';
import 'terms_illustration.dart';

class TermsOfUsePage extends StatefulWidget {
  const TermsOfUsePage({super.key});
  @override
  State<TermsOfUsePage> createState() => _TermsOfUsePageState();
}

class _TermsOfUsePageState extends State<TermsOfUsePage> {
  final _search = TextEditingController();
  String _topic = 'All';
  static const _topics = [
    'All',
    'Using iTIWI',
    'Account',
    'Reports',
    'Services',
  ];
  String _topicFor(PolicySection section) => switch (section.title) {
    'Your account and verification' || 'Responsible access' => 'Account',
    'Reports are not emergency calls' ||
    'Photos and submitted information' => 'Reports',
    'Appointments and service requests' => 'Services',
    _ => 'Using iTIWI',
  };

  static const _sections = [
    PolicySection(
      'Using iTIWI',
      'iTIWI provides access to municipal information, reports, and selected online service requests. Use it for lawful purposes and follow the instructions for each service. If you do not agree to these terms, do not submit requests through the app; ask the relevant municipal office about other ways to access its services.',
    ),
    PolicySection(
      'Your account and verification',
      'Keep your account information accurate and protect your sign-in credentials. Do not impersonate another person or use an account without permission. Contact the municipality if you suspect unauthorized use.\n\nReports and protected service requests require a signed-in, verified account. The verification flow uses Didit. Follow the provider’s instructions and review its notices. Identity verification does not itself approve a report, appointment, or document request.',
    ),
    PolicySection(
      'Reports are not emergency calls',
      'Reports are reviewed by staff and are not a live emergency-response channel. For an urgent situation, use Hotlines to call the appropriate service rather than waiting for a report update.\n\nDescribe your concern clearly, including its location and relevant facts. Do not submit knowingly false reports, threats, harassment, or repeated submissions intended to disrupt the service.',
    ),
    PolicySection(
      'Photos and submitted information',
      'Submit only information and photos that are relevant to your concern and that you are entitled to share. Avoid unrelated personal information, passwords, financial details, and identity documents in ordinary report attachments.\n\nReport photos may be resized or compressed. Keep your own original if you need it. Report images currently use public file links, so someone who obtains a working link may be able to view the image. Read the Privacy Policy before uploading sensitive material.',
    ),
    PolicySection(
      'Appointments and service requests',
      'Sending a form records a request for review; it does not guarantee an appointment, approval, or document issuance. Follow the selected service’s instructions and check for status updates or requests for clarification.\n\nConfirm collection arrangements, supporting documents, and any official fees directly with the responsible office. Do not assume a document is ready solely because your request was submitted.',
    ),
    PolicySection(
      'Responsible access',
      'Do not attempt to access another person’s records, bypass verification or access controls, upload malicious content, or interfere with the app’s operation. Respect submission limits and any waiting period shown by the app.\n\nIf access is restricted or a submission is rejected, review the displayed reason and contact the responsible office for clarification. These terms do not replace any applicable municipal review or appeal procedure.',
    ),
    PolicySection(
      'Availability and saved information',
      'An internet connection is required for submissions and current updates. Some pages may display content saved during an earlier visit, which may be out of date.\n\nMaintenance, connectivity problems, or service interruptions can delay access. If a submission appears to fail, check your report or request history before trying again to reduce duplicate records. No fixed response time is promised by these terms.',
    ),
    PolicySection(
      'External services and links',
      'The app may open maps, documents, verification pages, or other websites. Their availability and use are subject to their own notices and terms. Review those before providing information outside iTIWI.\n\nIf a link appears incorrect or a page requests unexpected information, stop and confirm the destination with the relevant office.',
    ),
    PolicySection(
      'Official information and your rights',
      'Published information can change as offices update their records. Confirm time-sensitive requirements with the responsible municipal office. An in-app description does not replace a formal decision, issued document, or applicable law.\n\nThese terms do not remove rights or remedies available under applicable law. Personal information is addressed in the Privacy Policy and Data & Compliance pages.',
    ),
    PolicySection(
      'Questions and changes',
      'For questions about a report or request, use its reference number when contacting the relevant office through published official channels. Never share your password.\n\nReview this page when using new features, as terms may be updated to reflect service changes. Continuing to use the app does not by itself replace any separate consent required for processing personal information.',
    ),
  ];

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
    final visible = _sections
        .where(
          (item) =>
              (_topic == 'All' || _topicFor(item) == _topic) &&
              '${item.title} ${item.body} ${_topicFor(item)}'
                  .toLowerCase()
                  .contains(query),
        )
        .toList();
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text('Terms of Use'),
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
                                        'TERMS OF USE',
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.8),
                                          fontSize: 10,
                                          letterSpacing: 2.2,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Using iTIWI responsibly',
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
                                        'What to expect when you submit a concern, request a service, or use municipal information.',
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
                                SizedBox(
                                  width: constraints.maxWidth * 0.42,
                                  height: 150,
                                  child: const CustomPaint(
                                    painter: TermsIllustration(),
                                  ),
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
                          hintText: 'Search terms, topics, or keywords...',
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
                      ? '${visible.length} ${visible.length == 1 ? 'section' : 'sections'}'
                      : '${visible.length} ${visible.length == 1 ? 'result' : 'results'}',
                  style: TextStyle(color: secondary, fontSize: 13),
                ),
                const SizedBox(height: 12),
                if (visible.isEmpty) ...[
                  const SizedBox(height: 28),
                  Text(
                    'No matching terms',
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
                      child: const Text('Show all terms'),
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
                            key: ValueKey(visible[i].title),
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
                              visible[i].title,
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
                                  visible[i].body,
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
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: accentSurface,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your privacy matters',
                        style: TextStyle(
                          color: ink,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Learn how your personal information is handled.',
                        style: TextStyle(color: secondary, height: 1.4),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const PrivacyPolicyPage(),
                          ),
                        ),
                        style: TextButton.styleFrom(foregroundColor: accent),
                        icon: const Icon(Icons.privacy_tip_outlined, size: 18),
                        label: const Text('Read the Privacy Policy'),
                      ),
                    ],
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
