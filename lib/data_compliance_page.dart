import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'policy_document_page.dart';
import 'privacy_policy_page.dart';
import 'data_compliance_illustration.dart';

class DataCompliancePage extends StatefulWidget {
  const DataCompliancePage({super.key});
  @override
  State<DataCompliancePage> createState() => _DataCompliancePageState();
}

class _DataCompliancePageState extends State<DataCompliancePage> {
  final _search = TextEditingController();
  String _topic = 'All';
  static const _topics = [
    'All',
    'Records',
    'Verification',
    'Your rights',
    'Privacy',
  ];
  String _topicFor(PolicySection section) => switch (section.title) {
    'Relevant and accurate records' || 'Retention and disposal' => 'Records',
    'Verification and service providers' => 'Verification',
    'Access, correction, and other rights' ||
    'How to make a data request' => 'Your rights',
    _ => 'Privacy',
  };

  static const _sections = [
    PolicySection(
      'Purpose of this page',
      'This page explains data-handling practices and how to raise a concern about your information in iTIWI. Read it together with the Privacy Policy. It is not a certification, audit result, or guarantee that every deployment or service meets every legal requirement.',
    ),
    PolicySection(
      'Purpose and lawful processing',
      'Account details support sign-in and communication. Reports and service forms provide information for municipal review, while verification results are used to check access to protected features.\n\nThe legal basis for processing depends on the data and purpose. Consent is not a substitute for every legal requirement, and continued use does not automatically supply consent where it is required. Ask the municipality to explain the basis for a particular use of your information.',
    ),
    PolicySection(
      'Relevant and accurate records',
      'Provide only the details needed for the selected service. Keep your profile accurate, describe concerns factually, and avoid including unrelated information about other people.\n\nIf a submitted record contains an error, identify the record and explain the correction to the responsible office. Editing your profile does not necessarily change details already recorded in a report or service request.',
    ),
    PolicySection(
      'Verification and service providers',
      'Didit captures the identity document and selfie in the current verification flow. iTIWI receives and stores session details, verification status, and decision information returned by the provider. Review the verification notices before continuing.\n\nFirebase supports authentication and notifications, and Supabase stores app records and uploaded files. Provider processing, storage locations, and applicable safeguards should be clarified with the municipality if you need details about where your data is handled.',
    ),
    PolicySection(
      'Uploaded images and visibility',
      'Report photos are stored using public file links. Anyone with a working link may be able to view the image. Do not treat a report attachment as a confidential document channel.\n\nCompression reduces file size but does not hide faces, text, or other identifying details. Avoid uploading identity documents, passwords, or unrelated sensitive information as report photos.',
    ),
    PolicySection(
      'Retention and disposal',
      'Retention depends on the record, the service being provided, and applicable recordkeeping duties. This page does not set a fixed deletion period. Ask the municipality about the schedule for your record.\n\nSigning out, clearing notifications, or uninstalling the app does not automatically delete records from cloud services. A deletion request may require identity confirmation and may be limited by legal retention obligations.',
    ),
    PolicySection(
      'Access, correction, and other rights',
      'Applicable Philippine data-protection law provides rights concerning information about processing, access, and correction. Rights to object, request erasure or blocking, and data portability apply in the circumstances provided by law.\n\nAsk the municipality about your request and any applicable limits. You may also raise a complaint with the National Privacy Commission. Use the official guidance linked below for more detail.',
    ),
    PolicySection(
      'How to make a data request',
      'Contact the Municipality of Tiwi through its published official channels and ask for the office responsible for data privacy. Explain whether you need access, a correction, deletion, or information about processing.\n\nInclude a relevant record reference and a way to contact you. Verify the recipient before sharing identity evidence. Do not send passwords or unnecessary full documents. The responsible office may need to verify that you are entitled to the requested information.',
    ),
    PolicySection(
      'Reporting a privacy concern',
      'If you suspect your account was used without permission or information was exposed, contact the municipality through an official channel. Describe when it happened, the affected page or record, and what you observed.\n\nAvoid forwarding exposed personal information to additional recipients. Keep only the details needed to explain the concern, and ask the responsible office for instructions on providing evidence safely.',
    ),
    PolicySection(
      'Device controls and updates',
      'You can manage notification permission and lock-screen previews in your device settings. The app may store previously loaded content and notification history locally; protect access to your device, especially if it is shared.\n\nReview the Privacy Policy when features or data practices change. For questions about a particular service, request clarification from the responsible municipal office.',
    ),
  ];

  Future<void> _openGuidance(BuildContext context) async {
    try {
      if (await launchUrl(
        Uri.parse('https://privacy.gov.ph/data-subject-rights/'),
        mode: LaunchMode.externalApplication,
      )) {
        return;
      }
    } catch (_) {
      // Offer a readable fallback if no browser is available.
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to open the page. Visit privacy.gov.ph for privacy-rights guidance.',
          ),
        ),
      );
    }
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
        title: const Text('Data & Compliance'),
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
                                      ExcludeSemantics(
                                        child: CircleAvatar(
                                          radius: 20,
                                          backgroundColor: accentSurface,
                                          child: Icon(
                                            Icons.account_balance_rounded,
                                            color: accent,
                                            size: 25,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Understanding your data',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 21,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: -0.7,
                                          height: 1.15,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Practical information about records, verification, retention, and raising a privacy concern.',
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
                                  width: constraints.maxWidth * 0.38,
                                  height: 150,
                                  child: const CustomPaint(
                                    painter: DataComplianceIllustration(),
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
                          hintText: 'Search data, topics, or keywords...',
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
                    'No matching sections',
                    style: TextStyle(
                      color: ink,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Try a shorter search, such as “records” or “retention”, or look in another topic.',
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
                      child: const Text('Show all sections'),
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
                        'Privacy resources',
                        style: TextStyle(
                          color: ink,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Learn about your information and your privacy rights.',
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
                      TextButton.icon(
                        onPressed: () => _openGuidance(context),
                        style: TextButton.styleFrom(foregroundColor: accent),
                        icon: const Icon(Icons.open_in_new, size: 18),
                        label: const Text('Read the NPC guidance'),
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
