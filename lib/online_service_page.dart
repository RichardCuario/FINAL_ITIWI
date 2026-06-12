import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OnlineServicePage extends StatelessWidget {
  const OnlineServicePage({
    super.key,
    this.initialTarget = OnlineServiceTarget.none,
  });

  final OnlineServiceTarget initialTarget;

  static const List<_OnlineServiceCategory> _categories = [
    _OnlineServiceCategory(
      title: 'Document',
      icon: Icons.description_rounded,
      iconColor: Color(0xFF42A5F5),
      services: [
        OnlineServiceItem(
          title: 'Birth Certificate',
          icon: Icons.child_friendly_rounded,
          iconColor: Color(0xFF4FC3F7),
          target: OnlineServiceTarget.birthCertificate,
          opensBirthCertificateAppointmentForm: true,
        ),
        OnlineServiceItem(
          title: 'Marriage Certificate',
          icon: Icons.favorite_rounded,
          iconColor: Color(0xFFE91E63),
          target: OnlineServiceTarget.marriageCertificate,
          opensMarriageCertificateAppointmentForm: true,
        ),
        OnlineServiceItem(
          title: 'Death Certificate',
          icon: Icons.local_florist_rounded,
          iconColor: Color(0xFF7E57C2),
          target: OnlineServiceTarget.deathCertificate,
          opensDeathCertificateAppointmentForm: true,
        ),
        OnlineServiceItem(
          title: 'CENOMAR (Certificate of No Marriage Record)',
          icon: Icons.verified_user_rounded,
          iconColor: Color(0xFFFFB300),
          target: OnlineServiceTarget.cenomar,
          opensCenomarAppointmentForm: true,
        ),
        OnlineServiceItem(
          title: 'CENODEATH (Certificate of No Death)',
          icon: Icons.fact_check_rounded,
          iconColor: Color(0xFF26A69A),
          target: OnlineServiceTarget.cenodeath,
          opensCenodeathAppointmentForm: true,
        ),
      ],
    ),
    _OnlineServiceCategory(
      title: 'Facilities',
      icon: Icons.apartment_rounded,
      iconColor: Color(0xFF43A047),
      services: [
        OnlineServiceItem(
          title: 'Tiwi Gymnasium',
          icon: Icons.apartment_rounded,
          iconColor: Color(0xFF43A047),
          target: OnlineServiceTarget.tiwiGymnasium,
          opensBorrowForm: true,
        ),
        OnlineServiceItem(
          title: 'Libjo Facilities',
          icon: Icons.location_city_rounded,
          iconColor: Color(0xFF00897B),
          target: OnlineServiceTarget.libjoFacilities,
          opensBorrowForm: true,
        ),
      ],
    ),
  ];

  static OnlineServiceItem? findServiceByTarget(OnlineServiceTarget target) {
    for (final category in _categories) {
      for (final service in category.services) {
        if (service.target == target) {
          return service;
        }
      }
    }

    return null;
  }

  static void openTarget(BuildContext context, OnlineServiceTarget target) {
    if (target == OnlineServiceTarget.none) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const OnlineServicePage(),
        ),
      );
      return;
    }

    final service = findServiceByTarget(target);
    if (service == null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const OnlineServicePage(),
        ),
      );
      return;
    }

    _openServiceItem(context, service);
  }

  static void _openServiceItem(
    BuildContext context,
    OnlineServiceItem item,
  ) {
    if (item.opensBorrowForm) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => _FacilityBorrowRequestPage(item: item),
        ),
      );
      return;
    }

    if (item.opensBirthCertificateAppointmentForm) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => _BirthCertificateAppointmentPage(item: item),
        ),
      );
      return;
    }

    if (item.opensMarriageCertificateAppointmentForm) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => _MarriageCertificateAppointmentPage(item: item),
        ),
      );
      return;
    }

    if (item.opensDeathCertificateAppointmentForm) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => _DeathCertificateAppointmentPage(item: item),
        ),
      );
      return;
    }

    if (item.opensCenomarAppointmentForm) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => _CenomarAppointmentPage(item: item),
        ),
      );
      return;
    }

    if (item.opensCenodeathAppointmentForm) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => _CenodeathAppointmentPage(item: item),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${item.title} is coming soon.')),
    );
  }

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
            height: 210,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: topGradient,
                stops: const [0.0, 0.58, 1.0],
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
                      const Text(
                        'Online Service',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                    itemCount: _categories.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      return _OnlineServiceCategoryCard(category: category);
                    },
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

class _OnlineServiceCategoryCard extends StatelessWidget {
  const _OnlineServiceCategoryCard({required this.category});

  final _OnlineServiceCategory category;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  _OnlineServiceCategoryDetailsPage(category: category),
            ),
          );
        },
        child: Ink(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF262631) : Colors.white,
            borderRadius: BorderRadius.circular(22),
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: category.iconColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    category.icon,
                    color: category.iconColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    category.title,
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF20242C),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: isDark ? Colors.white54 : Colors.black38,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OnlineServiceCategoryDetailsPage extends StatelessWidget {
  const _OnlineServiceCategoryDetailsPage({required this.category});

  final _OnlineServiceCategory category;

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
            height: 210,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: topGradient,
                stops: const [0.0, 0.58, 1.0],
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
                      Expanded(
                        child: Text(
                          category.title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                    itemCount: category.services.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final item = category.services[index];
                      return _OnlineServiceCard(item: item);
                    },
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

class _OnlineServiceCard extends StatelessWidget {
  const _OnlineServiceCard({required this.item});

  final OnlineServiceItem item;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => OnlineServicePage._openServiceItem(context, item),
        child: Ink(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF262631) : Colors.white,
            borderRadius: BorderRadius.circular(22),
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: item.iconColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    item.icon,
                    color: item.iconColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    item.title,
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF20242C),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: isDark ? Colors.white54 : Colors.black38,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BirthCertificateAppointmentPage extends StatefulWidget {
  const _BirthCertificateAppointmentPage({required this.item});

  final OnlineServiceItem item;

  @override
  State<_BirthCertificateAppointmentPage> createState() =>
      _BirthCertificateAppointmentPageState();
}

class _BirthCertificateAppointmentPageState
    extends State<_BirthCertificateAppointmentPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _emailController = TextEditingController();
  final _requestorRelationshipController = TextEditingController();
  final _purposeController = TextEditingController();
  final _notesController = TextEditingController();

  firebase_auth.User? get _currentUser =>
      firebase_auth.FirebaseAuth.instance.currentUser;

  DateTime? _appointmentDate;
  TimeOfDay? _appointmentTime;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _contactNumberController.dispose();
    _emailController.dispose();
    _requestorRelationshipController.dispose();
    _purposeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickAppointmentDate() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year, now.month, now.day + 1);
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _appointmentDate ?? firstDate,
      firstDate: firstDate,
      lastDate: DateTime(now.year + 2),
    );

    if (pickedDate != null) {
      setState(() {
        _appointmentDate = pickedDate;
      });
    }
  }

  Future<void> _pickAppointmentTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _appointmentTime ?? const TimeOfDay(hour: 9, minute: 0),
    );

    if (pickedTime != null) {
      setState(() {
        _appointmentTime = pickedTime;
      });
    }
  }

  Future<List<Map<String, dynamic>>> _loadAppointments() async {
    final user = _currentUser;
    if (user == null) {
      return [];
    }

    final response = await Supabase.instance.client
        .from('birth_certificate_appointments')
        .select(
          'id, full_name, contact_number, email, relationship_to_owner, purpose, appointment_date, appointment_time, notes, status, created_at, updated_at',
        )
        .eq('user_id', user.uid)
        .order('created_at', ascending: false);

    return (response as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<void> _submitAppointment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final user = _currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in first before booking an appointment.'),
        ),
      );
      return;
    }

    if (_appointmentDate == null || _appointmentTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your preferred appointment schedule.'),
        ),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isSubmitting = true;
    });

    try {
      await Supabase.instance.client.from('birth_certificate_appointments').insert({
        'user_id': user.uid,
        'service_name': widget.item.title,
        'full_name': _fullNameController.text.trim(),
        'contact_number': _contactNumberController.text.trim(),
        'email': _emailController.text.trim(),
        'relationship_to_owner': _requestorRelationshipController.text.trim(),
        'purpose': _purposeController.text.trim(),
        'appointment_date': _appointmentDate!.toIso8601String().split('T').first,
        'appointment_time': _formatTime(_appointmentTime!),
        'notes': _notesController.text.trim(),
        'status': 'pending',
      });

      _fullNameController.clear();
      _contactNumberController.clear();
      _emailController.clear();
      _requestorRelationshipController.clear();
      _purposeController.clear();
      _notesController.clear();

      setState(() {
        _appointmentDate = null;
        _appointmentTime = null;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Birth certificate appointment submitted successfully.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to submit appointment: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  String _formatDate(dynamic value) {
    if (value == null) {
      return 'Not specified';
    }

    final DateTime? date = value is DateTime
        ? value
        : DateTime.tryParse(value.toString());

    if (date == null) {
      return value.toString();
    }

    final month = _monthName(date.month);
    return '$month ${date.day}, ${date.year}';
  }

  String _formatDateTimeUpdated(dynamic value) {
    if (value == null) {
      return 'Not available';
    }

    final DateTime? date = value is DateTime
        ? value
        : DateTime.tryParse(value.toString());

    if (date == null) {
      return value.toString();
    }

    final month = _monthName(date.month);
    final hour = date.hour == 0 ? 12 : (date.hour > 12 ? date.hour - 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$month ${date.day}, ${date.year} • $hour:$minute $period';
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  String _monthName(int month) {
    const months = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month];
  }

  String _statusLabel(String status) {
    switch (status.trim().toLowerCase()) {
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      default:
        return 'Pending';
    }
  }

  Color _statusColor(String status) {
    switch (status.trim().toLowerCase()) {
      case 'approved':
        return const Color(0xFF16A34A);
      case 'rejected':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF1E88E5);
    }
  }

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
            height: 230,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: topGradient,
                stops: const [0.0, 0.58, 1.0],
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
                      Expanded(
                        child: Text(
                          widget.item.title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _BorrowInfoCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Birth Certificate Appointment',
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF20242C),
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Book your schedule here to request and claim a birth certificate. Fill in the required details and wait for confirmation from the admin.',
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white70
                                        : const Color(0xFF5F6368),
                                    fontSize: 14,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _BorrowInfoCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Requirements',
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF20242C),
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Please prepare the following before booking or claiming a birth certificate:',
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white70
                                        : const Color(0xFF5F6368),
                                    fontSize: 14,
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                _RequirementItem(
                                  text: 'Valid ID of the requester',
                                ),
                                _RequirementItem(
                                  text: 'Complete name on the birth certificate',
                                ),
                                _RequirementItem(
                                  text: 'Date of birth',
                                ),
                                _RequirementItem(
                                  text: 'Place of birth',
                                ),
                                _RequirementItem(
                                  text: 'Full name of the mother',
                                ),
                                _RequirementItem(
                                  text: 'Full name of the father, if available',
                                ),
                                _RequirementItem(
                                  text: 'Authorization letter and valid ID of the certificate owner if the requester is not the owner',
                                ),
                                _RequirementItem(
                                  text: 'Extra cash for applicable processing and copy fees',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _BorrowInfoCard(
                            child: Column(
                              children: [
                                _BorrowTextField(
                                  controller: _fullNameController,
                                  label: 'Full Name',
                                  hint: 'Enter your full name',
                                ),
                                const SizedBox(height: 14),
                                _BorrowTextField(
                                  controller: _contactNumberController,
                                  label: 'Contact Number',
                                  hint: 'Enter your contact number',
                                  keyboardType: TextInputType.phone,
                                ),
                                const SizedBox(height: 14),
                                _BorrowTextField(
                                  controller: _emailController,
                                  label: 'Email Address',
                                  hint: 'Enter your email address',
                                  keyboardType: TextInputType.emailAddress,
                                ),
                                const SizedBox(height: 14),
                                _BorrowTextField(
                                  controller: _requestorRelationshipController,
                                  label: 'Relationship to Certificate Owner',
                                  hint: 'Example: Self, Parent, Sister',
                                ),
                                const SizedBox(height: 14),
                                _BorrowTextField(
                                  controller: _purposeController,
                                  label: 'Purpose of Request',
                                  hint: 'Enter the purpose of the birth certificate request',
                                  maxLines: 3,
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _BorrowDateTimeField(
                                        label: 'Appointment Date',
                                        value: _appointmentDate == null
                                            ? 'Select date'
                                            : _formatDate(_appointmentDate!),
                                        icon: Icons.calendar_month_rounded,
                                        onTap: _pickAppointmentDate,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _BorrowDateTimeField(
                                        label: 'Appointment Time',
                                        value: _appointmentTime == null
                                            ? 'Select time'
                                            : _formatTime(_appointmentTime!),
                                        icon: Icons.access_time_rounded,
                                        onTap: _pickAppointmentTime,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                _BorrowTextField(
                                  controller: _notesController,
                                  label: 'Additional Notes',
                                  hint: 'Add other important details',
                                  maxLines: 4,
                                  requiredField: false,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: _isSubmitting ? null : _submitAppointment,
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF1E88E5),
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              child: Text(
                                _isSubmitting ? 'Submitting...' : 'Book Appointment',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _BorrowInfoCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'My Birth Certificate Appointments',
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF20242C),
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Your submitted appointments and their latest approval status will appear here.',
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white70
                                        : const Color(0xFF5F6368),
                                    fontSize: 14,
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                FutureBuilder<List<Map<String, dynamic>>>(
                                  future: _loadAppointments(),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Padding(
                                        padding:
                                            EdgeInsets.symmetric(vertical: 12),
                                        child: Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      );
                                    }

                                    if (_currentUser == null) {
                                      return Text(
                                        'Please sign in to view your submitted appointments.',
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.white70
                                              : const Color(0xFF5F6368),
                                          fontSize: 14,
                                          height: 1.5,
                                        ),
                                      );
                                    }

                                    if (snapshot.hasError) {
                                      return Text(
                                        'Unable to load your birth certificate appointments right now.',
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.white70
                                              : const Color(0xFF5F6368),
                                          fontSize: 14,
                                          height: 1.5,
                                        ),
                                      );
                                    }

                                    final appointments = snapshot.data ?? [];
                                    if (appointments.isEmpty) {
                                      return Text(
                                        'You have not booked any birth certificate appointment yet.',
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.white70
                                              : const Color(0xFF5F6368),
                                          fontSize: 14,
                                          height: 1.5,
                                        ),
                                      );
                                    }

                                    return Column(
                                      children: appointments.map((appointment) {
                                        final status =
                                            appointment['status']?.toString() ??
                                                'pending';
                                        final statusColor =
                                            _statusColor(status);

                                        return Container(
                                          width: double.infinity,
                                          margin:
                                              const EdgeInsets.only(bottom: 12),
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? const Color(0xFF1F1F28)
                                                : const Color(0xFFF7F8FA),
                                            borderRadius:
                                                BorderRadius.circular(18),
                                            border: Border.all(
                                              color: isDark
                                                  ? Colors.white10
                                                  : const Color(0xFFDADCE0),
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      appointment['full_name']
                                                                  ?.toString()
                                                                  .trim()
                                                                  .isNotEmpty ==
                                                              true
                                                          ? appointment['full_name']
                                                              .toString()
                                                          : 'Birth Certificate Appointment',
                                                      style: TextStyle(
                                                        color: isDark
                                                            ? Colors.white
                                                            : const Color(
                                                                0xFF20242C),
                                                        fontSize: 15,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                    ),
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 12,
                                                      vertical: 6,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: statusColor
                                                          .withValues(
                                                            alpha: 0.12,
                                                          ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            999,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      _statusLabel(status),
                                                      style: TextStyle(
                                                        color: statusColor,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        fontSize: 12.5,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 10),
                                              Text(
                                                'Schedule: ${_formatDate(appointment['appointment_date']?.toString())} • ${appointment['appointment_time'] ?? 'N/A'}',
                                                style: TextStyle(
                                                  color: isDark
                                                      ? Colors.white70
                                                      : const Color(0xFF5F6368),
                                                  fontSize: 13,
                                                  height: 1.5,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                'Purpose: ${appointment['purpose']?.toString().trim().isNotEmpty == true ? appointment['purpose'].toString() : 'No purpose provided'}',
                                                style: TextStyle(
                                                  color: isDark
                                                      ? Colors.white70
                                                      : const Color(0xFF5F6368),
                                                  fontSize: 13,
                                                  height: 1.5,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                'Updated: ${_formatDateTimeUpdated(appointment['updated_at']?.toString())}',
                                                style: TextStyle(
                                                  color: isDark
                                                      ? Colors.white54
                                                      : const Color(0xFF7A7F87),
                                                  fontSize: 12.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
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

class _MarriageCertificateAppointmentPage extends StatefulWidget {
  const _MarriageCertificateAppointmentPage({required this.item});

  final OnlineServiceItem item;

  @override
  State<_MarriageCertificateAppointmentPage> createState() =>
      _MarriageCertificateAppointmentPageState();
}

class _MarriageCertificateAppointmentPageState
    extends State<_MarriageCertificateAppointmentPage> {
  final _formKey = GlobalKey<FormState>();
  final _husbandNameController = TextEditingController();
  final _wifeNameController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _emailController = TextEditingController();
  final _requestorRelationshipController = TextEditingController();
  final _purposeController = TextEditingController();
  final _notesController = TextEditingController();

  firebase_auth.User? get _currentUser =>
      firebase_auth.FirebaseAuth.instance.currentUser;

  DateTime? _appointmentDate;
  TimeOfDay? _appointmentTime;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _husbandNameController.dispose();
    _wifeNameController.dispose();
    _contactNumberController.dispose();
    _emailController.dispose();
    _requestorRelationshipController.dispose();
    _purposeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickAppointmentDate() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year, now.month, now.day + 1);
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _appointmentDate ?? firstDate,
      firstDate: firstDate,
      lastDate: DateTime(now.year + 2),
    );

    if (pickedDate != null) {
      setState(() {
        _appointmentDate = pickedDate;
      });
    }
  }

  Future<void> _pickAppointmentTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _appointmentTime ?? const TimeOfDay(hour: 9, minute: 0),
    );

    if (pickedTime != null) {
      setState(() {
        _appointmentTime = pickedTime;
      });
    }
  }

  Future<List<Map<String, dynamic>>> _loadAppointments() async {
    final user = _currentUser;
    if (user == null) {
      return [];
    }

    final response = await Supabase.instance.client
        .from('marriage_certificate_appointments')
        .select(
          'id, husband_name, wife_name, contact_number, email, relationship_to_owner, purpose, appointment_date, appointment_time, notes, status, created_at, updated_at',
        )
        .eq('user_id', user.uid)
        .order('created_at', ascending: false);

    return (response as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<void> _submitAppointment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final user = _currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in first before booking an appointment.'),
        ),
      );
      return;
    }

    if (_appointmentDate == null || _appointmentTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your preferred appointment schedule.'),
        ),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isSubmitting = true;
    });

    try {
      await Supabase.instance.client.from('marriage_certificate_appointments').insert({
        'user_id': user.uid,
        'service_name': widget.item.title,
        'husband_name': _husbandNameController.text.trim(),
        'wife_name': _wifeNameController.text.trim(),
        'contact_number': _contactNumberController.text.trim(),
        'email': _emailController.text.trim(),
        'relationship_to_owner': _requestorRelationshipController.text.trim(),
        'purpose': _purposeController.text.trim(),
        'appointment_date': _appointmentDate!.toIso8601String().split('T').first,
        'appointment_time': _formatTime(_appointmentTime!),
        'notes': _notesController.text.trim(),
        'status': 'pending',
      });

      _husbandNameController.clear();
      _wifeNameController.clear();
      _contactNumberController.clear();
      _emailController.clear();
      _requestorRelationshipController.clear();
      _purposeController.clear();
      _notesController.clear();

      setState(() {
        _appointmentDate = null;
        _appointmentTime = null;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Marriage certificate appointment submitted successfully.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to submit appointment: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  String _formatDate(dynamic value) {
    if (value == null) {
      return 'Not specified';
    }

    final DateTime? date = value is DateTime
        ? value
        : DateTime.tryParse(value.toString());

    if (date == null) {
      return value.toString();
    }

    final month = _monthName(date.month);
    return '$month ${date.day}, ${date.year}';
  }

  String _formatDateTimeUpdated(dynamic value) {
    if (value == null) {
      return 'Not available';
    }

    final DateTime? date = value is DateTime
        ? value
        : DateTime.tryParse(value.toString());

    if (date == null) {
      return value.toString();
    }

    final month = _monthName(date.month);
    final hour = date.hour == 0 ? 12 : (date.hour > 12 ? date.hour - 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$month ${date.day}, ${date.year} • $hour:$minute $period';
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  String _monthName(int month) {
    const months = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month];
  }

  String _statusLabel(String status) {
    switch (status.trim().toLowerCase()) {
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      default:
        return 'Pending';
    }
  }

  Color _statusColor(String status) {
    switch (status.trim().toLowerCase()) {
      case 'approved':
        return const Color(0xFF16A34A);
      case 'rejected':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFFE91E63);
    }
  }

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
            Color(0xFFE91E63),
            Color(0xFFF48FB1),
            Color(0xFFEAEAEA),
          ];

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          Container(
            height: 230,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: topGradient,
                stops: const [0.0, 0.58, 1.0],
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
                      Expanded(
                        child: Text(
                          widget.item.title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _BorrowInfoCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Marriage Certificate Appointment',
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF20242C),
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Book your schedule here to request and claim a marriage certificate. Fill in the required details and wait for confirmation from the admin.',
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white70
                                        : const Color(0xFF5F6368),
                                    fontSize: 14,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _BorrowInfoCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Requirements',
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF20242C),
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Please prepare the following before booking or claiming a marriage certificate:',
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white70
                                        : const Color(0xFF5F6368),
                                    fontSize: 14,
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                _RequirementItem(
                                  text: 'Valid ID of the requester',
                                ),
                                _RequirementItem(
                                  text: 'Complete name of husband',
                                ),
                                _RequirementItem(
                                  text: 'Complete maiden name of wife',
                                ),
                                _RequirementItem(
                                  text: 'Date of marriage',
                                ),
                                _RequirementItem(
                                  text: 'Place of marriage',
                                ),
                                _RequirementItem(
                                  text: 'Authorization letter and valid ID of either spouse if the requester is not one of them',
                                ),
                                _RequirementItem(
                                  text: 'Extra cash for applicable processing and copy fees',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _BorrowInfoCard(
                            child: Column(
                              children: [
                                _BorrowTextField(
                                  controller: _husbandNameController,
                                  label: 'Husband Name',
                                  hint: 'Enter complete name of husband',
                                ),
                                const SizedBox(height: 14),
                                _BorrowTextField(
                                  controller: _wifeNameController,
                                  label: 'Wife Name',
                                  hint: 'Enter complete maiden name of wife',
                                ),
                                const SizedBox(height: 14),
                                _BorrowTextField(
                                  controller: _contactNumberController,
                                  label: 'Contact Number',
                                  hint: 'Enter your contact number',
                                  keyboardType: TextInputType.phone,
                                ),
                                const SizedBox(height: 14),
                                _BorrowTextField(
                                  controller: _emailController,
                                  label: 'Email Address',
                                  hint: 'Enter your email address',
                                  keyboardType: TextInputType.emailAddress,
                                ),
                                const SizedBox(height: 14),
                                _BorrowTextField(
                                  controller: _requestorRelationshipController,
                                  label: 'Relationship to Certificate Owner',
                                  hint: 'Example: Self, Son, Daughter, Representative',
                                ),
                                const SizedBox(height: 14),
                                _BorrowTextField(
                                  controller: _purposeController,
                                  label: 'Purpose of Request',
                                  hint: 'Enter the purpose of the marriage certificate request',
                                  maxLines: 3,
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _BorrowDateTimeField(
                                        label: 'Appointment Date',
                                        value: _appointmentDate == null
                                            ? 'Select date'
                                            : _formatDate(_appointmentDate!),
                                        icon: Icons.calendar_month_rounded,
                                        onTap: _pickAppointmentDate,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _BorrowDateTimeField(
                                        label: 'Appointment Time',
                                        value: _appointmentTime == null
                                            ? 'Select time'
                                            : _formatTime(_appointmentTime!),
                                        icon: Icons.access_time_rounded,
                                        onTap: _pickAppointmentTime,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                _BorrowTextField(
                                  controller: _notesController,
                                  label: 'Additional Notes',
                                  hint: 'Add other important details',
                                  maxLines: 4,
                                  requiredField: false,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: _isSubmitting ? null : _submitAppointment,
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFFE91E63),
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              child: Text(
                                _isSubmitting ? 'Submitting...' : 'Book Appointment',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _BorrowInfoCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'My Marriage Certificate Appointments',
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF20242C),
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Your submitted appointments and their latest approval status will appear here.',
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white70
                                        : const Color(0xFF5F6368),
                                    fontSize: 14,
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                FutureBuilder<List<Map<String, dynamic>>>(
                                  future: _loadAppointments(),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Padding(
                                        padding:
                                            EdgeInsets.symmetric(vertical: 12),
                                        child: Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      );
                                    }

                                    if (_currentUser == null) {
                                      return Text(
                                        'Please sign in to view your submitted appointments.',
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.white70
                                              : const Color(0xFF5F6368),
                                          fontSize: 14,
                                          height: 1.5,
                                        ),
                                      );
                                    }

                                    if (snapshot.hasError) {
                                      return Text(
                                        'Unable to load your marriage certificate appointments right now.',
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.white70
                                              : const Color(0xFF5F6368),
                                          fontSize: 14,
                                          height: 1.5,
                                        ),
                                      );
                                    }

                                    final appointments = snapshot.data ?? [];
                                    if (appointments.isEmpty) {
                                      return Text(
                                        'You have not booked any marriage certificate appointment yet.',
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.white70
                                              : const Color(0xFF5F6368),
                                          fontSize: 14,
                                          height: 1.5,
                                        ),
                                      );
                                    }

                                    return Column(
                                      children: appointments.map((appointment) {
                                        final status =
                                            appointment['status']?.toString() ??
                                                'pending';
                                        final statusColor =
                                            _statusColor(status);

                                        final husbandName =
                                            appointment['husband_name']
                                                ?.toString()
                                                .trim() ??
                                            '';
                                        final wifeName =
                                            appointment['wife_name']
                                                ?.toString()
                                                .trim() ??
                                            '';
                                        final title = husbandName.isNotEmpty ||
                                                wifeName.isNotEmpty
                                            ? '$husbandName & $wifeName'
                                            : 'Marriage Certificate Appointment';

                                        return Container(
                                          width: double.infinity,
                                          margin:
                                              const EdgeInsets.only(bottom: 12),
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? const Color(0xFF1F1F28)
                                                : const Color(0xFFF7F8FA),
                                            borderRadius:
                                                BorderRadius.circular(18),
                                            border: Border.all(
                                              color: isDark
                                                  ? Colors.white10
                                                  : const Color(0xFFDADCE0),
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      title,
                                                      style: TextStyle(
                                                        color: isDark
                                                            ? Colors.white
                                                            : const Color(
                                                                0xFF20242C),
                                                        fontSize: 15,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                    ),
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 12,
                                                      vertical: 6,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: statusColor
                                                          .withValues(
                                                            alpha: 0.12,
                                                          ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            999,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      _statusLabel(status),
                                                      style: TextStyle(
                                                        color: statusColor,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        fontSize: 12.5,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 10),
                                              Text(
                                                'Schedule: ${_formatDate(appointment['appointment_date']?.toString())} • ${appointment['appointment_time'] ?? 'N/A'}',
                                                style: TextStyle(
                                                  color: isDark
                                                      ? Colors.white70
                                                      : const Color(0xFF5F6368),
                                                  fontSize: 13,
                                                  height: 1.5,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                'Purpose: ${appointment['purpose']?.toString().trim().isNotEmpty == true ? appointment['purpose'].toString() : 'No purpose provided'}',
                                                style: TextStyle(
                                                  color: isDark
                                                      ? Colors.white70
                                                      : const Color(0xFF5F6368),
                                                  fontSize: 13,
                                                  height: 1.5,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                'Updated: ${_formatDateTimeUpdated(appointment['updated_at']?.toString())}',
                                                style: TextStyle(
                                                  color: isDark
                                                      ? Colors.white54
                                                      : const Color(0xFF7A7F87),
                                                  fontSize: 12.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
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

class _DeathCertificateAppointmentPage extends StatefulWidget {
  const _DeathCertificateAppointmentPage({required this.item});

  final OnlineServiceItem item;

  @override
  State<_DeathCertificateAppointmentPage> createState() =>
      _DeathCertificateAppointmentPageState();
}

class _DeathCertificateAppointmentPageState
    extends State<_DeathCertificateAppointmentPage> {
  final _formKey = GlobalKey<FormState>();
  final _deceasedFullNameController = TextEditingController();
  final _dateOfDeathController = TextEditingController();
  final _placeOfDeathController = TextEditingController();
  final _requestorFullNameController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _emailController = TextEditingController();
  final _requestorRelationshipController = TextEditingController();
  final _purposeController = TextEditingController();
  final _notesController = TextEditingController();

  firebase_auth.User? get _currentUser =>
      firebase_auth.FirebaseAuth.instance.currentUser;

  DateTime? _appointmentDate;
  TimeOfDay? _appointmentTime;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _deceasedFullNameController.dispose();
    _dateOfDeathController.dispose();
    _placeOfDeathController.dispose();
    _requestorFullNameController.dispose();
    _contactNumberController.dispose();
    _emailController.dispose();
    _requestorRelationshipController.dispose();
    _purposeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickAppointmentDate() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year, now.month, now.day + 1);
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _appointmentDate ?? firstDate,
      firstDate: firstDate,
      lastDate: DateTime(now.year + 2),
    );

    if (pickedDate != null) {
      setState(() {
        _appointmentDate = pickedDate;
      });
    }
  }

  Future<void> _pickAppointmentTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _appointmentTime ?? const TimeOfDay(hour: 9, minute: 0),
    );

    if (pickedTime != null) {
      setState(() {
        _appointmentTime = pickedTime;
      });
    }
  }

  Future<List<Map<String, dynamic>>> _loadAppointments() async {
    final user = _currentUser;
    if (user == null) {
      return [];
    }

    final response = await Supabase.instance.client
        .from('death_certificate_appointments')
        .select(
          'id, deceased_full_name, date_of_death, place_of_death, requestor_full_name, contact_number, email, relationship_to_owner, purpose, appointment_date, appointment_time, notes, status, created_at, updated_at',
        )
        .eq('user_id', user.uid)
        .order('created_at', ascending: false);

    return (response as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<void> _submitAppointment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final user = _currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in first before booking an appointment.'),
        ),
      );
      return;
    }

    if (_appointmentDate == null || _appointmentTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your preferred appointment schedule.'),
        ),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isSubmitting = true;
    });

    try {
      await Supabase.instance.client.from('death_certificate_appointments').insert({
        'user_id': user.uid,
        'service_name': widget.item.title,
        'deceased_full_name': _deceasedFullNameController.text.trim(),
        'date_of_death': _dateOfDeathController.text.trim(),
        'place_of_death': _placeOfDeathController.text.trim(),
        'requestor_full_name': _requestorFullNameController.text.trim(),
        'contact_number': _contactNumberController.text.trim(),
        'email': _emailController.text.trim(),
        'relationship_to_owner': _requestorRelationshipController.text.trim(),
        'purpose': _purposeController.text.trim(),
        'appointment_date': _appointmentDate!.toIso8601String().split('T').first,
        'appointment_time': _formatTime(_appointmentTime!),
        'notes': _notesController.text.trim(),
        'status': 'pending',
      });

      _deceasedFullNameController.clear();
      _dateOfDeathController.clear();
      _placeOfDeathController.clear();
      _requestorFullNameController.clear();
      _contactNumberController.clear();
      _emailController.clear();
      _requestorRelationshipController.clear();
      _purposeController.clear();
      _notesController.clear();

      setState(() {
        _appointmentDate = null;
        _appointmentTime = null;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Death certificate appointment submitted successfully.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to submit appointment: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  String _formatDate(dynamic value) {
    if (value == null) {
      return 'Not specified';
    }

    final DateTime? date = value is DateTime
        ? value
        : DateTime.tryParse(value.toString());

    if (date == null) {
      return value.toString();
    }

    final month = _monthName(date.month);
    return '$month ${date.day}, ${date.year}';
  }

  String _formatDateTimeUpdated(dynamic value) {
    if (value == null) {
      return 'Not available';
    }

    final DateTime? date = value is DateTime
        ? value
        : DateTime.tryParse(value.toString());

    if (date == null) {
      return value.toString();
    }

    final month = _monthName(date.month);
    final hour = date.hour == 0 ? 12 : (date.hour > 12 ? date.hour - 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$month ${date.day}, ${date.year} • $hour:$minute $period';
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  String _monthName(int month) {
    const months = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month];
  }

  String _statusLabel(String status) {
    switch (status.trim().toLowerCase()) {
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      default:
        return 'Pending';
    }
  }

  Color _statusColor(String status) {
    switch (status.trim().toLowerCase()) {
      case 'approved':
        return const Color(0xFF16A34A);
      case 'rejected':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF7E57C2);
    }
  }

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
            Color(0xFF7E57C2),
            Color(0xFFB39DDB),
            Color(0xFFEAEAEA),
          ];

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          Container(
            height: 230,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: topGradient,
                stops: const [0.0, 0.58, 1.0],
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
                      Expanded(
                        child: Text(
                          widget.item.title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _BorrowInfoCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Death Certificate Appointment',
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF20242C),
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Book your schedule here to request and claim a death certificate. Fill in the required details and wait for confirmation from the admin.',
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white70
                                        : const Color(0xFF5F6368),
                                    fontSize: 14,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _BorrowInfoCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Requirements',
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF20242C),
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Please prepare the following before booking or claiming a death certificate:',
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white70
                                        : const Color(0xFF5F6368),
                                    fontSize: 14,
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                _RequirementItem(
                                  text: 'Valid ID of the requester',
                                ),
                                _RequirementItem(
                                  text: 'Complete name of the deceased person',
                                ),
                                _RequirementItem(
                                  text: 'Date of death',
                                ),
                                _RequirementItem(
                                  text: 'Place of death',
                                ),
                                _RequirementItem(
                                  text: 'Relationship to the deceased person',
                                ),
                                _RequirementItem(
                                  text: 'Authorization letter and valid ID if the requester is not an immediate family member',
                                ),
                                _RequirementItem(
                                  text: 'Extra cash for applicable processing and copy fees',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _BorrowInfoCard(
                            child: Column(
                              children: [
                                _BorrowTextField(
                                  controller: _deceasedFullNameController,
                                  label: 'Deceased Full Name',
                                  hint: 'Enter complete name of the deceased',
                                ),
                                const SizedBox(height: 14),
                                _BorrowTextField(
                                  controller: _dateOfDeathController,
                                  label: 'Date of Death',
                                  hint: 'Enter date of death',
                                ),
                                const SizedBox(height: 14),
                                _BorrowTextField(
                                  controller: _placeOfDeathController,
                                  label: 'Place of Death',
                                  hint: 'Enter place of death',
                                ),
                                const SizedBox(height: 14),
                                _BorrowTextField(
                                  controller: _requestorFullNameController,
                                  label: 'Requester Full Name',
                                  hint: 'Enter your full name',
                                ),
                                const SizedBox(height: 14),
                                _BorrowTextField(
                                  controller: _contactNumberController,
                                  label: 'Contact Number',
                                  hint: 'Enter your contact number',
                                  keyboardType: TextInputType.phone,
                                ),
                                const SizedBox(height: 14),
                                _BorrowTextField(
                                  controller: _emailController,
                                  label: 'Email Address',
                                  hint: 'Enter your email address',
                                  keyboardType: TextInputType.emailAddress,
                                ),
                                const SizedBox(height: 14),
                                _BorrowTextField(
                                  controller: _requestorRelationshipController,
                                  label: 'Relationship to Deceased',
                                  hint: 'Example: Spouse, Son, Daughter, Sibling',
                                ),
                                const SizedBox(height: 14),
                                _BorrowTextField(
                                  controller: _purposeController,
                                  label: 'Purpose of Request',
                                  hint: 'Enter the purpose of the death certificate request',
                                  maxLines: 3,
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _BorrowDateTimeField(
                                        label: 'Appointment Date',
                                        value: _appointmentDate == null
                                            ? 'Select date'
                                            : _formatDate(_appointmentDate!),
                                        icon: Icons.calendar_month_rounded,
                                        onTap: _pickAppointmentDate,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _BorrowDateTimeField(
                                        label: 'Appointment Time',
                                        value: _appointmentTime == null
                                            ? 'Select time'
                                            : _formatTime(_appointmentTime!),
                                        icon: Icons.access_time_rounded,
                                        onTap: _pickAppointmentTime,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                _BorrowTextField(
                                  controller: _notesController,
                                  label: 'Additional Notes',
                                  hint: 'Add other important details',
                                  maxLines: 4,
                                  requiredField: false,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: _isSubmitting ? null : _submitAppointment,
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF7E57C2),
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              child: Text(
                                _isSubmitting ? 'Submitting...' : 'Book Appointment',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _BorrowInfoCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'My Death Certificate Appointments',
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF20242C),
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Your submitted appointments and their latest approval status will appear here.',
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white70
                                        : const Color(0xFF5F6368),
                                    fontSize: 14,
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                FutureBuilder<List<Map<String, dynamic>>>(
                                  future: _loadAppointments(),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Padding(
                                        padding:
                                            EdgeInsets.symmetric(vertical: 12),
                                        child: Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      );
                                    }

                                    if (_currentUser == null) {
                                      return Text(
                                        'Please sign in to view your submitted appointments.',
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.white70
                                              : const Color(0xFF5F6368),
                                          fontSize: 14,
                                          height: 1.5,
                                        ),
                                      );
                                    }

                                    if (snapshot.hasError) {
                                      return Text(
                                        'Unable to load your death certificate appointments right now.',
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.white70
                                              : const Color(0xFF5F6368),
                                          fontSize: 14,
                                          height: 1.5,
                                        ),
                                      );
                                    }

                                    final appointments = snapshot.data ?? [];
                                    if (appointments.isEmpty) {
                                      return Text(
                                        'You have not booked any death certificate appointment yet.',
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.white70
                                              : const Color(0xFF5F6368),
                                          fontSize: 14,
                                          height: 1.5,
                                        ),
                                      );
                                    }

                                    return Column(
                                      children: appointments.map((appointment) {
                                        final status =
                                            appointment['status']?.toString() ??
                                                'pending';
                                        final statusColor =
                                            _statusColor(status);

                                        return Container(
                                          width: double.infinity,
                                          margin:
                                              const EdgeInsets.only(bottom: 12),
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? const Color(0xFF1F1F28)
                                                : const Color(0xFFF7F8FA),
                                            borderRadius:
                                                BorderRadius.circular(18),
                                            border: Border.all(
                                              color: isDark
                                                  ? Colors.white10
                                                  : const Color(0xFFDADCE0),
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      appointment['deceased_full_name']
                                                                  ?.toString()
                                                                  .trim()
                                                                  .isNotEmpty ==
                                                              true
                                                          ? appointment['deceased_full_name']
                                                              .toString()
                                                          : 'Death Certificate Appointment',
                                                      style: TextStyle(
                                                        color: isDark
                                                            ? Colors.white
                                                            : const Color(
                                                                0xFF20242C),
                                                        fontSize: 15,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                    ),
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 12,
                                                      vertical: 6,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: statusColor
                                                          .withValues(
                                                            alpha: 0.12,
                                                          ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            999,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      _statusLabel(status),
                                                      style: TextStyle(
                                                        color: statusColor,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        fontSize: 12.5,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 10),
                                              Text(
                                                'Schedule: ${_formatDate(appointment['appointment_date']?.toString())} • ${appointment['appointment_time'] ?? 'N/A'}',
                                                style: TextStyle(
                                                  color: isDark
                                                      ? Colors.white70
                                                      : const Color(0xFF5F6368),
                                                  fontSize: 13,
                                                  height: 1.5,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                'Purpose: ${appointment['purpose']?.toString().trim().isNotEmpty == true ? appointment['purpose'].toString() : 'No purpose provided'}',
                                                style: TextStyle(
                                                  color: isDark
                                                      ? Colors.white70
                                                      : const Color(0xFF5F6368),
                                                  fontSize: 13,
                                                  height: 1.5,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                'Updated: ${_formatDateTimeUpdated(appointment['updated_at']?.toString())}',
                                                style: TextStyle(
                                                  color: isDark
                                                      ? Colors.white54
                                                      : const Color(0xFF7A7F87),
                                                  fontSize: 12.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
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

class _CenomarAppointmentPage extends StatefulWidget {
  const _CenomarAppointmentPage({required this.item});

  final OnlineServiceItem item;

  @override
  State<_CenomarAppointmentPage> createState() =>
      _CenomarAppointmentPageState();
}

class _CenomarAppointmentPageState extends State<_CenomarAppointmentPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _emailController = TextEditingController();
  final _requestorRelationshipController = TextEditingController();
  final _purposeController = TextEditingController();
  final _notesController = TextEditingController();

  firebase_auth.User? get _currentUser =>
      firebase_auth.FirebaseAuth.instance.currentUser;

  DateTime? _appointmentDate;
  TimeOfDay? _appointmentTime;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _contactNumberController.dispose();
    _emailController.dispose();
    _requestorRelationshipController.dispose();
    _purposeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickAppointmentDate() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year, now.month, now.day + 1);
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _appointmentDate ?? firstDate,
      firstDate: firstDate,
      lastDate: DateTime(now.year + 2),
    );

    if (pickedDate != null) {
      setState(() {
        _appointmentDate = pickedDate;
      });
    }
  }

  Future<void> _pickAppointmentTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _appointmentTime ?? const TimeOfDay(hour: 9, minute: 0),
    );

    if (pickedTime != null) {
      setState(() {
        _appointmentTime = pickedTime;
      });
    }
  }

  Future<List<Map<String, dynamic>>> _loadAppointments() async {
    final user = _currentUser;
    if (user == null) {
      return [];
    }

    final response = await Supabase.instance.client
        .from('cenomar_appointments')
        .select(
          'id, full_name, contact_number, email, relationship_to_owner, purpose, appointment_date, appointment_time, notes, status, created_at, updated_at',
        )
        .eq('user_id', user.uid)
        .order('created_at', ascending: false);

    return (response as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<void> _submitAppointment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final user = _currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in first before booking an appointment.'),
        ),
      );
      return;
    }

    if (_appointmentDate == null || _appointmentTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your preferred appointment schedule.'),
        ),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isSubmitting = true;
    });

    try {
      await Supabase.instance.client.from('cenomar_appointments').insert({
        'user_id': user.uid,
        'service_name': widget.item.title,
        'full_name': _fullNameController.text.trim(),
        'contact_number': _contactNumberController.text.trim(),
        'email': _emailController.text.trim(),
        'relationship_to_owner': _requestorRelationshipController.text.trim(),
        'purpose': _purposeController.text.trim(),
        'appointment_date': _appointmentDate!.toIso8601String().split('T').first,
        'appointment_time': _formatTime(_appointmentTime!),
        'notes': _notesController.text.trim(),
        'status': 'pending',
      });

      _fullNameController.clear();
      _contactNumberController.clear();
      _emailController.clear();
      _requestorRelationshipController.clear();
      _purposeController.clear();
      _notesController.clear();

      setState(() {
        _appointmentDate = null;
        _appointmentTime = null;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'CENOMAR appointment submitted successfully.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to submit appointment: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  String _formatDate(dynamic value) {
    if (value == null) {
      return 'Not specified';
    }

    final DateTime? date = value is DateTime
        ? value
        : DateTime.tryParse(value.toString());

    if (date == null) {
      return value.toString();
    }

    final month = _monthName(date.month);
    return '$month ${date.day}, ${date.year}';
  }

  String _formatDateTimeUpdated(dynamic value) {
    if (value == null) {
      return 'Not available';
    }

    final DateTime? date = value is DateTime
        ? value
        : DateTime.tryParse(value.toString());

    if (date == null) {
      return value.toString();
    }

    final month = _monthName(date.month);
    final hour = date.hour == 0 ? 12 : (date.hour > 12 ? date.hour - 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$month ${date.day}, ${date.year} • $hour:$minute $period';
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  String _monthName(int month) {
    const months = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month];
  }

  String _statusLabel(String status) {
    switch (status.trim().toLowerCase()) {
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      default:
        return 'Pending';
    }
  }

  Color _statusColor(String status) {
    switch (status.trim().toLowerCase()) {
      case 'approved':
        return const Color(0xFF16A34A);
      case 'rejected':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFFFFB300);
    }
  }

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
            Color(0xFFFFB300),
            Color(0xFFFFE082),
            Color(0xFFEAEAEA),
          ];

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          Container(
            height: 230,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: topGradient,
                stops: const [0.0, 0.58, 1.0],
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
                      Expanded(
                        child: Text(
                          widget.item.title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _BorrowInfoCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'CENOMAR Appointment',
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF20242C),
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Book your schedule here to request and claim a Certificate of No Marriage Record (CENOMAR). Fill in the required details and wait for confirmation from the admin.',
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white70
                                        : const Color(0xFF5F6368),
                                    fontSize: 14,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _BorrowInfoCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Requirements',
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF20242C),
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Please prepare the following before booking or claiming a CENOMAR:',
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white70
                                        : const Color(0xFF5F6368),
                                    fontSize: 14,
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                _RequirementItem(
                                  text: 'Valid ID of the requester',
                                ),
                                _RequirementItem(
                                  text: 'Complete full name of the certificate owner',
                                ),
                                _RequirementItem(
                                  text: 'Birth date of the certificate owner',
                                ),
                                _RequirementItem(
                                  text: 'Place of birth of the certificate owner',
                                ),
                                _RequirementItem(
                                  text: 'Name of the requester if different from the certificate owner',
                                ),
                                _RequirementItem(
                                  text: 'Authorization letter and valid ID of the certificate owner if the requester is not the owner',
                                ),
                                _RequirementItem(
                                  text: 'Extra cash for applicable processing and copy fees',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _BorrowInfoCard(
                            child: Column(
                              children: [
                                _BorrowTextField(
                                  controller: _fullNameController,
                                  label: 'Full Name',
                                  hint: 'Enter your full name',
                                ),
                                const SizedBox(height: 14),
                                _BorrowTextField(
                                  controller: _contactNumberController,
                                  label: 'Contact Number',
                                  hint: 'Enter your contact number',
                                  keyboardType: TextInputType.phone,
                                ),
                                const SizedBox(height: 14),
                                _BorrowTextField(
                                  controller: _emailController,
                                  label: 'Email Address',
                                  hint: 'Enter your email address',
                                  keyboardType: TextInputType.emailAddress,
                                ),
                                const SizedBox(height: 14),
                                _BorrowTextField(
                                  controller: _requestorRelationshipController,
                                  label: 'Relationship to Certificate Owner',
                                  hint: 'Example: Self, Parent, Sibling, Representative',
                                ),
                                const SizedBox(height: 14),
                                _BorrowTextField(
                                  controller: _purposeController,
                                  label: 'Purpose of Request',
                                  hint: 'Enter the purpose of the CENOMAR request',
                                  maxLines: 3,
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _BorrowDateTimeField(
                                        label: 'Appointment Date',
                                        value: _appointmentDate == null
                                            ? 'Select date'
                                            : _formatDate(_appointmentDate!),
                                        icon: Icons.calendar_month_rounded,
                                        onTap: _pickAppointmentDate,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _BorrowDateTimeField(
                                        label: 'Appointment Time',
                                        value: _appointmentTime == null
                                            ? 'Select time'
                                            : _formatTime(_appointmentTime!),
                                        icon: Icons.access_time_rounded,
                                        onTap: _pickAppointmentTime,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                _BorrowTextField(
                                  controller: _notesController,
                                  label: 'Additional Notes',
                                  hint: 'Add other important details',
                                  maxLines: 4,
                                  requiredField: false,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: _isSubmitting ? null : _submitAppointment,
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFFFFB300),
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              child: Text(
                                _isSubmitting ? 'Submitting...' : 'Book Appointment',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _BorrowInfoCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'My CENOMAR Appointments',
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF20242C),
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Your submitted appointments and their latest approval status will appear here.',
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white70
                                        : const Color(0xFF5F6368),
                                    fontSize: 14,
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                FutureBuilder<List<Map<String, dynamic>>>(
                                  future: _loadAppointments(),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Padding(
                                        padding:
                                            EdgeInsets.symmetric(vertical: 12),
                                        child: Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      );
                                    }

                                    if (_currentUser == null) {
                                      return Text(
                                        'Please sign in to view your submitted appointments.',
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.white70
                                              : const Color(0xFF5F6368),
                                          fontSize: 14,
                                          height: 1.5,
                                        ),
                                      );
                                    }

                                    if (snapshot.hasError) {
                                      return Text(
                                        'Unable to load your CENOMAR appointments right now.',
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.white70
                                              : const Color(0xFF5F6368),
                                          fontSize: 14,
                                          height: 1.5,
                                        ),
                                      );
                                    }

                                    final appointments = snapshot.data ?? [];
                                    if (appointments.isEmpty) {
                                      return Text(
                                        'You have not booked any CENOMAR appointment yet.',
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.white70
                                              : const Color(0xFF5F6368),
                                          fontSize: 14,
                                          height: 1.5,
                                        ),
                                      );
                                    }

                                    return Column(
                                      children: appointments.map((appointment) {
                                        final status =
                                            appointment['status']?.toString() ??
                                                'pending';
                                        final statusColor =
                                            _statusColor(status);

                                        return Container(
                                          width: double.infinity,
                                          margin:
                                              const EdgeInsets.only(bottom: 12),
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? const Color(0xFF1F1F28)
                                                : const Color(0xFFF7F8FA),
                                            borderRadius:
                                                BorderRadius.circular(18),
                                            border: Border.all(
                                              color: isDark
                                                  ? Colors.white10
                                                  : const Color(0xFFDADCE0),
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      appointment['full_name']
                                                                  ?.toString()
                                                                  .trim()
                                                                  .isNotEmpty ==
                                                              true
                                                          ? appointment['full_name']
                                                              .toString()
                                                          : 'CENOMAR Appointment',
                                                      style: TextStyle(
                                                        color: isDark
                                                            ? Colors.white
                                                            : const Color(
                                                                0xFF20242C),
                                                        fontSize: 15,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                    ),
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 12,
                                                      vertical: 6,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: statusColor
                                                          .withValues(
                                                            alpha: 0.12,
                                                          ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            999,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      _statusLabel(status),
                                                      style: TextStyle(
                                                        color: statusColor,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        fontSize: 12.5,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 10),
                                              Text(
                                                'Schedule: ${_formatDate(appointment['appointment_date']?.toString())} • ${appointment['appointment_time'] ?? 'N/A'}',
                                                style: TextStyle(
                                                  color: isDark
                                                      ? Colors.white70
                                                      : const Color(0xFF5F6368),
                                                  fontSize: 13,
                                                  height: 1.5,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                'Purpose: ${appointment['purpose']?.toString().trim().isNotEmpty == true ? appointment['purpose'].toString() : 'No purpose provided'}',
                                                style: TextStyle(
                                                  color: isDark
                                                      ? Colors.white70
                                                      : const Color(0xFF5F6368),
                                                  fontSize: 13,
                                                  height: 1.5,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                'Updated: ${_formatDateTimeUpdated(appointment['updated_at']?.toString())}',
                                                style: TextStyle(
                                                  color: isDark
                                                      ? Colors.white54
                                                      : const Color(0xFF7A7F87),
                                                  fontSize: 12.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
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

class _CenodeathAppointmentPage extends StatefulWidget {
  const _CenodeathAppointmentPage({required this.item});

  final OnlineServiceItem item;

  @override
  State<_CenodeathAppointmentPage> createState() =>
      _CenodeathAppointmentPageState();
}

class _CenodeathAppointmentPageState extends State<_CenodeathAppointmentPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _emailController = TextEditingController();
  final _requestorRelationshipController = TextEditingController();
  final _purposeController = TextEditingController();
  final _notesController = TextEditingController();

  firebase_auth.User? get _currentUser =>
      firebase_auth.FirebaseAuth.instance.currentUser;

  DateTime? _appointmentDate;
  TimeOfDay? _appointmentTime;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _contactNumberController.dispose();
    _emailController.dispose();
    _requestorRelationshipController.dispose();
    _purposeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickAppointmentDate() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year, now.month, now.day + 1);
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _appointmentDate ?? firstDate,
      firstDate: firstDate,
      lastDate: DateTime(now.year + 2),
    );

    if (pickedDate != null) {
      setState(() {
        _appointmentDate = pickedDate;
      });
    }
  }

  Future<void> _pickAppointmentTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _appointmentTime ?? const TimeOfDay(hour: 9, minute: 0),
    );

    if (pickedTime != null) {
      setState(() {
        _appointmentTime = pickedTime;
      });
    }
  }

  Future<List<Map<String, dynamic>>> _loadAppointments() async {
    final user = _currentUser;
    if (user == null) {
      return [];
    }

    final response = await Supabase.instance.client
        .from('cenodeath_appointments')
        .select(
          'id, full_name, contact_number, email, relationship_to_owner, purpose, appointment_date, appointment_time, notes, status, created_at, updated_at',
        )
        .eq('user_id', user.uid)
        .order('created_at', ascending: false);

    return (response as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<void> _submitAppointment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final user = _currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in first before booking an appointment.'),
        ),
      );
      return;
    }

    if (_appointmentDate == null || _appointmentTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your preferred appointment schedule.'),
        ),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isSubmitting = true;
    });

    try {
      await Supabase.instance.client.from('cenodeath_appointments').insert({
        'user_id': user.uid,
        'service_name': widget.item.title,
        'full_name': _fullNameController.text.trim(),
        'contact_number': _contactNumberController.text.trim(),
        'email': _emailController.text.trim(),
        'relationship_to_owner': _requestorRelationshipController.text.trim(),
        'purpose': _purposeController.text.trim(),
        'appointment_date': _appointmentDate!.toIso8601String().split('T').first,
        'appointment_time': _formatTime(_appointmentTime!),
        'notes': _notesController.text.trim(),
        'status': 'pending',
      });

      _fullNameController.clear();
      _contactNumberController.clear();
      _emailController.clear();
      _requestorRelationshipController.clear();
      _purposeController.clear();
      _notesController.clear();

      setState(() {
        _appointmentDate = null;
        _appointmentTime = null;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'CENODEATH appointment submitted successfully.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to submit appointment: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  String _formatDate(dynamic value) {
    if (value == null) {
      return 'Not specified';
    }

    final DateTime? date = value is DateTime
        ? value
        : DateTime.tryParse(value.toString());

    if (date == null) {
      return value.toString();
    }

    final month = _monthName(date.month);
    return '$month ${date.day}, ${date.year}';
  }

  String _formatDateTimeUpdated(dynamic value) {
    if (value == null) {
      return 'Not available';
    }

    final DateTime? date = value is DateTime
        ? value
        : DateTime.tryParse(value.toString());

    if (date == null) {
      return value.toString();
    }

    final month = _monthName(date.month);
    final hour = date.hour == 0 ? 12 : (date.hour > 12 ? date.hour - 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$month ${date.day}, ${date.year} • $hour:$minute $period';
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  String _monthName(int month) {
    const months = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month];
  }

  String _statusLabel(String status) {
    switch (status.trim().toLowerCase()) {
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      default:
        return 'Pending';
    }
  }

  Color _statusColor(String status) {
    switch (status.trim().toLowerCase()) {
      case 'approved':
        return const Color(0xFF16A34A);
      case 'rejected':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF26A69A);
    }
  }

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
            Color(0xFF26A69A),
            Color(0xFF80CBC4),
            Color(0xFFEAEAEA),
          ];

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          Container(
            height: 230,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: topGradient,
                stops: const [0.0, 0.58, 1.0],
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
                      Expanded(
                        child: Text(
                          widget.item.title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _BorrowInfoCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'CENODEATH Appointment',
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF20242C),
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Book your schedule here to request and claim a Certificate of No Death (CENODEATH). Fill in the required details and wait for confirmation from the admin.',
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white70
                                        : const Color(0xFF5F6368),
                                    fontSize: 14,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _BorrowInfoCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Requirements',
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF20242C),
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Please prepare the following before booking or claiming a CENODEATH:',
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white70
                                        : const Color(0xFF5F6368),
                                    fontSize: 14,
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                _RequirementItem(
                                  text: 'Valid ID of the requester',
                                ),
                                _RequirementItem(
                                  text: 'Complete full name of the certificate owner',
                                ),
                                _RequirementItem(
                                  text: 'Purpose for requesting the certificate',
                                ),
                                _RequirementItem(
                                  text: 'Relationship to the certificate owner',
                                ),
                                _RequirementItem(
                                  text: 'Authorization letter and valid ID of the certificate owner if the requester is not the owner',
                                ),
                                _RequirementItem(
                                  text: 'Supporting documents as may be required by the office',
                                ),
                                _RequirementItem(
                                  text: 'Extra cash for applicable processing and copy fees',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _BorrowInfoCard(
                            child: Column(
                              children: [
                                _BorrowTextField(
                                  controller: _fullNameController,
                                  label: 'Full Name',
                                  hint: 'Enter your full name',
                                ),
                                const SizedBox(height: 14),
                                _BorrowTextField(
                                  controller: _contactNumberController,
                                  label: 'Contact Number',
                                  hint: 'Enter your contact number',
                                  keyboardType: TextInputType.phone,
                                ),
                                const SizedBox(height: 14),
                                _BorrowTextField(
                                  controller: _emailController,
                                  label: 'Email Address',
                                  hint: 'Enter your email address',
                                  keyboardType: TextInputType.emailAddress,
                                ),
                                const SizedBox(height: 14),
                                _BorrowTextField(
                                  controller: _requestorRelationshipController,
                                  label: 'Relationship to Certificate Owner',
                                  hint: 'Example: Self, Parent, Sibling, Representative',
                                ),
                                const SizedBox(height: 14),
                                _BorrowTextField(
                                  controller: _purposeController,
                                  label: 'Purpose of Request',
                                  hint: 'Enter the purpose of the CENODEATH request',
                                  maxLines: 3,
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _BorrowDateTimeField(
                                        label: 'Appointment Date',
                                        value: _appointmentDate == null
                                            ? 'Select date'
                                            : _formatDate(_appointmentDate!),
                                        icon: Icons.calendar_month_rounded,
                                        onTap: _pickAppointmentDate,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _BorrowDateTimeField(
                                        label: 'Appointment Time',
                                        value: _appointmentTime == null
                                            ? 'Select time'
                                            : _formatTime(_appointmentTime!),
                                        icon: Icons.access_time_rounded,
                                        onTap: _pickAppointmentTime,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                _BorrowTextField(
                                  controller: _notesController,
                                  label: 'Additional Notes',
                                  hint: 'Add other important details',
                                  maxLines: 4,
                                  requiredField: false,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: _isSubmitting ? null : _submitAppointment,
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF26A69A),
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              child: Text(
                                _isSubmitting ? 'Submitting...' : 'Book Appointment',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _BorrowInfoCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'My CENODEATH Appointments',
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF20242C),
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Your submitted appointments and their latest approval status will appear here.',
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white70
                                        : const Color(0xFF5F6368),
                                    fontSize: 14,
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                FutureBuilder<List<Map<String, dynamic>>>(
                                  future: _loadAppointments(),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Padding(
                                        padding:
                                            EdgeInsets.symmetric(vertical: 12),
                                        child: Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      );
                                    }

                                    if (_currentUser == null) {
                                      return Text(
                                        'Please sign in to view your submitted appointments.',
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.white70
                                              : const Color(0xFF5F6368),
                                          fontSize: 14,
                                          height: 1.5,
                                        ),
                                      );
                                    }

                                    if (snapshot.hasError) {
                                      return Text(
                                        'Unable to load your CENODEATH appointments right now.',
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.white70
                                              : const Color(0xFF5F6368),
                                          fontSize: 14,
                                          height: 1.5,
                                        ),
                                      );
                                    }

                                    final appointments = snapshot.data ?? [];
                                    if (appointments.isEmpty) {
                                      return Text(
                                        'You have not booked any CENODEATH appointment yet.',
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.white70
                                              : const Color(0xFF5F6368),
                                          fontSize: 14,
                                          height: 1.5,
                                        ),
                                      );
                                    }

                                    return Column(
                                      children: appointments.map((appointment) {
                                        final status =
                                            appointment['status']?.toString() ??
                                                'pending';
                                        final statusColor =
                                            _statusColor(status);

                                        return Container(
                                          width: double.infinity,
                                          margin:
                                              const EdgeInsets.only(bottom: 12),
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? const Color(0xFF1F1F28)
                                                : const Color(0xFFF7F8FA),
                                            borderRadius:
                                                BorderRadius.circular(18),
                                            border: Border.all(
                                              color: isDark
                                                  ? Colors.white10
                                                  : const Color(0xFFDADCE0),
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      appointment['full_name']
                                                                  ?.toString()
                                                                  .trim()
                                                                  .isNotEmpty ==
                                                              true
                                                          ? appointment['full_name']
                                                              .toString()
                                                          : 'CENODEATH Appointment',
                                                      style: TextStyle(
                                                        color: isDark
                                                            ? Colors.white
                                                            : const Color(
                                                                0xFF20242C),
                                                        fontSize: 15,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                    ),
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 12,
                                                      vertical: 6,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: statusColor
                                                          .withValues(
                                                            alpha: 0.12,
                                                          ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            999,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      _statusLabel(status),
                                                      style: TextStyle(
                                                        color: statusColor,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        fontSize: 12.5,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 10),
                                              Text(
                                                'Schedule: ${_formatDate(appointment['appointment_date']?.toString())} • ${appointment['appointment_time'] ?? 'N/A'}',
                                                style: TextStyle(
                                                  color: isDark
                                                      ? Colors.white70
                                                      : const Color(0xFF5F6368),
                                                  fontSize: 13,
                                                  height: 1.5,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                'Purpose: ${appointment['purpose']?.toString().trim().isNotEmpty == true ? appointment['purpose'].toString() : 'No purpose provided'}',
                                                style: TextStyle(
                                                  color: isDark
                                                      ? Colors.white70
                                                      : const Color(0xFF5F6368),
                                                  fontSize: 13,
                                                  height: 1.5,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                'Updated: ${_formatDateTimeUpdated(appointment['updated_at']?.toString())}',
                                                style: TextStyle(
                                                  color: isDark
                                                      ? Colors.white54
                                                      : const Color(0xFF7A7F87),
                                                  fontSize: 12.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
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

class _FacilityBorrowRequestPage extends StatefulWidget {
  const _FacilityBorrowRequestPage({required this.item});

  final OnlineServiceItem item;

  @override
  State<_FacilityBorrowRequestPage> createState() =>
      _FacilityBorrowRequestPageState();
}

class _FacilityBorrowRequestPageState extends State<_FacilityBorrowRequestPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _purposeController = TextEditingController();
  final _participantsController = TextEditingController();
  final _additionalInfoController = TextEditingController();

  firebase_auth.User? get _currentUser =>
      firebase_auth.FirebaseAuth.instance.currentUser;

  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  @override
  void dispose() {
    _fullNameController.dispose();
    _contactNumberController.dispose();
    _purposeController.dispose();
    _participantsController.dispose();
    _additionalInfoController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  Future<void> _pickStartTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _startTime ?? TimeOfDay.now(),
    );

    if (pickedTime != null) {
      setState(() {
        _startTime = pickedTime;
      });
    }
  }

  Future<void> _pickEndTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _endTime ?? TimeOfDay.now(),
    );

    if (pickedTime != null) {
      setState(() {
        _endTime = pickedTime;
      });
    }
  }

  Future<List<Map<String, dynamic>>> _loadRequests() async {
    final user = _currentUser;
    if (user == null) {
      return [];
    }

    final response = await Supabase.instance.client
        .from('facility_borrow_requests')
        .select(
          'id, facility_name, full_name, purpose, event_date, start_time, end_time, expected_participants, additional_information, status, created_at, updated_at',
        )
        .or('user_id.eq.${user.uid},user_id.eq.facility-request-user')
        .order('created_at', ascending: false);

    return (response as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final user = _currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in first before submitting a request.'),
        ),
      );
      return;
    }

    if (_selectedDate == null || _startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select the exact date and time of use.'),
        ),
      );
      return;
    }

    FocusScope.of(context).unfocus();

    try {
      await Supabase.instance.client.from('facility_borrow_requests').insert({
        'user_id': user.uid,
        'facility_name': widget.item.title,
        'full_name': _fullNameController.text.trim(),
        'contact_number': _contactNumberController.text.trim(),
        'purpose': _purposeController.text.trim(),
        'expected_participants':
            int.tryParse(_participantsController.text.trim()),
        'event_date': _selectedDate!.toIso8601String().split('T').first,
        'start_time': _formatTime(_startTime!),
        'end_time': _formatTime(_endTime!),
        'additional_information': _additionalInfoController.text.trim(),
        'status': 'pending',
      });

      _fullNameController.clear();
      _contactNumberController.clear();
      _purposeController.clear();
      _participantsController.clear();
      _additionalInfoController.clear();

      setState(() {
        _selectedDate = null;
        _startTime = null;
        _endTime = null;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Borrow request for ${widget.item.title} submitted successfully.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to submit borrow request: $e'),
        ),
      );
    }
  }

  String _formatDate(dynamic value) {
    if (value == null) {
      return 'Not specified';
    }

    final DateTime? date = value is DateTime
        ? value
        : DateTime.tryParse(value.toString());

    if (date == null) {
      return value.toString();
    }

    final month = _monthName(date.month);
    return '$month ${date.day}, ${date.year}';
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  String _monthName(int month) {
    const months = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month];
  }

  String _displayFacilityName(String? value) {
    final normalized = value?.trim().toLowerCase() ?? '';
    if (normalized == 'tiwi tiwi gymnasium') {
      return 'Tiwi Gymnasium';
    }

    if (value == null || value.trim().isEmpty) {
      return widget.item.title;
    }

    return value.trim();
  }

  String _statusLabel(String status) {
    switch (status.trim().toLowerCase()) {
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      default:
        return 'Pending';
    }
  }

  Color _statusColor(String status) {
    switch (status.trim().toLowerCase()) {
      case 'approved':
        return const Color(0xFF16A34A);
      case 'rejected':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF1E88E5);
    }
  }

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
            height: 230,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: topGradient,
                stops: const [0.0, 0.58, 1.0],
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
                      Expanded(
                        child: Text(
                          widget.item.title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _BorrowInfoCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Facility Borrow Request',
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF20242C),
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Fill in the exact date, time, and other required information to request the use of the facility.',
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white70
                                        : const Color(0xFF5F6368),
                                    fontSize: 14,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _BorrowInfoCard(
                            child: Column(
                              children: [
                                _BorrowTextField(
                                  controller: _fullNameController,
                                  label: 'Full Name',
                                  hint: 'Enter your full name',
                                ),
                                const SizedBox(height: 14),
                                _BorrowTextField(
                                  controller: _contactNumberController,
                                  label: 'Contact Number',
                                  hint: 'Enter your contact number',
                                  keyboardType: TextInputType.phone,
                                ),
                                const SizedBox(height: 14),
                                _BorrowTextField(
                                  controller: _purposeController,
                                  label: 'Purpose of Borrowing',
                                  hint: 'Enter the purpose of using the facility',
                                  maxLines: 3,
                                ),
                                const SizedBox(height: 14),
                                _BorrowTextField(
                                  controller: _participantsController,
                                  label: 'Expected Number of Participants',
                                  hint: 'Enter expected number of participants',
                                  keyboardType: TextInputType.number,
                                ),
                                const SizedBox(height: 14),
                                _BorrowDateTimeField(
                                  label: 'Exact Date',
                                  value: _selectedDate == null
                                      ? 'Select date'
                                      : _formatDate(_selectedDate!),
                                  icon: Icons.calendar_month_rounded,
                                  onTap: _pickDate,
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _BorrowDateTimeField(
                                        label: 'Start Time',
                                        value: _startTime == null
                                            ? 'Select time'
                                            : _formatTime(_startTime!),
                                        icon: Icons.access_time_rounded,
                                        onTap: _pickStartTime,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _BorrowDateTimeField(
                                        label: 'End Time',
                                        value: _endTime == null
                                            ? 'Select time'
                                            : _formatTime(_endTime!),
                                        icon: Icons.schedule_rounded,
                                        onTap: _pickEndTime,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                _BorrowTextField(
                                  controller: _additionalInfoController,
                                  label: 'Additional Information',
                                  hint: 'Add other important details',
                                  maxLines: 4,
                                  requiredField: false,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: () {
                                _submitRequest();
                              },
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF1E88E5),
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              child: const Text(
                                'Submit Request',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _BorrowInfoCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'My Facility Requests',
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF20242C),
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'After the admin updates your request, the latest status will appear here. Older requests saved with the previous app version are also included.',
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white70
                                        : const Color(0xFF5F6368),
                                    fontSize: 14,
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                FutureBuilder<List<Map<String, dynamic>>>(
                                  future: _loadRequests(),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Padding(
                                        padding:
                                            EdgeInsets.symmetric(vertical: 12),
                                        child: Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      );
                                    }

                                    if (_currentUser == null) {
                                      return Text(
                                        'Please sign in to view your submitted requests.',
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.white70
                                              : const Color(0xFF5F6368),
                                          fontSize: 14,
                                          height: 1.5,
                                        ),
                                      );
                                    }

                                    if (snapshot.hasError) {
                                      return Text(
                                        'Unable to load your facility requests right now.',
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.white70
                                              : const Color(0xFF5F6368),
                                          fontSize: 14,
                                          height: 1.5,
                                        ),
                                      );
                                    }

                                    final requests = snapshot.data ?? [];
                                    if (requests.isEmpty) {
                                      return Text(
                                        'You have not submitted any facility request yet.',
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.white70
                                              : const Color(0xFF5F6368),
                                          fontSize: 14,
                                          height: 1.5,
                                        ),
                                      );
                                    }

                                    return Column(
                                      children: requests.map((request) {
                                        final status =
                                            request['status']?.toString() ??
                                                'pending';
                                        final statusColor =
                                            _statusColor(status);

                                        return Container(
                                          width: double.infinity,
                                          margin:
                                              const EdgeInsets.only(bottom: 12),
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? const Color(0xFF1F1F28)
                                                : const Color(0xFFF7F8FA),
                                            borderRadius:
                                                BorderRadius.circular(18),
                                            border: Border.all(
                                              color: isDark
                                                  ? Colors.white10
                                                  : const Color(0xFFDADCE0),
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      _displayFacilityName(
                                                        request['facility_name']
                                                            ?.toString(),
                                                      ),
                                                      style: TextStyle(
                                                        color: isDark
                                                            ? Colors.white
                                                            : const Color(
                                                                0xFF20242C),
                                                        fontSize: 15,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                    ),
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 12,
                                                      vertical: 6,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: statusColor
                                                          .withValues(
                                                            alpha: 0.12,
                                                          ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            999,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      _statusLabel(status),
                                                      style: TextStyle(
                                                        color: statusColor,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        fontSize: 12.5,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 10),
                                              Text(
                                                request['purpose']
                                                        ?.toString()
                                                        .trim()
                                                        .isNotEmpty ==
                                                    true
                                                    ? request['purpose']
                                                        .toString()
                                                    : 'No purpose provided',
                                                style: TextStyle(
                                                  color: isDark
                                                      ? Colors.white70
                                                      : const Color(0xFF5F6368),
                                                  fontSize: 14,
                                                  height: 1.5,
                                                ),
                                              ),
                                              const SizedBox(height: 10),
                                              Text(
                                                'Schedule: ${_formatDate(request['event_date']?.toString())} • ${request['start_time'] ?? 'N/A'} - ${request['end_time'] ?? 'N/A'}',
                                                style: TextStyle(
                                                  color: isDark
                                                      ? Colors.white70
                                                      : const Color(0xFF5F6368),
                                                  fontSize: 13,
                                                  height: 1.5,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                'Updated: ${_formatDate(request['updated_at']?.toString())}',
                                                style: TextStyle(
                                                  color: isDark
                                                      ? Colors.white54
                                                      : const Color(0xFF7A7F87),
                                                  fontSize: 12.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
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

class _BorrowInfoCard extends StatelessWidget {
  const _BorrowInfoCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF262631) : Colors.white,
        borderRadius: BorderRadius.circular(22),
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
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: child,
      ),
    );
  }
}

class _BorrowTextField extends StatelessWidget {
  const _BorrowTextField({
    required this.controller,
    required this.label,
    required this.hint,
    this.keyboardType,
    this.maxLines = 1,
    this.requiredField = true,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType? keyboardType;
  final int maxLines;
  final bool requiredField;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: TextStyle(
        color: isDark ? Colors.white : const Color(0xFF20242C),
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(
          color: isDark ? Colors.white70 : const Color(0xFF5F6368),
        ),
        hintStyle: TextStyle(
          color: isDark ? Colors.white38 : const Color(0xFF9AA0A6),
        ),
        filled: true,
        fillColor: isDark ? const Color(0xFF1F1F28) : const Color(0xFFF7F8FA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? Colors.white10 : const Color(0xFFDADCE0),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? Colors.white10 : const Color(0xFFDADCE0),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xFF1E88E5),
            width: 1.4,
          ),
        ),
      ),
      validator: (value) {
        if (!requiredField) {
          return null;
        }

        if (value == null || value.trim().isEmpty) {
          return 'This field is required.';
        }

        if (label == 'Email Address' &&
            value.trim().isNotEmpty &&
            !value.contains('@')) {
          return 'Enter a valid email address.';
        }

        return null;
      },
    );
  }
}

class _BorrowDateTimeField extends StatelessWidget {
  const _BorrowDateTimeField({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F1F28) : const Color(0xFFF7F8FA),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white10 : const Color(0xFFDADCE0),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: const Color(0xFF1E88E5),
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: isDark ? Colors.white70 : const Color(0xFF5F6368),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF20242C),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RequirementItem extends StatelessWidget {
  const _RequirementItem({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF1E88E5),
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: isDark ? Colors.white70 : const Color(0xFF5F6368),
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnlineServiceCategory {
  const _OnlineServiceCategory({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.services,
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final List<OnlineServiceItem> services;
}

enum OnlineServiceTarget {
  none,
  birthCertificate,
  marriageCertificate,
  deathCertificate,
  cenomar,
  cenodeath,
  tiwiGymnasium,
  libjoFacilities,
}

class OnlineServiceItem {
  const OnlineServiceItem({
    required this.title,
    required this.icon,
    required this.iconColor,
    this.target = OnlineServiceTarget.none,
    this.opensBorrowForm = false,
    this.opensBirthCertificateAppointmentForm = false,
    this.opensMarriageCertificateAppointmentForm = false,
    this.opensDeathCertificateAppointmentForm = false,
    this.opensCenomarAppointmentForm = false,
    this.opensCenodeathAppointmentForm = false,
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final OnlineServiceTarget target;
  final bool opensBorrowForm;
  final bool opensBirthCertificateAppointmentForm;
  final bool opensMarriageCertificateAppointmentForm;
  final bool opensDeathCertificateAppointmentForm;
  final bool opensCenomarAppointmentForm;
  final bool opensCenodeathAppointmentForm;
}
