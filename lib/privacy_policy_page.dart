import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Decorative vector artwork scales cleanly across phone and tablet layouts.
class _PrivacyIllustration extends CustomPainter {
  const _PrivacyIllustration();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 160, size.height / 150);
    final paint = Paint();
    void rect(Rect bounds, Color color, double radius) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(bounds, Radius.circular(radius)),
        paint..color = color,
      );
    }

    canvas.drawOval(
      const Rect.fromLTWH(4, 24, 152, 120),
      paint..color = const Color(0xFFD9EAFC),
    );
    // A softly colored municipal building behind the document.
    final roof = Path()
      ..moveTo(108, 4)
      ..lineTo(132, 20)
      ..lineTo(84, 20)
      ..close();
    canvas.drawPath(roof, paint..color = const Color(0xFFC0DCF8));
    rect(const Rect.fromLTWH(89, 21, 38, 49), const Color(0xFFE9F3FE), 2);
    for (final x in [94.0, 107.0, 120.0]) {
      rect(Rect.fromLTWH(x, 24, 4, 39), const Color(0xFFB7D4F2), 2);
    }
    // Leaves frame the shield without competing with the heading.
    for (var i = 0; i < 4; i++) {
      canvas.drawOval(
        Rect.fromLTWH(9 + i * 3, 68 + i * 14, 13, 22),
        paint..color = const Color(0xFFBCD8F1),
      );
      canvas.drawOval(
        Rect.fromLTWH(135 - i * 3, 64 + i * 15, 12, 24),
        paint..color = const Color(0xFFBCD8F1),
      );
    }
    canvas.drawOval(
      const Rect.fromLTWH(23, 133, 122, 10),
      paint..color = const Color(0xFFC0D9F2),
    );
    rect(const Rect.fromLTWH(30, 22, 69, 115), const Color(0xFFF7FBFF), 7);
    for (var i = 0; i < 8; i++) {
      rect(
        Rect.fromLTWH(39, 36 + i * 12, i.isEven ? 42 : 32, 4),
        const Color(0xFFD3E6FC),
        2,
      );
    }
    final shield = Path()
      ..moveTo(99, 27)
      ..cubicTo(85, 36, 72, 40, 59, 43)
      ..lineTo(59, 83)
      ..cubicTo(59, 111, 77, 128, 99, 139)
      ..cubicTo(121, 128, 139, 111, 139, 83)
      ..lineTo(139, 43)
      ..cubicTo(126, 40, 113, 36, 99, 27)
      ..close();
    canvas.drawShadow(shield, const Color(0xFF3376B5), 5, false);
    canvas.drawPath(shield, paint..color = const Color(0xFF80B5F4));
    canvas.save();
    canvas.translate(99, 83);
    canvas.scale(0.86);
    canvas.translate(-99, -83);
    canvas.drawPath(
      shield,
      paint
        ..shader = const LinearGradient(
          colors: [Color(0xFF2580DC), Color(0xFF084B9C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(const Rect.fromLTWH(59, 27, 80, 112)),
    );
    paint.shader = null;
    canvas.restore();
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(89, 59, 20, 27),
        const Radius.circular(10),
      ),
      Paint()
        ..color = const Color(0xFFF4FAFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
    rect(const Rect.fromLTWH(82, 74, 34, 29), const Color(0xFFF4FAFF), 5);
    canvas.drawCircle(
      const Offset(99, 86),
      3,
      paint..color = const Color(0xFF1969BA),
    );
    rect(const Rect.fromLTWH(97.5, 86, 3, 9), const Color(0xFF1969BA), 1);
    canvas.drawCircle(
      const Offset(131, 124),
      15,
      paint..color = const Color(0xFFF7FBFF),
    );
    canvas.drawCircle(
      const Offset(131, 124),
      12,
      paint..color = const Color(0xFF27B7A1),
    );
    canvas.drawPath(
      Path()
        ..moveTo(125, 124)
        ..lineTo(129, 128)
        ..lineTo(137, 120),
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PrivacyIllustration oldDelegate) => false;
}

class PrivacyPolicyPage extends StatefulWidget {
  const PrivacyPolicyPage({super.key});

  @override
  State<PrivacyPolicyPage> createState() => _PrivacyPolicyPageState();
}

class _PrivacyPolicyPageState extends State<PrivacyPolicyPage> {
  static const _sections = <({String title, String body})>[
    (
      title: 'Information you provide',
      body:
          'iTIWI uses account information such as your name, email address, account identifier, and profile photo. You may also provide a phone number and address in your profile. Google sign-in supplies account information used to authenticate you.\n\nReports include your description, category, attached photos, submission time, and account details. Service forms collect the information requested for the selected appointment or municipal service. Only include information needed for your concern or request.',
    ),
    (
      title: 'Why information is used',
      body:
          'Information supports sign-in, identity checks, report review, service requests, status updates, and municipal communication. Municipal personnel use submitted details to understand and process a concern or request.\n\nSome services require a signed-in, verified account. If you choose not to provide required details or complete verification, those services may not be available to you.',
    ),
    (
      title: 'Identity verification',
      body:
          'The current verification flow opens Didit, which asks for an identity document and selfie. Review the notices shown by Didit before continuing.\n\niTIWI stores verification session information, status, and decision information returned by the provider, including a reason when verification is declined. The current in-app flow does not ask you to attach ID photos to a report. Do not submit identity documents as ordinary report attachments.',
    ),
    (
      title: 'Photos and shared links',
      body:
          'Report photos are uploaded to cloud storage, and the report keeps links to those files. The app may resize and compress photos before upload. Compression is not anonymization: faces, document details, and other visible information can remain identifiable.\n\nReport photos currently use public file links. Anyone who obtains a working link may be able to view that image. Do not attach passwords, identity documents, financial information, or unrelated personal details. Avoid sharing another person’s information unless it is necessary and you have an appropriate basis to do so.',
    ),
    (
      title: 'Services that process data',
      body:
          'The app uses Firebase for authentication and push notifications, Supabase for app records and uploaded files, and Didit for identity verification. Google sign-in is used when you choose that sign-in option.\n\nMaps, linked websites, and online documents may load through other services. Those services receive the information needed to handle your interaction and have their own privacy notices. Review those notices before submitting information outside iTIWI.',
    ),
    (
      title: 'Notifications and device storage',
      body:
          'Push notifications use Firebase messaging identifiers and subscriptions to deliver announcements and account-related updates. You can manage notification permission and lock-screen previews in your phone’s settings. Notification previews may reveal information to someone looking at your screen.\n\nThe app keeps some content, preferences, and notification history on your device so previously loaded information can be shown again. Clearing the notification list does not delete reports, service requests, or other records stored by the municipality.',
    ),
    (
      title: 'Access and security',
      body:
          'Municipal administrators and service personnel review information submitted through the app. Hosting and verification services also process information needed to operate their features. The visibility of an uploaded image is explained separately under Photos and shared links.\n\nProtect your sign-in credentials, secure your device, and avoid using a shared account. No online service can guarantee complete security. If you suspect unauthorized access or disclosure, contact the municipality and describe what happened without sending passwords or unnecessary sensitive documents.',
    ),
    (
      title: 'Retention and deletion',
      body:
          'Signing out, uninstalling the app, or clearing local notifications does not automatically delete cloud records. Municipal reports, requests, and verification records may need to be kept for service processing and applicable recordkeeping obligations.\n\nAsk the municipality about the retention period for your particular record and whether it can be deleted. Deletion requests may be subject to identity checks and legal or public-record requirements. This notice does not specify a fixed retention period or promise immediate deletion.',
    ),
    (
      title: 'Your privacy rights',
      body:
          'Under applicable Philippine data-protection law, you may request information about how your data is processed, access to your data, and correction of inaccuracies. Rights to object, request erasure or blocking, and data portability apply in the circumstances provided by law.\n\nYou may raise a privacy concern with the municipality and file a complaint with the National Privacy Commission. Some requests may be limited by legal duties or other lawful grounds. The official guidance linked below explains these rights in more detail.',
    ),
    (
      title: 'Making a data request',
      body:
          'You can edit available account details from Profile. For access, correction, deletion, or another privacy concern, contact the Municipality of Tiwi through its published official contact channels and ask to be directed to the office responsible for data privacy.\n\nDescribe the request, the relevant report or service reference if you have one, and how you can be contacted. The office may need to confirm your identity. Do not send a password or a full ID document through an unverified contact channel.',
    ),
    (
      title: 'Changes to this notice',
      body:
          'Review this page when using a new feature or providing additional information. Changes to services and data handling may require an updated notice. Reading an updated notice or continuing to use the app does not, by itself, replace consent where consent is required.',
    ),
  ];
  final _search = TextEditingController();

  Future<void> _openRights() async {
    try {
      final opened = await launchUrl(
        Uri.parse('https://privacy.gov.ph/data-subject-rights/'),
        mode: LaunchMode.externalApplication,
      );
      if (opened || !mounted) return;
    } catch (_) {
      if (!mounted) return;
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to open the page. Visit privacy.gov.ph for privacy-rights guidance.',
          ),
        ),
      );
    }
  }

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
    final query = _search.text.trim().toLowerCase();
    final visible = _sections
        .where(
          (section) =>
              '${section.title} ${section.body}'.toLowerCase().contains(query),
        )
        .toList();
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text('Privacy Policy'),
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
                                        'PRIVACY POLICY',
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.8),
                                          fontSize: 10,
                                          letterSpacing: 2.2,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Your Privacy\nMatters',
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
                                        'How iTIWI handles your personal information when you use municipal services.',
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
                                  height: 144,
                                  child: const ExcludeSemantics(
                                    child: CustomPaint(
                                      painter: _PrivacyIllustration(),
                                    ),
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
                          hintText: 'Search privacy topics or keywords...',
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
                    'Try a keyword such as photos, verification, or deletion.',
                    style: TextStyle(color: secondary, height: 1.5),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () => setState(() {
                        _search.clear();
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
                                child: SelectableText(
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
                const SizedBox(height: 20),
                Text(
                  'Independent guidance',
                  style: TextStyle(
                    color: ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Learn about your rights from the National Privacy Commission.',
                  style: TextStyle(color: secondary, height: 1.5),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _openRights,
                    icon: const Icon(Icons.open_in_new, size: 17),
                    label: const Text('Read the NPC guidance'),
                    style: TextButton.styleFrom(foregroundColor: accent),
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
                            Flexible(
                              child: Text(
                                'Contact Us',
                                style: TextStyle(fontSize: 11),
                              ),
                            ),
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
