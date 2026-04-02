import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'faq_page.dart';

class ProfilePage extends StatefulWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onToggleDarkMode;
  final ValueChanged<int> onNavigate;

  const ProfilePage({
    super.key,
    required this.isDarkMode,
    required this.onToggleDarkMode,
    required this.onNavigate,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  void _handleBottomNavigation(int index) {
    if (index == 2) return;

    if (index == 0) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }

    Navigator.of(context).pop();
    widget.onNavigate(index);
  }

  User? get _user => _auth.currentUser;

  String get _email {
    return _user?.email?.trim().isNotEmpty == true
        ? _user!.email!.trim()
        : 'No email available';
  }

  String get _username {
    final displayName = _user?.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }

    final email = _user?.email ?? '';
    if (email.contains('@')) {
      return email.split('@').first;
    }

    return 'User';
  }

  String? get _photoUrl {
    final value = _user?.photoURL?.trim();
    if (value == null || value.isEmpty) return null;
    return value;
  }

  String get _initial {
    final username = _username.trim();
    if (username.isEmpty) return 'U';
    return username.characters.first.toUpperCase();
  }

  Future<void> _showEditProfileDialog() async {
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        final usernameController = TextEditingController(text: _username);
        final emailController = TextEditingController(
          text: _user?.email?.trim() ?? '',
        );
        var isSavingProfile = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> submit() async {
              final username = usernameController.text.trim();
              final email = emailController.text.trim();

              if (username.isEmpty) {
                Navigator.of(dialogContext).pop('Username is required.');
                return;
              }

              if (email.isEmpty) {
                Navigator.of(dialogContext).pop('Email is required.');
                return;
              }

              setDialogState(() {
                isSavingProfile = true;
              });

              try {
                final currentUser = _user;
                if (currentUser == null) {
                  Navigator.of(dialogContext).pop(
                    'Unable to update profile right now.',
                  );
                  return;
                }

                final currentUsername = currentUser.displayName?.trim() ?? '';
                final currentEmail = currentUser.email?.trim() ?? '';

                if (email != currentEmail) {
                  await currentUser.verifyBeforeUpdateEmail(email);
                }

                if (username != currentUsername) {
                  await currentUser.updateDisplayName(username);
                }

                await currentUser.reload();

                if (!mounted || !dialogContext.mounted) return;
                setState(() {});
                Navigator.of(dialogContext).pop(
                  'Profile updated. If you changed the email, confirm it from your inbox.',
                );
              } on FirebaseAuthException catch (error) {
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop(
                    error.message ??
                        'Failed to update profile. Please try again.',
                  );
                }
              } catch (_) {
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop(
                    'Unable to update profile right now.',
                  );
                }
              }
            }

            return AlertDialog(
              title: const Text('Edit Profile'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDialogTextField(
                      controller: usernameController,
                      label: 'Username',
                      icon: Icons.person_outline,
                    ),
                    const SizedBox(height: 14),
                    _buildDialogTextField(
                      controller: emailController,
                      label: 'Email',
                      icon: Icons.mail_outline,
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSavingProfile
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: isSavingProfile ? null : submit,
                  child: isSavingProfile
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (!mounted || result == null) return;
    _showMessage(result);
  }

  Future<void> _showChangePasswordDialog() async {
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        final passwordController = TextEditingController();
        final confirmController = TextEditingController();
        bool obscurePassword = true;
        bool obscureConfirm = true;
        var isChangingPassword = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> submit() async {
              final password = passwordController.text.trim();
              final confirmPassword = confirmController.text.trim();

              if (password.length < 6) {
                Navigator.of(dialogContext).pop(
                  'Password must be at least 6 characters.',
                );
                return;
              }

              if (password != confirmPassword) {
                Navigator.of(dialogContext).pop('Passwords do not match.');
                return;
              }

              setDialogState(() {
                isChangingPassword = true;
              });

              try {
                final currentUser = _user;
                if (currentUser == null) {
                  Navigator.of(dialogContext).pop(
                    'Unable to change password right now.',
                  );
                  return;
                }

                await currentUser.updatePassword(password);

                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop(
                    'Password updated successfully.',
                  );
                }
              } on FirebaseAuthException catch (error) {
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop(
                    error.message ??
                        'Failed to change password. Please try again.',
                  );
                }
              } catch (_) {
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop(
                    'Unable to change password right now.',
                  );
                }
              }
            }

            return AlertDialog(
              title: const Text('Change Password'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDialogTextField(
                      controller: passwordController,
                      label: 'New Password',
                      icon: Icons.lock_outline,
                      obscureText: obscurePassword,
                      suffixIcon: IconButton(
                        onPressed: () {
                          setDialogState(() {
                            obscurePassword = !obscurePassword;
                          });
                        },
                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _buildDialogTextField(
                      controller: confirmController,
                      label: 'Confirm Password',
                      icon: Icons.lock_reset_outlined,
                      obscureText: obscureConfirm,
                      suffixIcon: IconButton(
                        onPressed: () {
                          setDialogState(() {
                            obscureConfirm = !obscureConfirm;
                          });
                        },
                        icon: Icon(
                          obscureConfirm
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isChangingPassword
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: isChangingPassword ? null : submit,
                  child: isChangingPassword
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );

    if (!mounted || result == null) return;
    _showMessage(result);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message)),
      );
  }

  Widget _buildDialogTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor =
        isDark ? theme.scaffoldBackgroundColor : const Color(0xFFEAEAEA);
    final titleColor = isDark ? Colors.white : Colors.black;
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
            child: Column(
              children: [
                const SizedBox(height: 18),
                Text(
                  'Profile',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: Column(
                      children: [
                        _buildProfileHeader(context),
                        const SizedBox(height: 16),
                        _buildGeneralSection(context),
                        const SizedBox(height: 16),
                        _buildSettingsSection(context),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        child: BottomNavigationBar(
          currentIndex: 2,
          onTap: _handleBottomNavigation,
          backgroundColor: isDark ? const Color(0xFF111827) : Colors.white,
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor:
              isDark ? Colors.white70 : Colors.grey.shade600,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.info), label: 'News'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor:
                isDark ? const Color(0xFF243145) : const Color(0xFFD9EAF8),
            backgroundImage:
                _photoUrl != null ? NetworkImage(_photoUrl!) : null,
            child: _photoUrl == null
                ? Text(
                    _initial,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1565C0),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _username,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _email,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralSection(BuildContext context) {
    return _buildSectionCard(
      context: context,
      title: 'General',
      children: [
        _ProfileOptionTile(
          icon: Icons.person_outline,
          title: 'Edit Profile',
          subtitle: 'Change your username and email',
          onTap: _showEditProfileDialog,
        ),
        const SizedBox(height: 14),
        _ProfileOptionTile(
          icon: Icons.lock_outline,
          title: 'Change Password',
          subtitle: 'Update and strengthen account security',
          onTap: _showChangePasswordDialog,
        ),
        const SizedBox(height: 14),
        _ProfileOptionTile(
          icon: Icons.help_center_outlined,
          title: 'FAQs',
          subtitle: 'View frequently asked questions and quick help',
          onTap: () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const FaqPage()));
          },
        ),
      ],
    );
  }

  Widget _buildSettingsSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _buildSectionCard(
      context: context,
      title: 'Settings',
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF243145) : const Color(0xFFE5E5E5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.dark_mode_outlined,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'Dark Mode',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ),
            Switch(
              value: isDark,
              onChanged: widget.onToggleDarkMode,
              activeThumbColor: Colors.blue,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required BuildContext context,
    required String title,
    required List<Widget> children,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }
}

class _ProfileOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ProfileOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF243145)
                    : const Color(0xFFE5E5E5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white70
                          : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white54
                  : Colors.black45,
            ),
          ],
        ),
      ),
    );
  }
}
